extends Node
## Persistent roguelite progression: gold, stage progress, hero levels and
## armory upgrades. Saved to disk after every run and purchase.

const SAVE_PATH := "user://save.json"
const STAGE_COUNT := 100

## Gold income per stage grows by this factor; stage HP grows faster
## (see StageConfig), so later stages need upgrades bought with farmed gold.
var gold_growth := 1.09
var cost_scale := 1.0             # multiplies every upgrade cost

const HERO_LEVEL_DAMAGE := 1.15   # damage multiplier per hero level
const HERO_COST_BASE := 120.0
const HERO_COST_GROWTH := 1.17

var ARMORY := {
	"might": {"name": "Might", "desc": "+8% damage for every hero",
		"cost": 200.0, "growth": 1.21, "max": 0},
	"haste": {"name": "Haste", "desc": "+3% attack speed",
		"cost": 320.0, "growth": 1.3, "max": 25},
	"ferocity": {"name": "Ferocity", "desc": "+25% critical hit damage",
		"cost": 280.0, "growth": 1.24, "max": 0},
	"fortune": {"name": "Fortune", "desc": "+10% gold earned",
		"cost": 240.0, "growth": 1.35, "max": 10},
	"insight": {"name": "Insight", "desc": "+1 refresh at the start of each run",
		"cost": 600.0, "growth": 2.2, "max": 5},
	"treasure": {"name": "Treasure Hunter", "desc": "+2 extra skill chests per stage",
		"cost": 800.0, "growth": 1.9, "max": 8},
	"fortify": {"name": "Fortify", "desc": "+25% wall HP",
		"cost": 400.0, "growth": 1.55, "max": 12},
	"head_start": {"name": "Head Start", "desc": "Start each run with +1 random skill",
		"cost": 1200.0, "growth": 2.4, "max": 5},
}

var gold := 0.0
var highest_cleared := 0
var selected_hero := "warrior"
var hero_levels: Dictionary = {}  # hero id -> level (1+)
var armory: Dictionary = {}       # upgrade id -> level (0+)
var persist := true               # tests turn this off


func _ready() -> void:
	load_game()


# --- Levels & effects -------------------------------------------------------

func hero_level(hero_id: String) -> int:
	return hero_levels.get(hero_id, 1)


func armory_level(id: String) -> int:
	return armory.get(id, 0)


func hero_damage_mult(hero_id: String) -> float:
	return pow(HERO_LEVEL_DAMAGE, hero_level(hero_id) - 1)


func damage_mult() -> float:
	return pow(1.08, armory_level("might"))


func cooldown_mult() -> float:
	return 1.0 / (1.0 + 0.03 * armory_level("haste"))


func crit_mult() -> float:
	return 2.0 + 0.25 * armory_level("ferocity")


func gold_mult() -> float:
	return 1.0 + 0.1 * armory_level("fortune")


func wall_mult() -> float:
	return 1.0 + 0.25 * armory_level("fortify")


func bonus_refreshes() -> int:
	return armory_level("insight")


func bonus_skill_chests() -> int:
	return 2 * armory_level("treasure")


func head_start_skills() -> int:
	return armory_level("head_start")


# --- Costs & purchases ------------------------------------------------------

func hero_cost(hero_id: String) -> float:
	return round(cost_scale * HERO_COST_BASE * pow(HERO_COST_GROWTH, hero_level(hero_id) - 1))


func armory_cost(id: String) -> float:
	var a: Dictionary = ARMORY[id]
	return round(cost_scale * a.cost * pow(a.growth, armory_level(id)))


func armory_maxed(id: String) -> bool:
	var m: int = ARMORY[id].max
	return m > 0 and armory_level(id) >= m


func buy_hero_level(hero_id: String) -> bool:
	var c := hero_cost(hero_id)
	if gold < c:
		return false
	gold -= c
	hero_levels[hero_id] = hero_level(hero_id) + 1
	save_game()
	return true


func buy_armory(id: String) -> bool:
	var c := armory_cost(id)
	if gold < c or armory_maxed(id):
		return false
	gold -= c
	armory[id] = armory_level(id) + 1
	save_game()
	return true


# --- Stage rewards ----------------------------------------------------------

func is_unlocked(stage: int) -> bool:
	return stage <= mini(highest_cleared + 1, STAGE_COUNT)


func next_stage() -> int:
	return mini(highest_cleared + 1, STAGE_COUNT)


func gold_per_segment(stage: int) -> float:
	return 2.0 * pow(gold_growth, stage - 1) * gold_mult()


func clear_bonus(stage: int, first_clear: bool) -> float:
	var b := 40.0 * pow(gold_growth, stage - 1) * gold_mult()
	return b * (3.0 if first_clear else 1.0)


## Called by the stage when a run ends. Returns the gold awarded.
func finish_run(stage: int, won: bool, run_gold: float) -> Dictionary:
	var first := won and stage > highest_cleared
	var bonus := clear_bonus(stage, first) if won else 0.0
	gold += run_gold + bonus
	if won:
		highest_cleared = maxi(highest_cleared, stage)
	save_game()
	return {"bonus": bonus, "first_clear": first, "total": run_gold + bonus}


# --- Save / load ------------------------------------------------------------

func reset() -> void:
	gold = 0.0
	highest_cleared = 0
	selected_hero = "warrior"
	hero_levels = {}
	armory = {}


func save_game() -> void:
	if not persist:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"gold": gold, "highest_cleared": highest_cleared, "selected_hero": selected_hero,
		"hero_levels": hero_levels, "armory": armory,
	}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	gold = data.get("gold", 0.0)
	highest_cleared = int(data.get("highest_cleared", 0))
	selected_hero = data.get("selected_hero", "warrior")
	if not Data.HEROES.has(selected_hero):
		selected_hero = "warrior"
	for k in data.get("hero_levels", {}):
		hero_levels[k] = int(data.hero_levels[k])
	for k in data.get("armory", {}):
		armory[k] = int(data.armory[k])


# --- Formatting -------------------------------------------------------------

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


## 1234 -> "1.23K", 5600000 -> "5.60M"
static func fmt(n: float) -> String:
	if n < 1000.0:
		return str(int(n))
	var tier := 0
	while n >= 1000.0 and tier < SUFFIXES.size() - 1:
		n /= 1000.0
		tier += 1
	var digits := 2 if n < 10.0 else (1 if n < 100.0 else 0)
	return String.num(n, digits) + SUFFIXES[tier]
