class_name Jardim
extends Fase
## Fase 1: o jardim do castelo. Pegar o que cada monstro perdeu e entregar.
##
## Pensado para uma criança de 5 anos aprendendo a jogar: nada pra ler, nada
## pra perder, tudo acontece encostando nas coisas. Se ela ficar um tempo sem
## progresso, um vaga-lume mostra o caminho.

const CHAO_TOPO := 640.0

const MONSTROS := [
	{"id": "dracula", "item": "morcego", "pos": Vector2(700, 880)},
	{"id": "frankenstein", "item": "flor", "pos": Vector2(2500, 880)},
	{"id": "mumia", "item": "faixa", "pos": Vector2(640, 1690)},
	{"id": "lobisomem", "item": "bola", "pos": Vector2(2560, 1690)},
]
const ITENS := {
	"morcego": Vector2(2060, 1730),
	"flor": Vector2(1060, 1500),
	"faixa": Vector2(2140, 1070),
	"bola": Vector2(1140, 930),
}

var estado: EstadoMissao
var monstros: Dictionary[String, Monstro] = {}
var itens: Dictionary[String, ItemPerdido] = {}

var _auto_errado_feito := false


func montar() -> void:
	largura = 3200.0
	altura = 2000.0
	inicio = Vector2(1600, 1300)
	espera_guia = 5.0
	musica_inicial = "res://sons/musica_noite.wav"
	var pedidos: Dictionary[String, String] = {}
	for m: Dictionary in MONSTROS:
		pedidos[m["id"]] = m["item"]
	estado = EstadoMissao.new(pedidos)

	_montar_ceu_e_castelo()
	_montar_chao()
	add_child(_mundo)
	_montar_bordas()
	_montar_enfeites()
	_montar_personagens()
	_montar_vagalumes()


# ---------------------------------------------------------------- partida

func checar_interacoes() -> void:
	if em_festa:
		return
	var p := jogador.global_position
	if estado.carregando == "":
		for item_id: String in estado.itens_no_chao():
			var item := itens[item_id]
			if p.distance_to(item.global_position) < RAIO_ITEM:
				estado.pegar(item_id)
				item.ao_pegar()
				jogador.segurar(item)
				tocar("pegar")
				progresso_feito()
				marco("pegou", 0.5)
				break
	for m: Monstro in monstros.values():
		if m.ajudado or p.distance_to(m.global_position) > RAIO_MONSTRO:
			continue
		if estado.carregando == m.item_id:
			var item := jogador.soltar_na_mao()
			estado.entregar(m.id)
			m.receber(item)
			tocar("entregar")
			progresso_feito()
			marco("entregou", 0.9)
			if estado.todos_ajudados():
				_festa()
			return
		if m.lembrar_pedido():
			tocar("hum")


func depois_do_frame() -> void:
	for m: Monstro in monstros.values():
		m.marcar_farol(not em_festa and estado.carregando != "" and estado.carregando == m.item_id)


## Para onde a criança deveria ir agora: o dono do item na mão, ou o item
## mais perto no chão.
func alvo_atual() -> Vector2:
	if estado.carregando != "":
		return monstros[estado.dono_do_item(estado.carregando)].global_position
	var melhor := Vector2.ZERO
	var menor := INF
	for item_id: String in estado.itens_no_chao():
		var d := jogador.global_position.distance_to(itens[item_id].global_position)
		if d < menor:
			menor = d
			melhor = itens[item_id].global_position
	return melhor


func _festa() -> void:
	for m: Monstro in monstros.values():
		m.dancar()
	comecar_festa(inicio + Vector2(0, -80), true)
	marco("festa", 3.0)


func ao_recomecar() -> void:
	Jogo.trocar_fase(Jogo.JARDIM)


# ---------------------------------------------------------------- montagem do mundo

func _montar_ceu_e_castelo() -> void:
	var ceu := Polygon2D.new()
	ceu.polygon = PackedVector2Array([Vector2(0, 0), Vector2(largura, 0), Vector2(largura, CHAO_TOPO + 40), Vector2(0, CHAO_TOPO + 40)])
	var topo := Color("#2a2357")
	var horizonte := Color("#7a5fa8")
	ceu.vertex_colors = PackedColorArray([topo, topo, horizonte, horizonte])
	add_child(ceu)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 70:
		var estrela := Visual.luz(Color(1, 1, 0.9, rng.randf_range(0.4, 0.9)), rng.randf_range(10.0, 26.0))
		estrela.position = Vector2(rng.randf_range(0, largura), rng.randf_range(20, CHAO_TOPO - 120))
		add_child(estrela)
	var lua := Sprite2D.new()
	lua.texture = load("res://arte/lua.svg") as Texture2D
	lua.position = Vector2(2720, 190)
	add_child(lua)
	var castelo := Visual.sprite_em_pe(load("res://arte/castelo.svg") as Texture2D)
	castelo.position = Vector2(largura * 0.5, CHAO_TOPO + 30)
	add_child(castelo)


func _montar_chao() -> void:
	var grama := Polygon2D.new()
	grama.polygon = PackedVector2Array([Vector2(0, CHAO_TOPO), Vector2(largura, CHAO_TOPO), Vector2(largura, altura), Vector2(0, altura)])
	var g1 := Color("#4f9160")
	var g2 := Color("#3f7d55")
	grama.vertex_colors = PackedColorArray([g2, g2, g1, g1])
	add_child(grama)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 26:
		var mancha := Visual.sombra(rng.randf_range(260, 520))
		mancha.color = Color(0.45, 0.7, 0.45, 0.18)
		mancha.position = Vector2(rng.randf_range(100, largura - 100), rng.randf_range(CHAO_TOPO + 80, altura - 60))
		add_child(mancha)
	for m: Dictionary in MONSTROS:
		_caminho(inicio, m["pos"])
	_caminho(Vector2(700, 880), Vector2(largura * 0.5, CHAO_TOPO + 40))
	_caminho(Vector2(2500, 880), Vector2(largura * 0.5, CHAO_TOPO + 40))
	# poças de luz quente: o jardim é noite, mas nunca escuro
	for pos: Vector2 in [inicio, Vector2(700, 880), Vector2(2500, 880), Vector2(640, 1690), Vector2(2560, 1690)]:
		var poca := Visual.luz(Color(1.0, 0.85, 0.55, 0.22), 700.0)
		poca.position = pos
		poca.scale.y *= 0.55
		add_child(poca)


func _caminho(de: Vector2, ate: Vector2) -> void:
	var meio := (de + ate) * 0.5 + Vector2(0, 60).rotated(de.angle_to_point(ate))
	var pontos := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		pontos.append(de.lerp(meio, t).lerp(meio.lerp(ate, t), t))
	for camada: Array in [[150.0, Color("#b89a63")], [126.0, Color("#dcc590")]]:
		var linha := Line2D.new()
		linha.points = pontos
		linha.width = camada[0]
		linha.default_color = camada[1]
		linha.joint_mode = Line2D.LINE_JOINT_ROUND
		linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
		linha.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(linha)


func _montar_bordas() -> void:
	var paredes := StaticBody2D.new()
	add_child(paredes)
	for r: Rect2 in [Rect2(-200, 0, largura + 400, CHAO_TOPO + 20), Rect2(-200, altura - 20, largura + 400, 200),
			Rect2(-200, 0, 240, altura), Rect2(largura - 40, 0, 240, altura)]:
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = r.size
		forma.shape = ret
		forma.position = r.position + r.size * 0.5
		paredes.add_child(forma)


func _montar_enfeites() -> void:
	var arvore := load("res://arte/arvore.svg") as Texture2D
	for pos: Vector2 in [Vector2(250, 1180), Vector2(2950, 1180), Vector2(1600, 1990), Vector2(330, 760), Vector2(2870, 760)]:
		_enfeite(arvore, pos, 52.0)
	var abobora := load("res://arte/abobora.svg") as Texture2D
	for pos: Vector2 in [Vector2(1330, 1160), Vector2(1870, 1160), Vector2(1330, 1560), Vector2(1870, 1560), Vector2(880, 1190), Vector2(2330, 1190)]:
		_enfeite(abobora, pos, 0.0)
	var poste := load("res://arte/poste.svg") as Texture2D
	for pos: Vector2 in [Vector2(950, 1020), Vector2(2250, 1020), Vector2(1250, 1820), Vector2(1950, 1820)]:
		var luz := Visual.luz(Color(1.0, 0.82, 0.45, 0.35), 520.0)
		luz.position = pos + Vector2(0, -20)
		luz.scale.y *= 0.6
		add_child(luz)
		_enfeite(poste, pos, 0.0)  # sem colisão: fica no caminho e travava quem passava
	var arbusto := load("res://arte/arbusto.svg") as Texture2D
	var x := 120.0
	while x < largura:
		_enfeite(arbusto, Vector2(x, altura + 30), 0.0)
		x += 260.0
	var y := CHAO_TOPO + 160.0
	while y < altura:
		_enfeite(arbusto, Vector2(30, y), 0.0)
		_enfeite(arbusto, Vector2(largura - 30, y), 0.0)
		y += 300.0


func _enfeite(textura: Texture2D, pos: Vector2, raio_tronco: float) -> void:
	var s := Visual.sprite_em_pe(textura)
	s.position = pos
	_mundo.add_child(s)
	if raio_tronco > 0.0:
		var corpo := StaticBody2D.new()
		corpo.position = pos
		var forma := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = raio_tronco
		forma.shape = c
		corpo.add_child(forma)
		add_child(corpo)


func _montar_personagens() -> void:
	for m: Dictionary in MONSTROS:
		var mon := Monstro.new()
		mon.configurar(m["id"], m["item"], load("res://arte/%s.svg" % m["id"]) as Texture2D,
			load("res://arte/%s.svg" % m["item"]) as Texture2D)
		mon.position = m["pos"]
		_mundo.add_child(mon)
		monstros[m["id"]] = mon
	for item_id: String in ITENS:
		var it := ItemPerdido.new()
		it.configurar(item_id, load("res://arte/%s.svg" % item_id) as Texture2D)
		it.position = ITENS[item_id]
		_mundo.add_child(it)
		itens[item_id] = it
	jogador.position = inicio
	_mundo.add_child(jogador)


func _montar_vagalumes() -> void:
	var v := CPUParticles2D.new()
	v.texture = Visual.textura_brilho()
	v.amount = 46
	v.lifetime = 7.0
	v.preprocess = 7.0
	v.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	v.emission_rect_extents = Vector2(largura * 0.5, (altura - CHAO_TOPO) * 0.5)
	v.position = Vector2(largura * 0.5, (altura + CHAO_TOPO) * 0.5)
	v.direction = Vector2(0, -1)
	v.spread = 180.0
	v.gravity = Vector2.ZERO
	v.initial_velocity_min = 8.0
	v.initial_velocity_max = 28.0
	v.scale_amount_min = 0.12
	v.scale_amount_max = 0.24
	var cor := Gradient.new()
	cor.set_color(0, Color(1, 0.95, 0.5, 0.0))
	cor.set_color(1, Color(1, 0.95, 0.5, 0.0))
	cor.add_point(0.3, Color(1, 0.95, 0.5, 0.85))
	cor.add_point(0.7, Color(1, 0.95, 0.5, 0.85))
	v.color_ramp = cor
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	v.material = mat
	v.z_index = 15
	add_child(v)


# ---------------------------------------------------------------- teste automático

func iniciar_auto() -> void:
	if Jogo.marcos_globais.get("conferir_recomeco", "") == scene_file_path:
		Jogo.marcos_globais.erase("conferir_recomeco")
		_conferir_recomeco.call_deferred()
		return
	print("AUTOPLAY: começando no jardim")
	var controles: Array[String] = []
	for id: int in Input.get_connected_joypads():
		controles.append("%d=%s" % [id, Input.get_joy_name(id)])
	print("AUTOPLAY: controles conectados: %s" % (", ".join(controles) if controles else "nenhum"))


func pilotar_auto(delta: float) -> Vector2:
	if em_festa:
		return Vector2.ZERO
	# fica parado no começo pra provar que o vaga-lume aparece sozinho
	if _tempo < espera_guia + 1.5:
		if _tempo > 2.0:
			marco("inicio")
		return Vector2.ZERO
	if not tem_marco("guia"):
		falha_auto("o vaga-lume não apareceu depois de %ss parado" % espera_guia)
		marco("guia")
	var alvo := alvo_atual()
	# na primeira vez com item na mão, passa num monstro ERRADO de propósito
	if estado.carregando != "" and not _auto_errado_feito:
		for m: Monstro in monstros.values():
			if not m.ajudado and m.item_id != estado.carregando:
				alvo = m.global_position
				if jogador.global_position.distance_to(alvo) < RAIO_MONSTRO - 20.0:
					_auto_errado_feito = true
					if estado.carregando == "":
						falha_auto("entregar pro monstro errado tirou o item da mão")
					marco("errado", 0.2)
				break
	return andar_ate(alvo, delta)


func verificar_fim_auto() -> Array[String]:
	var falhas: Array[String] = []
	if not estado.todos_ajudados():
		falhas.append("nem todos os monstros foram ajudados (%d/4)" % estado.quantos_ajudados())
	for obrigatorio: String in ["guia", "pegou", "errado", "entregou", "festa", "pode_recomecar"]:
		if not tem_marco(obrigatorio):
			falhas.append("não passou pelo momento: %s" % obrigatorio)
	return falhas


func _conferir_recomeco() -> void:
	soltar_botao_auto()
	var falhas: Array[String] = []
	if estado.quantos_ajudados() != 0:
		falhas.append("recomeçou com monstro já ajudado")
	if estado.carregando != "":
		falhas.append("recomeçou com item na mão")
	if estado.itens_no_chao().size() != 4:
		falhas.append("recomeçou sem os 4 itens no chão")
	if em_festa:
		falhas.append("recomeçou ainda em festa")
	if falhas.is_empty():
		print("AUTOPLAY: botão A na festa recomeçou o jogo limpo")
		Jogo.marcos_globais["resumo"] = "partida completa e recomeço conferido"
	for f: String in falhas:
		falha_auto(f)
	_sair_com(_auto_falhas)
