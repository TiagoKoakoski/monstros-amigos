class_name Formas
extends Atividade
## Formas do Drácula: o painel na parede mostra formas; a criança pisa nos
## botões das mesmas formas, da esquerda pra direita. Grupos de 1, 1, 1, 2, 2,
## 3 e 3 formas (as lâmpadas ficam acesas). Errou: "hum" e recomeça o grupo.

const NOMES: Array[String] = ["circulo", "estrela", "coracao", "triangulo"]
const CORES: Array[Color] = [Color("#ff6f91"), Color("#ffd23f"), Color("#ff5d73"), Color("#4aa3ff")]
## botões em cantos opostos do quadrado (0 e 3, 1 e 2)
const OPOSTOS := {0: 3, 3: 0, 1: 2, 2: 1}
const GRUPOS: Array[int] = [1, 1, 1, 2, 2, 3, 3]
## grupo terminado -> ícone do Drácula (uma etapa: 1 forma, 2 formas, 3 formas)
const ETAPA := {3: 0, 5: 1, 7: 2}
const PAUSA := 1.0

var seq: EstadoSequencia
var drac: Monstro
var botoes: Array[BotaoForma] = []
var painel: Painel
## "vez" ou "pausa" (entre grupos) ou "fim"
var fase := "vez"
var _sobre := -1
var _feitos := 0
var _meio := Vector2.ZERO
var _texturas: Array[Texture2D] = []
var _auto_errou := false


func montar() -> void:
	id = "formas"
	seq = EstadoSequencia.new(7 if Jogo.auto else randi(), GRUPOS, 4, OPOSTOS, true)
	var o := area.position
	mapa.piso(area, Color("#f0e2f5"), Color("#e3d0ec"), true)
	for nome: String in NOMES:
		_texturas.append(load("res://arte/forma_%s.svg" % nome) as Texture2D)
	_meio = o + Vector2(600, 520)
	var cantos: Array[Vector2] = [Vector2(-240, -180), Vector2(240, -180), Vector2(-240, 180), Vector2(240, 180)]
	for i in 4:
		var b := BotaoForma.new()
		b.configurar(i, NOMES[i], CORES[i])
		b.position = _meio + cantos[i]
		add_child(b)
		botoes.append(b)
		mapa.carregar_som("forma_%d" % i)
	mapa.carregar_som("rodada")
	painel = Painel.new()
	painel.position = o + Vector2(260, 10)
	painel.z_index = 1
	mapa.add_child(painel)
	painel.montar()
	drac = Monstro.new()
	drac.configurar("dracula", "", load("res://arte/dracula.svg") as Texture2D, _texturas[0])
	var etapas: Array[Texture2D] = [_texturas[0], _texturas[1], _texturas[3]]
	drac.mostrar_varios(etapas)
	drac.position = o + Vector2(1040, 330)
	mapa.no_mundo(drac)
	_mostrar()


func _mostrar() -> void:
	var grupo := seq.sequencia() if not seq.terminou() else ([] as Array[int])
	painel.mostrar(grupo, _texturas, CORES, _feitos)
	var lab := mapa as Laboratorio
	if lab and lab.maquina:
		var cores: Array[Color] = []
		for f: int in grupo:
			cores.append(CORES[f])
		lab.maquina.espelhar(cores, _feitos)


func checar(p: Vector2) -> void:
	if terminada():
		return
	var agora := -1
	for i in 4:
		if botoes[i].contem(p):
			agora = i
	# só conta a borda de entrada: quem já está em cima precisa sair e entrar
	var entrou := agora != -1 and agora != _sobre
	_sobre = agora
	if fase == "vez" and entrou:
		_pisou(agora)


func _pisou(forma: int) -> void:
	var r := seq.pisar(forma)
	if r == "erro":
		botoes[forma].apertar(false)
		mapa.tocar("hum")
		drac.lembrar_pedido()
		mapa.marco("forma_errada", 0.2)
		_auto_errou = true
		_feitos = 0
		_mostrar()
		return
	botoes[forma].apertar(true)
	mapa.tocar("forma_%d" % forma)
	mapa.progresso_feito()
	_feitos += 1
	_mostrar()
	if r == "certo":
		return
	# grupo fechado
	_feitos = 0
	if ETAPA.has(seq.rodada):
		drac.marcar_icone(ETAPA[seq.rodada])
		drac.voltinha()
	var t := create_tween()
	t.tween_interval(0.3)
	t.tween_callback(func() -> void: mapa.tocar("rodada"))
	mapa.marco("grupo_%d" % seq.rodada, 0.4)
	if r == "fim":
		fase = "fim"
		drac.concluir()
		mapa.marco("formas", 1.2)
		terminar()
		return
	fase = "pausa"
	t.tween_interval(PAUSA - 0.3)
	t.tween_callback(func() -> void:
		fase = "vez"
		_mostrar())


func monstro() -> Monstro:
	return drac


func alvo() -> Vector2:
	if seq.terminou():
		return drac.global_position
	var f := seq.proxima_cor()
	if _sobre == f:
		return _meio  # já está em cima: precisa sair e entrar de novo
	return _pelo_meio(botoes[f].global_position)


## Chegando de longe (pela porta), primeiro o meio do quadrado: a diagonal
## direto até um botão do fundo passa por cima de um botão da frente.
## Do meio até qualquer botão o caminho é livre.
func _pelo_meio(destino: Vector2) -> Vector2:
	var p := mapa.jogador.global_position
	if _sobre == -1 and p.distance_to(_meio) > 150.0 and p.distance_to(destino) > 260.0:
		return _meio
	return destino


## Piloto: no 1º grupo de 2 formas pisa de propósito numa forma errada.
func alvo_auto() -> Vector2:
	if fase != "vez":
		return mapa.jogador.global_position if _sobre == -1 else _meio
	var f := seq.proxima_cor()
	if seq.rodada == 3 and not _auto_errou:
		f = (f + 1) % 4
		if f == _sobre:
			f = (f + 1) % 4
	if _sobre == f:
		return _meio
	return _pelo_meio(botoes[f].global_position)
