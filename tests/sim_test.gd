extends Node
## Headless bot tests. The bot aims at the front of the chain and always takes
## the first offer.
##
##   godot --headless --fixed-fps 60 res://tests/sim_test.tscn -- [options]
##
## mode=smoke (default): plays `stages` (comma list) with every starting hero,
##   no permanent upgrades. Fails on stages that never finish.
## mode=career: fresh save, plays the next stage over and over, spending gold
##   greedily on the cheapest upgrade after every run (i.e. farming). Prints
##   how many runs each stage took. Stops at `target` stage or `max_runs`.

var mode := "smoke"
var stages: Array[int] = [1, 2]
var target := 30
var max_runs := 200

var _cases: Array = []
var _stage: Stage
var _case: Array
var _time := 0.0
var _peak := 0.0
var _failed := false
var _wins := 0
var _total := 0
var _runs_on_stage := 0
var _start_ms := 0


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"mode": mode = kv[1]
			"target": target = int(kv[1])
			"max_runs": max_runs = int(kv[1])
			"hp_growth": StageConfig.hp_growth_per_stage = float(kv[1])
			"gold_growth": Meta.gold_growth = float(kv[1])
			"cost_scale": Meta.cost_scale = float(kv[1])
			"stages":
				stages.clear()
				for s in kv[1].split(","):
					stages.append(int(s))
	Meta.persist = false
	Meta.reset()
	if mode == "smoke":
		for n in stages:
			for hero in Data.HEROES:
				_cases.append([n, hero, false])
	_next()


func _next() -> void:
	if _stage:
		_stage.queue_free()
		_stage = null
	get_tree().paused = false
	if mode == "smoke":
		if _cases.is_empty():
			_finish()
			return
		_case = _cases.pop_front()
	else:
		if Meta.highest_cleared >= target or _total >= max_runs:
			_finish()
			return
		_case = [Meta.next_stage(), "warrior", true]
	seed(1000 + _total * 7919)
	_stage = Stage.new()
	_stage.stage_number = _case[0]
	_stage.starting_hero = _case[1]
	_stage.use_meta = _case[2]
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
		_stage.choose(_stage.pick_kind(), _stage.pick_offers()[0])
		return
	_time += delta
	_peak = maxf(_peak, _stage.wyrm.danger())
	if _time > 900.0:
		push_error("Stage did not finish in 900s: %s" % [_case])
		_failed = true
		_stage.retreat()
		return
	var t := _pick_target()
	if t:
		_stage._point(t.pos)


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
	_total += 1
	_runs_on_stage += 1
	if _stage.won:
		_wins += 1
	var r := _stage.run
	print("%-6s stage %3d %-8s %-4s t=%5.1fs left=%2d peak=%.2f party=%d skills=%2d dmg=%s gold+%s" % [
		"run%d" % _total, _case[0], _case[1], "WIN" if _stage.won else "LOSS", _time,
		_stage.wyrm.segments.size(), _peak, r.party.size(), _stage.skills_learned,
		Meta.fmt(_stage.wyrm.damage_dealt), Meta.fmt(_stage.reward.get("total", 0.0))])
	if mode == "career":
		if _stage.won and _stage.reward.first_clear:
			print("   -> cleared stage %d after %d run(s)" % [_case[0], _runs_on_stage])
			_runs_on_stage = 0
		_spend_gold()


## Greedy: rank up any hero with enough shards, then keep buying the
## cheapest affordable gold upgrade.
func _spend_gold() -> void:
	for id in Data.HEROES:
		while Meta.rank_up(id):
			pass
	while true:
		var best_cost := INF
		var best: Callable
		for id in Data.HEROES:
			var c := Meta.hero_cost(id)
			if c < best_cost:
				best_cost = c
				best = Meta.buy_hero_level.bind(id)
		for id in Meta.ARMORY:
			if Meta.armory_maxed(id):
				continue
			var c := Meta.armory_cost(id)
			if c < best_cost:
				best_cost = c
				best = Meta.buy_armory.bind(id)
		if best_cost > Meta.gold:
			return
		best.call()


func _finish() -> void:
	print("WINS %d / %d  (%.0fs real)" % [_wins, _total, (Time.get_ticks_msec() - _start_ms) / 1000.0])
	if mode == "career":
		print("Reached stage %d. Hero levels: %s  Armory: %s" % [Meta.highest_cleared, Meta.hero_levels, Meta.armory])
	get_tree().quit(1 if _failed else 0)
