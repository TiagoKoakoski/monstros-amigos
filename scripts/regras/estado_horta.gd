class_name EstadoHorta
extends RefCounted
## A horta: cada canteiro vai de vazio -> plantado -> crescendo -> pronta ->
## colhida. Semente e água nunca acabam (e voltam pro saco/poço se não têm
## onde usar); levar a coisa errada é "hum" e nada muda.

const TOTAL := 3

var _canteiros: Array[String] = []
var _entregues := 0


func _init(canteiros: int = TOTAL) -> void:
	_canteiros.resize(canteiros)
	_canteiros.fill("vazio")


func canteiro(i: int) -> String:
	return _canteiros[i]


## `na_mao`: "", "semente", "agua" ou "abobora". Devolve "plantou", "regou",
## "colheu" ou "hum".
func usar(i: int, na_mao: String) -> String:
	match [na_mao, _canteiros[i]]:
		["semente", "vazio"]:
			_canteiros[i] = "plantado"
			return "plantou"
		["agua", "plantado"]:
			_canteiros[i] = "crescendo"
			return "regou"
		["", "pronta"]:
			_canteiros[i] = "colhida"
			return "colheu"
	return "hum"


func crescer(i: int) -> void:
	if _canteiros[i] == "crescendo":
		_canteiros[i] = "pronta"


func entregar() -> String:
	_entregues += 1
	return "fim" if _entregues >= _canteiros.size() else "entregou"


func entregues() -> int:
	return _entregues


## O que fazer agora (pro vaga-lume): "canteiro_vazio", "canteiro_plantado",
## "carroca", "pronta", "poco", "sementes" (pegar, ou devolver o que não tem
## onde usar) ou "" (crescendo, é só esperar).
func proximo_passo(na_mao: String) -> String:
	match na_mao:
		"semente":
			return "canteiro_vazio" if canteiro_para("canteiro_vazio") != -1 else "sementes"
		"agua":
			return "canteiro_plantado" if canteiro_para("canteiro_plantado") != -1 else "poco"
		"abobora":
			return "carroca"
	if canteiro_para("pronta") != -1:
		return "pronta"
	if canteiro_para("canteiro_plantado") != -1:
		return "poco"
	if canteiro_para("canteiro_vazio") != -1 and _entregues + _colhendo() < _canteiros.size():
		return "sementes"
	return ""


## Primeiro canteiro que serve pro passo (-1 se nenhum).
func canteiro_para(passo: String) -> int:
	var quer: String = {"canteiro_vazio": "vazio", "canteiro_plantado": "plantado", "pronta": "pronta"}.get(passo, "")
	return _canteiros.find(quer) if quer != "" else -1


func _colhendo() -> int:
	return _canteiros.count("plantado") + _canteiros.count("crescendo") + _canteiros.count("pronta")
