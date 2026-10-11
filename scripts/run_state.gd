class_name RunState
extends RefCounted
## Everything that belongs to one run: party, skill ranks, refreshes, gold.

const OFFER_COUNT := 3

var party: Array[String] = []
var ranks: Dictionary = {}  # skill id -> rank
var refreshes := 2
var gold := 0


func _init(starting_hero: String) -> void:
	party.append(starting_hero)


func has_hero(hero_id: String) -> bool:
	return party.has(hero_id)


func rank_of(skill_id: String) -> int:
	return ranks.get(skill_id, 0)


## Final stats for a hero: base -> hero overrides -> skill ranks.
func hero_stats(hero_id: String) -> Dictionary:
	var s: Dictionary = Data.BASE_STATS.duplicate()
	s.merge(Data.HEROES[hero_id].stats, true)
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
func hero_offers() -> Array[String]:
	var pool: Array[String] = []
	for id in Data.HEROES:
		if not party.has(id):
			pool.append(id)
	pool.shuffle()
	return pool.slice(0, OFFER_COUNT)


## Up to 3 random skills usable by the current party and not yet maxed.
func skill_offers() -> Array[String]:
	var pool: Array[String] = []
	for skill in Data.SKILLS:
		if skill.hero != "" and not party.has(skill.hero):
			continue
		if rank_of(skill.id) >= Data.SKILL_MAX_RANK:
			continue
		pool.append(skill.id)
	pool.shuffle()
	return pool.slice(0, OFFER_COUNT)


func take_hero(hero_id: String) -> void:
	if not party.has(hero_id):
		party.append(hero_id)


func take_skill(skill_id: String) -> void:
	ranks[skill_id] = rank_of(skill_id) + 1


func _apply_mod(s: Dictionary, m: Array) -> void:
	var stat: String = m[0]
	match m[1]:
		"add":
			s[stat] += m[2]
		"mul":
			s[stat] *= m[2]
