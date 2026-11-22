class_name Porta
extends Node2D
## Porta trancada de uma sala, com uma fechadura da cor da chave que abre.
## Encostar sem a chave só balança a fechadura (nada se perde).

var id := ""
var cor := Color.WHITE
var aberta := false
## onde a criança encosta pra abrir (meio do vão)
var ponto := Vector2.ZERO

var _corpo: StaticBody2D
var _folha: Sprite2D
var _fechadura: Sprite2D
var _brilho: Sprite2D
var _tempo := 0.0
var _ultimo := -10.0
var _brilhando := false


## `vao`: retângulo do buraco na parede (o que a porta tapa).
## `mundo`: nó com y-sort onde a folha da porta fica de pé.
func configurar(p_id: String, p_cor: Color, vao: Rect2, mundo: Node2D) -> void:
	id = p_id
	cor = p_cor
	ponto = vao.get_center()
	_corpo = StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = vao.size
	forma.shape = ret
	forma.position = ponto
	_corpo.add_child(forma)
	add_child(_corpo)

	var em_pe := Node2D.new()
	em_pe.position = Vector2(ponto.x, vao.end.y)
	mundo.add_child(em_pe)
	_folha = Visual.sprite_em_pe(load("res://arte/porta_sala.svg") as Texture2D)
	var largura := maxf(vao.size.x, 120.0)
	_folha.scale = Vector2(largura / 210.0, 1.0)
	em_pe.add_child(_folha)
	_brilho = Visual.luz(Color(cor.r, cor.g, cor.b, 0.0), 300.0)
	_brilho.position = Vector2(0, -110)
	em_pe.add_child(_brilho)
	_fechadura = Sprite2D.new()
	_fechadura.texture = load("res://arte/fechadura.svg") as Texture2D
	_fechadura.modulate = cor
	_fechadura.position = Vector2(0, -110)
	em_pe.add_child(_fechadura)


func _process(delta: float) -> void:
	_tempo += delta
	if aberta:
		return
	var alvo := 0.6 + 0.3 * sin(_tempo * 4.0) if _brilhando else 0.0
	_brilho.modulate.a = lerpf(_brilho.modulate.a, alvo, 0.1)


## Brilha quando a criança já tem a chave desta porta.
func brilhar(ligado: bool) -> void:
	_brilhando = ligado


## Fechadura balança "hum-hum". true se balançou de fato (som só uma vez).
func balancar() -> bool:
	if aberta or _tempo - _ultimo < 1.6:
		return false
	_ultimo = _tempo
	var t := create_tween()
	for lado: float in [0.3, -0.3, 0.2, -0.12, 0.0]:
		t.tween_property(_fechadura, "rotation", lado, 0.08)
	var t2 := create_tween()
	t2.tween_property(_fechadura, "scale", Vector2.ONE * 1.3, 0.12).set_trans(Tween.TRANS_BACK)
	t2.tween_property(_fechadura, "scale", Vector2.ONE, 0.2)
	return true


func abrir() -> void:
	if aberta:
		return
	aberta = true
	_corpo.queue_free()
	var t := create_tween()
	t.tween_property(_fechadura, "position:y", _fechadura.position.y - 120.0, 0.5).set_trans(Tween.TRANS_BACK)
	t.parallel().tween_property(_fechadura, "modulate:a", 0.0, 0.5)
	t.parallel().tween_property(_brilho, "modulate:a", 0.0, 0.5)
	t.tween_property(_folha, "scale:x", 0.08, 0.5).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_folha, "modulate:a", 0.0, 0.5)
