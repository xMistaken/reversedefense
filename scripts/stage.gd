class_name Stage
extends Node2D
## One stage: track + wyrm + party + projectiles + chest picks + HUD.

signal exit_requested(action: String)  # "retry", "next" or "menu"

enum Mode { CIRCLE, WAGON }

const HERO_RADIUS := 34.0
const WAGON_SPEED := 2400.0
const BOUNCE_RANGE := 600.0
const MAX_NUMBERS := 70
const MAX_EFFECTS := 160

class Projectile:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var stats: Dictionary
	var color := Color.WHITE
	var pierce := 1
	var bounce := 0
	var hit_ids: Array[int] = []
	var dead := false
	var hero := ""
	var age := 0.0

var stage_number := 1
var starting_hero := "warrior"
var use_meta := true        # false = ignore permanent upgrades (tests)
var config: StageConfig
var mode := Mode.CIRCLE
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
var reward: Dictionary = {}
var biggest_hit := 0.0
var skills_learned := 0

var _stats: Dictionary = {}         # hero id -> computed stats
var _fire_timers: Dictionary = {}   # hero id -> seconds until next volley
var _push_timers: Dictionary = {}   # hero id -> seconds until next shove
var _projectiles: Array[Projectile] = []
var _effects: Array[Dictionary] = []
var _numbers: Array[Dictionary] = []
var _pending_picks: Array[String] = []
var _fx: DrawLayer          # normal layer: heroes, projectiles, numbers
var _glow: DrawLayer        # additive layer: magic, sparks, explosions
var _ground: ImageTexture
var _shake := 0.0
var _time := 0.0
var _recoil: Dictionary = {}  # hero id -> seconds of firing pose left
var _pick: PickPanel
var _hud_label: Label
var _party_label: Label
var _danger: ProgressBar
var _pause_panel: Control
var _end_panel: Control
var _end_label: Label
var _next_button: Button


func _ready() -> void:
	view = get_viewport_rect().size
	config = StageConfig.make(stage_number)
	mode = config.mode as Mode
	run = RunState.new(starting_hero, use_meta)

	wyrm = Wyrm.new()
	add_child(wyrm)
	var bonus_chests := Meta.bonus_skill_chests() if use_meta else 0
	wyrm.setup(_build_track(), config.segment_types(bonus_chests), config.base_hp, config.hp_growth)
	wyrm.base_speed = config.speed * clampf(wyrm.length / StageConfig.REFERENCE_LENGTH, 0.6, 1.4)
	wyrm.speed_pattern = config.speed_pattern
	wyrm.segment_destroyed.connect(_on_segment_destroyed)
	wyrm.reached_end.connect(_end.bind(false))
	wyrm.cleared.connect(_end.bind(true))

	_ground = Art.ground_texture(view, "dirt" if mode == Mode.CIRCLE else "sand", 5)

	_glow = DrawLayer.new()
	_glow.painter = _draw_glow
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	add_child(_glow)

	_fx = DrawLayer.new()
	_fx.painter = _draw_fx
	add_child(_fx)

	_build_ui()
	if use_meta:
		for i in Meta.head_start_skills():
			var offers := run.skill_offers()
			if not offers.is_empty():
				run.take_skill(offers[0].id, 1)
				skills_learned += 1
	_refresh_stats()


func _build_track() -> Curve2D:
	center = Vector2(view.x / 2.0, view.y * 0.52)
	wagon_y = view.y - 230.0
	wagon_x = view.x / 2.0
	wagon_target_x = wagon_x
	return config.build_track(view, center, wagon_y)


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
	_time += delta
	if mode == Mode.WAGON:
		wagon_x = move_toward(wagon_x, wagon_target_x, WAGON_SPEED * delta)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 4.0)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 14.0
	else:
		position = Vector2.ZERO
	for h in _recoil:
		_recoil[h] = maxf(0.0, _recoil[h] - delta)

	for h in run.party:
		var s: Dictionary = _stats[h]
		_fire_timers[h] -= delta
		if _fire_timers[h] <= 0.0:
			_fire_timers[h] = maxf(_fire_timers[h] + s.cooldown, 0.0)
			_fire(h)
		if s.push_interval > 0.0:
			_push_timers[h] -= delta
			if _push_timers[h] <= 0.0:
				_push_timers[h] = s.push_interval
				wyrm.push_back(s.push)
				_add_effect("light", hero_position(h), 0.4, 9.0, Color(1, 0.95, 0.6, 0.8), 0.6)
				Sfx.play("shove", -4.0)
				_shake = maxf(_shake, 0.5)

	_update_projectiles(delta)
	for e in _effects:
		e.t += delta
		e.rot += e.spin * delta
	_effects = _effects.filter(func(e: Dictionary) -> bool: return e.t < e.dur)
	for n in _numbers:
		n.t += delta
		n.pos.y -= 70.0 * delta
	_numbers = _numbers.filter(func(n: Dictionary) -> bool: return n.t < 0.7)
	_danger.value = wyrm.danger()
	_fx.queue_redraw()
	_glow.queue_redraw()


func hero_position(hero_id: String) -> Vector2:
	var n := run.party.size()
	var i := run.party.find(hero_id)
	if mode == Mode.CIRCLE:
		if n == 1:
			return center
		var a := -PI / 2 + TAU * i / n
		return center + Vector2(cos(a), sin(a)) * (70.0 if n <= 3 else 96.0)
	return Vector2(wagon_x + (i - (n - 1) / 2.0) * 90.0, wagon_y - 60.0)


func _fire(hero_id: String) -> void:
	var s: Dictionary = _stats[hero_id]
	var dir := aim_dir if mode == Mode.CIRCLE else Vector2.UP
	var origin := hero_position(hero_id)
	var count: int = s.count
	var spread: float = minf(s.spread, 1.6 / maxf(count - 1, 1))
	for k in count:
		var p := Projectile.new()
		var d := dir.rotated((k - (count - 1) / 2.0) * spread)
		p.pos = origin + d * HERO_RADIUS
		p.vel = d * s.speed
		p.stats = s
		p.color = Data.HEROES[hero_id].color
		p.hero = hero_id
		p.pierce = s.pierce
		p.bounce = s.bounce
		_projectiles.append(p)
	_recoil[hero_id] = 0.08


func _update_projectiles(delta: float) -> void:
	var bounds := Rect2(Vector2(-80, -80), view + Vector2(160, 160))
	for p in _projectiles:
		p.pos += p.vel * delta
		p.age += delta
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
	var dmg: float = s.damage * s.power
	var crit: bool = randf() < s.crit
	if crit:
		dmg *= s.crit_mult
	if s.execute > 0.0 and seg.hp < seg.max_hp * 0.3:
		dmg *= 1.0 + s.execute
	var hit_pos := seg.pos
	var neighbours := wyrm.segments.duplicate()
	if s.dot > 0.0:
		wyrm.apply_dot(seg, s.dot * s.power, s.dot_spread)
	if s.slow > 0.0:
		wyrm.slow_timer = maxf(wyrm.slow_timer, s.slow)
	var dealt := wyrm.damage(seg, dmg)
	biggest_hit = maxf(biggest_hit, dealt)
	_add_number(hit_pos, dealt, crit)
	_add_effect("spark", hit_pos, 0.2, 0.5, p.color, 0.14, randf() * TAU)
	Sfx.play("armor" if seg.armor > 0.0 else "hit", -12.0)
	if s.splash > 0.0:
		_add_effect("glow", hit_pos, 0.2, s.splash / 64.0, Color(1.0, 0.5, 0.15, 0.9), 0.28)
		_add_effect("flame", hit_pos, 0.2, s.splash / 80.0, Color(1.0, 0.7, 0.3, 0.9), 0.3, randf() * TAU, 3.0)
		for other in neighbours:
			if other != seg and other.alive and other.on_track() and other.pos.distance_to(hit_pos) <= s.splash:
				wyrm.damage(other, dmg * 0.5)
	if crit:
		_add_effect("burst", hit_pos, 0.3, 0.9, Color(1, 0.9, 0.3), 0.22, randf() * TAU, 5.0)
		Sfx.play("crit", -8.0)

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
	run.gold += Meta.gold_per_segment(stage_number)
	var col: Color = Data.SEGMENTS[seg.type].color
	_add_effect("burst", seg.pos, 0.3, 1.1, col.lightened(0.3), 0.3, randf() * TAU, 4.0)
	_add_effect("smoke", seg.pos, 0.3, 0.8, Color(0.6, 0.55, 0.55, 0.7), 0.5, randf() * TAU, 1.0, false)
	Sfx.play("kill", -6.0)
	match seg.type:
		"hero_chest":
			_pending_picks.append("hero")
			_chest_burst(seg.pos, Color(0.8, 0.5, 1.0))
		"skill_chest":
			_pending_picks.append("skill")
			_chest_burst(seg.pos, Color(0.4, 0.7, 1.0))
		"gilded":
			run.gold += Meta.gold_per_segment(stage_number) * 10.0
			run.refreshes += 1
			_add_effect("star", seg.pos, 0.3, 1.4, Color(1, 0.85, 0.3), 0.5, 0.0, 3.0)
			Sfx.play("coins")
	if not _pending_picks.is_empty():
		_open_next_pick.call_deferred()
	_update_hud()


func _chest_burst(pos: Vector2, col: Color) -> void:
	_add_effect("light", pos, 0.5, 3.5, col, 0.5)
	_add_effect("star", pos, 0.4, 1.6, Color(1, 0.9, 0.5), 0.45, 0.0, 4.0)
	Sfx.play("chest")
	_shake = maxf(_shake, 0.6)


## A particle texture that scales from s0 to s1 and fades out over `dur`.
func _add_effect(tex: String, pos: Vector2, s0: float, s1: float, col: Color, dur: float,
		rot := 0.0, spin := 0.0, additive := true) -> void:
	if _effects.size() >= MAX_EFFECTS:
		_effects.pop_front()
	_effects.append({"tex": tex, "pos": pos, "s0": s0, "s1": s1, "color": col, "t": 0.0,
		"dur": dur, "rot": rot, "spin": spin, "additive": additive})


func _add_number(pos: Vector2, amount: float, crit: bool) -> void:
	if _numbers.size() >= MAX_NUMBERS:
		_numbers.pop_front()
	var jitter := Vector2(randf_range(-22, 22), randf_range(-30, -10))
	_numbers.append({
		"pos": pos + jitter, "text": Meta.fmt(amount) + ("!" if crit else ""), "t": 0.0,
		"size": 40 if crit else 26, "color": Color(1, 0.85, 0.2) if crit else Color.WHITE,
	})


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
		run.gold += Meta.gold_per_segment(stage_number) * 10.0  # everything maxed out
		_open_next_pick()
		return
	get_tree().paused = true
	_pick.show_offers(kind, offers, run)
	Sfx.play("pick")


func _offers_for(kind: String) -> Array[Dictionary]:
	return run.hero_offers() if kind == "hero" else run.skill_offers()


func _on_pick_refresh(kind: String) -> void:
	if run.refreshes <= 0:
		return
	run.refreshes -= 1
	_pick.show_offers(kind, _offers_for(kind), run)
	_update_hud()


func choose(kind: String, offer: Dictionary) -> void:
	if kind == "hero":
		run.take_hero(offer.id)
	else:
		run.take_skill(offer.id, offer.ranks)
		skills_learned += 1
		if offer.rarity in ["Epic", "Legendary"]:
			Sfx.play("legendary", -4.0 if offer.rarity == "Legendary" else -10.0)
	_pick.visible = false
	get_tree().paused = false
	_refresh_stats()
	_open_next_pick()


func is_picking() -> bool:
	return _pick.visible


func pick_offers() -> Array[Dictionary]:
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
	_pause_panel.visible = false
	get_tree().paused = true
	reward = Meta.finish_run(stage_number, victory, run.gold)
	Sfx.play("legendary" if victory else "armor")
	Sfx.play("coins", -4.0)
	var lines: Array[String] = []
	lines.append("VICTORY!" if victory else "DEFEAT")
	lines.append(config.title)
	lines.append("")
	lines.append("Total damage: %s" % Meta.fmt(wyrm.damage_dealt))
	lines.append("Biggest hit: %s" % Meta.fmt(biggest_hit))
	lines.append("Skills learned: %d   Party: %d" % [skills_learned, run.party.size()])
	lines.append("")
	lines.append("Gold earned: %s" % Meta.fmt(reward.total))
	if reward.first_clear:
		lines.append("First clear bonus x3!")
	if not victory:
		lines.append("Spend gold on upgrades and try again!")
	_end_label.text = "\n".join(lines)
	_next_button.visible = victory and stage_number < Meta.STAGE_COUNT
	_end_panel.visible = true


func retreat() -> void:
	_end(false)


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UITheme.get_theme()
	layer.add_child(ui)

	var top := ColorRect.new()
	top.color = Color(0, 0, 0, 0.55)
	top.size = Vector2(view.x, 230)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)

	var title := Label.new()
	title.text = config.title
	title.position = Vector2(30, 14)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1, 0.4, 0.3) if config.boss else Color(0.95, 0.75, 0.25))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(title)

	_hud_label = Label.new()
	_hud_label.position = Vector2(30, 70)
	_hud_label.add_theme_font_size_override("font_size", 34)
	_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_hud_label)

	_party_label = Label.new()
	_party_label.position = Vector2(30, 118)
	_party_label.add_theme_font_size_override("font_size", 30)
	_party_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_party_label)

	_danger = ProgressBar.new()
	_danger.position = Vector2(30, 170)
	_danger.size = Vector2(view.x - 60, 34)
	_danger.max_value = 1.0
	_danger.show_percentage = false
	_danger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_danger)

	var pause := Button.new()
	pause.text = "II"
	pause.position = Vector2(view.x - 130, 20)
	pause.size = Vector2(100, 90)
	pause.add_theme_font_size_override("font_size", 44)
	pause.pressed.connect(func() -> void:
		if not over and not _pick.visible:
			get_tree().paused = true
			_pause_panel.visible = true)
	ui.add_child(pause)

	_pick = PickPanel.new()
	ui.add_child(_pick)
	_pick.chosen.connect(choose)
	_pick.refresh_requested.connect(_on_pick_refresh)

	var p := _overlay(ui)
	_pause_panel = p[0]
	var pbox: VBoxContainer = p[1]
	pbox.add_child(_big_label("Paused", 70))
	pbox.add_child(_button("Resume", func() -> void:
		_pause_panel.visible = false
		get_tree().paused = false))
	pbox.add_child(_button("Retreat (keep gold)", retreat))

	var e := _overlay(ui)
	_end_panel = e[0]
	var ebox: VBoxContainer = e[1]
	_end_label = _big_label("", 36)
	ebox.add_child(_end_label)
	_next_button = _button("Next stage", func() -> void: exit_requested.emit("next"))
	ebox.add_child(_next_button)
	ebox.add_child(_button("Play again", func() -> void: exit_requested.emit("retry")))
	ebox.add_child(_button("Upgrades & menu", func() -> void: exit_requested.emit("menu")))


func _overlay(parent: Control) -> Array:
	var panel := Control.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	parent.add_child(panel)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(c)
	var frame := PanelContainer.new()
	c.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	frame.add_child(box)
	return [panel, box]


func _big_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(820, 0)
	l.add_theme_font_size_override("font_size", size)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(820, 130)
	b.add_theme_font_size_override("font_size", 46)
	b.pressed.connect(cb)
	return b


func _update_hud() -> void:
	if not _hud_label:
		return
	_hud_label.text = "Left: %d    Refreshes: %d    Gold: %s" % [wyrm.segments.size(), run.refreshes, Meta.fmt(run.gold)]
	var names: Array[String] = []
	for h in run.party:
		names.append(Data.HEROES[h].name)
	_party_label.text = "Party: " + ", ".join(names)


# --- Drawing -----------------------------------------------------------------

func _draw() -> void:
	var tint := Color(0.62, 0.62, 0.66) if mode == Mode.CIRCLE else Color(0.6, 0.56, 0.52)
	if config.boss:
		tint *= Color(1.25, 0.7, 0.7)
	draw_texture_rect(_ground, Rect2(Vector2.ZERO, _ground.get_size() * 4.0), false, tint)
	if mode == Mode.CIRCLE:
		draw_circle(center, 150.0, Color(0.05, 0.12, 0.1, 0.55))
		draw_arc(center, 150.0, 0, TAU, 64, Color(0.4, 0.95, 0.75, 0.75), 5.0)
		draw_arc(center, 124.0, 0, TAU, 64, Color(0.4, 0.95, 0.75, 0.35), 3.0)
		for i in 8:
			var a := TAU * i / 8.0
			draw_circle(center + Vector2.from_angle(a) * 137.0, 6.0, Color(0.6, 1, 0.85, 0.8))
	else:
		draw_rect(Rect2(0, wagon_y + 34, view.x, 10), Color(0.35, 0.24, 0.14))
		draw_rect(Rect2(0, wagon_y + 54, view.x, 6), Color(0.35, 0.24, 0.14))


## Additive layer: glows behind magic projectiles and particle effects.
func _draw_glow(c: CanvasItem) -> void:
	if mode == Mode.CIRCLE:
		Art.draw_sprite(c, Art.FX.magic, center, 2.4, _time * 0.3, Color(0.2, 0.6, 0.45, 0.35))
	for p in _projectiles:
		var shot: Dictionary = Data.HEROES[p.hero].shot
		if shot.has("glow"):
			Art.draw_sprite(c, Art.FX.glow, p.pos, shot.scale * 0.9, 0.0, shot.color * Color(1, 1, 1, 0.6))
			Art.draw_sprite(c, Art.FX[shot.glow], p.pos, shot.scale, p.age * shot.spin, shot.color)
	for e in _effects:
		if e.additive:
			_draw_effect(c, e)


func _draw_effect(c: CanvasItem, e: Dictionary) -> void:
	var t: float = e.t / e.dur
	var col: Color = e.color
	col.a *= 1.0 - t * t
	Art.draw_sprite(c, Art.FX[e.tex], e.pos, lerpf(e.s0, e.s1, sqrt(t)), e.rot, col)


func _draw_fx(c: CanvasItem) -> void:
	var font := Art.FONT
	# Aim guide
	if mode == Mode.CIRCLE and not over:
		for i in range(1, 7):
			c.draw_circle(center + aim_dir * (95.0 + i * 36.0), 6.0 - i * 0.5, Color(1, 0.95, 0.7, 0.55 - i * 0.07))
	# Wagon
	if mode == Mode.WAGON:
		var w := 90.0 * run.party.size() + 70.0
		var body := Rect2(Vector2(wagon_x - w / 2.0, wagon_y - 18.0), Vector2(w, 56.0))
		c.draw_rect(body.grow(5.0), Color(0.25, 0.15, 0.19))
		c.draw_rect(body, Color(0.62, 0.4, 0.24))
		c.draw_rect(Rect2(body.position, Vector2(w, 12.0)), Color(0.78, 0.53, 0.32))
		for x in range(int(body.position.x) + 36, int(body.end.x) - 20, 60):
			c.draw_rect(Rect2(x, body.position.y, 6, body.size.y), Color(0.45, 0.28, 0.16))
		for x in [body.position.x + 34.0, body.end.x - 34.0]:
			var wheel := Vector2(x, body.end.y + 8.0)
			c.draw_circle(wheel, 28.0, Color(0.25, 0.15, 0.19))
			c.draw_circle(wheel, 22.0, Color(0.55, 0.36, 0.2))
			c.draw_circle(wheel, 8.0, Color(0.75, 0.75, 0.8))
	# Heroes
	for i in run.party.size():
		var h := run.party[i]
		var pos := hero_position(h) + Vector2(0, sin(_time * 5.0 + i * 1.3) * 3.0)
		var punch: float = 1.0 + _recoil.get(h, 0.0) * 1.5
		c.draw_set_transform(pos + Vector2(0, 30), 0.0, Vector2(1.0, 0.35))
		c.draw_circle(Vector2.ZERO, 28.0, Color(0, 0, 0, 0.35))
		c.draw_set_transform_matrix(Transform2D.IDENTITY)
		Art.draw_sprite(c, Art.HEROES[h], pos, Art.SPRITE_SCALE * punch)
	# Weapon projectiles (magic ones are drawn on the glow layer)
	for p in _projectiles:
		var shot: Dictionary = Data.HEROES[p.hero].shot
		if not shot.has("sprite"):
			continue
		var angle: float = p.age * shot.spin if shot.has("spin") else p.vel.angle() + shot.get("orient", 0.0)
		Art.draw_sprite(c, Art.ITEMS[shot.sprite], p.pos, shot.scale, angle)
	for e in _effects:
		if not e.additive:
			_draw_effect(c, e)
	# Damage numbers
	for n in _numbers:
		var col: Color = n.color
		var t: float = n.t / 0.7
		col.a = 1.0 - t * t
		var pop: float = 1.0 + maxf(0.0, 0.25 - n.t) * 2.0
		var size := int(n.size * pop)
		var pos: Vector2 = n.pos - Vector2(110, 0)
		c.draw_string_outline(font, pos, n.text, HORIZONTAL_ALIGNMENT_CENTER, 220, size, 8, Color(0.12, 0.05, 0.05, col.a))
		c.draw_string(font, pos, n.text, HORIZONTAL_ALIGNMENT_CENTER, 220, size, col)
