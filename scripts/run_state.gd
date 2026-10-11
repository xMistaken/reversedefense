class_name RunState
extends RefCounted
## Everything that belongs to one run: party, skill ranks, refreshes, gold.
## Permanent upgrades from Meta are folded into hero stats here.

const OFFER_COUNT := 3
const BASE_REFRESHES := 2

var party: Array[String] = []
var ranks: Dictionary = {}  # skill id -> rank
var refreshes := BASE_REFRESHES
var gold := 0.0
var use_meta := true        # tests can run without permanent upgrades


func _init(starting_hero: String, with_meta := true) -> void:
	use_meta = with_meta
	party.append(starting_hero)
	if use_meta:
		refreshes += Meta.bonus_refreshes()


## True if this hero's ultimate (rank 6) is unlocked.
func has_ultimate(hero_id: String) -> bool:
	return use_meta and Meta.hero_rank(hero_id) >= Data.HERO_MAX_RANK


func has_hero(hero_id: String) -> bool:
	return party.has(hero_id)


func rank_of(skill_id: String) -> int:
	return ranks.get(skill_id, 0)


## Total ranks a hero has in its own skills (gates its legendary).
func hero_ranks(hero_id: String) -> int:
	var total := 0
	for skill in Data.SKILLS:
		if skill.hero == hero_id and not skill.get("legendary", false):
			total += rank_of(skill.id)
	return total


## Final stats for a hero: base -> hero overrides -> permanent upgrades -> skill ranks.
func hero_stats(hero_id: String) -> Dictionary:
	var s: Dictionary = Data.BASE_STATS.duplicate()
	s.merge(Data.HEROES[hero_id].stats, true)
	if use_meta:
		s.power = Meta.hero_damage_mult(hero_id) * Meta.damage_mult()
		s.cooldown *= Meta.cooldown_mult()
		s.crit_mult = Meta.crit_mult()
		var perks: Array = Data.HERO_RANKS[hero_id]
		for r in range(1, Meta.hero_rank(hero_id)):
			for m in perks[r].get("mods", []):
				_apply_mod(s, m)
	for skill in Data.SKILLS:
		var r := rank_of(skill.id)
		if r == 0:
			continue
		var applies: bool = skill.target == "party" or (skill.target == "self" and skill.hero == hero_id)
		if not applies:
			continue
		for i in r:
			for m in skill.mods:
				_apply_mod(s, m)
	return s


## Run-wide multipliers (e.g. "wyrm_speed"), starting from 1.0.
func global_stat(stat: String) -> float:
	var s := {stat: 1.0}
	for skill in Data.SKILLS:
		if skill.target != "global":
			continue
		for i in rank_of(skill.id):
			for m in skill.mods:
				if m[0] == stat:
					_apply_mod(s, m)
	return s[stat]


## Up to 3 random heroes not already in the party (no duplicates).
## Each offer: {"id": hero_id}
func hero_offers() -> Array[Dictionary]:
	var pool: Array[String] = []
	for id in Data.HEROES:
		if not party.has(id):
			pool.append(id)
	pool.shuffle()
	var out: Array[Dictionary] = []
	for id in pool.slice(0, OFFER_COUNT):
		out.append({"id": id})
	return out


func skill_available(skill: Dictionary) -> bool:
	if skill.hero != "" and not party.has(skill.hero):
		return false
	if rank_of(skill.id) >= Data.max_rank(skill):
		return false
	if skill.get("legendary", false) and hero_ranks(skill.hero) < Data.LEGENDARY_REQUIRES:
		return false
	return true


## Up to 3 random skills usable by the current party and not yet maxed.
## Unlocked legendaries are always offered. Each offer: {"id", "ranks", "rarity"}
func skill_offers() -> Array[Dictionary]:
	var legendary: Array[String] = []
	var pool: Array[String] = []
	for skill in Data.SKILLS:
		if not skill_available(skill):
			continue
		if skill.get("legendary", false):
			legendary.append(skill.id)
		else:
			pool.append(skill.id)
	legendary.shuffle()
	pool.shuffle()
	var out: Array[Dictionary] = []
	for id in legendary.slice(0, 1):
		out.append({"id": id, "ranks": 1, "rarity": "Legendary"})
	for id in pool:
		if out.size() >= OFFER_COUNT:
			break
		out.append(_roll_rarity(id))
	return out


func _roll_rarity(id: String) -> Dictionary:
	var total := 0.0
	for r in Data.RARITIES:
		total += r.weight
	var roll := randf() * total
	var pick: Dictionary = Data.RARITIES[0]
	for r in Data.RARITIES:
		roll -= r.weight
		if roll <= 0.0:
			pick = r
			break
	var room := Data.max_rank(Data.get_skill(id)) - rank_of(id)
	return {"id": id, "ranks": mini(pick.ranks, room), "rarity": pick.name}


func take_hero(hero_id: String) -> void:
	if not party.has(hero_id):
		party.append(hero_id)


func take_skill(skill_id: String, count := 1) -> void:
	var skill := Data.get_skill(skill_id)
	ranks[skill_id] = mini(rank_of(skill_id) + count, Data.max_rank(skill))


func _apply_mod(s: Dictionary, m: Array) -> void:
	var stat: String = m[0]
	match m[1]:
		"add":
			s[stat] += m[2]
		"mul":
			s[stat] *= m[2]
