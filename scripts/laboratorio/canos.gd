class_name Canos
extends Atividade
## Canos do Lobisomem: girar as peças de cano no chão até a água da torneira
## chegar no vaso da planta. Girar = ficar parado em cima da peça (passar
## correndo não gira nada): o 1º giro depois de 0,5 s, depois a cada 1 s.

const PRIMEIRO_GIRO := 0.5
const OUTRO_GIRO := 1.0
## andou menos que isso desde o último quadro = está parado
const PARADO := 4.0
const PASSO := 260.0

var canos: EstadoCanos
var lobi: Monstro
var pecas: Dictionary[Vector2i, PecaCano] = {}
var _sobre := Vector2i(-1, -1)
var _ultima := Vector2.INF
var _parado := 0.0
var _proximo_giro := PRIMEIRO_GIRO
var _melhor := 0
var _planta: Sprite2D
var _auto_armadilha := false


func montar() -> void:
	id = "canos"
	canos = EstadoCanos.padrao()
	_melhor = canos.certas()
	var o := area.position
	mapa.piso(area, Color("#dfe9f5"), Color("#cdd9ea"), false)
	for cel: Vector2i in canos.celulas():
		var p := PecaCano.new()
		p.configurar(canos.tipo(cel), canos.rot(cel))
		p.position = centro(cel)
		add_child(p)
		pecas[cel] = p
	var torneira := Visual.sprite_em_pe(load("res://arte/torneira.svg") as Texture2D)
	torneira.position = centro(EstadoCanos.TORNEIRA) + Vector2(0, -PASSO * 0.5 + 10)
	add_child(torneira)
	var vaso_pos := centro(EstadoCanos.VASO) + Vector2(0, PASSO * 0.5 + 90)
	mapa.enfeite("vaso", vaso_pos, Vector2(150, 40))
	_planta = Visual.sprite_em_pe(load("res://arte/planta_pequena.svg") as Texture2D)
	_planta.position = vaso_pos + Vector2(0, -130)
	mapa.no_mundo(_planta)
	for nome: String in ["clique", "agua", "planta"]:
		mapa.carregar_som(nome)
	lobi = Monstro.new()
	lobi.configurar("lobisomem", "", load("res://arte/lobisomem.svg") as Texture2D, load("res://arte/planta_gigante.svg") as Texture2D)
	lobi.position = o + Vector2(880, 1320)
	mapa.no_mundo(lobi)


func centro(cel: Vector2i) -> Vector2:
	return area.position + Vector2(300 + cel.x * PASSO, 330 + cel.y * PASSO)


func checar(p: Vector2) -> void:
	if terminada():
		return
	var agora := Vector2i(-1, -1)
	for cel: Vector2i in pecas:
		if pecas[cel].contem(p):
			agora = cel
	var dt := get_physics_process_delta_time()
	if agora != Vector2i(-1, -1) and agora == _sobre and p.distance_to(_ultima) < PARADO:
		_parado += dt
	else:
		_parado = 0.0
		_proximo_giro = PRIMEIRO_GIRO
	_sobre = agora
	_ultima = p
	if _sobre != Vector2i(-1, -1) and _parado >= _proximo_giro:
		_proximo_giro += OUTRO_GIRO
		_girar(_sobre)


func _girar(cel: Vector2i) -> void:
	canos.girar(cel)
	pecas[cel].girar_para(canos.rot(cel))
	mapa.tocar("clique")
	if canos.armadilha(cel):
		mapa.marco("armadilha", 0.3)
		_auto_armadilha = true
		return  # girar a armadilha não é avanço (não cala o vaga-lume)
	if canos.certas() > _melhor:
		_melhor = canos.certas()
		mapa.progresso_feito()
	if canos.conectado():
		_agua_corre()


func _agua_corre() -> void:
	var cheias := canos.agua()
	mapa.tocar("agua")
	for i in cheias.size():
		pecas[cheias[i]].encher(0.2 + i * 0.18)
	var fim := 0.4 + cheias.size() * 0.18
	var t := create_tween()
	t.tween_interval(fim)
	t.tween_callback(func() -> void:
		mapa.tocar("planta")
		_planta.texture = load("res://arte/planta_gigante.svg") as Texture2D
		_planta.offset = Vector2(0, -_planta.texture.get_height() * 0.5)
		_planta.scale = Vector2.ONE * 0.3)
	t.tween_property(_planta, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lobi.concluir()
	mapa.marco("canos", fim + 1.2)
	terminar()


func monstro() -> Monstro:
	return lobi


## A peça do caminho que precisa girar. Se a criança já está em cima dela,
## continua ali: é pra ficar parada.
func alvo() -> Vector2:
	var cel := canos.proxima_errada()
	if cel == Vector2i(-1, -1):
		return lobi.global_position
	return centro(cel)


## Piloto: para na armadilha até ela girar uma vez, depois resolve o caminho.
func alvo_auto() -> Vector2:
	if not _auto_armadilha:
		return centro(Vector2i(1, 1))
	return alvo()
