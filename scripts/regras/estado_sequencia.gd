class_name EstadoSequencia
extends RefCounted
## A música do Drácula: rodadas de sequências de cores para repetir pisando.
## Errar recomeça a MESMA sequência da rodada; nunca volta rodada.

var rodada := 0
var _sequencias: Array = []  # Array de Array[int]
var _indice := 0


func _init(semente: int, tamanhos: Array[int] = [2, 3, 4], cores: int = 4) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for tam: int in tamanhos:
		var seq: Array[int] = []
		for i in tam:
			var c := rng.randi_range(0, cores - 1)
			while i > 0 and c == seq[i - 1]:
				c = rng.randi_range(0, cores - 1)
			seq.append(c)
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
