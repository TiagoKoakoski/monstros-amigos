class_name Biblioteca
extends Atividade
## Biblioteca da Múmia: sala em penumbra azulada (nunca preta). Encostar nas
## 5 velas acende; com todas acesas a sala clareia e aparece o livro de
## figuras que a Múmia perdeu. Levar o livro até ela.

const ESCURO := Color(0.10, 0.12, 0.30)
const ALFA_ESCURO := 0.55
const RAIO_VELA := 110.0

var velas_estado: EstadoVelas
var receita: EstadoReceita
var velas: Array[Vela] = []
var mumia: Monstro
var livro: ItemPerdido
var _penumbra: Polygon2D
var _lanterna: Sprite2D


func montar() -> void:
	id = "biblioteca"
	velas_estado = EstadoVelas.new(5)
	receita = EstadoReceita.new(["livro"] as Array[String])
	castelo.carregar_som("vela")
	var o := area.position
	castelo.piso(area, Color("#c9a77c"), Color("#b8956a"), false)
	for x: float in [180.0, 500.0, 1300.0, 1620.0]:
		castelo.enfeite("estante", o + Vector2(x, 260), Vector2(250, 60))
	castelo.enfeite("estante", o + Vector2(900, 560), Vector2(250, 60))

	var lugares: Array[Vector2] = [Vector2(160, 640), Vector2(660, 330), Vector2(900, 720), Vector2(1140, 330), Vector2(1640, 650)]
	for p: Vector2 in lugares:
		var v := Vela.new()
		v.position = o + p
		castelo.no_mundo(v)
		velas.append(v)

	mumia = Monstro.new()
	mumia.configurar("mumia", "livro", load("res://arte/mumia.svg") as Texture2D, load("res://arte/livro.svg") as Texture2D)
	mumia.position = o + Vector2(1450, 520)
	castelo.no_mundo(mumia)

	livro = ItemPerdido.new()
	livro.configurar("livro", load("res://arte/livro.svg") as Texture2D)
	livro.position = o + Vector2(1180, 640)
	livro.visible = false
	livro.no_chao = false
	castelo.no_mundo(livro)

	_penumbra = Polygon2D.new()
	_penumbra.polygon = PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)])
	_penumbra.color = Color(ESCURO.r, ESCURO.g, ESCURO.b, ALFA_ESCURO)
	_penumbra.z_index = 5
	add_child(_penumbra)
	_lanterna = Visual.luz(Color(1.0, 0.85, 0.55, 0.0), 560.0)
	_lanterna.z_index = 6
	add_child(_lanterna)


func checar(p: Vector2) -> void:
	var dentro := contem(p)
	var precisa_luz := dentro and not velas_estado.todas()
	_lanterna.global_position = p + Vector2(0, -80)
	_lanterna.modulate.a = lerpf(_lanterna.modulate.a, 0.5 if precisa_luz else 0.0, 0.1)
	if terminada():
		return
	for i in velas.size():
		if not velas[i].acesa and p.distance_to(velas[i].global_position) < RAIO_VELA:
			velas_estado.acender(i)
			velas[i].acender()
			castelo.tocar("vela")
			castelo.progresso_feito()
			castelo.marco("vela", 0.6)
			_atualizar_penumbra()
			if velas_estado.todas():
				_mostrar_livro()
	if livro.visible and livro.no_chao and castelo.mao_vazia() and p.distance_to(livro.global_position) < Fase.RAIO_ITEM:
		castelo.dar_na_mao(livro, "livro")
	if castelo.estado.carregando == "livro" and p.distance_to(mumia.global_position) < Fase.RAIO_MONSTRO:
		var no := castelo.tirar_da_mao()
		receita.entregar("livro")
		mumia.receber(no)
		castelo.tocar("entregar")
		castelo.progresso_feito()
		castelo.marco("biblioteca", 1.2)
		terminar()
	elif castelo.estado.carregando != "" and castelo.estado.carregando != "livro" \
			and p.distance_to(mumia.global_position) < Fase.RAIO_MONSTRO and mumia.lembrar_pedido():
		castelo.tocar("hum")


func _atualizar_penumbra() -> void:
	var alvo := ALFA_ESCURO * (1.0 - float(velas_estado.acesas()) / velas_estado.total())
	create_tween().tween_property(_penumbra, "color:a", alvo, 0.6)


func _mostrar_livro() -> void:
	castelo.marco("velas", 1.6)
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_callback(func() -> void:
		livro.visible = true
		livro.no_chao = true
		livro.scale = Vector2.ZERO
		castelo.tocar("brilho"))
	t.tween_property(livro, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func monstro() -> Monstro:
	return mumia


func dona_de(item: String) -> bool:
	return item == "livro"


func alvo() -> Vector2:
	if castelo.estado.carregando == "livro":
		return mumia.global_position
	if livro.visible and livro.no_chao:
		return livro.global_position
	var melhor := mumia.global_position
	var menor := INF
	for v: Vela in velas:
		if v.acesa:
			continue
		var d := castelo.jogador.global_position.distance_to(v.global_position)
		if d < menor:
			menor = d
			melhor = v.global_position
	return melhor
