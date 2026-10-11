class_name Wyrm
extends Node2D
## The segmented creature. Segments sit at distances ("offsets") along the
## track. The rearmost segment drives the chain forward and pushes everything
## ahead of it, Zuma-style: breaking a middle segment stalls the front part of
## the chain until the back catches up.

signal segment_destroyed(seg: Segment)
signal reached_end
signal cleared

const SPACING := 64.0
const RADIUS := 30.0
const DOT_DURATION := 3.0
const MEND_RATE := 0.05  # fraction of max HP per second healed into neighbours
const INTRO_SPEED_MUL := 5.0

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
var segments: Array[Segment] = []  # index 0 = head (front), last = tail
var base_speed := 62.0
var speed_mul := 1.0
var slow_timer := 0.0
var finished := false
var intro_distance := 0.0
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
		s.offset = -i * SPACING
		segments.append(s)
	_update_positions()


func head() -> Segment:
	return segments[0] if not segments.is_empty() else null


## 0..1: how close the front of the chain is to the end of the track.
func danger() -> float:
	if segments.is_empty():
		return 0.0
	return clampf(segments[0].offset / length, 0.0, 1.0)


func push_back(distance: float) -> void:
	for s in segments:
		s.offset -= distance


func damage(seg: Segment, amount: float) -> void:
	if not seg.alive:
		return
	seg.hp -= amount * (1.0 - seg.armor)
	seg.flash = 0.08
	if seg.hp <= 0.0:
		_kill(seg)


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
	if segments[0].offset < intro_distance:
		speed *= INTRO_SPEED_MUL

	# Tail drives; every segment ahead is pushed if it is touching.
	segments[-1].offset += speed * delta
	for i in range(segments.size() - 2, -1, -1):
		segments[i].offset = maxf(segments[i].offset, segments[i + 1].offset + SPACING)
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
			if s.hp <= 0.0:
				_kill(s)

	if not segments.is_empty() and segments[0].offset >= length:
		finished = true
		reached_end.emit()
	queue_redraw()


func _update_positions() -> void:
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
	# Track
	draw_polyline(_track_points, Color(0.1, 0.08, 0.07, 0.85), RADIUS * 2.0 + 16.0, true)
	draw_polyline(_track_points, Color(0.22, 0.18, 0.15), RADIUS * 2.0, true)
	var end := _track_points[-1]
	draw_circle(end, RADIUS + 22.0, Color(0.05, 0.02, 0.08))
	draw_arc(end, RADIUS + 22.0, 0, TAU, 32, Color(0.85, 0.2, 0.25), 6.0)

	var font := ThemeDB.fallback_font
	for i in range(segments.size() - 1, -1, -1):
		var s := segments[i]
		if not s.on_track():
			continue
		_draw_segment(s, i == 0, font)


func _draw_segment(s: Segment, is_head: bool, font: Font) -> void:
	var col: Color = Data.SEGMENTS[s.type].color
	if s.flash > 0.0:
		col = col.lerp(Color.WHITE, 0.6)
	var r := RADIUS * (1.15 if is_head else 1.0)
	draw_circle(s.pos, r + 4.0, Color(0, 0, 0, 0.6))
	draw_circle(s.pos, r, col)
	if s.dot_time > 0.0:
		draw_arc(s.pos, r - 3.0, 0, TAU, 20, Color(0.6, 0.2, 0.9), 4.0)

	match s.type:
		"bone":
			draw_arc(s.pos, r - 6.0, 0, TAU, 20, Color(0.55, 0.5, 0.42), 4.0)
		"mending":
			draw_rect(Rect2(s.pos - Vector2(4, 12), Vector2(8, 24)), Color(0.85, 1, 0.85))
			draw_rect(Rect2(s.pos - Vector2(12, 4), Vector2(24, 8)), Color(0.85, 1, 0.85))
		"hero_chest", "skill_chest":
			var lid := Color(0.95, 0.75, 0.2)
			draw_rect(Rect2(s.pos - Vector2(16, 8), Vector2(32, 20)), Color(0.45, 0.28, 0.12))
			draw_rect(Rect2(s.pos - Vector2(17, 14), Vector2(34, 8)), lid)
			draw_rect(Rect2(s.pos - Vector2(3, 6), Vector2(6, 8)), lid)
			var tag := "H" if s.type == "hero_chest" else "S"
			draw_string(font, s.pos + Vector2(-r, -r - 6), tag, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 26, lid)
		"gilded":
			draw_arc(s.pos, r - 6.0, 0, TAU, 20, Color(1, 0.95, 0.6), 3.0)

	if is_head:
		var side := s.dir.orthogonal() * 12.0
		var fwd := s.dir * 14.0
		for e in [side, -side]:
			draw_circle(s.pos + fwd + e, 7.0, Color(1, 0.85, 0.2))
			draw_circle(s.pos + fwd + e + s.dir * 2.0, 3.0, Color.BLACK)

	if s.type != "hero_chest" and s.type != "skill_chest":
		var txt := str(ceili(s.hp))
		draw_string_outline(font, s.pos + Vector2(-r, 8), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 22, 4, Color.BLACK)
		draw_string(font, s.pos + Vector2(-r, 8), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 22, Color.WHITE)
	elif s.hp < s.max_hp:
		var w := r * 2.0
		var bar := Rect2(s.pos + Vector2(-r, r + 6), Vector2(w, 6))
		draw_rect(bar, Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bar.position, Vector2(w * s.hp / s.max_hp, 6)), Color(0.9, 0.2, 0.2))
