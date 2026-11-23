class_name Planetinha
extends Node2D
## Um planetinha que rola pelo telhado (sem física: a sala move ele com Rolagem).

var cor := ""
var vel := Vector2.ZERO
var no_ninho := false
var _sprite: Sprite2D
var _giro := 0.0


func configurar(p_cor: String) -> void:
	cor = p_cor
	add_child(Visual.sombra(100.0))
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://arte/planeta_%s.svg" % cor) as Texture2D
	_sprite.position = Vector2(0, -50)
	add_child(_sprite)


func _process(delta: float) -> void:
	if no_ninho:
		_sprite.rotation = lerpf(_sprite.rotation, 0.0, minf(1.0, delta * 4.0))
		return
	# gira conforme rola (pra direita gira pra direita)
	_giro += vel.x * delta / 50.0
	_sprite.rotation = _giro


## Caiu no ninho: fica lá pra sempre, com um pulinho de alegria.
func encaixar(ninho: Vector2) -> void:
	no_ninho = true
	vel = Vector2.ZERO
	global_position = ninho + Vector2(0, 10)
	var t := create_tween()
	t.tween_property(_sprite, "position:y", -110.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "position:y", -40.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
