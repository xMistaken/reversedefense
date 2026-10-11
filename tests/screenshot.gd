extends Node
## Captures preview screenshots of the menus, both stage types, a chest pick
## and the end screen. Needs a display (e.g. xvfb-run):
##   godot --fixed-fps 60 --resolution 540x960 res://tests/screenshot.tscn -- out=/path/to/dir

var out_dir := "user://screens"
var _main: Node
var _step := 0
var _frames := 0
var _pick_frames := 0
var _picked_shot := false
var _busy := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			out_dir = arg.trim_prefix("out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	Meta.persist = false
	Meta.reset()
	Meta.gold = 12345.0
	Meta.highest_cleared = 14
	Meta.hero_levels = {"warrior": 9, "mage": 7, "hunter": 6, "priest": 5, "rogue": 6, "warlock": 5}
	Meta.armory = {"might": 6, "haste": 4, "ferocity": 3, "fortune": 2, "insight": 1, "treasure": 1}
	Meta.hero_ranks = {"warrior": 6, "mage": 3, "hunter": 2}
	Meta.hero_shards = {"warrior": 0, "mage": 9, "hunter": 3, "priest": 4}
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _process(_delta: float) -> void:
	if _busy:
		return
	_frames += 1
	var stage := _main._current as Stage
	if stage and stage.is_picking():
		_pick_frames += 1
		if not _picked_shot and _pick_frames >= 10 and stage.skills_learned >= 3:
			_picked_shot = true
			await _shot("pick")
		elif _picked_shot or _pick_frames >= 10:
			_pick_frames = 0
			stage.choose(stage.pick_kind(), stage.pick_offers()[0])
		return
	if stage and not stage.over:
		var best: Wyrm.Segment = null
		for s in stage.wyrm.segments:
			if s.on_track() and (not best or s.offset > best.offset):
				best = s
		if best:
			stage._point(best.pos)

	match _step:
		0:
			if _frames >= 20:
				await _shot("home")
				_main.show_hero("warrior")
				_next_step()
		1:
			if _frames >= 10:
				await _shot("hero")
				_main.show_heroes()
				_next_step()
		2:
			if _frames >= 10:
				await _shot("heroes")
				_main.start_stage(13)
				_next_step()
		3:
			if _frames >= 60 * 14:
				await _shot("circle")
				_main.start_stage(10)
				_next_step()
		4:
			if _frames >= 60 * 14:
				await _shot("wagon")
				stage.retreat()
				_next_step()
		5:
			if _frames >= 10:
				await _shot("end")
				get_tree().quit()


func _next_step() -> void:
	_step += 1
	_frames = 0


func _shot(name: String) -> void:
	_busy = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)
	_busy = false
