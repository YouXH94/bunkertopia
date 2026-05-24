extends Node

const SFX := {
	"button": "res://assets/audio/ui/button_click.wav",
	"pickup": "res://assets/audio/sfx/pickup.wav",
	"door": "res://assets/audio/sfx/door_open.wav",
	"gun": "res://assets/audio/sfx/player_fire.wav",
	"turret": "res://assets/audio/sfx/turret_fire.wav",
	"hit": "res://assets/audio/sfx/hit_flesh.wav",
	"zombie": "res://assets/audio/sfx/zombie_moan.wav",
	"alarm": "res://assets/audio/sfx/alarm.wav",
	"generator": "res://assets/audio/sfx/generator_pulse.wav",
	"research": "res://assets/audio/sfx/research_success.wav",
	"fail": "res://assets/audio/sfx/research_fail.wav",
	"damage": "res://assets/audio/sfx/base_damage.wav"
}

var ambience_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_bus("SFX")
	_ensure_bus("UI")
	_ensure_bus("Ambience")

	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "Ambience"
	add_child(ambience_player)


func play_sfx(name: String, bus_name: String = "SFX") -> void:
	var path := str(SFX.get(name, ""))
	if path == "":
		return
	var stream = load(path)
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func play_ui(name: String = "button") -> void:
	play_sfx(name, "UI")


func play_ambience(path: String) -> void:
	var stream = load(path)
	if stream == null:
		return
	ambience_player.stop()
	ambience_player.stream = stream
	ambience_player.play()


func stop_ambience() -> void:
	if ambience_player != null:
		ambience_player.stop()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
