class_name EstadoVelas
extends RefCounted
## Velas da biblioteca: acender ao encostar; acesa fica acesa.

var _acesas: Array[bool] = []


func _init(total: int = 5) -> void:
	_acesas.resize(total)
	_acesas.fill(false)


func acender(i: int) -> bool:
	if i < 0 or i >= _acesas.size() or _acesas[i]:
		return false
	_acesas[i] = true
	return true


func acesa(i: int) -> bool:
	return i >= 0 and i < _acesas.size() and _acesas[i]


func acesas() -> int:
	return _acesas.count(true)


func total() -> int:
	return _acesas.size()


func todas() -> bool:
	return acesas() == _acesas.size()
