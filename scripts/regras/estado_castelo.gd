class_name EstadoCastelo
extends RefCounted
## O castelo como um todo: a mão (uma coisa por vez), salas concluídas,
## chaves no chaveiro e portas trancadas.

const SALAS := ["cozinha", "musica", "biblioteca", "quarto"]
const CHAVE_DA_SALA := {"cozinha": "azul", "musica": "vermelha"}
## porta -> cor da chave que abre ("caixas" = abre quando o corredor termina)
const PORTAS := {"biblioteca": "azul", "caixas": "vermelha", "quarto": "caixas"}

var carregando := ""
var _concluidas: Dictionary[String, bool] = {}
var _chaves: Array[String] = []
var _abertas: Dictionary[String, bool] = {}


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
	var chave: String = CHAVE_DA_SALA.get(atividade, "")
	if chave != "":
		_chaves.append(chave)
	return chave


func concluida(atividade: String) -> bool:
	return _concluidas.get(atividade, false)


func tem_chave(cor: String) -> bool:
	return _chaves.has(cor)


func porta_aberta(porta: String) -> bool:
	return _abertas.get(porta, false)


## Pode abrir agora? (tem a chave, ou já está aberta)
func pode_abrir(porta: String) -> bool:
	if porta_aberta(porta):
		return true
	var precisa: String = PORTAS.get(porta, "")
	if precisa == "caixas":
		return concluida("caixas")
	return precisa != "" and tem_chave(precisa)


func tentar_abrir(porta: String) -> bool:
	if porta_aberta(porta):
		return true
	if not pode_abrir(porta):
		return false
	var precisa: String = PORTAS[porta]
	_chaves.erase(precisa)
	_abertas[porta] = true
	return true


func todas_salas() -> bool:
	for sala: String in SALAS:
		if not concluida(sala):
			return false
	return true
