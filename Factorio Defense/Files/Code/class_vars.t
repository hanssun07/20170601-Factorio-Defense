var turrets : array 1 .. TURRET_NUM of pointer to Turret
var enemies : array 1 .. ENEMY_NUM of pointer to Enemy
var projectiles : array 1 .. PROJ_NUM of pointer to Projectile

proc startup_init ()
    % allocate memory for all turrets
    for i : 1 .. TURRET_NUM
	new turrets (i)
	turret_on_standby (i) := false
    end for
    % allocate memory for all enemies
    for i : 1 .. ENEMY_NUM
	new enemies (i)
	enemy_on_standby (i) := false
    end for
    % allocate memory for all projectiles
    for i : 1 .. PROJ_NUM
	new projectiles (i)
    end for
    % null-initialize all turret types
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
    % null-initialize all turret types
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
    % null-initialize all projectile types
    for i : 1 .. PROJ_T_NUM
	proj_damage (i) := 0
	proj_speed (i) := 0
	proj_sprite (i) := 0
	proj_dmg_type (i) := 0
    end for

    % allocate space for the font
    font := Font.New ("serif:12")
    PROD_STR_WIDTH := max (Font.Width ("Production: ", font), Font.Width ("Electricity Stored: ", font))
    NMRL_STR_WIDTH := Font.Width ("0", font)

    % init mouse options
    Mouse.ButtonChoose ("multibutton")
end startup_init

proc read_data ()
    % self-explanatory. f is the file; tmp is atemporary variable
    var f : int
    var tmp : int
    open : f, "Files\\Data\\projectiles.txt", get
    for i : 1 .. PROJ_T_NUM
	exit when eof (f)
	get : f, proj_damage (i), proj_speed (i), proj_dmg_type (i)
	proj_speed (i) /= 60
    end for
    close : f
    open : f, "Files\\Data\\turrets.txt", get
    for i : 1 .. TURRET_T_NUM
	exit when eof (f)
	get : f, skip, turret_names (i) : *
	get : f, skip, proj_names (i) : *
	get : f, max_healths_turrets (i)
	get : f, reload_turrets (i)
	get : f, range_turrets (i)
	get : f, proj_turrets (i)
	get : f, prod_per_turret (i)
	prod_until_next_turret (i) := prod_per_turret (i)
	get : f, prod_per_proj (i)
	prod_until_next_proj (i) := prod_per_proj (i)
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
    open : f, "Files\\Data\\research.txt", get
    for i : 1 .. RESEARCH_NUM
	exit when eof (f)
	get : f, skip, research_name (i) : *
	get : f, skip, prod_until_research_done (i)
	prod_per_research (i) := prod_until_research_done (i)
	get : f, skip, research_effect (i) : *
	get : f, skip, research_effect_2 (i) : *
	for j : 1 .. RESEARCH_NUM
	    get : f, skip, tmp
	    if tmp = 1 then
		research_prereq (i) (j) := true
	    else
		research_prereq (i) (j) := false
	    end if
	end for
    end for
end read_data

proc begin_init ()
    % default-initalize the map
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    map_handler (i) (j) := make_ev (NONEXISTENT, 0, 0, 0, 0, FLOOR, make_v (i, j))
	    cheat (addressint, map (i) (j)) := addr (map_handler (i) (j))
	end for
    end for
    % reset the semaphore
    for i : 1 .. MAP_M_WID
	for j : 1 .. MAP_M_HEI
	    map_meta_sem (i) (j) := MAP_M_CAP
	    for k : 1 .. MAP_M_CAP
		map_meta (i) (j) (k) := nil
	    end for
	end for
    end for
    % reset the death counter (pathfinding)
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    map_deaths (i) (j) := 0
	end for
    end for
    % reset every turret
    for i : 1 .. TURRET_NUM
	turrets (i) -> initialize (i, 0, make_v (0, 0))
	turrets (i) -> v.state := NONEXISTENT
	turret_on_standby (i) := false
    end for
    % reset every enemy
    for i : 1 .. ENEMY_NUM
	enemies (i) -> initialize (i, 0, make_v (0, 0))
	enemies (i) -> v.state := NONEXISTENT
	enemy_on_standby (i) := false
    end for
    % reset every projectile
    for i : 1 .. PROJ_NUM
	projectiles (i) -> initialize (0, FLOOR, make_v (0, 0), 0)
	projectiles (i) -> v.state := NONEXISTENT
    end for
    % reset all handler variables
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
    chunks_avail_for_spawn := MAP_M_WID + MAP_M_HEI * 2 - 2
    last_turret := 0
    num_turrets := 0
    can_build_turrets := true
    can_spawn := true
    num_enemies := 0
    ticks_passed := 0

    %reset the interfce
    prod_avail := 0
    prod_per_tick := 1 / 60
    ticks_to_next_prod := 6
    ticks_per_prod := 6
    prod_distribution_prod := 1
    prod_distribution_prod_user := 1

    electricity_production := 0
    electricity_consumption := 0
    electricity_storage := 0.001
    electricity_stored := 0
    prod_until_next_e_storage := 1000.0
    prod_distribution_electricity := 0.0001
    prod_distribution_electricity_user := 0.0001
    prod_distribution_electricity_storage := 0.0001
    prod_distribution_electricity_storage_user := 0.0001

    prod_until_next_repair := 10.0
    prod_per_repair := 10.0
    num_repair_available := 1.0
    prod_distribution_repair := 0.0001
    prod_distribution_repair_user := 0.0001

    prod_until_next_wall := 240.0
    prod_per_wall := 240.0
    num_wall_avail := 20
    prod_distribution_wall := 0.0001
    prod_distribution_wall_user := 0.0001

    prod_until_rocket := 1000000.0  %one million
    rocket_enabled := false
    prod_distribution_rocket := 0.0
    prod_distribution_rocket_user := 0.0

    for i : 1 .. TURRET_T_NUM
	num_turrets_avail (i) := 0
	num_proj_avail (i) := 0
	turret_enabled (i) := false
	prod_distribution_turrets (i) := 0.0
	prod_distribution_turrets_user (i) := 0.0
	prod_distribution_proj (i) := 0.0
	prod_distribution_proj_user (i) := 0.0
	prod_until_next_turret (i) := prod_per_turret (i)
	prod_until_next_proj (i) := prod_per_proj (i)
    end for

    % the first turret is always enabled
    num_turrets_avail (1) := 1
    num_proj_avail (1) := 100
    turret_enabled (1) := true

    for i : 1 .. RESEARCH_NUM
	research_enabled (i) := false
	prod_distribution_research (i) := 0.0
	prod_distribution_research_user (i) := 0.0
	prod_until_research_done (i) := prod_per_research (i)
    end for

    check_research_prereqs ()
end begin_init

proc resolve_projectiles ()
    %fire_projectile only adds proj_var handlers to a queue; this offloads the
    %projectiles onto the actual projectile queue for updating.
    loop
	exit when num_proj_queue <= 0
	exit when num_projectiles >= PROJ_NUM

	projectiles (next_projectile) -> initialize (
	    proj_queue (last_proj_queue).target,
	    proj_queue (last_proj_queue).p_type,
	    proj_queue (last_proj_queue).loc,
	    proj_queue (last_proj_queue).dmg)

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
	exit when num_projectiles <= 0
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
	last_enemy := (last_enemy mod ENEMY_NUM) + 1
	num_enemies -= 1
    end loop
    if num_enemies < ENEMY_NUM then
	can_spawn := true
    end if
end resolve_enemies

%heap for flowfield generation; uses standard algoirthms for push and pop
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
%essentially dijkstra's algorithm, but without an end point.
%the flow field is generated based on how one arrives to any tile.
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
		    nn.weight += map (i) (j) -> effective_health * 2
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
    map_heap_size := 0
    reset_map
    map_mov (1) (MAP_WIDTH div 2) (1) := make_v (0, -1)
    map_weights (MAP_WIDTH div 2) (1) := COMPLETE
    push_to_heap (make_node (MAP_WIDTH div 2, 1, 0), map_heap_size)
    for i : 1 .. last_turret
	if turrets (i) -> v.state = ALIVE then
	    map_mov (1) (floor (turrets (i) -> v.loc.x)) (floor (turrets (i) -> v.loc.y)) := make_v (0, 0)
	    map_weights (floor (turrets (i) -> v.loc.x)) (floor (turrets (i) -> v.loc.y)) := COMPLETE
	    push_to_heap (make_node (floor (turrets (i) -> v.loc.x), floor (turrets (i) -> v.loc.y), 0), map_heap_size)
	end if
    end for
    loop
	exit when map_heap_size <= 0
	exit when map_heap_size >= MAP_WIDTH*MAP_HEIGHT
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
		    nn.weight += map (i) (j) -> effective_health * 5
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

    % normalize all of the weights for the sake of easier post-handling
    for k : 0 .. 1
	for i : 1 .. MAP_WIDTH
	    for j : 1 .. MAP_HEIGHT
		map_mov (k) (i) (j) := normalize (map_mov (k) (i) (j))
	    end for
	end for
    end for
end path_map

proc draw_map ()
    % tc: tile color, gl : grid line color
    var tc : int := 28
    var gl : int := 27

    % fill the background with the tile color
    Draw.FillBox (0, 0, MAP_WIDTH * PIXELS_PER_GRID, MAP_HEIGHT * PIXELS_PER_GRID, tc)
    % draw the gridlines
    for i : 1 .. MAP_WIDTH - 1
	Draw.Line (PIXELS_PER_GRID * i, 1, PIXELS_PER_GRID * i, MAP_HEIGHT * PIXELS_PER_GRID, gl)
    end for
    for i : 1 .. MAP_HEIGHT - 1
	Draw.Line (1, PIXELS_PER_GRID * i, MAP_WIDTH * PIXELS_PER_GRID, PIXELS_PER_GRID * i, gl)
    end for
    % draw walls and fire
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    if map (i) (j) -> class_type = WALL then
		Draw.FillBox ((i - 1) * PIXELS_PER_GRID, (j - 1) * PIXELS_PER_GRID, (i) * PIXELS_PER_GRID, (j) * PIXELS_PER_GRID, darkgrey)
		if map (i) (j) -> health < 350 then
		    Draw.Line ((i - 1) * PIXELS_PER_GRID, (j - 1) * PIXELS_PER_GRID, floor ((i - 1 + map (i) (j) -> health / 350) * PIXELS_PER_GRID), (j - 1) * PIXELS_PER_GRID, brightgreen)
		    Draw.Line (ceil ((i - 1 + map (i) (j) -> health / 350) * PIXELS_PER_GRID), (j - 1) * PIXELS_PER_GRID, ((i) * PIXELS_PER_GRID), (j - 1) * PIXELS_PER_GRID, brightred)
		end if
	    end if
	    if map_handler (i) (j).class_type = FIRE then
		for k : 1 .. max (1, floor (0.3 * sqrt (map_handler (i) (j).health)))
		    var s : int := Rand.Int (1, PIXELS_PER_GRID div 3)
		    Draw.FillOval (floor ((i - Rand.Real) * PIXELS_PER_GRID), floor ((j - Rand.Real) * PIXELS_PER_GRID),
			s, s, Rand.Int (41, 43))
		end for
	    end if
	end for
    end for
end draw_map

% given an enemy type, spawns the enemy wherever available
proc spawn_enemy (t : int)
    if can_spawn then
	% choose a random, available chunck
	var chunk_chosen := Rand.Int (1, max (1, chunks_avail_for_spawn))

	% loop through all available chunks
	for i : 1 .. MAP_M_WID
	    for decreasing j : MAP_M_HEI .. 1
		% check if chunk is valid...
		if j = MAP_M_HEI or (i = 1 or i = MAP_M_WID) then
		    % ... and available
		    if map_meta_sem (i) (j) > 0 then
			% if so, decrement the chunk counter to indicate that we're getting closer to the chosen chunk
			chunk_chosen -= 1

			% check if we've arrived at the chosen chunk
			if chunk_chosen = 0 then
			    % if so, lock the semaphore...
			    if lock_sem (i, j, addr (enemies (next_enemy) -> v)) then
				% ... and spawn an enemy at an appropriate location
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
					if Rand.Real > 0.5 then
					    enemies (next_enemy) -> initialize (next_enemy, t,
						make_v (1 + Rand.Real * (MAP_M_SIZ - 1) + (i - 1) * MAP_M_SIZ, MAP_HEIGHT))
					else

					    enemies (next_enemy) -> initialize (next_enemy, t,
						make_v (1, 1 + Rand.Real * (MAP_M_SIZ - 1) + (j - 1) * MAP_M_SIZ))
					end if
				    else
					enemies (next_enemy) -> initialize (next_enemy, t,
					    make_v (1 + Rand.Real * (MAP_M_SIZ - 1) + (i - 1) * MAP_M_SIZ, MAP_HEIGHT))
				    end if
				elsif i = MAP_M_WID then
				    enemies (next_enemy) -> initialize (next_enemy, t,
					make_v (MAP_WIDTH, 1 + Rand.Real * (MAP_M_SIZ - 1) + (j - 1) * MAP_M_SIZ))
				else
				    enemies (next_enemy) -> initialize (next_enemy, t,
					make_v (1, 1 + Rand.Real * (MAP_M_SIZ - 1) + (j - 1) * MAP_M_SIZ))

				end if
				%increment deque!
				next_enemy := (next_enemy mod ENEMY_NUM) + 1
				num_enemies += 1
				if num_enemies >= ENEMY_NUM then
				    can_spawn := false
				end if
			    end if
			end if
		    end if
		end if
	    end for
	end for
    end if
end spawn_enemy

proc resolve_targets
    var u : unchecked ^entity_vars
    var v : entity_vars
    var shortest : real := 4294967296.0
    var cur : real
    var check : int

    %enemies
    for e : 1 .. ENEMY_NUM
	exit when enemies_on_standby <= 0
	if enemy_on_standby (e) then
	    %easier on eyes
	    v := enemies (e) -> v


	    %initialize min-finder
	    shortest := 4294967296.0

	    %check in the appropriate chunks
	    for i : floor (max (1, (v.loc.x - range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1)) ..
		    floor (min (MAP_M_WID, (v.loc.x + range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1))
		for j : floor (max (1, (v.loc.y - range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1)) ..
			floor (min (MAP_M_HEI, (v.loc.y + range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1))
		    check := MAP_M_CAP - map_meta_sem (i) (j)

		    %check every necessary entry in the chunck
		    for k : 1 .. MAP_M_CAP
			exit when check <= 0
			if map_meta (i) (j) (k) not= nil then
			    if map_meta (i) (j) (k) -> class_type >= TURRET and map_meta (i) (j) (k) -> effective_health > 0 then
				%triple the effective distance if a wall
				cur := distance_squared (map_meta (i) (j) (k) -> loc, v.loc) *
				    map_meta (i) (j) (k) -> class_type
				if cur < shortest then
				    u := map_meta (i) (j) (k)
				    shortest := cur
				end if
			    end if
			    check -= 1
			end if
		    end for
		end for
	    end for

	    if shortest >= 4294967295.0 or distance_squared (u -> loc, v.loc) > range_enemies (v.e_type) ** 2 then
		enemies (e) -> v.cur_target := nil
	    else
		enemies (e) -> v.cur_target := u
	    end if


	    enemy_on_standby (e) := false
	    enemies_on_standby -= 1
	end if
    end for

    %turrets - as with enemies.
    for t : 1 .. TURRET_NUM
	exit when turrets_on_standby <= 0
	if turret_on_standby (t) then
	    %easier on eyes
	    v := turrets (t) -> v

	    %initialize min-finder
	    shortest := 4294967296.0

	    for i : floor (max (1, (v.loc.x - range_turrets (v.e_type) - 1) / MAP_M_SIZ + 1)) ..
		    floor (min (MAP_M_WID, (v.loc.x + range_turrets (v.e_type) - 1) / MAP_M_SIZ + 1))
		for j : floor (max (1, (v.loc.y - range_turrets (v.e_type) - 1) / MAP_M_SIZ + 1)) ..
			floor (min (MAP_M_HEI, (v.loc.y + range_turrets (v.e_type) - 1) / MAP_M_SIZ + 1))
		    check := MAP_M_CAP - map_meta_sem (i) (j)
		    for k : 1 .. MAP_M_CAP
			exit when check <= 0
			if map_meta (i) (j) (k) not= nil then
			    if map_meta (i) (j) (k) -> class_type = ENEMY and map_meta (i) (j) (k) -> effective_health > 0 then
				cur := distance_squared (map_meta (i) (j) (k) -> loc, v.loc)
				if proj_dmg_type (proj_turrets (v.e_type)) = 3 then
				    cur += Rand.Real * 100
				end if
				if cur < shortest then
				    u := map_meta (i) (j) (k)
				    shortest := cur
				end if
			    end if
			    check -= 1
			end if
		    end for
		end for
	    end for

	    if shortest >= 4294967295.0 or distance_squared (u -> loc, v.loc) > range_turrets (v.e_type) ** 2 then
		turrets (t) -> v.cur_target := nil
	    else
		turrets (t) -> v.cur_target := u
	    end if

	    turret_on_standby (t) := false
	    turrets_on_standby -= 1
	end if
    end for
end resolve_targets

proc update_map
    % per tile:
    % if it's a dead wall, remove it
    % if it's a dead turret, remove it and fix the pointers
    % if it's a fire, lower its health, removing it when necessary
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    map_deaths (i) (j) := max (map_deaths (i) (j) - 1 / 18000, 0)
	    if map (i) (j) -> class_type = WALL then
		if map (i) (j) -> health <= 0 then
		    map_handler (i) (j) := make_ev (NONEXISTENT, 0, 0, 0, 0, FLOOR, make_v (i, j))
		end if
	    end if
	    if map (i) (j) -> class_type = TURRET then
		if map (i) (j) -> state < ALIVE then
		    map_handler (i) (j) := make_ev (NONEXISTENT, 0, 0, 0, 0, FLOOR, make_v (i, j))
		    cheat (addressint, map (i) (j)) := addr (map_handler (i) (j))
		end if
	    end if
	    if map_handler (i) (j).class_type = FIRE then
		map_handler (i) (j).health -= 1
		if map_handler (i) (j).health <= 0 then
		    map_handler (i) (j) := make_ev (NONEXISTENT, 0, 0, 0, 0, FLOOR, make_v (i, j))
		end if
	    end if
	end for
    end for
end update_map

% creates a turret where mx and my form the coordinate of the topleft corner of the turret
proc spawn_turret_from_topleft (mx, my, i : int)
    num_turrets += 1
    if num_turrets >= TURRET_NUM then
	can_build_turrets := false
    end if
    var bp : boolean
    var n : int := 1
    % put the turret at an available index
    for j : 1 .. TURRET_NUM
	if turrets (j) -> v.state < ALIVE then
	    n := j
	    exit
	end if
    end for
    if n > last_turret then
	last_turret := n
    end if

    % after doing all the checks, actually make the turret
    turrets (n) -> initialize (n, i, make_v (mx + 0.5, my - 0.5))
    for j : mx .. mx + 1
	for k : my - 1 .. my
	    cheat (addressint, map (j) (k)) := addr (turrets (n) -> v)
	end for
    end for
    for j : max (1, (mx - 1) div MAP_M_SIZ + 1) .. min (MAP_M_WID, (mx) div MAP_M_SIZ) + 1
	for k : max (1, (my - 2) div MAP_M_SIZ + 1) .. min (MAP_M_HEI, (my - 1) div MAP_M_SIZ) + 1
	    bp := lock_sem (j, k, addr (turrets (n) -> v))
	end for
    end for
end spawn_turret_from_topleft

% using a lognormal probability distribution, weigh the choices of enemy
% against what we want to fill the power gap, spawning the ones chosen.
proc spawn_enemies
    % player power is an aggregate of the turrets on the map, the production
    % produced, and the time passed.
    var player_power : real := 0
    for i : 1 .. TURRET_NUM
	if turrets (i) -> v.state = ALIVE then
	    player_power += turrets (i) -> v.e_type ** 1.2
	end if
    end for
    player_power := (player_power ) * 10 + sqrt (prod_per_tick * 60) + ticks_passed * 0.02

    % enemy power is an aggregate of the health of enemies on the map
    var enemy_power : real := 0
    for i : 1 .. ENEMY_NUM
	if enemies (i) -> v.state = ALIVE then
	    enemy_power += ((range_enemies (enemies (i) -> v.e_type) div 6 + 1) * max_healths_enemies (enemies (i) -> v.e_type))
	end if
    end for
    var likelihood : array 1 .. ENEMY_T_NUM of real
    var llh_sum : real
    var choice : real
    var power_to_fill : real
    var power : real
    var enemies_needed : real
    var expected_num : real
    var expected_error : real
    var chance : real
    loop
	exit when enemy_power > player_power ** 1.5
	exit when num_enemies >= ENEMY_NUM
	llh_sum := 0
	enemies_needed := ENEMY_NUM - num_enemies
	power_to_fill := (player_power - 0)
	for i : 1 .. ENEMY_T_NUM
	    % given the health of an enemy and its type, find its power
	    power := ((range_enemies (i) div 6 + 1) * max_healths_enemies (i))

	    % figure out how many of that enemy we'd need to fill the power quota
	    expected_num := power_to_fill / power

	    % see how far off it is
	    expected_error := 1 / expected_num

	    % set its chance as its value on the lognormal distribution
	    chance := exp (- ((ln (expected_error) ** 2)))

	    llh_sum += chance
	    likelihood (i) := chance
	end for

	% like with choosing the chunk in spawn_enemy, choose the type of enemy to spawn
	exit when llh_sum = 0
	choice := Rand.Real () * llh_sum
	for i : 1 .. ENEMY_T_NUM
	    choice -= likelihood (i)
	    if choice < 0 then
		spawn_enemy (i)
		enemy_power += ((range_enemies (i) div 6 + 1) * max_healths_enemies (i))
		exit
	    end if
	end for
    end loop
end spawn_enemies
