class_name EstadoReceita
extends RefCounted
## Coisas que um monstro quer receber (uma ou várias) e quais já chegaram.
## Entregar algo que não está na receita não muda nada.

var _itens: Array[String] = []
var _entregues: Array[String] = []


func _init(itens: Array[String]) -> void:
	_itens = itens.duplicate()


func quer(item: String) -> bool:
	return _itens.has(item) and not _entregues.has(item)


func entregar(item: String) -> bool:
	if not quer(item):
		return false
	_entregues.append(item)
	return true


func itens() -> Array[String]:
	return _itens.duplicate()


func entregues() -> Array[String]:
	return _entregues.duplicate()


func falta() -> Array[String]:
	var lista: Array[String] = []
	for item: String in _itens:
		if not _entregues.has(item):
			lista.append(item)
	return lista


func completa() -> bool:
	return _entregues.size() == _itens.size()
