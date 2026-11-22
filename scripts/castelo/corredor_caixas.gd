class_name CorredorCaixas
extends Atividade
## Corredor das caixas: empurrar as 2 caixas até as 2 marcas brilhando.
## As caixas ficam dentro de um "cercadinho" invisível afastado das paredes:
## sempre sobra espaço pra criança passar por trás e empurrar de outro lado.

const RECUO := 120.0          # distância da borda das caixas até a parede
const ESPERA_SOCORRO := 20.0  # caixa parada e criança sem progresso: volta pro início

var estado: EstadoCaixas
var caixas: Array[Caixa] = []
var marcas: Array[Sprite2D] = []
var cercado := Rect2()
var _parada: Array[float] = [0.0, 0.0]
var _ultima: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
# piloto automático
var _auto_borda := 0
var _auto_parada := 0.0


func montar() -> void:
	id = "caixas"
	mapa.carregar_som("encaixe")
	var o := area.position
	mapa.piso(area, Color("#b9b0c9"), Color("#a79dba"), false)
	mapa.tocha(o + Vector2(250, 0))
	mapa.tocha(o + Vector2(750, 0))
	cercado = area.grow(-RECUO)
	_montar_borda()

	var pos_marcas: Array[Vector2] = [o + Vector2(260, 300), o + Vector2(760, 620)]
	estado = EstadoCaixas.new(pos_marcas, 70.0)
	for p: Vector2 in pos_marcas:
		var m := Sprite2D.new()
		m.texture = load("res://arte/marca.svg") as Texture2D
		m.position = p
		m.modulate = Color(1.0, 0.9, 0.5, 0.8)
		var luz := Visual.luz(Color(1.0, 0.85, 0.4, 0.7), 300.0)
		luz.position = p
		luz.name = "LuzMarca%d" % marcas.size()
		add_child(luz)
		add_child(m)
		marcas.append(m)
	# a segunda caixa exige dar a volta nela pra empurrar pra direita
	for p: Vector2 in [o + Vector2(520, 300), o + Vector2(420, 560)]:
		var c := Caixa.new()
		c.position = p
		c.inicio = p
		mapa.no_mundo(c)
		caixas.append(c)


func _montar_borda() -> void:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = Caixa.BORDA
	corpo.collision_mask = 0
	add_child(corpo)
	var r := cercado
	var g := 60.0
	for ret: Rect2 in [Rect2(r.position.x - g, r.position.y - g, r.size.x + 2 * g, g),
			Rect2(r.position.x - g, r.end.y, r.size.x + 2 * g, g),
			Rect2(r.position.x - g, r.position.y, g, r.size.y),
			Rect2(r.end.x, r.position.y, g, r.size.y)]:
		var forma := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = ret.size
		forma.shape = s
		forma.position = ret.get_center()
		corpo.add_child(forma)


func _process(delta: float) -> void:
	for m: Sprite2D in marcas:
		if m.modulate.g > 0.95:
			continue
		m.modulate.a = 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.005)


func checar(p: Vector2) -> void:
	if terminada():
		return
	var delta := get_physics_process_delta_time()
	for i in caixas.size():
		var c := caixas[i]
		if c.travada:
			continue
		var m := estado.tentar_encaixar(i, c.global_position)
		if m >= 0:
			c.travar(estado.marcas[m])
			marcas[m].modulate = Color(1, 1, 1, 1)
			(get_node("LuzMarca%d" % m) as Sprite2D).modulate = Color(0.7, 1.0, 0.6, 0.6)
			mapa.tocar("encaixe")
			mapa.progresso_feito()
			mapa.marco("caixa", 0.5)
			if estado.completo():
				mapa.marco("caixas", 1.0)
				terminar()
			continue
		# rede de segurança (só com a criança aqui: fora, a caixa fica onde ela deixou)
		if not contem(p):
			continue
		if c.global_position.distance_to(_ultima[i]) < 2.0:
			_parada[i] += delta
		else:
			_parada[i] = 0.0
		_ultima[i] = c.global_position
		if _parada[i] > ESPERA_SOCORRO and mapa.tempo_sem_progresso() > ESPERA_SOCORRO \
				and c.global_position.distance_to(c.inicio) > 10.0:
			_parada[i] = 0.0
			c.voltar_pro_inicio()
			mapa.tocar("brilho")


## A caixa livre e a marca livre que formam o par mais perto.
func _par() -> Array:
	var melhor := []
	var menor := INF
	for i in caixas.size():
		if caixas[i].travada:
			continue
		for m in estado.marcas.size():
			if not estado.marca_livre(m):
				continue
			var d := caixas[i].global_position.distance_to(estado.marcas[m])
			if d < menor:
				menor = d
				melhor = [i, m]
	return melhor


func alvo() -> Vector2:
	var par := _par()
	if par.is_empty():
		return area.get_center()
	var c := caixas[par[0]].global_position
	if mapa.jogador.global_position.distance_to(c) < 160.0:
		return estado.marcas[par[1]]
	return c


var _dbg := 0.0


func alvo_auto() -> Vector2:
	_dbg += get_physics_process_delta_time()
	if _dbg > 1.5 and OS.get_cmdline_user_args().has("--depurar"):
		_dbg = 0.0
		print("DBG p=%s c0=%s c1=%s borda=%d" % [mapa.jogador.global_position.round(), caixas[0].global_position.round(), caixas[1].global_position.round(), _auto_borda])
	var par := _par()
	if par.is_empty():
		return area.get_center()
	var p := mapa.jogador.global_position
	# uma vez: empurra a caixa 2 contra a borda e confere que dá pra passar por trás
	if _auto_borda < 3:
		var c2 := caixas[1]
		match _auto_borda:
			0:
				var acima := c2.global_position + Vector2(0, -125)
				if p.distance_to(acima) < 20.0:
					_auto_borda = 1
				return _dentro(_contornar(c2.global_position, acima, Vector2(0, 1)))
			1:
				_auto_parada = _auto_parada + get_physics_process_delta_time() if c2.velocity.length() < 1.0 else 0.0
				if c2.global_position.y >= cercado.end.y - Caixa.LADO * 0.5 - 2.0 or _auto_parada > 0.6:
					_auto_borda = 2
				return c2.global_position + Vector2(0, 80)
			2:
				var atras := Vector2(c2.global_position.x, (cercado.end.y + area.end.y) * 0.5)
				if p.distance_to(atras) < 30.0:
					_auto_borda = 3
					mapa.marco("borda", 0.2)
				return _contornar(c2.global_position, atras, Vector2(0, -1))
	var c := caixas[par[0]].global_position
	var d: Vector2 = estado.marcas[par[1]] - c
	var eixo := Vector2(signf(d.x), 0) if absf(d.x) > 12.0 else Vector2(0, signf(d.y))
	var atras := c - eixo * 125.0
	if p.distance_to(atras) < 25.0 or (p - c).dot(eixo) < -100.0 and absf((p - c).dot(Vector2(-eixo.y, eixo.x))) < 30.0:
		return c + eixo * 80.0  # empurra
	return _dentro(_contornar(c, atras, eixo))


## Pra chegar em `ponto` atrás da caixa sem empurrá-la: vai pro lado dela,
## desce até a linha de trás e só então entra atrás.
func _contornar(caixa: Vector2, ponto: Vector2, eixo: Vector2) -> Vector2:
	var p := mapa.jogador.global_position
	var lado := Vector2(-eixo.y, eixo.x)
	var rel := p - caixa
	if rel.dot(eixo) <= -100.0:
		return ponto  # já está atrás
	var s := signf(rel.dot(lado))
	if s == 0.0:
		s = 1.0
	if absf(rel.dot(lado)) < 160.0:
		return caixa + lado * s * 180.0 + eixo * rel.dot(eixo)  # sai pro lado
	return caixa + lado * s * 180.0 - eixo * 125.0  # desce pelo lado até atrás


func _dentro(p: Vector2) -> Vector2:
	var r := area.grow(-50.0)
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
