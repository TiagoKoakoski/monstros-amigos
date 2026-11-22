class_name Fantasminha
extends Node2D
## Fantasminha fofo. Escondido: fica atrás do esconderijo e de vez em quando
## espia (um brilho e meio corpo de lado). Achado: pula pra fora e segue a
## criança flutuando (sem física: passa pelos portões). Entregue: fica com a mamãe.

var estado := "escondido"
var _corpo: Node2D
var _sprite: Sprite2D
var _brilho: Sprite2D
var _tempo := 0.0
var _proxima_espiada := 0.0
var _lado := 1.0


func configurar(atraso_espiada: float) -> void:
	_tempo = randf() * TAU
	_proxima_espiada = atraso_espiada
	_brilho = Visual.luz(Color(0.8, 0.9, 1.0, 0.0), 260.0)
	_brilho.position = Vector2(0, -70)
	add_child(_brilho)
	_corpo = Node2D.new()
	add_child(_corpo)
	_sprite = Visual.sprite_em_pe(load("res://arte/fantasminha.svg") as Texture2D)
	_corpo.add_child(_sprite)
	_corpo.modulate.a = 0.0


func _process(delta: float) -> void:
	_tempo += delta
	match estado:
		"escondido":
			if _tempo > _proxima_espiada:
				_proxima_espiada = _tempo + 4.0 + randf() * 1.5
				_espiar()
		"seguindo", "entregue", "festa":
			_corpo.position.y = -20.0 + sin(_tempo * 3.0) * 10.0


## Aparece de lado por um instante (pista visual) e volta a se esconder.
func _espiar() -> void:
	_lado = -_lado
	var t := create_tween()
	t.tween_property(_corpo, "position", Vector2(70.0 * _lado, -30), 0.3).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_corpo, "modulate:a", 0.85, 0.3)
	t.parallel().tween_property(_brilho, "modulate:a", 0.7, 0.3)
	t.tween_interval(0.6)
	t.tween_property(_corpo, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_corpo, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property(_brilho, "modulate:a", 0.0, 0.4)


func achar() -> void:
	estado = "seguindo"
	z_index = 3
	var t := create_tween()
	t.tween_property(_corpo, "modulate:a", 1.0, 0.15)
	t.parallel().tween_property(_corpo, "position", Vector2(0, -90), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_corpo, "position", Vector2(0, -20), 0.25)
	_brilho.modulate.a = 0.0


## Seguindo: chega perto do ponto da fila.
func seguir(ponto: Vector2, delta: float) -> void:
	var antes := global_position
	global_position = global_position.lerp(ponto, minf(1.0, delta * 7.0))
	var anda := global_position - antes
	if absf(anda.x) > 0.5:
		_sprite.scale.x = -1.0 if anda.x < 0 else 1.0


func entregar(lugar: Vector2) -> void:
	estado = "entregue"
	create_tween().tween_property(self, "global_position", lugar, 0.7).set_trans(Tween.TRANS_SINE)


func dancar() -> void:
	estado = "festa"
