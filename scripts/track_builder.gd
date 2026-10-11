class_name TrackBuilder
extends RefCounted
## Builds the (invisible) path the wyrm crawls along. Every shape starts
## off-screen, so the wyrm slides in from outside and its queued sections stay
## hidden until they cross the screen edge. Shapes pack in as many bends as
## the screen holds: rows sit just over a body-width apart. Circle-stage shapes
## end at the ring around the party; wagon-stage shapes end above the wall.

const ENTRY := 160.0       # how far off-screen the track starts
const ROW_GAP := 205.0     # tightest spacing between parallel runs (body is ~160 wide)
const TURN_RADIUS := 100.0 # U-turns and corners

## Screen size, set by StageConfig before building.
static var view := Vector2(1080, 1920)


## Point on the ray from `from` along `dir` that lies ENTRY px beyond the screen edge.
static func offscreen_point(from: Vector2, dir: Vector2) -> Vector2:
	var bounds := Rect2(Vector2(-ENTRY, -ENTRY), view + Vector2(ENTRY, ENTRY) * 2.0)
	var t := INF
	if dir.x > 0.001:
		t = minf(t, (bounds.end.x - from.x) / dir.x)
	elif dir.x < -0.001:
		t = minf(t, (bounds.position.x - from.x) / dir.x)
	if dir.y > 0.001:
		t = minf(t, (bounds.end.y - from.y) / dir.y)
	elif dir.y < -0.001:
		t = minf(t, (bounds.position.y - from.y) / dir.y)
	return from + dir * t


## A curve through `points` with every corner rounded off by an arc of
## `radius` (smaller where the legs are too short for it).
static func rounded(points: PackedVector2Array, radius: float = TURN_RADIUS) -> Curve2D:
	var c := Curve2D.new()
	c.add_point(points[0])
	for i in range(1, points.size() - 1):
		var p := points[i]
		var d1 := points[i - 1] - p
		var d2 := points[i + 1] - p
		var l1 := d1.length()
		var l2 := d2.length()
		if l1 < 1.0 or l2 < 1.0:
			continue
		d1 /= l1
		d2 /= l2
		var half := d1.angle_to(d2)
		half = absf(half) / 2.0  # half the corner's inner angle
		if half > PI / 2.0 - 0.01:  # straight on: no corner
			c.add_point(p)
			continue
		var t := minf(radius / tan(half), minf(l1, l2) * 0.5)
		var r := t * tan(half)
		var t1 := p + d1 * t
		var t2 := p + d2 * t
		var centre := p + (d1 + d2).normalized() * (r / sin(half))
		var a0 := (t1 - centre).angle()
		var sweep := wrapf((t2 - centre).angle() - a0, -PI, PI)
		var steps := maxi(4, ceili(absf(sweep) * r / 14.0))
		for k in steps + 1:
			c.add_point(centre + Vector2.from_angle(a0 + sweep * k / steps) * r)
	c.add_point(points[-1])
	return c


static func _curve(points: PackedVector2Array) -> Curve2D:
	var c := Curve2D.new()
	for p in points:
		c.add_point(p)
	return c


static func _mirror(points: PackedVector2Array) -> PackedVector2Array:
	for i in points.size():
		points[i].x = view.x - points[i].x
	return points


# --- Ritual Circle shapes ----------------------------------------------------
# The screen is tall and narrow, so concentric laps don't fit; these shapes
# get their bends from loops, petals and meanders around the ring instead.

## One lap round the party, squashed to fill the tall screen, rippling as it
## winds in. `wobble` is the ripple size.
static func spiral(center: Vector2, r_inner: float, start_angle: float, clockwise: bool,
		turns: float, wobble: float, wobble_freq: float) -> Curve2D:
	var dir := 1.0 if clockwise else -1.0
	var pts := PackedVector2Array()
	var steps := int(turns * 220)
	for i in steps + 1:
		var t := float(i) / steps
		var a := start_angle + dir * t * turns * TAU
		var r := lerpf(view.x * 0.42, r_inner, t) + wobble * sin(a * wobble_freq) * (1.0 - t)
		var squash := lerpf(1.75, 1.0, t)
		pts.append(center + Vector2(cos(a) * r, sin(a) * r * squash))
	pts.insert(0, offscreen_point(pts[0], pts[0] - pts[1]))
	return _curve(pts)


## Petal loops: the wyrm swings out towards the screen edge and back in to
## the ring, again and again, as it circles the party.
static func petals(center: Vector2, r_inner: float, start_angle: float, clockwise: bool,
		turns: float, count: int) -> Curve2D:
	var dir := 1.0 if clockwise else -1.0
	var pts := PackedVector2Array()
	var steps := int(turns * 400)
	var r_out := view.x * 0.47
	for i in steps + 1:
		var t := float(i) / steps
		var a := start_angle + dir * t * turns * TAU
		var swing := (0.5 - 0.5 * cos(t * turns * count * TAU)) * (1.0 - t * 0.75)
		var r := lerpf(r_inner, r_out, swing)
		var squash := lerpf(1.0, 1.85, swing)
		pts.append(center + Vector2(cos(a) * r, sin(a) * r * squash))
	# Begin at a petal tip, coming in from off-screen.
	pts.insert(0, offscreen_point(pts[0], (pts[0] - center).normalized()))
	return _curve(pts)


## Meander: tight rows across the open space above the ring, down the side,
## rows across the space below, then a last lap onto the ring.
static func meander(center: Vector2, r_inner: float, mirrored: bool, top_rows: int, bottom_rows: int) -> Curve2D:
	var left := 105.0
	var right := view.x - 105.0
	var top := 300.0
	var ring_top := center.y - r_inner - 90.0
	var ring_bottom := center.y + r_inner + 90.0
	var pts := PackedVector2Array()
	var gap := minf(ROW_GAP, (ring_top - top) / maxf(1.0, top_rows - 1))
	pts.append(Vector2(-ENTRY, top))
	var on_right := false
	for row in top_rows:
		var y := top + row * gap
		if row > 0:
			pts.append(Vector2(right if on_right else left, y))
		on_right = not on_right
		pts.append(Vector2(right if on_right else left, y))
	# Down the side, then rows below the ring, working downwards.
	var bottom := view.y - 120.0
	var bgap := minf(ROW_GAP, (bottom - ring_bottom) / maxf(1.0, bottom_rows - 1))
	for row in bottom_rows:
		var y := ring_bottom + row * bgap
		pts.append(Vector2(right if on_right else left, y))
		on_right = not on_right
		pts.append(Vector2(right if on_right else left, y))
	# Back up the side and onto the ring.
	var side := right if on_right else left
	pts.append(Vector2(side, center.y + r_inner * 0.4))
	var curve := rounded(_mirror(pts) if mirrored else pts)
	var last := curve.get_point_position(curve.point_count - 1)
	var a0 := (last - center).angle()
	var dir := -1.0 if (side < center.x) != mirrored else 1.0
	for i in range(1, 61):
		var a := a0 + dir * i / 60.0 * PI * 0.9
		curve.add_point(center + Vector2.from_angle(a) * lerpf((last - center).length(), r_inner, i / 60.0))
	return curve


## Coils: a lap round the party made of loop-the-loops that unwind as the
## wyrm closes in on the ring.
static func coil(center: Vector2, r_inner: float, start_angle: float, clockwise: bool,
		loops: int, loop_radius: float) -> Curve2D:
	var dir := 1.0 if clockwise else -1.0
	var pts := PackedVector2Array()
	var steps := loops * 90
	for i in steps + 1:
		var t := float(i) / steps
		var a := start_angle + dir * t * TAU * 0.95
		var base_r := lerpf(view.x * 0.34, r_inner, t)
		var squash := lerpf(1.8, 1.0, t)
		var base := center + Vector2(cos(a) * base_r, sin(a) * base_r * squash)
		# Loop size fades out over the last quarter so the head lands cleanly.
		var lr := loop_radius * clampf((1.0 - t) * 4.0, 0.0, 1.0)
		var phase := a - dir * t * loops * TAU
		pts.append(base + (Vector2.from_angle(phase) - Vector2.from_angle(a)) * lr)
	pts.insert(0, offscreen_point(pts[0], (pts[0] - center).normalized()))
	return _curve(pts)


# --- War Wagon shapes --------------------------------------------------------

## Horizontal rows joined by tight U-turns, top to bottom. `wiggle` makes
## each row ripple (`waves` humps per row).
static func serpentine(left: float, right: float, top: float, bottom: float, gap: float,
		from_left := true, wiggle := 0.0, waves := 3) -> Curve2D:
	var rows := maxi(2, int((bottom - top) / gap) + 1)
	gap = (bottom - top) / (rows - 1)
	var radius := gap / 2.0
	var pts := PackedVector2Array()
	pts.append(Vector2(-ENTRY if from_left else view.x + ENTRY, top))
	for row in rows:
		var y := top + row * gap
		var going_right := (row % 2 == 0) == from_left
		var x0 := left if going_right else right
		var x1 := right if going_right else left
		var n := 48
		for i in n + 1:
			var t := float(i) / n
			pts.append(Vector2(lerpf(x0, x1, t), y - wiggle * sin(t * waves * PI)))
		if row == rows - 1:
			break
		var turn_center := Vector2(x1, y + radius)
		for i in range(1, 20):
			var a := -PI / 2 + (i / 20.0 * PI if going_right else -i / 20.0 * PI)
			pts.append(turn_center + Vector2.from_angle(a) * radius)
	return _curve(pts)


## Diagonal zig-zag down the screen with rounded corners.
static func zigzag(left: float, right: float, top: float, bottom: float, legs: int, from_left: bool) -> Curve2D:
	var pts := PackedVector2Array()
	pts.append(Vector2(left if from_left else right, -ENTRY))
	for i in legs + 1:
		var t := float(i) / legs
		var on_left := (i % 2 == 0) == from_left
		pts.append(Vector2(left if on_left else right, lerpf(top, bottom, t)))
	return rounded(pts, 90.0)


## Rows with loop-the-loops along them.
static func curly(left: float, right: float, top: float, bottom: float, rows: int,
		loops_per_row: int, loop_radius: float, from_left: bool) -> Curve2D:
	var gap := (bottom - top) / (rows - 1)
	var radius := gap / 2.0
	var pts := PackedVector2Array()
	pts.append(Vector2(-ENTRY if from_left else view.x + ENTRY, top))
	for row in rows:
		var y := top + row * gap
		var going_right := (row % 2 == 0) == from_left
		var s := 1.0 if going_right else -1.0
		var x0 := left if going_right else right
		var x1 := right if going_right else left
		var seg := (right - left) / (loops_per_row + 1)
		var w := loop_radius * 1.2  # forward travel while looping
		pts.append(Vector2(x0, y))
		for k in range(1, loops_per_row + 1):
			var xc := x0 + s * k * seg
			# Trochoid: the body rises, loops back over itself and carries on.
			for i in 41:
				var u := i / 40.0
				pts.append(Vector2(xc + s * ((u - 0.5) * w + loop_radius * sin(u * TAU)),
					y - loop_radius * (1.0 - cos(u * TAU))))
		pts.append(Vector2(x1, y))
		if row == rows - 1:
			break
		var turn_center := Vector2(x1, y + radius)
		for i in range(1, 20):
			var a := -PI / 2 + (i / 20.0 * PI if going_right else -i / 20.0 * PI)
			pts.append(turn_center + Vector2.from_angle(a) * radius)
	return _curve(pts)
