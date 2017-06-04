
module Floating_Point
    export pervasive unqualified all
    fcn * cmp_f (a, b : real) : boolean
	var eps_a : real := abs (a) / 65536.0
	var eps_b : real := abs (b) / 65536.0
	result a + eps_a >= b and a - eps_a <= b and
	    b + eps_b >= a and b - eps_b <= a
    end cmp_f
end Floating_Point

module Point
    export pervasive unqualified all

    type point :
	record
	    x, y : real
	end record

    fcn make_v (x, y : real) : point
	var r : point
	r.x := x
	r.y := y
	result r
    end make_v

    fcn add_v (a, b : point) : point
	result make_v (a.x + b.x, a.y + b.y)
    end add_v

    fcn diff_v (a, b : point) : point
	result make_v (a.x - b.x, a.y - b.y)
    end diff_v

    fcn scale_v (p : point, f : real) : point
	result make_v (p.x * f, p.y * f)
    end scale_v

    fcn magnitude_squared (p : point) : real
	result p.x * p.x + p.y * p.y
    end magnitude_squared

    fcn distance_squared (a, b : point) : real
	result magnitude_squared (diff_v (a, b))
    end distance_squared

    fcn truncate (p : point, d : real) : point
	var ms : real := magnitude_squared (p)
	if ms > d * d then
	    result scale_v (p, d / sqrt (ms))
	end if
	result p
    end truncate

    fcn normalize (p : point) : point
	var d : real := magnitude_squared (p)
	if d = 0 then
	    result p
	end if
	result scale_v (p, 1.0 / sqrt (d))
    end normalize

    %in radians
    fcn angle_v (p : point) : real
	var ra : real := 0
	if p.x = 0 then
	    ra := PI * 0.5
	    if p.y < 0 then
		ra += PI
	    end if
	else
	    ra := arctan (p.y / p.x)
	end if
	if p.x < 0 then
	    ra := PI + ra
	end if
	loop
	    exit when ra < TAU
	    ra -= TAU
	end loop
	loop
	    exit when ra >= 0
	    ra += TAU
	end loop
	result ra
    end angle_v

    fcn equal_v (a, b : point) : boolean
	if cmp_f (a.x, b.x) then
	    result cmp_f (a.y, b.y)
	end if
	result false
    end equal_v

    fcn v_to_string (p : point) : string
	result "(" + realstr (p.x, 1) + ", " + realstr (p.y, 1) + ")"
    end v_to_string
end Point

module Class_Vars
    export var pervasive unqualified all

    type proj_vars :
	record
	    target : int
	    target_type : int
	    p_type : int
	    loc : point
	    state : int
	end record
    type entity_vars :
	record
	    cur_target : int
	    state : int
	    health : int
	    effective_health : int
	    e_type : int
	    loc : point
	    cooldown : int
	    ind : int
	    class_type : int
	end record
    type path_vars :
	record
	    x : int
	    y : int
	    weight : real
	end record

    fcn make_ev (s, h, et, cd, i, ct : int, l : point) : entity_vars
	var e : entity_vars
	e.cur_target := 0
	e.state := s
	e.health := h
	e.effective_health := e.health
	e.e_type := et
	e.cooldown := cd
	e.ind := i
	e.class_type := ct
	e.loc := l
	result e
    end make_ev

    fcn make_node (x, y : int, weight : real) : path_vars
	var p : path_vars
	p.x := x
	p.y := y
	p.weight := weight
	result p
    end make_node

    var proj_queue : array 1 .. PROJ_QUEUE_NUM of proj_vars

    %base map; entity_vars of walls
    var map_handler : array MAP_B_W_L .. MAP_B_W_U of array MAP_B_H_L .. MAP_B_H_U of entity_vars
    %map holding pointers to entity_vars of walls and turrets
    var map : array MAP_B_W_L .. MAP_B_W_U of array MAP_B_H_L .. MAP_B_H_U of unchecked ^entity_vars

    %metamap holding pointers to entity_vars
    var map_meta : array 1 .. MAP_M_WID of array 1 .. MAP_M_HEI of array 1 .. MAP_M_CAP of unchecked ^entity_vars
    %semaphore for metamap
    var map_meta_sem : array 1 .. MAP_M_WID of array 1 .. MAP_M_HEI of int

    %flow field for enemy movement
    var map_mov : array 0 .. 1 of array 1 .. MAP_WIDTH of array 1 .. MAP_HEIGHT of point
    var map_weights : array 1 .. MAP_WIDTH of array 1 .. MAP_HEIGHT of real
    var map_heap : array 1 .. MAP_WIDTH * MAP_HEIGHT of path_vars
    var map_deaths : array 1 .. MAP_WIDTH of array 1 .. MAP_HEIGHT of real

    fcn lock_sem (x, y : int, e : cheat
	unchecked ^entity_vars) : boolean
	
	locate (2,102)
	put x:10,y:10..
	
	if map_meta_sem (x) (y) > 0 then
	    map_meta_sem (x) (y) -= 1
	    for i : 1 .. MAP_M_CAP
		if map_meta (x) (y) (i) = nil then
		    map_meta (x) (y) (i) := e
		    exit
		end if
	    end for
	    if map_meta_sem (x) (y) <= 0 and (x = 1 or x = MAP_M_WID or y = MAP_M_HEI) then
		chunks_avail_for_spawn -= 1
		if chunks_avail_for_spawn <= 0 then
		    can_spawn := false
		end if
	    end if
	    result true
	end if
	result false
    end lock_sem
    proc unlock_sem (x, y : int, e : cheat
	unchecked ^entity_vars)
	map_meta_sem (x) (y) += 1
	for i : 1 .. MAP_M_CAP
	    if map_meta (x) (y) (i) = e then
		map_meta (x) (y) (i) := nil
		exit
	    end if
	end for
	if map_meta_sem (x) (y) = 1 and (x = 1 or x = MAP_M_WID or y = MAP_M_HEI) then
	    chunks_avail_for_spawn += 1
	    if chunks_avail_for_spawn = 1 and num_enemies >= ENEMY_NUM then
		can_spawn := false
	    end if
	end if
    end unlock_sem
end Class_Vars
