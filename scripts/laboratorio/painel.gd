class_name Painel
extends Node2D
## Painel de 3 lâmpadas na parede da sala das Formas. Mostra as formas do
## grupo da vez (ficam acesas: é reconhecer e seguir a ordem, não decorar);
## a lâmpada da vez pulsa, as feitas ficam firmes.

const POS: Array[Vector2] = [Vector2(-130, 0), Vector2(0, 0), Vector2(130, 0)]

var _formas: Array[Sprite2D] = []
var _luzes: Array[Sprite2D] = []
var _vez := -1
var _tempo := 0.0


func montar() -> void:
	var fundo := Sprite2D.new()
	fundo.texture = load("res://arte/painel.svg") as Texture2D
	add_child(fundo)
	for i in 3:
		var luz := Visual.luz(Color(1, 1, 1, 0.0), 220.0)
		luz.position = POS[i]
		add_child(luz)
		_luzes.append(luz)
		var s := Sprite2D.new()
		s.position = POS[i]
		s.scale = Vector2.ONE * 0.8
		s.visible = false
		add_child(s)
		_formas.append(s)


## `formas`: índices das formas do grupo; `cores`: cor de cada forma (0..3);
## `feitos`: quantas do grupo já foram pisadas certo.
func mostrar(formas: Array[int], texturas: Array[Texture2D], cores: Array[Color], feitos: int) -> void:
	_vez = feitos if feitos < formas.size() else -1
	for i in 3:
		var s := _formas[i]
		var luz := _luzes[i]
		if i >= formas.size():
			s.visible = false
			luz.modulate.a = 0.0
			continue
		s.visible = true
		s.texture = texturas[formas[i]]
		var c := cores[formas[i]]
		s.modulate = c
		luz.modulate = Color(c.r, c.g, c.b, 0.85 if i < feitos else 0.35)
		if i < feitos:
			s.scale = Vector2.ONE * 0.8


func _process(delta: float) -> void:
	_tempo += delta
	if _vez >= 0:
		_formas[_vez].scale = Vector2.ONE * (0.8 + 0.1 * sin(_tempo * 6.0))
		_luzes[_vez].modulate.a = 0.45 + 0.35 * sin(_tempo * 6.0)
