class_name Vela
extends Node2D
## Vela da biblioteca. Apagada, brilha fraquinho pra ser achada no escuro;
## acesa, ilumina bem em volta.

var acesa := false
var _chama: Sprite2D
var _fraca: Sprite2D
var _forte: Sprite2D
var _tempo := 0.0


func _ready() -> void:
	_tempo = randf() * TAU
	_fraca = Visual.luz(Color(1.0, 0.9, 0.6, 0.35), 240.0)
	_fraca.position = Vector2(0, -90)
	_fraca.z_index = 6
	add_child(_fraca)
	_forte = Visual.luz(Color(1.0, 0.82, 0.5, 0.0), 700.0)
	_forte.position = Vector2(0, -80)
	_forte.z_index = 6
	add_child(_forte)
	add_child(Visual.sombra(80.0))
	add_child(Visual.sprite_em_pe(load("res://arte/vela.svg") as Texture2D))
	_chama = Sprite2D.new()
	_chama.texture = load("res://arte/chama.svg") as Texture2D
	_chama.offset = Vector2(0, -36)
	_chama.position = Vector2(0, -124)
	_chama.z_index = 7
	_chama.visible = false
	add_child(_chama)


func _process(delta: float) -> void:
	_tempo += delta
	if acesa:
		_chama.scale = Vector2(1.0 + 0.06 * sin(_tempo * 13.0), 1.0 + 0.1 * sin(_tempo * 9.0))
	else:
		_fraca.modulate.a = 0.25 + 0.2 * (0.5 + 0.5 * sin(_tempo * 3.0))


func acender() -> void:
	acesa = true
	_fraca.visible = false
	_chama.visible = true
	_chama.scale = Vector2.ZERO
	create_tween().tween_property(_forte, "modulate:a", 0.55, 0.6)
