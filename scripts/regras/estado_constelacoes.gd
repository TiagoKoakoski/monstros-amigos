class_name EstadoConstelacoes
extends RefCounted
## Ligar as estrelas na ordem: só a próxima estrela do desenho conta; tocar
## outra não muda nada (nem apaga). Fechou um desenho, passa pro próximo.
## Os desenhos são fechados (a última liga na primeira sozinha).

var _desenhos: Array = []
var _desenho := 0
var _acesas := 0


func _init(desenhos: Array) -> void:
	_desenhos = desenhos


## Gato (6), morcego (7) e peixe (8), em posições locais da área (1200 × 1000).
static func padrao() -> Array:
	var gato: Array[Vector2] = [Vector2(250, 150), Vector2(450, 380), Vector2(750, 380), Vector2(950, 150),
		Vector2(900, 750), Vector2(300, 750)]
	var morcego: Array[Vector2] = [Vector2(150, 250), Vector2(420, 150), Vector2(600, 330), Vector2(780, 150),
		Vector2(1050, 250), Vector2(780, 720), Vector2(420, 720)]
	var peixe: Array[Vector2] = [Vector2(200, 450), Vector2(420, 220), Vector2(700, 220), Vector2(850, 450),
		Vector2(1050, 230), Vector2(1050, 700), Vector2(700, 700), Vector2(420, 700)]
	return [gato, morcego, peixe]


func desenho() -> int:
	return _desenho


func pontos() -> Array:
	return _desenhos[mini(_desenho, _desenhos.size() - 1)]


## Índice da próxima estrela do desenho atual (-1 no fim).
func proxima() -> int:
	return -1 if terminou() else _acesas


func acesas() -> int:
	return _acesas


## "certo", "desenho" (fechou e passou pro próximo), "fim", "errado" ou "ignorado".
func tocar(i: int) -> String:
	if terminou() or i < _acesas:
		return "ignorado"
	if i != _acesas:
		return "errado"
	_acesas += 1
	if _acesas < (_desenhos[_desenho] as Array).size():
		return "certo"
	_acesas = 0
	_desenho += 1
	return "fim" if terminou() else "desenho"


func terminou() -> bool:
	return _desenho >= _desenhos.size()


static func menor_distancia(pts: Array) -> float:
	var menor := INF
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			menor = minf(menor, (pts[i] as Vector2).distance_to(pts[j]))
	return menor


## Menor distância de uma estrela a um risco entre duas outras seguidas
## (contando o risco que fecha o desenho).
static func folga_dos_riscos(pts: Array) -> float:
	var menor := INF
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		for k in n:
			if k == i or k == (i + 1) % n:
				continue
			var p: Vector2 = pts[k]
			menor = minf(menor, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return menor
