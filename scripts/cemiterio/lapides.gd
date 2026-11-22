class_name Lapides
extends Atividade
## Esconde-esconde: a Fantasma mamãe perdeu os 5 fantasminhas, escondidos atrás
## de lápides, abóboras e arbustos. Pistas: a risadinha (mais alta perto) e uma
## espiadinha de vez em quando. Achado, o fantasminha segue a criança em fila;
## encostar na mamãe entrega todos os que estão seguindo.

const RAIO_ESCONDERIJO := 110.0
const ESPACO_FILA := 16
## esconderijos (posição local, desenho): espalhados, longe uns dos outros e
## fora do caminho entre a entrada e a mamãe
const ESCONDERIJOS := [
	[Vector2(200, 200), "lapide_flor"], [Vector2(600, 180), "abobora_grande"],
	[Vector2(1000, 250), "arbusto"], [Vector2(300, 600), "lapide_gato"],
	[Vector2(700, 520), "arbusto"], [Vector2(250, 1050), "lapide_coracao"],
	[Vector2(650, 950), "abobora_grande"], [Vector2(1050, 1250), "lapide_flor"],
	[Vector2(300, 1500), "arbusto"], [Vector2(800, 1550), "lapide_gato"],
]
const BASES := {"lapide_flor": Vector2(110, 30), "lapide_gato": Vector2(110, 30), "lapide_coracao": Vector2(110, 30),
	"abobora_grande": Vector2(120, 40), "arbusto": Vector2(120, 40)}  # estreitas: dá pra encostar de lado
const ENTRE_RISADAS := 3.0

var esconde: EstadoEsconde
var mamae: Monstro
var lugares: Array[Vector2] = []
var fantasminhas: Dictionary[int, Fantasminha] = {}
var _rastro: Array[Vector2] = []
var _risada: AudioStreamPlayer
var _ate_risada := 1.0
var _ultimo_hum := -10.0
var _tempo := 0.0
var _auto_vazio := false


func montar() -> void:
	id = "lapides"
	esconde = EstadoEsconde.new(7 if Jogo.auto else randi())
	var o := area.position
	mapa.piso(area, Color("#7fb8a0"), Color("#74ad95"), false)
	for i in ESCONDERIJOS.size():
		var pos: Vector2 = o + (ESCONDERIJOS[i][0] as Vector2)
		var nome: String = ESCONDERIJOS[i][1]
		lugares.append(pos)
		if esconde.tem_fantasma(i):
			var f := Fantasminha.new()
			f.configurar(1.0 + i * 0.7)
			f.position = pos + Vector2(0, -12)  # logo atrás do esconderijo
			mapa.no_mundo(f)
			fantasminhas[i] = f
		mapa.enfeite(nome, pos, BASES[nome])
	mamae = Monstro.new()
	mamae.configurar("fantasma_mamae", "", load("res://arte/fantasma_mamae.svg") as Texture2D, load("res://arte/fantasminha.svg") as Texture2D)
	var filhos: Array[Texture2D] = []
	for i in 5:
		filhos.append(load("res://arte/fantasminha.svg") as Texture2D)
	mamae.mostrar_varios(filhos)
	mamae.position = o + Vector2(1050, 700)
	mapa.no_mundo(mamae)
	_risada = AudioStreamPlayer.new()
	_risada.stream = load("res://sons/risadinha.wav") as AudioStream
	add_child(_risada)


func _physics_process(delta: float) -> void:
	if mapa == null or mapa.jogador == null:
		return
	_tempo += delta
	var p := mapa.jogador.global_position
	if _rastro.is_empty() or _rastro[-1].distance_to(p) > 6.0:
		_rastro.append(p)
		if _rastro.size() > 200:
			_rastro.pop_front()
	var fila := 0
	for i: int in esconde.seguindo():
		fila += 1
		var idx := maxi(0, _rastro.size() - 1 - fila * ESPACO_FILA)
		fantasminhas[i].seguir(_rastro[idx], delta)
	_risadinha(delta, p)


## A risadinha do fantasminha escondido mais perto: mais alta quanto mais perto.
func _risadinha(delta: float, p: Vector2) -> void:
	if terminada() or not contem(p) or esconde.faltam_achar().is_empty():
		return
	_ate_risada -= delta
	if _ate_risada > 0.0:
		return
	_ate_risada = ENTRE_RISADAS
	var d := INF
	for i: int in esconde.faltam_achar():
		d = minf(d, p.distance_to(lugares[i]))
	_risada.volume_db = lerpf(-6.0, -30.0, clampf((d - 150.0) / 1250.0, 0.0, 1.0))
	_risada.play()


func checar(p: Vector2) -> void:
	if terminada():
		return
	for i in lugares.size():
		if p.distance_to(lugares[i]) >= RAIO_ESCONDERIJO:
			continue
		var r := esconde.achar(i)
		if r == "achou":
			fantasminhas[i].achar()
			mapa.tocar("achei")
			mapa.progresso_feito()
			mapa.marco("achou_%d" % (5 - esconde.faltam_achar().size()), 0.4)
		elif r == "vazio" and _tempo - _ultimo_hum > 2.0:
			_ultimo_hum = _tempo
			mapa.marco("vazio", 0.3)
			_auto_vazio = true
	if not esconde.seguindo().is_empty() and p.distance_to(mamae.global_position) < Fase.RAIO_MONSTRO:
		_entregar()


func _entregar() -> void:
	var antes := esconde.entregues()
	var quem := esconde.seguindo()
	esconde.entregar()
	for k in quem.size():
		var n := antes + k
		var lado := Vector2(-140 + 70 * n, 40 + (n % 2) * 30)
		fantasminhas[quem[k]].entregar(mamae.global_position + lado)
		mamae.marcar_icone(n)
	mapa.tocar("entregar")
	mapa.progresso_feito()
	if esconde.terminou():
		mamae.concluir()
		mapa.marco("lapides", 1.2)
		terminar()


func monstro() -> Monstro:
	return mamae


## Os fantasminhas também vão pra festa.
func convidados() -> Array[Node2D]:
	var c: Array[Node2D] = []
	for f: Fantasminha in fantasminhas.values():
		f.dancar()
		c.append(f)
	return c


func _mais_perto(p: Vector2, lista: Array[int]) -> int:
	var melhor := -1
	var menor := INF
	for i: int in lista:
		var d := p.distance_to(lugares[i])
		if d < menor:
			menor = d
			melhor = i
	return melhor


func alvo() -> Vector2:
	var p := mapa.jogador.global_position
	var falta := esconde.faltam_achar()
	if falta.is_empty():
		return mamae.global_position
	return lugares[_mais_perto(p, falta)]


## Piloto: primeiro encosta num esconderijo vazio de propósito; depois acha o
## mais perto; quando todos foram achados, leva pra mamãe.
func alvo_auto() -> Vector2:
	if not _auto_vazio:
		var vazios: Array[int] = []
		for i in lugares.size():
			if not esconde.tem_fantasma(i):
				vazios.append(i)
		return lugares[_mais_perto(mapa.jogador.global_position, vazios)]
	return alvo()
