class_name TrackBuilder
extends RefCounted
## Builds the path the wyrm crawls along for each stage type.

const ENTRY := 160.0  # how far off-screen the track starts


## Ritual Circle: enters from the top, then spirals inward toward the party.
static func spiral(center: Vector2, r_outer: float, r_inner: float, turns: float) -> Curve2D:
	var c := Curve2D.new()
	c.add_point(Vector2(center.x, -ENTRY))
	var steps := int(turns * 120)
	for i in steps + 1:
		var t := float(i) / steps
		var a := -PI / 2 + t * turns * TAU
		var r: float = lerp(r_outer, r_inner, t)
		c.add_point(center + Vector2(cos(a), sin(a)) * r)
	return c


## War Wagon: enters from the left, then zig-zags down the screen in rows.
static func serpentine(left: float, right: float, top: float, row_gap: float, rows: int) -> Curve2D:
	var c := Curve2D.new()
	c.add_point(Vector2(-ENTRY, top))
	var radius := row_gap / 2.0
	for row in rows:
		var y := top + row * row_gap
		var going_right := row % 2 == 0
		var from_x := left if going_right else right
		var to_x := right if going_right else left
		c.add_point(Vector2(from_x, y))
		c.add_point(Vector2(to_x, y))
		if row == rows - 1:
			break
		# Half-circle U-turn down to the next row.
		var turn_center := Vector2(to_x, y + radius)
		var steps := 24
		for i in range(1, steps):
			var t := float(i) / steps
			var a := -PI / 2 + (t * PI if going_right else -t * PI)
			c.add_point(turn_center + Vector2(cos(a), sin(a)) * radius)
	return c
