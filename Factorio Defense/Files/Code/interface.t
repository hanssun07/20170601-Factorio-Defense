module Interface
    export var pervasive unqualified all

    proc fix_int ()
	var tot_dist := 0
	var dist_mult
	tot_dist += prod_distribution_prod
	tot_dist += prod_distribution_electricity
	tot_dist += prod_distribution_electricity_storage
	tot_dist += prod_distribution_repair
	tot_dist += prod_distribution_rocket
	for i : 1 .. TURRET_T_NUM
	    tot_dist += prod_distribution_turrets
	    tot_dist += prod_distribution_proj
	end for
	for i : 1 .. RESEARCH_NUM
	    tot_dist += prod_distribution_research
	end for
	
	dist_mult := 1.0/tot_dist
	prod_distribution_prod *= dist_mult
	prod_distribution_electricity *= dist_mult
	prod_distribution_electricity_storage *= dist_mult
	prod_distribution_repair *= dist_mult
	prod_distribution_rocket *= dist_mult
	for i : 1 .. TURRET_T_NUM
	    prod_distribution_turrets *= dist_mult
	    prod_distribution_proj *= dist_mult
	end for
	for i : 1 .. RESEARCH_NUM
	    prod_distribution_research *= dist_mult
	end for
    end fix_int
    
    proc int_tick ()
	fix_int
	
	prod_avail := 0
	ticks_to_next_prod -= 1
	loop
	    exit when ticks_to_next_prod > 0
	    
	    if electricity_stored <= 0 then
		ticks_to_next_prod += ticks_per_prod
	    else
		ticks_to_next_prod += max(1, ticks_per_prod)
	    end if
	    prod_avail += 1
	end loop
	
	%update production
	prod_per_tick += prod_distribution_prod * prod_avail / 600.0
	ticks_per_prod := 1.0/prod_per_tick
	
	%update electricity
	electricity_consumption := prod_per_tick / 60.0
	electricity_stored += electricity_production - electricity_consumption
	if electricity_stored < 0 then
	    electricity_stored := 0
	end if
	electricity_production += prod_distribution_electricity / 
	
    end int_tick
end Interface
