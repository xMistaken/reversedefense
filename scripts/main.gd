extends Node
## Entry point: home screen, stage select, upgrades shop, and stage switching.

var last_stage := 1
var _current: Node


func _ready() -> void:
	show_home()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		Meta.save_game()


func start_stage(n: int) -> void:
	last_stage = n
	var stage := Stage.new()
	stage.stage_number = n
	stage.starting_hero = Meta.selected_hero
	stage.exit_requested.connect(_on_stage_exit)
	_swap(stage)


func _on_stage_exit(action: String) -> void:
	match action:
		"retry":
			start_stage(last_stage)
		"next":
			start_stage(mini(last_stage + 1, Meta.STAGE_COUNT))
		_:
			show_home()


func _swap(node: Node) -> void:
	get_tree().paused = false
	if _current:
		_current.queue_free()
	_current = node
	add_child(node)


# --- Home ------------------------------------------------------------------

func show_home() -> void:
	var s := _screen()
	var box: VBoxContainer = s[1]
	box.add_child(_spacer(330))
	box.add_child(_label("WYRMBREAKER", 96, Color(0.95, 0.75, 0.25)))
	box.add_child(_label("Gold: %s" % Meta.fmt(Meta.gold), 48, Color(1, 0.85, 0.3)))
	box.add_child(_label("Stages cleared: %d / %d" % [Meta.highest_cleared, Meta.STAGE_COUNT], 36, Color(0.8, 0.8, 0.8)))
	box.add_child(_spacer(20))
	box.add_child(_label("Starting hero", 42, Color.WHITE))

	var hint := _label(Data.HEROES[Meta.selected_hero].blurb, 30, Color(0.75, 0.75, 0.75))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(900, 80)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	box.add_child(grid)
	var group := ButtonGroup.new()
	for id in Data.HEROES:
		var h: Dictionary = Data.HEROES[id]
		var b := Button.new()
		b.text = "%s\nLv %d" % [h.name, Meta.hero_level(id)]
		b.icon = Art.HEROES[id]
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 72)
		b.add_theme_stylebox_override("pressed", UITheme.blue_box())
		b.add_theme_stylebox_override("hover_pressed", UITheme.blue_box())
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = id == Meta.selected_hero
		b.custom_minimum_size = Vector2(320, 140)
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(func() -> void:
			Meta.selected_hero = id
			Meta.save_game()
			hint.text = h.blurb)
		grid.add_child(b)
	box.add_child(hint)

	var next := Meta.next_stage()
	box.add_child(_button("PLAY  %s" % StageConfig.make(next).title, func() -> void: start_stage(next), 54))
	box.add_child(_button("Choose stage (farm gold)", show_stage_select))
	box.add_child(_button("Heroes", show_heroes, 44, Color.WHITE, _any_rank_up()))
	box.add_child(_button("Armory", show_upgrades))
	_swap(s[0])


# --- Stage select ------------------------------------------------------------

func show_stage_select() -> void:
	var s := _screen(true)
	var box: VBoxContainer = s[1]
	box.add_child(_label("Choose a stage", 64, Color(0.95, 0.75, 0.25)))
	box.add_child(_label("Replay cleared stages to farm gold", 32, Color(0.8, 0.8, 0.8)))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)
	for n in range(1, Meta.STAGE_COUNT + 1):
		var cfg := StageConfig.make(n)
		var b := Button.new()
		b.custom_minimum_size = Vector2(176, 130)
		b.add_theme_font_size_override("font_size", 36)
		var mark := "BOSS" if cfg.boss else ("Done" if n <= Meta.highest_cleared else "")
		b.text = "%d\n%s" % [n, mark]
		b.disabled = not Meta.is_unlocked(n)
		if cfg.boss:
			b.add_theme_color_override("font_color", Color(1, 0.45, 0.35))
		elif n <= Meta.highest_cleared:
			b.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		b.pressed.connect(start_stage.bind(n))
		grid.add_child(b)
	box.add_child(_button("Back", show_home))
	_swap(s[0])


# --- Upgrades ----------------------------------------------------------------

func show_upgrades() -> void:
	var s := _screen(true)
	var box: VBoxContainer = s[1]
	box.add_child(_label("Armory", 72, Color(0.95, 0.75, 0.25)))
	box.add_child(_label("Gold: %s" % Meta.fmt(Meta.gold), 48, Color(1, 0.85, 0.3)))

	for id in Meta.ARMORY:
		var a: Dictionary = Meta.ARMORY[id]
		var lvl := Meta.armory_level(id)
		var cap := "" if a.max == 0 else "/%d" % a.max
		var info := "%s  Lv %d%s\n%s" % [a.name, lvl, cap, a.desc]
		box.add_child(_upgrade_row(info, Color(0.8, 0.85, 1.0), Meta.armory_cost(id), Meta.armory_maxed(id), null,
			func() -> void:
				if Meta.buy_armory(id):
					show_upgrades()))
	box.add_child(_button("Back", show_home))
	_swap(s[0])


# --- Heroes ------------------------------------------------------------------

func _any_rank_up() -> bool:
	for id in Data.HEROES:
		if Meta.can_rank_up(id):
			return true
	return false


func show_heroes() -> void:
	var s := _screen(true)
	var box: VBoxContainer = s[1]
	box.add_child(_label("Heroes", 72, Color(0.95, 0.75, 0.25)))
	box.add_child(_label("Train with gold. Rank up with hero shards,\nwhich every party member earns each run.", 30, Color(0.85, 0.85, 0.9)))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	box.add_child(grid)
	for id in Data.HEROES:
		var h: Dictionary = Data.HEROES[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(480, 260)
		b.icon = Art.HEROES[id]
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 150)
		b.add_theme_font_size_override("font_size", 34)
		var rank := Meta.hero_rank(id)
		var shard_txt := "MAX" if rank >= Data.HERO_MAX_RANK else "%d/%d" % [Meta.shards(id), Meta.rank_cost(id)]
		b.text = "%s\nLv %d\nRank %d/%d\nShards %s%s" % [h.name, Meta.hero_level(id), rank, Data.HERO_MAX_RANK, shard_txt, "  !" if Meta.can_rank_up(id) else ""]
		if Meta.can_rank_up(id):
			b.add_theme_stylebox_override("normal", UITheme.blue_box())
		b.pressed.connect(show_hero.bind(id))
		grid.add_child(b)
	box.add_child(_button("Back", show_home))
	_swap(s[0])


func show_hero(id: String) -> void:
	var h: Dictionary = Data.HEROES[id]
	var s := _screen(true)
	var box: VBoxContainer = s[1]
	box.add_child(_label(h.name, 80, Color(0.95, 0.75, 0.25)))

	# Portrait + stats card
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 30)
	box.add_child(card)
	var portrait := TextureRect.new()
	portrait.texture = Art.HEROES[id]
	portrait.custom_minimum_size = Vector2(300, 340)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(portrait)
	var stats := RunState.new(id).hero_stats(id)
	var info := Label.new()
	info.add_theme_font_size_override("font_size", 36)
	info.text = "Level %d   Rank %d\n\nDamage  %s\nAttack interval  %.2fs\nProjectiles  %d\nCrit  %d%%  (x%.1f)" % [
		Meta.hero_level(id), Meta.hero_rank(id), Meta.fmt(stats.damage * stats.power), stats.cooldown,
		stats.count, int(stats.crit * 100.0), stats.crit_mult]
	card.add_child(info)

	# Train (gold)
	box.add_child(_label("Train", 46, Color.WHITE))
	box.add_child(_upgrade_row("Level %d  ->  %d\n+15%% damage" % [Meta.hero_level(id), Meta.hero_level(id) + 1],
		h.color, Meta.hero_cost(id), false, null,
		func() -> void:
			if Meta.buy_hero_level(id):
				show_hero(id)))

	# Skill track (ranks)
	box.add_child(_label("Skills", 46, Color.WHITE))
	var rank := Meta.hero_rank(id)
	var perks: Array = Data.HERO_RANKS[id]
	for i in perks.size():
		var p: Dictionary = perks[i]
		var unlocked := i < rank
		var row := PanelContainer.new()
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(900, 0)
		l.add_theme_font_size_override("font_size", 32)
		var tag := "LV%d %s:" % [i + 1, "ULTIMATE" if p.get("ult", false) else "Unlock"]
		l.text = "%s %s\n%s" % [tag, p.name, p.desc]
		var col := Color(0.55, 1.0, 0.5) if unlocked else Color(0.62, 0.6, 0.68)
		if p.get("ult", false):
			col = Color(1.0, 0.7, 0.25) if unlocked else Color(0.85, 0.6, 0.35)
		l.add_theme_color_override("font_color", col)
		row.add_child(l)
		box.add_child(row)

	var maxed := rank >= Data.HERO_MAX_RANK
	var rank_btn := _button("MAX RANK" if maxed else "Rank Up  (%d / %d shards)" % [Meta.shards(id), Meta.rank_cost(id)],
		func() -> void:
			if Meta.rank_up(id):
				Sfx.play("legendary")
				show_hero(id))
	rank_btn.disabled = not Meta.can_rank_up(id)
	box.add_child(rank_btn)
	box.add_child(_button("Back", show_heroes))
	_swap(s[0])


func _upgrade_row(info: String, color: Color, cost: float, maxed: bool, icon: Texture2D, buy: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(980, 120)
	row.add_theme_constant_override("separation", 20)
	if icon:
		var t := TextureRect.new()
		t.texture = icon
		t.custom_minimum_size = Vector2(80, 80)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(t)
	var l := Label.new()
	l.text = info
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", color)
	row.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 110)
	b.add_theme_font_size_override("font_size", 36)
	b.text = "MAX" if maxed else Meta.fmt(cost)
	b.disabled = maxed or Meta.gold < cost
	b.pressed.connect(func() -> void:
		Sfx.play("coins")
		buy.call())
	row.add_child(b)
	return row


# --- Helpers -----------------------------------------------------------------

## Returns [root, content VBox]. Scrollable screens get a ScrollContainer.
func _screen(scroll := false) -> Array:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.get_theme()
	var bg := TextureRect.new()
	bg.texture = Art.BACKGROUNDS.menu
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(1, 1, 1) if not scroll else Color(0.45, 0.42, 0.5)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	if scroll:
		var sc := ScrollContainer.new()
		sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sc.offset_top = 60
		sc.offset_bottom = -40
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		root.add_child(sc)
		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 40)
		margin.add_theme_constant_override("margin_right", 40)
		sc.add_child(margin)
		margin.add_child(box)
	else:
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(center)
		center.add_child(box)
	return [root, box]


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, cb: Callable, size := 44, color := Color.WHITE, highlight := false) -> Button:
	var b := Button.new()
	if highlight:
		b.add_theme_stylebox_override("normal", UITheme.blue_box())
		text += "  !"
	b.text = text
	b.custom_minimum_size = Vector2(900, 130)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", color)
	b.pressed.connect(cb)
	return b


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _mult(x: float) -> String:
	return Meta.fmt(x) if x >= 1000.0 else String.num(x, 2)
