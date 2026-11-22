class_name Atividade
extends Node2D
## Base de cada sala de uma fase de salas (castelo, laboratório). A sala monta suas coisas em montar(), olha a
## criança em checar() e diz pro vaga-lume (alvo) e pro piloto automático
## (alvo_auto) para onde ir. Quando termina, chama terminar().

signal concluida(id: String)

var id := ""
## Retângulo do chão da sala, em coordenadas do mundo.
var area := Rect2()
var mapa: FaseDeSalas
var _terminada := false


func configurar(p_mapa: FaseDeSalas, p_area: Rect2) -> void:
	mapa = p_mapa
	area = p_area


## Cria as coisas da sala. O que tem altura vai em mapa.no_mundo().
func montar() -> void:
	pass


## Chamado todo frame de física com a posição da criança.
func checar(_jogador_pos: Vector2) -> void:
	pass


func alvo() -> Vector2:
	return area.get_center()


func alvo_auto() -> Vector2:
	return alvo()


## Esta sala é quem quer este item? (pra levar de volta quando ele sai com ele)
func dona_de(_item: String) -> bool:
	return false


## O monstro desta sala (pra festa e pra chave sair dele).
func monstro() -> Monstro:
	return null


func terminada() -> bool:
	return _terminada


func terminar() -> void:
	if _terminada:
		return
	_terminada = true
	concluida.emit(id)


func contem(p: Vector2) -> bool:
	return area.has_point(p)
