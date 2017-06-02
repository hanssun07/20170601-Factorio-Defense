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

    var k : int := Rand.Int (2, 49)
    for i : 1 .. 50
	map_deaths (i) (k - 1) := Rand.Real () * 50 + 50
	map_deaths (i) (k) := Rand.Real () * 50 + 50
	map_deaths (i) (k + 1) := Rand.Real () * 50 + 50
    end for
    path_map
    %var e : ^Enemy
    %new e
    %e -> initialize (1, 1, make_v (Rand.Real * 49 + 1, 50))
    %  for i : 1 .. 1000

    % spawn_enemy(1)
    % end for
    range_enemies (1) := 1
    var tick : int
    loop
	tick := Time.Elapsed

	draw_map
	%e -> draw
	%e -> update (e -> v)
	for i : 1 .. 10
	    spawn_enemy (1)
	end for
	for i : 1 .. 1000
	    enemies (i) -> draw
	    enemies (i) -> update (enemies (i) -> v)
	    %if enemies (i) -> v.state = NONEXISTENT then
	    %    enemies (i) -> initialize (1, 1, make_v (Rand.Real * 49 + 1, 50))
	    %end if
	end for
	if Rand.Real () <= 0.01 then
	    k := Rand.Int (2, 49)
	    for i : 1 .. 50
		map_deaths (i) (k - 1) := Rand.Real () * 50 + 50
		map_deaths (i) (k) := Rand.Real () * 50 + 50
		map_deaths (i) (k + 1) := Rand.Real () * 50 + 50
	    end for
	    path_map
	end if

	resolve_enemies

	for i : 1 .. 10
	    for j : 1 .. 10
		locate (50-(j * 5-2), (i * 10-2))
		put map_meta_sem (i) (j) ..
	    end for
	end for
	locate (1,102)
	put num_enemies:5..

	View.Update
	%exit when e -> v.state = NONEXISTENT
	delay (30 - Time.Elapsed + tick)
    end loop

    % tick
    % check for input
    % update all turrets
    % update all enemies
    % update all projectiles
    % update all stats
    % check for win/lose-condition

    % loop back to menu if play again
end loop


