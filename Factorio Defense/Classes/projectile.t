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


    proc initialize (t, tt, pt : int, l : point)
	v.target := t
	v.target_type := tt
	v.p_type := pt
	v.loc := l
	v.state := ALIVE
    end initialize

    %update
    proc update (var u : entity_vars)
	%only if projectile is alive
	if v.state = ALIVE then
	    %if the target is alive, work; otherwise, projectile is now invalid
	    if u.state = ALIVE then
		%if within range, do damage and invalidate; otherwise,
		%move closer
		if distance_squared (u.loc, v.loc) <= 0.25 then
		    u.health -= proj_damage (v.p_type)
		    v.state := NONEXISTENT
		else
		    v.loc := add_v (v.loc,
			truncate (
			diff_v (u.loc, v.loc),
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
    end draw
end Projectile
