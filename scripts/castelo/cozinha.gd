class_name Cozinha
extends Atividade
## Cozinha do Frankenstein: ele quer fazer um bolo e precisa de 3
## ingredientes espalhados pela cozinha. Um por vez, encostando.

const INGREDIENTES: Array[String] = ["ovo", "morango", "leite"]

var receita: EstadoReceita
var frank: Monstro
var itens: Dictionary[String, ItemPerdido] = {}
var _bolo: Sprite2D


func montar() -> void:
	id = "cozinha"
	receita = EstadoReceita.new(INGREDIENTES)
	var o := area.position
	castelo.piso(area, Color("#f3e3c4"), Color("#e2cda6"), true)
	var mesa_pos := o + Vector2(400, 380)
	castelo.enfeite("mesa", mesa_pos, Vector2(280, 60))
	castelo.enfeite("fogao", o + Vector2(820, 830), Vector2(190, 60))
	castelo.tocha(o + Vector2(250, 0))
	castelo.tocha(o + Vector2(750, 0))

	frank = Monstro.new()
	frank.configurar("frankenstein", "", load("res://arte/frankenstein.svg") as Texture2D,
		load("res://arte/ovo.svg") as Texture2D)
	var desenhos: Array[Texture2D] = []
	for item: String in INGREDIENTES:
		desenhos.append(load("res://arte/%s.svg" % item) as Texture2D)
	frank.mostrar_varios(desenhos)
	frank.position = o + Vector2(780, 330)
	castelo.no_mundo(frank)

	# atrás da mesa, num canto e perto do fogão: precisa contornar
	var lugares := {"ovo": o + Vector2(420, 190), "morango": o + Vector2(140, 800), "leite": o + Vector2(560, 820)}
	for item: String in INGREDIENTES:
		var it := ItemPerdido.new()
		it.configurar(item, load("res://arte/%s.svg" % item) as Texture2D)
		it.position = lugares[item]
		castelo.no_mundo(it)
		itens[item] = it

	_bolo = Visual.sprite_em_pe(load("res://arte/bolo.svg") as Texture2D)
	_bolo.position = mesa_pos + Vector2(0, -95)
	_bolo.scale = Vector2.ZERO
	_bolo.z_index = 2
	castelo.no_mundo(_bolo)


func checar(p: Vector2) -> void:
	if terminada():
		return
	if castelo.mao_vazia():
		for item: String in receita.falta():
			var it := itens[item]
			if it.no_chao and p.distance_to(it.global_position) < Fase.RAIO_ITEM:
				castelo.dar_na_mao(it, item)
				if Jogo.auto:
					print("AUTOPLAY: pegou %s (t=%.1fs)" % [item, castelo._tempo])
				castelo.marco("pegou_ingrediente", 0.5)
				return
	if p.distance_to(frank.global_position) > Fase.RAIO_MONSTRO:
		return
	var na_mao := castelo.estado.carregando
	if receita.quer(na_mao):
		var no := castelo.tirar_da_mao()
		receita.entregar(na_mao)
		if Jogo.auto:
			print("AUTOPLAY: frankenstein recebeu %s (t=%.1fs)" % [na_mao, castelo._tempo])
		frank.receber_parcial(no)
		frank.marcar_icone(INGREDIENTES.find(na_mao))
		castelo.tocar("entregar")
		castelo.progresso_feito()
		if receita.completa():
			_assar_bolo()
	elif frank.lembrar_pedido():
		castelo.tocar("hum")


func _assar_bolo() -> void:
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(_bolo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	frank.concluir()
	castelo.marco("cozinha", 1.2)
	terminar()


func monstro() -> Monstro:
	return frank


func dona_de(item: String) -> bool:
	return INGREDIENTES.has(item)


func alvo() -> Vector2:
	if receita.quer(castelo.estado.carregando):
		return frank.global_position
	var melhor := frank.global_position
	var menor := INF
	for item: String in receita.falta():
		var it := itens[item]
		if not it.no_chao:
			continue
		var d := castelo.jogador.global_position.distance_to(it.global_position)
		if d < menor:
			menor = d
			melhor = it.global_position
	return melhor
