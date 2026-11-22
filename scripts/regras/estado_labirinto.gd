class_name EstadoLabirinto
extends RefCounted
## O labirinto de cerca viva como grade. O desenho é texto: `#` cerca, `.`
## livre; as células ficam nas posições ímpares (célula (c, l) = caractere
## (2c+1, 2l+1)) e o caractere entre duas células diz se há passagem.

const LARGURA := 6
const ALTURA := 5
const ENTRADA := Vector2i(2, 4)
const CHAVE := Vector2i(0, 0)
## desenhado à mão: um caminho só até a chave, com becos sem saída
const PADRAO: Array[String] = [
	"#############",
	"#K....#.....#",
	"#####.#.###.#",
	"#.....#...#.#",
	"#.#####.#.#.#",
	"#.#.....#...#",
	"#.#.#####.###",
	"#...#.......#",
	"#.###.#####.#",
	"#.#...#.....#",
	"#####.#######",
]

var _texto: Array[String] = []


func _init(texto: Array[String]) -> void:
	_texto = texto


static func padrao() -> EstadoLabirinto:
	return EstadoLabirinto.new(PADRAO)


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < LARGURA and c.y < ALTURA


## Vizinhas sem cerca no meio.
func livre(de: Vector2i, para: Vector2i) -> bool:
	if not dentro(de) or not dentro(para):
		return false
	var d := (para - de).abs()
	if d.x + d.y != 1:
		return false
	return _texto[de.y + para.y + 1][de.x + para.x + 1] != "#"


func vizinhos(c: Vector2i) -> Array[Vector2i]:
	var v: Array[Vector2i] = []
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if livre(c, c + d):
			v.append(c + d)
	return v


## Caminho mais curto (inclui as pontas); vazio se não há.
func caminho(de: Vector2i, ate: Vector2i) -> Array[Vector2i]:
	var veio: Dictionary = {de: de}
	var fila: Array[Vector2i] = [de]
	while not fila.is_empty():
		var c: Vector2i = fila.pop_front()
		if c == ate:
			break
		for n: Vector2i in vizinhos(c):
			if not veio.has(n):
				veio[n] = c
				fila.append(n)
	if not veio.has(ate):
		return []
	var cam: Array[Vector2i] = [ate]
	while cam[0] != de:
		cam.push_front(veio[cam[0]])
	return cam


## Próxima célula rumo a `ate` (a própria, se já chegou ou não há caminho).
func proximo(de: Vector2i, ate: Vector2i) -> Vector2i:
	var cam := caminho(de, ate)
	return cam[1] if cam.size() >= 2 else de


func becos() -> int:
	var n := 0
	for x in LARGURA:
		for y in ALTURA:
			var c := Vector2i(x, y)
			if c != ENTRADA and c != CHAVE and vizinhos(c).size() == 1:
				n += 1
	return n


## Cercas internas em coordenadas do texto (cada `#` fora da borda vira um
## pedaço). A borda de fora é a cerca da própria área.
func paredes() -> Array[Rect2i]:
	var r: Array[Rect2i] = []
	for y in range(1, _texto.size() - 1):
		for x in range(1, _texto[y].length() - 1):
			if _texto[y][x] == "#":
				r.append(Rect2i(x, y, 1, 1))
	return r
