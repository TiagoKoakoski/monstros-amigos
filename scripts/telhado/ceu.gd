class_name Ceu
extends CanvasLayer
## O céu do telhado: fixo na tela, atrás de tudo (aparece entre os
## telhadinhos). Lua grande, estrelinhas piscando e as constelações que a
## criança já formou, pequenas, no alto.

const ESCALA_CONSTELACAO := 0.2
## onde cada constelação pronta fica na tela (canto de cima)
const LUGARES: Array[Vector2] = [Vector2(330, 120), Vector2(620, 90), Vector2(910, 130)]
const DOURADO := Color("#ffe27a")

var _estrelinhas: Array[Sprite2D] = []
var _constelacoes: Array[Node2D] = []
var _tempo := 0.0
var _fogos: CPUParticles2D
var _em_festa := false
## na festa, as constelações e os fogos vêm pra cá (na frente do telhado:
## com a câmera afastada o céu de trás quase não aparece)
var _frente: CanvasLayer


func _ready() -> void:
	layer = -1
	var fundo := Polygon2D.new()
	fundo.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)])
	fundo.vertex_colors = PackedColorArray([Color("#141a45"), Color("#141a45"), Color("#2e3a7a"), Color("#2e3a7a")])
	add_child(fundo)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var tex := load("res://arte/estrela.svg") as Texture2D
	for i in 120:
		var s := Sprite2D.new()
		s.texture = tex
		s.position = Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1080))
		s.scale = Vector2.ONE * rng.randf_range(0.06, 0.16)
		s.set_meta("fase", rng.randf() * TAU)
		add_child(s)
		_estrelinhas.append(s)
	var lua := Sprite2D.new()
	lua.texture = load("res://arte/lua_grande.svg") as Texture2D
	lua.position = Vector2(1640, 200)
	add_child(lua)
	_frente = CanvasLayer.new()
	_frente.layer = 2
	add_child(_frente)
	_fogos = CPUParticles2D.new()
	_fogos.position = Vector2(960, 300)
	_fogos.emitting = false
	_fogos.amount = 90
	_fogos.lifetime = 2.2
	_fogos.explosiveness = 0.0
	_fogos.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_fogos.emission_rect_extents = Vector2(800, 200)
	_fogos.direction = Vector2(0, -1)
	_fogos.spread = 180.0
	_fogos.initial_velocity_min = 40.0
	_fogos.initial_velocity_max = 140.0
	_fogos.gravity = Vector2(0, 30)
	_fogos.scale_amount_min = 6.0
	_fogos.scale_amount_max = 12.0
	var cores := Gradient.new()
	cores.colors = PackedColorArray([Color("#ffe27a"), Color("#ff9ecb"), Color("#9ad7ff"), Color(1, 1, 1, 0)])
	cores.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	_fogos.color_ramp = cores
	add_child(_fogos)


func _process(delta: float) -> void:
	_tempo += delta
	var forca := 1.0 if _em_festa else 0.6
	for s: Sprite2D in _estrelinhas:
		s.modulate.a = forca * (0.55 + 0.45 * sin(_tempo * 1.6 + float(s.get_meta("fase"))))


## Desenha a constelação `pontos` (coordenadas do mundo, em qualquer escala)
## pequena no alto da tela, no lugar `indice`.
func mostrar_constelacao(pontos: Array[Vector2], indice: int, animar: bool) -> void:
	var centro := Vector2.ZERO
	for p: Vector2 in pontos:
		centro += p
	centro /= pontos.size()
	var c := Node2D.new()
	c.position = LUGARES[clampi(indice, 0, LUGARES.size() - 1)]
	var linha := Line2D.new()
	linha.width = 4.0
	linha.default_color = Color(DOURADO, 0.8)
	for p: Vector2 in pontos:
		linha.add_point((p - centro) * ESCALA_CONSTELACAO)
	linha.add_point((pontos[0] - centro) * ESCALA_CONSTELACAO)
	c.add_child(linha)
	var tex := load("res://arte/estrela.svg") as Texture2D
	for p: Vector2 in pontos:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2.ONE * 0.22
		s.position = (p - centro) * ESCALA_CONSTELACAO
		c.add_child(s)
	add_child(c)
	_constelacoes.append(c)
	if animar:
		c.scale = Vector2.ONE * 0.2
		c.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(c, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(c, "modulate:a", 1.0, 0.8)


func constelacoes() -> int:
	return _constelacoes.size()


## Festa no céu: tudo brilha mais, as constelações crescem e os fogos de estrelinha começam.
func festa() -> void:
	_em_festa = true
	_fogos.reparent(_frente)
	_fogos.emitting = true
	for c: Node2D in _constelacoes:
		c.reparent(_frente)
		create_tween().tween_property(c, "scale", Vector2.ONE * 1.5, 1.6).set_trans(Tween.TRANS_SINE)


func festa_na_frente() -> bool:
	if _fogos.get_parent() != _frente:
		return false
	for c: Node2D in _constelacoes:
		if c.get_parent() != _frente:
			return false
	return true
