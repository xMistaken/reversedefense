extends Node2D
## Draws every track shape (normally invisible in game) in a 4x2 grid and
## saves a PNG. Needs a display (e.g. xvfb-run):
##   godot --resolution 1080x1920 res://tests/track_preview.tscn -- out=/path/tracks.png

var out_path := "user://tracks.png"
var _curves: Array = []  # [label, Curve2D]


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			out_path = arg.trim_prefix("out=")
	var view := Vector2(1080, 1920)
	var center := Vector2(view.x / 2.0, view.y * 0.52)
	var wagon_y := view.y - 230.0
	var kinds := StageConfig.CIRCLE_TRACKS + StageConfig.WAGON_TRACKS + ["columns"]
	for i in kinds.size():
		var cfg := StageConfig.make(1 if i < 4 else 2)
		cfg.track_kind = kinds[i]
		cfg.track_seed = 12345 + i
		_curves.append([kinds[i], cfg.build_track(view, center, wagon_y), i < 4])
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_path)
	get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1080, 1920), Color(0.1, 0.1, 0.12))
	var font := ThemeDB.fallback_font
	for i in _curves.size():
		var cell := Vector2((i % 4) * 270, (i / 4) * 960)
		var xf := Transform2D(0, Vector2(0.25, 0.5), 0, cell)
		draw_set_transform_matrix(xf)
		draw_rect(Rect2(0, 0, 1080, 1920), Color(0.16, 0.18, 0.16) if _curves[i][2] else Color(0.2, 0.16, 0.12))
		draw_rect(Rect2(0, 0, 1080, 230), Color(0, 0, 0, 0.5))
		draw_polyline(_curves[i][1].get_baked_points(), Color(0.9, 0.4, 0.4), 60.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		draw_string(font, cell + Vector2(8, 40), _curves[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		draw_string(font, cell + Vector2(8, 70), "len %d" % _curves[i][1].get_baked_length(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
