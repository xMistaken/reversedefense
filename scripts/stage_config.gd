class_name StageConfig
extends RefCounted
## Procedural definition of stages 1..100. Difficulty ramps exponentially in
## HP (faster than gold income grows), so pushing deep needs farmed upgrades.

static var hp_growth_per_stage := 1.19
const BOSS_EVERY := 10
const SKILL_CHESTS := 14

var number := 1
var mode := 0              # Stage.Mode
var boss := false
var title := ""
var segment_count := 45
var base_hp := 50.0
var hp_growth := 0.1       # within the chain: segment i has base_hp * (1 + i * hp_growth)
var speed := 55.0
var bone_chance := 0.15
var mending_chance := 0.08
var gilded_chance := 0.05
var track_kind := ""
var track_seed := 0
var speed_pattern := "steady"  # "steady", "pulse" (speeds up and slows down) or "surge" (sudden lunges)

const CIRCLE_TRACKS := ["spiral", "wobble_spiral", "square_spiral", "looping_spiral"]
const WAGON_TRACKS := ["serpentine", "sine_descent", "zigzag"]
const SPEED_PATTERNS := ["steady", "pulse", "surge"]
## Track lengths vary by shape; speed is scaled so a wyrm takes about as long
## to cross any of them.
const REFERENCE_LENGTH := 5200.0


static func make(n: int) -> StageConfig:
	var c := StageConfig.new()
	c.number = n
	c.boss = n % BOSS_EVERY == 0
	c.mode = 0 if n % 2 == 1 else 1
	c.segment_count = mini(45 + n / 2, 90) + (10 if c.boss else 0)
	c.base_hp = 50.0 * pow(hp_growth_per_stage, n - 1) * (1.4 if c.boss else 1.0)
	c.speed = 55.0 + minf(n, 60) * 0.3
	c.bone_chance = minf(0.12 + n * 0.003, 0.35)
	c.mending_chance = minf(0.06 + n * 0.0015, 0.18)
	# Each stage always gets the same layout, so it can be learned and farmed.
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7919 + 13
	c.track_seed = rng.randi()
	var tracks := CIRCLE_TRACKS if c.mode == 0 else WAGON_TRACKS
	c.track_kind = tracks[0] if n <= 2 else tracks[rng.randi() % tracks.size()]
	c.speed_pattern = "steady" if n <= 4 or c.boss else SPEED_PATTERNS[rng.randi() % SPEED_PATTERNS.size()]
	c.title = ("Stage %d  -  BOSS: Elder Wyrm" % n) if c.boss else ("Stage %d" % n)
	return c


## Head first. Hero chests early so the party fills out. A fixed number of
## skill chests (plus Treasure Hunter's bonus) spread evenly along the chain,
## so longer late-game wyrms add HP, not extra power.
func segment_types(bonus_skill_chests: int) -> Array[String]:
	var types: Array[String] = []
	var hero_slots := [3, 11, 21, 33, 46]
	var skill_slots := {}
	var span := segment_count - 2
	for k in SKILL_CHESTS:
		skill_slots[1 + int(float(k) * span / SKILL_CHESTS)] = true
	for i in segment_count:
		if i in hero_slots:
			types.append("hero_chest")
		elif skill_slots.has(i):
			types.append("skill_chest")
		else:
			var r := randf()
			if r < bone_chance:
				types.append("bone")
			elif r < bone_chance + mending_chance:
				types.append("mending")
			elif r < bone_chance + mending_chance + gilded_chance:
				types.append("gilded")
			else:
				types.append("flesh")
	# Treasure Hunter: convert random plain segments into skill chests.
	var plain: Array[int] = []
	for i in types.size():
		if types[i] == "flesh":
			plain.append(i)
	plain.shuffle()
	for i in mini(bonus_skill_chests, plain.size()):
		types[plain[i]] = "skill_chest"
	return types


## Builds this stage's hidden path. `center` is the party position for circle
## stages; `wagon_y` is the wagon's row for wagon stages.
func build_track(view: Vector2, center: Vector2, wagon_y: float) -> Curve2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = track_seed
	var cw := rng.randf() < 0.5
	var start := rng.randf_range(-PI * 0.85, -PI * 0.15)  # enter from the top half
	var r_outer := view.x * 0.46
	var left := 130.0
	var right := view.x - 130.0
	var top := 330.0
	var bottom := wagon_y - 380.0
	match track_kind:
		"spiral":
			return TrackBuilder.spiral(center, r_outer, 190.0, rng.randf_range(2.0, 2.6), start, cw)
		"wobble_spiral":
			return TrackBuilder.spiral(center, r_outer - 20.0, 200.0, rng.randf_range(2.0, 2.4), start, cw,
				rng.randf_range(18.0, 30.0), float(rng.randi_range(5, 9)))
		"square_spiral":
			return TrackBuilder.square_spiral(center, r_outer - 30.0, 175.0, rng.randf_range(2.0, 2.5), cw)
		"looping_spiral":
			return TrackBuilder.looping_spiral(center, r_outer - 30.0, 200.0, rng.randf_range(2.0, 2.4), start, cw)
		"serpentine":
			var rows := rng.randi_range(4, 6)
			return TrackBuilder.serpentine(left, right, top, (bottom - top) / (rows - 1), rows, rng.randf() < 0.5)
		"sine_descent":
			return TrackBuilder.sine_descent(left, right, top, bottom, rng.randf_range(3.0, 4.5))
		"columns":
			return TrackBuilder.columns(left, right, top, bottom, 5)
		"zigzag":
			return TrackBuilder.zigzag(left, right, top, bottom, rng.randi_range(4, 6))
	return TrackBuilder.spiral(center, r_outer, 190.0, 2.3, -PI / 2, true)
