class_name Labirinto
extends Atividade
## Labirinto de cerca viva. Pegadas brilhantes (fracas, mais fortes perto da
## criança) marcam o caminho até a chave rosa, que fica no fim. O vaga-lume
## segue os corredores, nunca através da cerca — também pra sair dele.

const CELULA := 200.0
const GROSSURA := 50.0
const RAIO_CHAVE := 90.0
const COR_CERCA := Color("#2c5e43")
const COR_TOPO := Color("#4f9a6a")

var lab: EstadoLabirinto
var _chave: Sprite2D
var _brilho: Sprite2D
var _pegadas: Array[Sprite2D] = []
var _tempo := 0.0
var _auto_beco := false
const BECO_AUTO := Vector2i(1, 4)


func montar() -> void:
	id = "labirinto"
	lab = EstadoLabirinto.padrao()
	mapa.piso(area, Color("#7fb8a0"), Color("#74ad95"), false)
	var corpo := StaticBody2D.new()
	add_child(corpo)
	for r: Rect2i in lab.paredes():
		var ret := _ret_da_parede(r)
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([ret.position, Vector2(ret.end.x, ret.position.y), ret.end, Vector2(ret.position.x, ret.end.y)])
		p.color = COR_CERCA
		add_child(p)
		var topo := Polygon2D.new()
		var t := ret.grow(-8.0)
		topo.polygon = PackedVector2Array([t.position, Vector2(t.end.x, t.position.y), t.end, Vector2(t.position.x, t.end.y)])
		topo.color = COR_TOPO
		add_child(topo)
		var forma := CollisionShape2D.new()
		var caixa := RectangleShape2D.new()
		caixa.size = ret.size
		forma.shape = caixa
		forma.position = ret.get_center()
		corpo.add_child(forma)
	# pegadas no caminho certo, de célula em célula
	var cam := lab.caminho(EstadoLabirinto.ENTRADA, EstadoLabirinto.CHAVE)
	var tex := load("res://arte/pegada.svg") as Texture2D
	for i in cam.size() - 1:
		var a := centro(cam[i])
		var b := centro(cam[i + 1])
		for k in 2:
			var s := Sprite2D.new()
			s.texture = tex
			s.position = a.lerp(b, 0.3 + 0.4 * k) + (b - a).orthogonal().normalized() * (12.0 if k == 0 else -12.0)
			s.rotation = (b - a).angle() + PI * 0.5
			s.scale = Vector2.ONE * 0.6
			s.modulate.a = 0.25
			mapa.no_chao(s)
			_pegadas.append(s)
	_brilho = Visual.luz(Color(1.0, 0.62, 0.8, 0.8), 300.0)
	_brilho.position = centro(EstadoLabirinto.CHAVE) + Vector2(0, -40)
	add_child(_brilho)
	_chave = Sprite2D.new()
	_chave.texture = load("res://arte/chave.svg") as Texture2D
	_chave.modulate = Chaveiro.CORES["rosa"]
	_chave.position = centro(EstadoLabirinto.CHAVE) + Vector2(0, -40)
	_chave.z_index = 5
	add_child(_chave)


## Retângulo (no mundo) de um `#` do desenho: célula, cerca fina ou pilar.
func _ret_da_parede(r: Rect2i) -> Rect2:
	var x := r.position.x
	var y := r.position.y
	var o := area.position
	var px := o.x + (x / 2) * CELULA - GROSSURA * 0.5 if x % 2 == 0 else o.x + ((x - 1) / 2) * CELULA
	var py := o.y + (y / 2) * CELULA - GROSSURA * 0.5 if y % 2 == 0 else o.y + ((y - 1) / 2) * CELULA
	var w := GROSSURA if x % 2 == 0 else CELULA
	var h := GROSSURA if y % 2 == 0 else CELULA
	return Rect2(px, py, w, h)


func centro(c: Vector2i) -> Vector2:
	return area.position + Vector2((c.x + 0.5) * CELULA, (c.y + 0.5) * CELULA)


func celula(p: Vector2) -> Vector2i:
	var d := (p - area.position) / CELULA
	return Vector2i(clampi(floori(d.x), 0, EstadoLabirinto.LARGURA - 1), clampi(floori(d.y), 0, EstadoLabirinto.ALTURA - 1))


func _process(delta: float) -> void:
	_tempo += delta
	if mapa == null or mapa.jogador == null:
		return
	var p := mapa.jogador.global_position
	for s: Sprite2D in _pegadas:
		var perto := clampf(1.0 - p.distance_to(s.global_position) / 320.0, 0.0, 1.0)
		s.modulate.a = 0.25 + 0.6 * perto
	if not terminada():
		_chave.position.y = centro(EstadoLabirinto.CHAVE).y - 40.0 + sin(_tempo * 3.0) * 10.0


func checar(p: Vector2) -> void:
	if terminada() or not contem(p):
		return
	var c := celula(p)
	if c == BECO_AUTO:
		mapa.marco("beco", 0.3)
		_auto_beco = true
	if p.distance_to(_chave.global_position + Vector2(0, 40)) < RAIO_CHAVE:
		_chave.visible = false
		_brilho.visible = false
		mapa.marco("labirinto", 0.3)
		terminar()


func origem_da_chave() -> Vector2:
	return _chave.global_position


## Próxima célula até a chave (seguindo os corredores).
func alvo() -> Vector2:
	var c := celula(mapa.jogador.global_position)
	if c == EstadoLabirinto.CHAVE:
		return centro(c)
	return centro(lab.proximo(c, EstadoLabirinto.CHAVE))


## Saindo do labirinto: volta pelos corredores até a entrada, depois o portão.
func caminho_ate(destino: Vector2) -> Vector2:
	var c := celula(mapa.jogador.global_position)
	if c == EstadoLabirinto.ENTRADA:
		return destino
	return centro(lab.proximo(c, EstadoLabirinto.ENTRADA))


## Piloto: primeiro entra no beco ao lado da entrada, depois segue o caminho.
func alvo_auto() -> Vector2:
	if not _auto_beco:
		return centro(BECO_AUTO)
	return alvo()
