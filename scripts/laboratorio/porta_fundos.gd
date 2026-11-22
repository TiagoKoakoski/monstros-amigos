class_name PortaFundos
extends Node2D
## Porta dos fundos do laboratório (parede de cima da sala da máquina): sai
## pro cemitério. Fechada até a festa (ou aberta desde o começo, com progresso).

const RAIO := 90.0

var aberta := false
## onde a criança encosta (logo abaixo da porta)
var ponto := Vector2.ZERO
var _fechada: Sprite2D
var _aberta: Sprite2D
var _luz: Sprite2D
var _tempo := 0.0


## `pes`: base da porta (encostada na parede); `p_ponto`: onde encostar.
func configurar(pes: Vector2, p_ponto: Vector2, p_aberta: bool) -> void:
	position = pes
	ponto = p_ponto
	_luz = Visual.luz(Color(0.6, 0.85, 1.0, 0.0), 380.0)
	_luz.position = Vector2(0, -60)
	add_child(_luz)
	_fechada = Visual.sprite_em_pe(load("res://arte/porta_fundos_fechada.svg") as Texture2D)
	add_child(_fechada)
	_aberta = Visual.sprite_em_pe(load("res://arte/porta_fundos_aberta.svg") as Texture2D)
	add_child(_aberta)
	aberta = p_aberta
	_fechada.visible = not aberta
	_aberta.visible = aberta


func _process(delta: float) -> void:
	_tempo += delta
	if aberta:
		_luz.modulate.a = 0.55 + 0.25 * sin(_tempo * 3.0)


func abrir() -> void:
	if aberta:
		return
	aberta = true
	_fechada.visible = false
	_aberta.visible = true
	_aberta.scale = Vector2(0.2, 1.0)
	create_tween().tween_property(_aberta, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func perto(p: Vector2) -> bool:
	return aberta and p.distance_to(ponto) < RAIO
