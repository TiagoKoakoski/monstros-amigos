class_name Guia
extends Node2D
## Vaga-lume que aparece quando a criança fica um tempo sem progresso e voa
## até o próximo objetivo, mostrando o caminho. Repete enquanto for preciso.

const VELOCIDADE := 430.0

var _ativo := false
var _origem := Vector2.ZERO
var _alvo := Vector2.ZERO
var _tempo := 0.0
var _parado := 0.0


func _ready() -> void:
	z_index = 20
	# grande de propósito: tem que ser visto de longe, na TV, por uma criança de 5 anos
	add_child(Visual.luz(Color(1.0, 0.95, 0.5, 0.95), 340.0))
	var s := Sprite2D.new()
	s.texture = load("res://arte/vagalume.svg") as Texture2D
	s.scale = Vector2.ONE * 1.7
	add_child(s)
	visible = false


func ativo() -> bool:
	return _ativo


func guiar(origem: Vector2, alvo: Vector2) -> void:
	_alvo = alvo
	if not _ativo:
		_ativo = true
		_origem = origem
		global_position = origem
		visible = true
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.4)


func atualizar_origem(origem: Vector2) -> void:
	_origem = origem


func parar() -> void:
	if not _ativo:
		return
	_ativo = false
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: visible = false)


func _process(delta: float) -> void:
	if not _ativo:
		return
	_tempo += delta
	var ate_alvo := _alvo - global_position
	if ate_alvo.length() < 40.0:
		_parado += delta
		if _parado > 0.9:  # chegou: volta pra perto da criança e mostra de novo
			_parado = 0.0
			global_position = _origem + Vector2(0, -160)
		return
	var passo := ate_alvo.normalized() * VELOCIDADE * delta
	var lado := Vector2(-ate_alvo.y, ate_alvo.x).normalized() * sin(_tempo * 6.0) * 2.5
	global_position += passo + lado
