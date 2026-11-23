class_name Constelacoes
extends Atividade
## Constelações do Gato astrônomo: estrelas grandes no chão formam o contorno
## de um desenho. A próxima pisca dourada; encostar nela acende e um risco de
## luz liga a anterior a ela (a criança desenha andando). Fechou: o desenho
## sobe pro céu e vem o próximo. Gato (6), morcego (7), peixe (8).

const RAIO := 100.0
## longe assim de uma estrela, ela pode ser tocada de novo
const SAIR := 160.0
const DOURADO := Color("#ffe27a")
const DESENHOS: Array[String] = ["desenho_gato", "desenho_morcego", "desenho_peixe"]

var constelacoes: EstadoConstelacoes
var gato: Monstro
var _estrelas: Array[Sprite2D] = []
var _riscos: Line2D
var _desenho_no: Node2D
var _perto := -1
var _tempo := 0.0
var _auto_errou := false


func montar() -> void:
	id = "constelacoes"
	mapa.piso(area, Color("#3f4a80"), Color("#394375"), false)
	constelacoes = EstadoConstelacoes.new(EstadoConstelacoes.padrao())
	var icones: Array[Texture2D] = []
	for nome: String in DESENHOS:
		icones.append(load("res://arte/%s.svg" % nome) as Texture2D)
	gato = Monstro.new()
	gato.configurar("gato_astronomo", "", load("res://arte/gato_astronomo.svg") as Texture2D, icones[0])
	gato.mostrar_varios(icones)
	gato.position = area.position + Vector2(1000, 880)
	mapa.no_mundo(gato)
	for i in 8:
		mapa.carregar_som("astro_%d" % i)
	mapa.carregar_som("constelacao")
	_montar_desenho()


func _montar_desenho() -> void:
	_desenho_no = Node2D.new()
	mapa.no_chao(_desenho_no)
	_riscos = Line2D.new()
	_riscos.width = 10.0
	_riscos.default_color = DOURADO
	_riscos.joint_mode = Line2D.LINE_JOINT_ROUND
	_desenho_no.add_child(_riscos)
	_estrelas.clear()
	var tex := load("res://arte/estrela_grande.svg") as Texture2D
	for i in constelacoes.pontos().size():
		var s := Sprite2D.new()
		s.texture = tex
		s.position = _pos(i)
		_desenho_no.add_child(s)
		_estrelas.append(s)
	_perto = -1
	_animar()


func _pos(i: int) -> Vector2:
	return area.position + (constelacoes.pontos()[i] as Vector2)


func checar(p: Vector2) -> void:
	if terminada():
		return
	_tempo += get_physics_process_delta_time()
	if _perto != -1 and p.distance_to(_pos(_perto)) > SAIR:
		_perto = -1
	if _perto == -1:
		for i in _estrelas.size():
			if p.distance_to(_pos(i)) < RAIO:
				_perto = i
				_tocar(i)
				break
	_animar()


func _tocar(i: int) -> void:
	var antes := constelacoes.desenho()
	var r := constelacoes.tocar(i)
	match r:
		"certo":
			_riscos.add_point(_pos(i))
			mapa.tocar("astro_%d" % (constelacoes.acesas() - 1))
			mapa.progresso_feito()
		"errado":
			_auto_errou = true
			var s := _estrelas[i]
			var t := create_tween()
			t.tween_property(s, "rotation", 0.5, 0.12)
			t.tween_property(s, "rotation", -0.5, 0.12)
			t.tween_property(s, "rotation", 0.0, 0.12)
			mapa.marco("estrela_errada", 0.3)
		"desenho", "fim":
			_fechar(antes)
			if r == "fim":
				gato.concluir()
				mapa.marco("constelacoes", 1.2)
				terminar()
			else:
				_montar_desenho()


## Fecha o desenho `indice`: risco de volta à primeira, som, sobe pro céu.
func _fechar(indice: int) -> void:
	var pts: Array = EstadoConstelacoes.padrao()[indice]
	var mundo: Array[Vector2] = []
	for q: Vector2 in pts:
		mundo.append(area.position + q)
	_riscos.add_point(mundo[-1])
	_riscos.add_point(mundo[0])
	for s: Sprite2D in _estrelas:
		s.scale = Vector2.ONE
		s.modulate = Color.WHITE
	mapa.tocar("constelacao")
	mapa.progresso_feito()
	mapa.marco("desenho_%d" % (indice + 1), 0.6)
	gato.marcar_icone(indice)
	if mapa is Telhado:
		(mapa as Telhado).ceu.mostrar_constelacao(mundo, indice, true)
	var sobe := _desenho_no
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_property(sobe, "position:y", -500.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(sobe, "modulate:a", 0.0, 1.6)
	t.tween_callback(sobe.queue_free)


## Próxima estrela pisca grande e dourada; acesas brilham; as outras ficam pequenas.
func _animar() -> void:
	var prox := constelacoes.proxima()
	for i in _estrelas.size():
		var s := _estrelas[i]
		if i < constelacoes.acesas():
			s.scale = Vector2.ONE * 0.8
			s.modulate = Color(1.0, 0.95, 0.7)
		elif i == prox:
			s.scale = Vector2.ONE * (0.95 + 0.2 * sin(_tempo * 6.0))
			s.modulate = DOURADO
		else:
			s.scale = Vector2.ONE * 0.5
			s.modulate = Color(0.75, 0.78, 0.95, 0.75)


func monstro() -> Monstro:
	return gato


func alvo() -> Vector2:
	if constelacoes.terminou():
		return gato.global_position
	return _pos(constelacoes.proxima())


## Piloto: toca uma estrela errada de propósito uma vez (a mais perto que não é a próxima).
func alvo_auto() -> Vector2:
	if _auto_errou or constelacoes.terminou():
		return alvo()
	var p := mapa.jogador.global_position
	var melhor := alvo()
	var menor := INF
	for i in _estrelas.size():
		if i == constelacoes.proxima():
			continue
		if p.distance_to(_pos(i)) < menor:
			menor = p.distance_to(_pos(i))
			melhor = _pos(i)
	return melhor
