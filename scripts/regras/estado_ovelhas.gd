class_name EstadoOvelhas
extends RefCounted
## Ovelhinhas de nuvem: cada uma dá um pulinho brincalhão uma vez só, depois
## deixa pegar e segue a criança; na porteira as que seguem são guardadas
## (pode guardar aos poucos). Todas guardadas → fim.

var _n := 4
var _assustou: Array[bool] = []
## "solta", "seguindo" ou "guardada"
var _estado: Array[String] = []
var _fila: Array[int] = []
var _guardadas := 0


func _init(n := 4) -> void:
	_n = n
	for i in n:
		_assustou.append(false)
		_estado.append("solta")


## true só no 1º encontro, com ela solta.
func assustar(i: int) -> bool:
	if i < 0 or i >= _n or _estado[i] != "solta" or _assustou[i]:
		return false
	_assustou[i] = true
	return true


func pegar(i: int) -> bool:
	if i < 0 or i >= _n or _estado[i] != "solta":
		return false
	_estado[i] = "seguindo"
	_fila.append(i)
	return true


func seguindo() -> Array[int]:
	return _fila.duplicate()


func soltas() -> Array[int]:
	var r: Array[int] = []
	for i in _n:
		if _estado[i] == "solta":
			r.append(i)
	return r


## Guarda as que estão seguindo; devolve quais.
func guardar() -> Array[int]:
	var r := _fila.duplicate()
	for i: int in r:
		_estado[i] = "guardada"
	_guardadas += r.size()
	_fila.clear()
	return r


func guardadas() -> int:
	return _guardadas


func terminou() -> bool:
	return _guardadas >= _n
