module Constants
    export pervasive unqualified all

    const PI : real := 3.14159265358
    const TAU : real := 2 * PI
    const SQRT_2 : real := sqrt(2)

    const PIXELS_PER_GRID : int := 16
    
    const UNCHECKED : int := maxint
    const COMPLETE : int := 0
    
    const FLOOR : int := -1
    const ENEMY : int := 0
    const FIRE : int := 1
    const TURRET : int := 2
    const WALL : int := 6

    const ALIVE : int := 1
    const DEAD : int := 0
    const NONEXISTENT : int := -1

    const PROJ_T_NUM : int := 11
    const TURRET_T_NUM : int := 3
    const ENEMY_T_NUM : int := 8
    const PROJ_NUM : int := 100
    const TURRET_NUM : int := 100
    const ENEMY_NUM : int := 100
    const PROJ_QUEUE_NUM : int := (TURRET_NUM + ENEMY_NUM) div 2
    
    const ENEMY_MVT_TILES_PER_SEC : real := 0.16

    const DAMAGE_TYPES : int := 4
    
    const MAP_WIDTH : int := 50
    const MAP_HEIGHT : int := 50
    const MAP_B_W_L : int := 11             %map "build allowed" width lower limit
    const MAP_B_W_U : int := MAP_WIDTH-10   %map "build allowed" width upper limit
    const MAP_B_H_L : int := 1              %map "build allowed" height lower limit
    const MAP_B_H_U : int := MAP_HEIGHT-10  %map "build allowed" height upper limit
    const MAP_M_SIZ : int := 5                          %metamap block size
    const MAP_M_WID : int := MAP_WIDTH div MAP_M_SIZ    %width of metamap
    const MAP_M_HEI : int := MAP_HEIGHT div MAP_M_SIZ   %height of metamap
    const MAP_M_CAP : int := MAP_M_SIZ * MAP_M_SIZ * 5  %cap of entities per block
end Constants

module Global_Vars
    export var pervasive unqualified all
    var proj_damage : array 1 .. PROJ_T_NUM of int
    var proj_speed : array 1 .. PROJ_T_NUM of real
    var proj_sprite : array 1 .. PROJ_T_NUM of int
    var proj_dmg_type : array 1 .. PROJ_T_NUM of int

    var turret_names : array 1 .. TURRET_T_NUM of string
    var max_healths_turrets : array 1 .. TURRET_T_NUM of int
    var reload_turrets : array 1 .. TURRET_T_NUM of int
    var armor_turrets : array 1 .. TURRET_T_NUM of array 1 .. DAMAGE_TYPES of int
    var range_turrets : array 1 .. TURRET_T_NUM of real
    var proj_turrets : array 1..TURRET_T_NUM of int
    var cost_turrets : array 1..TURRET_T_NUM of int
    
    var enemy_names : array 1 .. ENEMY_T_NUM of string
    var max_healths_enemies : array 1 .. ENEMY_T_NUM of int
    var reload_enemies : array 1 .. ENEMY_T_NUM of int
    var armor_enemies : array 1 .. ENEMY_T_NUM of array 1 .. DAMAGE_TYPES of int
    var range_enemies : array 1 .. ENEMY_T_NUM of real
    var proj_enemies : array 1 .. ENEMY_T_NUM of int

    var turret_on_standby : array 1 .. TURRET_NUM of boolean
    var turrets_on_standby : int := 0
    var enemy_on_standby : array 1 .. ENEMY_NUM of boolean
    var enemies_on_standby : int := 0

    %since projectiles are plentiful but short-lived, they'll be handled
    %as queues to optimize cleanup.
    var next_projectile : int := 1
    var last_projectile : int := 1
    var num_projectiles : int := 0
    var next_proj_queue : int := 1
    var last_proj_queue : int := 1
    var num_proj_queue : int := 0
    var can_fire        : boolean := true

    %enemies are less short-lived but will generally die chronologically,
    %so they'll also be handled as queues.
    var next_enemy : int := 1
    var last_enemy : int := 1
    var num_enemies : int := 0
    var can_spawn : boolean := true
    var chunks_avail_for_spawn : int :=MAP_M_SIZ * MAP_M_SIZ * 2
    
    %turrets are not short-lived, so they'll be handled as vectors.
    var last_turret : int := 0
    var num_turrets : int := 0
    var can_build_turrets : boolean := true
    
    var enemies_through : int := 0
end Global_Vars





