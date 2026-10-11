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
	var head := TextureRect.new()
	head.texture = Art.WYRM_HEADS.dragon
	head.custom_minimum_size = Vector2(0, 240)
	head.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(head)
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
	box.add_child(_button("Upgrades", show_upgrades))
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
	box.add_child(_label("Upgrades", 72, Color(0.95, 0.75, 0.25)))
	box.add_child(_label("Gold: %s" % Meta.fmt(Meta.gold), 48, Color(1, 0.85, 0.3)))

	box.add_child(_label("Heroes  (+15% damage per level)", 40, Color.WHITE))
	for id in Data.HEROES:
		var h: Dictionary = Data.HEROES[id]
		var info := "%s  Lv %d\nDamage x%s" % [h.name, Meta.hero_level(id), _mult(Meta.hero_damage_mult(id))]
		box.add_child(_upgrade_row(info, h.color, Meta.hero_cost(id), false, Art.HEROES[id],
			func() -> void:
				if Meta.buy_hero_level(id):
					show_upgrades()))

	box.add_child(_spacer(10))
	box.add_child(_label("Armory", 40, Color.WHITE))
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
	l.add_theme_font_size_override("font_size", 28)
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
	bg.texture = Art.BACKGROUNDS.crypt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.75, 0.7, 0.8)
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


func _button(text: String, cb: Callable, size := 44, color := Color.WHITE) -> Button:
	var b := Button.new()
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
