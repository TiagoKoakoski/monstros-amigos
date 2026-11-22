class_name Quarto
extends Atividade
## Quarto do Lobisomem: 3 filhotinhos fugiram da cama. Encostar num filhote
## faz ele seguir a criança em fila; levar até a cama e eles dormem.

const RAIO_FILHOTE := 90.0
const RAIO_CAMA := 210.0
const ESPACO_FILA := 16  # pontos do rastro entre um filhote e outro

var estado: EstadoFilhotes
var filhotes: Array[Filhote] = []
var lobis: Monstro
var cama_pos := Vector2.ZERO
var _rastro: Array[Vector2] = []
var _lugares: Array[Vector2] = []
var _deitados := 0


func montar() -> void:
	id = "quarto"
	estado = EstadoFilhotes.new(3)
	castelo.carregar_som("filhote")
	var o := area.position
	castelo.piso(area, Color("#e8c3d6"), Color("#dbb1c7"), false)
	castelo.tocha(o + Vector2(200, 0))
	castelo.tocha(o + Vector2(800, 0))
	cama_pos = o + Vector2(760, 330)
	castelo.enfeite("cama", cama_pos, Vector2.ZERO)
	for dx: float in [-90.0, 0.0, 90.0]:
		_lugares.append(cama_pos + Vector2(dx, -60))

	lobis = Monstro.new()
	lobis.configurar("lobisomem", "", load("res://arte/lobisomem.svg") as Texture2D, load("res://arte/filhote.svg") as Texture2D)
	var desenhos: Array[Texture2D] = []
	for i in 3:
		desenhos.append(load("res://arte/filhote.svg") as Texture2D)
	lobis.mostrar_varios(desenhos)
	lobis.position = o + Vector2(330, 330)
	castelo.no_mundo(lobis)

	# passeiam na parte de baixo do quarto, longe da cama
	var zona := Rect2(o + Vector2(120, 430), Vector2(760, 250))
	for p: Vector2 in [o + Vector2(160, 690), o + Vector2(520, 420), o + Vector2(880, 700)]:
		var f := Filhote.new()
		f.configurar(zona)
		f.position = p
		castelo.no_mundo(f)
		filhotes.append(f)


func _physics_process(delta: float) -> void:
	if castelo == null or castelo.jogador == null:
		return
	var p := castelo.jogador.global_position
	if _rastro.is_empty() or _rastro[-1].distance_to(p) > 6.0:
		_rastro.append(p)
		if _rastro.size() > 200:
			_rastro.pop_front()
	var fila := 0
	for i in filhotes.size():
		match estado.estado(i):
			"solto":
				filhotes[i].soltinho(delta, p if contem(p) else Vector2.INF)
			"seguindo":
				fila += 1
				var idx := maxi(0, _rastro.size() - 1 - fila * ESPACO_FILA)
				filhotes[i].seguir(_rastro[idx], delta)


func checar(p: Vector2) -> void:
	if terminada():
		return
	for i in filhotes.size():
		if estado.estado(i) == "solto" and p.distance_to(filhotes[i].global_position) < RAIO_FILHOTE:
			estado.pegar(i)
			filhotes[i].pegar()
			castelo.tocar("filhote")
			castelo.progresso_feito()
			castelo.marco("filhote", 0.5)
	if not estado.seguidores().is_empty() and p.distance_to(cama_pos) < RAIO_CAMA:
		var quem := estado.seguidores()
		estado.deitar_seguidores()
		for i: int in quem:
			filhotes[i].deitar(_lugares[_deitados])
			lobis.marcar_icone(_deitados)
			_deitados += 1
		castelo.tocar("entregar")
		castelo.progresso_feito()
		castelo.marco("cama", 0.8)
		if estado.todos_na_cama():
			lobis.concluir()
			castelo.marco("quarto", 1.2)
			terminar()


func monstro() -> Monstro:
	return lobis


func alvo() -> Vector2:
	if not estado.seguidores().is_empty():
		return cama_pos
	var melhor := cama_pos
	var menor := INF
	for i in filhotes.size():
		if estado.estado(i) != "solto":
			continue
		var d := castelo.jogador.global_position.distance_to(filhotes[i].global_position)
		if d < menor:
			menor = d
			melhor = filhotes[i].global_position
	return melhor


func alvo_auto() -> Vector2:
	# pega todos antes de ir pra cama (mais rápido) — a criança pode levar um por vez
	for i in filhotes.size():
		if estado.estado(i) == "solto":
			var melhor := filhotes[0].global_position
			var menor := INF
			for j in filhotes.size():
				if estado.estado(j) == "solto":
					var d := castelo.jogador.global_position.distance_to(filhotes[j].global_position)
					if d < menor:
						menor = d
						melhor = filhotes[j].global_position
			return melhor
	return cama_pos
