class_name Pocoes
extends Atividade
## Poções do Frankenstein: 4 baldes de cor (nunca acabam) e um caldeirão.
## Pega um frasco de cor, põe no caldeirão; duas cores viram uma mistura.
## A cor pedida vira poção; mistura errada faz "plop" e o caldeirão esvazia.
## O quadro na parede mostra as misturas (bolinha + bolinha = bolinha).

const CORES := {
	"vermelho": Color("#ff5d73"), "azul": Color("#4aa3ff"), "amarelo": Color("#ffd23f"), "branco": Color("#ffffff"),
	"verde": Color("#5bd17a"), "laranja": Color("#ff9f43"), "roxo": Color("#a66bff"), "rosa": Color("#ff9ecb"),
	"marrom": Color("#9a6b4f"),
}
const BALDES: Array[String] = ["vermelho", "azul", "amarelo", "branco"]
## alcance do balde: menor que o normal, pra não pegar outro balde de passagem
const RAIO_BALDE := 80.0

var pocoes: EstadoPocoes
var frank: Monstro
var baldes: Dictionary[String, Vector2] = {}
var caldeirao := Vector2.ZERO
var _tinta: Polygon2D
var _auto_plop := false


func montar() -> void:
	id = "pocoes"
	pocoes = EstadoPocoes.new()
	var o := area.position
	mapa.piso(area, Color("#e6dcf5"), Color("#d6c9ee"), true)
	mapa.enfeite("quadro_receitas", o + Vector2(260, 300), Vector2(420, 40))
	# caldeirão no meio; baldes embaixo, longe do caldeirão e uns dos outros
	# (ir do caldeirão a um balde nunca passa por cima de outro balde)
	caldeirao = o + Vector2(550, 480)
	mapa.enfeite("caldeirao", caldeirao, Vector2(240, 60))
	_tinta = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(caldeirao + Vector2(cos(a) * 104.0, -140.0 + sin(a) * 22.0))
	_tinta.polygon = pts
	_tinta.color = Color(0, 0, 0, 0)
	_tinta.z_index = 2
	add_child(_tinta)
	for i in BALDES.size():
		var cor := BALDES[i]
		var pos := o + Vector2([150.0, 410.0, 690.0, 950.0][i], 900)
		var b := mapa.enfeite("balde", pos, Vector2.ZERO)
		var tinta := Polygon2D.new()
		var tp := PackedVector2Array()
		for k in 24:
			var a := TAU * k / 24.0
			tp.append(Vector2(cos(a) * 48.0, -116.0 + sin(a) * 10.0))
		tinta.polygon = tp
		tinta.color = CORES[cor]
		b.add_child(tinta)
		baldes[cor] = pos
	mapa.carregar_som("plop")
	mapa.carregar_som("borbulha")

	frank = Monstro.new()
	frank.configurar("frankenstein", "", load("res://arte/frankenstein.svg") as Texture2D, load("res://arte/frasco.svg") as Texture2D)
	var frascos: Array[Texture2D] = []
	for i in EstadoPocoes.PEDIDOS.size():
		frascos.append(load("res://arte/frasco.svg") as Texture2D)
	frank.mostrar_varios(frascos)
	frank.position = o + Vector2(830, 300)
	mapa.no_mundo(frank)
	_mostrar_pedido()


func checar(p: Vector2) -> void:
	if terminada():
		return
	if mapa.mao_vazia():
		for cor: String in baldes:
			if p.distance_to(baldes[cor]) < RAIO_BALDE:
				_pegar(cor)
				return
		return
	var na_mao := mapa.estado.carregando
	if na_mao.begins_with("frasco_") and p.distance_to(caldeirao) < Fase.RAIO_MONSTRO:
		_colocar(na_mao.trim_prefix("frasco_"))


func _pegar(cor: String) -> void:
	var it := ItemPerdido.new()
	it.configurar("frasco_" + cor, load("res://arte/frasco.svg") as Texture2D)
	it.modulate = CORES[cor]
	it.global_position = baldes[cor]
	mapa.no_mundo(it)
	# pegar de novo e de novo não é avanço: não cala o vaga-lume
	mapa.dar_na_mao(it, "frasco_" + cor, false)


func _colocar(cor: String) -> void:
	var ajudou := pocoes.ajuda(cor)
	var antes := pocoes.caldeirao.duplicate()
	var frasco := mapa.tirar_da_mao()
	if frasco:
		frasco.reparent(self, true)
		var t := create_tween()
		t.tween_property(frasco, "global_position", caldeirao + Vector2(0, -170), 0.3).set_trans(Tween.TRANS_QUAD)
		t.tween_property(frasco, "scale", Vector2.ZERO, 0.2)
		t.tween_callback(frasco.queue_free)
	var r := pocoes.colocar(cor)
	if ajudou or r == "certo" or r == "fim":
		mapa.progresso_feito()
	match r:
		"dentro":
			_pintar(CORES[cor])
			mapa.tocar("entregar")
		"plop":
			_pintar(CORES.get(EstadoPocoes.misturar(antes[0], cor), CORES["marrom"]))
			_auto_plop = true
			mapa.tocar("plop")
			frank.lembrar_pedido()
			mapa.marco("plop", 0.3)
			_esvaziar(0.6)
		"certo", "fim":
			var feita: String = EstadoPocoes.PEDIDOS[pocoes.feitos() - 1]
			_pintar(CORES[feita])
			mapa.tocar("borbulha")
			_pocao_voa(feita)
			frank.marcar_icone(pocoes.feitos() - 1)
			frank.tingir_icone(pocoes.feitos() - 1, CORES[feita])
			_esvaziar(0.9)
			mapa.marco("pocao_%s" % feita, 0.6)
			if r == "fim":
				frank.concluir()
				mapa.marco("pocoes", 1.2)
				terminar()
			else:
				frank.voltinha()
				_mostrar_pedido()


func _pintar(cor: Color) -> void:
	_tinta.color = Color(cor.r, cor.g, cor.b, 0.95)
	_tinta.scale = Vector2.ONE
	var t := create_tween()
	t.tween_property(_tinta, "scale", Vector2(1.06, 1.3), 0.12)
	t.tween_property(_tinta, "scale", Vector2.ONE, 0.18)


func _esvaziar(atraso: float) -> void:
	var t := create_tween()
	t.tween_interval(atraso)
	t.tween_property(_tinta, "color:a", 0.0, 0.4)


## A poção pronta sai voando do caldeirão até o Frankenstein.
func _pocao_voa(cor: String) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://arte/frasco.svg") as Texture2D
	s.modulate = CORES[cor]
	s.global_position = caldeirao + Vector2(0, -160)
	s.z_index = 12
	add_child(s)
	var t := create_tween()
	t.tween_property(s, "global_position", frank.global_position + Vector2(0, -frank.altura() * 0.6), 0.7).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "modulate:a", 0.0, 0.3)
	t.tween_callback(s.queue_free)


## O frasco do pedido atual aparece no balão com a cor pedida (meio apagado).
func _mostrar_pedido() -> void:
	var pedido := pocoes.pedido_atual()
	if pedido == "":
		return
	var c: Color = CORES[pedido]
	frank.tingir_icone(pocoes.feitos(), Color(c.r, c.g, c.b, 0.6))


func monstro() -> Monstro:
	return frank


func dona_de(item: String) -> bool:
	return item.begins_with("frasco_")


func alvo() -> Vector2:
	if not mapa.mao_vazia():
		return caldeirao
	var faltam := pocoes.faltam()
	if faltam.is_empty():
		return caldeirao
	return baldes[faltam[0]]


## Piloto: no 1º pedido põe azul + vermelho de propósito (plop) antes de acertar.
func alvo_auto() -> Vector2:
	if not _auto_plop and pocoes.feitos() == 0:
		if mapa.mao_vazia():
			return baldes["azul" if pocoes.caldeirao.is_empty() else "vermelho"]
		return caldeirao
	return alvo()
