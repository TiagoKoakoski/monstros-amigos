class_name EstadoCanos
extends RefCounted
## Os canos do Lobisomem: uma grade de peças (retas e curvas) que giram 90°.
## A água sai da torneira (entra pelo norte da peça TORNEIRA) e tem que chegar
## no vaso (sai pelo sul da peça VASO). Lados: N=1, E=2, S=4, O=8.

const N := 1
const E := 2
const S := 4
const O := 8
const TORNEIRA := Vector2i(0, 0)
const VASO := Vector2i(1, 3)
## lados de cada rotação (girar = próxima, sentido horário)
const LADOS := {
	"reta": [N | S, E | O, N | S, E | O],
	"curva": [N | E, E | S, S | O, O | N],
}
const PASSO := {N: Vector2i(0, -1), E: Vector2i(1, 0), S: Vector2i(0, 1), O: Vector2i(-1, 0)}
const OPOSTO := {N: S, S: N, E: O, O: E}

## célula -> {"tipo", "rot", "solucao"} (solucao -1 = armadilha)
var _pecas: Dictionary = {}


func _init(pecas: Dictionary) -> void:
	for cel: Vector2i in pecas:
		_pecas[cel] = (pecas[cel] as Dictionary).duplicate()


## O quebra-cabeça desenhado à mão (3 colunas x 4 linhas): um caminho só,
## 7 peças começam viradas errado; a curva do meio (1,1) é a armadilha.
static func padrao() -> EstadoCanos:
	return EstadoCanos.new({
		Vector2i(0, 0): {"tipo": "curva", "rot": 2, "solucao": 0},
		Vector2i(1, 0): {"tipo": "reta", "rot": 1, "solucao": 1},
		Vector2i(2, 0): {"tipo": "curva", "rot": 0, "solucao": 2},
		Vector2i(2, 1): {"tipo": "reta", "rot": 1, "solucao": 0},
		Vector2i(2, 2): {"tipo": "curva", "rot": 1, "solucao": 3},
		Vector2i(1, 2): {"tipo": "reta", "rot": 0, "solucao": 1},
		Vector2i(0, 2): {"tipo": "curva", "rot": 3, "solucao": 1},
		Vector2i(0, 3): {"tipo": "curva", "rot": 2, "solucao": 0},
		Vector2i(1, 3): {"tipo": "curva", "rot": 2, "solucao": 2},
		Vector2i(1, 1): {"tipo": "curva", "rot": 0, "solucao": -1},
	})


func celulas() -> Array[Vector2i]:
	var c: Array[Vector2i] = []
	c.assign(_pecas.keys())
	return c


func tipo(cel: Vector2i) -> String:
	return _pecas[cel]["tipo"]


func rot(cel: Vector2i) -> int:
	return _pecas[cel]["rot"]


func armadilha(cel: Vector2i) -> bool:
	return _pecas.has(cel) and int(_pecas[cel]["solucao"]) < 0


func girar(cel: Vector2i) -> void:
	if _pecas.has(cel):
		_pecas[cel]["rot"] = (int(_pecas[cel]["rot"]) + 1) % 4


func lados(cel: Vector2i) -> int:
	if not _pecas.has(cel):
		return 0
	var p: Dictionary = _pecas[cel]
	return LADOS[p["tipo"]][p["rot"]]


func certa(cel: Vector2i) -> bool:
	var p: Dictionary = _pecas[cel]
	return int(p["solucao"]) >= 0 and lados(cel) == LADOS[p["tipo"]][p["solucao"]]


func certas() -> int:
	var n := 0
	for cel: Vector2i in _pecas:
		if certa(cel):
			n += 1
	return n


## Células com água, na ordem em que a água passa (da torneira em diante).
func agua() -> Array[Vector2i]:
	return _correr()[0]


## A água sai pelo sul do vaso?
func conectado() -> bool:
	return _correr()[1]


func _correr() -> Array:
	var cheias: Array[Vector2i] = []
	var cel := TORNEIRA
	var entra := N
	while _pecas.has(cel) and not cheias.has(cel) and (lados(cel) & entra) != 0:
		cheias.append(cel)
		var sai := lados(cel) & ~entra
		if cel == VASO and sai == S:
			return [cheias, true]
		cel += PASSO[sai]
		entra = OPOSTO[sai]
	return [cheias, false]


## A próxima peça do caminho (na ordem da água) que está virada errado.
func proxima_errada() -> Vector2i:
	for cel: Vector2i in caminho():
		if not certa(cel):
			return cel
	return Vector2i(-1, -1)


## O caminho certo, da torneira ao vaso (seguindo a solução).
func caminho() -> Array[Vector2i]:
	var c: Array[Vector2i] = []
	var cel := TORNEIRA
	var entra := N
	while _pecas.has(cel) and not c.has(cel):
		c.append(cel)
		var p: Dictionary = _pecas[cel]
		var sai: int = LADOS[p["tipo"]][p["solucao"]] & ~entra
		if cel == VASO:
			break
		cel += PASSO[sai]
		entra = OPOSTO[sai]
	return c
