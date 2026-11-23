class_name Ovelhinha
extends Node2D
## Ovelhinha de nuvem. Solta: passeia devagar (para um pouco, escolhe outro
## lugar). Uma vez só dá um pulinho brincalhão pra longe. Pega: segue a
## criança (sem física: passa pelos portões). Guardada: pula a cerca e dorme.
## Todo movimento anda em passo()/seguir() (chamados pela sala), não em tween.

const VELOCIDADE := 110.0
const PULO := 600.0
const DISTANCIA_PULO := 350.0
## longe assim do cercadinho quando está solta
const FOLGA_CERCADO := 80.0

## "solta", "seguindo", "guardando", "dormindo", "festa"
var estado := "solta"
var _rng := RandomNumberGenerator.new()
var _destino := Vector2.INF
var _parada := 0.0
var _pulo := Vector2.INF
var _pulo_de := Vector2.ZERO
var _corpo: Node2D
var _sprite: Sprite2D
var _zzz: Sprite2D
var _tempo := 0.0


func configurar(semente: int) -> void:
	_rng.seed = semente
	_tempo = _rng.randf() * TAU
	_parada = _rng.randf_range(0.3, 1.5)
	add_child(Visual.sombra(110.0))
	_corpo = Node2D.new()
	add_child(_corpo)
	_sprite = Visual.sprite_em_pe(load("res://arte/ovelhinha.svg") as Texture2D)
	_corpo.add_child(_sprite)
	_zzz = Sprite2D.new()
	_zzz.texture = load("res://arte/zzz.svg") as Texture2D
	_zzz.position = Vector2(40, -150)
	_zzz.visible = false
	add_child(_zzz)


func pulando() -> bool:
	return _pulo != Vector2.INF


func _process(delta: float) -> void:
	_tempo += delta
	if estado == "dormindo":
		_zzz.modulate.a = 0.6 + 0.4 * sin(_tempo * 2.0)
		_corpo.scale = Vector2(1.0 + sin(_tempo * 1.5) * 0.03, 1.0 - sin(_tempo * 1.5) * 0.03)
	elif estado == "festa":
		_corpo.position.y = -absf(sin(_tempo * 6.0)) * 30.0


## Um quadro solta (passeando) ou pulando (pulinho / pular a cerca).
func passo(delta: float, limites: Rect2, cercado: Rect2) -> void:
	if estado == "festa":
		return
	if pulando():
		_andar_pulo(delta)
		return
	if estado != "solta":
		return
	if _parada > 0.0:
		_parada -= delta
		return
	if _destino == Vector2.INF:
		_destino = _sortear(limites, cercado)
	_virar(_destino.x - global_position.x)
	global_position = global_position.move_toward(_destino, VELOCIDADE * delta)
	if global_position.distance_to(_destino) < 1.0:
		_destino = Vector2.INF
		_parada = _rng.randf_range(1.0, 2.0)


func _sortear(limites: Rect2, cercado: Rect2) -> Vector2:
	var evitar := cercado.grow(FOLGA_CERCADO)
	for k in 30:
		var p := Vector2(_rng.randf_range(limites.position.x, limites.end.x), _rng.randf_range(limites.position.y, limites.end.y))
		if not evitar.has_point(p) and p.distance_to(global_position) > 150.0:
			return p
	return global_position


## Pulinho brincalhão pra longe da criança (uma vez só; quem decide é a sala).
func pular_longe(crianca: Vector2, limites: Rect2, cercado: Rect2) -> void:
	var evitar := cercado.grow(FOLGA_CERCADO)
	var dir := (global_position - crianca).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	for ang: float in [0.0, 0.6, -0.6, 1.3, -1.3, 2.0, -2.0]:
		var p := (global_position + dir.rotated(ang) * DISTANCIA_PULO).clamp(limites.position, limites.end)
		if not evitar.has_point(p) and p.distance_to(global_position) > 150.0:
			_pular(p)
			return


func _pular(destino: Vector2) -> void:
	_pulo_de = global_position
	_pulo = destino
	_destino = Vector2.INF


func _andar_pulo(delta: float) -> void:
	global_position = global_position.move_toward(_pulo, PULO * delta)
	var total := maxf(1.0, _pulo_de.distance_to(_pulo))
	var k := clampf(_pulo_de.distance_to(global_position) / total, 0.0, 1.0)
	_corpo.position.y = -sin(k * PI) * minf(120.0, total * 0.4)
	_virar(_pulo.x - _pulo_de.x)
	if global_position.distance_to(_pulo) < 1.0:
		_pulo = Vector2.INF
		_corpo.position.y = 0.0
		if estado == "guardando":
			estado = "dormindo"
			_zzz.visible = true


## Seguindo: chega perto do ponto da fila.
func seguir(ponto: Vector2, delta: float) -> void:
	var antes := global_position
	global_position = global_position.lerp(ponto, minf(1.0, delta * 7.0))
	_virar(global_position.x - antes.x)


## Pula a cerca até `lugar` (dentro do cercadinho) e dorme.
func guardar(lugar: Vector2) -> void:
	estado = "guardando"
	_pular(lugar)


func dancar() -> void:
	estado = "festa"
	_pulo = Vector2.INF
	_corpo.position.y = 0.0
	_zzz.visible = false


func _virar(dx: float) -> void:
	if absf(dx) > 0.5:
		_sprite.scale.x = 1.0 if dx < 0 else -1.0  # o desenho olha pra esquerda
