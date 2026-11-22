class_name EstadoFilhotes
extends RefCounted
## Filhotes do Lobisomem: soltos, seguindo a criança, ou dormindo na cama.

var _estados: Array[String] = []


func _init(total: int = 3) -> void:
	_estados.resize(total)
	_estados.fill("solto")


func estado(i: int) -> String:
	return _estados[i]


func pegar(i: int) -> bool:
	if _estados[i] != "solto":
		return false
	_estados[i] = "seguindo"
	return true


func seguidores() -> Array[int]:
	var lista: Array[int] = []
	for i in _estados.size():
		if _estados[i] == "seguindo":
			lista.append(i)
	return lista


func deitar_seguidores() -> int:
	var n := 0
	for i in _estados.size():
		if _estados[i] == "seguindo":
			_estados[i] = "cama"
			n += 1
	return n


func total() -> int:
	return _estados.size()


func todos_na_cama() -> bool:
	return _estados.count("cama") == _estados.size()
