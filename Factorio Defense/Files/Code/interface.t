module Interface
    export var pervasive unqualified all


    forward proc apply_research_effects (rid : int)
    forward proc apply_effect (effect : string)
    forward proc check_research_prereqs ()

    proc fix_int ()
	var tot_dist : real := 0
	var dist_mult : real
	tot_dist += prod_distribution_prod
	tot_dist += prod_distribution_electricity
	tot_dist += prod_distribution_electricity_storage
	tot_dist += prod_distribution_repair
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

	    if electricity_stored <= 0 then
		t := ticks_per_prod
	    else
		t := max (1, ticks_per_prod)
	    end if

	    t := floor (max (-ticks_to_next_prod / t, 1))
	    ticks_to_next_prod += t * ticks_per_prod
	    prod_avail += floor (t)
	end loop

	%update production
	prod_per_tick += sqrt (prod_distribution_prod * prod_avail) / 600.0
	ticks_per_prod := 1.0 / prod_per_tick

	%update electricity
	electricity_consumption := prod_per_tick / 60.0
	electricity_stored += electricity_production - electricity_consumption
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
	    tmp2 := index (effect (tmp .. *), " ") + 1
	    proj_damage (strint (effect (tmp .. tmp2 - 2))) := strint (effect (tmp2 .. *))
	elsif effect (1 .. 11) = "proj_sprite" then
	    tmp := index (effect, " ") + 1
	    tmp2 := index (effect (tmp .. *), " ") + 1
	    proj_sprite (strint (effect (tmp .. tmp2 - 2))) := strint (effect (tmp2 .. *))
	elsif effect (1 .. 14) = "reload_turrets" then
	    tmp := index (effect, " ") + 1
	    tmp2 := index (effect (tmp .. *), " ") + 1
	    reload_turrets (strint (effect (tmp .. tmp2 - 2))) := strint (effect (tmp2 .. *))
	elsif effect (1 .. 14) = "turret_enabled" then
	    turret_enabled (strint (effect (index (effect, " ") .. *))) := true
	elsif effect (1 .. 14) = "rocket_enabled" then
	    rocket_enabled := true
	end if
    end apply_effect

    proc draw_part_of_bar(used_part : real, x, tot_h : int, var agg : real, var parts_passed : int)
	var cur_y := ALLOC_BEGIN - floor(agg * tot_h + 10*parts_passed)
	agg += used_part
	parts_passed += 1
	var next_y := ALLOC_BEGIN - floor(agg * tot_h + 10*parts_passed)
	Draw.FillBox(x, cur_y, x + 10, next_y, COLORS((parts_passed -1)mod NUM_COLORS+1))
    end draw_part_of_bar
    
    proc draw_interface
	Draw.FillBox (INTFC_BEGIN, 00, 1100, 800, 30)

	var str : string := frealstr (prod_per_tick * 60, 1, 1)
	var spc : int := (15 - length (str)) * NMRL_STR_WIDTH + PROD_STR_WIDTH
	var alloc_agg : real := 0
	var cur_y : int := ALLOC_BEGIN
	var next_y : int
	var num_parts : int := 5
	var tot_h : int

	Font.Draw ("Production: ", INTFC_BEGIN + 30, 760, font, 18)
	Font.Draw (str, INTFC_BEGIN + 30 + spc, 760, font, black)

	str := frealstr (electricity_stored, 1, 1)
	spc := (15 - length (str)) * NMRL_STR_WIDTH + PROD_STR_WIDTH
	Font.Draw ("Electricity Stored: ", INTFC_BEGIN + 30, 740, font, 18)
	Font.Draw (str, INTFC_BEGIN + 30 + spc, 740, font, black)

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
	tot_h := ALLOC_HEIGHT - 10*num_parts
	
	draw_part_of_bar(prod_distribution_prod, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)
	draw_part_of_bar(prod_distribution_electricity, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)
	draw_part_of_bar(prod_distribution_electricity_storage, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)
	draw_part_of_bar(prod_distribution_repair, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)
	draw_part_of_bar(prod_distribution_wall, ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)

	for i : 1 .. TURRET_T_NUM
	    if (turret_enabled(i)) then
		draw_part_of_bar(prod_distribution_turrets(i), ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)
		if prod_per_proj(i) > 0 then
		    draw_part_of_bar(prod_distribution_proj(i), ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)
		end if
	    end if
	end for
	for i : 1 .. RESEARCH_NUM
	    if (research_enabled(i)) then
		draw_part_of_bar(prod_distribution_research(i), ACTUAL_BEGIN, tot_h, alloc_agg, parts_passed)
	    end if
	end for
	Draw.Box(ACTUAL_BEGIN -1, ALLOC_BEGIN+1,ACTUAL_BEGIN + 11, ALLOC_BEGIN - ALLOC_HEIGHT -1, 23)
    end draw_interface
end Interface
