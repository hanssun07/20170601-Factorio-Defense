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
setscreen ("graphics:1100;800,nocursor,nobuttonbar")
View.Set ("offscreenonly")


% load everything
startup_init
read_data

loop
    % initialize game
    begin_init

    % display and handle menu screen
    if not handle_intro_screen() then
	exit
    end if

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

	%tick done; render and wait
	View.Update

	% check for win/lose-condition
	exit when enemies_through > 0 or prod_until_rocket <= 0

	ticks_passed += 1
	delay (16 - Time.Elapsed + tick)
    end loop

    % handle game-over
    Draw.FillBox (300, 299, 801, 500, 24)
    Draw.FillBox (299, 300, 800, 501, 30)
    Draw.FillBox (300, 300, 800, 500, 28)
    var wid : int
    if enemies_through > 0 then
	wid := Font.Width ("Game Over. Better luck next time!", font)
	Font.Draw ("Game Over. Better luck next time!", 550 - wid div 2, 400, font, black)
    else
	wid := Font.Width ("With the rocket you built, you escape the planet.", font)
	Font.Draw ("With the rocket you built, you escape the planet.", 550 - wid div 2, 410, font, black)
	wid := Font.Width ("You won! Congratulations!", font)
	Font.Draw ("You won! Congratulations!", 550 - wid div 2, 390, font, black)
    end if
    wid := Font.Width ("Press any key to continue...", font)
    Font.Draw ("Press any key to continue...", 550 - wid div 2, 340, font, black)
    View.Update

    % return to main menu when key pressed
    var c : string (1)
    getch (c)
end loop


