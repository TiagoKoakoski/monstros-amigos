class_name EstadoSalas
extends RefCounted
## Uma fase de salas como um todo: a mão (uma coisa por vez), salas
## concluídas, chaves no chaveiro e portas trancadas.
##
## `portas`: porta -> o que abre. Uma cor de CORES_CHAVE = a chave daquela
## cor; qualquer outra coisa = o id de uma sala que precisa terminar (mesmo
## que ela não esteja em `salas`, como o corredor das caixas no castelo).

const CORES_CHAVE: Array[String] = ["azul", "vermelha", "verde", "laranja"]

var carregando := ""
var salas: Array[String] = []
var chave_da_sala: Dictionary = {}
var portas: Dictionary = {}
var _concluidas: Dictionary[String, bool] = {}
var _chaves: Array[String] = []
var _abertas: Dictionary[String, bool] = {}


func _init(p_salas: Array[String] = [], p_chave_da_sala: Dictionary = {}, p_portas: Dictionary = {}) -> void:
	salas = p_salas
	chave_da_sala = p_chave_da_sala
	portas = p_portas


func pegar(item: String) -> bool:
	if carregando != "" or item == "":
		return false
	carregando = item
	return true


func soltar() -> String:
	var item := carregando
	carregando = ""
	return item


## Marca a atividade como concluída e devolve a chave ganha ("" se nenhuma).
func concluir(atividade: String) -> String:
	if _concluidas.get(atividade, false):
		return ""
	_concluidas[atividade] = true
	var chave: String = chave_da_sala.get(atividade, "")
	if chave != "":
		_chaves.append(chave)
	return chave


func concluida(atividade: String) -> bool:
	return _concluidas.get(atividade, false)


func tem_chave(cor: String) -> bool:
	return _chaves.has(cor)


func porta_aberta(porta: String) -> bool:
	return _abertas.get(porta, false)


func cor_da_porta(porta: String) -> String:
	return portas.get(porta, "")


## A porta abre quando uma sala termina (não com chave): não balança a fechadura.
func abre_por_sala(porta: String) -> bool:
	var precisa := cor_da_porta(porta)
	return precisa != "" and not CORES_CHAVE.has(precisa)


## Pode abrir agora? (tem a chave, ou a sala necessária terminou, ou já está aberta)
func pode_abrir(porta: String) -> bool:
	if porta_aberta(porta):
		return true
	var precisa := cor_da_porta(porta)
	if precisa == "":
		return false
	if abre_por_sala(porta):
		return concluida(precisa)
	return tem_chave(precisa)


func tentar_abrir(porta: String) -> bool:
	if porta_aberta(porta):
		return true
	if not pode_abrir(porta):
		return false
	_chaves.erase(cor_da_porta(porta))
	_abertas[porta] = true
	return true


func todas_salas() -> bool:
	for sala: String in salas:
		if not concluida(sala):
			return false
	return true
