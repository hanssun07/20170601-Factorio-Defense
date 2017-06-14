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
setscreen ("graphics:1100;800,nocursor,nobuttonbar,noecho")
View.Set ("offscreenonly,title:Factorio Defense")


% load everything
startup_init
read_data

loop
    % initialize game
    begin_init

    % display and handle menu screen
    if not handle_intro_screen () then
	exit
    end if

    % prep phase: no enemies and no need to update;
    % continue when first turret is placed
    var tick : int
    loop
	tick := Time.Elapsed

	% draw the map
	draw_map
	% interface
	draw_interface
	handle_input
	fix_int

	%tick done; render and wait
	View.Update

	%check for progress
	exit when num_turrets > 0

	delay (16 - Time.Elapsed + tick)
    end loop
    
    % give enemies a path
    path_map
    
    % start playing music
    in_game := true
    play_bgm
    
    % game
    loop
	tick := Time.Elapsed

	% draw the map
	if not paused then
	    update_map
	end if
	draw_map
	
	% update all turrets
	for i : 1 .. last_turret
	    if not paused then
		turrets (i) -> update
	    end if
	    turrets (i) -> draw
	end for
	
	% update all enemies
	for i : 1 .. ENEMY_NUM
	    % the pre-update prevents throttling
	    enemies (i) -> pre_update
	end for
	for i : 1 .. ENEMY_NUM
	    if not paused then
		enemies (i) -> update
	    end if
	    enemies (i) -> draw
	end for
	if not paused then
	    spawn_enemies
	end if
	
	% update all projectiles
	for i : 1 .. PROJ_NUM
	    if not paused then
		projectiles (i) -> update
	    end if
	    projectiles (i) -> draw
	end for
	% do cleanups
	if not paused then
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
	else
	    fix_int
	end if
	draw_interface
	handle_input

	%tick done; render and wait
	View.Update

	% check for win/lose-condition
	exit when enemies_through > 0 or prod_until_rocket <= 0

	ticks_passed += 1
	delay (16 - Time.Elapsed + tick)
    end loop

    % handle game-over
    in_game := false
    if enemies_through > 0 then
	game_over_loss
    else
	game_over_win
    end if
end loop


