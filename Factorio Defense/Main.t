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

    %for k : 1 .. 50
    %    for i : 1 .. 50
    %        map_deaths (i) (k) := sin(i/5) + cos(k/5)*2%*Rand.Real()*50
    %    end for
    %end for
    path_map
    range_enemies (1) := 1

    turrets (1) -> initialize (1, 3, make_v (25.5, 3.5))
    last_turret += 1
    num_turrets += 1
    var garbage : boolean
    var t : int := 0
    for i : floor (max (1, (25.5 - 1.5) / MAP_M_SIZ + 1)) .. floor (min (MAP_M_WID, (25.5 - 0.5) / MAP_M_SIZ) + 1)
	for j : floor (max (1, (3.5 - 1.5) / MAP_M_SIZ + 1)) .. floor (min (MAP_M_HEI, (3.5 - 0.5) / MAP_M_SIZ) + 1)
	    garbage := lock_sem (i, j, addr (turrets (1) -> v))
	end for
    end for
    for i : 25 .. 26
	for j : 3 .. 4
	    cheat (addressint, map (i) (j)) := addr (turrets (1) -> v)
	end for
    end for
    reload_turrets (3) := 0

    var tick : int
    loop
	tick := Time.Elapsed

	% check for input
	% draw the map
	draw_map
	% update all turrets
	turrets (1) -> v.effective_health := 1000
	turrets (1) -> v.health := 1000
	turrets (1) -> update
	turrets (1) -> draw
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
	if num_enemies <= 0 and last_turret not= num_turrets then
	    resolve_turrets
	end if
	resolve_targets
	% check for win/lose-condition

	%e -> draw
	%e -> update (e -> v)

	for i : 1 .. Rand.Int (1, 1)
	    spawn_enemy (Rand.Int (1, 1) + Rand.Int (0, 1) * 4)
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
		locate(50-(j*5-3),i*10-5)
		put map_meta_sem(i)(j)..
	    end for
	end for
	
	%prod_per_tick *= 1.01
	int_tick
	draw_interface

	View.Update
	%exit when e -> v.state = NONEXISTENT
	t := (t+1)mod 360
	Draw.Line(810, 400-t, 810+Time.Elapsed - tick, 400-t, black)
	Draw.Line(810, 400-(t+1)mod 360, 910, 400-(t+1)mod 360, white)
	Draw.Dot(810+16, 400-(t+1)mod 360, brightred)
	%delay (16 - Time.Elapsed + tick)
    end loop
    % loop back to menu if play again
end loop


