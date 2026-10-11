extends Node
## Headless balance/smoke test: a simple bot plays stages to completion.
## Run: godot --headless --fixed-fps 60 res://tests/sim_test.tscn [-- runs=N]
## The bot aims at the front of the chain and always takes the first offer.

var runs_per_case := 3
var _cases: Array = []
var _stage: Stage
var _case: Array
var _time := 0.0
var _peak := 0.0
var _results: Array[String] = []
var _wins := 0
var _total := 0
var _failed := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("runs="):
			runs_per_case = int(arg.trim_prefix("runs="))
	for mode in [Stage.Mode.CIRCLE, Stage.Mode.WAGON]:
		for hero in Data.HEROES:
			for r in runs_per_case:
				_cases.append([mode, hero, r])
	_next()


func _next() -> void:
	if _stage:
		_stage.queue_free()
		_stage = null
	get_tree().paused = false
	if _cases.is_empty():
		_finish()
		return
	_case = _cases.pop_front()
	seed(1000 + _case[2] * 7919 + hash(_case[1]))
	_stage = Stage.new()
	_stage.mode = _case[0]
	_stage.starting_hero = _case[1]
	_time = 0.0
	_peak = 0.0
	add_child(_stage)


func _process(delta: float) -> void:
	if not _stage:
		return
	if _stage.over:
		_record()
		_next()
		return
	if _stage.is_picking():
		var offers := _stage.pick_offers()
		_stage.choose(_stage.pick_kind(), offers[0])
		return
	_time += delta
	_peak = maxf(_peak, _stage.wyrm.danger())
	if _time > 600.0:
		push_error("Stage did not finish in 600s: %s" % [_case])
		_failed = true
		_record()
		_next()
		return
	var target := _pick_target()
	if target:
		if _stage.mode == Stage.Mode.CIRCLE:
			_stage.aim_at(target.pos)
		else:
			_stage._point(target.pos)


func _pick_target() -> Wyrm.Segment:
	var best: Wyrm.Segment = null
	for s in _stage.wyrm.segments:
		if not s.on_track():
			continue
		if _stage.mode == Stage.Mode.CIRCLE:
			if not best or s.offset > best.offset:
				best = s
		elif not best or s.pos.y > best.pos.y + 5.0 or (absf(s.pos.y - best.pos.y) <= 5.0 and s.offset > best.offset):
			best = s
	return best


func _record() -> void:
	var r := _stage.run
	var mode_name: String = "circle" if _case[0] == Stage.Mode.CIRCLE else "wagon"
	_total += 1
	if _stage.won:
		_wins += 1
	_results.append("%-6s %-8s #%d  %-4s  t=%5.1fs  left=%2d  peak_danger=%.2f  party=%d  skills=%d" % [
		mode_name, _case[1], _case[2], "WIN" if _stage.won else "LOSS", _time,
		_stage.wyrm.segments.size(), _peak, r.party.size(), r.ranks.values().reduce(func(a, b): return a + b, 0)])


func _finish() -> void:
	for line in _results:
		print(line)
	print("WINS %d / %d" % [_wins, _total])
	get_tree().quit(1 if _failed else 0)
