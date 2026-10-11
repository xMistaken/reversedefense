class_name Stage
extends Node2D
## One stage: track + wyrm + party + projectiles + chest picks + HUD.

signal exit_requested(action: String)  # "retry" or "menu"

enum Mode { CIRCLE, WAGON }

const HERO_RADIUS := 34.0
const WAGON_SPEED := 2400.0
const SEGMENT_COUNT := 60
const BASE_HP := 60.0
const HP_GROWTH := 0.12
const BOUNCE_RANGE := 600.0
const GOLD_PER_SEGMENT := 1

class Projectile:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var stats: Dictionary
	var color := Color.WHITE
	var pierce := 1
	var bounce := 0
	var hit_ids: Array[int] = []
	var dead := false

var mode := Mode.CIRCLE
var starting_hero := "warrior"
var run: RunState
var wyrm: Wyrm
var view: Vector2
var center: Vector2
var aim_dir := Vector2.UP
var wagon_x := 0.0
var wagon_target_x := 0.0
var wagon_y := 0.0
var over := false
var won := false

var _stats: Dictionary = {}         # hero id -> computed stats
var _fire_timers: Dictionary = {}   # hero id -> seconds until next volley
var _push_timers: Dictionary = {}   # hero id -> seconds until next shove
var _projectiles: Array[Projectile] = []
var _effects: Array[Dictionary] = []
var _pending_picks: Array[String] = []
var _fx: DrawLayer
var _pick: PickPanel
var _hud_label: Label
var _party_label: Label
var _danger: ProgressBar
var _end_panel: Control
var _end_label: Label


func _ready() -> void:
	view = get_viewport_rect().size
	run = RunState.new(starting_hero)

	wyrm = Wyrm.new()
	add_child(wyrm)
	wyrm.setup(_build_track(), _build_segment_types(), BASE_HP, HP_GROWTH)
	wyrm.segment_destroyed.connect(_on_segment_destroyed)
	wyrm.reached_end.connect(_end.bind(false))
	wyrm.cleared.connect(_end.bind(true))

	_fx = DrawLayer.new()
	_fx.painter = _draw_fx
	add_child(_fx)

	_build_ui()
	_refresh_stats()


func _build_track() -> Curve2D:
	if mode == Mode.CIRCLE:
		center = Vector2(view.x / 2.0, view.y * 0.52)
		return TrackBuilder.spiral(center, view.x * 0.46, 190.0, 2.3)
	wagon_y = view.y - 230.0
	wagon_x = view.x / 2.0
	wagon_target_x = wagon_x
	var rows := 5
	var top := 330.0
	var gap := (wagon_y - 380.0 - top) / (rows - 1)
	return TrackBuilder.serpentine(130.0, view.x - 130.0, top, gap, rows)


## Head first. Hero chests early so the party grows; skill chests regularly.
func _build_segment_types() -> Array[String]:
	var types: Array[String] = []
	var hero_slots := [4, 16, 30, 45]
	for i in SEGMENT_COUNT:
		if i in hero_slots:
			types.append("hero_chest")
		elif i % 4 == 1:
			types.append("skill_chest")
		else:
			var r := randf()
			if r < 0.62:
				types.append("flesh")
			elif r < 0.82:
				types.append("bone")
			elif r < 0.94:
				types.append("mending")
			else:
				types.append("gilded")
	return types


func _refresh_stats() -> void:
	for h in run.party:
		_stats[h] = run.hero_stats(h)
		if not _fire_timers.has(h):
			_fire_timers[h] = 0.2
			_push_timers[h] = _stats[h].push_interval
	wyrm.speed_mul = run.global_stat("wyrm_speed")
	_update_hud()


# --- Input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventScreenTouch and event.pressed:
		_point(event.position)
	elif event is InputEventScreenDrag:
		_point(event.position)


func _point(p: Vector2) -> void:
	if mode == Mode.CIRCLE:
		aim_at(p)
	else:
		wagon_target_x = clampf(p.x, 90.0, view.x - 90.0)


func aim_at(p: Vector2) -> void:
	if p.distance_to(center) > 10.0:
		aim_dir = (p - center).normalized()


# --- Simulation --------------------------------------------------------------

func _process(delta: float) -> void:
	if over:
		return
	if mode == Mode.WAGON:
		wagon_x = move_toward(wagon_x, wagon_target_x, WAGON_SPEED * delta)

	for h in run.party:
		var s: Dictionary = _stats[h]
		_fire_timers[h] -= delta
		if _fire_timers[h] <= 0.0:
			_fire_timers[h] += s.cooldown
			_fire(h)
		if s.push_interval > 0.0:
			_push_timers[h] -= delta
			if _push_timers[h] <= 0.0:
				_push_timers[h] = s.push_interval
				wyrm.push_back(s.push)
				_add_effect(hero_position(h), 20.0, view.x * 0.6, Data.HEROES[h].color, 0.5)

	_update_projectiles(delta)
	for e in _effects:
		e.t += delta
	_effects = _effects.filter(func(e: Dictionary) -> bool: return e.t < e.dur)
	_danger.value = wyrm.danger()
	_fx.queue_redraw()


func hero_position(hero_id: String) -> Vector2:
	var n := run.party.size()
	var i := run.party.find(hero_id)
	if mode == Mode.CIRCLE:
		if n == 1:
			return center
		var a := -PI / 2 + TAU * i / n
		return center + Vector2(cos(a), sin(a)) * 62.0
	return Vector2(wagon_x + (i - (n - 1) / 2.0) * 72.0, wagon_y - 40.0)


func _fire(hero_id: String) -> void:
	var s: Dictionary = _stats[hero_id]
	var dir := aim_dir if mode == Mode.CIRCLE else Vector2.UP
	var origin := hero_position(hero_id)
	var count: int = s.count
	for k in count:
		var p := Projectile.new()
		var angle: float = (k - (count - 1) / 2.0) * s.spread
		var d := dir.rotated(angle)
		p.pos = origin + d * HERO_RADIUS
		p.vel = d * s.speed
		p.stats = s
		p.color = Data.HEROES[hero_id].color
		p.pierce = s.pierce
		p.bounce = s.bounce
		_projectiles.append(p)


func _update_projectiles(delta: float) -> void:
	var bounds := Rect2(Vector2(-80, -80), view + Vector2(160, 160))
	for p in _projectiles:
		p.pos += p.vel * delta
		if not bounds.has_point(p.pos):
			p.dead = true
			continue
		var hit_r: float = Wyrm.RADIUS + p.stats.size
		for seg in wyrm.segments.duplicate():
			if not seg.alive or not seg.on_track() or p.hit_ids.has(seg.id):
				continue
			if p.pos.distance_squared_to(seg.pos) <= hit_r * hit_r:
				_hit(p, seg)
				if p.dead:
					break
	_projectiles = _projectiles.filter(func(p: Projectile) -> bool: return not p.dead)


func _hit(p: Projectile, seg: Wyrm.Segment) -> void:
	var s := p.stats
	var dmg: float = s.damage
	var crit: bool = randf() < s.crit
	if crit:
		dmg *= 2.0
	if s.execute > 0.0 and seg.hp < seg.max_hp * 0.3:
		dmg *= 1.0 + s.execute
	var hit_pos := seg.pos
	var neighbours := wyrm.segments.duplicate()
	if s.dot > 0.0:
		wyrm.apply_dot(seg, s.dot, s.dot_spread)
	if s.slow > 0.0:
		wyrm.slow_timer = maxf(wyrm.slow_timer, s.slow)
	wyrm.damage(seg, dmg)
	if s.splash > 0.0:
		_add_effect(hit_pos, 10.0, s.splash, Color(1.0, 0.55, 0.2, 0.8), 0.25)
		for other in neighbours:
			if other != seg and other.alive and other.on_track() and other.pos.distance_to(hit_pos) <= s.splash:
				wyrm.damage(other, dmg * 0.5)
	if crit:
		_add_effect(hit_pos, 10.0, 46.0, Color(1, 1, 0.4), 0.15)

	p.hit_ids.append(seg.id)
	p.pierce -= 1
	if p.pierce > 0:
		return
	if p.bounce > 0:
		var target := _nearest_unhit(p)
		if target:
			p.bounce -= 1
			p.pierce = 1
			p.vel = (target.pos - p.pos).normalized() * p.vel.length()
			return
	p.dead = true


func _nearest_unhit(p: Projectile) -> Wyrm.Segment:
	var best: Wyrm.Segment = null
	var best_d := BOUNCE_RANGE
	for seg in wyrm.segments:
		if not seg.on_track() or p.hit_ids.has(seg.id):
			continue
		var d := seg.pos.distance_to(p.pos)
		if d < best_d:
			best_d = d
			best = seg
	return best


func _on_segment_destroyed(seg: Wyrm.Segment) -> void:
	run.gold += GOLD_PER_SEGMENT
	var col: Color = Data.SEGMENTS[seg.type].color
	_add_effect(seg.pos, Wyrm.RADIUS, Wyrm.RADIUS * 2.2, col, 0.3)
	match seg.type:
		"hero_chest":
			_pending_picks.append("hero")
		"skill_chest":
			_pending_picks.append("skill")
		"gilded":
			run.gold += 10
			run.refreshes += 1
	if not _pending_picks.is_empty():
		_open_next_pick.call_deferred()
	_update_hud()


func _add_effect(pos: Vector2, r0: float, r1: float, col: Color, dur: float) -> void:
	_effects.append({"pos": pos, "r0": r0, "r1": r1, "color": col, "t": 0.0, "dur": dur})


# --- Chest picks -------------------------------------------------------------

func _open_next_pick() -> void:
	if over or _pick.visible or _pending_picks.is_empty():
		return
	var kind: String = _pending_picks.pop_front()
	var offers := _offers_for(kind)
	if kind == "hero" and offers.is_empty():
		kind = "skill"  # whole roster recruited
		offers = _offers_for(kind)
	if offers.is_empty():
		run.gold += 25  # everything maxed out
		_open_next_pick()
		return
	get_tree().paused = true
	_pick.show_offers(kind, offers, run)


func _offers_for(kind: String) -> Array[String]:
	return run.hero_offers() if kind == "hero" else run.skill_offers()


func _on_pick_refresh(kind: String) -> void:
	if run.refreshes <= 0:
		return
	run.refreshes -= 1
	_pick.show_offers(kind, _offers_for(kind), run)
	_update_hud()


func choose(kind: String, id: String) -> void:
	if kind == "hero":
		run.take_hero(id)
	else:
		run.take_skill(id)
	_pick.visible = false
	get_tree().paused = false
	_refresh_stats()
	_open_next_pick()


func is_picking() -> bool:
	return _pick.visible


func pick_offers() -> Array[String]:
	return _pick.offers


func pick_kind() -> String:
	return _pick.kind


# --- End of stage ------------------------------------------------------------

func _end(victory: bool) -> void:
	if over:
		return
	over = true
	won = victory
	_pick.visible = false
	get_tree().paused = true
	_end_label.text = ("VICTORY\nThe wyrm is slain!" if victory else "DEFEAT\nThe wyrm broke through.") \
		+ "\n\nGold earned: %d" % run.gold
	_end_panel.visible = true


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var top := ColorRect.new()
	top.color = Color(0, 0, 0, 0.55)
	top.position = Vector2.ZERO
	top.size = Vector2(view.x, 190)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)

	_hud_label = Label.new()
	_hud_label.position = Vector2(30, 20)
	_hud_label.add_theme_font_size_override("font_size", 40)
	_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hud_label)

	_party_label = Label.new()
	_party_label.position = Vector2(30, 75)
	_party_label.add_theme_font_size_override("font_size", 32)
	_party_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_party_label)

	_danger = ProgressBar.new()
	_danger.position = Vector2(30, 130)
	_danger.size = Vector2(view.x - 60, 36)
	_danger.max_value = 1.0
	_danger.show_percentage = false
	_danger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.2)
	_danger.add_theme_stylebox_override("fill", fill)
	layer.add_child(_danger)

	_pick = PickPanel.new()
	layer.add_child(_pick)
	_pick.chosen.connect(choose)
	_pick.refresh_requested.connect(_on_pick_refresh)

	_end_panel = Control.new()
	_end_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_end_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_panel.visible = false
	layer.add_child(_end_panel)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_panel.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_panel.add_child(c)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	c.add_child(box)
	_end_label = Label.new()
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.add_theme_font_size_override("font_size", 60)
	box.add_child(_end_label)
	for pair in [["Play again", "retry"], ["Main menu", "menu"]]:
		var b := Button.new()
		b.text = pair[0]
		b.custom_minimum_size = Vector2(700, 150)
		b.add_theme_font_size_override("font_size", 48)
		b.pressed.connect(func() -> void: exit_requested.emit(pair[1]))
		box.add_child(b)


func _update_hud() -> void:
	if not _hud_label:
		return
	_hud_label.text = "Segments left: %d    Refreshes: %d    Gold: %d" % [wyrm.segments.size(), run.refreshes, run.gold]
	var names: Array[String] = []
	for h in run.party:
		names.append(Data.HEROES[h].name)
	_party_label.text = "Party: " + ", ".join(names)


# --- Drawing -----------------------------------------------------------------

func _draw() -> void:
	var bg := Color(0.09, 0.14, 0.1) if mode == Mode.CIRCLE else Color(0.17, 0.13, 0.09)
	draw_rect(Rect2(Vector2.ZERO, view), bg)
	if mode == Mode.CIRCLE:
		draw_circle(center, 150.0, Color(0.12, 0.2, 0.16))
		draw_arc(center, 150.0, 0, TAU, 64, Color(0.4, 0.9, 0.7, 0.6), 5.0)
		draw_arc(center, 125.0, 0, TAU, 64, Color(0.4, 0.9, 0.7, 0.3), 3.0)
		for i in 8:
			var a := TAU * i / 8.0
			draw_circle(center + Vector2(cos(a), sin(a)) * 137.0, 6.0, Color(0.5, 1, 0.8, 0.7))
	else:
		draw_rect(Rect2(0, wagon_y - 10, view.x, 12), Color(0.3, 0.23, 0.15))


func _draw_fx(c: CanvasItem) -> void:
	var font := ThemeDB.fallback_font
	# Aim guide
	if mode == Mode.CIRCLE and not over:
		for i in range(1, 7):
			c.draw_circle(center + aim_dir * (80.0 + i * 38.0), 5.0, Color(1, 1, 1, 0.45 - i * 0.05))
	# Wagon
	if mode == Mode.WAGON:
		var w := 72.0 * run.party.size() + 70.0
		var body := Rect2(Vector2(wagon_x - w / 2.0, wagon_y - 20.0), Vector2(w, 70.0))
		c.draw_rect(body, Color(0.45, 0.3, 0.16))
		c.draw_rect(body, Color(0.25, 0.15, 0.08), false, 6.0)
		for x in [body.position.x + 30.0, body.end.x - 30.0]:
			c.draw_circle(Vector2(x, body.end.y + 5.0), 26.0, Color(0.15, 0.1, 0.06))
			c.draw_circle(Vector2(x, body.end.y + 5.0), 10.0, Color(0.6, 0.5, 0.3))
	# Heroes
	for h in run.party:
		var pos := hero_position(h)
		var hd: Dictionary = Data.HEROES[h]
		c.draw_circle(pos, HERO_RADIUS + 4.0, Color(0, 0, 0, 0.7))
		c.draw_circle(pos, HERO_RADIUS, hd.color)
		c.draw_string(font, pos + Vector2(-HERO_RADIUS, 13), hd.name.left(1), HORIZONTAL_ALIGNMENT_CENTER, HERO_RADIUS * 2.0, 38, Color(0.1, 0.1, 0.1))
	# Projectiles
	for p in _projectiles:
		c.draw_circle(p.pos, p.stats.size + 3.0, Color(0, 0, 0, 0.5))
		c.draw_circle(p.pos, p.stats.size, p.color)
	# Effects
	for e in _effects:
		var t: float = e.t / e.dur
		var col: Color = e.color
		col.a *= 1.0 - t
		c.draw_arc(e.pos, lerpf(e.r0, e.r1, t), 0, TAU, 32, col, 6.0)
