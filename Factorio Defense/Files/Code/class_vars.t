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

    font := Font.New ("serif:12")
    PROD_STR_WIDTH := max (Font.Width ("Production: ", font), Font.Width ("Electricity Stored: ", font))
    NMRL_STR_WIDTH := Font.Width ("0", font)

    Mouse.ButtonChoose ("multibutton")
end startup_init

proc read_data ()
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
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
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
	projectiles (i) -> initialize (0, FLOOR, make_v (0, 0), 0)
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
    chunks_avail_for_spawn := MAP_M_WID + MAP_M_HEI * 2 - 2
    last_turret := 0
    num_turrets := 0
    can_build_turrets := true
    can_spawn := true
    num_enemies := 0
    ticks_passed := 0

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
    end for

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
	% proj_queue (last_proj_queue).target_type,
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

%Only call this when there are no enemies on the map. Turret insertion is
%after a search - O(n) - so that this works. Since we can't keep track of
%enemy targets, we can't necessarily clear them, and it'll look pretty stupid
%to have enemies, all of a sudden, get confused
/*proc resolve_turrets
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
 can_build_turrets:= true
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
 end resolve_turrets*/

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

    for k : 0 .. 1
	for i : 1 .. MAP_WIDTH
	    for j : 1 .. MAP_HEIGHT
		%for k : 0 .. 1
		map_mov (k) (i) (j) := normalize (map_mov (k) (i) (j))
	    end for
	end for
    end for

end path_map

proc draw_map ()
    var tc : int := 28
    var gl : int := 27

    Draw.FillBox (0, 0, MAP_WIDTH * PIXELS_PER_GRID, MAP_HEIGHT * PIXELS_PER_GRID, tc)
    for i : 1 .. MAP_WIDTH - 1
	Draw.Line (PIXELS_PER_GRID * i, 1, PIXELS_PER_GRID * i, MAP_HEIGHT * PIXELS_PER_GRID, gl)
    end for
    for i : 1 .. MAP_HEIGHT - 1
	Draw.Line (1, PIXELS_PER_GRID * i, MAP_WIDTH * PIXELS_PER_GRID, PIXELS_PER_GRID * i, gl)
    end for
    for i : MAP_B_W_L .. MAP_B_W_U
	for j : MAP_B_H_L .. MAP_B_H_U
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
    for i : 1 .. 0 %MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    Draw.Line (round ((i - 0.5) * PIXELS_PER_GRID),
		round ((j - 0.5) * PIXELS_PER_GRID),
		round ((i - 0.5 + map_mov (0) (i) (j).x * 0.5) * PIXELS_PER_GRID),
		round ((j - 0.5 + map_mov (0) (i) (j).y * 0.5) * PIXELS_PER_GRID),
		brightblue)
	end for
    end for
end draw_map

proc spawn_enemy (t : int)
    if can_spawn then
	var chunk_chosen := Rand.Int (1, max (1, chunks_avail_for_spawn))
	for i : 1 .. MAP_M_WID
	    for decreasing j : MAP_M_HEI .. 1
		if j = MAP_M_HEI or (i = 1 or i = MAP_M_WID) then
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

	    var found : boolean := false
	    for i : floor (max (MAP_B_W_L, v.loc.x - 1)) .. floor (min (MAP_B_W_U, v.loc.x + 1))
		for j : floor (max (MAP_B_H_L, v.loc.y - 1)) .. floor (min (MAP_B_H_U, v.loc.y + 1))
		    if map (i) (j) -> class_type = WALL then
			if Math.Distance (i, j, v.loc.x, v.loc.y) < 0.5 then
			    enemies (e) -> v.cur_target := map (i) (j)
			    found := true
			    exit
			end if
		    end if
		end for
		exit when found
	    end for

	    if not found then

		%initialize min-finder
		shortest := 4294967296.0

		%check in the appropriate chunks
		for i : floor (max (1, (v.loc.x - range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1)) ..
			floor (min (MAP_M_WID, (v.loc.x + range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1))
		    for j : floor (max (1, (v.loc.y - range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1)) ..
			    floor (min (MAP_M_HEI, (v.loc.y + range_enemies (v.e_type) - 1) / MAP_M_SIZ + 1))
			check := MAP_M_CAP - map_meta_sem (i) (j)
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

	    end if

	    enemy_on_standby (e) := false
	    enemies_on_standby -= 1
	end if
    end for

    %turrets
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
    for i : 1 .. MAP_WIDTH
	for j : 1 .. MAP_HEIGHT
	    map_deaths (i) (j) := max (map_deaths (i) (j) - 1 / 3600, 0)
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

proc spawn_turret_from_topleft (mx, my, i : int)
    num_turrets += 1
    if num_turrets >= TURRET_NUM then
	can_build_turrets := false
    end if
    var bp : boolean
    var n : int := 1
    for j : 1 .. TURRET_NUM
	if turrets (j) -> v.state < ALIVE then
	    n := j
	    exit
	end if
    end for
    if n > last_turret then
	last_turret := n
    end if

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

proc spawn_enemies
    var player_power : real := 0
    for i : 1 .. TURRET_NUM
	if turrets (i) -> v.state = ALIVE then
	    player_power += turrets (i) -> v.e_type
	    end if
    end for
    player_power := player_power*10+  sqrt (prod_per_tick * 60)
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
	exit when enemy_power > player_power**1.2
	exit when num_enemies >= ENEMY_NUM
	llh_sum := 0
	enemies_needed := ENEMY_NUM - num_enemies
	power_to_fill := (player_power - 0)
	for i : 1 .. ENEMY_T_NUM
	    power := ((range_enemies (i) div 6 + 1) * max_healths_enemies (i))
	    expected_num := power_to_fill / power
	    expected_error := 1 / expected_num
	    chance := exp (- ((ln (expected_error) ** 2)))
	    llh_sum += chance
	    likelihood (i) := chance
	end for

	exit when chance = 0
	choice := Rand.Real () * chance
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
