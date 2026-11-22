class_name FaseDeSalas
extends Fase
## Base das fases de salas (castelo, laboratório, ...): um salão no meio e
## salas em volta, cada uma com uma brincadeira (Atividade). Chaves coloridas
## abrem as portas trancadas; o vaga-lume mostra a próxima sala.
##
## A fase filha preenche o mapa em configurar_mapa() e cria as salas em
## nova_atividade(). O resto (paredes, portas, chaveiro, rota, piloto por
## sala e --sala=) é daqui.

## preencher em configurar_mapa()
var salao := Rect2()
var areas: Dictionary = {}
## vãos nas paredes (passagens). As trancadas ganham uma Porta.
var vaos: Dictionary = {}
var paredes: Array = []
var ordem: Array[String] = []
var cores_porta: Dictionary = {}
var cor_fundo := Color("#2a2357")
var cor_parede := Color("#3d3266")
var cor_face := Color("#5a4b8a")
var estado: EstadoSalas

var atividades: Dictionary[String, Atividade] = {}
var portas: Dictionary[String, Porta] = {}
var chaveiro: Chaveiro

var _auto_parado_feito := false
## chão de todas as salas fica aqui embaixo de tudo
var _pisos: Node2D


# ---------------------------------------------------------------- para a fase filha

## Preenche largura/altura/inicio/... e o mapa (salao, areas, vaos, paredes,
## ordem, cores_porta, estado).
func configurar_mapa() -> void:
	pass


func nova_atividade(_id: String) -> Atividade:
	return null


## Chão e enfeites do salão (depois das salas e das paredes).
func decorar() -> void:
	pass


## Todas as salas terminadas.
func festa_final() -> void:
	pass


## Momentos que a partida automática tem que ter passado.
func marcos_obrigatorios() -> Array[String]:
	return []


## Caminho até `alvo` dentro da sala `destino`: sai da sala atual pelo vão
## dela até o salão e entra pelo vão do destino.
func rota(destino: String, alvo: Vector2) -> Vector2:
	var aqui := sala_do_jogador()
	if aqui == destino:
		return alvo
	if aqui != "":
		return _saindo_de(aqui, _passar(vaos[aqui], salao))
	return _passar(vaos[destino], areas[destino])


## Ponto de saída da sala `aqui`, seguindo o caminho de dentro dela.
func _saindo_de(aqui: String, saida: Vector2) -> Vector2:
	if atividades.has(aqui):
		return atividades[aqui].caminho_ate(saida)
	return saida


# ---------------------------------------------------------------- montagem

func montar() -> void:
	configurar_mapa()
	for nome: String in ["porta", "chave", "fechadura"]:
		carregar_som(nome)
	var fundo := Polygon2D.new()
	fundo.polygon = _ret(Rect2(0, 0, largura, altura))
	fundo.color = cor_fundo
	add_child(fundo)
	_pisos = Node2D.new()
	add_child(_pisos)
	for id: String in ordem:
		_criar_atividade(id)
	_paredes()
	add_child(_mundo)
	decorar()
	for id: String in cores_porta:
		if not ordem.has(id):
			continue
		var porta := Porta.new()
		add_child(porta)
		porta.configurar(id, cores_porta[id], vaos[id], _mundo)
		portas[id] = porta
	var ui := interface()
	chaveiro = Chaveiro.new()
	ui.add_child(chaveiro)


func _criar_atividade(id: String) -> void:
	var a := nova_atividade(id)
	a.configurar(self, areas[id])
	add_child(a)
	a.montar()
	a.concluida.connect(_ao_concluir)
	atividades[id] = a


# ---------------------------------------------------------------- serviços pras salas

func no_mundo(no: Node2D) -> void:
	_mundo.add_child(no)


func mao_vazia() -> bool:
	return estado.carregando == ""


## Põe o item na mão. `conta_progresso` falso pra coisas que nunca acabam
## (pegar de novo e de novo não pode calar o vaga-lume).
func dar_na_mao(item: ItemPerdido, id: String, conta_progresso := true) -> bool:
	if not estado.pegar(id):
		return false
	item.ao_pegar()
	jogador.segurar(item)
	tocar("pegar")
	if conta_progresso:
		progresso_feito()
	return true


func tirar_da_mao() -> Node2D:
	estado.soltar()
	return jogador.soltar_na_mao()


func sala_do_jogador() -> String:
	for id: String in areas:
		if (areas[id] as Rect2).has_point(jogador.global_position):
			return id
	return ""


## Posição na tela de algo no mundo (pra chave voar até o chaveiro).
func na_tela(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * p


func piso(r: Rect2, cor: Color, linha: Color, xadrez: bool) -> void:
	var chao := Polygon2D.new()
	chao.polygon = _ret(r)
	chao.color = cor
	_pisos.add_child(chao)
	var lado := 125.0
	if xadrez:
		var y := r.position.y
		var j := 0
		while y < r.end.y:
			var x := r.position.x + (lado if j % 2 == 1 else 0.0)
			while x < r.end.x:
				var q := Polygon2D.new()
				q.polygon = _ret(Rect2(x, y, minf(lado, r.end.x - x), minf(lado, r.end.y - y)))
				q.color = linha
				_pisos.add_child(q)
				x += lado * 2.0
			y += lado
			j += 1
		return
	var x2 := r.position.x + lado
	while x2 < r.end.x:
		_linha(Vector2(x2, r.position.y), Vector2(x2, r.end.y), linha)
		x2 += lado * 1.6
	var y2 := r.position.y + lado
	while y2 < r.end.y:
		_linha(Vector2(r.position.x, y2), Vector2(r.end.x, y2), linha)
		y2 += lado


## Coisa desenhada no chão, embaixo de tudo (tapetes, marcas).
func no_chao(no: Node2D) -> void:
	_pisos.add_child(no)


## Móvel com os pés em `pos` e uma colisão retangular de `base` em volta deles.
func enfeite(nome: String, pos: Vector2, base: Vector2) -> Sprite2D:
	var s := Visual.sprite_em_pe(load("res://arte/%s.svg" % nome) as Texture2D)
	s.position = pos
	_mundo.add_child(s)
	if base != Vector2.ZERO:
		var corpo := StaticBody2D.new()
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = base
		forma.shape = ret
		forma.position = pos - Vector2(0, base.y * 0.5)
		corpo.add_child(forma)
		add_child(corpo)
	return s


## Tocha presa na parede de cima de uma sala (y = linha de baixo da parede).
func tocha(pos: Vector2) -> void:
	var luz := Visual.luz(Color(1.0, 0.8, 0.45, 0.4), 560.0)
	luz.position = pos + Vector2(0, 40)
	luz.scale.y *= 0.7
	add_child(luz)
	var s := Visual.sprite_em_pe(load("res://arte/tocha.svg") as Texture2D)
	s.position = pos + Vector2(0, 10)
	s.z_index = 1
	add_child(s)


func _linha(a: Vector2, b: Vector2, cor: Color) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([a, b])
	l.width = 4.0
	l.default_color = cor
	_pisos.add_child(l)


func _ret(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func _paredes() -> void:
	var corpo := StaticBody2D.new()
	add_child(corpo)
	for r: Rect2 in paredes:
		var p := Polygon2D.new()
		p.polygon = _ret(r)
		p.color = cor_parede
		add_child(p)
		# face clara embaixo das paredes horizontais: dá a ideia de altura
		if r.size.x > r.size.y:
			var face := Polygon2D.new()
			face.polygon = _ret(Rect2(r.position.x, r.end.y - 34, r.size.x, 34))
			face.color = cor_face
			add_child(face)
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = r.size
		forma.shape = ret
		forma.position = r.get_center()
		corpo.add_child(forma)


# ---------------------------------------------------------------- partida

func checar_interacoes() -> void:
	if em_festa:
		return
	var p := jogador.global_position
	for a: Atividade in atividades.values():
		a.checar(p)
	for id: String in portas:
		var porta := portas[id]
		if porta.aberta:
			continue
		porta.brilhar(estado.pode_abrir(id))
		if p.distance_to(porta.ponto) > 160.0:
			continue
		if estado.tentar_abrir(id):
			_abrir_porta(id)
		elif not estado.abre_por_sala(id) and porta.balancar():  # abre por sala: nada de fechadura
			tocar("fechadura")
			marco("trancada", 0.3)


func _abrir_porta(id: String) -> void:
	var porta := portas[id]
	if not estado.abre_por_sala(id):
		chaveiro.usar(estado.cor_da_porta(id))
	porta.abrir()
	tocar("porta")
	progresso_feito()
	marco("abriu_" + id, 0.8)


func _ao_concluir(id: String) -> void:
	var chave := estado.concluir(id)
	progresso_feito()
	if chave != "":
		var de := atividades[id].monstro()
		var origem := na_tela(de.global_position + Vector2(0, -de.altura())) if de else Vector2(960, 540)
		var t := create_tween()
		t.tween_interval(1.0)
		t.tween_callback(func() -> void:
			chaveiro.ganhar(chave, origem)
			tocar("chave"))
		marco("chave_" + chave, 2.2)
	# portas que abrem quando uma sala termina (o quarto do castelo)
	for p: String in portas:
		if estado.abre_por_sala(p) and not portas[p].aberta and estado.tentar_abrir(p):
			portas[p].abrir()
			tocar("porta")
	if estado.todas_salas():
		festa_final()


## Próxima sala a fazer: a primeira (na ordem) que não terminou e que já dá pra entrar.
func proxima_atividade() -> String:
	for id: String in ordem:
		if not atividades.has(id) or atividades[id].terminada():
			continue
		if not portas.has(id) or portas[id].aberta or estado.pode_abrir(id):
			return id
	return ""


func alvo_atual() -> Vector2:
	var na_mao := estado.carregando
	var destino := ""
	if na_mao != "":
		for id: String in atividades:
			if atividades[id].dona_de(na_mao):
				destino = id
	if destino == "":
		var aqui := sala_do_jogador()
		if aqui != "" and atividades.has(aqui) and not atividades[aqui].terminada():
			destino = aqui
		else:
			destino = proxima_atividade()
	if destino == "":
		return salao.get_center()
	return rota(destino, atividades[destino].alvo())


func alvo_auto() -> Vector2:
	var destino := sala_do_jogador()
	if destino == "" or not atividades.has(destino) or atividades[destino].terminada() or estado.carregando != "":
		return alvo_atual()
	return atividades[destino].alvo_auto()


## Um ponto logo depois do vão, já dentro de `lado` (pra atravessar a porta).
func _passar(vao: Rect2, lado: Rect2) -> Vector2:
	var c := vao.get_center()
	var dentro := lado.get_center() - c
	if vao.size.x < vao.size.y:
		dentro = Vector2(signf(dentro.x), 0)
	else:
		dentro = Vector2(0, signf(dentro.y))
	return c + dentro * 140.0


# ---------------------------------------------------------------- teste automático

func sala_pedida() -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--sala="):
			return a.split("=")[1]
	return ""


## Só pra testar uma sala: dá as salas anteriores por feitas e leva a criança
## até a porta da sala pedida (`de_onde`: o lado de fora do vão).
func _pular_ate(sala: String, de_onde: Rect2) -> void:
	for id: String in ordem:
		if id == sala:
			break
		atividades[id].terminar()
		for p: String in portas:
			if estado.tentar_abrir(p):
				portas[p].abrir()
	_auto_parado_feito = true
	_auto_marcos["trancada"] = true
	_auto_marcos["guia"] = true
	jogador.global_position = _passar(vaos[sala], de_onde)
	print("AUTOPLAY: pulou até %s" % sala)


## Fica parado até o vaga-lume aparecer. true enquanto está esperando.
func esperar_guia_auto() -> bool:
	if _auto_parado_feito:
		return false
	if guia.ativo():
		_auto_parado_feito = true
	elif _tempo > espera_guia + 2.0:
		falha_auto("o vaga-lume não apareceu depois de %ss parado" % espera_guia)
		_auto_parado_feito = true
	return not _auto_parado_feito


func depurar_auto(alvo: Vector2) -> void:
	if OS.get_cmdline_user_args().has("--depurar") and int(_tempo * 60) % 90 == 0:
		print("DBG p=%s alvo=%s sala=%s prox=%s mao=%s" % [jogador.global_position.round(), alvo.round(), sala_do_jogador(), proxima_atividade(), estado.carregando])


func verificar_fim_auto() -> Array[String]:
	var falhas: Array[String] = []
	for obrigatorio: String in marcos_obrigatorios():
		if not tem_marco(obrigatorio):
			falhas.append("não passou pelo momento: %s" % obrigatorio)
	for id: String in atividades:
		if not atividades[id].terminada():
			falhas.append("sala não terminada: %s" % id)
	if _auto_travadas > 25:
		falhas.append("travou %d vezes em obstáculos" % _auto_travadas)
	return falhas
