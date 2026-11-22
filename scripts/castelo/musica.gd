class_name Musica
extends Atividade
## Sala de música do Drácula: o órgão toca uma sequência de cores e a criança
## repete pisando nos ladrilhos. 3 rodadas (2, 3, 4 notas). Errar só faz o
## Drácula tocar a mesma sequência de novo.

const CORES: Array[Color] = [Color("#ff6f91"), Color("#4aa3ff"), Color("#ffd23f"), Color("#5bd17a")]
const NOTA := 0.55
const PAUSA_NOTA := 0.25

var seq: EstadoSequencia
var drac: Monstro
var ladrilhos: Array[Ladrilho] = []
## "esperando" (criança fora), "demo", "vez", "pausa", "fim"
var fase := "esperando"
var _sobre := -1
var _orgao_pos := Vector2.ZERO
var _auto_errou := false
var _demo: Tween
## meio dos 4 ladrilhos: dá pra chegar em qualquer um daqui sem pisar nos outros
var _meio := Vector2.ZERO


func montar() -> void:
	id = "musica"
	seq = EstadoSequencia.new(7 if Jogo.auto else randi())
	var o := area.position
	castelo.piso(area, Color("#a88bd1"), Color("#9a7cc4"), false)
	_meio = o + Vector2(800, 520)
	_tapete_roxo(_meio)
	castelo.tocha(o + Vector2(300, 0))
	castelo.tocha(o + Vector2(1200, 0))
	_orgao_pos = o + Vector2(260, 360)
	castelo.enfeite("orgao", _orgao_pos, Vector2(340, 70))
	# quadrado 2x2 com espaço no meio (em fila, ir de um a outro pisava no do meio)
	var cantos: Array[Vector2] = [Vector2(-240, -180), Vector2(240, -180), Vector2(-240, 180), Vector2(240, 180)]
	for i in 4:
		var l := Ladrilho.new()
		l.configurar(CORES[i])
		l.position = _meio + cantos[i]
		add_child(l)
		ladrilhos.append(l)
		castelo.carregar_som("nota_%d" % i)
	castelo.carregar_som("rodada")
	drac = Monstro.new()
	drac.configurar("dracula", "", load("res://arte/dracula.svg") as Texture2D, load("res://arte/nota.svg") as Texture2D)
	var notas: Array[Texture2D] = []
	for i in 3:
		notas.append(load("res://arte/nota.svg") as Texture2D)
	drac.mostrar_varios(notas)
	drac.position = o + Vector2(1310, 330)
	castelo.no_mundo(drac)


func _tapete_roxo(centro: Vector2) -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([centro + Vector2(-420, -330), centro + Vector2(420, -330),
		centro + Vector2(420, 330), centro + Vector2(-420, 330)])
	p.color = Color("#7d5fae")
	add_child(p)


func checar(p: Vector2) -> void:
	if terminada():
		return
	var agora := -1
	for i in 4:
		if ladrilhos[i].contem(p):
			agora = i
	var entrou := agora != -1 and agora != _sobre
	_sobre = agora
	if fase == "esperando" and contem(p):
		_tocar_demo(1.2)
		return
	if fase == "vez" and entrou:
		_pisou(agora)


func _pisou(cor: int) -> void:
	var r := seq.pisar(cor)
	ladrilhos[cor].acender(0.35)
	if r == "erro":
		castelo.tocar("hum")
		drac.lembrar_pedido()
		castelo.marco("nota_errada", 0.2)
		_auto_errou = true
		fase = "pausa"
		_tocar_demo(1.5)
		return
	castelo.tocar("nota_%d" % cor)
	castelo.progresso_feito()
	if r == "rodada" or r == "fim":
		drac.marcar_icone(seq.rodada - 1)
		drac.voltinha()
		var t := create_tween()
		t.tween_interval(0.35)
		t.tween_callback(func() -> void: castelo.tocar("rodada"))
		castelo.marco("rodada_%d" % seq.rodada, 0.4)
	if r == "rodada":
		fase = "pausa"
		_tocar_demo(1.8)
	elif r == "fim":
		fase = "fim"
		drac.concluir()
		castelo.marco("musica", 1.2)
		terminar()


## Drácula toca a sequência da rodada (depois de `atraso` segundos).
func _tocar_demo(atraso: float) -> void:
	fase = "demo"
	if _demo:
		_demo.kill()
	_demo = create_tween()
	_demo.tween_interval(atraso)
	for cor: int in seq.sequencia():
		_demo.tween_callback(func() -> void:
			ladrilhos[cor].acender(NOTA)
			castelo.tocar("nota_%d" % cor))
		_demo.tween_interval(NOTA + PAUSA_NOTA)
	_demo.tween_callback(func() -> void: fase = "vez")


func monstro() -> Monstro:
	return drac


func alvo() -> Vector2:
	if fase == "vez":
		return ladrilhos[seq.proxima_cor()].global_position
	return drac.global_position


func alvo_auto() -> Vector2:
	var p := castelo.jogador.global_position
	if fase == "esperando":
		return _meio
	if fase != "vez":
		return p if _sobre == -1 else _meio  # espera a demonstração parada, fora dos ladrilhos
	var alvo_cor := seq.proxima_cor()
	# na rodada 2, a primeira vez, pisa de propósito na cor errada
	if seq.rodada == 1 and not _auto_errou:
		alvo_cor = (alvo_cor + 1) % 4
		if alvo_cor == _sobre:
			alvo_cor = (alvo_cor + 1) % 4
	if _sobre == alvo_cor:
		return _meio  # sai pra entrar de novo
	return ladrilhos[alvo_cor].global_position
