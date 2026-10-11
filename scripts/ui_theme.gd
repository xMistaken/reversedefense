class_name UITheme
extends RefCounted
## Builds the game-wide UI theme from the Kenney RPG UI pack and font.

const BUTTON := preload("res://assets/ui/button.png")
const BUTTON_PRESSED := preload("res://assets/ui/button_pressed.png")
const BUTTON_GREY := preload("res://assets/ui/button_grey.png")
const PANEL := preload("res://assets/ui/panel.png")
const BAR_BACK := preload("res://assets/ui/bar_back.png")
const BAR_RED := preload("res://assets/ui/bar_red.png")

const TEXT := Color(1.0, 0.95, 0.85)
const GOLD := Color(1.0, 0.82, 0.3)


static var _cached: Theme


## Shared theme instance; assign it to every root Control.
static func get_theme() -> Theme:
	if _cached == null:
		_cached = make()
	return _cached


static func make() -> Theme:
	var t := Theme.new()
	t.default_font = Art.FONT
	t.default_font_size = 40

	t.set_stylebox("normal", "Button", _box(BUTTON, 30, 30))
	t.set_stylebox("hover", "Button", _box(BUTTON, 30, 30))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "Button", _box(BUTTON_PRESSED, 30, 30))
	t.set_stylebox("disabled", "Button", _box(BUTTON_GREY, 30, 30, Color(1, 1, 1, 0.6)))
	t.set_stylebox("hover_pressed", "Button", _box(BUTTON_PRESSED, 30, 30))
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(c, "Button", TEXT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.75, 0.72, 0.68))
	t.set_constant("outline_size", "Button", 8)
	t.set_color("font_outline_color", "Button", Color(0.18, 0.1, 0.08))

	t.set_color("font_color", "Label", TEXT)
	t.set_constant("outline_size", "Label", 10)
	t.set_color("font_outline_color", "Label", Color(0.1, 0.06, 0.06))

	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 36, 36))
	t.set_stylebox("background", "ProgressBar", _box(BAR_BACK, 18, 18))
	t.set_stylebox("fill", "ProgressBar", _box(BAR_RED, 18, 18))
	return t


static func _box(tex: Texture2D, margin_x: float, margin_y: float, modulate := Color.WHITE) -> StyleBoxTexture:
	var b := StyleBoxTexture.new()
	b.texture = tex
	b.texture_margin_left = margin_x
	b.texture_margin_right = margin_x
	b.texture_margin_top = margin_y
	b.texture_margin_bottom = margin_y
	b.content_margin_left = 24
	b.content_margin_right = 24
	b.content_margin_top = 12
	b.content_margin_bottom = 16
	b.modulate_color = modulate
	return b
