class_name EstadoSequencia
extends RefCounted
## A música do Drácula: rodadas de sequências de cores para repetir pisando.
## Errar recomeça a MESMA sequência da rodada; nunca volta rodada.

var rodada := 0
var _sequencias: Array = []  # Array de Array[int]
var _indice := 0


## `opostos`: cor -> cor que fica no canto oposto (ir de uma à outra no
## direcional passa por cima de outro ladrilho); nunca ficam seguidas.
## `entre_grupos`: a regra vale também da última de um grupo pra primeira do
## próximo (as Formas, onde os grupos vêm um atrás do outro sem demonstração).
func _init(semente: int, tamanhos: Array[int] = [2, 3, 4], cores: int = 4, opostos: Dictionary = {},
		entre_grupos := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var ultima := -1
	for tam: int in tamanhos:
		var seq: Array[int] = []
		for i in tam:
			var anterior := seq[i - 1] if i > 0 else (ultima if entre_grupos else -1)
			var c := rng.randi_range(0, cores - 1)
			while anterior != -1 and (c == anterior or opostos.get(anterior, -1) == c):
				c = rng.randi_range(0, cores - 1)
			seq.append(c)
		ultima = seq[-1]
		_sequencias.append(seq)


func sequencia() -> Array[int]:
	var seq: Array[int] = _sequencias[mini(rodada, _sequencias.size() - 1)]
	return seq.duplicate()


func proxima_cor() -> int:
	if terminou():
		return -1
	return _sequencias[rodada][_indice]


## "certo", "rodada" (fechou e avançou), "erro", "fim" ou "ignorado".
func pisar(cor: int) -> String:
	if terminou():
		return "ignorado"
	if cor != proxima_cor():
		_indice = 0
		return "erro"
	_indice += 1
	if _indice < _sequencias[rodada].size():
		return "certo"
	_indice = 0
	rodada += 1
	return "fim" if terminou() else "rodada"


func terminou() -> bool:
	return rodada >= _sequencias.size()
