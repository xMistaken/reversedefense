class_name PickPanel
extends Control
## "Pick 1 of 3" overlay shown when a chest segment breaks.

signal chosen(kind: String, offer: Dictionary)
signal refresh_requested(kind: String)

var kind := ""
var offers: Array[Dictionary] = []

var _title: Label
var _buttons: Array[Button] = []
var _labels: Array[Label] = []
var _refresh: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.04, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_color_override("font_color", Color(1, 0.82, 0.3))
	box.add_child(_title)

	for i in RunState.OFFER_COUNT:
		var b := Button.new()
		b.custom_minimum_size = Vector2(940, 250)
		b.pressed.connect(_on_pick.bind(i))
		var l := Label.new()
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.offset_left = 24
		l.offset_right = -24
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 36)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(l)
		box.add_child(b)
		_buttons.append(b)
		_labels.append(l)

	_refresh = Button.new()
	_refresh.custom_minimum_size = Vector2(920, 120)
	_refresh.add_theme_font_size_override("font_size", 40)
	_refresh.pressed.connect(func() -> void: refresh_requested.emit(kind))
	box.add_child(_refresh)


func show_offers(new_kind: String, new_offers: Array[Dictionary], run: RunState) -> void:
	kind = new_kind
	offers = new_offers
	_title.text = "Hero Chest! Recruit a hero" if kind == "hero" else "Skill Chest! Learn a skill"
	for i in _buttons.size():
		var b := _buttons[i]
		b.visible = i < offers.size()
		if b.visible:
			_labels[i].text = _describe(offers[i], run)
			var col := _color(offers[i])
			_labels[i].add_theme_color_override("font_color", col)
			var box := StyleBoxFlat.new()
			box.bg_color = Color(0.24, 0.15, 0.11, 0.97)
			box.border_color = col
			box.set_border_width_all(6 if offers[i].get("rarity", "") in ["Epic", "Legendary"] else 3)
			box.set_corner_radius_all(14)
			for state in ["normal", "hover", "pressed", "focus"]:
				b.add_theme_stylebox_override(state, box)
	_refresh.text = "Refresh (%d left)" % run.refreshes
	_refresh.disabled = run.refreshes <= 0
	visible = true


func _color(offer: Dictionary) -> Color:
	if kind == "hero":
		return Data.HEROES[offer.id].color
	if offer.rarity == "Legendary":
		return Data.LEGENDARY_COLOR
	for r in Data.RARITIES:
		if r.name == offer.rarity:
			return r.color
	return Color.WHITE


func _describe(offer: Dictionary, run: RunState) -> String:
	var id: String = offer.id
	if kind == "hero":
		var h: Dictionary = Data.HEROES[id]
		return "NEW HERO: %s\n%s" % [h.name, h.blurb]
	var s := Data.get_skill(id)
	var owner_name: String = "Party" if s.hero == "" else Data.HEROES[s.hero].name
	if offer.rarity == "Legendary":
		return "* LEGENDARY *  %s  [%s]\n%s" % [s.name, owner_name, s.desc]
	var gain: int = offer.ranks
	var rank_txt := "Rank %d/%d" % [run.rank_of(id) + gain, Data.max_rank(s)]
	if gain > 1:
		rank_txt = "%s +%d ranks!  %s" % [offer.rarity.to_upper(), gain, rank_txt]
	return "%s  [%s]\n%s\n%s" % [s.name, owner_name, rank_txt, s.desc]


func _on_pick(i: int) -> void:
	if i < offers.size():
		chosen.emit(kind, offers[i])
