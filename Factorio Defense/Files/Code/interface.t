module Interface
    import Mouse, spawn_turret_from_topleft
    export var pervasive unqualified all


    forward proc apply_research_effects (rid : int)
    forward proc apply_effect (effect : string)

    % moves a variable towards a value by a percentage amount
    proc move_towards (var f : real, t, r : real)
	f += (t - f) * r
    end move_towards

    % normalizes production distributions and moves real production
    % towards user-requested production
    proc fix_int ()
	%tot_dist finds the total weights
	%dist_mult is then calculated from tot_dist, and is used to
	%normalize both production bars
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

	% move the real production bar 10% closer to the user-requested bar
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

	% normalize real production
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

    %updates the interface stats
    proc int_tick ()
	%before updating, make sure everything is working properly
	fix_int

	var t : real

	%this is the amount of production created every tick
	prod_avail := 0
	ticks_to_next_prod -= 1
	loop
	    exit when ticks_to_next_prod > 0

	    %this part uses some arithmetic to directly find how many
	    %production points you'll make
	    t := floor (max (-ticks_to_next_prod / ticks_per_prod, 1))
	    ticks_to_next_prod += t * ticks_per_prod

	    %if you ran out of electricity to sustain production, then
	    %production will falter to at most 60pt/sec
	    if electricity_stored > 0 then
		prod_avail += floor (t)
	    else
		prod_avail += min (floor (t), 1)
	    end if
	end loop

	%update production; use diminishing returns
	prod_per_tick += sqrt (prod_per_tick) / prod_per_tick * prod_distribution_prod * prod_avail / 600.0
	ticks_per_prod := 1.0 / prod_per_tick

	%update electricity
	%consumption is proportional to production
	electricity_consumption := prod_per_tick / 6.0
	%update the amount stored
	electricity_stored += (electricity_production - electricity_consumption) / 60.0
	%clamp storage between acceptable values
	if electricity_stored < 0 then
	    electricity_stored := 0
	elsif electricity_stored > electricity_storage then
	    electricity_stored := electricity_storage
	end if
	%production increases slowly according to production allocated
	electricity_production += prod_distribution_electricity * prod_avail / 60.0
	%increase the progress towards next accumulator
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

	%update walls
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
	    %if there's less than zero production needed to build a projectile,
	    %it draws electricity; if that's the case, it doesn't use ammunition
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
	    %check if research is done and, if so, clean it up
	    if prod_until_research_done (i) <= 0 then
		research_enabled (i) := false
		prod_distribution_research (i) := 0
		prod_distribution_research_user (i) := 0

		%handle research effects
		apply_research_effects (i)

		prereqs := true
	    end if
	end for
	%if a research was completed, check and enable those which are available.
	if prereqs then
	    check_research_prereqs
	end if
    end int_tick

    %wrapper for applying research effects
    body proc apply_research_effects (rid : int)
	apply_effect (research_effect (rid))
	apply_effect (research_effect_2 (rid))
    end apply_research_effects

    body proc apply_effect (effect : string)
	% hyphen means not applicable
	if effect (1) = "-" then
	    return
	end if
	%split the effects into tokens, then update values accordingly
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

    %this draws one segment of a production allocation bar,
    %updating relevant variables so that the next segment
    %can be easily drawn
    proc draw_part_of_bar (used_part : real, x, tot_h : int, var agg : real, var parts_passed, cur_y : int)
	cur_y := ALLOC_BEGIN - floor (agg * tot_h + 10 * parts_passed)
	agg += used_part
	parts_passed += 1
	var next_y := ALLOC_BEGIN - floor (agg * tot_h + 10 * parts_passed)
	Draw.FillBox (x, cur_y, x + 10, next_y, COLORS ((parts_passed - 1) mod NUM_COLORS + 1))
    end draw_part_of_bar

    %update pointer lists so that we don't need to have thousands
    %of if statements handling every case
    proc update_item_list
	%the lists are the y-values of items, the allocation of production of items,
	%and whether or not they're selectable.
	%production infrastructure is first, and not selectable
	cheat (addressint, prod_dist_ys (1)) := addr (prod_distribution_prod_y)
	cheat (addressint, prod_dist_allocs (1)) := addr (prod_distribution_prod_user)
	prod_dist_selectable (1) := false
	%electric generation infrastructure is second, and not selectable
	cheat (addressint, prod_dist_ys (2)) := addr (prod_distribution_electricity_y)
	cheat (addressint, prod_dist_allocs (2)) := addr (prod_distribution_electricity_user)
	prod_dist_selectable (2) := false
	%electricity storage infrastructure is third, and not selectable
	cheat (addressint, prod_dist_ys (3)) := addr (prod_distribution_electricity_storage_y)
	cheat (addressint, prod_dist_allocs (3)) := addr (prod_distribution_electricity_storage_user)
	prod_dist_selectable (3) := false
	%repair packs are fourth and selectable
	cheat (addressint, prod_dist_ys (4)) := addr (prod_distribution_repair_y)
	cheat (addressint, prod_dist_allocs (4)) := addr (prod_distribution_repair_user)
	prod_dist_selectable (4) := true
	%stone walls are fifth and selectable
	cheat (addressint, prod_dist_ys (5)) := addr (prod_distribution_wall_y)
	cheat (addressint, prod_dist_allocs (5)) := addr (prod_distribution_wall_user)
	prod_dist_selectable (5) := true
	var j : int := 6
	for i : 1 .. TURRET_T_NUM
	    % if the turret is enabled, then it'll show up, so update them; all turrets are selectable
	    if (turret_enabled (i)) then
		cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_turrets_y (i))
		cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_turrets_user (i))
		prod_dist_selectable (j) := true
		j += 1
		% if the projectile of the turret comes from ammunition (ie. not laser turret), then
		% update them; they aren't selectable
		if prod_per_proj (i) > 0 then
		    cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_proj_y (i))
		    cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_proj_user (i))
		    prod_dist_selectable (j) := false
		    j += 1
		end if
	    end if
	end for
	for i : 1 .. RESEARCH_NUM
	    % if the research in question is enabled, then update them accordingly
	    if (research_enabled (i)) then
		cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_research_y (i))
		cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_research_user (i))
		prod_dist_selectable (j) := false
		j += 1
	    else
		prod_distribution_research (i) := 0
	    end if
	end for
	% if the rocket has been researched, then update it accordingly
	if rocket_enabled then
	    cheat (addressint, prod_dist_ys (j)) := addr (prod_distribution_rocket_y)
	    cheat (addressint, prod_dist_allocs (j)) := addr (prod_distribution_rocket_user)
	    prod_dist_selectable (j) := false
	    j += 1
	end if
	% we end with one more than the total number of parts, so set the count
	% to one less than our index
	prod_dist_ys_count := j - 1

	% from here, update the aggregate allocation and the y-locations
	prod_dist_allocs_agg (0) := 0
	for i : 1 .. prod_dist_ys_count
	    prod_dist_allocs_agg (i) := prod_dist_allocs_agg (i - 1) + ^ (prod_dist_allocs (i))
	    prod_dist_allocs_ys (i) := floor (ALLOC_BEGIN - prod_dist_allocs_agg (i) * (ALLOC_HEIGHT - 10 * prod_dist_ys_count) - i * 10)
	end for
    end update_item_list

    % draw the entire interface, not counting that which is affected by the mouse
    proc draw_interface
	% background of interface
	Draw.FillBox (INTFC_BEGIN, 00, 1100, 800, 30)

	% str is a string to be drawn; spc counts the spacing for right-alignment, where necessary
	var str : string := frealstr (prod_per_tick * 60, 1, 1)
	var spc : int := (13 - length (str)) * NMRL_STR_WIDTH + PROD_STR_WIDTH
	% aggregate for allocation, variables for keeping track of where y-values go,
	% the total number of parts (for keeping track of the minimum 10-pixel grid),
	% and the total height
	var alloc_agg : real := 0
	var cur_y : int := ALLOC_BEGIN
	var next_y : int
	var num_parts : int := 5
	var tot_h : int
	% a dummy variable for when it's needed
	var dmmy : int

	% display production
	Font.Draw ("Production", INTFC_BEGIN + 30, 760, font, 18)
	Font.Draw (str, INTFC_BEGIN + 30 + spc, 760, font, black)

	% display electricity stored
	str := frealstr (electricity_stored, 1, 1)
	spc := (13 - length (str)) * NMRL_STR_WIDTH + PROD_STR_WIDTH
	Font.Draw ("Electricity Stored", INTFC_BEGIN + 30, 740, font, 18)
	Font.Draw (str + " / " + intstr (round (electricity_storage)), INTFC_BEGIN + 30 + spc, 740, font, black)

	% draw the bar for how much electricity is stored
	Draw.FillBox (INTFC_BEGIN + 30, 730, maxx - 30, 735, black)
	dmmy := floor ((maxx - INTFC_BEGIN - 62) * electricity_stored / electricity_storage + INTFC_BEGIN + 31)
	Draw.FillBox (INTFC_BEGIN + 31, 731, dmmy, 734, brightgreen)

	% count the number of parts (a bit redundant, but eh, whatever)
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

	%initialize before drawing the real production bar
	var parts_passed := 0
	tot_h := ALLOC_HEIGHT - 10 * num_parts

	%drawing the first five segments (fixed) of the real production bar
	draw_part_of_bar (prod_distribution_prod, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_electricity, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_electricity_storage, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_repair, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)
	draw_part_of_bar (prod_distribution_wall, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed, dmmy)

	%turrets, research, and rockets according to whether they're enabled/disabled
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
	% draw box around it so it's not just random color
	Draw.Box (ACTUAL_BEGIN - 1, ALLOC_BEGIN + 1, ACTUAL_BEGIN + 11, ALLOC_BEGIN - ALLOC_HEIGHT - 1, 23)

	% re-initialize
	parts_passed := 0
	alloc_agg := 0.0

	% draw fixed parts of the user-requested bar
	draw_part_of_bar (prod_distribution_prod_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_prod_y)
	draw_part_of_bar (prod_distribution_electricity_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_electricity_y)
	draw_part_of_bar (prod_distribution_electricity_storage_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_electricity_storage_y)
	draw_part_of_bar (prod_distribution_repair_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_repair_y)
	draw_part_of_bar (prod_distribution_wall_user, ACTUAL_BEGIN + 20, tot_h, alloc_agg, parts_passed, prod_distribution_wall_y)

	% draw non-fixed parts of the user-requested bar
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

	% make sure everything is done correct before moving list of items to accomodate for space
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

	% put a var here so i dont' have to write "INTFC_BEGIN + 50" all the time (didn't really work though)
	var cur_x : int := INTFC_BEGIN + 50

	% display production infrastructure stats (segment 1)
	parts_passed := 0
	Draw.FillBox (cur_x, prod_distribution_prod_y, cur_x + 50, prod_distribution_prod_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Production Infrastructure", cur_x + 60, prod_distribution_prod_y - 12, font, 18)
	% if out of electricity, draw in red and display warning; otherwise, as normal
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

	% display electric generation infrastructure stats (segment 2)
	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_electricity_y, cur_x + 50, prod_distribution_electricity_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Electric Generation Infrastructure", cur_x + 60, prod_distribution_electricity_y - 12, font, 18)
	str := frealstr (electricity_production, 1, 1)
	spc := (8 - length (str)) * NMRL_STR_WIDTH
	Font.Draw ("+", cur_x + 60, prod_distribution_electricity_y - 26, font, black)
	Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_electricity_y - 26, font, black)
	str := frealstr (electricity_consumption, 1, 1)
	spc := (8 - length (str)) * NMRL_STR_WIDTH
	% if we're running out (<60 sec left), display a warning; otherwise, as normal
	if electricity_consumption = electricity_production then
	    Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_electricity_y - 41, font, black)
	    Font.Draw ("-", cur_x + 60, prod_distribution_electricity_y - 41, font, black)
	elsif electricity_stored / (electricity_consumption - electricity_production) < 60 and electricity_consumption > electricity_production then
	    Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_electricity_y - 41, font, brightred)
	    Font.Draw ("-", cur_x + 60, prod_distribution_electricity_y - 41, font, brightred)
	else
	    Font.Draw (str + " per second", cur_x + 60 + spc, prod_distribution_electricity_y - 41, font, black)
	    Font.Draw ("-", cur_x + 60, prod_distribution_electricity_y - 41, font, black)
	end if

	% dislay electricity storage infrastructure stats (segment 3)
	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_electricity_storage_y, cur_x + 50, prod_distribution_electricity_storage_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Electricity Storage Infrastructure", cur_x + 60, prod_distribution_electricity_storage_y - 12, font, 18)
	dmmy := floor ((maxx - cur_x - 92) * (1000.0 - prod_until_next_e_storage) / 1000.0 + cur_x + 61)
	Draw.FillBox (cur_x + 60, prod_distribution_electricity_storage_y - 23, maxx - 30, prod_distribution_electricity_storage_y - 18, black)
	Draw.FillBox (cur_x + 61, prod_distribution_electricity_storage_y - 22, dmmy, prod_distribution_electricity_storage_y - 19, brightgreen)

	% dislay repair pack stats (segment 4)
	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_repair_y, cur_x + 50, prod_distribution_repair_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Repair Pack", cur_x + 60, prod_distribution_repair_y - 12, font, 18)
	dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_next_repair / prod_per_repair)) + cur_x + 61)
	Draw.FillBox (cur_x + 60, prod_distribution_repair_y - 23, maxx - 30, prod_distribution_repair_y - 18, black)
	Draw.FillBox (cur_x + 61, prod_distribution_repair_y - 22, dmmy, prod_distribution_repair_y - 19, brightgreen)
	Font.Draw (frealstr (num_repair_available, 1, 2), cur_x + 60, prod_distribution_repair_y - 37, font, black)

	% dislay stone wall stats (segment 5)
	parts_passed += 1
	Draw.FillBox (cur_x, prod_distribution_wall_y, cur_x + 50, prod_distribution_wall_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	Font.Draw ("Stone Wall", cur_x + 60, prod_distribution_wall_y - 12, font, 18)
	dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_next_wall / prod_per_wall)) + cur_x + 61)
	Draw.FillBox (cur_x + 60, prod_distribution_wall_y - 23, maxx - 30, prod_distribution_wall_y - 18, black)
	Draw.FillBox (cur_x + 61, prod_distribution_wall_y - 22, dmmy, prod_distribution_wall_y - 19, brightgreen)
	Font.Draw (intstr (num_wall_avail, 1), cur_x + 60, prod_distribution_wall_y - 37, font, black)

	% for each turret, display its stats
	for i : 1 .. TURRET_T_NUM
	    if turret_enabled (i) then
		parts_passed += 1
		Draw.FillBox (cur_x, prod_distribution_turrets_y (i), cur_x + 50, prod_distribution_turrets_y (i) - 50, COLORS (parts_passed mod NUM_COLORS + 1))
		Font.Draw (turret_names (i), cur_x + 60, prod_distribution_turrets_y (i) - 12, font, 18)
		dmmy := floor ((maxx - cur_x - 92) * (1.0 - (prod_until_next_turret (i) / prod_per_turret (i))) + cur_x + 61)
		Draw.FillBox (cur_x + 60, prod_distribution_turrets_y (i) - 23, maxx - 30, prod_distribution_turrets_y (i) - 18, black)
		Draw.FillBox (cur_x + 61, prod_distribution_turrets_y (i) - 22, dmmy, prod_distribution_turrets_y (i) - 19, brightgreen)
		Font.Draw (intstr (num_turrets_avail (i), 1), cur_x + 60, prod_distribution_turrets_y (i) - 37, font, black)

		% if the projectile of the turret uses ammunition, then display its stats as well
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
	% for every enabled research, display its stats
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

	% if the rocket has been researched, display its stats
	if rocket_enabled then
	    parts_passed += 1
	    Draw.FillBox (cur_x, prod_distribution_rocket_y, cur_x + 50, prod_distribution_rocket_y - 50, COLORS (parts_passed mod NUM_COLORS + 1))
	    Font.Draw ("Rocket", cur_x + 60, prod_distribution_rocket_y - 12, font, 18)
	    dmmy := floor ((maxx - cur_x - 92) * (1.0 - prod_until_rocket / 1000000.0) + cur_x + 61)
	    Draw.FillBox (cur_x + 60, prod_distribution_rocket_y - 23, maxx - 30, prod_distribution_rocket_y - 18, black)
	    Draw.FillBox (cur_x + 61, prod_distribution_rocket_y - 22, dmmy, prod_distribution_rocket_y - 19, brightgreen)
	    Font.Draw (intstr (ceil (prod_until_rocket), 1) + " left", cur_x + 60, prod_distribution_rocket_y - 37, font, black)
	end if

	% if something is selected, draw a border
	if prod_dist_selectable (mouse_over_item) then
	    Draw.Box (cur_x, ^ (prod_dist_ys (mouse_over_item)), cur_x + 50, ^ (prod_dist_ys (mouse_over_item)) - 50, white)
	end if
	if prod_dist_selectable (mouse_item_selected) then
	    Draw.Box (cur_x, ^ (prod_dist_ys (mouse_item_selected)), cur_x + 50, ^ (prod_dist_ys (mouse_item_selected)) - 50, black)
	end if
    end draw_interface

    proc handle_input
	var motion : string
	var x, y, bn, bud : int
	var bp : boolean
	loop
	    % dealing with Turing's terrible, terrible mouse event-handling
	    motion := "down"
	    bp := Mouse.ButtonMoved (motion)
	    if not bp then
		motion := "up"
		bp := Mouse.ButtonMoved (motion)
	    end if
	    exit when bp = false
	    Mouse.ButtonWait (motion, x, y, bn, bud)

	    % deselect user allocation bar if mouse released (it works on drag)
	    if bn = LEFT and motion = "up" then
		alloc_bar_selected := 0
	    end if

	    % check if we've selected a bar; if so, do the initializations
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

	    % check if we're selecting an item; if so, do the initializations
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

	% check for keyboard input: hotkey to [w]alls, [r]epair packs, and [p]ause
	var c : string (1)
	if hasch () then
	    getch (c)
	    if c = "w" or c = "W" then
		mouse_item_selected := 5
	    elsif c = "r" or c = "R" then
		mouse_item_selected := 4
	    elsif c = "p" or c = "P" then
		paused := not paused
	    end if
	end if

	% check if the mouse is on the user alloc bar
	Mouse.Where (x, y, bn)
	if (x > ACTUAL_BEGIN + 15 and x < ACTUAL_BEGIN + 35 and y < ALLOC_BEGIN + 5 and y > ALLOC_BEGIN - ALLOC_HEIGHT - 5) then
	    mouse_on_alloc_bar := true
	else
	    mouse_on_alloc_bar := false
	end if

	% check if the mouse is hovering over an item
	mouse_over_item := 1
	for i : 1 .. prod_dist_ys_count
	    if (x > ACTUAL_BEGIN + 50 and x < ACTUAL_BEGIN + 100 and y > ^ (prod_dist_ys (i)) - 50 and y < ^ (prod_dist_ys (i))) then
		mouse_over_item := i
		exit
	    end if
	end for

	% if the user allocation bar is selected, draw a bar that shows the range at which the mouse should go
	if alloc_bar_selected > 0 then
	    var part : int := bar_s_x - round (pd_at_selection * 200)
	    Draw.Line (part, bar_s_y, part + 200, bar_s_y, black)
	    Draw.Line (part, bar_s_y - 2, part, bar_s_y + 2, black)
	    Draw.Line (part + 200, bar_s_y - 2, part + 200, bar_s_y + 2, black)
	    ^ (prod_dist_allocs (alloc_bar_selected)) := min (1, max (0, (x - part) / 200))
	end if

	% handle mouse on the map
	if x < INTFC_BEGIN and x > 0 and y > 0 and y < MAP_HEIGHT * PIXELS_PER_GRID then
	    var mx : int := x div PIXELS_PER_GRID + 1
	    var my : int := y div PIXELS_PER_GRID + 1
	    % wall
	    if mouse_item_selected = 5 then
		% check if you have any available
		if num_wall_avail > 0 then
		    % check if the mouse button's down
		    if bn mod 10 = 1 then
			% check if it's within the build boundaries
			if mx >= MAP_B_W_L and mx <= MAP_B_W_U and my >= MAP_B_H_L and my <= MAP_B_H_U then
			    % check if it's not over another turret/wall
			    if map (mx) (my) -> class_type < TURRET then
				% put down the wall
				^ (map (mx) (my)) := make_ev (ALIVE, 350, 0, 0, 0, WALL, make_v (mx, my))
				ticks_to_repath -= 20
				num_wall_avail -= 1
			    else
				% draw an error
				Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 3, (my - 1) * PIXELS_PER_GRID + 3, (mx) * PIXELS_PER_GRID - 3, (my) * PIXELS_PER_GRID - 3, red)
			    end if
			else
			    % draw an error
			    Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 3, (my - 1) * PIXELS_PER_GRID + 3, (mx) * PIXELS_PER_GRID - 3, (my) * PIXELS_PER_GRID - 3, red)
			end if
		    else
			% check if it's within the build boundaries
			if mx >= MAP_B_W_L and mx <= MAP_B_W_U and my >= MAP_B_H_L and my <= MAP_B_H_U then
			    % check if it's not over another turret/wall
			    if map (mx) (my) -> class_type < TURRET then
				% draw a ghost
				Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 2, (my - 1) * PIXELS_PER_GRID + 2, (mx) * PIXELS_PER_GRID - 2, (my) * PIXELS_PER_GRID - 2, green)
			    else
				% draw an error
				Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 2, (my - 1) * PIXELS_PER_GRID + 2, (mx) * PIXELS_PER_GRID - 2, (my) * PIXELS_PER_GRID - 2, red)
			    end if
			else
			    % draw an error
			    Draw.FillBox ((mx - 1) * PIXELS_PER_GRID + 2, (my - 1) * PIXELS_PER_GRID + 2, (mx) * PIXELS_PER_GRID - 2, (my) * PIXELS_PER_GRID - 2, red)
			end if
		    end if
		end if
	    elsif mouse_item_selected = 4 then
		% repair packs; if over a damaged item, repair it to a maximum of 50 HP/tick (600/sec)
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
	    % do with turrets what we did with walls earlier
	    else
		for i : 1 .. TURRET_T_NUM
		    if mouse_item_selected = selection_num_turrets (i) and num_turrets_avail (i) > 0 then
			if mx >= MAP_B_W_L and mx < MAP_B_W_U and my > MAP_B_H_L and my <= MAP_B_H_U then
			    bp := true
			    for j : max (1, (mx - 1) div MAP_M_SIZ + 1) .. min (MAP_M_WID, mx div MAP_M_SIZ + 1)
				for k : max (1, (my - 2) div MAP_M_SIZ + 1) .. min (MAP_M_HEI, (my - 1) div MAP_M_SIZ + 1)
				    if map_meta_sem (j) (k) <= 0 then
					bp := false
				    end if
				end for
			    end for
			    if map (mx) (my) -> class_type < TURRET and
				    map (mx + 1) (my) -> class_type < TURRET and
				    map (mx) (my - 1) -> class_type < TURRET and
				    map (mx + 1) (my - 1) -> class_type < TURRET and bp then
				if bn mod 10 = 1 and can_build_turrets then
				    num_turrets_avail (i) -= 1
				    spawn_turret_from_topleft (mx, my, i)
				else
				    Draw.FillOval (mx * PIXELS_PER_GRID, (my - 1) * PIXELS_PER_GRID, PIXELS_PER_GRID - 2, PIXELS_PER_GRID - 2, green)
				end if
			    else
				Draw.FillOval (mx * PIXELS_PER_GRID, (my - 1) * PIXELS_PER_GRID, PIXELS_PER_GRID - 2, PIXELS_PER_GRID - 2, red)
			    end if
			else
			    Draw.FillOval (mx * PIXELS_PER_GRID, (my - 1) * PIXELS_PER_GRID, PIXELS_PER_GRID - 2, PIXELS_PER_GRID - 2, red)
			end if
			exit
		    end if
		end for
	    end if
	    
	    % remove buildings on the map (so long as it's not fire)
	    if bn div 100 = 1 then
		if map (mx) (my) -> class_type not= FIRE then
		    map (mx) (my) -> health := 0
		    map (mx) (my) -> effective_health := 0
		end if
	    end if
	end if
    end handle_input

    % hard coded strings for intro screen (sorry, i know, i was running out of time to think
    % of how to do it otherwise)
    var synopsis : array 1 .. 12 of string := init (
	"You have crashlanded on an unknown, alien planet.",
	"",
	"To escape, you must build a rocket. To build a",
	"rocket, you have built a factory.",
	"",
	"But the aliens do not take kindly to your pollution.",
	"You must keep them at bay, or your factory, and your",
	"hope, will be destroyed.",
	"",
	"Manage what your factory produces. Build turrets and",
	"ammunition to supply them. Research new technologies.",
	"And, finally, make sure they do not get in.")
    var turret_synopsises : array 1 .. 3 of array 1 .. 3 of string := init (
	init ("The gun turret is the most basic of turrets. Supplied by bullets,",
	"its power weakens as the aliens become stronger.", ""),
	init ("The flamethrower doesn't damage aliens directly; instead, it leaves",
	"the ground burning where its oil sacks land. As such, it's great for",
	"crowd control; beware, however, that it might destroy your own buildings."),
	init ("The laser turret is an amazing technological advance. It uses electricity",
	"to fire, bypassing most aliens' defenses. Just make sure you don't run out of",
	"electricity to fuel it with."))
    % draw and handle input at the intro screen
    fcn handle_intro_screen () : boolean
	% background
	Draw.FillBox (0, 0, 1100, 800, 28)
	
	% draw the title in a nice embossing
	var wid : int
	wid := Font.Width ("Factorio Defense", font)
	Font.Draw ("Factorio Defense", 550 - wid div 2 + 1, 699, font, darkgrey)
	Font.Draw ("Factorio Defense", 550 - wid div 2, 700, font, black)

	% draw the synopsis
	for i : 1 .. upper (synopsis)
	    Font.Draw (synopsis (i), 100, 640 - i * 20, font, black)
	end for

	% draw the turret descriptions
	for i : 1 .. 3
	    Draw.FillOval (580, 720 - i * 100, PIXELS_PER_GRID, PIXELS_PER_GRID, COLORS (colors_turrets (i)))
	    for j : 1 .. 3
		Font.Draw (turret_synopsises (i) (j), 600, 740 - i * 100 - j * 20, font, black)
	    end for
	end for

	% draw input instructions
	wid := Font.Width ("The game will begin when you place your first turret.", font)
	Font.Draw ("The game will begin when you place your first turret.", 550 - wid div 2, 240, font, black)
	wid := Font.Width ("Press [Space] to play.", font)
	Font.Draw ("Press [Space] to play.", 550 - wid div 2, 200, font, black)
	wid := Font.Width ("Alternatively, Press Q to quit.", font)
	Font.Draw ("Alternatively, Press Q to quit.", 550 - wid div 2, 180, font, black)
	
	% wait for input
	View.Update ()
	var c : string (1)
	loop
	    getch (c)
	    if c = "Q" or c = "q" then
		result false
	    elsif c = " " then
		result true
	    end if
	end loop
    end handle_intro_screen
end Interface
