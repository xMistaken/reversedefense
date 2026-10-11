class_name TrackBuilder
extends RefCounted
## Builds the (invisible) path the wyrm crawls along. Every shape starts
## off-screen. Circle-stage shapes end near the party in the center;
## wagon-stage shapes end above the wagon at the bottom.

const ENTRY := 160.0  # how far off-screen the track starts

## Screen size, set by StageConfig before building, so spirals can start just
## off-screen (sections become hittable only once they can be seen).
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


# --- Ritual Circle shapes ----------------------------------------------------

## Spiral inward. `wobble` makes the rings ripple like a slithering snake.
static func spiral(center: Vector2, r_outer: float, r_inner: float, turns: float,
		start_angle: float, clockwise: bool, wobble := 0.0, wobble_freq := 6.0) -> Curve2D:
	var c := Curve2D.new()
	var dir := 1.0 if clockwise else -1.0
	c.add_point(offscreen_point(center, Vector2.from_angle(start_angle)))
	var steps := int(turns * 140)
	for i in steps + 1:
		var t := float(i) / steps
		var a := start_angle + dir * t * turns * TAU
		var r: float = lerp(r_outer, r_inner, t) + wobble * sin(a * wobble_freq) * (1.0 - t * 0.5)
		c.add_point(center + Vector2.from_angle(a) * r)
	return c


## Square spiral inward with sharp corners.
static func square_spiral(center: Vector2, half_outer: float, half_inner: float, turns: float,
		clockwise: bool) -> Curve2D:
	var c := Curve2D.new()
	var corners := int(turns * 4)
	var corner_dirs := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	if not clockwise:
		corner_dirs = [Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1)]
	var first: Vector2 = center + corner_dirs[0] * half_outer
	c.add_point(Vector2(first.x, -ENTRY))
	for i in corners + 1:
		var t := float(i) / corners
		var h: float = lerp(half_outer, half_inner, t)
		c.add_point(center + corner_dirs[i % 4] * h)
	return c


## Lazy loops: the wyrm circles wide, cuts in, and circles again (cardioid-ish).
static func looping_spiral(center: Vector2, r_outer: float, r_inner: float, turns: float,
		start_angle: float, clockwise: bool) -> Curve2D:
	var c := Curve2D.new()
	var dir := 1.0 if clockwise else -1.0
	c.add_point(offscreen_point(center, Vector2.from_angle(start_angle)))
	var steps := int(turns * 160)
	for i in steps + 1:
		var t := float(i) / steps
		var a := start_angle + dir * t * turns * TAU
		var base: float = lerp(r_outer, r_inner, t)
		# Off-center loops: the ring drifts around the party as it shrinks.
		var drift := Vector2.from_angle(a * 0.5) * (r_outer - r_inner) * 0.09 * (1.0 - t)
		c.add_point(center + drift + Vector2.from_angle(a) * base)
	return c


# --- War Wagon shapes --------------------------------------------------------

## Horizontal rows joined by U-turns, top to bottom.
static func serpentine(left: float, right: float, top: float, row_gap: float, rows: int,
		from_left := true) -> Curve2D:
	var c := Curve2D.new()
	c.add_point(Vector2(-ENTRY if from_left else right + 300.0, top))
	var radius := row_gap / 2.0
	for row in rows:
		var y := top + row * row_gap
		var going_right := (row % 2 == 0) == from_left
		var from_x := left if going_right else right
		var to_x := right if going_right else left
		c.add_point(Vector2(from_x, y))
		c.add_point(Vector2(to_x, y))
		if row == rows - 1:
			break
		var turn_center := Vector2(to_x, y + radius)
		var steps := 24
		for i in range(1, steps):
			var t := float(i) / steps
			var a := -PI / 2 + (t * PI if going_right else -t * PI)
			c.add_point(turn_center + Vector2.from_angle(a) * radius)
	return c


## Smooth S-curves sweeping down the screen.
static func sine_descent(left: float, right: float, top: float, bottom: float, waves: float) -> Curve2D:
	var c := Curve2D.new()
	var cx := (left + right) / 2.0
	var amp := (right - left) / 2.0
	c.add_point(Vector2(cx, -ENTRY))
	var steps := int(waves * 60)
	for i in steps + 1:
		var t := float(i) / steps
		c.add_point(Vector2(cx + amp * sin(t * waves * TAU), lerpf(top, bottom, t)))
	return c


## Vertical columns: the wyrm dives down, climbs up, dives down...
static func columns(left: float, right: float, top: float, bottom: float, cols: int) -> Curve2D:
	var c := Curve2D.new()
	var gap := (right - left) / (cols - 1)
	var radius := gap / 2.0
	c.add_point(Vector2(left, -ENTRY))
	for col in cols:
		var x := left + col * gap
		var down := col % 2 == 0
		c.add_point(Vector2(x, top if down else bottom))
		c.add_point(Vector2(x, bottom if down else top))
		if col == cols - 1:
			break
		var turn_center := Vector2(x + radius, bottom if down else top)
		for i in range(1, 16):
			var t := float(i) / 16
			var a := PI - t * PI if down else PI + t * PI
			c.add_point(turn_center + Vector2.from_angle(a) * radius)
	return c


## Diagonal zig-zag with sharp turns.
static func zigzag(left: float, right: float, top: float, bottom: float, legs: int) -> Curve2D:
	var c := Curve2D.new()
	c.add_point(Vector2(left, -ENTRY))
	for i in legs + 1:
		var t := float(i) / legs
		c.add_point(Vector2(left if i % 2 == 0 else right, lerpf(top, bottom, t)))
	return c
