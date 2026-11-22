class_name Arena
extends Atividade
## Pega-pega com o Fantasmão: encostar nele 3 vezes. Ele foge mais devagar
## que a criança e cansa, então sempre dá pra pegar (até com o analógico devagar).

const VEZES := 3

var fantasmao: Fantasmao
var _rendeu := false
var _dono: Monstro


func montar() -> void:
	id = "arena"
	var o := area.position
	mapa.piso(area, Color("#8cc4ab"), Color("#7fb8a0"), false)
	for pos: Vector2 in [o + Vector2(120, 150), o + Vector2(1080, 150), o + Vector2(120, 900), o + Vector2(1080, 900)]:
		var ab := Visual.sprite_em_pe(load("res://arte/abobora.svg") as Texture2D)
		ab.position = pos
		mapa.no_mundo(ab)
	mapa.carregar_som("peguei")
	fantasmao = Fantasmao.new()
	fantasmao.configurar(area)
	fantasmao.position = o + Vector2(600, 600)
	mapa.no_mundo(fantasmao)


func checar(p: Vector2) -> void:
	if terminada():
		return
	if not contem(p):
		return
	if fantasmao.mover(get_physics_process_delta_time(), p):
		mapa.tocar("peguei")
		mapa.progresso_feito()
		mapa.marco("pegou_%d" % fantasmao.pegadas, 0.3)
		if fantasmao.pegadas >= VEZES:
			fantasmao.render()
			mapa.tocar("entregar")
			mapa.marco("arena", 1.2)
			terminar()


## O Fantasmão também vai pra festa.
func convidados() -> Array[Node2D]:
	var c: Array[Node2D] = [fantasmao]
	return c


func alvo() -> Vector2:
	return fantasmao.global_position


func alvo_auto() -> Vector2:
	return fantasmao.global_position
