class Turret
    export var all

    var v : entity_vars
    var kills : int
    var damage_dealt : int

    forward proc request_new_target ()
    forward proc fire_projectile (var u : entity_vars)

    proc initialize (i, tt : int, l : point)
	if tt > 0 then
	    v.cooldown := reload_turrets (tt)
	    v.health := max_healths_turrets (tt)
	else
	    v.cooldown := 1000
	    v.health := 0
	end if
	v.ind := i
	v.cur_target := 0
	v.state := ALIVE
	v.effective_health := v.health
	kills := 0
	damage_dealt := 0
	v.e_type := tt
	v.loc := l
	v.class_type := TURRET
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
	    elsif distance_squared (v.loc, u.loc) > range_turrets (v.e_type) ** 2 then
		request_new_target ()
	    else
		if v.cooldown <= 0 then
		    fire_projectile (u)
		end if
	    end if
	else
	    request_new_target ()
	end if
	v.cooldown -= 1
    end update

    %draw
    proc draw ()

    end draw

    body proc request_new_target ()
	if v.cooldown < 0 and v.cooldown > -6 then
	    return
	end if
	if not turret_on_standby (v.ind) then
	    turret_on_standby (v.ind) := true
	    turrets_on_standby += 1
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
	proj_queue (next_proj_queue).p_type := proj_turrets (v.e_type)
	proj_queue (next_proj_queue).loc := v.loc
	proj_queue (next_proj_queue).state := ALIVE

	damage_dealt += proj_damage (proj_turrets (v.ind))
	u.effective_health -= proj_damage (proj_turrets (v.ind))
	if u.effective_health <= 0 then
	    kills += 1
	end if

	next_proj_queue := (next_proj_queue mod PROJ_QUEUE_NUM) + 1
	num_proj_queue += 1
	if num_proj_queue >= PROJ_QUEUE_NUM then
	    can_fire := false
	end if
    end fire_projectile

end Turret
