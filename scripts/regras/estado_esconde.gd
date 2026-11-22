class_name EstadoEsconde
extends RefCounted
## Esconde-esconde dos fantasminhas: alguns esconderijos têm um fantasminha
## (sorteados pela semente). Achar = ele passa a seguir a criança; entregar na
## mamãe = todos os que seguem ficam com ela. Esconderijo vazio não muda nada.

var _tem: Array[bool] = []
## "escondido", "seguindo", "entregue" para os que têm fantasminha
var _estado: Dictionary[int, String] = {}
var _ordem: Array[int] = []  # ordem em que foram achados (a fila)


func _init(semente: int, esconderijos: int = 10, fantasmas: int = 5) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var lugares: Array[int] = []
	for i in esconderijos:
		lugares.append(i)
		_tem.append(false)
	for k in fantasmas:
		var j := rng.randi_range(k, esconderijos - 1)
		var troca := lugares[k]
		lugares[k] = lugares[j]
		lugares[j] = troca
		_tem[lugares[k]] = true
		_estado[lugares[k]] = "escondido"


func tem_fantasma(i: int) -> bool:
	return i >= 0 and i < _tem.size() and _tem[i]


## "achou", "vazio" ou "ja_achado".
func achar(i: int) -> String:
	if not tem_fantasma(i):
		return "vazio"
	if _estado[i] != "escondido":
		return "ja_achado"
	_estado[i] = "seguindo"
	_ordem.append(i)
	return "achou"


## Esconderijos dos que estão seguindo, na ordem da fila.
func seguindo() -> Array[int]:
	var s: Array[int] = []
	for i: int in _ordem:
		if _estado[i] == "seguindo":
			s.append(i)
	return s


func entregar() -> int:
	var n := 0
	for i: int in seguindo():
		_estado[i] = "entregue"
		n += 1
	return n


func entregues() -> int:
	var n := 0
	for i: int in _estado:
		if _estado[i] == "entregue":
			n += 1
	return n


func faltam_achar() -> Array[int]:
	var f: Array[int] = []
	for i: int in _estado:
		if _estado[i] == "escondido":
			f.append(i)
	return f


func terminou() -> bool:
	return entregues() == _estado.size()
