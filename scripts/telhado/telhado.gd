class_name Telhado
extends FaseDeSalas
## Fase 5: o telhado das estrelas, no topo da torre do cemitério. Um terraço
## no meio e 4 telhadinhos em volta (muretas = paredes, pontezinhas = vãos com
## portão). A festa no céu fecha o jogo: botão de jogar → jardim.
##
##                 [Constelações]
##                       | azul
##   [Estrelas]=====[ TERRAÇO ]==verde==[Planetinhas]
##   aberta              | laranja
##                  [Ovelhinhas]
##
## Mesma geometria do cemitério (que já funciona com a rota e o piloto).

const W := Cemiterio.W
const H := Cemiterio.H
const SALAO := Cemiterio.SALAO
const AREAS := {
	"estrelas": Cemiterio.AREAS["lapides"],
	"planetas": Cemiterio.AREAS["horta"],
	"constelacoes": Cemiterio.AREAS["labirinto"],
	"ovelhas": Cemiterio.AREAS["arena"],
}
const VAOS := {
	"estrelas": Cemiterio.VAOS["lapides"],
	"planetas": Cemiterio.VAOS["horta"],
	"constelacoes": Cemiterio.VAOS["labirinto"],
	"ovelhas": Cemiterio.VAOS["arena"],
}
## cada área entra aqui quando fica pronta
const ORDEM: Array[String] = ["estrelas"]
const CHAVE_DA_SALA := {"estrelas": "azul", "constelacoes": "verde", "planetas": "laranja"}
const PORTAS := {"constelacoes": "azul", "planetas": "verde", "ovelhas": "laranja"}
const CORES_PORTA := {"constelacoes": Color("#4aa3ff"), "planetas": Color("#5bd17a"), "ovelhas": Color("#ff9f43")}
const ALCAPAO := Vector2(1700, 1330)
const TELHA := Color("#4f5d94")
const TELHA_LINHA := Color("#475489")

var ceu: Ceu


func configurar_mapa() -> void:
	largura = W
	altura = H
	inicio = Vector2(1700, 1460)
	espera_guia = 14.0
	musica_inicial = "res://sons/musica_telhado.wav"
	zoom_abertura = 0.62
	salao = SALAO
	areas = AREAS
	vaos = VAOS
	paredes = Cemiterio.PAREDES
	ordem = ORDEM.duplicate()
	cores_porta = CORES_PORTA
	cor_fundo = Color(0, 0, 0, 0)  # transparente: o céu aparece entre os telhadinhos
	cor_parede = Color("#8a93b8")
	cor_face = Color("#a9b1d1")
	estado = EstadoSalas.new(ordem, CHAVE_DA_SALA, PORTAS)
	ceu = Ceu.new()
	add_child(ceu)
	# chegou aqui: todas as passagens até o telhado ficam abertas nas próximas
	for fase: String in ["castelo", "laboratorio", "cemiterio", "telhado"]:
		Jogo.progresso.marcar(fase)


func nova_atividade(id: String) -> Atividade:
	match id:
		"estrelas":
			return EstrelasCadentes.new()
	return null


func decorar() -> void:
	piso(SALAO, Color("#5d6aa0"), Color("#55629a"), false)
	for id: String in AREAS:
		if not ordem.has(id):
			piso(AREAS[id], TELHA, TELHA_LINHA, false)  # telhadinho ainda sem brincadeira
	# alçapão por onde ele chega, subindo a escada da torre
	var alcapao := Sprite2D.new()
	alcapao.texture = load("res://arte/alcapao_aberto.svg") as Texture2D
	alcapao.position = ALCAPAO
	no_chao(alcapao)
	for pos: Vector2 in [Vector2(1580, 1280), Vector2(2620, 1280), Vector2(1580, 2120), Vector2(2620, 2120)]:
		var ch := Visual.sprite_em_pe(load("res://arte/chamine.svg") as Texture2D)
		ch.position = pos
		no_mundo(ch)
	for pos: Vector2 in [Vector2(1900, 1300), Vector2(2300, 2100), Vector2(1560, 1950), Vector2(2640, 1450)]:
		enfeite("lanterninha", pos, Vector2.ZERO)
		var luz := Visual.luz(Color(1.0, 0.8, 0.55, 0.3), 420.0)
		luz.position = pos + Vector2(0, -120)
		add_child(luz)
	if estado.todas_salas():
		festa_final.call_deferred()  # (sem áreas ainda: vai direto pra festa)


## Festa no céu: todos no terraço, constelações acesas e fogos de estrelinha.
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
	ceu.festa()
	comecar_festa(SALAO.get_center() + Vector2(0, -60), true)
	marco("festa_telhado", 4.0)


func ao_recomecar() -> void:
	Jogo.trocar_fase(Jogo.JARDIM)


# ---------------------------------------------------------------- teste automático

func iniciar_auto() -> void:
	print("AUTOPLAY: começando no telhado")
	var sala := sala_pedida()
	if sala != "":
		_pular_ate.call_deferred(sala, SALAO)


func tempo_limite_auto() -> float:
	return 600.0


func pilotar_auto(delta: float) -> Vector2:
	if _tempo > 2.0:
		marco("inicio_telhado", 0.0)
	if em_festa:
		return Vector2.ZERO
	if esperar_guia_auto():
		return Vector2.ZERO
	# encosta uma vez de propósito no portão azul trancado (balança, nada se perde)
	if not tem_marco("trancada") and portas.has("constelacoes") and not estado.porta_aberta("constelacoes"):
		return andar_ate(portas["constelacoes"].ponto + Vector2(0, 110), delta)
	var alvo := alvo_auto()
	depurar_auto(alvo)
	return andar_ate(alvo, delta)


func marcos_obrigatorios() -> Array[String]:
	if sala_pedida() != "":
		return ["festa_telhado", "pode_recomecar"]
	return ["inicio_telhado", "guia", "estrela_1", "estrela_6", "estrelas", "chave_azul", "festa_telhado", "pode_recomecar"]
