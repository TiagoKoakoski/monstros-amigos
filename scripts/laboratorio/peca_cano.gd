class_name PecaCano
extends Node2D
## Uma peça de cano no chão (reta ou curva). Gira 90° de cada vez; quando a
## água passa, o miolo fica azul.

const LADO := 170.0

var _cano: Sprite2D
var _agua: Sprite2D
var _rot := 0


func configurar(tipo: String, rot: int) -> void:
	_cano = Sprite2D.new()
	_cano.texture = load("res://arte/cano_%s.svg" % tipo) as Texture2D
	add_child(_cano)
	_agua = Sprite2D.new()
	_agua.texture = load("res://arte/agua_%s.svg" % tipo) as Texture2D
	_agua.modulate.a = 0.0
	_cano.add_child(_agua)
	_rot = rot
	_cano.rotation = rot * PI * 0.5


func girar_para(rot: int) -> void:
	# gira sempre pra frente (sentido horário), nunca dá a volta pra trás
	var passos := posmod(rot - _rot, 4)
	_rot = rot
	var t := create_tween()
	t.tween_property(_cano, "rotation", _cano.rotation + passos * PI * 0.5, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func encher(atraso: float) -> void:
	var t := create_tween()
	t.tween_interval(atraso)
	t.tween_property(_agua, "modulate:a", 1.0, 0.25)


func contem(p: Vector2) -> bool:
	var d := p - global_position
	return absf(d.x) < LADO * 0.5 and absf(d.y) < LADO * 0.5
