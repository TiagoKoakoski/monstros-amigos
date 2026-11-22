class_name ItemPerdido
extends Node2D
## Algo que um monstro perdeu. Brilha e balança pra chamar atenção de longe.

var id := ""
var _sprite: Sprite2D
var _brilho: Sprite2D
var _tempo := 0.0
var no_chao := true


func configurar(p_id: String, textura: Texture2D) -> void:
	id = p_id
	_brilho = Visual.luz(Color(1.0, 0.92, 0.55, 0.8), 230.0)
	_brilho.position = Vector2(0, -50)
	add_child(_brilho)
	add_child(Visual.sombra(90.0))
	_sprite = Sprite2D.new()
	_sprite.texture = textura
	_sprite.position = Vector2(0, -60)
	add_child(_sprite)
	_tempo = randf() * TAU


func _process(delta: float) -> void:
	_tempo += delta
	if no_chao:
		_sprite.position.y = -60.0 + sin(_tempo * 3.0) * 10.0
		var pulso := 0.75 + 0.25 * sin(_tempo * 4.0)
		_brilho.modulate.a = pulso
		_brilho.scale = Vector2.ONE * (230.0 / 128.0) * (0.9 + 0.15 * pulso)


func ao_pegar() -> void:
	no_chao = false
	_brilho.visible = false
	for filho in get_children():
		if filho is Polygon2D:
			filho.visible = false  # a sombra fica no chão, não acima da cabeça
	_sprite.position = Vector2.ZERO
	var t := create_tween()
	scale = Vector2.ONE * 0.4
	t.tween_property(self, "scale", Vector2.ONE * 0.85, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
