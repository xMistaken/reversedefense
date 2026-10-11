class_name UITheme
extends RefCounted
## Game-wide UI theme: chunky cartoon buttons and panels (assets/hd/ui) with
## the Lilita One font.

const BUTTON := preload("res://assets/hd/ui/button.svg")
const BUTTON_PRESSED := preload("res://assets/hd/ui/button_pressed.svg")
const BUTTON_BLUE := preload("res://assets/hd/ui/button_blue.svg")
const BUTTON_DISABLED := preload("res://assets/hd/ui/button_disabled.svg")
const PANEL := preload("res://assets/hd/ui/panel.svg")
const HEX := preload("res://assets/hd/ui/hex.svg")

const TEXT := Color(1.0, 0.98, 0.92)
const GOLD := Color(1.0, 0.84, 0.3)
const OUTLINE := Color(0.14, 0.08, 0.12)

static var _cached: Theme


## Shared theme instance; assign it to every root Control.
static func get_theme() -> Theme:
	if _cached == null:
		_cached = make()
	return _cached


static func make() -> Theme:
	var t := Theme.new()
	t.default_font = Art.FONT
	t.default_font_size = 42

	t.set_stylebox("normal", "Button", box(BUTTON, 36, 34, 40))
	t.set_stylebox("hover", "Button", box(BUTTON, 36, 34, 40))
	t.set_stylebox("pressed", "Button", box(BUTTON_PRESSED, 36, 34, 40))
	t.set_stylebox("hover_pressed", "Button", box(BUTTON_PRESSED, 36, 34, 40))
	t.set_stylebox("disabled", "Button", box(BUTTON_DISABLED, 36, 34, 40))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(0.85, 0.83, 0.88))
	t.set_constant("outline_size", "Button", 12)
	t.set_color("font_outline_color", "Button", OUTLINE)

	t.set_color("font_color", "Label", TEXT)
	t.set_constant("outline_size", "Label", 12)
	t.set_color("font_outline_color", "Label", OUTLINE)

	t.set_stylebox("panel", "PanelContainer", box(PANEL, 50, 50, 50, 40))
	return t


## Toggle-button look (blue = selected).
static func blue_box() -> StyleBoxTexture:
	return box(BUTTON_BLUE, 36, 34, 40)


static func box(tex: Texture2D, margin_x: float, margin_top: float, margin_bottom: float, content := 22.0) -> StyleBoxTexture:
	var b := StyleBoxTexture.new()
	b.texture = tex
	b.texture_margin_left = margin_x
	b.texture_margin_right = margin_x
	b.texture_margin_top = margin_top
	b.texture_margin_bottom = margin_bottom
	b.content_margin_left = content + 8
	b.content_margin_right = content + 8
	b.content_margin_top = content * 0.5
	b.content_margin_bottom = content * 0.8
	return b
