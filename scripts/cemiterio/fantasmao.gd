class_name Fantasmao
extends Node2D
## O Fantasmão bonachão do pega-pega. Foge da criança, sempre mais devagar
## que ela, e cansa com o tempo; nas bordas escorrega por elas e nos cantos
## dá pra encurralar. Pego: ri, gira, descansa um pouco e dá um pulo pra
## longe (pra ser pego de novo é preciso correr atrás de novo).

const MAX := 228.0  # 60% da criança (380 px/s)
const MIN := 95.0  # 25%
const CANSA := 8.0  # segundos fugindo até chegar no mínimo
const FOGE := 450.0
const PEGA := 130.0
const DESCANSO := 1.5
const PULO := 320.0

var pegadas := 0
var _limites := Rect2()
var _fugindo := 0.0
var _descanso := 0.0
var _tempo := 0.0
## destino do pulo pra longe (INF = não está pulando)
var _pulo := Vector2.INF
var _corpo: Node2D
var _sprite: Sprite2D


## `area`: a arena; ele fica 90 px pra dentro dela.
func configurar(area: Rect2) -> void:
	_limites = area.grow(-90.0)
	add_child(Visual.sombra(220.0))
	_corpo = Node2D.new()
	add_child(_corpo)
	_sprite = Visual.sprite_em_pe(load("res://arte/fantasmao.svg") as Texture2D)
	_corpo.add_child(_sprite)


func velocidade() -> float:
	return lerpf(MAX, MIN, clampf(_fugindo / CANSA, 0.0, 1.0))


## Um quadro do pega-pega. true quando foi pego neste quadro.
func mover(delta: float, crianca: Vector2) -> bool:
	_tempo += delta
	if _descanso > 0.0:
		_descanso -= delta
		if _descanso <= 0.0:
			_pular_longe(crianca)
		return false
	if _pulo != Vector2.INF:
		global_position = global_position.move_toward(_pulo, 800.0 * delta)
		if global_position.distance_to(_pulo) < 1.0:
			_pulo = Vector2.INF
		return false
	var longe := global_position.distance_to(crianca)
	if longe < PEGA:
		pegadas += 1
		_fugindo = 0.0
		_descanso = DESCANSO
		var t := create_tween()
		t.tween_property(_corpo, "rotation", TAU, 0.6).set_trans(Tween.TRANS_BACK)
		t.tween_callback(func() -> void: _corpo.rotation = 0.0)
		return true
	if longe > FOGE:
		return false
	_fugindo += delta
	var fuga := (global_position - crianca).normalized()
	if fuga == Vector2.ZERO:
		fuga = Vector2.RIGHT
	var passo := fuga * velocidade() * delta
	var novo := global_position + passo
	# na borda: escorrega por ela em vez de parar (só os cantos encurralam)
	if novo.x < _limites.position.x or novo.x > _limites.end.x:
		passo = Vector2(0.0, signf(passo.y) if absf(passo.y) > 0.01 else _lado_livre_y()) * velocidade() * delta
	elif novo.y < _limites.position.y or novo.y > _limites.end.y:
		passo = Vector2(signf(passo.x) if absf(passo.x) > 0.01 else _lado_livre_x(), 0.0) * velocidade() * delta
	global_position = _dentro(global_position + passo)
	if absf(passo.x) > 0.1:
		_sprite.scale.x = -1.0 if passo.x < 0 else 1.0
	return false


## Fim do descanso: pula pra longe da criança (pro meio da arena se estiver encurralado).
func _pular_longe(crianca: Vector2) -> void:
	var fuga := (global_position - crianca).normalized()
	if fuga == Vector2.ZERO:
		fuga = (_limites.get_center() - global_position).normalized()
	var alvo := _dentro(global_position + fuga * PULO)
	if alvo.distance_to(crianca) < PULO * 0.6:
		alvo = _dentro(_limites.get_center() + (_limites.get_center() - crianca).normalized() * 260.0)
	_pulo = alvo


func _lado_livre_y() -> float:
	return 1.0 if global_position.y < _limites.get_center().y else -1.0


func _lado_livre_x() -> float:
	return 1.0 if global_position.x < _limites.get_center().x else -1.0


func _dentro(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, _limites.position.x, _limites.end.x), clampf(p.y, _limites.position.y, _limites.end.y))


func _process(_delta: float) -> void:
	_corpo.position.y = -16.0 + sin(_tempo * 2.5) * 12.0


func render() -> void:
	var t := create_tween()
	for i in 3:
		t.tween_property(_corpo, "position:y", -80.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(_corpo, "position:y", -16.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
