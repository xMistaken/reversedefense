extends Node
## Game data tables: heroes, skills and wyrm segment types.
## Balance the game by editing the numbers here.

## Every hero starts from these stats, then applies its own overrides.
var BASE_STATS := {
	"damage": 10.0,        # damage per projectile hit
	"power": 1.0,          # permanent-upgrade multiplier on hit and DoT damage
	"cooldown": 0.5,       # seconds between volleys
	"speed": 1400.0,       # projectile speed (px/s)
	"pierce": 1,           # segments a projectile can hit before it's spent
	"count": 1,            # projectiles per volley
	"spread": 0.15,        # radians between projectiles in a volley
	"splash": 0.0,         # radius of splash damage (50% damage)
	"dot": 0.0,            # damage per second applied for 3s on hit
	"dot_spread": 0,       # how many neighbouring segments the DoT also infects
	"bounce": 0,           # times a spent projectile redirects to a new segment
	"crit": 0.05,          # crit chance
	"crit_mult": 2.0,      # crit damage multiplier (raised by Ferocity)
	"slow": 0.0,           # seconds the whole wyrm is slowed on hit
	"execute": 0.0,        # bonus damage multiplier vs segments under 30% HP
	"poison_chance": 0.0,  # chance a hit poisons (DoT of 60% hit damage per second)
	"freeze_chance": 0.0,  # chance a hit freezes the whole wyrm for 1s
	"push": 0.0,           # px the wyrm is shoved back by the hero's ability
	"push_interval": 0.0,  # seconds between shoves (0 = no ability)
	"size": 12.0,          # projectile radius
}

var HEROES := {
	"warrior": {
		"name": "Warrior", "color": Color(0.82, 0.32, 0.24),
		"blurb": "Thrown axes that cut through 2 segments.",
		"shot": {"sprite": "axe", "spin": 14.0, "scale": 0.36},
		"stats": {"damage": 16.0, "cooldown": 0.6, "speed": 1200.0, "pierce": 2, "size": 16.0},
	},
	"mage": {
		"name": "Mage", "color": Color(0.35, 0.6, 1.0),
		"blurb": "Slow fireballs that explode on impact.",
		"shot": {"sprite": "fire", "spin": 3.0, "scale": 0.4, "halo": Color(1.0, 0.5, 0.15)},
		"stats": {"damage": 22.0, "cooldown": 0.95, "speed": 950.0, "splash": 110.0, "size": 18.0},
	},
	"hunter": {
		"name": "Hunter", "color": Color(0.45, 0.8, 0.3),
		"blurb": "Rapid-fire arrows.",
		"shot": {"sprite": "arrow", "orient": PI / 2, "scale": 0.42},
		"stats": {"damage": 6.0, "cooldown": 0.18, "speed": 1900.0, "size": 9.0},
	},
	"priest": {
		"name": "Priest", "color": Color(0.98, 0.95, 0.8),
		"blurb": "Holy bolts. Every few seconds, shoves the wyrm back.",
		"shot": {"sprite": "holy", "orient": PI / 4, "scale": 0.36, "halo": Color(1.0, 0.95, 0.55)},
		"stats": {"damage": 11.0, "cooldown": 0.55, "push": 45.0, "push_interval": 7.0},
	},
	"rogue": {
		"name": "Rogue", "color": Color(1.0, 0.93, 0.35),
		"blurb": "Pairs of daggers with a high crit chance.",
		"shot": {"sprite": "dagger", "orient": PI / 2, "scale": 0.38},
		"stats": {"damage": 8.0, "cooldown": 0.45, "count": 2, "spread": 0.18, "crit": 0.25, "size": 10.0},
	},
	"warlock": {
		"name": "Warlock", "color": Color(0.65, 0.3, 0.9),
		"blurb": "Shadow bolts that leave a burning curse.",
		"shot": {"sprite": "shadow", "spin": 7.0, "scale": 0.34, "halo": Color(0.6, 0.3, 1.0)},
		"stats": {"damage": 7.0, "cooldown": 0.7, "dot": 8.0, "size": 14.0},
	},
}

## target: "self" = only the owning hero, "party" = every hero, "global" = run-wide value.
## mods: [stat, "add" | "mul", value], applied once per rank.
## Permanent hero ranks (LV1-6), bought with hero shards between runs.
## LV1 describes the hero's innate attack; LV2-5 are passive perks (mods apply
## like skill mods); LV6 is the hero's ultimate, a periodic screen-wide attack.
var HERO_RANKS := {
	"warrior": [
		{"name": "Cleaving Axes", "desc": "Thrown axes cut through 2 sections."},
		{"name": "Heavy Swing", "desc": "Axes deal +40% damage.", "mods": [["damage", "mul", 1.4]]},
		{"name": "Brutality", "desc": "Crit rate +20%, crit damage +50%.", "mods": [["crit", "add", 0.2], ["crit_mult", "mul", 1.5]]},
		{"name": "Ricochet", "desc": "Axes bounce to 1 more section.", "mods": [["bounce", "add", 1]]},
		{"name": "Warlord", "desc": "All damage +100%.", "mods": [["damage", "mul", 2.0]]},
		{"name": "EARTHSHATTER", "desc": "Every 10s the Warrior slams the ground: every section on screen takes 400% damage.", "ult": true},
	],
	"mage": [
		{"name": "Fireball", "desc": "Fireballs explode, splashing nearby sections."},
		{"name": "Inferno", "desc": "Blast radius +50%.", "mods": [["splash", "mul", 1.5]]},
		{"name": "Ignite", "desc": "Fireballs burn for 8 damage per second.", "mods": [["dot", "add", 8.0]]},
		{"name": "Wildfire", "desc": "Fireballs explode 30% bigger.", "mods": [["splash", "mul", 1.3]]},
		{"name": "Archmage", "desc": "All damage +100%.", "mods": [["damage", "mul", 2.0]]},
		{"name": "ARMAGEDDON", "desc": "Every 12s, 8 meteors crash into random sections for 600% damage each, with a huge blast.", "ult": true},
	],
	"hunter": [
		{"name": "Rapid Shot", "desc": "Fires arrows very quickly."},
		{"name": "Eagle Eye", "desc": "+20% crit chance.", "mods": [["crit", "add", 0.2]]},
		{"name": "Piercing Arrows", "desc": "Arrows pierce 1 more section.", "mods": [["pierce", "add", 1]]},
		{"name": "Quickdraw", "desc": "Attack speed +30%.", "mods": [["cooldown", "mul", 0.77]]},
		{"name": "Marksman", "desc": "All damage +100%.", "mods": [["damage", "mul", 2.0]]},
		{"name": "RAIN OF ARROWS", "desc": "Every 8s, arrows rain on the whole screen: every section takes 250% damage.", "ult": true},
	],
	"priest": [
		{"name": "Holy Shove", "desc": "Holy bolts, and a periodic shove that pushes the wyrm back."},
		{"name": "Mighty Shove", "desc": "Shoves push 40px further.", "mods": [["push", "add", 40.0]]},
		{"name": "Smite", "desc": "Holy bolts bounce to 1 more section.", "mods": [["bounce", "add", 1]]},
		{"name": "Zeal", "desc": "Attack speed +25%.", "mods": [["cooldown", "mul", 0.8]]},
		{"name": "High Priest", "desc": "All damage +100%.", "mods": [["damage", "mul", 2.0]]},
		{"name": "DIVINE JUDGMENT", "desc": "Every 14s, holy light smites every section on screen for 300% damage and repairs the wall by 15%.", "ult": true},
	],
	"rogue": [
		{"name": "Twin Daggers", "desc": "Throws 2 daggers with a high crit chance."},
		{"name": "Hidden Blades", "desc": "Daggers deal +40% damage.", "mods": [["damage", "mul", 1.4]]},
		{"name": "Assassinate", "desc": "Crit rate +20%, crit damage +55%.", "mods": [["crit", "add", 0.2], ["crit_mult", "mul", 1.55]]},
		{"name": "Venom", "desc": "Daggers poison for 6 damage per second.", "mods": [["dot", "add", 6.0]]},
		{"name": "Master Thief", "desc": "All damage +100%.", "mods": [["damage", "mul", 2.0]]},
		{"name": "SHADOW FLURRY", "desc": "Every 9s, 14 shadow strikes hit random sections; every strike is a critical hit.", "ult": true},
	],
	"warlock": [
		{"name": "Curse", "desc": "Shadow bolts leave a burning curse."},
		{"name": "Spreading Curse", "desc": "Curses spread to 1 more section on each side.", "mods": [["dot_spread", "add", 1]]},
		{"name": "Shadow Mastery", "desc": "Bolts deal +40% damage.", "mods": [["damage", "mul", 1.4]]},
		{"name": "Malice", "desc": "Curse damage +100%.", "mods": [["dot", "mul", 2.0]]},
		{"name": "Dark Lord", "desc": "All damage +100%.", "mods": [["damage", "mul", 2.0], ["dot", "mul", 2.0]]},
		{"name": "DOOM", "desc": "Every 12s, every section on screen is cursed and takes 350% damage.", "ult": true},
	],
}
const HERO_MAX_RANK := 6
## Ultimate timing and power (damage is a multiple of the hero's hit damage).
var ULTIMATES := {
	"warrior": {"interval": 10.0, "mult": 4.0, "color": Color(1.0, 0.55, 0.25)},
	"mage": {"interval": 12.0, "mult": 6.0, "hits": 8, "color": Color(1.0, 0.45, 0.1)},
	"hunter": {"interval": 8.0, "mult": 2.5, "color": Color(0.5, 1.0, 0.4)},
	"priest": {"interval": 14.0, "mult": 3.0, "repair": 0.15, "color": Color(1.0, 0.95, 0.6)},
	"rogue": {"interval": 9.0, "mult": 1.0, "hits": 14, "crit": true, "color": Color(0.75, 0.5, 1.0)},
	"warlock": {"interval": 12.0, "mult": 3.5, "curse": true, "color": Color(0.7, 0.3, 1.0)},
}

## In-run skills. Each is a single pick with one effect; once taken it leaves
## the pool. target: "self" = only the owning hero, "party" = every hero,
## "global" = run-wide value. mods: [stat, "add" | "mul", value].
var SKILLS := [
	# Party-wide (always offered)
	{"id": "sharpen", "name": "Sharpened Steel", "hero": "", "target": "party",
		"desc": "All heroes deal +30% damage.", "mods": [["damage", "mul", 1.3]]},
	{"id": "drums", "name": "War Drums", "hero": "", "target": "party",
		"desc": "All heroes attack 25% faster.", "mods": [["cooldown", "mul", 0.8]]},
	{"id": "keen", "name": "Keen Eye", "hero": "", "target": "party",
		"desc": "+15% crit chance for all heroes.", "mods": [["crit", "add", 0.15]]},
	{"id": "brutal", "name": "Brutal Strikes", "hero": "", "target": "party",
		"desc": "Critical hits deal +100% damage.", "mods": [["crit_mult", "add", 1.0]]},
	{"id": "venom", "name": "Venom Coating", "hero": "", "target": "party",
		"desc": "All attacks have a 20% chance to poison.", "mods": [["poison_chance", "add", 0.2]]},
	{"id": "chill", "name": "Chilling Aura", "hero": "", "target": "global",
		"desc": "The wyrm moves 15% slower.", "mods": [["wyrm_speed", "mul", 0.85]]},
	# Warrior
	{"id": "twin_axes", "name": "Twin Axes", "hero": "warrior", "target": "self",
		"desc": "Throws 1 more axe.", "mods": [["count", "add", 1]]},
	{"id": "ricochet", "name": "Shield Ricochet", "hero": "warrior", "target": "self",
		"desc": "Axes bounce to 1 more section.", "mods": [["bounce", "add", 1]]},
	{"id": "execute", "name": "Execute", "hero": "warrior", "target": "self",
		"desc": "+100% damage to sections below 30% HP.", "mods": [["execute", "add", 1.0]]},
	{"id": "heavy_axes", "name": "Heavy Axes", "hero": "warrior", "target": "self",
		"desc": "Axes pierce 1 more section.", "mods": [["pierce", "add", 1]]},
	# Mage
	{"id": "pyroblast", "name": "Pyroblast", "hero": "mage", "target": "self",
		"desc": "Fireball explosions are 50% bigger.", "mods": [["splash", "mul", 1.5]]},
	{"id": "frost", "name": "Frost Nova", "hero": "mage", "target": "self",
		"desc": "25% chance to freeze the wyrm for 1 second.", "mods": [["freeze_chance", "add", 0.25]]},
	{"id": "ignite", "name": "Ignite", "hero": "mage", "target": "self",
		"desc": "Fireballs set sections on fire.", "mods": [["dot", "add", 12.0]]},
	{"id": "arcane", "name": "Arcane Power", "hero": "mage", "target": "self",
		"desc": "Fireballs deal +60% damage.", "mods": [["damage", "mul", 1.6]]},
	# Hunter
	{"id": "multishot", "name": "Multishot", "hero": "hunter", "target": "self",
		"desc": "Fires 2 more arrows.", "mods": [["count", "add", 2]]},
	{"id": "piercing", "name": "Piercing Shot", "hero": "hunter", "target": "self",
		"desc": "Arrows pierce 2 more sections.", "mods": [["pierce", "add", 2]]},
	{"id": "rapid", "name": "Rapid Fire", "hero": "hunter", "target": "self",
		"desc": "Attacks 40% faster.", "mods": [["cooldown", "mul", 0.6]]},
	{"id": "sting", "name": "Serpent Sting", "hero": "hunter", "target": "self",
		"desc": "35% chance to poison.", "mods": [["poison_chance", "add", 0.35]]},
	# Priest
	{"id": "shield", "name": "Divine Shield", "hero": "priest", "target": "self",
		"desc": "Shoves push the wyrm twice as far.", "mods": [["push", "mul", 2.0]]},
	{"id": "smite", "name": "Smite", "hero": "priest", "target": "self",
		"desc": "Holy bolts bounce to 2 more sections.", "mods": [["bounce", "add", 2]]},
	{"id": "holy_nova", "name": "Holy Nova", "hero": "priest", "target": "self",
		"desc": "Holy bolts explode on impact.", "mods": [["splash", "add", 100.0]]},
	{"id": "blessing", "name": "Blessing of Haste", "hero": "priest", "target": "party",
		"desc": "All heroes attack 15% faster.", "mods": [["cooldown", "mul", 0.87]]},
	# Rogue
	{"id": "poison", "name": "Poisoned Blades", "hero": "rogue", "target": "self",
		"desc": "50% chance to poison.", "mods": [["poison_chance", "add", 0.5]]},
	{"id": "fan", "name": "Fan of Knives", "hero": "rogue", "target": "self",
		"desc": "Throws 1 more dagger.", "mods": [["count", "add", 1]]},
	{"id": "cold_blood", "name": "Cold Blood", "hero": "rogue", "target": "self",
		"desc": "+30% crit chance.", "mods": [["crit", "add", 0.3]]},
	{"id": "backstab", "name": "Backstab", "hero": "rogue", "target": "self",
		"desc": "Critical hits deal +150% damage.", "mods": [["crit_mult", "add", 1.5]]},
	# Warlock
	{"id": "corruption", "name": "Corruption", "hero": "warlock", "target": "self",
		"desc": "Curses spread to neighbouring sections.", "mods": [["dot_spread", "add", 1]]},
	{"id": "shadow_bolt", "name": "Shadow Lance", "hero": "warlock", "target": "self",
		"desc": "Bolts pierce 1 more section.", "mods": [["pierce", "add", 1]]},
	{"id": "agony", "name": "Agony", "hero": "warlock", "target": "self",
		"desc": "Curses deal double damage.", "mods": [["dot", "mul", 2.0]]},
	{"id": "soul_fire", "name": "Soul Fire", "hero": "warlock", "target": "self",
		"desc": "Bolts deal +80% damage.", "mods": [["damage", "mul", 1.8]]},
	# Legendaries: one per hero, offered once you've taken 2 of that hero's skills.
	{"id": "bladestorm", "name": "BLADESTORM", "hero": "warrior", "target": "self", "legendary": true,
		"desc": "Axes deal double damage and pierce 3 more sections.", "mods": [["damage", "mul", 2.0], ["pierce", "add", 3]]},
	{"id": "meteor", "name": "METEOR", "hero": "mage", "target": "self", "legendary": true,
		"desc": "Fireballs become meteors: triple damage, double explosion size.", "mods": [["splash", "mul", 2.0], ["damage", "mul", 3.0]]},
	{"id": "volley_storm", "name": "DEADEYE", "hero": "hunter", "target": "self", "legendary": true,
		"desc": "Attacks twice as fast and arrows bounce 2 more times.", "mods": [["cooldown", "mul", 0.5], ["bounce", "add", 2]]},
	{"id": "wrath", "name": "DIVINE WRATH", "hero": "priest", "target": "party", "legendary": true,
		"desc": "All heroes deal double damage.", "mods": [["damage", "mul", 2.0]]},
	{"id": "deathmark", "name": "DEATH MARK", "hero": "rogue", "target": "self", "legendary": true,
		"desc": "+30% crit chance and crits deal double damage.", "mods": [["crit", "add", 0.3], ["crit_mult", "mul", 2.0]]},
	{"id": "plague", "name": "PLAGUE", "hero": "warlock", "target": "self", "legendary": true,
		"desc": "Curses deal triple damage and spread 2 sections further.", "mods": [["dot", "mul", 3.0], ["dot_spread", "add", 2]]},
]

## A hero's legendary is offered once you've taken this many of that hero's skills.
const LEGENDARY_REQUIRES := 2
const LEGENDARY_COLOR := Color(1.0, 0.55, 0.1)
const SKILL_COLOR := Color(0.95, 0.92, 0.85)

## Every 10 stages the scenery and the wyrm change. `body`/`accent` tint the
## wyrm's plates.
var THEMES := {
	"ember": {"name": "Ember Canyon", "head": "dragon", "body": Color(1.0, 0.6, 0.52), "accent": Color(1.0, 0.75, 0.2)},
	"frost": {"name": "Frozen Halls", "head": "ice", "body": Color(0.92, 0.96, 1.0), "accent": Color(0.3, 0.85, 1.0)},
	"crypt": {"name": "Bone Crypt", "head": "bone", "body": Color(0.95, 0.9, 0.78), "accent": Color(0.55, 1.0, 0.45)},
	"abyss": {"name": "Abyssal Deep", "head": "serpent", "body": Color(0.45, 0.68, 1.0), "accent": Color(0.4, 1.0, 0.95)},
}
const THEME_ORDER := ["ember", "frost", "crypt", "abyss"]

## hp_mul scales the section's HP; armor reduces damage taken.
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
