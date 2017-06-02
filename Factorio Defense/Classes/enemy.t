class Enemy
    export var all

    var v : entity_vars

    forward proc request_new_target ()
    forward proc fire_projectile (var u : entity_vars)

    proc initialize (i, et : int, l : point)
	v.ind := i
	v.cur_target := 0
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
    end initialize

    %update every tick
    proc update (var u : entity_vars)
	if v.state = NONEXISTENT or v.state = DEAD then
	    return
	end if
	if v.health < 0 then
	    v.state := DEAD
	    return
	end if
	if v.cur_target > 0 then
	    if u.state = DEAD then
		request_new_target ()
	    elsif u.effective_health <= 0 then
		request_new_target ()
	    elsif distance_squared (v.loc, u.loc) > range_enemies (v.e_type) ** 2 then
		request_new_target ()
	    else
		if v.cooldown <= 0 then
		    fire_projectile (u)
		end if
	    end if
	else
	    %add move code here; let there be a short cooldown when they
	    %finish destroying something
	    var movt : int := 0
	    if range_enemies (v.e_type) >= 5 then
		movt := 1
	    end if
	    v.loc := add_v (v.loc, truncate (scale_v (map_mov (movt) (round (v.loc.x)) (round (v.loc.y)), 5), ENEMY_MVT_TILES_PER_SEC))
	    if v.loc.y < 1 then
		v.state := NONEXISTENT
		enemies_through += 1
	    else
		request_new_target ()
	    end if
	end if

	v.cooldown -= 1
    end update

    %draw
    proc draw ()
	var dsc_x : int := round ((v.loc.x - 0.5) * PIXELS_PER_GRID)
	var dsc_y : int := round ((v.loc.y - 0.5) * PIXELS_PER_GRID)
	Draw.FillBox (dsc_x - 5, dsc_y - 5, dsc_x + 5, dsc_y + 5, brightred)
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

    proc assign_target (t : int)
	v.cur_target := t
    end assign_target

    body proc fire_projectile (var u : entity_vars)
	if not can_fire then
	    return
	end if

	proj_queue (next_proj_queue).target := u.ind
	proj_queue (next_proj_queue).target_type := u.class_type
	proj_queue (next_proj_queue).p_type := proj_enemies (v.e_type)
	proj_queue (next_proj_queue).loc := v.loc
	proj_queue (next_proj_queue).state := ALIVE

	u.effective_health -= proj_damage (proj_enemies (v.ind))

	next_proj_queue := (next_proj_queue mod PROJ_QUEUE_NUM) + 1
	num_proj_queue += 1
	if num_proj_queue >= PROJ_QUEUE_NUM then
	    can_fire := false
	end if
    end fire_projectile

end Enemy
