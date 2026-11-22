class_name BotaoForma
extends Node2D
## Botão grande no chão com uma forma. Afunda e acende quando a criança pisa.

const LADO := 220.0

var forma := 0
var cor := Color.WHITE
var _base: Sprite2D
var _desenho: Sprite2D
var _luz: Sprite2D


func configurar(p_forma: int, nome: String, p_cor: Color) -> void:
	forma = p_forma
	cor = p_cor
	_luz = Visual.luz(Color(cor.r, cor.g, cor.b, 0.0), 420.0)
	add_child(_luz)
	_base = Sprite2D.new()
	_base.texture = load("res://arte/botao_forma.svg") as Texture2D
	_base.modulate = cor.lightened(0.55)
	add_child(_base)
	_desenho = Sprite2D.new()
	_desenho.texture = load("res://arte/forma_%s.svg" % nome) as Texture2D
	_desenho.modulate = cor
	_desenho.position = Vector2(0, -6)
	add_child(_desenho)


func apertar(certo: bool) -> void:
	var t := create_tween()
	_desenho.scale = Vector2.ONE * 0.85
	t.tween_property(_desenho, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if certo:
		_luz.modulate.a = 0.9
		create_tween().tween_property(_luz, "modulate:a", 0.0, 0.6)


func contem(p: Vector2) -> bool:
	var meio := LADO * 0.5
	var d := p - global_position
	return absf(d.x) < meio and absf(d.y) < meio
