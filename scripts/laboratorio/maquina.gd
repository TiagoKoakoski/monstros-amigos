class_name Maquina
extends Node2D
## A máquina do Frankenstein, no meio do laboratório. Um cabo acende a cada
## sala terminada; as 3 lâmpadas repetem o painel das Formas (enfeite); com
## tudo pronto ela liga: engrenagens giram e sobem bolhas de arco-íris.

const CORES_CABO: Array[Color] = [Color("#5bd17a"), Color("#ff9f43"), Color("#c77dff")]

var ligada := false
var _cabos: Array[Line2D] = []
var _lampadas: Array[Sprite2D] = []
var _engrenagens: Array[Sprite2D] = []
var _bolhas: CPUParticles2D
var _tempo := 0.0


## `mapa`: a fase (pra pôr a máquina de pé no mundo com colisão).
func montar(mapa: FaseDeSalas, pes: Vector2) -> void:
	position = pes
	# cabos no chão saindo pras portas das 3 salas (esquerda, direita, baixo)
	var pontas: Array[Vector2] = [Vector2(-600, 150), Vector2(600, 150), Vector2(0, 630)]
	for i in 3:
		var l := Line2D.new()
		l.points = PackedVector2Array([pes + Vector2(0, -20), pes + (pontas[i] * 0.5) + Vector2(0, 40), pes + pontas[i]])
		l.width = 18.0
		l.default_color = Color("#6b5f8f")
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		mapa.no_chao(l)
		_cabos.append(l)
	mapa.enfeite("maquina", pes, Vector2(360, 90))
	for x: float in [-150.0, 150.0]:
		var e := Sprite2D.new()
		e.texture = load("res://arte/engrenagem.svg") as Texture2D
		e.position = pes + Vector2(x, -330)
		e.z_index = 3
		mapa.add_child(e)
		_engrenagens.append(e)
	for i in 3:
		var s := Sprite2D.new()
		s.texture = Visual.textura_brilho()
		s.scale = Vector2.ONE * 0.5
		s.position = pes + Vector2(-90 + i * 90, -215)
		s.modulate = Color(1, 1, 1, 0.15)
		s.z_index = 3
		mapa.add_child(s)
		_lampadas.append(s)
	_bolhas = CPUParticles2D.new()
	_bolhas.position = pes + Vector2(0, -360)
	_bolhas.z_index = 4
	_bolhas.amount = 40
	_bolhas.lifetime = 3.0
	_bolhas.direction = Vector2(0, -1)
	_bolhas.spread = 30.0
	_bolhas.gravity = Vector2(0, -20)
	_bolhas.initial_velocity_min = 40.0
	_bolhas.initial_velocity_max = 110.0
	_bolhas.scale_amount_min = 6.0
	_bolhas.scale_amount_max = 14.0
	_bolhas.color_initial_ramp = Visual.gradiente_festa()
	_bolhas.emitting = false
	mapa.add_child(_bolhas)


func _process(delta: float) -> void:
	_tempo += delta
	if not ligada:
		return
	for i in _engrenagens.size():
		_engrenagens[i].rotation += delta * (1.5 if i == 0 else -1.5)
	for i in _lampadas.size():
		_lampadas[i].modulate = Color.from_hsv(fmod(_tempo * 0.3 + i * 0.33, 1.0), 0.6, 1.0, 0.9)


func acender_cabo(i: int) -> void:
	if i < 0 or i >= _cabos.size():
		return
	var l := _cabos[i]
	create_tween().tween_property(l, "default_color", CORES_CABO[i], 0.8)


## Lâmpadas da máquina copiam o painel das Formas (cores das formas do grupo).
func espelhar(cores: Array[Color], vez: int) -> void:
	if ligada:
		return
	for i in _lampadas.size():
		if i < cores.size():
			var c := cores[i]
			_lampadas[i].modulate = Color(c.r, c.g, c.b, 1.0 if i == vez else 0.6)
		else:
			_lampadas[i].modulate = Color(1, 1, 1, 0.15)


func ligar() -> void:
	if ligada:
		return
	ligada = true
	_bolhas.emitting = true
