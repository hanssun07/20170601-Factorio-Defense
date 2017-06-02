include "Files\\Code\\globals.t"
include "Files\\Code\\infrastructure.t"
include "Classes\\projectile.t"
include "Classes\\turret.t"
include "Classes\\enemy.t"
include "Files\\Code\\class_vars.t"

const TESTS : int := 100000
var a, b, c : point
var n, m : real
var j,t : int := 1
t := Time.Elapsed
for i : 1 .. TESTS
    if Rand.Real () > 0.7 then
	a.x := 0
    else
	a.x := Rand.Real () * 100 - 50
    end if
    if Rand.Real () > 0.7 then
	a.y := 0
    else
	a.y := Rand.Real () * 100 - 50
    end if
    b := make_v (a.x, a.y)
    %put v_to_string (a), " equals ", v_to_string (b) ..
    assert (equal_v (a, b))
    locate(j, 1)
    %put i, ": GOOD"
end for
locate(j, 1)
j += 1
put "**********  make_v, equal_v: PASS" : 50, "(", Time.Elapsed - t, ")"

fcn rand_point () : point
    var a : point
    if Rand.Real () > 0.7 then
	a.x := 0
    else
	a.x := Rand.Real () * 100 - 50
    end if
    if Rand.Real () > 0.7 then
	a.y := 0
    else
	a.y := Rand.Real () * 100 - 50
    end if
    result a
end rand_point

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    b := rand_point ()
    c.x := a.x + b.x
    c.y := a.y + b.y
    %put v_to_string (a), " + ", v_to_string (b), " = ", v_to_string (c) ..
    assert (equal_v (add_v (a, b), c))
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  add_v: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    %put v_to_string (a), " : mag^2 ", magnitude_squared(a) ..
    assert (magnitude_squared(a) = a.x*a.x + a.y*a.y)
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  tmagnitude_squared: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    b := rand_point ()
    c.x := a.x + b.x
    c.y := a.y + b.y
    %put v_to_string (a), " + ", v_to_string (b), " = ", v_to_string (c) ..
    assert (magnitude_squared(add_v (a, b))= magnitude_squared(c))
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  tmagnitude_squared for add_v: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    b := rand_point ()
    c.x := a.x - b.x
    c.y := a.y - b.y
    %put v_to_string (a), " - ", v_to_string(b), " = ", v_to_string(c) ..
    assert (equal_v(diff_v(a, b), c))
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  tdiff_v: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    n := Rand.Real() * 20 - 10
    b := scale_v(a,n)
    %put v_to_string (a), " * ", n, " = ", v_to_string(b)..
    assert (equal_v(b, make_v(a.x*n, a.y*n)))
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  scale_v: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    n := Rand.Real() * TAU
    m := Rand.Real() * 10
    b := add_v(a, scale_v(make_v(cos(n), sin(n)),m))
    %put v_to_string (a), " to ", v_to_string(b), " : ", m..
    assert (cmp_f(distance_squared(a, b),m*m))
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  distance_squared: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    n := Rand.Real() * TAU
    m := Rand.Real() * 49.9999+.0001
    a := make_v(cos(n), sin(n))
    b := scale_v(a, m)
    %put v_to_string (b), " ^= ", v_to_string(a) ..
    assert (equal_v(a, normalize(b)))
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  reverse normalize" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    n := Rand.Real() * TAU
    m := Rand.Real() * 50
    a := scale_v(make_v(cos(n), sin(n)),m)
    %put v_to_string (a), " : ", n, " rad"..
    assert (cmp_f(angle_v(a), n))
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  angle_v: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    m := Rand.Real()*20
    b := truncate(a, m)
    locate(j, 1)
    %put v_to_string (a), " to ", m, " : ", v_to_string(b)
    %put v_to_string (normalize(a)), " to ", m, " : ", v_to_string(normalize(b))
    %put normalize (a).x : 23 : 20, normalize (a).y : 23 : 20
    %put normalize (b).x : 23 : 20, normalize (b).y : 23 : 20
    assert (magnitude_squared(b) <= magnitude_squared(a) and cmp_f(angle_v(a), angle_v(b)))
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  truncate: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    b := normalize(a)
    %put v_to_string (a), " ^= ", v_to_string(b) ..
    assert (magnitude_squared(a) = 0 or (cmp_f(magnitude_squared(b),1.0) and cmp_f(angle_v(a), angle_v(b))))    
    locate(j, 1)
    %put i, ": GOOD\r"
end for
locate(j, 1)
j += 1
put "**********  forward normalize: PASS" : 50, "(", Time.Elapsed - t, ")"

t := Time.Elapsed
for i : 1 .. TESTS*10
    a := truncate(rand_point(), Rand.Real())
    %locate(j, 1)
    %put v_to_string (a) ..
    assert (true)
    %put i, ": GOOD\r"
end for
j += 1
locate(j, 1)
put "**********  truncate benchmark" : 50, "(", Time.Elapsed - t, ") : ", TESTS * 10

if false then
t := Time.Elapsed
for i : 1 .. TESTS
    a := rand_point ()
    locate(j, 1)
    put v_to_string (a) ..
    assert (true)
    %put i, ": GOOD\r"
end for
j += 1
locate(j, 1)
put "**********  : PASS" : 50, "(", Time.Elapsed - t, ")"
end if
