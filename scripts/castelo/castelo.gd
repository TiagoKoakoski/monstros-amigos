class_name Castelo
extends FaseDeSalas
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
const ORDEM: Array[String] = ["cozinha", "musica", "biblioteca", "caixas", "quarto"]
const CORES_PORTA := {"biblioteca": Color("#4aa3ff"), "caixas": Color("#ff6f91"), "quarto": Color("#ffd23f")}


func configurar_mapa() -> void:
	largura = W
	altura = H
	inicio = Vector2(1800, 1760)
	espera_guia = 9.0
	musica_inicial = "res://sons/musica_castelo.wav"
	zoom_abertura = 0.62
	salao = SALAO
	areas = AREAS
	vaos = VAOS
	paredes = PAREDES
	ordem = ORDEM
	cores_porta = CORES_PORTA
	cor_fundo = Color("#2a2357")
	cor_parede = Color("#3d3266")
	cor_face = Color("#5a4b8a")
	estado = EstadoCastelo.new()
	Jogo.progresso.marcar_castelo_aberto()  # chegou aqui: a porta fica aberta nas próximas


func nova_atividade(id: String) -> Atividade:
	match id:
		"cozinha":
			return Cozinha.new()
		"musica":
			return Musica.new()
		"biblioteca":
			return Biblioteca.new()
		"caixas":
			return CorredorCaixas.new()
		"quarto":
			return Quarto.new()
	return null


func decorar() -> void:
	piso(SALAO, Color("#d9c7a4"), Color("#cbb68f"), false)
	_tapete(SALAO.get_center() + Vector2(0, 40), Vector2(760, 460))
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
	_porta_de_entrada()


func _tapete(centro: Vector2, tamanho: Vector2) -> void:
	for camada: Array in [[1.0, Color("#b0425e")], [0.86, Color("#d9577a")], [0.6, Color("#e9a23b")]]:
		var p := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			pts.append(centro + Vector2(cos(a) * tamanho.x * 0.5, sin(a) * tamanho.y * 0.5) * camada[0])
		p.polygon = pts
		p.color = camada[1]
		no_chao(p)


## A porta por onde ele entrou: fecha atrás dele (é só enfeite por dentro).
func _porta_de_entrada() -> void:
	var p := Visual.sprite_em_pe(load("res://arte/porta_sala.svg") as Texture2D)
	p.position = Vector2(1800, 2000)
	p.z_index = 1
	add_child(p)
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_callback(func() -> void: tocar("porta"))


## Todos ajudados: os monstros e os filhotes vêm pro salão e dançam.
func festa_final() -> void:
	var lugares: Array[Vector2] = [Vector2(-380, -120), Vector2(-130, -180), Vector2(130, -180), Vector2(380, -120)]
	var i := 0
	for id: String in ORDEM:
		var m := atividades[id].monstro()
		if m == null:
			continue
		var t := create_tween()
		t.tween_interval(0.8 + i * 0.25)
		t.tween_property(m, "global_position", SALAO.get_center() + lugares[i], 1.8).set_trans(Tween.TRANS_SINE)
		t.tween_callback(m.dancar)
		i += 1
	var quarto := atividades["quarto"] as Quarto
	for j in quarto.filhotes.size():
		var f := quarto.filhotes[j]
		var t := create_tween()
		t.tween_interval(1.2 + j * 0.2)
		t.tween_callback(f.acordar)
		t.tween_property(f, "global_position", SALAO.get_center() + Vector2([-470.0, 470.0, -330.0][j], [200.0, 200.0, 330.0][j]), 1.8).set_trans(Tween.TRANS_SINE)
	comecar_festa(SALAO.get_center() + Vector2(0, -60), true)
	marco("festa_castelo", 4.0)


func ao_recomecar() -> void:
	Jogo.trocar_fase(Jogo.JARDIM)


## O quarto só se chega pelo corredor das caixas.
func rota(destino: String, alvo: Vector2) -> Vector2:
	var aqui := sala_do_jogador()
	if aqui == destino:
		return alvo
	if aqui == "quarto":
		return _passar(VAOS["quarto"], AREAS["caixas"])
	if aqui != "" and not (aqui == "caixas" and destino == "quarto"):
		return _passar(VAOS[aqui], SALAO)
	var no_vao_do_quarto := (VAOS["quarto"] as Rect2).grow(60.0).has_point(jogador.global_position)
	if destino == "quarto" and aqui != "caixas" and not no_vao_do_quarto:
		return _passar(VAOS["caixas"], AREAS["caixas"])
	return _passar(VAOS[destino], AREAS[destino])


# ---------------------------------------------------------------- teste automático

func iniciar_auto() -> void:
	print("AUTOPLAY: começando no castelo")
	var sala := sala_pedida()
	if sala != "":
		_pular_ate.call_deferred(sala, SALAO if sala != "quarto" else AREAS["caixas"])


func tempo_limite_auto() -> float:
	return 600.0


func pilotar_auto(delta: float) -> Vector2:
	if em_festa:
		return Vector2.ZERO
	if _tempo > 2.0:
		marco("inicio_castelo", 0.0)
	# fica parado até o vaga-lume aparecer (espera mais longa no castelo)
	if esperar_guia_auto():
		return Vector2.ZERO
	# encosta uma vez de propósito na porta trancada da biblioteca
	if not tem_marco("trancada") and not estado.porta_aberta("biblioteca"):
		return andar_ate(portas["biblioteca"].ponto + Vector2(0, 110), delta)
	var alvo := alvo_auto()
	depurar_auto(alvo)
	return andar_ate(alvo, delta)


func marcos_obrigatorios() -> Array[String]:
	if sala_pedida() != "":
		return ["festa_castelo", "pode_recomecar"]
	return ["inicio_castelo", "guia", "trancada", "cozinha", "chave_azul", "nota_errada", "musica",
		"chave_vermelha", "abriu_biblioteca", "velas", "biblioteca", "abriu_caixas", "borda", "caixas", "filhote",
		"cama", "quarto", "festa_castelo", "pode_recomecar"]
