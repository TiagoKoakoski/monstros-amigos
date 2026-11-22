class_name Castelo
extends Fase
## Fase 2: dentro do castelo. Um salão no meio e salas em volta, cada uma com
## uma brincadeira. Chaves coloridas abrem as portas trancadas.
##
##    [Música]  [Biblioteca]        Cozinha e Música: abertas
##       |         | azul           Cozinha -> chave azul (Biblioteca)
##  [Corredor]=[ SALÃO ]=[Cozinha]   Música  -> chave vermelha (Corredor)
##   verm. |                        Corredor das caixas -> abre o Quarto
##  [Quarto]

const W := 3600.0
const H := 2900.0
const PAREDE := Color("#3d3266")
const FACE := Color("#5a4b8a")

const SALAO := Rect2(1200, 1000, 1200, 900)
const AREAS := {
	"cozinha": Rect2(2500, 1000, 1000, 900),
	"musica": Rect2(100, 100, 1500, 800),
	"biblioteca": Rect2(1700, 100, 1800, 800),
	"caixas": Rect2(100, 1000, 1000, 900),
	"quarto": Rect2(100, 2000, 1000, 800),
}
## vãos nas paredes (passagens). As trancadas ganham uma Porta.
const VAOS := {
	"cozinha": Rect2(2400, 1350, 100, 200),
	"musica": Rect2(1300, 900, 200, 100),
	"biblioteca": Rect2(2000, 900, 200, 100),
	"caixas": Rect2(1100, 1350, 100, 200),
	"quarto": Rect2(500, 1900, 200, 100),
}
const PAREDES := [
	Rect2(0, 0, 3600, 100), Rect2(0, 0, 100, 2900), Rect2(3500, 0, 100, 2000),
	Rect2(0, 900, 1300, 100), Rect2(1500, 900, 500, 100), Rect2(2200, 900, 1400, 100),
	Rect2(1600, 100, 100, 800),
	Rect2(1100, 1000, 100, 350), Rect2(1100, 1550, 100, 350),
	Rect2(2400, 1000, 100, 350), Rect2(2400, 1550, 100, 350),
	Rect2(0, 1900, 500, 100), Rect2(700, 1900, 2900, 100),
	Rect2(0, 2800, 1200, 100), Rect2(1100, 2000, 2500, 900),
]
const ORDEM := ["cozinha", "musica", "biblioteca", "caixas", "quarto"]
const CORES_PORTA := {"biblioteca": Color("#4aa3ff"), "caixas": Color("#ff6f91"), "quarto": Color("#ffd23f")}

var estado: EstadoCastelo
var atividades: Dictionary[String, Atividade] = {}
var portas: Dictionary[String, Porta] = {}
var chaveiro: Chaveiro

var _auto_parado_feito := false
## chão de todas as salas fica aqui embaixo de tudo
var _pisos: Node2D


func montar() -> void:
	largura = W
	altura = H
	inicio = Vector2(1800, 1760)
	espera_guia = 9.0
	musica_inicial = "res://sons/musica_castelo.wav"
	zoom_abertura = 0.62
	estado = EstadoCastelo.new()
	for nome: String in ["porta", "chave", "fechadura"]:
		carregar_som(nome)

	var fundo := Polygon2D.new()
	fundo.polygon = _ret(Rect2(0, 0, W, H))
	fundo.color = Color("#2a2357")
	add_child(fundo)
	_pisos = Node2D.new()
	add_child(_pisos)
	piso(SALAO, Color("#d9c7a4"), Color("#cbb68f"), false)
	_tapete(SALAO.get_center() + Vector2(0, 40), Vector2(760, 460))
	for id: String in ["cozinha", "musica", "biblioteca"]:
		_criar_atividade(id)
	_paredes()
	add_child(_mundo)
	_decorar_salao()
	for id: String in ["biblioteca", "caixas", "quarto"]:
		var porta := Porta.new()
		add_child(porta)
		porta.configurar(id, CORES_PORTA[id], VAOS[id], _mundo)
		portas[id] = porta
	_porta_de_entrada()

	var ui := interface()
	chaveiro = Chaveiro.new()
	ui.add_child(chaveiro)


func _criar_atividade(id: String) -> void:
	var a: Atividade
	match id:
		"cozinha":
			a = Cozinha.new()
		"musica":
			a = Musica.new()
		"biblioteca":
			a = Biblioteca.new()
	a.configurar(self, AREAS[id])
	add_child(a)
	a.montar()
	a.concluida.connect(_ao_concluir)
	atividades[id] = a


# ---------------------------------------------------------------- serviços pras salas

func no_mundo(no: Node2D) -> void:
	_mundo.add_child(no)


func mao_vazia() -> bool:
	return estado.carregando == ""


func dar_na_mao(item: ItemPerdido, id: String) -> bool:
	if not estado.pegar(id):
		return false
	item.ao_pegar()
	jogador.segurar(item)
	tocar("pegar")
	progresso_feito()
	return true


func tirar_da_mao() -> Node2D:
	estado.soltar()
	return jogador.soltar_na_mao()


func sala_do_jogador() -> String:
	for id: String in AREAS:
		if (AREAS[id] as Rect2).has_point(jogador.global_position):
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


func _tapete(centro: Vector2, tamanho: Vector2) -> void:
	for camada: Array in [[1.0, Color("#b0425e")], [0.86, Color("#d9577a")], [0.6, Color("#e9a23b")]]:
		var p := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			pts.append(centro + Vector2(cos(a) * tamanho.x * 0.5, sin(a) * tamanho.y * 0.5) * camada[0])
		p.polygon = pts
		p.color = camada[1]
		_pisos.add_child(p)


func _paredes() -> void:
	var corpo := StaticBody2D.new()
	add_child(corpo)
	for r: Rect2 in PAREDES:
		var p := Polygon2D.new()
		p.polygon = _ret(r)
		p.color = PAREDE
		add_child(p)
		# face clara embaixo das paredes horizontais: dá a ideia de altura
		if r.size.x > r.size.y:
			var face := Polygon2D.new()
			face.polygon = _ret(Rect2(r.position.x, r.end.y - 34, r.size.x, 34))
			face.color = FACE
			add_child(face)
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = r.size
		forma.shape = ret
		forma.position = r.get_center()
		corpo.add_child(forma)


func _decorar_salao() -> void:
	for x: float in [1400.0, 2200.0]:
		tocha(Vector2(x, 1000))
	var abobora := load("res://arte/abobora.svg") as Texture2D
	for pos: Vector2 in [Vector2(1300, 1130), Vector2(2300, 1130), Vector2(1300, 1820), Vector2(2300, 1820)]:
		var s := Visual.sprite_em_pe(abobora)
		s.position = pos
		_mundo.add_child(s)
	for pos: Vector2 in [Vector2(1800, 1450), Vector2(1350, 1450), Vector2(2250, 1450)]:
		var luz := Visual.luz(Color(1.0, 0.85, 0.55, 0.18), 900.0)
		luz.position = pos
		luz.scale.y *= 0.6
		add_child(luz)


## A porta por onde ele entrou: fecha atrás dele (é só enfeite por dentro).
func _porta_de_entrada() -> void:
	var p := Visual.sprite_em_pe(load("res://arte/porta_sala.svg") as Texture2D)
	p.position = Vector2(1800, 2000)
	p.z_index = 1
	add_child(p)
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_callback(func() -> void: tocar("porta"))


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
		elif porta.balancar():
			tocar("fechadura")
			marco("trancada", 0.3)


func _abrir_porta(id: String) -> void:
	var porta := portas[id]
	var cor: String = EstadoCastelo.PORTAS[id]
	chaveiro.usar(cor)
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
	if id == "caixas" and estado.tentar_abrir("quarto"):
		portas["quarto"].abrir()
		tocar("porta")
	if estado.todas_salas():
		_festa_final()


func _festa_final() -> void:
	for a: Atividade in atividades.values():
		if a.monstro():
			a.monstro().dancar()
	comecar_festa(SALAO.get_center(), true)
	marco("festa_castelo", 3.0)


func ao_recomecar() -> void:
	Jogo.trocar_fase(Jogo.JARDIM)


## Próxima sala a fazer: a primeira (na ordem) que não terminou e que já dá pra entrar.
func proxima_atividade() -> String:
	for id: String in ORDEM:
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
		return SALAO.get_center()
	return _rota(destino, atividades[destino].alvo())


func alvo_auto() -> Vector2:
	var destino := sala_do_jogador()
	if destino == "" or not atividades.has(destino) or atividades[destino].terminada() or estado.carregando != "":
		return alvo_atual()
	return atividades[destino].alvo_auto()


## Caminho até `alvo` dentro da sala `destino`: se a criança está em outra
## sala, primeiro sai pela porta dela; o quarto só se chega pelo corredor.
func _rota(destino: String, alvo: Vector2) -> Vector2:
	var aqui := sala_do_jogador()
	if aqui == destino:
		return alvo
	if aqui == "quarto":
		return _passar(VAOS["quarto"], AREAS["caixas"])
	if aqui != "" and not (aqui == "caixas" and destino == "quarto"):
		return _passar(VAOS[aqui], SALAO)
	if destino == "quarto" and aqui != "caixas":
		return _passar(VAOS["caixas"], AREAS["caixas"])
	return _passar(VAOS[destino], AREAS[destino])


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

func iniciar_auto() -> void:
	print("AUTOPLAY: começando no castelo")


func tempo_limite_auto() -> float:
	return 600.0


func pilotar_auto(delta: float) -> Vector2:
	if em_festa:
		return Vector2.ZERO
	if _tempo > 2.0:
		marco("inicio_castelo", 0.0)
	# fica parado até o vaga-lume aparecer (espera mais longa no castelo)
	if not _auto_parado_feito:
		if guia.ativo():
			_auto_parado_feito = true
		elif _tempo > espera_guia + 2.0:
			falha_auto("o vaga-lume do castelo não apareceu depois de %ss parado" % espera_guia)
			_auto_parado_feito = true
		return Vector2.ZERO
	# encosta uma vez de propósito na porta trancada da biblioteca
	if not tem_marco("trancada") and not estado.porta_aberta("biblioteca"):
		return andar_ate(portas["biblioteca"].ponto + Vector2(0, 110), delta)
	return andar_ate(alvo_auto(), delta)


func depois_do_frame() -> void:
	if not Jogo.auto or em_festa or _saindo:
		return
	# enquanto nem todas as salas existem: termina quando as que existem acabaram
	if atividades.size() < ORDEM.size():
		for a: Atividade in atividades.values():
			if not a.terminada():
				return
		if not tem_marco("salas_prontas"):
			marco("salas_prontas")
			get_tree().create_timer(3.0).timeout.connect(sair_auto)


func verificar_fim_auto() -> Array[String]:
	var falhas: Array[String] = []
	for obrigatorio: String in ["inicio_castelo", "guia", "trancada"]:
		if not tem_marco(obrigatorio):
			falhas.append("não passou pelo momento: %s" % obrigatorio)
	for id: String in atividades:
		if not atividades[id].terminada():
			falhas.append("sala não terminada: %s" % id)
	if _auto_travadas > 25:
		falhas.append("travou %d vezes em obstáculos" % _auto_travadas)
	return falhas
