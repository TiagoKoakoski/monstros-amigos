class_name Chaveiro
extends Node2D
## Chaves guardadas no canto da tela. Não ocupam a mão da criança.

const CANTO := Vector2(1780, 90)
const PASSO := 150.0
const CORES := {"azul": Color("#4aa3ff"), "vermelha": Color("#ff6f91")}

var _chaves: Dictionary[String, Sprite2D] = {}


func ganhar(cor: String, de_onde_na_tela: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://arte/chave.svg") as Texture2D
	s.modulate = CORES.get(cor, Color.WHITE)
	s.position = de_onde_na_tela
	s.scale = Vector2.ONE * 0.4
	add_child(s)
	var luz := Visual.luz(Color(1, 0.95, 0.6, 0.7), 220.0)
	luz.show_behind_parent = true
	s.add_child(luz)
	_chaves[cor] = s
	_reorganizar(s)


func usar(cor: String) -> void:
	if not _chaves.has(cor):
		return
	var s := _chaves[cor]
	_chaves.erase(cor)
	var t := create_tween()
	t.tween_property(s, "scale", Vector2.ONE * 1.6, 0.25)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.35)
	t.tween_callback(s.queue_free)
	_reorganizar(null)


func tem(cor: String) -> bool:
	return _chaves.has(cor)


func _reorganizar(nova: Sprite2D) -> void:
	var i := 0
	for cor: String in _chaves:
		var s := _chaves[cor]
		var destino := CANTO - Vector2(PASSO * i, 0)
		var t := create_tween()
		if s == nova:
			t.tween_property(s, "position", destino, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			t.parallel().tween_property(s, "scale", Vector2.ONE * 1.1, 0.9)
		else:
			t.tween_property(s, "position", destino, 0.3)
		i += 1
