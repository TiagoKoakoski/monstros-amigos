extends Node2D
## Monta o jardim do castelo e conduz a partida: pegar, entregar, festa, recomeçar.
##
## Pensado para uma criança de 5 anos aprendendo a jogar: nada pra ler, nada
## pra perder, tudo acontece encostando nas coisas. Se ela ficar um tempo sem
## progresso, um vaga-lume mostra o caminho.
##
## Modo de teste: godot --path . -- --autoplay --capturas=/pasta
## joga a partida sozinho com o mesmo movimento do jogador e salva fotos da tela.

const LARGURA := 3200.0
const ALTURA := 2000.0
const CHAO_TOPO := 640.0
const RAIO_ITEM := 115.0
const RAIO_MONSTRO := 175.0
const ESPERA_GUIA := 5.0
const INICIO := Vector2(1600, 1300)

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
var jogador: Jogador
var camera: Camera2D
var guia: Guia

var _mundo: Node2D
var _musica: AudioStreamPlayer
var _sons: Dictionary[String, AudioStreamPlayer] = {}
var _tempo_sem_progresso := 0.0
var _seguindo := false
var em_festa := false
var pode_recomecar := false
var _botao_jogar: Sprite2D
var _tempo := 0.0

# modo de teste automático
var _auto := false
var _pasta_capturas := ""
var _auto_falhas: Array[String] = []
var _auto_errado_feito := false
var _auto_ultima_pos := Vector2.ZERO
var _auto_preso := 0.0
var _auto_desvio := 0.0
var _auto_desvio_dir := Vector2.ZERO
var _auto_marcos: Dictionary[String, bool] = {}
## Sobrevive ao recarregar a cena: o teste aperta "jogar de novo" e confere a volta.
static var _auto_conferir_recomeco := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var pedidos: Dictionary[String, String] = {}
	for m: Dictionary in MONSTROS:
		pedidos[m["id"]] = m["item"]
	estado = EstadoMissao.new(pedidos)

	_montar_ceu_e_castelo()
	_montar_chao()
	_mundo = Node2D.new()
	_mundo.y_sort_enabled = true
	add_child(_mundo)
	_montar_bordas()
	_montar_enfeites()
	_montar_personagens()
	_montar_vagalumes()
	_montar_audio()
	_montar_interface()

	guia = Guia.new()
	add_child(guia)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(LARGURA)
	camera.limit_bottom = int(ALTURA)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	camera.global_position = INICIO + Vector2(0, -60)
	camera.zoom = Vector2.ONE * 0.62
	add_child(camera)
	camera.make_current()
	_abertura()

	var args := OS.get_cmdline_user_args()
	_auto = args.has("--autoplay")
	for a: String in args:
		if a.begins_with("--capturas="):
			_pasta_capturas = a.split("=", true, 1)[1]
	if _auto:
		jogador.automatico = true
		if _auto_conferir_recomeco:
			_conferir_recomeco()
			return
		print("AUTOPLAY: começando")
		var controles: Array[String] = []
		for id: int in Input.get_connected_joypads():
			controles.append("%d=%s" % [id, Input.get_joy_name(id)])
		print("AUTOPLAY: controles conectados: %s" % (", ".join(controles) if controles else "nenhum"))


## Começa mostrando o jardim inteiro com os monstros e seus balões, depois
## aproxima da criança. Ela já pode andar durante a abertura.
func _abertura() -> void:
	var t := create_tween()
	t.tween_interval(2.4)
	t.tween_callback(func() -> void: _seguindo = true)
	t.tween_property(camera, "zoom", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------------------------------------------------------------- partida

func _physics_process(delta: float) -> void:
	_tempo += delta
	if _auto:
		_pilotar(delta)
	if em_festa:
		if pode_recomecar and Input.is_action_just_pressed("acao"):
			recomecar()
		return
	_checar_interacoes()
	_atualizar_guia(delta)
	for m: Monstro in monstros.values():
		m.marcar_farol(estado.carregando != "" and estado.carregando == m.item_id)


func _process(_delta: float) -> void:
	if _seguindo:
		camera.global_position = jogador.global_position + Vector2(0, -110)
	if _botao_jogar and _botao_jogar.visible:
		_botao_jogar.scale = Vector2.ONE * (1.0 + 0.08 * sin(_tempo * 5.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sair"):
		get_tree().quit()


func _checar_interacoes() -> void:
	var p := jogador.global_position
	if estado.carregando == "":
		for item_id: String in estado.itens_no_chao():
			var item := itens[item_id]
			if p.distance_to(item.global_position) < RAIO_ITEM:
				estado.pegar(item_id)
				item.ao_pegar()
				jogador.segurar(item)
				_tocar("pegar")
				_progresso()
				_marco("pegou")
				break
	for m: Monstro in monstros.values():
		if m.ajudado or p.distance_to(m.global_position) > RAIO_MONSTRO:
			continue
		if estado.carregando == m.item_id:
			var item := jogador.soltar_na_mao()
			estado.entregar(m.id)
			m.receber(item)
			_tocar("entregar")
			_progresso()
			_marco("entregou")
			if estado.todos_ajudados():
				_comecar_festa()
			return
		if m.lembrar_pedido():
			_tocar("hum")


func _progresso() -> void:
	_tempo_sem_progresso = 0.0
	guia.parar()


func _atualizar_guia(delta: float) -> void:
	_tempo_sem_progresso += delta
	if _tempo_sem_progresso < ESPERA_GUIA:
		return
	var origem := jogador.global_position + Vector2(0, -170)
	var alvo := alvo_atual() + Vector2(0, -130)
	if not guia.ativo():
		_tocar("brilho")
	guia.guiar(origem, alvo)
	guia.atualizar_origem(origem)


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


func _comecar_festa() -> void:
	em_festa = true
	guia.parar()
	_musica.stream = _laco("res://sons/musica_festa.wav")
	_musica.play()
	for m: Monstro in monstros.values():
		m.dancar()
	_seguindo = false
	var t := create_tween()
	t.tween_interval(1.2)
	t.tween_property(camera, "global_position", INICIO + Vector2(0, -80), 1.6).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(camera, "zoom", Vector2.ONE * 0.62, 1.6).set_trans(Tween.TRANS_SINE)
	var chuva := get_node("Interface/Chuva") as CPUParticles2D
	chuva.emitting = true
	var mostrar := create_tween()
	mostrar.tween_interval(3.6)
	mostrar.tween_callback(_mostrar_botao_jogar)
	_marco("festa")


func _mostrar_botao_jogar() -> void:
	_botao_jogar.visible = true
	_botao_jogar.modulate.a = 0.0
	create_tween().tween_property(_botao_jogar, "modulate:a", 1.0, 0.5)
	pode_recomecar = true
	_marco("pode_recomecar")


func recomecar() -> void:
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- montagem do mundo

func _montar_ceu_e_castelo() -> void:
	var ceu := Polygon2D.new()
	ceu.polygon = PackedVector2Array([Vector2(0, 0), Vector2(LARGURA, 0), Vector2(LARGURA, CHAO_TOPO + 40), Vector2(0, CHAO_TOPO + 40)])
	var topo := Color("#2a2357")
	var horizonte := Color("#7a5fa8")
	ceu.vertex_colors = PackedColorArray([topo, topo, horizonte, horizonte])
	add_child(ceu)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 70:
		var estrela := Visual.luz(Color(1, 1, 0.9, rng.randf_range(0.4, 0.9)), rng.randf_range(10.0, 26.0))
		estrela.position = Vector2(rng.randf_range(0, LARGURA), rng.randf_range(20, CHAO_TOPO - 120))
		add_child(estrela)
	var lua := Sprite2D.new()
	lua.texture = load("res://arte/lua.svg") as Texture2D
	lua.position = Vector2(2720, 190)
	add_child(lua)
	var castelo := Visual.sprite_em_pe(load("res://arte/castelo.svg") as Texture2D)
	castelo.position = Vector2(LARGURA * 0.5, CHAO_TOPO + 30)
	add_child(castelo)


func _montar_chao() -> void:
	var grama := Polygon2D.new()
	grama.polygon = PackedVector2Array([Vector2(0, CHAO_TOPO), Vector2(LARGURA, CHAO_TOPO), Vector2(LARGURA, ALTURA), Vector2(0, ALTURA)])
	var g1 := Color("#4f9160")
	var g2 := Color("#3f7d55")
	grama.vertex_colors = PackedColorArray([g2, g2, g1, g1])
	add_child(grama)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 26:
		var mancha := Visual.sombra(rng.randf_range(260, 520))
		mancha.color = Color(0.45, 0.7, 0.45, 0.18)
		mancha.position = Vector2(rng.randf_range(100, LARGURA - 100), rng.randf_range(CHAO_TOPO + 80, ALTURA - 60))
		add_child(mancha)
	for m: Dictionary in MONSTROS:
		_caminho(INICIO, m["pos"])
	_caminho(Vector2(700, 880), Vector2(LARGURA * 0.5, CHAO_TOPO + 40))
	_caminho(Vector2(2500, 880), Vector2(LARGURA * 0.5, CHAO_TOPO + 40))
	# poças de luz quente: o jardim é noite, mas nunca escuro
	for pos: Vector2 in [INICIO, Vector2(700, 880), Vector2(2500, 880), Vector2(640, 1690), Vector2(2560, 1690)]:
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
	for r: Rect2 in [Rect2(-200, 0, LARGURA + 400, CHAO_TOPO + 20), Rect2(-200, ALTURA - 20, LARGURA + 400, 200),
			Rect2(-200, 0, 240, ALTURA), Rect2(LARGURA - 40, 0, 240, ALTURA)]:
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
	while x < LARGURA:
		_enfeite(arbusto, Vector2(x, ALTURA + 30), 0.0)
		x += 260.0
	var y := CHAO_TOPO + 160.0
	while y < ALTURA:
		_enfeite(arbusto, Vector2(30, y), 0.0)
		_enfeite(arbusto, Vector2(LARGURA - 30, y), 0.0)
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
	jogador = Jogador.new()
	jogador.position = INICIO
	_mundo.add_child(jogador)


func _montar_vagalumes() -> void:
	var v := CPUParticles2D.new()
	v.texture = Visual.textura_brilho()
	v.amount = 46
	v.lifetime = 7.0
	v.preprocess = 7.0
	v.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	v.emission_rect_extents = Vector2(LARGURA * 0.5, (ALTURA - CHAO_TOPO) * 0.5)
	v.position = Vector2(LARGURA * 0.5, (ALTURA + CHAO_TOPO) * 0.5)
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


func _montar_audio() -> void:
	_musica = AudioStreamPlayer.new()
	_musica.stream = _laco("res://sons/musica_noite.wav")
	_musica.volume_db = -9.0
	add_child(_musica)
	_musica.play()
	for nome: String in ["pegar", "entregar", "hum", "brilho"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://sons/%s.wav" % nome) as AudioStream
		p.volume_db = -5.0
		add_child(p)
		_sons[nome] = p


func _laco(caminho: String) -> AudioStreamWAV:
	var s := (load(caminho) as AudioStreamWAV).duplicate() as AudioStreamWAV
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	return s


func _tocar(nome: String) -> void:
	_sons[nome].play()


func _montar_interface() -> void:
	var ui := CanvasLayer.new()
	ui.name = "Interface"
	add_child(ui)
	var chuva := CPUParticles2D.new()
	chuva.name = "Chuva"
	chuva.texture = Visual.textura_confete()
	chuva.amount = 160
	chuva.lifetime = 4.0
	chuva.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	chuva.emission_rect_extents = Vector2(1000, 10)
	chuva.position = Vector2(960, -40)
	chuva.direction = Vector2(0, 1)
	chuva.spread = 25.0
	chuva.gravity = Vector2(0, 160)
	chuva.initial_velocity_min = 80.0
	chuva.initial_velocity_max = 220.0
	chuva.angular_velocity_min = -300.0
	chuva.angular_velocity_max = 300.0
	chuva.scale_amount_min = 1.0
	chuva.scale_amount_max = 1.8
	chuva.color_initial_ramp = Visual.gradiente_festa()
	chuva.emitting = false
	ui.add_child(chuva)
	_botao_jogar = Sprite2D.new()
	_botao_jogar.texture = load("res://arte/jogar.svg") as Texture2D
	_botao_jogar.position = Vector2(960, 860)
	_botao_jogar.visible = false
	ui.add_child(_botao_jogar)


# ---------------------------------------------------------------- teste automático

func _pilotar(delta: float) -> void:
	if _tempo > 240.0:
		_auto_fim(["tempo esgotado: a partida não terminou em 240s"])
		return
	if em_festa:
		jogador.direcao_forcada = Vector2.ZERO
		return
	# fica parado no começo pra provar que o vaga-lume aparece sozinho
	if _tempo < ESPERA_GUIA + 1.5:
		jogador.direcao_forcada = Vector2.ZERO
		if _tempo > 2.0:
			_marco("inicio")
		if guia.ativo():
			_marco("guia")
		return
	if not _auto_marcos.has("guia"):
		_auto_falhas.append("o vaga-lume não apareceu depois de %ss parado" % ESPERA_GUIA)
		_auto_marcos["guia"] = true

	var alvo := alvo_atual()
	# na primeira vez com item na mão, passa num monstro ERRADO de propósito
	if estado.carregando != "" and not _auto_errado_feito:
		for m: Monstro in monstros.values():
			if not m.ajudado and m.item_id != estado.carregando:
				alvo = m.global_position
				if jogador.global_position.distance_to(alvo) < RAIO_MONSTRO - 20.0:
					_auto_errado_feito = true
					if estado.carregando == "":
						_auto_falhas.append("entregar pro monstro errado tirou o item da mão")
					_marco("errado")
				break

	var dir := (alvo - jogador.global_position).normalized()
	if _auto_desvio > 0.0:
		_auto_desvio -= delta
		dir = _auto_desvio_dir
	elif jogador.global_position.distance_to(_auto_ultima_pos) < 1.0:
		_auto_preso += delta
		if _auto_preso > 0.4:
			_auto_preso = 0.0
			_auto_desvio = 0.6
			print("AUTOPLAY: travou perto de %s — tem obstáculo no caminho" % jogador.global_position.round())
			_auto_desvio_dir = Vector2(-dir.y, dir.x) * (1.0 if randf() < 0.5 else -1.0)
	else:
		_auto_preso = 0.0
	_auto_ultima_pos = jogador.global_position
	jogador.direcao_forcada = dir


func _marco(nome: String) -> void:
	if not _auto or _auto_marcos.has(nome):
		return
	_auto_marcos[nome] = true
	print("AUTOPLAY: %s (t=%.1fs, ajudados=%d)" % [nome, _tempo, estado.quantos_ajudados()])
	# guia e botão entram com fade: fotografa depois que já apareceram de verdade
	var atraso := {"guia": 1.6, "pegou": 0.5, "entregou": 0.9, "festa": 3.0, "errado": 0.2, "pode_recomecar": 1.2}
	_capturar.call_deferred(nome, float(atraso.get(nome, 0.0)))
	if nome == "pode_recomecar":
		var t := create_tween()
		t.tween_interval(2.2)
		t.tween_callback(_apertar_jogar_de_novo)


func _capturar(nome: String, atraso: float) -> void:
	if _pasta_capturas == "":
		return
	if atraso > 0.0:
		await get_tree().create_timer(atraso).timeout
	await RenderingServer.frame_post_draw
	var ordem := ["inicio", "guia", "pegou", "errado", "entregou", "festa", "pode_recomecar"].find(nome)
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [_pasta_capturas, ordem + 1, nome])


## Aperta o botão A pelo caminho de entrada real, como um controle (o nº 1).
func _apertar_jogar_de_novo() -> void:
	var falhas := _falhas_da_partida([])
	if not falhas.is_empty():
		_sair_com(falhas)
		return
	_auto_conferir_recomeco = true
	var botao := InputEventJoypadButton.new()
	botao.device = 1
	botao.button_index = JOY_BUTTON_A
	botao.pressed = true
	Input.parse_input_event(botao)
	var espera := get_tree().create_timer(3.0)
	espera.timeout.connect(func() -> void: _sair_com(["apertar o botão A na festa não recomeçou o jogo"]))


func _conferir_recomeco() -> void:
	var solta := InputEventJoypadButton.new()
	solta.device = 1
	solta.button_index = JOY_BUTTON_A
	solta.pressed = false
	Input.parse_input_event(solta)
	var falhas: Array = []
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
		print("AUTOPLAY OK: partida completa e recomeço conferido")
		get_tree().quit(0)
	else:
		_sair_com(falhas)


func _falhas_da_partida(extras: Array) -> Array:
	var falhas: Array = _auto_falhas + extras
	if not estado.todos_ajudados():
		falhas.append("nem todos os monstros foram ajudados (%d/4)" % estado.quantos_ajudados())
	for obrigatorio: String in ["guia", "pegou", "errado", "entregou", "festa", "pode_recomecar"]:
		if not _auto_marcos.has(obrigatorio):
			falhas.append("não passou pelo momento: %s" % obrigatorio)
	return falhas


func _auto_fim(extras: Array) -> void:
	_sair_com(_falhas_da_partida(extras))


func _sair_com(falhas: Array) -> void:
	if falhas.is_empty():
		print("AUTOPLAY OK: partida completa em %.1fs" % _tempo)
		get_tree().quit(0)
		return
	for f: Variant in falhas:
		print("AUTOPLAY FALHA: %s" % f)
	get_tree().quit(1)
