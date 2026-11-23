class_name EstrelasCadentes
extends Atividade
## Estrelas cadentes da Coruja: as estrelas caem devagar em pontos sorteados
## (primeiro aparece a sombra brilhante de onde vai cair) e ficam no chão
## esperando. Encostar numa pousada: ela voa sozinha pro pote. 6 → termina.

const RAIO_PEGAR := 100.0
const ENTRE_QUEDAS := 2.0
const TOTAL := 6

var estrelas: EstadoEstrelas
var coruja: Monstro
var pote := Vector2.ZERO
var caindo: Dictionary[int, EstrelaCadente] = {}
var _ate_queda := 0.0


func montar() -> void:
	id = "estrelas"
	var o := area.position
	mapa.piso(area, Color("#56649c"), Color("#4d5a90"), false)
	var tex_estrela := load("res://arte/estrela.svg") as Texture2D
	coruja = Monstro.new()
	coruja.configurar("coruja", "", load("res://arte/coruja.svg") as Texture2D, tex_estrela)
	var icones: Array[Texture2D] = []
	for i in TOTAL:
		icones.append(tex_estrela)
	coruja.mostrar_varios(icones)
	coruja.position = o + Vector2(1050, 350)
	mapa.no_mundo(coruja)
	pote = o + Vector2(1180, 420)
	mapa.enfeite("pote_estrelas", pote, Vector2(70, 24))
	estrelas = EstadoEstrelas.new(11 if Jogo.auto else randi(), area.grow(-150), coruja.position, TOTAL)
	for nome: String in ["estrela", "queda"]:
		mapa.carregar_som(nome)


func checar(p: Vector2) -> void:
	if terminada():
		return
	var dt := get_physics_process_delta_time()
	if contem(p):
		_ate_queda -= dt
		if _ate_queda <= 0.0 and estrelas.pode_cair():
			_ate_queda = ENTRE_QUEDAS
			_nova_estrela(p)
	for i: int in caindo.keys():
		var e := caindo[i]
		e.passo(dt)
		if e.pousou and p.distance_to(e.global_position) < RAIO_PEGAR:
			_pegar(i)


func _nova_estrela(p: Vector2) -> void:
	var onde := estrelas.sortear(p)
	var i := estrelas.cair(onde)
	var e := EstrelaCadente.new()
	e.position = onde
	mapa.no_mundo(e)
	caindo[i] = e
	mapa.tocar("queda")


func _pegar(i: int) -> void:
	var r := estrelas.pegar(i)
	if r == "ignorado":
		return
	var e := caindo[i]
	caindo.erase(i)
	e.voar_ate(pote + Vector2(0, -60))
	coruja.marcar_icone(estrelas.pegas() - 1)
	mapa.tocar("estrela")
	mapa.progresso_feito()
	mapa.marco("estrela_%d" % estrelas.pegas(), 0.3)
	if r == "fim":
		coruja.concluir()
		mapa.marco("estrelas", 1.2)
		terminar()


func monstro() -> Monstro:
	return coruja


## A estrela esperando mais perto da criança; nenhuma, a Coruja.
func alvo() -> Vector2:
	var p := mapa.jogador.global_position
	var melhor := coruja.global_position
	var menor := INF
	for q: Vector2 in estrelas.esperando().values():
		if p.distance_to(q) < menor:
			menor = p.distance_to(q)
			melhor = q
	return melhor
