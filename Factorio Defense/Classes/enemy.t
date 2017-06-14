class Enemy
    import Math
    export var all

    var v : entity_vars
    var dl : point

    forward proc request_new_target ()
    forward proc fire_projectile (u : unchecked ^entity_vars)

    proc initialize (i, et : int, l : point)
	v.ind := i
	v.cur_target := nil
	v.state := ALIVE
	if et > 0 then
	    v.health := max_healths_enemies (et)
	    v.cooldown := reload_enemies (et)
	else
	    v.health := 0
	    v.cooldown := 1000
	end if
	v.effective_health := v.health
	v.e_type := et
	v.loc := l
	v.class_type := ENEMY
	dl := make_v (0, 0)
    end initialize

    %update every tick
    proc update ()
	if v.state = NONEXISTENT or v.state = DEAD then
	    return
	end if
	if v.health <= 0 then
	    unlock_sem (floor ((v.loc.x - 1) / MAP_M_SIZ) + 1, floor ((v.loc.y - 1) / MAP_M_SIZ) + 1, addr (v))
	    v.state := DEAD
	    map_deaths (floor (v.loc.x)) (floor (v.loc.y)) += 1
	fork play_effect ("Sounds\\enemy_death.wav")
	    return
	end if
	var found : boolean := false
	for i : floor (max (MAP_B_W_L, dl.x - 1)) .. floor (min (MAP_B_W_U, dl.x + 1))
	    for j : floor (max (MAP_B_H_L, dl.y - 1)) .. floor (min (MAP_B_H_U, dl.y + 1))
		if map (i) (j) -> class_type = WALL then
		    if Math.Distance (i, j, dl.x, dl.y) < 1-ENEMY_MVT_TILES_PER_SEC then
			v.cur_target := map (i) (j)
			found := true
			if enemy_on_standby(v.ind) then
			    enemy_on_standby(v.ind) := false
			    enemies_on_standby -= 1
			end if
			exit
		    end if
		end if
	    end for
	    exit when found
	end for
	if v.cur_target not= nil then %and Rand.Real > 0.01 then
	    if v.cur_target -> state = DEAD then
		request_new_target ()
	    elsif v.cur_target -> effective_health <= 0 then
		request_new_target ()
	    elsif distance_squared (v.loc, v.cur_target -> loc) > range_enemies (v.e_type) ** 2 then
		request_new_target ()
	    else
		if v.cooldown <= 0 then
		    fire_projectile (v.cur_target)
		end if
	    end if
	else
	    if dl.y >= 1 and dl.y <= MAP_HEIGHT and dl.x >= 1 and dl.x <= MAP_WIDTH then
		if (floor ((dl.x - 1) / MAP_M_SIZ) = floor ((v.loc.x - 1) / MAP_M_SIZ) and floor ((dl.y - 1) / MAP_M_SIZ) = floor ((v.loc.y - 1) / MAP_M_SIZ)) then
		    v.loc := dl
		else
		    if lock_sem (floor ((dl.x - 1) / MAP_M_SIZ) + 1, floor ((dl.y - 1) / MAP_M_SIZ) + 1, addr (v)) then
			unlock_sem (floor ((v.loc.x - 1) / MAP_M_SIZ) + 1, floor ((v.loc.y - 1) / MAP_M_SIZ) + 1, addr (v))
			v.loc := dl
		    end if
		end if
	    end if

	    if dl.y < 1 then
		v.state := NONEXISTENT
		enemies_through += 1
		unlock_sem (floor ((v.loc.x - 1) / MAP_M_SIZ) + 1, floor ((v.loc.y - 1) / MAP_M_SIZ) + 1, addr (v))
		return
	    else
		request_new_target ()
	    end if
	end if
	if map_handler (max(1,floor (dl.x))) (max(1,floor (dl.y))).class_type = FIRE then
	    var s : int := real_damage (floor (Rand.Real () + 3 * ln (map_handler (floor (dl.x)) (floor (dl.y)).health)),
		3, armor_enemies (v.e_type))
	    v.health -= s
	    v.effective_health -= s
	end if
	v.cooldown -= 1
    end update

    proc pre_update ()
	if v.state = NONEXISTENT or v.state = DEAD then
	    return
	end if
	var movt : int := 0
	var dd : point
	var t : real
	if range_enemies (v.e_type) >= 5 then
	    movt := 1
	end if

	%follow the flow field
	dl := make_v (0, 0)
	for i : round (max (1, v.loc.x - 0.5)) .. round (min (MAP_WIDTH, v.loc.x + 0.5))
	    for j : round (max (1, v.loc.y - 0.5)) .. round (min (MAP_HEIGHT, v.loc.y + 0.5))
		dl := add_v (dl, scale_v (map_mov (movt) (i) (j), (1 - abs (v.loc.x - i)) * (1 - abs (v.loc.y - j))))
	    end for
	end for

	dl := scale_v (dl, 1)

	%separate
	for i : floor (max (1, ((v.loc.x - 2) / MAP_M_SIZ) + 1)) .. floor (min (MAP_M_WID, (v.loc.x) / MAP_M_SIZ + 1))
	    for j : floor (max (1, ((v.loc.y - 2) / MAP_M_SIZ) + 1)) .. floor (min (MAP_M_HEI, (v.loc.y) / MAP_M_SIZ + 1))
		movt := map_meta_sem (i) (j)
		for k : 1 .. MAP_M_CAP
		    exit when movt <= 0
		    if map_meta (i) (j) (k) not= nil then
			if addr ( ^ (map_meta (i) (j) (k))) not= addr (v) then
			    if map_meta (i) (j) (k) -> class_type = ENEMY then
				dd := diff_v (v.loc, map_meta (i) (j) (k) -> loc)
				t := magnitude_squared (dd)
				if t < 1 and t > 0 then
				    dl := add_v (dl, scale_v (dd, (1.0 - sqrt (t)) / t))
				end if
			    end if
			end if
			movt -= 1
		    end if
		end for
	    end for
	end for
	%move away from edges
	if v.loc.x < 1.5 and dl.x < 0 then
	    dl.x := 1.5 - v.loc.x
	elsif v.loc.x > MAP_WIDTH - 0.5 and dl.x > 0 then
	    dl.x := MAP_WIDTH - 0.5 - v.loc.x
	end if
	if v.loc.y > MAP_HEIGHT - 0.5 and dl.y > 0 then
	    dl.y := MAP_HEIGHT - 0.5 - v.loc.y
	elsif v.loc.y < 1.5 and dl.y < 0 and abs (v.loc.x - MAP_WIDTH / 2) > 3 then
	    dl.y := 1.5 - v.loc.y
	end if

	%move request
	dl := add_v (v.loc, truncate (dl, ENEMY_MVT_TILES_PER_SEC))
    end pre_update

    %draw
    proc draw ()
	if v.state < ALIVE then
	    return
	end if
	var dsc_x : int := round ((v.loc.x - 0.5) * PIXELS_PER_GRID)
	var dsc_y : int := round ((v.loc.y - 0.5) * PIXELS_PER_GRID)
	Draw.FillBox (dsc_x - 5, dsc_y - 5, dsc_x + 5, dsc_y + 5, brightred)

	if v.health < max_healths_enemies (v.e_type) then
	    dsc_x -= floor (PIXELS_PER_GRID / 2)
	    dsc_y -= 7
	    Draw.Line (dsc_x, dsc_y, floor (PIXELS_PER_GRID * v.health / max_healths_enemies (v.e_type)) + dsc_x, dsc_y, brightgreen)
	    Draw.Line (floor (PIXELS_PER_GRID * v.health / max_healths_enemies (v.e_type)) + dsc_x, dsc_y, PIXELS_PER_GRID + dsc_x, dsc_y, brightred)
	end if
    end draw

    body proc request_new_target ()
	if v.cooldown < 0 and v.cooldown > -6 then
	    return
	end if
	if not enemy_on_standby (v.ind) then
	    enemy_on_standby (v.ind) := true
	    enemies_on_standby += 1
	end if
	if v.cooldown < 0 then
	    v.cooldown += 5
	end if
    end request_new_target

    body proc fire_projectile (u : unchecked ^entity_vars)
	if not can_fire then
	    return
	end if

	proj_queue (next_proj_queue).target := u
	%proj_queue (next_proj_queue).target_type := u.class_type
	proj_queue (next_proj_queue).p_type := proj_enemies (v.e_type)
	proj_queue (next_proj_queue).loc := v.loc
	proj_queue (next_proj_queue).state := ALIVE

	if u -> class_type = TURRET then
	    proj_queue (next_proj_queue).dmg := real_damage (proj_damage (proj_enemies (v.e_type)), proj_dmg_type (proj_enemies (v.e_type)), armor_turrets (u -> e_type))
	else
	    proj_queue (next_proj_queue).dmg := real_damage (proj_damage (proj_enemies (v.e_type)), proj_dmg_type (proj_enemies (v.e_type)), armor_wall)
	end if
	u -> effective_health -= proj_queue (next_proj_queue).dmg

	next_proj_queue := (next_proj_queue mod PROJ_QUEUE_NUM) + 1
	num_proj_queue += 1
	if num_proj_queue >= PROJ_QUEUE_NUM then
	    can_fire := false
	end if

	v.cooldown := reload_enemies (v.e_type)
	
	fork play_effect ("Sounds\\Effects\\enemy_shot_" + intstr(v.e_type) + ".wav")
    end fire_projectile

end Enemy
