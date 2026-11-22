class_name Horta
extends Atividade
## Horta de abóboras do Lobisomem: semente no canteiro, água do poço, a
## abóbora cresce gigante e vai pra carroça. 3 abóboras. Semente e água nunca
## acabam e voltam pro saco/poço se não têm onde usar (nunca fica preso).

const RAIO_CANTEIRO := 100.0
const RAIO_COISA := 115.0
const RAIO_CARROCA := 140.0
const CRESCE := 2.0
## colisão no pé de cada coisa: estreita o bastante pra encostar de lado
const BASE_SACO := Vector2(120, 30)
const BASE_POCO := Vector2(150, 40)
const BASE_CARROCA := Vector2(160, 40)

var horta: EstadoHorta
var lobi: Monstro
var saco := Vector2.ZERO
var poco := Vector2.ZERO
var carroca := Vector2.ZERO
var canteiros: Array[Vector2] = []
var _plantas: Array[Sprite2D] = []
var _tempo := 0.0
var _ultimo_hum := -10.0
var _auto_hum := false
var _na_carroca := 0
## saco/poço onde a criança está agora: pegar e devolver só na chegada (quem
## fica parado ali não pega e devolve sem parar)
var _junto := ""


func montar() -> void:
	id = "horta"
	horta = EstadoHorta.new(3)
	var o := area.position
	mapa.piso(area, Color("#8cc4ab"), Color("#7fb8a0"), false)
	saco = o + Vector2(150, 250)
	poco = o + Vector2(950, 260)
	# arrumado pra que nenhum caminho reto entre saco, poço, carroça e canteiros
	# passe em cima de outro canteiro (senão toca "hum" no caminho certo)
	carroca = o + Vector2(450, 630)
	mapa.enfeite("saco_sementes", saco, BASE_SACO)
	mapa.enfeite("poco", poco, BASE_POCO)
	mapa.enfeite("carroca", carroca, BASE_CARROCA)
	for pos: Vector2 in [o + Vector2(150, 860), o + Vector2(480, 890), o + Vector2(810, 860)]:
		canteiros.append(pos)
		var terra := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(pos + Vector2(cos(a) * 95.0, sin(a) * 55.0))
		terra.polygon = pts
		terra.color = Color("#8a6a4f")
		mapa.no_chao(terra)
		var planta := Visual.sprite_em_pe(load("res://arte/broto.svg") as Texture2D)
		planta.position = pos + Vector2(0, 20)
		planta.visible = false
		mapa.no_mundo(planta)
		_plantas.append(planta)
	for nome: String in ["plantar", "regar", "crescer", "carroca"]:
		mapa.carregar_som(nome)
	lobi = Monstro.new()
	lobi.configurar("lobisomem", "", load("res://arte/lobisomem.svg") as Texture2D, load("res://arte/abobora_gigante.svg") as Texture2D)
	var aboboras: Array[Texture2D] = []
	for i in 3:
		aboboras.append(load("res://arte/abobora_gigante.svg") as Texture2D)
	lobi.mostrar_varios(aboboras)
	lobi.position = o + Vector2(560, 200)
	mapa.no_mundo(lobi)


func _physics_process(delta: float) -> void:
	_tempo += delta


func _na_mao() -> String:
	return mapa.estado.carregando


func checar(p: Vector2) -> void:
	if terminada():
		return
	var mao := _na_mao()
	var junto := "saco" if p.distance_to(saco) < RAIO_COISA else ("poco" if p.distance_to(poco) < RAIO_COISA + 20.0 else "")
	# só "saiu" bem longe da borda: tremer na beirada não conta como chegar de novo
	if junto == "" and _junto != "" and p.distance_to(saco if _junto == "saco" else poco) < RAIO_COISA + 60.0:
		junto = _junto
	var chegou := junto != "" and junto != _junto
	_junto = junto
	if mao == "":
		if chegou and junto == "saco":
			_pegar("semente", "semente", saco, false)
		elif chegou and junto == "poco":
			_pegar("agua", "regador", poco, false)
		elif junto == "":
			for i in canteiros.size():
				if horta.canteiro(i) == "pronta" and p.distance_to(canteiros[i]) < RAIO_CANTEIRO:
					horta.usar(i, "")
					_plantas[i].visible = false
					_pegar("abobora", "abobora_gigante", canteiros[i], true)
					mapa.marco("colheu", 0.4)
					break
		return
	# devolver o que não tem onde usar (nada se perde, ninguém fica preso)
	if chegou and ((mao == "semente" and junto == "saco") or (mao == "agua" and junto == "poco")):
		var item := mapa.tirar_da_mao()
		if item:
			item.queue_free()
		mapa.tocar("pegar")
		mapa.marco("devolveu", 0.3)
		return
	if mao == "abobora" and p.distance_to(carroca) < RAIO_CARROCA:
		_entregar()
		return
	for i in canteiros.size():
		if p.distance_to(canteiros[i]) >= RAIO_CANTEIRO:
			continue
		var r := horta.usar(i, mao)
		match r:
			"plantou":
				_soltar_no(canteiros[i])
				_plantas[i].texture = load("res://arte/broto.svg") as Texture2D
				_plantas[i].offset = Vector2(0, -_plantas[i].texture.get_height() * 0.5)
				_plantas[i].visible = true
				_plantas[i].scale = Vector2.ONE * 0.3
				create_tween().tween_property(_plantas[i], "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
				mapa.tocar("plantar")
				mapa.progresso_feito()
				mapa.marco("plantou", 0.4)
			"regou":
				_soltar_no(canteiros[i])
				mapa.tocar("regar")
				mapa.progresso_feito()
				mapa.marco("regou", 0.4)
				_crescer(i)
			"hum":
				if _tempo - _ultimo_hum > 1.6:
					_ultimo_hum = _tempo
					mapa.tocar("hum")
					mapa.marco("hum_horta", 0.3)
					_auto_hum = true
		return


func _pegar(id_item: String, desenho: String, de: Vector2, conta: bool) -> void:
	var it := ItemPerdido.new()
	it.configurar(id_item, load("res://arte/%s.svg" % desenho) as Texture2D)
	it.global_position = de
	mapa.no_mundo(it)
	mapa.dar_na_mao(it, id_item, conta)


## O item da mão cai no canteiro e some.
func _soltar_no(lugar: Vector2) -> void:
	var item := mapa.tirar_da_mao()
	if item == null:
		return
	item.reparent(self, true)
	var t := create_tween()
	t.tween_property(item, "global_position", lugar + Vector2(0, -30), 0.3).set_trans(Tween.TRANS_QUAD)
	t.tween_property(item, "scale", Vector2.ZERO, 0.2)
	t.tween_callback(item.queue_free)


func _crescer(i: int) -> void:
	var planta := _plantas[i]
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_callback(func() -> void:
		mapa.tocar("crescer")
		planta.texture = load("res://arte/abobora_gigante.svg") as Texture2D
		planta.offset = Vector2(0, -planta.texture.get_height() * 0.5)
		planta.scale = Vector2.ONE * 0.2)
	t.tween_property(planta, "scale", Vector2.ONE, CRESCE).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void:
		horta.crescer(i)
		mapa.marco("cresceu", 0.2))


func _entregar() -> void:
	var item := mapa.tirar_da_mao()
	var lugar := carroca + Vector2(-60 + _na_carroca * 60, -110)
	_na_carroca += 1
	if item:
		item.reparent(self, true)
		item.z_index = 3
		var t := create_tween()
		t.tween_property(item, "global_position", lugar, 0.4).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(item, "scale", Vector2.ONE * 0.5, 0.4)
	var r := horta.entregar()
	lobi.marcar_icone(horta.entregues() - 1)
	mapa.tocar("carroca")
	mapa.progresso_feito()
	mapa.marco("abobora_%d" % horta.entregues(), 0.5)
	if r == "fim":
		lobi.concluir()
		mapa.marco("horta", 1.2)
		terminar()
	else:
		lobi.voltinha()


func monstro() -> Monstro:
	return lobi


func dona_de(item: String) -> bool:
	return item in ["semente", "agua", "abobora"]


func alvo() -> Vector2:
	var a := _alvo_do_passo()
	# já está no saco/poço que o vaga-lume mostraria: precisa sair e voltar
	if _junto == "saco" and a == saco or _junto == "poco" and a == poco:
		return a + (Vector2(480, 600) + area.position - a).normalized() * 240.0
	return a


func _alvo_do_passo() -> Vector2:
	match horta.proximo_passo(_na_mao()):
		"canteiro_vazio":
			return canteiros[horta.canteiro_para("canteiro_vazio")]
		"canteiro_plantado":
			return canteiros[horta.canteiro_para("canteiro_plantado")]
		"pronta":
			return canteiros[horta.canteiro_para("pronta")]
		"carroca":
			return carroca
		"poco":
			return poco
		"sementes":
			return saco
	# crescendo: espera perto do canteiro que está crescendo
	var crescendo := horta.canteiro_para("canteiro_plantado")
	for i in canteiros.size():
		if horta.canteiro(i) == "crescendo":
			return canteiros[i] + Vector2(0, 130)
	return lobi.global_position if crescendo == -1 else canteiros[crescendo]


## Piloto: primeiro leva água a um canteiro vazio de propósito (hum) e devolve
## no poço; depois segue o vaga-lume.
func alvo_auto() -> Vector2:
	if not _auto_hum:
		if _na_mao() == "":
			return poco
		if _na_mao() == "agua":
			return canteiros[0]
	return alvo()
