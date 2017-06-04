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

    for k : 1 .. 50
	for i : 1 .. 50 
	    map_deaths (i) (k) := sin(i/5) + cos(k/5)*2%*Rand.Real()*50
	end for
    end for
    path_map
    range_enemies (1) := 1
    var tick : int
    loop
	tick := Time.Elapsed

	% check for input
	% draw the map
	draw_map
	% update all turrets
	% update all enemies
	for i : 1..ENEMY_NUM
	    enemies(i)->pre_update
	end for
	for i : 1 .. ENEMY_NUM
	    enemies (i) -> update (enemies (i) -> v)
	    enemies (i) -> draw
	end for
	% update all projectiles
	% update all stats
	% do cleanups
	resolve_enemies
	resolve_projectiles
	if num_enemies <= 0 and last_turret not= num_turrets then
	    resolve_turrets
	end if
	resolve_targets
	% check for win/lose-condition

	%e -> draw
	%e -> update (e -> v)

	for i : 1 .. 1
	    spawn_enemy (1)
	end for
	if Rand.Real () <= 0.00 then
	    %k := Rand.Int (2, 49)
	    for i : 1 .. 50
		%map_deaths (i) (k) += 50 + i
	    end for
	    path_map
	end if

	resolve_enemies

	for i : 1 .. 0%MAP_M_WID
	    for j : 1 .. MAP_M_HEI
		locate (50 - floor((j-0.5) * MAP_M_SIZ), floor((i-0.5) * MAP_M_SIZ*2))
		put map_meta_sem (i) (j) ..
	    end for
	end for
	locate (1, 102)
	put num_enemies : 5 ..

	View.Update
	%exit when e -> v.state = NONEXISTENT
	delay (16 - Time.Elapsed + tick)
    end loop
    % loop back to menu if play again
end loop


