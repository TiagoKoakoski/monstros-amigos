class_name Ovelhinhas
extends Atividade
## Ovelhinhas de nuvem da Ovelhona (hora de dormir): 4 ovelhinhas passeiam
## devagar; cada uma dá um pulinho brincalhão uma vez só, depois deixa pegar e
## segue a criança em fila. Na porteira do cercadinho, uma de cada vez pula a
## cerca (contando) e dorme. 4 → termina.

const RAIO_PEGAR := 110.0
const RAIO_SUSTO := 260.0
const RAIO_PORTEIRA := 130.0
const ESPACO_FILA := 16
const ENTRE_PULOS := 0.6
## cercadinho e porteira (locais à área)
const CERCADO := Rect2(800, 620, 330, 320)
const PORTEIRA := Vector2(780, 600)
const INICIOS: Array[Vector2] = [Vector2(200, 300), Vector2(450, 700), Vector2(950, 300), Vector2(250, 800)]
const DENTRO: Array[Vector2] = [Vector2(880, 720), Vector2(1060, 700), Vector2(880, 880), Vector2(1060, 900)]

var ovelhas: EstadoOvelhas
var ovelhona: Monstro
var bichos: Array[Ovelhinha] = []
var cercado := Rect2()
var porteira := Vector2.ZERO
## onde as soltas passeiam
var limites := Rect2()
var _rastro: Array[Vector2] = []
var _fila_pulo: Array[int] = []
var _ate_pulo := 0.0
var _pularam := 0


func montar() -> void:
	id = "ovelhas"
	var o := area.position
	mapa.piso(area, Color("#56649c"), Color("#4d5a90"), false)
	cercado = Rect2(o + CERCADO.position, CERCADO.size)
	porteira = o + PORTEIRA
	limites = area.grow(-120.0)
	var pasto := Sprite2D.new()
	pasto.texture = load("res://arte/cercadinho.svg") as Texture2D
	pasto.position = cercado.get_center()
	mapa.no_chao(pasto)
	var tex := load("res://arte/ovelhinha.svg") as Texture2D
	var icones: Array[Texture2D] = []
	ovelhas = EstadoOvelhas.new(INICIOS.size())
	for i in INICIOS.size():
		icones.append(tex)
		var b := Ovelhinha.new()
		b.configurar(100 + i)
		b.position = o + INICIOS[i]
		mapa.no_mundo(b)
		bichos.append(b)
	ovelhona = Monstro.new()
	ovelhona.configurar("ovelhona", "", load("res://arte/ovelhona.svg") as Texture2D, tex)
	ovelhona.mostrar_varios(icones)
	ovelhona.position = o + Vector2(1000, 820)
	mapa.no_mundo(ovelhona)
	for nome: String in ["mee", "boing"]:
		mapa.carregar_som(nome)
	for i in 8:
		mapa.carregar_som("astro_%d" % i)


func _physics_process(delta: float) -> void:
	if mapa == null or mapa.jogador == null:
		return
	var p := mapa.jogador.global_position
	if _rastro.is_empty() or _rastro[-1].distance_to(p) > 6.0:
		_rastro.append(p)
		if _rastro.size() > 200:
			_rastro.pop_front()
	var fila := 0
	for b: Ovelhinha in bichos:
		if b.estado == "seguindo":
			fila += 1
			var idx := maxi(0, _rastro.size() - 1 - fila * ESPACO_FILA)
			b.seguir(_rastro[idx], delta)
		else:
			b.passo(delta, limites, cercado)


func checar(p: Vector2) -> void:
	if terminada():
		return
	for i: int in ovelhas.soltas():
		var b := bichos[i]
		if b.pulando():
			continue
		var d := p.distance_to(b.global_position)
		if d < RAIO_SUSTO and ovelhas.assustar(i):
			b.pular_longe(p, limites, cercado)
			mapa.tocar("boing")
			mapa.marco("pulinho", 0.3)
		elif d < RAIO_PEGAR and ovelhas.pegar(i):
			b.estado = "seguindo"
			mapa.tocar("mee")
			mapa.progresso_feito()
	if not ovelhas.seguindo().is_empty() and p.distance_to(porteira) < RAIO_PORTEIRA:
		_fila_pulo.append_array(ovelhas.guardar())
	_ate_pulo -= get_physics_process_delta_time()
	if not _fila_pulo.is_empty() and _ate_pulo <= 0.0:
		_ate_pulo = ENTRE_PULOS
		_pular_cerca(_fila_pulo.pop_front())


func _pular_cerca(i: int) -> void:
	var k := _pularam
	_pularam += 1
	bichos[i].guardar(area.position + DENTRO[k])
	ovelhona.marcar_icone(k)
	mapa.tocar("boing")
	mapa.tocar("astro_%d" % (k * 2))  # contando: dó, mi, sol, si
	mapa.progresso_feito()
	mapa.marco("guardou_%d" % _pularam, 0.3)
	if _pularam >= bichos.size():
		ovelhona.concluir()
		mapa.marco("ovelhas", 1.2)
		terminar()


func monstro() -> Monstro:
	return ovelhona


## As ovelhinhas também vão pra festa.
func convidados() -> Array[Node2D]:
	var c: Array[Node2D] = []
	for b: Ovelhinha in bichos:
		b.dancar()
		c.append(b)
	return c


## A solta mais perto; nenhuma solta, a porteira.
func alvo() -> Vector2:
	var p := mapa.jogador.global_position
	var melhor := porteira
	var menor := INF
	for i: int in ovelhas.soltas():
		var d := p.distance_to(bichos[i].global_position)
		if d < menor:
			menor = d
			melhor = bichos[i].global_position
	return melhor
