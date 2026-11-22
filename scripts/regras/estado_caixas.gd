class_name EstadoCaixas
extends RefCounted
## Marcas do corredor: caixa perto de uma marca livre encaixa e não sai mais.

var marcas: Array[Vector2] = []
var raio := 70.0
var _ocupante: Array[int] = []  # índice da caixa em cada marca, -1 = livre


func _init(p_marcas: Array[Vector2], p_raio: float = 70.0) -> void:
	marcas = p_marcas.duplicate()
	raio = p_raio
	_ocupante.resize(marcas.size())
	_ocupante.fill(-1)


## Devolve o índice da marca onde a caixa encaixou, ou -1.
func tentar_encaixar(caixa: int, pos: Vector2) -> int:
	if encaixada(caixa):
		return -1
	for i in marcas.size():
		if _ocupante[i] == -1 and pos.distance_to(marcas[i]) <= raio:
			_ocupante[i] = caixa
			return i
	return -1


func encaixada(caixa: int) -> bool:
	return _ocupante.has(caixa)


func marca_livre(i: int) -> bool:
	return _ocupante[i] == -1


func completo() -> bool:
	return not _ocupante.has(-1)
