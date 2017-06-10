%will have imported :/ point             (record)
%                /     distance_squared  (function: point, point : real)
%                /     truncate          (function: point, real : point)
%                /     add_v             (function: point, point : point)
%                /     diff_v            (function: point, point : point)
%                /     angle             (function: point : real)
%                /     proj_damage       (array)
%                /     proj_sprite       (array)
%                /     proj_speed        (array)
%                     enemies           (array)
%                     turrets           (array)
%                /     pixels_per_grid   (int)
%                /     ENEMY               0
%                /     TURRET              1
%                /     ALIVE               1
%                     Pic.Draw

class Projectile
    export var all

    var v : proj_vars


    proc initialize (t : cheat
	unchecked ^entity_vars, pt : int, l : point, dmg : int)
	v.target := t
	%v.target_type := tt
	v.p_type := pt
	v.loc := l
	v.state := ALIVE
	v.dmg := dmg
    end initialize

    %update
    proc update ()
	%only if projectile is alive
	if v.state = ALIVE then
	    %if the target is alive, work; otherwise, projectile is now invalid
	    if v.target -> state = ALIVE then
		%if within range, do damage and invalidate; otherwise,
		%move closer
		if distance_squared (v.target -> loc, v.loc) <= 0.25 then
		    v.target -> health -= v.dmg
		    v.state := NONEXISTENT
		else
		    v.loc := add_v (v.loc,
			truncate (
			diff_v (v.target -> loc, v.loc),
			proj_speed (v.p_type)))
		end if
	    else
		v.state := NONEXISTENT
	    end if
	end if
    end update

    %draw
    proc draw
	%to be overhauled
	%Pic.Draw (proj_sprite (p_type) ((angle_v (diff_v (turrets (target) -> get_loc (), loc))div 10 )mod 10),
	%    (loc.x - .5) * pixels_per_grid,
	%    (loc.y - .5) * pixels_per_grid,
	%    picMerge)
	if v.state < ALIVE then
	    return
	end if
	var dsc_x : int := round ((v.loc.x - 0.5) * PIXELS_PER_GRID)
	var dsc_y : int := round ((v.loc.y - 0.5) * PIXELS_PER_GRID)
	Draw.FillBox(dsc_x-1, dsc_y-1,dsc_x+1,dsc_y+1, v.p_type+32)
    end draw
end Projectile
