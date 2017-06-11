%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Programmer:    Hans Sun
%Program Name:  Factorio Defense
%Date:          2017-05-12
%Course:        ICS3CU1  Final Project 15%
%Teacher:       M. Ianni
%Descriptions:  Factorio-inspired RTS-style, TD-style game
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% files/code folder
include "files/code/includes.t"
setscreen ("graphics:1100;800")
View.Set ("offscreenonly")


loop
    % load everything
    startup_init
    read_data

    % display and handle menu screen
    % initialize game
    begin_init
    path_map
    
    turret_enabled(2) := true

    var tick : int
    loop
	tick := Time.Elapsed

	% check for input
	% draw the map
	update_map
	draw_map
	% update all turrets
	for i : 1 .. last_turret
	    turrets (i) -> update
	    turrets (i) -> draw
	end for
	% update all enemies
	for i : 1 .. ENEMY_NUM
	    enemies (i) -> pre_update
	end for
	for i : 1 .. ENEMY_NUM
	    enemies (i) -> update
	    enemies (i) -> draw
	end for
	% update all projectiles
	for i : 1 .. PROJ_NUM
	    projectiles (i) -> update
	    projectiles (i) -> draw
	end for
	% update all stats
	% do cleanups
	resolve_enemies
	resolve_projectiles
	%if last_turret not= num_turrets then
	%    resolve_turrets
	%end if
	resolve_targets
	% check for win/lose-condition

	%e -> draw
	%e -> update (e -> v)

	for i : 1 .. Rand.Int (-5, 1)
	    spawn_enemy (Rand.Int (1, 4) + Rand.Int (0, 1) * 4)
	end for
	if Rand.Real () <= 0.00 then
	    for i : 1 .. MAP_WIDTH
		for j : 1 .. MAP_HEIGHT
		    map_deaths (i) (j) -= .027777
		    if map_deaths (i) (j) < 0 then
			map_deaths (i) (j) := 0
		    end if
		end for
	    end for
	    path_map
	end if

	resolve_enemies

	locate (1, 102)
	put num_enemies : 5 ..

	for i : 1 .. 0
	    for j : 1 .. 10
		locate (50 - (j * 5 - 3), i * 10 - 5)
		put map_meta_sem (i) (j) ..
	    end for
	end for

	%prod_per_tick *= 1.01
	int_tick
	draw_interface
	handle_input

	View.Update
	%exit when e -> v.state = NONEXISTENT

	ticks_to_repath -= 1
	if ticks_to_repath <= 0 then
	    ticks_to_repath += 600
	    path_map
	end if

	ticks_passed += 1
	delay (16 - Time.Elapsed + tick)
    end loop
    % loop back to menu if play again
end loop


