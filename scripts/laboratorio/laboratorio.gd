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
##
## Na festa abre a porta dos fundos (parede de cima): sai pro cemitério.

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
## pés da máquina acima do corredor Poções <-> Canos (y 1300..1500): a criança
## passa na frente dela, nunca escondida atrás
const MAQUINA := Vector2(1900, 1250)
const CABO := {"pocoes": 0, "canos": 1, "formas": 2}
## porta dos fundos: pés na parede de cima, longe da escada e dos caminhos
const PORTA_FUNDOS := Vector2(2300, 960)

var maquina: Maquina
var mumia: Monstro
var porta_fundos: PortaFundos
var _ir_pra_porta := false
var _pela_porta := false


func configurar_mapa() -> void:
	largura = W
	altura = H
	inicio = Vector2(1560, 1150)
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
	for nome: String in ["alcapao", "maquina", "porta"]:
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
	escada.position = Vector2(1560, 1020)
	escada.z_index = 1
	add_child(escada)
	maquina = Maquina.new()
	add_child(maquina)
	maquina.montar(self, MAQUINA)
	if atividades.has("formas"):
		(atividades["formas"] as Formas)._mostrar()  # as lâmpadas da máquina copiam o painel
	porta_fundos = PortaFundos.new()
	add_child(porta_fundos)
	porta_fundos.z_index = 1
	# já esteve no cemitério: a porta fica aberta (atalho)
	porta_fundos.configurar(Vector2(PORTA_FUNDOS.x, 900), PORTA_FUNDOS, Jogo.progresso.alcancou("cemiterio"))
	mumia = Monstro.new()
	mumia.configurar("mumia", "", load("res://arte/mumia.svg") as Texture2D, load("res://arte/engrenagem.svg") as Texture2D)
	mumia.position = Vector2(2250, 1450)
	no_mundo(mumia)
	# tubos de vidro borbulhando e luzes coloridas: porão alegre, nada escuro
	for x: float in [1360.0, 2440.0]:
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
	comecar_festa(MAQUINA + Vector2(0, -120), false)
	marco("festa_laboratorio", 4.0)
	var t := create_tween()
	t.tween_interval(5.0)
	t.tween_callback(_abrir_porta_fundos)
	t.tween_interval(2.4)
	t.tween_callback(func() -> void:
		(get_node("Interface/Chuva") as CPUParticles2D).emitting = false
		_ir_pra_porta = true
		_tempo_sem_progresso = espera_guia - 1.0  # vaga-lume aparece logo
		seguir_jogador())


## A porta dos fundos abre e a Múmia passa por ela na frente (mostra o caminho).
func _abrir_porta_fundos() -> void:
	if not porta_fundos.aberta:
		porta_fundos.abrir()
		tocar("porta")
	var t := create_tween()
	t.tween_property(mumia, "global_position", PORTA_FUNDOS + Vector2(0, -20), 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(mumia, "scale", Vector2.ONE * 0.3, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(mumia, "modulate:a", 0.0, 0.5)
	marco("porta_fundos_aberta", 2.0)


func guia_ligado() -> bool:
	return not em_festa or _ir_pra_porta


func alvo_atual() -> Vector2:
	if _ir_pra_porta:
		return _ate_a_porta()
	return super()


## Caminho até a porta dos fundos: se a festa pegou a criança numa sala, primeiro sai dela.
func _ate_a_porta() -> Vector2:
	var aqui := sala_do_jogador()
	if aqui != "":
		return _saindo_de(aqui, _passar(VAOS[aqui], SALAO))
	return PORTA_FUNDOS


func checar_interacoes() -> void:
	if porta_fundos.perto(jogador.global_position):
		_sair()
		return
	super()


func _sair() -> void:
	if _pela_porta:
		return
	_pela_porta = true
	if Jogo.auto:
		marco("porta_fundos")
		var falhas := _auto_falhas + verificar_fim_auto()
		if not falhas.is_empty() or sala_pedida() != "":
			_sair_com(falhas)
			return
	tocar("porta")
	Jogo.trocar_fase(Jogo.CEMITERIO)


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
		return andar_ate(_ate_a_porta(), delta) if _ir_pra_porta else Vector2.ZERO
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
		return ["festa_laboratorio", "porta_fundos"]
	return ["inicio_laboratorio", "guia", "trancada", "plop", "pocoes", "chave_verde", "abriu_canos", "armadilha", "canos",
		"chave_laranja", "abriu_formas", "forma_errada", "formas", "festa_laboratorio", "porta_fundos_aberta",
		"porta_fundos"]
