class_name Alcapao
extends Node2D
## Alçapão no chão do salão do castelo: desce pro laboratório.
## Fechado até a festa do castelo (ou aberto desde o começo, com progresso).

const RAIO := 90.0

var aberto := false
var _fechado: Sprite2D
var _aberto: Sprite2D
var _luz: Sprite2D
var _tempo := 0.0


func configurar(pos: Vector2, p_aberto: bool) -> void:
	position = pos
	_luz = Visual.luz(Color(0.75, 0.6, 1.0, 0.0), 360.0)
	add_child(_luz)
	_fechado = Sprite2D.new()
	_fechado.texture = load("res://arte/alcapao_fechado.svg") as Texture2D
	add_child(_fechado)
	_aberto = Sprite2D.new()
	_aberto.texture = load("res://arte/alcapao_aberto.svg") as Texture2D
	_aberto.offset = Vector2(0, -30)
	add_child(_aberto)
	aberto = p_aberto
	_fechado.visible = not aberto
	_aberto.visible = aberto


func _process(delta: float) -> void:
	_tempo += delta
	if aberto:
		_luz.modulate.a = 0.55 + 0.25 * sin(_tempo * 3.0)


func abrir() -> void:
	if aberto:
		return
	aberto = true
	_fechado.visible = false
	_aberto.visible = true
	_aberto.scale = Vector2(1.0, 0.2)
	create_tween().tween_property(_aberto, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func perto(p: Vector2) -> bool:
	return aberto and p.distance_to(position) < RAIO
