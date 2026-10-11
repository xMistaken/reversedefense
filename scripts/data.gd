extends Node
## Game data tables: heroes, skills and wyrm segment types.
## Balance the game by editing the numbers here.

## Every hero starts from these stats, then applies its own overrides.
var BASE_STATS := {
	"damage": 10.0,        # damage per projectile hit
	"cooldown": 0.5,       # seconds between volleys
	"speed": 1400.0,       # projectile speed (px/s)
	"pierce": 1,           # segments a projectile can hit before it's spent
	"count": 1,            # projectiles per volley
	"spread": 0.15,        # radians between projectiles in a volley
	"splash": 0.0,         # radius of splash damage (50% damage)
	"dot": 0.0,            # damage per second applied for 3s on hit
	"dot_spread": 0,       # how many neighbouring segments the DoT also infects
	"bounce": 0,           # times a spent projectile redirects to a new segment
	"crit": 0.05,          # crit chance (crits deal 2x)
	"slow": 0.0,           # seconds the whole wyrm is slowed on hit
	"execute": 0.0,        # bonus damage multiplier vs segments under 30% HP
	"push": 0.0,           # px the wyrm is shoved back by the hero's ability
	"push_interval": 0.0,  # seconds between shoves (0 = no ability)
	"size": 12.0,          # projectile radius
}

var HEROES := {
	"warrior": {
		"name": "Warrior", "color": Color(0.82, 0.32, 0.24),
		"blurb": "Thrown axes that cut through 2 segments.",
		"stats": {"damage": 16.0, "cooldown": 0.6, "speed": 1200.0, "pierce": 2, "size": 16.0},
	},
	"mage": {
		"name": "Mage", "color": Color(0.35, 0.6, 1.0),
		"blurb": "Slow fireballs that explode on impact.",
		"stats": {"damage": 22.0, "cooldown": 0.95, "speed": 950.0, "splash": 110.0, "size": 18.0},
	},
	"hunter": {
		"name": "Hunter", "color": Color(0.45, 0.8, 0.3),
		"blurb": "Rapid-fire arrows.",
		"stats": {"damage": 6.0, "cooldown": 0.18, "speed": 1900.0, "size": 9.0},
	},
	"priest": {
		"name": "Priest", "color": Color(0.98, 0.95, 0.8),
		"blurb": "Holy bolts. Every few seconds, shoves the wyrm back.",
		"stats": {"damage": 11.0, "cooldown": 0.55, "push": 45.0, "push_interval": 7.0},
	},
	"rogue": {
		"name": "Rogue", "color": Color(1.0, 0.93, 0.35),
		"blurb": "Fans of 3 daggers with a high crit chance.",
		"stats": {"damage": 6.0, "cooldown": 0.5, "count": 3, "spread": 0.22, "crit": 0.25, "size": 10.0},
	},
	"warlock": {
		"name": "Warlock", "color": Color(0.65, 0.3, 0.9),
		"blurb": "Shadow bolts that leave a burning curse.",
		"stats": {"damage": 7.0, "cooldown": 0.7, "dot": 8.0, "size": 14.0},
	},
}

## target: "self" = only the owning hero, "party" = every hero, "global" = run-wide value.
## mods: [stat, "add" | "mul", value], applied once per rank.
var SKILLS := [
	# Party-wide (always offered)
	{"id": "sharpen", "name": "Sharpened Steel", "hero": "", "target": "party",
		"desc": "+15% damage for the whole party.", "mods": [["damage", "mul", 1.15]]},
	{"id": "drums", "name": "War Drums", "hero": "", "target": "party",
		"desc": "Party attacks 12% faster.", "mods": [["cooldown", "mul", 0.88]]},
	{"id": "keen", "name": "Keen Eye", "hero": "", "target": "party",
		"desc": "+8% crit chance for the party.", "mods": [["crit", "add", 0.08]]},
	{"id": "chill", "name": "Chilling Aura", "hero": "", "target": "global",
		"desc": "The wyrm crawls 8% slower.", "mods": [["wyrm_speed", "mul", 0.92]]},
	# Warrior
	{"id": "whirl", "name": "Whirling Axes", "hero": "warrior", "target": "self",
		"desc": "Warrior throws +1 axe.", "mods": [["count", "add", 1]]},
	{"id": "ricochet", "name": "Shield Ricochet", "hero": "warrior", "target": "self",
		"desc": "Axes bounce to +1 more segment.", "mods": [["bounce", "add", 1]]},
	{"id": "execute", "name": "Execute", "hero": "warrior", "target": "self",
		"desc": "+60% damage to segments under 30% HP.", "mods": [["execute", "add", 0.6]]},
	{"id": "heavy_axes", "name": "Heavy Axes", "hero": "warrior", "target": "self",
		"desc": "Axes pierce +1 segment and deal +15% damage.", "mods": [["pierce", "add", 1], ["damage", "mul", 1.15]]},
	# Mage
	{"id": "pyroblast", "name": "Pyroblast", "hero": "mage", "target": "self",
		"desc": "Fireballs: +25% blast radius, +20% damage.", "mods": [["splash", "mul", 1.25], ["damage", "mul", 1.2]]},
	{"id": "frost", "name": "Frost Nova", "hero": "mage", "target": "self",
		"desc": "Fireball hits slow the whole wyrm for 0.6s.", "mods": [["slow", "add", 0.6]]},
	{"id": "barrage", "name": "Arcane Barrage", "hero": "mage", "target": "self",
		"desc": "Mage casts +1 missile.", "mods": [["count", "add", 1]]},
	{"id": "ignite", "name": "Ignite", "hero": "mage", "target": "self",
		"desc": "Fireballs burn for 5 damage/s.", "mods": [["dot", "add", 5.0]]},
	# Hunter
	{"id": "multishot", "name": "Multishot", "hero": "hunter", "target": "self",
		"desc": "Hunter fires +2 arrows.", "mods": [["count", "add", 2]]},
	{"id": "piercing", "name": "Piercing Shot", "hero": "hunter", "target": "self",
		"desc": "Arrows pierce +1 segment.", "mods": [["pierce", "add", 1]]},
	{"id": "rapid", "name": "Rapid Fire", "hero": "hunter", "target": "self",
		"desc": "Hunter attacks 20% faster.", "mods": [["cooldown", "mul", 0.8]]},
	{"id": "sting", "name": "Serpent Sting", "hero": "hunter", "target": "self",
		"desc": "Arrows poison for 3 damage/s.", "mods": [["dot", "add", 3.0]]},
	# Priest
	{"id": "shield", "name": "Divine Shield", "hero": "priest", "target": "self",
		"desc": "Shoves push +35px further and come 15% sooner.", "mods": [["push", "add", 35.0], ["push_interval", "mul", 0.85]]},
	{"id": "smite", "name": "Smite", "hero": "priest", "target": "self",
		"desc": "Holy bolts: +40% damage and bounce once.", "mods": [["damage", "mul", 1.4], ["bounce", "add", 1]]},
	{"id": "holy_nova", "name": "Holy Nova", "hero": "priest", "target": "self",
		"desc": "Holy bolts burst for 70px splash.", "mods": [["splash", "add", 70.0]]},
	{"id": "blessing", "name": "Blessing of Haste", "hero": "priest", "target": "party",
		"desc": "Party attacks 8% faster.", "mods": [["cooldown", "mul", 0.92]]},
	# Rogue
	{"id": "poison", "name": "Poisoned Blades", "hero": "rogue", "target": "self",
		"desc": "Daggers poison for 4 damage/s.", "mods": [["dot", "add", 4.0]]},
	{"id": "fan", "name": "Fan of Knives", "hero": "rogue", "target": "self",
		"desc": "Rogue throws +2 daggers.", "mods": [["count", "add", 2]]},
	{"id": "cold_blood", "name": "Cold Blood", "hero": "rogue", "target": "self",
		"desc": "+15% crit chance for the Rogue.", "mods": [["crit", "add", 0.15]]},
	{"id": "deadly", "name": "Deadly Throw", "hero": "rogue", "target": "self",
		"desc": "Daggers deal +25% damage.", "mods": [["damage", "mul", 1.25]]},
	# Warlock
	{"id": "corruption", "name": "Corruption", "hero": "warlock", "target": "self",
		"desc": "Curses spread to +1 neighbouring segment each side.", "mods": [["dot_spread", "add", 1]]},
	{"id": "volley", "name": "Shadow Volley", "hero": "warlock", "target": "self",
		"desc": "Warlock fires +1 bolt.", "mods": [["count", "add", 1]]},
	{"id": "agony", "name": "Agony", "hero": "warlock", "target": "self",
		"desc": "Curses burn +5 damage/s.", "mods": [["dot", "add", 5.0]]},
	{"id": "soul_fire", "name": "Soul Fire", "hero": "warlock", "target": "self",
		"desc": "Shadow bolts deal +50% hit damage.", "mods": [["damage", "mul", 1.5]]},
]

const SKILL_MAX_RANK := 5

## hp_mul scales the segment's HP; armor reduces damage taken.
var SEGMENTS := {
	"flesh": {"color": Color(0.62, 0.24, 0.32), "hp_mul": 1.0, "armor": 0.0},
	"bone": {"color": Color(0.86, 0.83, 0.72), "hp_mul": 1.2, "armor": 0.5},
	"mending": {"color": Color(0.28, 0.68, 0.38), "hp_mul": 1.0, "armor": 0.0},
	"gilded": {"color": Color(0.95, 0.75, 0.2), "hp_mul": 1.4, "armor": 0.0},
	"hero_chest": {"color": Color(0.5, 0.25, 0.6), "hp_mul": 2.2, "armor": 0.0},
	"skill_chest": {"color": Color(0.22, 0.38, 0.7), "hp_mul": 1.8, "armor": 0.0},
}


func get_skill(id: String) -> Dictionary:
	for s in SKILLS:
		if s.id == id:
			return s
	return {}
