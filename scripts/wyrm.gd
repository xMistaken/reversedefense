class_name Wyrm
extends Node2D
## The wyrm: an indestructible head leading a long, continuous body made of
## overlapping plates. Plates are grouped into **sections** (class Segment);
## each section has one HP pool. Chest sections are glowing orbs embedded in
## the body.
##
## Sections sit at distances ("offsets") along the hidden track. The rearmost
## section drives the chain forward. The chain always stays connected: when a
## section is destroyed, everything ahead of it (including the head) slides
## back to close the gap. When the head reaches the end of the track it stops
## at the wall and chews on it (see `at_wall()`); the stage drains wall HP.

signal segment_destroyed(seg: Segment)
signal cleared

const PLATE_SPACING := 26.0   # distance between plates along the body
const PLATE_RADIUS := 52.0    # half the body's width
const RADIUS := PLATE_RADIUS  # used for effect sizes
const HEAD_GAP := 70.0        # head centre ahead of the first plate
const ORB_PLATES := 3
const DOT_DURATION := 3.0
const MEND_RATE := 0.05       # fraction of max HP per second healed into neighbours
const INTRO_SPEED_MUL := 5.0
const RETRACT_SPEED := 650.0  # how fast the front slides back to close a gap
const BODY_HEIGHT := 215.0    # on-screen height of the painted body (incl. spikes)
const BAND_OVERLAP := 0.35    # extra width each body slice draws, hides gaps on bends
const HEAD_SCALE := 0.5
const TAIL_SCALE_MUL := 1.25  # tail art scale relative to the body art
const ORB_SCALE := 0.52

## A section of the body: several plates sharing one HP pool.
class Segment:
	var id := 0
	var type := "flesh"
	var plates := 6
	var first_plate := 0       # index of this section's front plate in the whole body (texture slicing)
	var hp := 1.0
	var max_hp := 1.0
	var armor := 0.0
	var offset := 0.0          # front plate's distance along the track
	var pos := Vector2.ZERO    # middle plate (labels, effects, targeting)
	var dir := Vector2.RIGHT
	var plate_pos := PackedVector2Array()
	var plate_angle := PackedFloat32Array()
	var plate_visible := PackedByteArray()
	var bound := 0.0           # broad-phase radius around `pos`
	var dot := 0.0
	var dot_time := 0.0
	var flash := 0.0
	var alive := true

	func on_track() -> bool:
		return offset >= 0.0

	func length() -> float:
		return plates * PLATE_SPACING

	func is_orb() -> bool:
		return type == "hero_chest" or type == "skill_chest"

	## Does a circle at `p` with radius `r` touch any visible plate?
	func hit_test(p: Vector2, r: float) -> bool:
		if not on_track() or p.distance_squared_to(pos) > (bound + r) * (bound + r):
			return false
		var rr := (PLATE_RADIUS + r) * (PLATE_RADIUS + r)
		for k in plates:
			if plate_visible[k] and p.distance_squared_to(plate_pos[k]) <= rr:
				return true
		return false

var curve: Curve2D
var length := 0.0
var segments: Array[Segment] = []  # index 0 = front (right behind the head), last = tail
var head_offset := 0.0
var head_pos := Vector2.ZERO
var head_dir := Vector2.RIGHT
var base_speed := 62.0
var speed_mul := 1.0
var slow_timer := 0.0
var finished := false
var intro_distance := 0.0
var damage_dealt := 0.0
var speed_pattern := "steady"
var skin: Dictionary = {}
var _clock := 0.0
var _track_points: PackedVector2Array


func setup(track: Curve2D, types: Array[String], base_hp: float, hp_growth: float) -> void:
	curve = track
	length = curve.get_baked_length()
	_track_points = curve.get_baked_points()
	intro_distance = TrackBuilder.ENTRY + 300.0
	segments.clear()
	var back := -HEAD_GAP
	var plate_count := 0
	for i in types.size():
		var s := Segment.new()
		s.id = i
		s.type = types[i]
		var def: Dictionary = Data.SEGMENTS[s.type]
		s.plates = ORB_PLATES if s.is_orb() else 5 + randi() % 3
		s.max_hp = round(base_hp * (1.0 + i * hp_growth) * def.hp_mul)
		s.hp = s.max_hp
		s.armor = def.armor
		s.offset = back
		s.first_plate = plate_count
		plate_count += s.plates
		back -= s.length()
		s.plate_pos.resize(s.plates)
		s.plate_angle.resize(s.plates)
		s.plate_visible.resize(s.plates)
		s.bound = s.plates * PLATE_SPACING / 2.0 + PLATE_RADIUS
		segments.append(s)
	head_offset = 0.0
	_update_positions()


## 0..1: how close the head is to the end of the track.
func danger() -> float:
	return clampf(head_offset / length, 0.0, 1.0)


## True while the head is pressed against the wall at the end of the track.
func at_wall() -> bool:
	return not segments.is_empty() and head_offset >= length - 1.0


func push_back(distance: float) -> void:
	head_offset -= distance
	for s in segments:
		s.offset -= distance


## Returns the damage actually applied after armor.
func damage(seg: Segment, amount: float) -> float:
	if not seg.alive:
		return 0.0
	var dealt := amount * (1.0 - seg.armor)
	seg.hp -= dealt
	damage_dealt += dealt
	seg.flash = 0.08
	if seg.hp <= 0.0:
		_kill(seg)
	return dealt


func apply_dot(seg: Segment, dps: float, spread: int) -> void:
	var idx := segments.find(seg)
	if idx == -1:
		return
	for i in range(idx - spread, idx + spread + 1):
		if i < 0 or i >= segments.size():
			continue
		var s := segments[i]
		s.dot = maxf(s.dot, dps)
		s.dot_time = DOT_DURATION


func _process(delta: float) -> void:
	_clock += delta
	if finished or segments.is_empty():
		queue_redraw()
		return
	var speed := base_speed * speed_mul
	if slow_timer > 0.0:
		slow_timer -= delta
		speed *= 0.5
	if head_offset < intro_distance:
		speed *= INTRO_SPEED_MUL
	else:
		match speed_pattern:
			"pulse":  # slithers: speeds up and slows down
				speed *= 1.0 + 0.6 * sin(_clock * 1.4)
			"surge":  # crawls slowly, then lunges for 1.2s every 6s
				speed *= 2.6 if fmod(_clock, 6.0) > 4.8 else 0.68

	# Tail drives. Each section stays butted against the one behind it:
	# pushed forward when touching, sliding back when a gap opened.
	segments[-1].offset += speed * delta
	var retract := RETRACT_SPEED * delta
	for i in range(segments.size() - 2, -1, -1):
		segments[i].offset = _follow(segments[i].offset, segments[i + 1].offset + segments[i].length(), retract)
	head_offset = _follow(head_offset, segments[0].offset + HEAD_GAP, retract)
	# The wall stops the head; the body piles up behind it.
	if head_offset > length:
		head_offset = length
		var limit := head_offset - HEAD_GAP
		for s in segments:
			s.offset = minf(s.offset, limit)
			limit = s.offset - s.length()
	_update_positions()

	# Damage over time, mending and hit flashes.
	for i in segments.size():
		var s := segments[i]
		s.flash = maxf(0.0, s.flash - delta)
		if s.type == "mending" and s.on_track():
			for j in [i - 1, i + 1]:
				if j >= 0 and j < segments.size():
					var n := segments[j]
					n.hp = minf(n.max_hp, n.hp + n.max_hp * MEND_RATE * delta)
	for s in segments.duplicate():
		if s.dot_time > 0.0:
			s.dot_time -= delta
			s.hp -= s.dot * delta
			damage_dealt += s.dot * delta
			if s.hp <= 0.0:
				_kill(s)
	queue_redraw()


func _follow(current: float, target: float, retract: float) -> float:
	if current <= target:
		return target
	return maxf(target, current - retract)


func _sample(o: float) -> Vector2:
	return curve.sample_baked(clampf(o, 0.0, length))


func _update_positions() -> void:
	head_pos = _sample(head_offset)
	var h_ahead := _sample(head_offset + 6.0)
	var h_behind := _sample(head_offset - 6.0)
	if h_ahead != h_behind:
		head_dir = (h_ahead - h_behind).normalized()
	for s in segments:
		for k in s.plates:
			var o := s.offset - k * PLATE_SPACING
			var p := _sample(o)
			s.plate_pos[k] = p
			s.plate_visible[k] = 1 if o >= 0.0 else 0
			var d := _sample(o + 6.0) - _sample(o - 6.0)
			s.plate_angle[k] = d.angle() if d != Vector2.ZERO else 0.0
		var mid := s.plates / 2
		s.pos = s.plate_pos[mid]
		s.dir = Vector2.from_angle(s.plate_angle[mid])


func _kill(seg: Segment) -> void:
	if not seg.alive:
		return
	seg.alive = false
	segments.erase(seg)
	segment_destroyed.emit(seg)
	if segments.is_empty() and not finished:
		finished = true
		cleared.emit()


# --- Drawing ---------------------------------------------------------------
# The body art is one painted "log" per theme. It is cut into vertical slices
# (one per plate) and consecutive plates draw consecutive slices, so the
# painted body bends smoothly along the path.

func _draw() -> void:
	var font := Art.FONT
	if not segments.is_empty():
		_draw_tail(segments[-1])
	# Tail first so plates nearer the head overlap the ones behind them.
	for i in range(segments.size() - 1, -1, -1):
		var s := segments[i]
		if s.plate_visible[0]:
			_draw_section(s)
	if head_offset >= -60.0 and not segments.is_empty():
		_draw_head()
	for s in segments:
		if s.on_track():
			_draw_label(s, font)


func _section_tint(s: Segment) -> Color:
	var col := Color.WHITE
	match s.type:
		"bone":
			col = Color(0.78, 0.82, 0.92)
		"mending":
			col = Color(0.75, 1.15, 0.75).lerp(Color.WHITE, 0.5 + 0.5 * sin(_clock * 5.0 + s.id))
		"gilded":
			col = Color(1.35, 1.1, 0.55)
	if skin.get("boss", false):
		col *= Color(1.0, 0.75, 0.75)
	if s.flash > 0.0:
		col = Color(1.9, 1.9, 1.9)
	return col


func _body_flip(angle: float) -> bool:
	return absf(wrapf(angle, -PI, PI)) > PI / 2.0


func _draw_section(s: Segment) -> void:
	var tex: Texture2D = skin.body
	var ts := tex.get_size()
	var sc := BODY_HEIGHT / ts.y
	var bw := PLATE_SPACING / sc           # source width of one slice
	var ov := bw * BAND_OVERLAP
	var usable := ts.x - 2.0 * ov
	var bands := maxi(1, int(usable / bw))
	var col := _section_tint(s)
	var flip := _body_flip(s.plate_angle[s.plates / 2])
	for k in range(s.plates - 1, -1, -1):
		if not s.plate_visible[k]:
			continue
		var band := (s.first_plate + k) % bands
		var x := ov + usable - (band + 1) * bw  # front of the body is the right of the art
		var src := Rect2(x - ov * 0.5, 0, bw + ov, ts.y)
		Art.draw_region(self, tex, src, s.plate_pos[k], Vector2(sc, -sc if flip else sc), s.plate_angle[k], col)
	if s.type == "gilded" or s.type == "mending":
		var glow := Color(1, 0.8, 0.3, 0.45) if s.type == "gilded" else Color(0.3, 1, 0.4, 0.4)
		Art.draw_sprite(self, Art.FX.glow, s.pos, 1.2, 0.0, glow)
	if s.dot_time > 0.0:
		Art.draw_sprite(self, Art.FX.twirl, s.pos, 0.9, _clock * 6.0, Color(0.7, 0.25, 1.0, 0.7))
	if s.is_orb() and s.plate_visible[1]:
		var orb: Texture2D = Art.ORB_HERO if s.type == "hero_chest" else Art.ORB_SKILL
		var pulse := 1.0 + 0.05 * sin(_clock * 6.0 + s.id)
		Art.draw_sprite(self, Art.FX.glow, s.plate_pos[1], 1.0 * pulse, 0.0,
			Color(1, 0.7, 0.2, 0.5) if s.type == "hero_chest" else Color(0.3, 0.6, 1, 0.5))
		Art.draw_sprite(self, orb, s.plate_pos[1], ORB_SCALE * pulse, 0.0, Color(1.6, 1.6, 1.6) if s.flash > 0.0 else Color.WHITE)


func _draw_tail(last: Segment) -> void:
	var tex: Texture2D = skin.tail
	var body: Texture2D = skin.body
	var sc := BODY_HEIGHT / body.get_height() * TAIL_SCALE_MUL
	var k := last.plates - 1
	var a := last.plate_angle[k]
	var dir := Vector2.from_angle(a)
	# The tail's thick right end tucks under the last plate.
	var pos := last.plate_pos[k] - dir * (tex.get_width() * sc * 0.5 - PLATE_SPACING)
	Art.draw_sprite(self, tex, pos, sc, a, _section_tint(last) if last.flash > 0.0 else Color.WHITE, _body_flip(a))


func _draw_head() -> void:
	var flip := head_dir.x < 0.0
	var bite := 0.0
	if at_wall():
		bite = absf(sin(_clock * 9.0)) * 0.15
	var tex: Texture2D = skin.head
	var sc := HEAD_SCALE * (1.2 if skin.get("boss", false) else 1.0) * (1.0 + bite * 0.4)
	var angle := head_dir.angle() + (bite if not flip else -bite)
	Art.draw_sprite(self, tex, head_pos + head_dir * 25.0, sc, angle, Color.WHITE, flip)


func _draw_label(s: Segment, font: Font) -> void:
	if s.is_orb():
		if s.hp < s.max_hp:
			var bar := Rect2(s.pos + Vector2(-46, PLATE_RADIUS + 10), Vector2(92, 10))
			draw_rect(bar.grow(2), Color(0.1, 0.05, 0.05, 0.9))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * s.hp / s.max_hp, 10)), Color(1.0, 0.3, 0.2))
		return
	var txt := Meta.fmt(ceilf(s.hp))
	var p := s.pos + Vector2(-90, 12)
	draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 180, 34, 10, Color(0.08, 0.06, 0.1))
	draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, 180, 34, Color.WHITE)
