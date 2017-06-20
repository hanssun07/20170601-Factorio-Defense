# Construction of the Game
Making this game presented many challenges, and in the end it was completed with many, many interesting optimizations and infrastructure.
This is intended to be a comprehensive list of those challenges, optimizations, and infrastructure decisions.

### Pathing
The very first problem I thought of was that of pathing fifty entities through a fifty-by-fifty-tile map with multiple possible endpoints. While [A\*](https://en.wikipedia.org/wiki/A*_search_algorithm) is optimal against [Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) in the sense that it's not just a BFS, it only works well with one endpoint. [JPS](https://en.wikipedia.org/wiki/Jump_point_search), the only other algorithm I know of which is efficient in node-dense graphs, wouldn't work either as it requires that all edges have uniform weights. If that were the case, I wouldn't be able to prevent aliens from running straight into their own deaths. Even if they worked, they'd have to be run fifty times every few ticks; which is unacceptable in a language as slow as Turing.

In addition to the issues with timing, storing paths, moving smoothly, and avoiding bunching up would have presented a massive headache.

So, instead of pathing each individual alien, I decided to have them follow a game-generated flow field. This way, only one call to a pathing algorithm would be needed every few hundred ticks, no paths would need to be stored, and moving smoothly and not bunching up becomes rather trivial.

In `Files/Code/class_vars.t`, you can find `proc path_map()`, which generates the flow field (`map_mov`) using Dijkstra's algorithm with the appropriate source points. Above it, you'll find `push_to_heap` and `pop_from_heap`, which were needed for the priority queue.

In `Classes/enemy.t`, you can find in `proc pre_update()` that, after following the flow field, aliens will check for other aliens around so as to not invade each other's personal space. The algorithm is based on the Separation behaviour outlined in [Craig W. Reynolds' Steering Behaviors for Autonomous Characters](http://www.red3d.com/cwr/steer/gdc99/).

### Projectile Efficiency
Ideally, turrets will not waste ammunition firing at aliens which would have die once all the already-in-the-air projectiles have reached their target. But because a lot of projectiles are not instantaneous, turrets and aliens can't directly lower the health of their targets when firing.

Instead, all entities have an `effective_health` as well as their `health`.

You can find the health interactions between turrets, projectiles, and aliens in `Classes/enemy.t` and `Classes/turret.t` in `proc fire_projectile (u : unchecked ^entity_vars)` and in `Classes/projectile.t` in `proc update()` inside the hit checks.

### Choosing Targets
Ideally, turrets and spitters (ranged aliens) would aim for and fire at the closest target. But Turing is slow, and checking ranges and finding the nearest of fifty aliens for up to a hundred turrets and vice-versa every tick would be an issue.

Instead, each entity can cache a target, and search for a new one once that target has died or has left its range.

In `Classes/enemy.t` and `Classes/turret.t`, you can see that in `proc update()`, in addition to the other checks for validity, every entity will check if they have a target, if the target is dead (or effective health indicates such), or if they are out of range before either firing or preparing to fire a projectile or, in the case of the aliens, move.

This optimization, however, created several problems.

### Retaining Targets and Standardizing Entities
In C++, caching a target would be straightforward. The different entities' classes would have been prototyped in a header file, and code for its member functions would be found in a `.cpp` file. The cached target would simply be a pointer to the other type of entity; NULL if no target existed. In Turing? Not so.

In Turing, there are no class prototype declarations, and handling pointers requires a whole lot of red tape; initially, I didn't even think that pointers could be handled at all. This was the first major roadblock of development: how would targets be cached?

At first, I thought of referencing another entity by storing the index at which the target is located in the array of turret or aliens. But this had a major problem, and lead to many more: if enemies would only store an index for a target turret, how would they target walls that they would need to destroy to get to their goal? If walls had the same structure as other entities, then his would work just like a pointer - but with a whole lot more red tape. Would walls even have the same structure as turrets and aliens? If they do, how should fire - which, like walls, are bound to the map - be represented?

I realized that turrets and enemies had pretty much exactly the same variables, and decided to standardize all entities so that their properties are stored in a communal type. As such, targets can be cached like pointers.

Could targets be cached, not _like_ pointers, but rather _as_ pointers? It turns out they can.

The Turing Documentation says, for the keyword `unchecked`,
> ... unchecked pointers are like C language pointers.

Well, thanks, Turing. Why not just call them pointers, then?

In `Files/Code/infrastructure.t`, you can find the communal `type entity_vars` for all entities: records which hold all the relevant variables for every entity, including `cur_target`, an `unchecked pointer to entity_vars`. You can also see that `proj_vars` keeps an `unchecked pointer to entity_vars` target as well.

### Searching for Targets
With the decision that targets will be requested when needed comes the need for a procedure to assign targets. When aliens or turrets request a target, they'll flag themselves on "standby." Then they just have to check the distance between them and all the possible targets, looking for the closest one.

"_All_ the possible targets," I thought, might be a problem. Could they just check the ones that _might_ possibly be in range?

I decided that, instead of checking by entity, they would check by location on the map. To do that, the map would have to store references to entities. To do that efficiently, the map would have to be split into chunks, each storing a list of pointers pointing to the entities in that chunk.

Since we weren't allowed to use "flexible" arrays, those lists would be fixed-sized, and each chunk would need a semaphore that would close if the lists were filled. Assigning targets would check through close-enough chunks; if there were entities there, they would be checked for type and distance and be assigned as target accordingly.

In `Files/Code/class_vars` is `proc resolve_targets()`, which is the entire target assignment algorithm. Aliens have an override in their own file if they're too close to a wall (there wasn't any collision handling; if an alien was too close to a wall, it would target the wall, forcing immobility).

In `Files/Code/infrastructure`, you can find the `map_meta`, the chunk handler; `map_meta_sem`, the semaphore; `fcn lock_sem(x, y, e)`, a function to add a entity_var to a chunk and lock the semaphore one level; and `proc unlock_sem(x, y, e)`, which does the opposite.

### Handling Projectiles (and Aliens)
In this project, I was not allowed to use `flexible` arrays (which is, really, just another way that Turing obfuscates pointers). As such, everything was implemented in fixed-size arrays. But how would projectiles, plentiful and short-lived, be handled?

Naively handling them as a vector, shifting everything over whenever one was destroyed, could be a performance bottleneck. So instead, it was to be implemented as a queue.

Such a task actually entailed creating two queues: one for the projectiles in play, and one for entities to queue projectiles waiting to be fired in case the first was full. Projectiles were pushed when fired and popped when at the front and no longer in use. The list of aliens were handled the same way.

In `Files/Code/globals.t`, you can find the infrastructure variables used for the queues.

The implementation of the queues can be found in `Files/Code/entity_vars.t` in `proc resolve_projectiles()` and `proc resolve_enemies()`.
