class_name Ladrilho
extends Node2D
## Ladrilho colorido do chão da sala de música. Acende tocando sua nota.

const LADO := 220.0

var cor := Color.WHITE
var _sprite: Sprite2D
var _luz: Sprite2D
var _aceso := 0.0


func configurar(p_cor: Color) -> void:
	cor = p_cor
	_luz = Visual.luz(Color(cor.r, cor.g, cor.b, 0.0), 420.0)
	add_child(_luz)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://arte/ladrilho.svg") as Texture2D
	add_child(_sprite)
	_pintar()


func _process(delta: float) -> void:
	if _aceso > 0.0:
		_aceso = maxf(0.0, _aceso - delta)
		_pintar()


func acender(tempo: float) -> void:
	_aceso = tempo
	_pintar()
	var t := create_tween()
	_sprite.scale = Vector2.ONE * 1.12
	t.tween_property(_sprite, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func contem(p: Vector2) -> bool:
	var meio := LADO * 0.5
	var d := p - global_position
	return absf(d.x) < meio and absf(d.y) < meio


func _pintar() -> void:
	var ligado := _aceso > 0.0
	_sprite.modulate = cor.lightened(0.25) if ligado else cor.darkened(0.25)
	_luz.modulate.a = 0.9 if ligado else 0.0
