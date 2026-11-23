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
##
## Na festa acende a escada da torre (canto de cima da praça): sobe pro telhado.

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
const ORDEM: Array[String] = ["lapides", "horta", "labirinto", "arena"]
const CHAVE_DA_SALA := {"lapides": "roxa", "horta": "amarela", "labirinto": "rosa"}
const PORTAS := {"horta": "roxa", "labirinto": "amarela", "arena": "rosa"}
const CORES_PORTA := {"horta": Color("#a66bff"), "labirinto": Color("#ffd23f"), "arena": Color("#ff9ecb")}
## escada da torre: pés no canto de cima da praça, longe dos caminhos entre os portões
const ESCADA := Vector2(2520, 1300)
## onde encostar pra subir (na frente da escada)
const PE_DA_ESCADA := Vector2(2520, 1370)
const GRAMA := Color("#7fb8a0")
const GRAMA_LINHA := Color("#74ad95")

var escada: PortaFundos
var _ir_pra_escada := false
var _subindo := false


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
		"labirinto":
			return Labirinto.new()
		"arena":
			return Arena.new()
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
	# escada da torre: apagada até a festa (acesa desde o começo com o telhado no progresso)
	escada = PortaFundos.new()
	escada.configurar(ESCADA, PE_DA_ESCADA, Jogo.progresso.alcancou("telhado"), "escada_torre", "escada_torre_acesa")
	no_mundo(escada)
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
	# os fantasminhas e o Fantasmão vêm junto e dançam em volta
	var filhos: Array[Node2D] = []
	for id: String in ordem:
		if atividades[id].has_method("convidados"):
			filhos.append_array(atividades[id].call("convidados"))
	if not filhos.is_empty():
		for j in filhos.size():
			var a := TAU * j / filhos.size()
			var t := create_tween()
			t.tween_interval(1.0 + j * 0.15)
			t.tween_property(filhos[j], "global_position", SALAO.get_center() + Vector2(cos(a) * 520.0, 60.0 + sin(a) * 260.0), 1.8).set_trans(Tween.TRANS_SINE)
	comecar_festa(SALAO.get_center() + Vector2(0, -60), false)
	marco("festa_cemiterio", 4.0)
	var t := create_tween()
	t.tween_interval(5.0)
	t.tween_callback(_acender_escada)
	t.tween_interval(2.4)
	t.tween_callback(func() -> void:
		(get_node("Interface/Chuva") as CPUParticles2D).emitting = false
		_ir_pra_escada = true
		_tempo_sem_progresso = espera_guia - 1.0  # vaga-lume aparece logo
		seguir_jogador())


## A escada da torre acende e o Fantasmão flutua até ela na frente (mostra o caminho).
func _acender_escada() -> void:
	if not escada.aberta:
		escada.abrir()
		tocar("porta")
	marco("escada_acesa", 2.0)
	if not atividades.has("arena"):
		return
	var f := (atividades["arena"] as Arena).fantasmao
	var t := create_tween()
	t.tween_property(f, "global_position", PE_DA_ESCADA + Vector2(0, -30), 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(f, "scale", Vector2.ONE * 0.3, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(f, "modulate:a", 0.0, 0.5)


func guia_ligado() -> bool:
	return not em_festa or _ir_pra_escada


func alvo_atual() -> Vector2:
	if _ir_pra_escada:
		return _ate_a_escada()
	return super()


## Caminho até a escada: se a festa pegou a criança numa área, primeiro sai dela.
func _ate_a_escada() -> Vector2:
	var aqui := sala_do_jogador()
	if aqui != "":
		return _saindo_de(aqui, _passar(VAOS[aqui], SALAO))
	return PE_DA_ESCADA


func checar_interacoes() -> void:
	if escada.perto(jogador.global_position):
		_subir()
		return
	super()


func _subir() -> void:
	if _subindo:
		return
	_subindo = true
	if Jogo.auto:
		marco("escada")
		var falhas := _auto_falhas + verificar_fim_auto()
		if not falhas.is_empty() or sala_pedida() != "":
			_sair_com(falhas)
			return
	tocar("porta")
	Jogo.trocar_fase(Jogo.TELHADO)


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
		return andar_ate(_ate_a_escada(), delta) if _ir_pra_escada else Vector2.ZERO
	if _tempo > 2.0:
		marco("inicio_cemiterio", 0.0)
	if esperar_guia_auto():
		return Vector2.ZERO
	# encosta uma vez de propósito no portão roxo trancado (balança, nada se perde)
	if not tem_marco("trancada") and not estado.porta_aberta("horta"):
		return andar_ate(portas["horta"].ponto + Vector2(-110, 0), delta)
	var alvo := alvo_auto()
	depurar_auto(alvo)
	return andar_ate(alvo, delta)


func marcos_obrigatorios() -> Array[String]:
	if sala_pedida() != "":
		return ["festa_cemiterio", "escada"]
	return ["inicio_cemiterio", "guia", "trancada", "vazio", "lapides", "chave_roxa", "abriu_horta", "hum_horta", "devolveu",
		"horta", "chave_amarela", "abriu_labirinto", "beco", "labirinto",
		"chave_rosa", "abriu_arena", "pegou_1", "pegou_2", "pegou_3", "arena",
		"festa_cemiterio", "escada_acesa", "escada"]
