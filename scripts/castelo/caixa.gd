class_name Caixa
extends CharacterBody2D
## Caixa de madeira que anda quando a criança empurra (andando contra ela).
## Só colide com paredes e com a borda das caixas — nunca chega num canto.

const LADO := 120.0
const CAMADA := 4        # bit 3
const BORDA := 8         # bit 4: borda invisível só das caixas

var inicio := Vector2.ZERO
var travada := false
var _empurro := Vector2.ZERO
var _visual: Node2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = CAMADA
	collision_mask = 1 | BORDA
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(LADO, LADO)
	forma.shape = ret
	add_child(forma)
	_visual = Node2D.new()
	_visual.position = Vector2(0, LADO * 0.5)
	add_child(_visual)
	_visual.add_child(Visual.sombra(150.0))
	var s := Visual.sprite_em_pe(load("res://arte/caixa.svg") as Texture2D)
	s.position = Vector2(8, 0)
	_visual.add_child(s)


## Empurra neste frame; vai só na direção principal (fica previsível).
func empurrar(direcao: Vector2) -> void:
	if travada:
		return
	if absf(direcao.x) >= absf(direcao.y):
		_empurro = Vector2(signf(direcao.x), 0)
	else:
		_empurro = Vector2(0, signf(direcao.y))


func _physics_process(_delta: float) -> void:
	if travada:
		return
	velocity = _empurro * Jogador.VELOCIDADE * 0.7
	_empurro = Vector2.ZERO
	move_and_slide()


## Encaixa na marca: desliza pro centro e não sai mais.
func travar(centro: Vector2) -> void:
	travada = true
	velocity = Vector2.ZERO
	var t := create_tween()
	t.tween_property(self, "global_position", centro, 0.25).set_trans(Tween.TRANS_QUAD)
	t.tween_property(_visual, "scale", Vector2(1.15, 0.85), 0.1)
	t.tween_property(_visual, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


## Rede de segurança: some com um brilho e volta pro começo.
func voltar_pro_inicio() -> void:
	var t := create_tween()
	t.tween_property(_visual, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: global_position = inicio)
	t.tween_property(_visual, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
