module Interface
    import Mouse
    export var pervasive unqualified all


    forward proc apply_research_effects (rid : int)
    forward proc apply_effect (effect : string)
    forward proc check_research_prereqs ()

    proc move_towards (var f : real, t, r : real)
	f += (t - f) * r
    end move_towards

    proc fix_int ()
	var tot_dist : real := 0
	var dist_mult : real

	tot_dist += prod_distribution_prod_user
	tot_dist += prod_distribution_electricity_user
	tot_dist += prod_distribution_electricity_storage_user
	tot_dist += prod_distribution_repair_user
	tot_dist += prod_distribution_wall_user
	tot_dist += prod_distribution_rocket_user
	for i : 1 .. TURRET_T_NUM
	    tot_dist += prod_distribution_turrets_user (i)
	    tot_dist += prod_distribution_proj_user (i)
	end for
	for i : 1 .. RESEARCH_NUM
	    tot_dist += prod_distribution_research_user (i)
	end for

	if (tot_dist > 0) then
	    dist_mult := 1.0 / tot_dist
	else
	    dist_mult := 1.0
	end if
	prod_distribution_prod_user *= dist_mult
	prod_distribution_electricity_user *= dist_mult
	prod_distribution_electricity_storage_user *= dist_mult
	prod_distribution_repair_user *= dist_mult
	prod_distribution_wall_user *= dist_mult
	prod_distribution_rocket_user *= dist_mult
	for i : 1 .. TURRET_T_NUM
	    prod_distribution_turrets_user (i) *= dist_mult
	    prod_distribution_proj_user (i) *= dist_mult
	end for
	for i : 1 .. RESEARCH_NUM
	    prod_distribution_research_user (i) *= dist_mult
	end for

	move_towards (prod_distribution_prod, prod_distribution_prod_user, 0.1)
	move_towards (prod_distribution_electricity, prod_distribution_electricity_user, 0.1)
	move_towards (prod_distribution_electricity_storage, prod_distribution_electricity_storage_user, 0.1)
	move_towards (prod_distribution_repair, prod_distribution_repair_user, 0.1)
	move_towards (prod_distribution_wall, prod_distribution_wall_user, 0.1)
	move_towards (prod_distribution_rocket, prod_distribution_rocket_user, 0.1)
	for i : 1 .. TURRET_T_NUM
	    move_towards (prod_distribution_turrets (i), prod_distribution_turrets_user (i), 0.1)
	    move_towards (prod_distribution_proj (i), prod_distribution_proj_user (i), 0.1)
	end for
	for i : 1 .. RESEARCH_NUM
	    move_towards (prod_distribution_research (i), prod_distribution_research_user (i), 0.1)
	end for


	tot_dist := 0
	tot_dist += prod_distribution_prod
	tot_dist += prod_distribution_electricity
	tot_dist += prod_distribution_electricity_storage
	tot_dist += prod_distribution_repair
	tot_dist += prod_distribution_wall
	tot_dist += prod_distribution_rocket
	for i : 1 .. TURRET_T_NUM
	    tot_dist += prod_distribution_turrets (i)
	    tot_dist += prod_distribution_proj (i)
	end for
	for i : 1 .. RESEARCH_NUM
	    tot_dist += prod_distribution_research (i)
	end for

	dist_mult := 1.0 / tot_dist
	prod_distribution_prod *= dist_mult
	prod_distribution_electricity *= dist_mult
	prod_distribution_electricity_storage *= dist_mult
	prod_distribution_repair *= dist_mult
	prod_distribution_wall *= dist_mult
	prod_distribution_rocket *= dist_mult
	for i : 1 .. TURRET_T_NUM
	    prod_distribution_turrets (i) *= dist_mult
	    prod_distribution_proj (i) *= dist_mult
	end for
	for i : 1 .. RESEARCH_NUM
	    prod_distribution_research (i) *= dist_mult
	end for
    end fix_int

    proc int_tick ()
	fix_int

	var t : real

	prod_avail := 0
	ticks_to_next_prod -= 1
	loop
	    exit when ticks_to_next_prod > 0

	    t := floor (max (-ticks_to_next_prod / ticks_per_prod, 1))
	    ticks_to_next_prod += t * ticks_per_prod
	    if electricity_stored > 0 then
		prod_avail += floor (t)
	    else
		prod_avail += min (floor (t), 1)
	    end if
	end loop

	%update production
	prod_per_tick += sqrt (prod_per_tick) / prod_per_tick * prod_distribution_prod * prod_avail / 600.0
	ticks_per_prod := 1.0 / prod_per_tick

	%update electricity
	electricity_consumption := prod_per_tick / 6.0
	electricity_stored += (electricity_production - electricity_consumption) / 60.0
	if electricity_stored < 0 then
	    electricity_stored := 0
	elsif electricity_stored > electricity_storage then
	    electricity_stored := electricity_storage
	end if
	electricity_production += prod_distribution_electricity * prod_avail / 60.0
	loop
	    exit when prod_until_next_e_storage > 0
	    electricity_storage += 100.0
	    prod_until_next_e_storage += 1000.0
	end loop
	prod_until_next_e_storage -= prod_distribution_electricity_storage * prod_avail

	%update repair packs
	prod_until_next_repair -= prod_per_tick * prod_distribution_repair
	loop
	    exit when prod_until_next_repair > 0
	    prod_until_next_repair += prod_per_repair
	    num_repair_available += 1
	end loop

	prod_until_next_wall -= prod_per_tick * prod_distribution_wall
	loop
	    exit when prod_until_next_wall > 0
	    prod_until_next_wall += prod_per_wall
	    num_wall_avail += 1
	end loop

	%update rocket
	prod_until_rocket -= prod_distribution_rocket * prod_avail

	%update turrets and projectiles
	for i : 1 .. TURRET_T_NUM
	    prod_until_next_turret (i) -= prod_distribution_turrets (i) * prod_avail
	    prod_until_next_proj (i) -= prod_distribution_proj (i) * prod_avail
	    loop
		exit when prod_until_next_turret (i) > 0
		num_turrets_avail (i) += 1
		prod_until_next_turret (i) += prod_per_turret (i)
	    end loop
	    if prod_per_proj (i) > 0 then
		loop
		    exit when prod_until_next_proj (i) > 0
		    num_proj_avail (i) += 1
		    prod_until_next_proj (i) += prod_per_proj (i)
		end loop
	    end if
	end for

	%update research
	var prereqs : boolean := false
	for i : 1 .. RESEARCH_NUM
	    prod_until_research_done (i) -= prod_distribution_research (i) * prod_avail
	    if prod_until_research_done (i) <= 0 then
		research_enabled (i) := false
		prod_distribution_research (i) := 0
		prod_distribution_research_user (i) := 0

		%handle research effects
		apply_research_effects (i)

		prereqs := true
	    end if
	end for
	%if a research was completed, check and enabled those which are available.
	if prereqs then
	    check_research_prereqs
	end if
    end int_tick

    body proc check_research_prereqs ()
	var prereqs : boolean := false
	for i : 1 .. RESEARCH_NUM
	    prereqs := false
	    %only check if research in question isn't done
	    if prod_until_research_done (i) > 0 then
		prereqs := true
		%check the prereqs and mark false if one isn't met
		for j : 1 .. RESEARCH_NUM
		    if research_prereq (i) (j) and prod_until_research_done (j) > 0 then
			prereqs := false
		    end if
		end for
	    end if
	    %if all prereqs are met, enable
	    if prereqs then
		research_enabled (i) := true
	    end if
	end for
    end check_research_prereqs

    body proc apply_research_effects (rid : int)
	apply_effect (research_effect (rid))
	apply_effect (research_effect_2 (rid))
    end apply_research_effects

    body proc apply_effect (effect : string)
	if effect (1) = "-" then
	    return
	end if
	var tmp, tmp2 : int
	if effect (1 .. 11) = "proj_damage" then
	    tmp := index (effect, " ") + 1
	    tmp2 := index (effect (tmp .. *), " ") + tmp
	    proj_damage (strint (effect (tmp .. tmp2 - 2))) := strint (effect (tmp2 .. *))
	elsif effect (1 .. 11) = "proj_sprite" then
	    tmp := index (effect, " ") + 1
	    tmp2 := index (effect (tmp .. *), " ") + tmp
	    proj_sprite (strint (effect (tmp .. tmp2 - 2))) := strint (effect (tmp2 .. *))
	elsif effect (1 .. 14) = "reload_turrets" then
	    tmp := index (effect, " ") + 1
	    tmp2 := index (effect (tmp .. *), " ") + tmp
	    reload_turrets (strint (effect (tmp .. tmp2 - 2))) := strint (effect (tmp2 .. *))
	elsif effect (1 .. 14) = "turret_enabled" then
	    turret_enabled (strint (effect (index (effect, " ") .. *))) := true
	elsif effect (1 .. 14) = "rocket_enabled" then
	    rocket_enabled := true
	end if
    end apply_effect

    proc draw_part_of_bar (used_part : real, x, tot_h : int, var agg : real, var parts_passed, cur_y : int)
	cur_y := ALLOC_BEGIN - floor (agg * tot_h + 10 * parts_passed)
	agg += used_part
	parts_passed += 1
	var next_y := ALLOC_BEGIN - floor (agg * tot_h + 10 * parts_passed)
	Draw.FillBox (x, cur_y, x + 10, next_y, COLORS ((parts_passed - 1) mod NUM_COLORS + 1))
    end draw_part_of_bar

    proc update_item_list
	cheat (addressint, prod_dist_ys (1)) := addr (prod_distribution_prod_y)
	cheat (addressint, prod_dist_allocs (1)) := addr (prod_distribution_prod_user)
	prod_dist_selectable (1) := false
	cheat (addressint, prod_dist_ys (2)) := addr (prod_distribution_electricity_y)
	cheat (addressint, prod_dist_allocs (2)) := addr (prod_distribution_electricity_user)
	prod_dist_selectable (2) := false
	cheat (addressint, prod_dist_ys (3)) := addr (prod_distribution_electricity_storage_y)
	cheat (addressint, prod_dist_allocs (3)) := addr (prod_distribution_electricity_storage_user)
	prod_dist_selectable (3) := false
	cheat (addressint, prod_dist_ys (4)) := addr (prod_distribution_repair_y)
	cheat (addressint, prod_dist_allocs (4)) := addr (prod_distribution_repair_user)
	prod_dist_selectable (4) := true
	cheat (addressint, prod_dist_ys (5)) := addr (prod_distribution_wall_y)
	cheat (addressint, prod_dist_allocs (5)) := addr (prod_distribution_wall_user)
	prod_dist_selectable (5) := true
	var j : int := 6
	for i : 1 .. TURRET_T_NUM
	    if (turret_enabled (i)) then
		cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_turrets_y (i))
		cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_turrets_user (i))
		prod_dist_selectable (j) := true
		j += 1
		if prod_per_proj (i) > 0 then
		    cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_proj_y (i))
		    cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_proj_user (i))
		    prod_dist_selectable (j) := false
		    j += 1
		end if
	    end if
	end for
	for i : 1 .. RESEARCH_NUM
	    if (research_enabled (i)) then
		cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_research_y (i))
		cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_research_user (i))
		prod_dist_selectable (j) := false
		j += 1
	    else
		prod_distribution_research (i) := 0
	    end if
	end for
	if rocket_enabled then
	    cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_rocket_y)
	    cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_rocket_user)
	    prod_dist_selectable (j) := false
	    j += 1
	end if
	prod_dist_ys_count := j - 1

	prod_dist_allocs_agg (0) := 0
	for i : 1 .. prod_dist_ys_count
	    prod_dist_allocs_agg (i) := prod_dist_allocs_agg (i - 1) + ^ (prod_dist_allocs (i))
	    prod_dist_allocs_ys (i) := floor (ALLOC_BEGIN - prod_dist_allocs_agg (i) * (ALLOC_HEIGHT - 10 * prod_dist_ys_count) - i * 10)
	end for
    end update_item_list

    %beginning of draw_interface ******************************************
    %^ this is so I can find this easily while scrolling ******************
    %**********************************************************************
    proc draw_interface
	Draw.FillBox (INTFC_BEGIN, 00, 1100, 800, 30)

	var str : string := frealstr (prod_per_tick * 60, 1, 1)
	var spc : int := (13 - length (str)) * NMRL_STR_WIDTH + PROD_STR_WIDTH
	var alloc_agg : real := 0
	var cur_y : int := ALLOC_BEGIN
	var next_y : int
	var num_parts : int := 5
	var tot_h : int
	var dmmy : int

	Font.Draw ("Production", INTFC_BEGIN + 30, 760, font, 18)
	Font.Draw (str, INTFC_BEGIN + 30 + spc, 760, font, black)

	str := frealstr (electricity_stored, 1, 1)
	spc := (13 - length (str)) * NMRL_STR_WIDTH + PROD_STR_WIDTH
	Font.Draw ("Electricity Stored", INTFC_BEGIN + 30, 740, font, 18)
	Font.Draw (str + " / " + intstr (round (electricity_storage)), INTFC_BEGIN + 30 + spc, 740, font, black)

	Draw.FillBox (INTFC_BEGIN + 30, 730, maxx - 30, 735, black)
	dmmy := floor ((maxx - INTFC_BEGIN - 62) * electricity_stored / electricity_storage + INTFC_BEGIN + 31)
	Draw.FillBox (INTFC_BEGIN + 31, 731, dmmy, 734, brightgreen)

	for i : 1 .. TURRET_T_NUM
	    if turret_enabled (i) then
		num_parts += 1
		if prod_per_proj (i) > 0 then
		    num_parts += 1
		end if
	    end if
	end for
	for i : 1 .. RESEARCH_NUM
	    if research_enabled (i) then
		num_parts += 1
	    end if
	end for
	if rocket_enabled then
	    num_parts += 1
	end if

	var parts_passed := 0
	tot_h := ALLOC_HEIGHT - 10 * num_parts

	draw_part_of_bar (prod_distribution_prod, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_electricity, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_electricity_storage, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_repair, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_wall, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)

	for i : 1 .. TURRET_T_NUM
	    if (turret_enabled (i)) then
		draw_part_of_bar (prod_distribution_turrets (i), ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
		if prod_per_proj (i) > 0 then
		    draw_part_of_bar (prod_distribution_proj (i), ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
		end if
	    end if
	end for
	for i : 1 .. RESEARCH_NUM
	    if (research_enabled (i)) then
		draw_part_of_bar (prod_distribution_research (i), ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	    end if
	end for
	if rocket_enabled then
	    draw_part_of_bar (prod_distribution_rocket, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	end if
	Draw.Box (ACTUAL_BEGIN - 1, ALLOC_BEGIN + 1, ACTUAL_BEGIN + 11, ALLOC_BEGIN - ALLOC_HEIGHT - 1, 23)

	parts_passed := 0
	alloc_agg := 0.0

	draw_part_of_bar (prod_distribution_prod_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_prod_y)
	draw_part_of_bar (prod_distribution_electricity_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_electricity_y)
	draw_part_of_bar (prod_distribution_electricity_storage_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_electricity_storage_y)
	draw_part_of_bar (prod_distribution_repair_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_repair_y)
	draw_part_of_bar (prod_distribution_wall_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_wall_y)

	for i : 1 .. TURRET_T_NUM
	    if (turret_enabled (i)) then
		draw_part_of_bar (prod_distribution_turrets_user (i), ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_turrets_y (i))
		if prod_per_proj (i) > 0 then
		    draw_part_of_bar (prod_distribution_proj_user (i), ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_proj_y (i))
		end if
	    end if
	end for
	for i : 1 .. RESEARCH_NUM
	    if (research_enabled (i)) then
		draw_part_of_bar (prod_distribution_research_user (i), ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_research_y (i))
	    end if
	end for
	if rocket_enabled then
	    draw_part_of_bar (prod_distribution_rocket_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_rocket_y)
	end if
	Draw.Box (ACTUAL_BEGIN + 19, ALLOC_BEGIN + 1, ACTUAL_BEGIN + 31, ALLOC_BEGIN - ALLOC_HEIGHT - 1, 23)
	if mouse_on_alloc_bar then
	    Draw.Box (ACTUAL_BEGIN + 18, ALLOC_BEGIN + 2, ACTUAL_BEGIN + 32, ALLOC_BEGIN - ALLOC_HEIGHT - 2, white)
	end if

	update_item_list
	var moved : boolean := false
	var db : int := min (50, floor (ALLOC_HEIGHT / (num_parts + 2)))
	^ (prod_dist_ys (num_parts)) := max ( ^ (prod_dist_ys (num_parts)), db)
	var n : int := 0
	loop
	    n += 1
	    for i : 1 .. num_parts - 2
		if ^ (prod_dist_ys (i)) - db < ^ (prod_dist_ys (i + 1)) then
		    ^ (prod_dist_ys (i + 1)) := ^ (prod_dist_ys (i)) - db
		    moved := true
		end if
	    end for
	    for decreasing i : num_parts .. 3
		if ^ (prod_dist_ys (i)) + db > ^ (prod_dist_ys (i - 1)) then
		    ^ (prod_dist_ys (i - 1)) := ^ (prod_dist_ys (i)) + db
		    moved := true
		end if
	    end for
	    exit when moved = false
	    exit when n > 100
	    moved := false
	end loop

	var cur_x : int := INTFC_BEGIN + 50

	parts_passed := 0
	Draw.FillBox (cur_x, prod_distribution_prod_y, cur_x + 50, prod_distribution_prod_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Production Infrastructure", cur_x + 60, prod_distribution_prod_y - 12, font, 18)
	if electricity_stored <= 0 and ticks_per_prod < 1 then
	    str := frealstr (sqrt (prod_per_tick) / prod_per_tick * prod_distribution_prod * 10.0, 1, 1)
	    spc := (8 - length (str)) * NMRL_STR_WIDTH
	    Font.Draw ("+", cur_x + 60, prod_distribution_prod_y - 26, font, brightred)
	    Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_prod_y - 26, font, brightred)
	    Font.Draw ("Electricity Low!", cur_x + 60, prod_distribution_prod_y - 41, font, brightred)
	else
	    str := frealstr (sqrt (prod_per_tick) * prod_distribution_prod * 10.0, 1, 1)
	    spc := (8 - length (str)) * NMRL_STR_WIDTH
	    Font.Draw ("+", cur_x + 60, prod_distribution_prod_y - 26, font, black)
	    Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_prod_y - 26, font, black)
	end if

	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_electricity_y, cur_x + 50, prod_distribution_electricity_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Electric Generation Infrastructure", cur_x + 60, prod_distribution_electricity_y - 12, font, 18)
	str := frealstr (electricity_production, 1, 1)
	spc := (8 - length (str)) * NMRL_STR_WIDTH
	Font.Draw ("+", cur_x + 60, prod_distribution_electricity_y - 26, font, black)
	Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_electricity_y - 26, font, black)
	str := frealstr (electricity_consumption, 1, 1)
	spc := (8 - length (str)) * NMRL_STR_WIDTH
	if electricity_stored / (electricity_consumption - electricity_production) < 60 and electricity_consumption > electricity_production then
	    Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_electricity_y - 41, font, brightred)
	    Font.Draw ("-", cur_x + 60, prod_distribution_electricity_y - 41, font, brightred)
	else
	    Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_electricity_y - 41, font, black)
	    Font.Draw ("-", cur_x + 60, prod_distribution_electricity_y - 41, font, black)
	end if

	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_electricity_storage_y, cur_x + 50, prod_distribution_electricity_storage_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Electricity Storage Infrastructure", cur_x + 60, prod_distribution_electricity_storage_y - 12, font, 18)
	dmmy := floor ((maxx - cur_x - 92) * (1000.0 - prod_until_next_e_storage) / 1000.0 + cur_x + 61)
	Draw.FillBox (cur_x + 60, prod_distribution_electricity_storage_y - 23, maxx - 30, prod_distribution_electricity_storage_y - 18, black)
	Draw.FillBox (cur_x + 61, prod_distribution_electricity_storage_y - 22, dmmy, prod_distribution_electricity_storage_y - 19, brightgreen)

	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_repair_y, cur_x + 50, prod_distribution_repair_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Repair Pack", cur_x + 60, prod_distribution_repair_y - 12, font, 18)
	dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_next_repair / prod_per_repair)) + cur_x + 61)
	Draw.FillBox (cur_x + 60, prod_distribution_repair_y - 23, maxx - 30, prod_distribution_repair_y - 18, black)
	Draw.FillBox (cur_x + 61, prod_distribution_repair_y - 22, dmmy, prod_distribution_repair_y - 19, brightgreen)
	Font.Draw (frealstr (num_repair_available, 1, 2), cur_x + 60, prod_distribution_repair_y - 37, font, black)

	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_wall_y, cur_x + 50, prod_distribution_wall_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Stone Wall", cur_x + 60, prod_distribution_wall_y - 12, font, 18)
	dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_next_wall / prod_per_wall)) + cur_x + 61)
	Draw.FillBox (cur_x + 60, prod_distribution_wall_y - 23, maxx - 30, prod_distribution_wall_y - 18, black)
	Draw.FillBox (cur_x + 61, prod_distribution_wall_y - 22, dmmy, prod_distribution_wall_y - 19, brightgreen)
	Font.Draw (intstr (num_wall_avail, 1), cur_x + 60, prod_distribution_wall_y - 37, font, black)

	for i : 1 .. TURRET_T_NUM
	    if turret_enabled (i) then
		parts_passed += 1
		Draw.FillBox (cur_x, prod_distribution_turrets_y (i), cur_x + 50, prod_distribution_turrets_y (i) - 50, COLORS (parts_passed mod NUM_COLORS + 1))
		Font.Draw (turret_names (i), cur_x + 60, prod_distribution_turrets_y (i) - 12, font, 18)
		dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_next_turret (i) / prod_per_turret (i))) + cur_x + 61)
		Draw.FillBox (cur_x + 60, prod_distribution_turrets_y (i) - 23, maxx - 30, prod_distribution_turrets_y (i) - 18, black)
		Draw.FillBox (cur_x + 61, prod_distribution_turrets_y (i) - 22, dmmy, prod_distribution_turrets_y (i) - 19, brightgreen)
		Font.Draw (intstr (num_turrets_avail (i), 1), cur_x + 60, prod_distribution_turrets_y (i) - 37, font, black)

		if prod_per_proj (i) > 0 then
		    parts_passed += 1
		    Draw.FillBox (cur_x, prod_distribution_proj_y (i), cur_x + 50, prod_distribution_proj_y (i) - 50, COLORS (parts_passed mod NUM_COLORS + 1))
		    Font.Draw (proj_names (i), cur_x + 60, prod_distribution_proj_y (i) - 12, font, 18)
		    dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_next_proj (i) / prod_per_proj (i))) + cur_x + 61)
		    Draw.FillBox (cur_x + 60, prod_distribution_proj_y (i) - 23, maxx - 30, prod_distribution_proj_y (i) - 18, black)
		    Draw.FillBox (cur_x + 61, prod_distribution_proj_y (i) - 22, dmmy, prod_distribution_proj_y (i) - 19, brightgreen)
		    Font.Draw (intstr (num_proj_avail (i), 1), cur_x + 60, prod_distribution_proj_y (i) - 37, font, black)
		end if
	    end if
	end for
	for i : 1 .. RESEARCH_NUM
	    if research_enabled (i) then
		parts_passed += 1
		Draw.FillBox (cur_x, prod_distribution_research_y (i), cur_x + 50, prod_distribution_research_y (i) - 50, COLORS (parts_passed mod NUM_COLORS + 1))
		Font.Draw (research_name (i), cur_x + 60, prod_distribution_research_y (i) - 12, font, 18)
		dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_research_done (i) / prod_per_research (i))) + cur_x + 61)
		Draw.FillBox (cur_x + 60, prod_distribution_research_y (i) - 23, maxx - 30, prod_distribution_research_y (i) - 18, black)
		Draw.FillBox (cur_x + 61, prod_distribution_research_y (i) - 22, dmmy, prod_distribution_research_y (i) - 19, brightgreen)
		Font.Draw (intstr (ceil (prod_until_research_done (i)), 1) + " left", cur_x + 60, prod_distribution_research_y (i) - 37, font, black)
	    end if
	end for

	if rocket_enabled then
	    parts_passed += 1
	    Draw.FillBox (cur_x, prod_distribution_rocket_y, cur_x + 50, prod_distribution_rocket_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	    Font.Draw ("Rocket", cur_x + 60, prod_distribution_rocket_y - 12, font, 18)
	    dmmy := floor ((maxx - cur_x - 92) * (1.0 - prod_until_rocket / 1000000.0) + cur_x + 61)
	    Draw.FillBox (cur_x + 60, prod_distribution_rocket_y - 23, maxx - 30, prod_distribution_rocket_y - 18, black)
	    Draw.FillBox (cur_x + 61, prod_distribution_rocket_y - 22, dmmy, prod_distribution_rocket_y - 19, brightgreen)
	    Font.Draw (intstr (ceil (prod_until_rocket), 1) + " left", cur_x + 60, prod_distribution_rocket_y - 37, font, black)
	end if
	if prod_dist_selectable (mouse_over_item) then
	    Draw.Box (cur_x, ^ (prod_dist_ys (mouse_over_item)), cur_x + 50, ^ (prod_dist_ys (mouse_over_item)) - 50, white)
	end if
	if prod_dist_selectable (mouse_item_selected) then
	    Draw.Box (cur_x, ^ (prod_dist_ys (mouse_item_selected)), cur_x + 50, ^ (prod_dist_ys (mouse_item_selected)) - 50, black)
	end if
    end draw_interface

    proc handle_input
	/*
	 if electricity_production > electricity_consumption then
	 prod_distribution_electricity_user := 0
	 else
	 prod_distribution_electricity_user := 1
	 end if
	 for i : 1 .. RESEARCH_NUM
	 if research_enabled (i) then
	 prod_distribution_research_user (i) := 0.1
	 else
	 prod_distribution_research_user (i) := 0.0
	 end if
	 end for*/

	var motion : string
	var x, y, bn, bud : int
	var bp : boolean
	loop
	    motion := "down"
	    bp := Mouse.ButtonMoved (motion)
	    if not bp then
		motion := "up"
		bp := Mouse.ButtonMoved (motion)
	    end if
	    exit when bp = false
	    Mouse.ButtonWait (motion, x, y, bn, bud)
	    if bn = LEFT and motion = "up" then
		alloc_bar_selected := 0
	    end if

	    if (bn = LEFT and motion = "down" and x > ACTUAL_BEGIN + 15 and x < ACTUAL_BEGIN + 35 and y < ALLOC_BEGIN + 5 and y > ALLOC_BEGIN - ALLOC_HEIGHT - 5) then
		for i : 1 .. prod_dist_ys_count
		    if y >= prod_dist_allocs_ys (i) then
			alloc_bar_selected := i
			pd_at_selection := ^ (prod_dist_allocs (i))
			bar_s_x := x
			bar_s_y := y
			exit
		    end if
		end for
	    else
		alloc_bar_selected := 0
	    end if

	    if x > INTFC_BEGIN then
		mouse_item_selected := 1
		if bn = LEFT then
		    for i : 1 .. prod_dist_ys_count
			if (x > ACTUAL_BEGIN + 50 and x < ACTUAL_BEGIN + 100 and y > ^ (prod_dist_ys (i)) - 50 and y < ^ (prod_dist_ys (i))) then
			    mouse_item_selected := i
			    exit
			end if
		    end for
		end if
	    end if
	end loop

	Mouse.Where (x, y, bn)
	if (x > ACTUAL_BEGIN + 15 and x < ACTUAL_BEGIN + 35 and y < ALLOC_BEGIN + 5 and y > ALLOC_BEGIN - ALLOC_HEIGHT - 5) then
	    mouse_on_alloc_bar := true
	else
	    mouse_on_alloc_bar := false
	end if

	mouse_over_item := 1
	for i : 1 .. prod_dist_ys_count
	    if (x > ACTUAL_BEGIN + 50 and x < ACTUAL_BEGIN + 100 and y > ^ (prod_dist_ys (i)) - 50 and y < ^ (prod_dist_ys (i))) then
		mouse_over_item := i
		exit
	    end if
	end for

	if alloc_bar_selected > 0 then
	    put alloc_bar_selected, prod_dist_allocs_ys (alloc_bar_selected)
	    var part : int := bar_s_x - round (pd_at_selection * 200)
	    Draw.Line (part, bar_s_y, part + 200, bar_s_y, black)
	    Draw.Line (part, bar_s_y - 2, part, bar_s_y + 2, black)
	    Draw.Line (part + 200, bar_s_y - 2, part + 200, bar_s_y + 2, black)
	    ^ (prod_dist_allocs (alloc_bar_selected)) := min (1, max (0, (x - part) / 200))
	end if

	if x < INTFC_BEGIN then
	    var mx : int := x div PIXELS_PER_GRID + 1
	    var my : int := y div PIXELS_PER_GRID + 1
	    if mouse_item_selected = 5 then
		if num_wall_avail > 0 then
		    if bn mod 10 = 1 then
			if mx >= MAP_B_W_L and mx <= MAP_B_W_U and my >= MAP_B_H_L and my <= MAP_B_H_U then
			    if map (mx) (my) -> class_type < TURRET then
				^ (map (mx) (my)) := make_ev (ALIVE, 350, 0, 0, 0, WALL, make_v (mx, my))
				ticks_to_repath -= 20
				num_wall_avail -= 1
			    else
				Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 3, (my - 1) * PIXELS_PER_GRID + 3, (mx) * PIXELS_PER_GRID - 3, (my) * PIXELS_PER_GRID - 3, red)
			    end if
			else
			    Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 3, (my - 1) * PIXELS_PER_GRID + 3, (mx) * PIXELS_PER_GRID - 3, (my) * PIXELS_PER_GRID - 3, red)
			end if
		    else
			if mx >= MAP_B_W_L and mx <= MAP_B_W_U and my >= MAP_B_H_L and my <= MAP_B_H_U then
			    if map (mx) (my) -> class_type < TURRET then
				Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 2, (my - 1) * PIXELS_PER_GRID + 2, (mx) * PIXELS_PER_GRID - 2, (my) * PIXELS_PER_GRID - 2, green)
			    else
				Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 2, (my - 1) * PIXELS_PER_GRID + 2, (mx) * PIXELS_PER_GRID - 2, (my) * PIXELS_PER_GRID - 2, red)
			    end if
			else
			    Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 2, (my - 1) * PIXELS_PER_GRID + 2, (mx) * PIXELS_PER_GRID - 2, (my) * PIXELS_PER_GRID - 2, red)
			end if
		    end if
		end if
	    elsif mouse_item_selected = 4 then
		if bn mod 10 = 1 then
		    if map (mx) (my) -> class_type = TURRET then
			for i : 1 .. 50
			    exit when map (mx) (my) -> health >= max_healths_turrets (map (mx) (my) -> e_type)
			    exit when num_repair_available <= 0.01
			    map (mx) (my) -> health += 1
			    map (mx) (my) -> effective_health += 1
			    num_repair_available -= 0.01
			end for
		    elsif map (mx) (my) -> class_type = WALL then
			for i : 1 .. 50
			    exit when map (mx) (my) -> health >= 350
			    exit when num_repair_available <= 0.01
			    map (mx) (my) -> health += 1
			    map (mx) (my) -> effective_health += 1
			    num_repair_available -= 0.01
			end for
		    end if
		end if
	    end if
	end if

    end handle_input
end Interface
