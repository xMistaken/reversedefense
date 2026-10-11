class_name Stage
extends Node2D
## One stage: hidden track + wyrm + wall + party + projectiles + chest picks + HUD.

signal exit_requested(action: String)  # "retry", "next" or "menu"

enum Mode { CIRCLE, WAGON }

const HERO_RADIUS := 50.0
const WAGON_SPEED := 2400.0
const BOUNCE_RANGE := 600.0
const MAX_NUMBERS := 70
const MAX_EFFECTS := 160
const WALL_RADIUS := 205.0      # ritual ring wall (circle stages)
const WALL_HP := 100.0          # before the Fortify upgrade
const BITE_DPS := 4.0           # wall damage per second while the head chews...
const BITE_DPS_PER_SECTION := 0.15  # ...plus this per remaining section

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
var wall_y := 0.0
var wall_hp := WALL_HP
var wall_max := WALL_HP
var over := false
var won := false
var reward: Dictionary = {}
var biggest_hit := 0.0
var skills_learned := 0
var elapsed := 0.0
var total_sections := 0

var _theme: Dictionary
var _stats: Dictionary = {}         # hero id -> computed stats
var _fire_timers: Dictionary = {}   # hero id -> seconds until next volley
var _push_timers: Dictionary = {}   # hero id -> seconds until next shove
var _projectiles: Array[Projectile] = []
var _effects: Array[Dictionary] = []
var _numbers: Array[Dictionary] = []
var _pending_picks: Array[String] = []
var _fx: DrawLayer          # normal layer: wall, heroes, projectiles, numbers
var _glow: DrawLayer        # additive layer: magic, sparks, explosions
var _shake := 0.0
var _time := 0.0
var _wall_flash := 0.0
var _recoil: Dictionary = {}  # hero id -> seconds of firing pose left
var _pick: PickPanel
var _title_label: Label
var _progress_label: Label
var _info_label: Label
var _timer_label: Label
var _speed_button: Button
var _pause_panel: Control
var _end_panel: Control
var _end_label: Label
var _next_button: Button


func _ready() -> void:
	view = get_viewport_rect().size
	config = StageConfig.make(stage_number)
	mode = config.mode as Mode
	_theme = Data.THEMES[config.theme]
	run = RunState.new(starting_hero, use_meta)
	if use_meta:
		wall_max = WALL_HP * Meta.wall_mult()
	wall_hp = wall_max

	wyrm = Wyrm.new()
	add_child(wyrm)
	wyrm.skin = {"head": Art.WYRM_HEADS[_theme.head], "body": _theme.body, "accent": _theme.accent}
	if config.boss:
		wyrm.skin.body = (_theme.body as Color).darkened(0.25)
	var bonus_chests := Meta.bonus_skill_chests() if use_meta else 0
	wyrm.setup(_build_track(), config.segment_types(bonus_chests), config.base_hp, config.hp_growth)
	wyrm.base_speed = config.speed * clampf(wyrm.length / StageConfig.REFERENCE_LENGTH, 0.6, 1.4)
	wyrm.speed_pattern = config.speed_pattern
	wyrm.segment_destroyed.connect(_on_segment_destroyed)
	wyrm.cleared.connect(_end.bind(true))
	total_sections = wyrm.segments.size()

	_glow = DrawLayer.new()
	_glow.painter = _draw_glow
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


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _build_track() -> Curve2D:
	center = Vector2(view.x / 2.0, view.y * 0.55)
	wagon_y = view.y - 200.0
	wall_y = view.y - 430.0
	wagon_x = view.x / 2.0
	wagon_target_x = wagon_x
	return config.build_track(view, center, wall_y, WALL_RADIUS)


func _refresh_stats() -> void:
	for h in run.party:
		_stats[h] = run.hero_stats(h)
		if not _fire_timers.has(h):
			_fire_timers[h] = 0.2
			_push_timers[h] = _stats[h].push_interval
	wyrm.speed_mul = run.global_stat("wyrm_speed")
	_update_hud()


## 0..1 share of the wyrm destroyed.
func progress() -> float:
	return 1.0 - float(wyrm.segments.size()) / maxf(total_sections, 1)


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
		wagon_target_x = clampf(p.x, 110.0, view.x - 110.0)


func aim_at(p: Vector2) -> void:
	if p.distance_to(center) > 10.0:
		aim_dir = (p - center).normalized()


# --- Simulation --------------------------------------------------------------

func _process(delta: float) -> void:
	if over:
		return
	_time += delta
	elapsed += delta
	if mode == Mode.WAGON:
		wagon_x = move_toward(wagon_x, wagon_target_x, WAGON_SPEED * delta)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 4.0)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 14.0
	else:
		position = Vector2.ZERO
	for h in _recoil:
		_recoil[h] = maxf(0.0, _recoil[h] - delta)
	_wall_flash = maxf(0.0, _wall_flash - delta)

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

	# The head chews on the wall while it's pressed against it.
	if wyrm.at_wall():
		wall_hp -= (BITE_DPS + BITE_DPS_PER_SECTION * wyrm.segments.size()) * delta
		if _wall_flash <= 0.0:
			_wall_flash = 0.35
			_shake = maxf(_shake, 0.35)
			Sfx.play("armor", -6.0)
			_add_effect("burst", wyrm.head_pos, 0.4, 1.2, Color(1, 0.5, 0.3), 0.3, randf() * TAU, 3.0)
		if wall_hp <= 0.0:
			wall_hp = 0.0
			_end(false)
			return

	_update_projectiles(delta)
	for e in _effects:
		e.t += delta
		e.rot += e.spin * delta
	_effects = _effects.filter(func(e: Dictionary) -> bool: return e.t < e.dur)
	for n in _numbers:
		n.t += delta
		n.pos.y -= 70.0 * delta
	_numbers = _numbers.filter(func(n: Dictionary) -> bool: return n.t < 0.7)
	_timer_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	_fx.queue_redraw()
	_glow.queue_redraw()


func hero_position(hero_id: String) -> Vector2:
	var n := run.party.size()
	var i := run.party.find(hero_id)
	if mode == Mode.CIRCLE:
		if n == 1:
			return center
		var a := -PI / 2 + TAU * i / n
		return center + Vector2(cos(a), sin(a)) * (64.0 if n <= 3 else 92.0)
	return Vector2(wagon_x + (i - (n - 1) / 2.0) * 96.0, wagon_y - 70.0)


func _hero_scale() -> float:
	return Art.HERO_SCALE * (0.82 if mode == Mode.CIRCLE and run.party.size() >= 4 else 1.0)


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
		var size: float = p.stats.size
		for seg in wyrm.segments.duplicate():
			if not seg.alive or p.hit_ids.has(seg.id):
				continue
			if seg.hit_test(p.pos, size):
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
	var hit_pos := p.pos
	var neighbours := wyrm.segments.duplicate()
	if s.dot > 0.0:
		wyrm.apply_dot(seg, s.dot * s.power, s.dot_spread)
	if s.slow > 0.0:
		wyrm.slow_timer = maxf(wyrm.slow_timer, s.slow)
	var dealt := wyrm.damage(seg, dmg)
	biggest_hit = maxf(biggest_hit, dealt)
	_add_number(hit_pos, dealt, crit)
	_add_effect("spark", hit_pos, 0.25, 0.6, p.color, 0.14, randf() * TAU)
	Sfx.play("armor" if seg.armor > 0.0 else "hit", -12.0)
	if s.splash > 0.0:
		_add_effect("glow", hit_pos, 0.2, s.splash / 64.0, Color(1.0, 0.5, 0.15, 0.9), 0.28)
		_add_effect("flame", hit_pos, 0.2, s.splash / 80.0, Color(1.0, 0.7, 0.3, 0.9), 0.3, randf() * TAU, 3.0)
		for other in neighbours:
			if other != seg and other.alive and other.hit_test(hit_pos, s.splash):
				wyrm.damage(other, dmg * 0.5)
	if crit:
		_add_effect("burst", hit_pos, 0.3, 1.0, Color(1, 0.9, 0.3), 0.22, randf() * TAU, 5.0)
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
	run.gold += Meta.gold_per_segment(stage_number) * (1.0 if seg.is_orb() else 2.5)
	var col: Color = Data.SEGMENTS[seg.type].color
	for k in range(0, seg.plates, 2):
		_add_effect("burst", seg.plate_pos[k], 0.3, 1.0, col.lightened(0.3), 0.3, randf() * TAU, 4.0)
	_add_effect("smoke", seg.pos, 0.4, 1.3, Color(0.6, 0.55, 0.55, 0.7), 0.5, randf() * TAU, 1.0, false)
	Sfx.play("kill", -6.0)
	match seg.type:
		"hero_chest":
			_pending_picks.append("hero")
			_chest_burst(seg.pos, Color(1.0, 0.6, 0.2))
		"skill_chest":
			_pending_picks.append("skill")
			_chest_burst(seg.pos, Color(0.4, 0.7, 1.0))
		"gilded":
			run.gold += Meta.gold_per_segment(stage_number) * 10.0
			run.refreshes += 1
			_add_effect("star", seg.pos, 0.3, 1.6, Color(1, 0.85, 0.3), 0.5, 0.0, 3.0)
			Sfx.play("coins")
	if not _pending_picks.is_empty():
		_open_next_pick.call_deferred()
	_update_hud()


func _chest_burst(pos: Vector2, col: Color) -> void:
	_add_effect("light", pos, 0.5, 4.0, col, 0.5)
	_add_effect("star", pos, 0.4, 1.8, Color(1, 0.9, 0.5), 0.45, 0.0, 4.0)
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
		"size": 46 if crit else 30, "color": Color(1, 0.85, 0.2) if crit else Color.WHITE,
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
	Engine.time_scale = 1.0
	_pick.visible = false
	_pause_panel.visible = false
	get_tree().paused = true
	reward = Meta.finish_run(stage_number, victory, run.gold)
	Sfx.play("legendary" if victory else "armor")
	Sfx.play("coins", -4.0)
	var lines: Array[String] = []
	lines.append("VICTORY!" if victory else "THE WALL FELL")
	lines.append(config.title)
	lines.append("")
	lines.append("Progress: %d%%" % int(progress() * 100.0))
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

	# Top centre: stage title + progress pill (like the reference).
	_title_label = _hud_label(config.title, 64, Vector2(0, 26), view.x)
	_title_label.add_theme_color_override("font_color", Color(1, 0.5, 0.4) if config.boss else Color.WHITE)
	ui.add_child(_title_label)
	var pill := Panel.new()
	var pill_box := StyleBoxFlat.new()
	pill_box.bg_color = Color(0.12, 0.1, 0.18, 0.75)
	pill_box.set_corner_radius_all(30)
	pill.add_theme_stylebox_override("panel", pill_box)
	pill.position = Vector2(view.x / 2.0 - 190, 112)
	pill.size = Vector2(380, 60)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(pill)
	_progress_label = _hud_label("", 36, Vector2(0, 116), view.x)
	ui.add_child(_progress_label)
	_info_label = _hud_label("", 30, Vector2(0, 182), view.x)
	_info_label.add_theme_color_override("font_color", UITheme.GOLD)
	ui.add_child(_info_label)

	# Left column: pause (with timer) and game speed.
	var pause := _hex_button("II")
	pause.position = Vector2(30, 40)
	pause.pressed.connect(func() -> void:
		if not over and not _pick.visible:
			get_tree().paused = true
			_pause_panel.visible = true)
	ui.add_child(pause)
	_timer_label = _hud_label("00:00", 30, Vector2(30, 172), 120)
	ui.add_child(_timer_label)
	_speed_button = _hex_button("x1")
	_speed_button.position = Vector2(30, 222)
	_speed_button.pressed.connect(func() -> void:
		Engine.time_scale = 2.0 if Engine.time_scale < 1.5 else 1.0
		_speed_button.text = "x%d" % int(Engine.time_scale))
	ui.add_child(_speed_button)

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
	_end_label = _big_label("", 40)
	ebox.add_child(_end_label)
	_next_button = _button("Next stage", func() -> void: exit_requested.emit("next"))
	ebox.add_child(_next_button)
	ebox.add_child(_button("Play again", func() -> void: exit_requested.emit("retry")))
	ebox.add_child(_button("Upgrades & menu", func() -> void: exit_requested.emit("menu")))


func _hud_label(text: String, size: int, pos: Vector2, width: float) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, size + 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _hex_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(120, 132)
	b.add_theme_font_size_override("font_size", 44)
	var hex := StyleBoxTexture.new()
	hex.texture = UITheme.HEX
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, hex)
	return b


func _overlay(parent: Control) -> Array:
	var panel := Control.new()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	parent.add_child(panel)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.06, 0.75)
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
	if not _progress_label:
		return
	_progress_label.text = "Progress: %d%%" % int(progress() * 100.0)
	_info_label.text = "Gold %s   ·   Refreshes %d" % [Meta.fmt(run.gold), run.refreshes]


# --- Drawing -----------------------------------------------------------------

func _draw() -> void:
	var bg: Texture2D = Art.BACKGROUNDS[config.theme]
	var tint := Color(1, 0.7, 0.7) if config.boss else Color.WHITE
	draw_texture_rect(bg, Rect2(Vector2.ZERO, Vector2(view.x, view.x * bg.get_height() / bg.get_width()).max(view)), false, tint)
	if mode == Mode.CIRCLE:
		draw_circle(center, 175.0, Color(0.05, 0.1, 0.12, 0.35))
		draw_arc(center, 168.0, 0, TAU, 72, Color(0.5, 1.0, 0.85, 0.55), 6.0)
		draw_arc(center, 140.0, 0, TAU, 72, Color(0.5, 1.0, 0.85, 0.3), 3.0)


## Additive layer: glows behind magic projectiles and particle effects.
func _draw_glow(c: CanvasItem) -> void:
	if mode == Mode.CIRCLE:
		Art.draw_sprite(c, Art.FX.magic, center, 2.6, _time * 0.3, Color(0.2, 0.6, 0.5, 0.35))
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


func _draw_wall(c: CanvasItem) -> void:
	var hit := Color(1, 0.75, 0.75) if _wall_flash > 0.2 else Color.WHITE
	var frac := wall_hp / wall_max
	var bar_w := 520.0
	var bar_pos: Vector2
	if mode == Mode.CIRCLE:
		for i in 22:
			var a := TAU * i / 22.0
			Art.draw_sprite(c, Art.WALL_BLOCK, center + Vector2.from_angle(a) * WALL_RADIUS, 1.0, a + PI / 2, hit)
		bar_pos = Vector2(center.x - bar_w / 2.0, center.y + WALL_RADIUS + 50.0)
	else:
		var wall_h := Art.WALL.get_height() * view.x / Art.WALL.get_width()
		c.draw_texture_rect(Art.WALL, Rect2(0, wall_y, view.x, wall_h), false, hit)
		bar_pos = Vector2(view.x / 2.0 - bar_w / 2.0, wall_y + 18.0)
	# Wall HP bar with a heart, like the reference.
	var bar := Rect2(bar_pos, Vector2(bar_w, 30))
	c.draw_rect(bar.grow(5), Color(0.08, 0.05, 0.1, 0.9))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.45, 0.9, 0.3).lerp(Color(1, 0.25, 0.2), 1.0 - frac))
	var txt := "Wall  %d / %d" % [ceili(wall_hp), ceili(wall_max)]
	c.draw_string_outline(Art.FONT, bar.position + Vector2(0, 27), txt, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 30, 8, UITheme.OUTLINE)
	c.draw_string(Art.FONT, bar.position + Vector2(0, 27), txt, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 30, Color.WHITE)


func _draw_fx(c: CanvasItem) -> void:
	var font := Art.FONT
	_draw_wall(c)
	# Aim guide
	if mode == Mode.CIRCLE and not over:
		for i in range(1, 7):
			c.draw_circle(center + aim_dir * (110.0 + i * 36.0), 7.0 - i * 0.6, Color(1, 0.95, 0.7, 0.6 - i * 0.07))
	# Wagon
	if mode == Mode.WAGON:
		var w := 96.0 * run.party.size() + 90.0
		var body := Rect2(Vector2(wagon_x - w / 2.0, wagon_y - 30.0), Vector2(w, 64.0))
		c.draw_rect(body.grow(6.0), UITheme.OUTLINE)
		c.draw_rect(body, Color(0.72, 0.45, 0.24))
		c.draw_rect(Rect2(body.position, Vector2(w, 16.0)), Color(0.88, 0.6, 0.34))
		for x in [body.position.x + 40.0, body.end.x - 40.0]:
			var wheel := Vector2(x, body.end.y + 10.0)
			c.draw_circle(wheel, 32.0, UITheme.OUTLINE)
			c.draw_circle(wheel, 26.0, Color(0.6, 0.38, 0.2))
			c.draw_circle(wheel, 9.0, Color(0.85, 0.85, 0.9))
	# Heroes
	var hs := _hero_scale()
	for i in run.party.size():
		var h := run.party[i]
		var pos := hero_position(h) + Vector2(0, sin(_time * 5.0 + i * 1.3) * 3.0)
		var punch: float = 1.0 + _recoil.get(h, 0.0) * 1.2
		Art.draw_sprite(c, Art.HEROES[h], pos, hs * punch)
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
		c.draw_string_outline(font, pos, n.text, HORIZONTAL_ALIGNMENT_CENTER, 220, size, 10, Color(0.1, 0.05, 0.08, col.a))
		c.draw_string(font, pos, n.text, HORIZONTAL_ALIGNMENT_CENTER, 220, size, col)
