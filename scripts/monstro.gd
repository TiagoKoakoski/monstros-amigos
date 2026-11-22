class_name Monstro
extends Node2D
## Um monstro clássico fofo esperando ajuda. O balão mostra o desenho do que
## ele perdeu — nada pra ler.

var id := ""
var item_id := ""
var ajudado := false

var _corpo: Node2D
var _balao: Node2D
var _farol: Sprite2D
var _tempo := 0.0
var _dancando := false
var _ultimo_hum := -10.0
var _altura := 260.0
var _desenho: Sprite2D
var _icones: Array[Sprite2D] = []

const COR_SILHUETA := Color(0.22, 0.18, 0.36, 0.6)


func configurar(p_id: String, p_item: String, textura: Texture2D, textura_item: Texture2D) -> void:
	id = p_id
	item_id = p_item
	_altura = textura.get_height()
	_tempo = randf() * TAU

	_farol = Visual.luz(Color(1.0, 0.85, 0.35, 0.0), 420.0)
	_farol.position = Vector2(0, -20)
	add_child(_farol)
	add_child(Visual.sombra(textura.get_width() * 0.8))

	_corpo = Node2D.new()
	add_child(_corpo)
	_corpo.add_child(Visual.sprite_em_pe(textura))

	_balao = Node2D.new()
	_balao.position = Vector2(70, -_altura - 70)
	_balao.z_index = 10
	add_child(_balao)
	var fundo := Sprite2D.new()
	fundo.texture = load("res://arte/balao.svg") as Texture2D
	_balao.add_child(fundo)
	_desenho = Sprite2D.new()
	_desenho.texture = textura_item
	_desenho.position = Vector2(0, -18)
	_desenho.scale = Vector2.ONE * minf(0.75, 90.0 / maxf(textura_item.get_width(), textura_item.get_height()))
	_balao.add_child(_desenho)


## Balão com vários desenhos lado a lado (ex.: a receita do bolo).
## Os que ainda faltam aparecem como silhueta.
func mostrar_varios(texturas: Array[Texture2D]) -> void:
	_desenho.visible = false
	var fundo := _balao.get_child(0) as Sprite2D
	var n := texturas.size()
	fundo.scale.x = 0.55 + 0.5 * n
	var passo := 92.0
	for i in n:
		var s := Sprite2D.new()
		s.texture = texturas[i]
		s.position = Vector2((i - (n - 1) * 0.5) * passo, -18)
		s.scale = Vector2.ONE * minf(0.75, 80.0 / maxf(texturas[i].get_width(), texturas[i].get_height()))
		s.modulate = COR_SILHUETA
		_balao.add_child(s)
		_icones.append(s)


## Um dos desenhos do balão chegou: fica colorido e dá um pulinho.
func marcar_icone(i: int) -> void:
	var s := _icones[i]
	s.modulate = Color.WHITE
	var base := s.scale
	var t := create_tween()
	t.tween_property(s, "scale", base * 1.5, 0.15).set_trans(Tween.TRANS_BACK)
	t.tween_property(s, "scale", base, 0.2)


## Recebe uma parte do pedido: o item voa até ele e some.
func receber_parcial(item: Node2D) -> void:
	item.reparent(self, true)
	item.z_index = 5
	var t := create_tween()
	t.tween_property(item, "position", Vector2(80, -90), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(item, "scale", Vector2.ONE * 0.5, 0.4)
	t.tween_property(item, "modulate:a", 0.0, 0.3)
	t.tween_callback(item.queue_free)
	var pulo := create_tween()
	pulo.tween_property(_corpo, "position:y", -40.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pulo.tween_property(_corpo, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_coracao(0.0, Vector2(0, -_altura * 0.7))


## Pedido completo (sem item na mão): balão some e ele comemora.
func concluir() -> void:
	ajudado = true
	_farol.modulate.a = 0.0
	var some := create_tween()
	some.tween_property(_balao, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	comemorar()


## Dá uma voltinha (rodada da música, por exemplo).
func voltinha() -> void:
	var t := create_tween()
	for lado: float in [-1.0, 1.0, -1.0, 1.0]:
		t.tween_property(_corpo.get_child(0), "scale:x", lado, 0.15).set_trans(Tween.TRANS_SINE)


func altura() -> float:
	return _altura


func _process(delta: float) -> void:
	_tempo += delta
	if _dancando:
		_corpo.position.y = -absf(sin(_tempo * 7.0)) * 34.0
		_corpo.rotation = sin(_tempo * 3.5) * 0.18
		return
	# respirando devagar: vivo, mas calmo
	_corpo.scale = Vector2(1.0 + sin(_tempo * 2.2) * 0.02, 1.0 - sin(_tempo * 2.2) * 0.02)
	if not ajudado:
		_balao.position.y = -_altura - 70.0 + sin(_tempo * 2.5) * 7.0


## Liga o farol quando a criança está carregando o item deste monstro.
func marcar_farol(ligado: bool) -> void:
	if ajudado:
		ligado = false
	var alvo := 0.75 if ligado else 0.0
	if not is_equal_approx(_farol.modulate.a, alvo):
		_farol.modulate.a = lerpf(_farol.modulate.a, alvo, 0.12)
	if ligado:
		_farol.scale = Vector2.ONE * (420.0 / 128.0) * (0.92 + 0.08 * sin(_tempo * 5.0))


## "Hum-hum, não é esse": o balão balança pra lembrar o que ele quer.
## Devolve true quando realmente balançou (pra tocar o som só uma vez).
func lembrar_pedido() -> bool:
	if ajudado or _tempo - _ultimo_hum < 1.6:
		return false
	_ultimo_hum = _tempo
	var t := create_tween()
	for lado: float in [0.25, -0.25, 0.18, -0.12, 0.0]:
		t.tween_property(_balao, "rotation", lado, 0.08)
	var t2 := create_tween()
	t2.tween_property(_balao, "scale", Vector2.ONE * 1.25, 0.12).set_trans(Tween.TRANS_BACK)
	t2.tween_property(_balao, "scale", Vector2.ONE, 0.2)
	return true


func receber(item: Node2D) -> void:
	ajudado = true
	_farol.modulate.a = 0.0
	item.reparent(self, true)
	item.z_index = 5
	var t := create_tween()
	t.tween_property(item, "position", Vector2(110, -70), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(item, "scale", Vector2.ONE * 0.75, 0.45)
	var some := create_tween()
	some.tween_property(_balao, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	comemorar()


func comemorar() -> void:
	var pulos := create_tween()
	for i in 3:
		pulos.tween_property(_corpo, "position:y", -60.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pulos.tween_property(_corpo, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var conf := Visual.confete(46, 620.0)
	conf.position = Vector2(0, -_altura * 0.6)
	add_child(conf)
	conf.emitting = true
	conf.finished.connect(conf.queue_free)
	for i in 3:
		_coracao(i * 0.18, Vector2(-60 + 60 * i, -_altura * 0.7))


func _coracao(atraso: float, inicio: Vector2) -> void:
	var c := Sprite2D.new()
	c.texture = load("res://arte/coracao.svg") as Texture2D
	c.position = inicio
	c.scale = Vector2.ZERO
	c.z_index = 25
	add_child(c)
	var t := create_tween()
	t.tween_interval(atraso)
	t.tween_property(c, "scale", Vector2.ONE * 0.9, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(c, "position:y", inicio.y - 170.0, 1.3).set_trans(Tween.TRANS_SINE)
	t.tween_property(c, "modulate:a", 0.0, 0.35)
	t.tween_callback(c.queue_free)


func dancar() -> void:
	_dancando = true
	_tempo = randf() * TAU
