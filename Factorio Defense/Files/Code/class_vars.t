var turrets : array 1 .. TURRET_NUM of pointer to Turret
var enemies : array 1 .. ENEMY_NUM of pointer to Enemy
var projectiles : array 1 .. PROJ_NUM of pointer to Projectile

proc startup_init ()
    for i : 1 .. TURRET_NUM
	new turrets (i)
	turret_on_standby (i) := false
    end for
    for i : 1 .. ENEMY_NUM
	new enemies (i)
	enemy_on_standby (i) := false
    end for
    for i : 1 .. PROJ_NUM
	new projectiles (i)
    end for
    for i : 1 .. TURRET_T_NUM
	turret_names (i) := ""
	max_healths_turrets (i) := 0
	reload_turrets (i) := 0
	range_turrets (i) := 0.0
	proj_turrets (i) := 0
	for j : 1 .. DAMAGE_TYPES
	    armor_turrets (i) (j) := 0
	end for
    end for
    for i : 1 .. ENEMY_T_NUM
	enemy_names (i) := ""
	max_healths_enemies (i) := 0
	reload_enemies (i) := 0
	range_enemies (i) := 0.0
	proj_enemies (i) := 0
	for j : 1 .. DAMAGE_TYPES
	    armor_enemies (i) (j) := 0
	end for
    end for
    for i : 1 .. PROJ_T_NUM
	proj_damage (i) := 0
	proj_speed (i) := 0
	proj_sprite (i) := 0
	proj_dmg_type (i) := 0
    end for
end startup_init

proc read_data ()
    var f : int
    open : f, "Files\\Data\\projectiles.txt", get
    for i : 1 .. PROJ_T_NUM
	exit when eof (f)
	get : f, proj_damage (i), proj_speed (i), proj_dmg_type (i)
    end for
    close : f
    open : f, "Files\\Data\\turrets.txt", get
    for i : 1 .. TURRET_T_NUM
	exit when eof (f)
	get : f, skip, turret_names (i) : *
	get : f, max_healths_turrets (i)
	get : f, reload_turrets (i)
	get : f, range_turrets (i)
	get : f, proj_turrets (i)
	get : f, cost_turrets (i)
	for j : 1 .. DAMAGE_TYPES
	    get : f, armor_turrets (i) (j)
	end for
    end for
    close : f
    open : f, "Files\\Data\\enemies.txt", get
    for i : 1 .. ENEMY_T_NUM
	exit when eof (f)
	get : f, skip, enemy_names (i) : *
	get : f, max_healths_enemies (i)
	get : f, reload_enemies (i)
	get : f, range_enemies (i)
	get : f, proj_enemies (i)
	for j : 1 .. DAMAGE_TYPES
	    get : f, armor_enemies (i) (j)
	end for
    end for
    close : f
end read_data

proc begin_init ()
    for i : MAP_B_W_L .. MAP_B_W_U
	for j : MAP_B_H_L .. MAP_B_H_U
	    map_handler (i) (j) := make_ev (NONEXISTENT, 0, 0, 0, 0, FLOOR, make_v (i, j))
	    cheat (addressint, map (i) (j)) := addr (map_handler (i) (j))
	end for
    end for
    for i : 1 .. MAP_M_WID
	for j : 1 .. MAP_M_HEI
	    map_meta_sem (i) (j) := MAP_M_CAP
	    for k : 1 .. MAP_M_CAP
		map_meta (i) (j) (k) := nil
	    end for
	end for
    end for
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    map_deaths (i) (j) := 0
	end for
    end for
    for i : 1 .. TURRET_NUM
	turrets (i) -> initialize (i, 0, make_v (0, 0))
	turrets (i) -> v.state := NONEXISTENT
	turret_on_standby (i) := false
    end for
    for i : 1 .. ENEMY_NUM
	enemies (i) -> initialize (i, 0, make_v (0, 0))
	enemies (i) -> v.state := NONEXISTENT
	enemy_on_standby (i) := false
    end for
    for i : 1 .. PROJ_NUM
	projectiles (i) -> initialize (0, FLOOR, 0, make_v (0, 0))
	projectiles (i) -> v.state := NONEXISTENT
    end for
    turrets_on_standby := 0
    enemies_on_standby := 0
    next_projectile := 1
    last_projectile := 1
    num_projectiles := 0
    next_proj_queue := 1
    last_proj_queue := 1
    num_proj_queue := 0
    can_fire := true
    enemies_through := 0
    chunks_avail_for_spawn := MAP_M_SIZ * MAP_M_SIZ * 2
end begin_init

proc resolve_projectiles ()
    %fire_projectile only adds proj_var handlers to a queue; this offloads the
    %projectiles onto the actual projectile queue for updating.
    loop
	exit when num_proj_queue <= 0
	exit when num_projectiles >= PROJ_NUM

	projectiles (next_projectile) -> initialize (
	    proj_queue (last_proj_queue).target,
	    proj_queue (last_proj_queue).target_type,
	    proj_queue (last_proj_queue).p_type,
	    proj_queue (last_proj_queue).loc)

	next_projectile := (next_projectile mod PROJ_NUM) + 1
	last_proj_queue := (last_proj_queue mod PROJ_QUEUE_NUM) + 1
	num_proj_queue -= 1
	num_projectiles += 1
    end loop

    %when a projectile hits its target, it sets its state to NONEXISTENT, but
    %does not free itself up as it would break the queue. This cleans up the
    %queue.
    loop
	exit when projectiles (last_projectile) -> v.state not= NONEXISTENT
	num_projectiles -= 1
	last_projectile := (last_projectile mod PROJ_NUM) + 1
    end loop

    %if there isn't enough space to store new projectiles, have a temporary
    %ceasefire until someone dies
    can_fire := true
    if num_proj_queue >= PROJ_QUEUE_NUM or num_projectiles >= PROJ_NUM then
	can_fire := false
    end if
end resolve_projectiles

proc resolve_enemies
    %when the enemies at the front of the queue are unalive, pop them
    loop
	exit when num_enemies <= 0
	exit when enemies (last_enemy) -> v.state = ALIVE
	last_enemy += 1
	num_enemies -= 1
    end loop
end resolve_enemies

%Only call this when there are no enemies on the map. Turret insertion is
%after a search - O(n) - so that this works. Since we can't keep track of
%enemy targets, we can't necessarily clear them, and it'll look pretty stupid
%to have enemies, all of a sudden, get confused
proc resolve_turrets
    var i : int := 1
    var t : ^Turret
    new t
    loop
	exit when last_turret = num_turrets
	if turrets (last_turret) -> v.state < ALIVE then
	    last_turret -= 1
	elsif turrets (i) -> v.state = ALIVE then
	    i += 1
	else
	    %swap the two
	    t -> v := turrets (i) -> v
	    t -> kills := turrets (i) -> kills
	    t -> damage_dealt := turrets (i) -> damage_dealt
	    turrets (i) -> v := turrets (last_turret) -> v
	    turrets (i) -> kills := turrets (last_turret) -> kills
	    turrets (i) -> damage_dealt := turrets (last_turret) -> damage_dealt
	    turrets (last_turret) -> v := t -> v
	    turrets (last_turret) -> kills := t -> kills
	    turrets (last_turret) -> damage_dealt := t -> damage_dealt

	    %fix indicies
	    turrets (i) -> v.ind := i
	    turrets (last_turret) -> v.ind := last_turret

	    %we know both will pass the checks above, so increment them
	    last_turret -= 1
	    i += 1
	end if
    end loop
    free t
end resolve_turrets

%heap for flowfield generation
proc push_to_heap (p : path_vars, var size : int)
    var i : int := size + 1
    var m : path_vars
    size += 1
    map_heap (size) := p
    loop
	exit when i <= 1
	exit when map_heap (i).weight > map_heap (i div 2).weight
	m := map_heap (i)
	map_heap (i) := map_heap (i div 2)
	map_heap (i div 2) := m
	i := i div 2
    end loop
end push_to_heap
proc pop_from_heap (var size : int)
    map_heap (1) := map_heap (size)
    size -= 1
    var i : int := 1
    var j : int
    var m : path_vars
    loop
	exit when i * 2 > size
	j := i * 2
	if j + 1 <= size then
	    if map_heap (j).weight > map_heap (j + 1).weight then
		j += 1
	    end if
	end if
	if map_heap (i).weight > map_heap (j).weight then
	    m := map_heap (i)
	    map_heap (i) := map_heap (j)
	    map_heap (j) := m
	    i := j
	else
	    exit
	end if
    end loop
end pop_from_heap
proc reset_map ()
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    map_weights (i) (j) := UNCHECKED
	end for
    end for
end reset_map

%generate flowfield
proc path_map ()
    var map_heap_size : int := 0
    var cn : path_vars              %current node
    var nn : path_vars              %new node

    %biters: begin at 1, map_width/2
    reset_map
    map_mov (0) (MAP_WIDTH div 2) (1) := make_v (0, -1)
    map_weights (MAP_WIDTH div 2) (1) := COMPLETE
    push_to_heap (make_node (MAP_WIDTH div 2, 1, 0), map_heap_size)
    loop
	exit when map_heap_size <= 0
	cn := map_heap (1)
	pop_from_heap (map_heap_size)
	%only propagate if shortest path
	if map_weights (cn.x) (cn.y) >= cn.weight then
	    map_weights (cn.x) (cn.y) := COMPLETE
	    for i : max (cn.x - 1, 1) .. min (cn.x + 1, MAP_WIDTH)
		for j : max (cn.y - 1, 1) .. min (cn.y + 1, MAP_HEIGHT)
		    nn.weight := cn.weight + 1
		    if abs (cn.x - i) + abs (cn.y - j) >= 2 then
			nn.weight := cn.weight + 1.4
		    end if
		    nn.weight += map_deaths (i) (j) * 0.2
		    nn.weight += Rand.Real () * 0.001
		    if MAP_B_W_L <= i and MAP_B_W_U >= i and MAP_B_H_L <= j and MAP_B_H_U >= j then
			nn.weight += map (i) (j) -> effective_health * 0.2
		    end if
		    %check if new attempt is shortest; if so, add to heap
		    if map_weights (i) (j) > nn.weight then
			map_mov (0) (i) (j) := make_v (cn.x - i, cn.y - j)
			map_weights (i) (j) := nn.weight
			push_to_heap (make_node (i, j, nn.weight), map_heap_size)
		    end if
		end for
	    end for
	end if
    end loop

    %spitters: begin at all turrets and at biter endpoint
    reset_map
    map_mov (1) (MAP_WIDTH div 2) (1) := make_v (0, -1)
    map_weights (MAP_WIDTH div 2) (1) := COMPLETE
    push_to_heap (make_node (MAP_WIDTH div 2, 1, 0), map_heap_size)
    for i : 1 .. last_turret
	if turrets (i) -> v.state = ALIVE then
	    map_mov (1) (floor (turrets (i) -> v.loc.x)) (floor (turrets (i) -> v.loc.y)) := make_v (0, 0)
	    map_weights (1) (MAP_WIDTH div 2) := COMPLETE
	    push_to_heap (make_node (MAP_WIDTH div 2, 1, 0), map_heap_size)
	end if
    end for
    loop
	exit when map_heap_size <= 0
	cn := map_heap (1)
	pop_from_heap (map_heap_size)
	%only propagate if shortest path
	if map_weights (cn.x) (cn.y) >= cn.weight then
	    map_weights (cn.x) (cn.y) := COMPLETE
	    for i : max (cn.x - 1, 1) .. min (cn.x + 1, MAP_WIDTH)
		for j : max (cn.y - 1, 1) .. min (cn.y + 1, MAP_HEIGHT)
		    nn.weight := cn.weight + 1
		    if abs (cn.x - i) + abs (cn.y - j) >= 2 then
			nn.weight := cn.weight + 1.4
		    end if
		    nn.weight += map_deaths (i) (j) * 0.4
		    nn.weight += Rand.Real () * 0.001
		    if MAP_B_W_L <= i and MAP_B_W_U >= i and MAP_B_H_L <= j and MAP_B_H_U >= j then
			nn.weight += map (i) (j) -> effective_health * 0.2
		    end if
		    %check if new attempt is shortest; if so, add to heap
		    if map_weights (i) (j) > nn.weight then
			map_mov (1) (i) (j) := make_v (cn.x - i, cn.y - j)
			map_weights (i) (j) := nn.weight
			push_to_heap (make_node (i, j, nn.weight), map_heap_size)
		    end if
		end for
	    end for
	end if
    end loop
end path_map

%will be overhauled later
proc draw_map ()
    var c : int := 28
    Draw.FillBox (0, 0, MAP_WIDTH * PIXELS_PER_GRID, MAP_HEIGHT * PIXELS_PER_GRID, 27)
    for i : 0 .. MAP_WIDTH - 1
	for j : 0 .. MAP_HEIGHT - 1
	    Draw.FillBox (i * PIXELS_PER_GRID, j * PIXELS_PER_GRID,
		(i + 1) * PIXELS_PER_GRID - 2, (j + 1) * PIXELS_PER_GRID - 2, c)
	end for
    end for
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    Draw.Line (round ((i - 0.5) * PIXELS_PER_GRID),
		round ((j - 0.5) * PIXELS_PER_GRID),
		round ((i - 0.5 + map_mov (0) (i) (j).x * 0.5) * PIXELS_PER_GRID),
		round ((j - 0.5 + map_mov (0) (i) (j).y * 0.5) * PIXELS_PER_GRID),
		brightblue)
	end for
    end for
end draw_map

fcn lock_sem (x, y : int, e : cheat
    unchecked ^entity_vars) : boolean
    if map_meta_sem (x) (y) > 0 then
	map_meta_sem (x) (y) -= 1
	for i : 1 .. MAP_M_CAP
	    if map_meta (x) (y) (i) = nil then
		map_meta (x) (y) (i) := e
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
    map_meta_sem (x) (y) -= 1
    for i : 1 .. MAP_M_CAP
	if map_meta (x) (y) (i) = e then
	    map_meta (x) (y) (i) := nil
	end if
    end for
    if map_meta_sem (x) (y) = 1 and (x = 1 or x = MAP_M_WID or y = MAP_M_HEI) then
	chunks_avail_for_spawn += 1
	if chunks_avail_for_spawn = 1 and num_enemies >= ENEMY_NUM then
	    can_spawn := false
	end if
    end if
end unlock_sem

proc spawn_enemy (t : int)
    if can_spawn then
	var chunk_chosen := Rand.Int (1, chunks_avail_for_spawn)
	for i : 1 .. MAP_M_WID
	    for decreasing j : MAP_M_HEI .. 0
		if j < 5 and (i not= 1 or i not= MAP_M_WID) then
		    exit
		end if
		if map_meta_sem (i) (j) > 0 then
		    chunk_chosen -= 1
		    if chunk_chosen = 0 then
			if lock_sem (i, j, addr (enemies (next_enemy) -> v)) then
			    if j = MAP_M_HEI then
				if i = MAP_M_WID then
				    if Rand.Real > 0.5 then
					enemies (next_enemy) -> initialize (next_enemy, t,
					    make_v (1 + Rand.Real * (MAP_M_SIZ - 1) + (i - 1) * MAP_M_SIZ, MAP_HEIGHT))
				    else
					enemies (next_enemy) -> initialize (next_enemy, t,
					    make_v (MAP_WIDTH, 1 + Rand.Real * (MAP_M_SIZ - 1) + (j - 1) * MAP_M_SIZ))
				    end if
				elsif i = 1 then
				    enemies (next_enemy) -> initialize (next_enemy, t,
					make_v (1 + Rand.Real * (MAP_M_SIZ - 1) + (i - 1) * MAP_M_SIZ, MAP_HEIGHT))
				else
				    enemies (next_enemy) -> initialize (next_enemy, t,
					make_v (1, 1 + Rand.Real * (MAP_M_SIZ - 1) + (j - 1) * MAP_M_SIZ))
				end if
			    elsif i = MAP_M_WID then
				enemies (next_enemy) -> initialize (next_enemy, t,
				    make_v (MAP_WIDTH, 1 + Rand.Real * (MAP_M_SIZ - 1) + (j - 1) * MAP_M_SIZ))
			    else
				enemies (next_enemy) -> initialize (next_enemy, t,
				    make_v (1, 1 + Rand.Real * (MAP_M_SIZ - 1) + (j - 1) * MAP_M_SIZ))

			    end if
			    %increment deque!
			end if
		    end if
		end if
	    end for
	end for
    end if
end spawn_enemy
