class_name StageConfig
extends RefCounted
## Procedural definition of stages 1..100. Difficulty ramps exponentially in
## HP (faster than gold income grows), so pushing deep needs farmed upgrades.

static var hp_growth_per_stage := 1.2
const BOSS_EVERY := 10
const SKILL_CHESTS := 12
const HERO_CHESTS := 5

var number := 1
var theme := "ember"
var mode := 0              # Stage.Mode
var boss := false
var title := ""
var segment_count := 45
var base_hp := 50.0
var hp_growth := 0.06      # within the chain: section i has base_hp * (1 + i * hp_growth)
var speed := 55.0
var bone_chance := 0.15
var mending_chance := 0.08
var gilded_chance := 0.05
var track_kind := ""
var track_seed := 0
var speed_pattern := "steady"  # "steady", "pulse" (speeds up and slows down) or "surge" (sudden lunges)

const CIRCLE_TRACKS := ["spiral", "petals", "meander", "coil"]
const WAGON_TRACKS := ["serpentine", "wavy", "zigzag", "curly"]
const SPEED_PATTERNS := ["steady", "pulse", "surge"]
## Track lengths vary by shape; speed is scaled so a wyrm takes about as long
## to cross any of them.
const REFERENCE_LENGTH := 4200.0


static func make(n: int) -> StageConfig:
	var c := StageConfig.new()
	c.number = n
	c.boss = n % BOSS_EVERY == 0
	c.mode = 0 if n % 2 == 1 else 1
	c.theme = Data.THEME_ORDER[((n - 1) / 10) % Data.THEME_ORDER.size()]
	# Regular sections plus the chest orbs embedded among them.
	c.segment_count = mini(22 + n / 4, 40) + (6 if c.boss else 0) + HERO_CHESTS + SKILL_CHESTS
	c.base_hp = 140.0 * pow(hp_growth_per_stage, n - 1) * (1.25 if c.boss else 1.0)
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
	c.title = ("Stage %d - BOSS" % n) if c.boss else ("Stage %d" % n)
	return c


## Head first. Hero chests early so the party fills out. A fixed number of
## skill chests (plus Treasure Hunter's bonus) spread evenly along the chain,
## so longer late-game wyrms add HP, not extra power.
func segment_types(bonus_skill_chests: int) -> Array[String]:
	var types: Array[String] = []
	var hero_slots := [2, 6, 11, 17, 24]
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


## Builds this stage's hidden path. It ends at the wall: a ring of radius
## `wall_radius` around `center` (circle stages) or the line `wall_y` (wagon).
func build_track(view: Vector2, center: Vector2, wall_y: float, wall_radius: float) -> Curve2D:
	TrackBuilder.view = view
	var c := _shape(view, center, wall_y, wall_radius)
	var last := c.get_point_position(c.point_count - 1)
	if mode == 0:
		c.add_point(center + (last - center).normalized() * (wall_radius + 60.0))
	else:
		c.add_point(Vector2(last.x, wall_y - 50.0))
	return c


func _shape(view: Vector2, center: Vector2, wall_y: float, wall_radius: float) -> Curve2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = track_seed
	var cw := rng.randf() < 0.5
	var start := rng.randf_range(-PI * 0.85, -PI * 0.15)  # enter from the top half
	var r_inner := wall_radius + 95.0
	var left := 110.0
	var right := view.x - 110.0
	var top := 300.0
	var bottom := wall_y - 170.0
	match track_kind:
		"spiral":
			return TrackBuilder.spiral(center, r_inner, start, cw, rng.randf_range(1.0, 1.15),
				rng.randf_range(30.0, 50.0), float(rng.randi_range(6, 9)))
		"petals":
			return TrackBuilder.petals(center, r_inner, start, cw, rng.randf_range(1.0, 1.2), rng.randi_range(5, 7))
		"meander":
			return TrackBuilder.meander(center, r_inner, rng.randf() < 0.5, rng.randi_range(2, 3), 2)
		"coil":
			return TrackBuilder.coil(center, r_inner, start, cw, rng.randi_range(7, 10), rng.randf_range(80.0, 100.0))
		"serpentine":
			return TrackBuilder.serpentine(left, right, top, bottom, TrackBuilder.ROW_GAP, rng.randf() < 0.5)
		"wavy":
			return TrackBuilder.serpentine(left, right, top, bottom, 240.0, rng.randf() < 0.5,
				rng.randf_range(35.0, 50.0), rng.randi_range(3, 4))
		"zigzag":
			return TrackBuilder.zigzag(left, right, top, bottom, rng.randi_range(6, 8), rng.randf() < 0.5)
		"curly":
			return TrackBuilder.curly(left, right, top, bottom, 4, rng.randi_range(2, 3), rng.randf_range(80.0, 95.0), rng.randf() < 0.5)
	return TrackBuilder.spiral(center, r_inner, start, cw, 1.0, 40.0, 7.0)
