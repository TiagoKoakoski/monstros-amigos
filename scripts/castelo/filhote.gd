class_name Filhote
extends Node2D
## Filhotinho de lobo. Solto, passeia devagar e dá "fugidinhas" brincalhonas
## quando a criança chega perto (sempre mais devagar que ela, nunca pro canto).
## Pego, segue a criança em fila. Na cama, dorme.

const PASSEIO := 90.0
const PERTO := 260.0
const PULO := 140.0

var estado := "solto"
var zona := Rect2()
var _alvo := Vector2.ZERO
var _ultima_fuga := -10.0
var _tempo := 0.0
var _corpo: Node2D
var _sprite: Sprite2D
var _pulando := false
var _zzz: Sprite2D


func configurar(p_zona: Rect2) -> void:
	zona = p_zona
	_tempo = randf() * TAU
	add_child(Visual.sombra(90.0))
	_corpo = Node2D.new()
	add_child(_corpo)
	_sprite = Visual.sprite_em_pe(load("res://arte/filhote.svg") as Texture2D)
	_corpo.add_child(_sprite)
	_zzz = Sprite2D.new()
	_zzz.texture = load("res://arte/zzz.svg") as Texture2D
	_zzz.position = Vector2(40, -120)
	_zzz.scale = Vector2.ONE * 0.6
	_zzz.z_index = 10
	_zzz.visible = false
	add_child(_zzz)
	_novo_passeio()


func _novo_passeio() -> void:
	_alvo = Vector2(randf_range(zona.position.x, zona.end.x), randf_range(zona.position.y, zona.end.y))


## Passeio e fuga (chamado pelo quarto com a posição da criança).
func soltinho(delta: float, crianca: Vector2) -> void:
	_tempo += delta
	if _pulando:
		return
	var longe := global_position.distance_to(crianca)
	if longe < PERTO and _tempo - _ultima_fuga > 1.5:
		_ultima_fuga = _tempo
		var fuga := (global_position - crianca).normalized()
		if fuga == Vector2.ZERO:
			fuga = Vector2.RIGHT
		var destino := _na_zona(global_position + fuga * PULO)
		# encostado na borda: foge de lado em vez de ficar preso no canto
		if destino.distance_to(global_position) < PULO * 0.5:
			destino = _na_zona(global_position + Vector2(-fuga.y, fuga.x) * PULO)
		_pular_para(destino)
		return
	var para := _alvo - global_position
	if para.length() < 10.0:
		_novo_passeio()
		return
	global_position += para.normalized() * PASSEIO * delta
	_sprite.scale.x = -1.0 if para.x < 0 else 1.0
	_corpo.position.y = -absf(sin(_tempo * 8.0)) * 6.0


func _pular_para(destino: Vector2) -> void:
	_pulando = true
	_sprite.scale.x = -1.0 if destino.x < global_position.x else 1.0
	var t := create_tween()
	t.tween_property(self, "global_position", destino, 0.45).set_trans(Tween.TRANS_SINE)
	var h := create_tween()
	h.tween_property(_corpo, "position:y", -50.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	h.tween_property(_corpo, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	h.tween_callback(func() -> void: _pulando = false)


func _na_zona(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, zona.position.x, zona.end.x), clampf(p.y, zona.position.y, zona.end.y))


func pegar() -> void:
	estado = "seguindo"
	_pulando = false
	var t := create_tween()
	t.tween_property(_corpo, "position:y", -40.0, 0.15)
	t.tween_property(_corpo, "position:y", 0.0, 0.15)


## Seguindo: chega perto do ponto da fila (sem física: passa pelas portas).
func seguir(ponto: Vector2, delta: float) -> void:
	_tempo += delta
	var antes := global_position
	global_position = global_position.lerp(ponto, minf(1.0, delta * 8.0))
	var anda := global_position - antes
	if absf(anda.x) > 0.5:
		_sprite.scale.x = -1.0 if anda.x < 0 else 1.0
	_corpo.position.y = -absf(sin(_tempo * 10.0)) * 6.0 if anda.length() > 0.5 else 0.0


func deitar(lugar: Vector2) -> void:
	estado = "cama"
	var t := create_tween()
	t.tween_property(self, "global_position", lugar, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void:
		_corpo.position.y = 0.0
		_corpo.rotation = -0.25
		_zzz.visible = true)


## Festa: acorda e fica pulando.
func acordar() -> void:
	estado = "festa"
	_zzz.visible = false
	_corpo.rotation = 0.0


func _process(delta: float) -> void:
	if estado == "festa":
		_tempo += delta
		_corpo.position.y = -absf(sin(_tempo * 7.0)) * 30.0
		return
	if estado == "cama":
		_tempo += delta
		_zzz.position.y = -120.0 + sin(_tempo * 2.0) * 8.0
		_zzz.modulate.a = 0.6 + 0.4 * sin(_tempo * 2.0)
