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
	var desenho := Sprite2D.new()
	desenho.texture = textura_item
	desenho.position = Vector2(0, -18)
	desenho.scale = Vector2.ONE * minf(0.75, 90.0 / maxf(textura_item.get_width(), textura_item.get_height()))
	_balao.add_child(desenho)


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
