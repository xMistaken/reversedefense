extends Node
## Entry point: main menu (pick starting hero + stage type) and stage switching.

var selected_hero := "warrior"
var last_mode := Stage.Mode.CIRCLE
var _current: Node


func _ready() -> void:
	show_menu()


func show_menu() -> void:
	_swap(_build_menu())


func start_stage(mode: Stage.Mode) -> void:
	last_mode = mode
	var stage := Stage.new()
	stage.mode = mode
	stage.starting_hero = selected_hero
	stage.exit_requested.connect(_on_stage_exit)
	_swap(stage)


func _on_stage_exit(action: String) -> void:
	if action == "retry":
		start_stage(last_mode)
	else:
		show_menu()


func _swap(node: Node) -> void:
	get_tree().paused = false
	if _current:
		_current.queue_free()
	_current = node
	add_child(node)


func _build_menu() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	center.add_child(box)

	box.add_child(_label("WYRMBREAKER", 110, Color(0.95, 0.75, 0.25)))
	box.add_child(_label("Break the wyrm before it breaks through.", 36, Color(0.8, 0.8, 0.8)))
	box.add_child(_spacer(40))
	box.add_child(_label("Choose your starting hero", 46, Color.WHITE))

	var hint := _label("", 32, Color(0.75, 0.75, 0.75))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(900, 90)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	box.add_child(grid)
	var group := ButtonGroup.new()
	for id in Data.HEROES:
		var h: Dictionary = Data.HEROES[id]
		var b := Button.new()
		b.text = h.name
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = id == selected_hero
		b.custom_minimum_size = Vector2(440, 120)
		b.add_theme_font_size_override("font_size", 44)
		b.add_theme_color_override("font_color", h.color)
		b.add_theme_color_override("font_pressed_color", h.color)
		b.add_theme_color_override("font_hover_color", h.color)
		b.add_theme_color_override("font_hover_pressed_color", h.color)
		b.pressed.connect(func() -> void:
			selected_hero = id
			hint.text = h.blurb)
		grid.add_child(b)
	hint.text = Data.HEROES[selected_hero].blurb
	box.add_child(hint)

	box.add_child(_spacer(30))
	box.add_child(_label("Choose a stage", 46, Color.WHITE))
	for pair in [["Ritual Circle  (drag to aim)", Stage.Mode.CIRCLE], ["War Wagon  (drag to move)", Stage.Mode.WAGON]]:
		var b := Button.new()
		b.text = pair[0]
		b.custom_minimum_size = Vector2(900, 140)
		b.add_theme_font_size_override("font_size", 46)
		b.pressed.connect(start_stage.bind(pair[1]))
		box.add_child(b)
	return root


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
