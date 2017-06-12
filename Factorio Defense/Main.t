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
    
    %prep phase
    var tick : int
    loop
	tick := Time.Elapsed

	% draw the map
	draw_map
	% interface
	draw_interface
	handle_input
	fix_int
	% check for win/lose-condition
	
	%tick done; render and wait
	View.Update
	
	exit when num_turrets > 0

	ticks_passed += 1
	delay (16 - Time.Elapsed + tick)
    end loop
    
    %game
    path_map
    loop
	tick := Time.Elapsed

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
	%if num_enemies <= 0 then
	    spawn_enemies
	%end if
	% update all projectiles
	for i : 1 .. PROJ_NUM
	    projectiles (i) -> update
	    projectiles (i) -> draw
	end for
	% do cleanups
	resolve_enemies
	resolve_projectiles
	resolve_targets
	ticks_to_repath -= 1
	if ticks_to_repath <= 0 then
	    ticks_to_repath += 600
	    path_map
	end if
	% interface
	int_tick
	draw_interface
	handle_input
	% check for win/lose-condition
	
	%tick done; render and wait
	View.Update

	ticks_passed += 1
	delay (16 - Time.Elapsed + tick)
    end loop
    % loop back to menu if play again
end loop


