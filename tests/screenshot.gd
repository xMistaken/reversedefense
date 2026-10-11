extends Node
## Captures preview screenshots of the menu, both stages and a chest pick.
## Run (needs a display, e.g. xvfb-run):
##   godot --fixed-fps 60 --resolution 540x960 res://tests/screenshot.tscn -- out=/path/to/dir

var out_dir := "user://screens"
var _main: Node
var _step := 0
var _frames := 0
var _picked_shot := false
var _pick_frames := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			out_dir = arg.trim_prefix("out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(_delta: float) -> void:
	_frames += 1
	var stage: Stage = _main._current as Stage
	if stage and stage.is_picking():
		_pick_frames += 1
		if not _picked_shot and _pick_frames < 10:
			return
		if not _picked_shot:
			_picked_shot = true
			await _shot("pick")
		_pick_frames = 0
		stage.choose(stage.pick_kind(), stage.pick_offers()[0])
	elif stage and not stage.over:
		var best: Wyrm.Segment = null
		for s in stage.wyrm.segments:
			if s.on_track() and (not best or s.offset > best.offset):
				best = s
		if best:
			stage._point(best.pos)

	match _step:
		0:
			if _frames == 20:
				_step = 1
				await _shot("menu")
				_main.start_stage(Stage.Mode.CIRCLE)
				_frames = 0
		1:
			if _frames == 60 * 40:
				_step = 2
				await _shot("circle")
				_main.selected_hero = "mage"
				_main.start_stage(Stage.Mode.WAGON)
				_frames = 0
		2:
			if _frames == 60 * 40:
				_step = 3
				await _shot("wagon")
				get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)
