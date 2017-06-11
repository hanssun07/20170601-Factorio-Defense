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
    const PROJ_NUM : int := 1000
    const TURRET_NUM : int := 100
    const ENEMY_NUM : int := 50
    const PROJ_QUEUE_NUM : int := (TURRET_NUM + ENEMY_NUM) div 2
    
    const ENEMY_MVT_TILES_PER_SEC : real := 0.16

    const DAMAGE_TYPES : int := 4
    
    const MAP_WIDTH : int := 50
    const MAP_HEIGHT : int := 50
    const MAP_B_W_L : int := 6             %map "build allowed" width lower limit
    const MAP_B_W_U : int := MAP_WIDTH-5   %map "build allowed" width upper limit
    const MAP_B_H_L : int := 1              %map "build allowed" height lower limit
    const MAP_B_H_U : int := MAP_HEIGHT-5  %map "build allowed" height upper limit
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
    
    var armor_wall : array 1..DAMAGE_TYPES of int := init(30,100,0,0)

    var turret_names : array 1 .. TURRET_T_NUM of string
    var proj_names : array 1..TURRET_T_NUM of string
    var max_healths_turrets : array 1 .. TURRET_T_NUM of int
    var reload_turrets : array 1 .. TURRET_T_NUM of int
    var armor_turrets : array 1 .. TURRET_T_NUM of array 1 .. DAMAGE_TYPES of int
    var range_turrets : array 1 .. TURRET_T_NUM of real
    var proj_turrets : array 1..TURRET_T_NUM of int
    var colors_turrets : array 1..TURRET_T_NUM of int := init(6,2,4)
    var selection_num_turrets: array 1..TURRET_T_NUM of int := init (6, 8, 10)
    
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
    var ticks_passed : int := 0
    var ticks_to_repath : int := 600
end Global_Vars

module Sidebar
    export var pervasive unqualified all

    var prod_avail : int
    var prod_per_tick : real
    var ticks_to_next_prod : real
    var ticks_per_prod : real
    var prod_distribution_prod : real
    var prod_distribution_prod_user : real
    var prod_distribution_prod_y : int

    %electricity (laser turrets, production)
    var electricity_production : real
    var electricity_consumption : real
    var electricity_storage : real
    var electricity_stored : real
    var prod_until_next_e_storage : real
    var prod_distribution_electricity : real
    var prod_distribution_electricity_user : real
    var prod_distribution_electricity_y : int
    var prod_distribution_electricity_storage : real
    var prod_distribution_electricity_storage_user : real
    var prod_distribution_electricity_storage_y : int

    %repair packs
    var prod_until_next_repair : real
    var prod_per_repair : real
    var num_repair_available : real
    var prod_distribution_repair : real
    var prod_distribution_repair_user : real
    var prod_distribution_repair_y : int
    
    %walls
    var prod_until_next_wall : real
    var prod_per_wall : real
    var num_wall_avail : int
    var prod_distribution_wall : real
    var prod_distribution_wall_user : real
    var prod_distribution_wall_y : int
    
    %turrets and projectiles
    var prod_until_next_turret : array 1 .. TURRET_T_NUM of real
    var prod_until_next_proj : array 1 .. TURRET_T_NUM of real
    var num_turrets_avail : array 1 .. TURRET_T_NUM of int
    var num_proj_avail : array 1 .. TURRET_T_NUM of int
    var prod_per_turret : array 1 .. TURRET_T_NUM of int
    var prod_per_proj : array 1 .. TURRET_T_NUM of int
    var turret_enabled : array 1 .. TURRET_T_NUM of boolean
    var prod_distribution_turrets : array 1 .. TURRET_T_NUM of real
    var prod_distribution_turrets_user : array 1 .. TURRET_T_NUM of real
    var prod_distribution_turrets_y : array 1 .. TURRET_T_NUM of int
    var prod_distribution_proj : array 1 .. TURRET_T_NUM of real
    var prod_distribution_proj_user : array 1 .. TURRET_T_NUM of real
    var prod_distribution_proj_y : array 1 .. TURRET_T_NUM of int

    %research
    const RESEARCH_NUM : int := 28
    var research_name : array 1..RESEARCH_NUM of string
    var research_enabled : array 1..RESEARCH_NUM of boolean
    var prod_until_research_done : array 1..RESEARCH_NUM of real
    var prod_per_research : array 1..RESEARCH_NUM of real
    var research_effect : array 1..RESEARCH_NUM of string
    var research_effect_2 : array 1..RESEARCH_NUM of string
    var research_prereq : array 1..RESEARCH_NUM of array 1..RESEARCH_NUM of boolean
    var prod_distribution_research : array 1..RESEARCH_NUM of real
    var prod_distribution_research_user : array 1..RESEARCH_NUM of real
    var prod_distribution_research_y : array 1..RESEARCH_NUM of int
    
    %rockets
    var prod_until_rocket : real
    var rocket_enabled : boolean
    var prod_distribution_rocket : real
    var prod_distribution_rocket_user : real
    var prod_distribution_rocket_y : int
    
    var prod_dist_ys_count : int
    var prod_dist_ys : array 1..50 of unchecked ^int
    var prod_dist_selectable : array 1..50 of boolean
    var prod_dist_allocs : array 1..50 of unchecked ^real
    var prod_dist_allocs_agg : array 0..50 of real
    var prod_dist_allocs_ys  : array 1..50 of int
    
    var font : int
    
    const INTFC_BEGIN : int := MAP_WIDTH * PIXELS_PER_GRID+1
    const ACTUAL_BEGIN : int := INTFC_BEGIN + 10
    const CONTROL_BEGIN : int := ACTUAL_BEGIN + 20
    const COLORS : array 1..6 of int := init(59,64,67,71,75,79)
    const NUM_COLORS : int := 6
    const ALLOC_BEGIN : int := 720
    const ALLOC_HEIGHT : int := ALLOC_BEGIN-20
    
    var PROD_STR_WIDTH : int
    var NMRL_STR_WIDTH : int
    
    const PRESSED : int := 1
    const RELEASED : int := 0
    const LEFT : int := 1
    const MIDDLE : int := 2
    const RIGHT : int := 3
    var mouse_on_alloc_bar : boolean := false
    var alloc_bar_selected : int := 0
    var mouse_over_item : int := 1
    var mouse_item_selected : int := 1
    var bar_s_x : int
    var bar_s_y : int
    var pd_at_selection : real
    
end Sidebar

