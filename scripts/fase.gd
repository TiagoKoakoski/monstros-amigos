class_name Fase
extends Node2D
## Base comum das fases (jardim, castelo): criança, câmera, vaga-lume, sons,
## festa com confete e o modo de teste automático.
##
## A fase filha monta o cenário em montar() e diz para onde ir em alvo_atual().
## Modo de teste: godot --path . -- --autoplay --capturas=/pasta

const RAIO_MONSTRO := 175.0
const RAIO_ITEM := 115.0

## preencher em montar()
var largura := 3200.0
var altura := 2000.0
var inicio := Vector2(1600, 1300)
var espera_guia := 5.0
var musica_inicial := "res://sons/musica_noite.wav"
var zoom_abertura := 0.62

var jogador: Jogador
var camera: Camera2D
var guia: Guia
var em_festa := false
var pode_recomecar := false

var _mundo: Node2D
var _musica: AudioStreamPlayer
var _sons: Dictionary[String, AudioStreamPlayer] = {}
var _tempo_sem_progresso := 0.0
var _seguindo := false
var _botao_jogar: Sprite2D
var _tempo := 0.0

# modo de teste automático
var _auto_falhas: Array[String] = []
var _auto_marcos: Dictionary[String, bool] = {}
var _auto_ultima_pos := Vector2.ZERO
var _auto_preso := 0.0
var _auto_desvio := 0.0
var _auto_desvio_dir := Vector2.ZERO
var _auto_travadas := 0
var _saindo := false
var _pronta := false


func _ready() -> void:
	if not Jogo.ja_iniciou:
		Jogo.ja_iniciou = true
		if scene_file_path != Jogo.fase_inicial():
			Jogo.trocar_fase.call_deferred(Jogo.fase_inicial())
			return
	_pronta = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_mundo = Node2D.new()
	_mundo.y_sort_enabled = true
	_montar_audio()
	_montar_interface()
	jogador = Jogador.new()
	jogador.automatico = Jogo.auto
	montar()
	if _mundo.get_parent() == null:
		add_child(_mundo)
	if jogador.get_parent() == null:
		jogador.position = inicio
		_mundo.add_child(jogador)

	guia = Guia.new()
	add_child(guia)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(largura)
	camera.limit_bottom = int(altura)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	camera.global_position = inicio + Vector2(0, -60)
	camera.zoom = Vector2.ONE * zoom_abertura
	add_child(camera)
	camera.make_current()
	_abertura()
	if Jogo.auto:
		iniciar_auto()


# ---------------------------------------------------------------- para a fase filha

## Monta cenário e personagens. Use _mundo (com y-sort) para o que tem altura.
func montar() -> void:
	pass


## Para onde a criança deveria ir agora (o vaga-lume voa até lá).
func alvo_atual() -> Vector2:
	return inicio


## Chamado todo frame de física (também durante a festa).
func checar_interacoes() -> void:
	pass


## O vaga-lume pode aparecer agora?
func guia_ligado() -> bool:
	return not em_festa


## Chamado todo frame de física depois das interações.
func depois_do_frame() -> void:
	pass


## Botão apertado na festa, depois que o botão de jogar apareceu.
func ao_recomecar() -> void:
	Jogo.trocar_fase(scene_file_path)


## Para onde o piloto automático anda (padrão: o mesmo alvo do vaga-lume).
func alvo_auto() -> Vector2:
	return alvo_atual()


## Direção do piloto automático neste frame.
func pilotar_auto(delta: float) -> Vector2:
	return andar_ate(alvo_auto(), delta)


func iniciar_auto() -> void:
	pass


func tempo_limite_auto() -> float:
	return 240.0


## Conferências do fim da partida automática (devolve as falhas).
func verificar_fim_auto() -> Array[String]:
	return []


# ---------------------------------------------------------------- partida

func _physics_process(delta: float) -> void:
	if not _pronta:
		return
	_tempo += delta
	if Jogo.auto and not _saindo:
		if _tempo > tempo_limite_auto():
			falha_auto("tempo esgotado: a fase não terminou em %ds" % int(tempo_limite_auto()))
			sair_auto()
			return
		jogador.direcao_forcada = Vector2.ZERO if (em_festa and pode_recomecar) else pilotar_auto(delta)
	if em_festa and pode_recomecar and Input.is_action_just_pressed("acao"):
		ao_recomecar()
		return
	checar_interacoes()
	if guia_ligado():
		_atualizar_guia(delta)
	elif guia.ativo():
		guia.parar()
	depois_do_frame()


func _process(_delta: float) -> void:
	if not _pronta:
		return
	if _seguindo:
		camera.global_position = jogador.global_position + Vector2(0, -110)
	if _botao_jogar and _botao_jogar.visible:
		_botao_jogar.scale = Vector2.ONE * (1.0 + 0.08 * sin(_tempo * 5.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sair"):
		get_tree().quit()


## Começa mostrando a fase de longe, depois aproxima da criança.
## Ela já pode andar durante a abertura.
func _abertura() -> void:
	var t := create_tween()
	t.tween_interval(2.4)
	t.tween_callback(func() -> void: _seguindo = true)
	t.tween_property(camera, "zoom", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func progresso_feito() -> void:
	_tempo_sem_progresso = 0.0
	guia.parar()


func _atualizar_guia(delta: float) -> void:
	_tempo_sem_progresso += delta
	if _tempo_sem_progresso < espera_guia:
		return
	var origem := jogador.global_position + Vector2(0, -170)
	var alvo := alvo_atual() + Vector2(0, -130)
	if not guia.ativo():
		tocar("brilho")
		marco("guia", 1.6)
	guia.guiar(origem, alvo)
	guia.atualizar_origem(origem)


## Festa: música, confete, câmera abre em `foco`. Com mostrar_botao, o botão
## de jogar aparece depois e qualquer botão chama ao_recomecar().
func comecar_festa(foco: Vector2, mostrar_botao: bool) -> void:
	em_festa = true
	guia.parar()
	trocar_musica("res://sons/musica_festa.wav")
	_seguindo = false
	var t := create_tween()
	t.tween_interval(1.2)
	t.tween_property(camera, "global_position", foco, 1.6).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(camera, "zoom", Vector2.ONE * 0.62, 1.6).set_trans(Tween.TRANS_SINE)
	var chuva := get_node("Interface/Chuva") as CPUParticles2D
	chuva.emitting = true
	if mostrar_botao:
		var mostrar := create_tween()
		mostrar.tween_interval(3.6)
		mostrar.tween_callback(_mostrar_botao_jogar)


## Volta a câmera a seguir a criança (depois de uma festa que não termina a fase).
func seguir_jogador() -> void:
	_seguindo = true
	create_tween().tween_property(camera, "zoom", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)


func _mostrar_botao_jogar() -> void:
	_botao_jogar.visible = true
	_botao_jogar.modulate.a = 0.0
	create_tween().tween_property(_botao_jogar, "modulate:a", 1.0, 0.5)
	pode_recomecar = true
	marco("pode_recomecar", 1.2)


# ---------------------------------------------------------------- som e interface

func _montar_audio() -> void:
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = -9.0
	add_child(_musica)
	for nome: String in ["pegar", "entregar", "hum", "brilho"]:
		carregar_som(nome)
	trocar_musica.call_deferred(musica_inicial)


func carregar_som(nome: String) -> void:
	if _sons.has(nome):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load("res://sons/%s.wav" % nome) as AudioStream
	p.volume_db = -5.0
	add_child(p)
	_sons[nome] = p


func tocar(nome: String) -> void:
	if not _sons.has(nome):
		carregar_som(nome)
	_sons[nome].play()


func trocar_musica(caminho: String) -> void:
	_musica.stream = _laco(caminho)
	_musica.play()


func _laco(caminho: String) -> AudioStreamWAV:
	var s := (load(caminho) as AudioStreamWAV).duplicate() as AudioStreamWAV
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	return s


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


func interface() -> CanvasLayer:
	return get_node("Interface") as CanvasLayer


# ---------------------------------------------------------------- teste automático

## Anda até `alvo` e, se travar num obstáculo, desvia de lado por um tempo.
func andar_ate(alvo: Vector2, delta: float) -> Vector2:
	var para := alvo - jogador.global_position
	if para.length() < 8.0:
		_auto_ultima_pos = jogador.global_position
		_auto_preso = 0.0
		return Vector2.ZERO
	var dir := para.normalized()
	if _auto_desvio > 0.0:
		_auto_desvio -= delta
		dir = _auto_desvio_dir
	elif jogador.global_position.distance_to(_auto_ultima_pos) < 1.0:
		_auto_preso += delta
		if _auto_preso > 0.4:
			_auto_preso = 0.0
			_auto_desvio = 0.6
			_auto_travadas += 1
			print("AUTOPLAY: travou perto de %s — tem obstáculo no caminho" % jogador.global_position.round())
			_auto_desvio_dir = Vector2(-dir.y, dir.x) * (1.0 if randf() < 0.5 else -1.0)
	else:
		_auto_preso = 0.0
	_auto_ultima_pos = jogador.global_position
	return dir


func marco(nome: String, atraso_foto := 0.0) -> void:
	if not Jogo.auto or _auto_marcos.has(nome):
		return
	_auto_marcos[nome] = true
	print("AUTOPLAY: %s (t=%.1fs)" % [nome, _tempo])
	_capturar.call_deferred(nome, atraso_foto)
	if nome == "pode_recomecar":
		var t := create_tween()
		t.tween_interval(2.2)
		t.tween_callback(_apertar_jogar_de_novo)


func tem_marco(nome: String) -> bool:
	return _auto_marcos.has(nome)


func _capturar(nome: String, atraso: float) -> void:
	if Jogo.pasta_capturas == "":
		return
	var n := Jogo.proxima_foto()
	if atraso > 0.0:
		await get_tree().create_timer(atraso).timeout
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [Jogo.pasta_capturas, n, nome])


func falha_auto(texto: String) -> void:
	_auto_falhas.append(texto)


## Botão A pelo caminho de entrada real, como um controle (o nº 1).
func _apertar_jogar_de_novo() -> void:
	var falhas := _auto_falhas + verificar_fim_auto()
	if not falhas.is_empty():
		_sair_com(falhas)
		return
	Jogo.marcos_globais["conferir_recomeco"] = scene_file_path
	_botao_real(true)
	var espera := get_tree().create_timer(3.0)
	espera.timeout.connect(func() -> void:
		if is_inside_tree():
			_sair_com(["apertar o botão A na festa não recomeçou o jogo"]))


func _botao_real(apertado: bool) -> void:
	var botao := InputEventJoypadButton.new()
	botao.device = 1
	botao.button_index = JOY_BUTTON_A
	botao.pressed = apertado
	Input.parse_input_event(botao)


func soltar_botao_auto() -> void:
	_botao_real(false)


func sair_auto() -> void:
	_sair_com(_auto_falhas + verificar_fim_auto())


func _sair_com(falhas: Array) -> void:
	if _saindo:
		return
	_saindo = true
	if falhas.is_empty():
		print("AUTOPLAY OK: %s" % Jogo.marcos_globais.get("resumo", "partida completa em %.1fs" % _tempo))
		get_tree().quit(0)
		return
	for f: Variant in falhas:
		print("AUTOPLAY FALHA: %s" % f)
	get_tree().quit(1)
