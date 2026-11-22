class_name Cemiterio
extends FaseDeSalas
## Fase 4: o cemitério das abóboras, atrás do castelo. Uma praça no meio e 4
## áreas cercadas por cerca viva (as paredes), com portões que abrem com chave.
##
##                [Labirinto]
##                    | amarelo
##   [Lápides]=====[ PRAÇA ]==roxo==[Horta]
##   aberta           | rosa
##                 [Arena]

const W := 4000.0
const H := 3400.0

const SALAO := Rect2(1500, 1200, 1200, 1000)
const AREAS := {
	"lapides": Rect2(100, 800, 1300, 1800),
	"horta": Rect2(2800, 1200, 1100, 1000),
	"labirinto": Rect2(1500, 100, 1200, 1000),
	"arena": Rect2(1500, 2300, 1200, 1000),
}
const VAOS := {
	"lapides": Rect2(1400, 1600, 100, 200),
	"horta": Rect2(2700, 1600, 100, 200),
	"labirinto": Rect2(1900, 1100, 200, 100),
	"arena": Rect2(2000, 2200, 200, 100),
}
const PAREDES := [
	Rect2(1400, 0, 1400, 100), Rect2(1400, 100, 100, 1500), Rect2(1400, 1800, 100, 1600),
	Rect2(2700, 100, 100, 1500), Rect2(2700, 1800, 100, 1600),
	Rect2(1500, 1100, 400, 100), Rect2(2100, 1100, 600, 100),
	Rect2(1500, 2200, 500, 100), Rect2(2200, 2200, 500, 100), Rect2(1400, 3300, 1400, 100),
	Rect2(0, 700, 1400, 100), Rect2(0, 700, 100, 2000), Rect2(0, 2600, 1400, 100),
	Rect2(2800, 1100, 1200, 100), Rect2(3900, 1100, 100, 1200), Rect2(2800, 2200, 1200, 100),
]
## cada área entra aqui quando fica pronta
const ORDEM: Array[String] = ["lapides", "horta"]
const CHAVE_DA_SALA := {"lapides": "roxa", "horta": "amarela", "labirinto": "rosa"}
const PORTAS := {"horta": "roxa", "labirinto": "amarela", "arena": "rosa"}
const CORES_PORTA := {"horta": Color("#a66bff"), "labirinto": Color("#ffd23f"), "arena": Color("#ff9ecb")}
const GRAMA := Color("#7fb8a0")
const GRAMA_LINHA := Color("#74ad95")


func configurar_mapa() -> void:
	largura = W
	altura = H
	inicio = Vector2(1700, 1460)
	espera_guia = 14.0
	musica_inicial = "res://sons/musica_cemiterio.wav"
	zoom_abertura = 0.62
	salao = SALAO
	areas = AREAS
	vaos = VAOS
	paredes = PAREDES
	ordem = ORDEM.duplicate()
	cores_porta = CORES_PORTA
	cor_fundo = Color("#1f2a4a")
	cor_parede = Color("#3f7a5a")
	cor_face = Color("#5a9a72")
	estado = EstadoSalas.new(ordem, CHAVE_DA_SALA, PORTAS)
	# chegou aqui: as passagens até o cemitério ficam abertas nas próximas
	for fase: String in ["castelo", "laboratorio", "cemiterio"]:
		Jogo.progresso.marcar(fase)
	for nome: String in ["risadinha", "achei"]:
		carregar_som(nome)


func nova_atividade(id: String) -> Atividade:
	match id:
		"lapides":
			return Lapides.new()
		"horta":
			return Horta.new()
	return null


func decorar() -> void:
	piso(SALAO, Color("#cdb48a"), Color("#bfa47a"), false)
	for id: String in AREAS:
		if not ordem.has(id):
			piso(AREAS[id], GRAMA, GRAMA_LINHA, false)  # área ainda sem brincadeira
	# portinha de porão por onde ele chega, vindo do laboratório
	var portinha := Sprite2D.new()
	portinha.texture = load("res://arte/portinha.svg") as Texture2D
	portinha.position = Vector2(1700, 1330)
	no_chao(portinha)
	# escada da torre (o telhado vem depois): enfeite fechado
	var torre := Visual.sprite_em_pe(load("res://arte/escada_torre.svg") as Texture2D)
	torre.position = Vector2(2520, 1300)
	torre.z_index = 1
	add_child(torre)
	for pos: Vector2 in [Vector2(1580, 1260), Vector2(2620, 1500), Vector2(1580, 2120), Vector2(2620, 2120)]:
		enfeite("lanterna", pos, Vector2.ZERO)
		var luz := Visual.luz(Color(1.0, 0.85, 0.5, 0.35), 520.0)
		luz.position = pos + Vector2(0, -150)
		add_child(luz)
	for pos: Vector2 in [Vector2(1800, 2100), Vector2(2400, 2100), Vector2(2300, 1300)]:
		var ab := Visual.sprite_em_pe(load("res://arte/abobora.svg") as Texture2D)
		ab.position = pos
		no_mundo(ab)
	if estado.todas_salas():
		festa_final.call_deferred()  # (sem áreas ainda: vai direto pra festa)


## Todos na praça, dançando.
func festa_final() -> void:
	if em_festa:
		return
	var dancantes: Array[Monstro] = []
	for id: String in ordem:
		var m := atividades[id].monstro()
		if m != null:
			dancantes.append(m)
	var lugares: Array[Vector2] = [Vector2(-380, -60), Vector2(380, -60), Vector2(-220, 140), Vector2(220, 140)]
	for i in dancantes.size():
		var m := dancantes[i]
		var t := create_tween()
		t.tween_interval(0.8 + i * 0.25)
		t.tween_property(m, "global_position", SALAO.get_center() + lugares[i % lugares.size()], 1.8).set_trans(Tween.TRANS_SINE)
		t.tween_callback(m.dancar)
	# os fantasminhas vêm junto e dançam em volta
	if atividades.has("lapides"):
		var filhos := (atividades["lapides"] as Lapides).convidados()
		for j in filhos.size():
			var a := TAU * j / filhos.size()
			var t := create_tween()
			t.tween_interval(1.0 + j * 0.15)
			t.tween_property(filhos[j], "global_position", SALAO.get_center() + Vector2(cos(a) * 520.0, 60.0 + sin(a) * 260.0), 1.8).set_trans(Tween.TRANS_SINE)
	comecar_festa(SALAO.get_center() + Vector2(0, -60), true)
	marco("festa_cemiterio", 4.0)


func ao_recomecar() -> void:
	Jogo.trocar_fase(Jogo.JARDIM)


# ---------------------------------------------------------------- teste automático

func iniciar_auto() -> void:
	print("AUTOPLAY: começando no cemitério")
	var sala := sala_pedida()
	if sala != "":
		_pular_ate.call_deferred(sala, SALAO)


func tempo_limite_auto() -> float:
	return 600.0


func pilotar_auto(delta: float) -> Vector2:
	if em_festa:
		return Vector2.ZERO
	if _tempo > 2.0:
		marco("inicio_cemiterio", 0.0)
	if esperar_guia_auto():
		return Vector2.ZERO
	var alvo := alvo_auto()
	depurar_auto(alvo)
	return andar_ate(alvo, delta)


func marcos_obrigatorios() -> Array[String]:
	if sala_pedida() != "":
		return ["festa_cemiterio", "pode_recomecar"]
	return ["inicio_cemiterio", "guia", "vazio", "lapides", "chave_roxa", "abriu_horta", "hum_horta", "devolveu",
		"horta", "chave_amarela", "festa_cemiterio", "pode_recomecar"]
