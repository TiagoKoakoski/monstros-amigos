class_name Jogador
extends CharacterBody2D
## A criança com a lanterna. Anda com o analógico, as setas do controle ou o teclado.

const VELOCIDADE := 380.0

## Modo automático (teste): ignora o controle e anda nessa direção.
var automatico := false
var direcao_forcada := Vector2.ZERO
var movendo := false

var _visual: Node2D
var _mao: Node2D
var _tempo := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 38.0  # redondo: escorrega nas paredes em vez de travar
	forma.shape = circulo
	add_child(forma)
	add_child(Visual.sombra(110.0))
	_visual = Node2D.new()
	add_child(_visual)
	_visual.add_child(Visual.sprite_em_pe(load("res://arte/crianca.svg") as Texture2D))
	_mao = Node2D.new()
	_mao.position = Vector2(0, -230)
	_mao.z_index = 10
	add_child(_mao)


func entrada() -> Vector2:
	if automatico:
		return direcao_forcada.limit_length(1.0)
	return Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")


func _physics_process(_delta: float) -> void:
	var dir := entrada()
	velocity = dir * VELOCIDADE
	move_and_slide()
	movendo = dir.length() > 0.05
	if dir.x < -0.1:
		_visual.scale.x = -1.0
	elif dir.x > 0.1:
		_visual.scale.x = 1.0


func _process(delta: float) -> void:
	_tempo += delta
	if movendo:
		_visual.position.y = -absf(sin(_tempo * 11.0)) * 9.0
		_visual.rotation = sin(_tempo * 11.0) * 0.05
	else:
		_visual.position.y = lerpf(_visual.position.y, 0.0, minf(1.0, delta * 12.0))
		_visual.rotation = lerpf(_visual.rotation, 0.0, minf(1.0, delta * 12.0))
	if _mao.get_child_count() > 0:
		_mao.position.y = -230.0 + sin(_tempo * 4.0) * 6.0


## Põe o item acima da cabeça, como quem mostra pra todo mundo.
func segurar(item: Node2D) -> void:
	item.reparent(_mao, false)
	item.position = Vector2.ZERO


func soltar_na_mao() -> Node2D:
	if _mao.get_child_count() == 0:
		return null
	return _mao.get_child(0) as Node2D
