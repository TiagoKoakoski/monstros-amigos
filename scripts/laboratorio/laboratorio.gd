class_name Laboratorio
extends FaseDeSalas
## Fase 3: o laboratório do Frankenstein, no porão do castelo. A sala da
## máquina no meio e 3 salas em volta. Cada sala terminada acende um cabo da
## máquina; com os 3 acesos ela liga e começa a festa.
##
##   [Poções]=[ MÁQUINA ]=verde=[Canos]
##   aberta        |
##              laranja
##                 |
##             [Formas]

const W := 3800.0
const H := 3000.0

const SALAO := Rect2(1300, 900, 1200, 1000)
const AREAS := {
	"pocoes": Rect2(100, 900, 1100, 1000),
	"canos": Rect2(2600, 700, 1100, 1400),
	"formas": Rect2(1300, 2000, 1200, 900),
}
const VAOS := {
	"pocoes": Rect2(1200, 1300, 100, 200),
	"canos": Rect2(2500, 1300, 100, 200),
	"formas": Rect2(1800, 1900, 200, 100),
}
const PAREDES := [
	Rect2(2600, 600, 1200, 100), Rect2(3700, 600, 100, 1600), Rect2(2600, 2100, 1200, 100),
	Rect2(0, 800, 2600, 100), Rect2(2500, 600, 100, 700), Rect2(2500, 1500, 100, 700),
	Rect2(0, 800, 100, 1200), Rect2(0, 1900, 1300, 100),
	Rect2(1200, 900, 100, 400), Rect2(1200, 1500, 100, 400),
	Rect2(1300, 1900, 500, 100), Rect2(2000, 1900, 500, 100),
	Rect2(1200, 1900, 100, 1100), Rect2(2500, 2100, 100, 900), Rect2(1200, 2900, 1400, 100),
]
## cada sala entra aqui quando fica pronta
const ORDEM: Array[String] = ["pocoes", "canos", "formas"]
const CHAVE_DA_SALA := {"pocoes": "verde", "canos": "laranja"}
const PORTAS := {"canos": "verde", "formas": "laranja"}
const CORES_PORTA := {"canos": Color("#5bd17a"), "formas": Color("#ff9f43")}
const MAQUINA := Vector2(1900, 1560)
const CABO := {"pocoes": 0, "canos": 1, "formas": 2}

var maquina: Maquina
var mumia: Monstro


func configurar_mapa() -> void:
	largura = W
	altura = H
	inicio = Vector2(1900, 1150)
	espera_guia = 12.0
	musica_inicial = "res://sons/musica_laboratorio.wav"
	zoom_abertura = 0.62
	salao = SALAO
	areas = AREAS
	vaos = VAOS
	paredes = PAREDES
	ordem = ORDEM.duplicate()
	cores_porta = CORES_PORTA
	cor_fundo = Color("#4a3f78")
	cor_parede = Color("#7a68b0")
	cor_face = Color("#9887c9")
	estado = EstadoSalas.new(ordem, CHAVE_DA_SALA, PORTAS)
	# chegou aqui: o castelo e o alçapão ficam abertos nas próximas
	Jogo.progresso.marcar("castelo")
	Jogo.progresso.marcar("laboratorio")
	for nome: String in ["alcapao", "maquina"]:
		carregar_som(nome)


func nova_atividade(id: String) -> Atividade:
	match id:
		"pocoes":
			return Pocoes.new()
		"canos":
			return Canos.new()
		"formas":
			return Formas.new()
	return null


func decorar() -> void:
	piso(SALAO, Color("#d8cdf0"), Color("#c9bce6"), false)
	# escada de chegada, encostada na parede de cima
	var escada := Visual.sprite_em_pe(load("res://arte/escada.svg") as Texture2D)
	escada.position = Vector2(1900, 1020)
	escada.z_index = 1
	add_child(escada)
	maquina = Maquina.new()
	add_child(maquina)
	maquina.montar(self, MAQUINA)
	if atividades.has("formas"):
		(atividades["formas"] as Formas)._mostrar()  # as lâmpadas da máquina copiam o painel
	mumia = Monstro.new()
	mumia.configurar("mumia", "", load("res://arte/mumia.svg") as Texture2D, load("res://arte/engrenagem.svg") as Texture2D)
	mumia.position = Vector2(2250, 1450)
	no_mundo(mumia)
	# tubos de vidro borbulhando e luzes coloridas: porão alegre, nada escuro
	for x: float in [1420.0, 2380.0]:
		var tubo := Visual.sprite_em_pe(load("res://arte/tubo_vidro.svg") as Texture2D)
		tubo.position = Vector2(x, 1130)
		no_mundo(tubo)
	for par: Array in [[Vector2(1500, 1300), Color(0.5, 1.0, 0.7, 0.2)], [Vector2(2300, 1300), Color(1.0, 0.7, 0.4, 0.2)],
			[Vector2(1900, 1700), Color(0.8, 0.6, 1.0, 0.22)]]:
		var luz := Visual.luz(par[1], 900.0)
		luz.position = par[0]
		luz.scale.y *= 0.6
		add_child(luz)
	if estado.todas_salas():
		festa_final.call_deferred()  # (sem salas ainda: vai direto pra festa)


func _ao_concluir(id: String) -> void:
	maquina.acender_cabo(CABO.get(id, -1))
	super(id)


## A máquina liga e todos dançam em volta dela.
func festa_final() -> void:
	if em_festa:
		return
	maquina.ligar()
	tocar("maquina")
	var dancantes: Array[Monstro] = []
	for id: String in ordem:
		var m := atividades[id].monstro()
		if m != null:
			dancantes.append(m)
	dancantes.append(mumia)
	var lugares: Array[Vector2] = [Vector2(-420, 60), Vector2(420, 60), Vector2(-250, 230), Vector2(250, 230)]
	for i in dancantes.size():
		var m := dancantes[i]
		var t := create_tween()
		t.tween_interval(0.8 + i * 0.25)
		t.tween_property(m, "global_position", MAQUINA + lugares[i % lugares.size()], 1.8).set_trans(Tween.TRANS_SINE)
		t.tween_callback(m.dancar)
	mumia.concluir()
	comecar_festa(MAQUINA + Vector2(0, -120), true)
	marco("festa_laboratorio", 4.0)


func ao_recomecar() -> void:
	Jogo.trocar_fase(Jogo.JARDIM)


# ---------------------------------------------------------------- teste automático

func iniciar_auto() -> void:
	print("AUTOPLAY: começando no laboratório")
	var sala := sala_pedida()
	if sala != "":
		_pular_ate.call_deferred(sala, SALAO)


func tempo_limite_auto() -> float:
	return 600.0


func pilotar_auto(delta: float) -> Vector2:
	if em_festa:
		return Vector2.ZERO
	if _tempo > 2.0:
		marco("inicio_laboratorio", 0.0)
	if esperar_guia_auto():
		return Vector2.ZERO
	# encosta uma vez de propósito na porta verde trancada (balança, nada se perde)
	if not tem_marco("trancada") and not estado.porta_aberta("canos"):
		return andar_ate(portas["canos"].ponto + Vector2(-110, 0), delta)
	var alvo := alvo_auto()
	depurar_auto(alvo)
	return andar_ate(alvo, delta)


func marcos_obrigatorios() -> Array[String]:
	if sala_pedida() != "":
		return ["festa_laboratorio", "pode_recomecar"]
	return ["inicio_laboratorio", "guia", "trancada", "plop", "pocoes", "chave_verde", "abriu_canos", "armadilha", "canos",
		"chave_laranja", "abriu_formas", "forma_errada", "formas", "festa_laboratorio", "pode_recomecar"]
