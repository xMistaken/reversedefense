extends Node
## Sound effects with a small player pool. Rapid repeats of the same sound are
## throttled so a hail of arrows doesn't turn into noise.

const SOUNDS := {
	"hit": [preload("res://assets/sfx/hit_0.ogg"), preload("res://assets/sfx/hit_1.ogg"), preload("res://assets/sfx/hit_2.ogg")],
	"crit": [preload("res://assets/sfx/crit.ogg")],
	"kill": [preload("res://assets/sfx/kill_0.ogg"), preload("res://assets/sfx/kill_1.ogg")],
	"armor": [preload("res://assets/sfx/armor.ogg")],
	"legendary": [preload("res://assets/sfx/legendary.ogg")],
	"chest": [preload("res://assets/sfx/chest.ogg")],
	"pick": [preload("res://assets/sfx/pick.ogg")],
	"coins": [preload("res://assets/sfx/coins.ogg")],
	"shove": [preload("res://assets/sfx/shove.ogg")],
	"click": [preload("res://assets/sfx/click.ogg")],
}
const MIN_GAP := {"hit": 0.06, "crit": 0.1, "kill": 0.05, "armor": 0.12}
const POOL_SIZE := 10

var enabled := true
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(name: String, volume_db := 0.0, pitch_jitter := 0.08) -> void:
	if not enabled or DisplayServer.get_name() == "headless":
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(name, -10.0) < MIN_GAP.get(name, 0.0):
		return
	_last_played[name] = now
	var options: Array = SOUNDS[name]
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = options[randi() % options.size()]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
