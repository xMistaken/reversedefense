class_name Wyrm
extends Node2D
## The segmented creature. An indestructible head leads a chain of body
## segments, each at a distance ("offset") along the track. The rearmost
## segment drives the chain forward. The chain always stays connected: when a
## segment is destroyed, everything ahead of it (including the head) slides
## back to close the gap. Destroy every body segment to win; if the head
## reaches the end of the track, you lose.

signal segment_destroyed(seg: Segment)
signal reached_end
signal cleared

const SPACING := 64.0
const RADIUS := 30.0
const DOT_DURATION := 3.0
const MEND_RATE := 0.05  # fraction of max HP per second healed into neighbours
const INTRO_SPEED_MUL := 5.0
const RETRACT_SPEED := 650.0  # how fast the front slides back to close a gap
const HEAD_RADIUS := 40.0

class Segment:
	var id := 0
	var type := "flesh"
	var hp := 1.0
	var max_hp := 1.0
	var armor := 0.0
	var offset := 0.0
	var pos := Vector2.ZERO
	var dir := Vector2.RIGHT
	var dot := 0.0
	var dot_time := 0.0
	var flash := 0.0
	var alive := true

	func on_track() -> bool:
		return offset >= 0.0

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
var _clock := 0.0
var _track_points: PackedVector2Array


func setup(track: Curve2D, types: Array[String], base_hp: float, hp_growth: float) -> void:
	curve = track
	length = curve.get_baked_length()
	_track_points = curve.get_baked_points()
	intro_distance = TrackBuilder.ENTRY + 260.0
	segments.clear()
	for i in types.size():
		var s := Segment.new()
		s.id = i
		s.type = types[i]
		var def: Dictionary = Data.SEGMENTS[s.type]
		s.max_hp = round(base_hp * (1.0 + i * hp_growth) * def.hp_mul)
		s.hp = s.max_hp
		s.armor = def.armor
		s.offset = -(i + 1) * SPACING
		segments.append(s)
	head_offset = 0.0
	_update_positions()


## 0..1: how close the head is to the end of the track.
func danger() -> float:
	return clampf(head_offset / length, 0.0, 1.0)


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
	if finished or segments.is_empty():
		return
	var speed := base_speed * speed_mul
	if slow_timer > 0.0:
		slow_timer -= delta
		speed *= 0.5
	_clock += delta
	if head_offset < intro_distance:
		speed *= INTRO_SPEED_MUL
	else:
		match speed_pattern:
			"pulse":  # slithers: speeds up and slows down
				speed *= 1.0 + 0.6 * sin(_clock * 1.4)
			"surge":  # crawls slowly, then lunges for 1.2s every 6s
				speed *= 2.6 if fmod(_clock, 6.0) > 4.8 else 0.68

	# Tail drives. Everything ahead stays one SPACING apart: pushed forward
	# when touching, sliding back when a gap opened in front of it.
	segments[-1].offset += speed * delta
	var retract := RETRACT_SPEED * delta
	for i in range(segments.size() - 2, -1, -1):
		segments[i].offset = _follow(segments[i].offset, segments[i + 1].offset + SPACING, retract)
	head_offset = _follow(head_offset, segments[0].offset + SPACING, retract)
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

	if head_offset >= length:
		finished = true
		reached_end.emit()
	queue_redraw()


func _follow(current: float, target: float, retract: float) -> float:
	if current <= target:
		return target
	return maxf(target, current - retract)


func _update_positions() -> void:
	var ho := clampf(head_offset, 0.0, length)
	head_pos = curve.sample_baked(ho)
	var h_ahead := curve.sample_baked(minf(ho + 4.0, length))
	if h_ahead != head_pos:
		head_dir = (h_ahead - head_pos).normalized()
	for s in segments:
		var o := clampf(s.offset, 0.0, length)
		s.pos = curve.sample_baked(o)
		var ahead := curve.sample_baked(minf(o + 4.0, length))
		if ahead != s.pos:
			s.dir = (ahead - s.pos).normalized()


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

func _draw() -> void:
	# The path itself is hidden; only the exit portal the head is heading for shows.
	var end := _track_points[-1]
	Art.draw_sprite(self, Art.FX.glow, end, 1.1, 0.0, Color(0.6, 0.05, 0.15, 0.9))
	Art.draw_sprite(self, Art.FX.twirl, end, 0.85, -_clock * 2.0, Color(0.9, 0.2, 0.35))
	Art.draw_sprite(self, Art.FX.twirl, end, 0.55, _clock * 3.0, Color(0.15, 0.0, 0.1))

	var font := Art.FONT
	for i in range(segments.size() - 1, -1, -1):
		var s := segments[i]
		if s.on_track():
			_draw_segment(s, font)
	if head_offset >= 0.0 and not segments.is_empty():
		var flip := head_dir.x < 0.0
		Art.draw_sprite(self, Art.WYRM_HEAD, head_pos, Art.SPRITE_SCALE, head_dir.angle(), Color.WHITE, flip)


func _draw_segment(s: Segment, font: Font) -> void:
	var col: Color = Data.SEGMENTS[s.type].color
	if s.flash > 0.0:
		col = col.lerp(Color.WHITE, 0.7)
	var angle := s.dir.angle()
	var flip := s.dir.x < 0.0
	if s.type == "gilded" or s.type == "mending":
		var pulse := 0.85 + 0.15 * sin(_clock * 5.0 + s.id)
		var glow := Color(1, 0.85, 0.3, 0.55) if s.type == "gilded" else Color(0.3, 1, 0.4, 0.45)
		Art.draw_sprite(self, Art.FX.glow, s.pos, 0.75 * pulse, 0.0, glow)
	Art.draw_sprite(self, Art.WYRM_SEGMENT, s.pos, 4.0, angle, col, flip)
	if s.dot_time > 0.0:
		Art.draw_sprite(self, Art.FX.twirl, s.pos, 0.5, _clock * 6.0, Color(0.7, 0.25, 1.0, 0.8))

	match s.type:
		"bone":
			Art.draw_sprite(self, Art.WYRM_PLATE, s.pos, 4.0, angle, Color.WHITE, flip)
		"hero_chest":
			Art.draw_sprite(self, Art.ITEMS.chest_hero, s.pos + Vector2(0, -4), 3.0)
		"skill_chest":
			Art.draw_sprite(self, Art.ITEMS.chest_skill, s.pos + Vector2(0, -4), 3.0)

	var txt := Meta.fmt(ceilf(s.hp))
	if s.type == "hero_chest" or s.type == "skill_chest":
		if s.hp < s.max_hp:
			var bar := Rect2(s.pos + Vector2(-RADIUS, RADIUS + 4), Vector2(RADIUS * 2.0, 7))
			draw_rect(bar, Color(0.1, 0.05, 0.05, 0.85))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * s.hp / s.max_hp, 7)), Color(0.95, 0.25, 0.2))
		return
	var p := s.pos + Vector2(-RADIUS, 9)
	draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 20, 6, Color(0.1, 0.05, 0.08))
	draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 20, Color.WHITE)
