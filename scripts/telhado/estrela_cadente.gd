class_name EstrelaCadente
extends Node2D
## Uma estrela cadente: primeiro uma sombra brilhante no chão (onde vai cair),
## depois ela desce devagar e fica pousada piscando, esperando a criança.
## O movimento anda em passo() (chamado pela sala), não em tween.

const SOMBRA := 1.5
const DESCE := 0.5
const ALTURA := 700.0
const FLUTUA := 40.0

var pousou := false
var _t := 0.0
var _sombra: Sprite2D
var _estrela: Sprite2D
var _luz: Sprite2D


func _ready() -> void:
	_sombra = Sprite2D.new()
	_sombra.texture = load("res://arte/sombra_estrela.svg") as Texture2D
	_sombra.modulate.a = 0.0
	add_child(_sombra)
	_luz = Visual.luz(Color(1.0, 0.9, 0.5, 0.0), 300.0)
	_luz.position = Vector2(0, -FLUTUA)
	add_child(_luz)
	_estrela = Sprite2D.new()
	_estrela.texture = load("res://arte/estrela.svg") as Texture2D
	_estrela.visible = false
	_estrela.position = Vector2(0, -ALTURA)
	add_child(_estrela)


func passo(delta: float) -> void:
	_t += delta
	if _t < SOMBRA:
		_sombra.modulate.a = 0.8 * _t / SOMBRA
		_sombra.scale = Vector2.ONE * (0.5 + 0.5 * _t / SOMBRA)
		return
	_estrela.visible = true
	if _t < SOMBRA + DESCE:
		var k := (_t - SOMBRA) / DESCE
		_estrela.position.y = lerpf(-ALTURA, -FLUTUA, k * k)
		_estrela.rotation = k * TAU
		return
	pousou = true
	_estrela.rotation = 0.0
	_estrela.position.y = -FLUTUA + sin(_t * 3.0) * 8.0
	_luz.modulate.a = 0.45 + 0.2 * sin(_t * 4.0)
	_sombra.modulate.a = 0.5


## Pega: voa até o pote e some.
func voar_ate(destino: Vector2) -> void:
	_sombra.visible = false
	var t := create_tween()
	t.tween_property(self, "global_position", destino + Vector2(0, FLUTUA), 0.7).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(self, "scale", Vector2.ONE * 0.35, 0.7)
	t.tween_callback(queue_free)
