class_name Planetinhas
extends Atividade
## Planetinhas da Dona Lua: 3 planetinhas rolaram pelo telhado. Encostar
## empurra (pra longe da criança, com ajuda na mira pro ninho); ele rola,
## para e quica nas bordas. Perto do ninho da cor dele, cai nele e fica.

const CORES: Array[String] = ["vermelho", "azul", "amarelo"]
const NINHOS: Array[Vector2] = [Vector2(400, 220), Vector2(650, 220), Vector2(900, 220)]
const INICIOS: Array[Vector2] = [Vector2(700, 750), Vector2(350, 700), Vector2(600, 500)]
const TINTA := {"vermelho": Color("#ffb3b3"), "azul": Color("#b3d9ff"), "amarelo": Color("#fff0a8")}

var lua: Monstro
var planetas: Array[Planetinha] = []
var ninhos: Array[Vector2] = []
## onde os planetinhas podem estar (a criança passa por trás deles em qualquer borda)
var limites := Rect2()
var _encostado: Array[bool] = []
var _no_ninho := 0
## planetinha que o piloto está levando (fica nele até encaixar)
var _auto_i := -1


func montar() -> void:
	id = "planetas"
	var o := area.position
	mapa.piso(area, Color("#56649c"), Color("#4d5a90"), false)
	limites = area.grow(-150.0)
	var icones: Array[Texture2D] = []
	for i in CORES.size():
		var tex := load("res://arte/planeta_%s.svg" % CORES[i]) as Texture2D
		icones.append(tex)
		ninhos.append(o + NINHOS[i])
		var n := Sprite2D.new()
		n.texture = load("res://arte/ninho.svg") as Texture2D
		n.modulate = TINTA[CORES[i]]
		n.position = ninhos[i]
		mapa.no_chao(n)
		var pl := Planetinha.new()
		pl.configurar(CORES[i])
		pl.position = o + INICIOS[i]
		mapa.no_mundo(pl)
		planetas.append(pl)
		_encostado.append(false)
	lua = Monstro.new()
	lua.configurar("dona_lua", "", load("res://arte/dona_lua.svg") as Texture2D, icones[0])
	lua.mostrar_varios(icones)
	lua.position = o + Vector2(950, 800)
	mapa.no_mundo(lua)
	for nome: String in ["rolar", "encaixe"]:
		mapa.carregar_som(nome)


func checar(p: Vector2) -> void:
	if terminada():
		return
	var dt := get_physics_process_delta_time()
	for i in planetas.size():
		var pl := planetas[i]
		if pl.no_ninho:
			continue
		if p.distance_to(pl.global_position) < Rolagem.TOQUE:
			if not _encostado[i]:
				mapa.tocar("rolar")  # empurrar não é avanço (dá pra empurrar pra sempre)
			_encostado[i] = true
			pl.vel = Rolagem.empurrao(pl.global_position, p, ninhos[i])
		else:
			_encostado[i] = false
		var r := Rolagem.rolar(pl.global_position, pl.vel, dt, limites)
		pl.global_position = r[0]
		pl.vel = r[1]
		if Rolagem.encaixa(pl.global_position, ninhos[i]):
			_encaixar(i)


func _encaixar(i: int) -> void:
	planetas[i].encaixar(ninhos[i])
	_no_ninho += 1
	lua.marcar_icone(i)
	mapa.tocar("encaixe")
	mapa.progresso_feito()
	mapa.marco("ninho_%d" % _no_ninho, 0.4)
	if _no_ninho >= planetas.size():
		lua.concluir()
		mapa.marco("planetas", 1.2)
		terminar()


func monstro() -> Monstro:
	return lua


func _mais_perto(p: Vector2) -> int:
	var melhor := -1
	var menor := INF
	for i in planetas.size():
		if planetas[i].no_ninho:
			continue
		var d := p.distance_to(planetas[i].global_position)
		if d < menor:
			menor = d
			melhor = i
	return melhor


## De onde empurrar o planetinha solto mais perto pro ninho dele.
func alvo() -> Vector2:
	var p := mapa.jogador.global_position
	var i := _mais_perto(p)
	if i == -1:
		return lua.global_position
	return Rolagem.ponto_de_empurrar(planetas[i].global_position, ninhos[i], p, limites)


## Piloto: vai pro ponto de empurrar e, chegando, atravessa o planetinha rumo ao ninho.
func alvo_auto() -> Vector2:
	var p := mapa.jogador.global_position
	if _auto_i == -1 or planetas[_auto_i].no_ninho:
		_auto_i = _mais_perto(p)
	if _auto_i == -1:
		return lua.global_position
	var bola := planetas[_auto_i].global_position
	var ponto := Rolagem.ponto_de_empurrar(bola, ninhos[_auto_i], p, limites)
	if p.distance_to(ponto) < 50.0:
		return bola + (ninhos[_auto_i] - bola).normalized() * 120.0
	return ponto
