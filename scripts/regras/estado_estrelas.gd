class_name EstadoEstrelas
extends RefCounted
## Estrelas cadentes da Coruja: caem em pontos sorteados (nunca perto da
## Coruja, da criança ou de outra estrela esperando), no máximo `juntas`
## esperando ao mesmo tempo. Estrela no chão espera pra sempre; pegar
## `total` termina.

const LONGE_DA_CORUJA := 320.0
const LONGE_DA_CRIANCA := 300.0
const LONGE_DE_OUTRA := 260.0
const TENTATIVAS := 40

var _rng := RandomNumberGenerator.new()
var _limites := Rect2()
var _coruja := Vector2.ZERO
var _total := 6
var _juntas := 3
var _esperando: Dictionary = {}  # id -> posição
var _proximo_id := 0
var _pegas := 0


func _init(semente: int, limites: Rect2, evitar: Vector2, total := 6, juntas := 3) -> void:
	_rng.seed = semente
	_limites = limites
	_coruja = evitar
	_total = total
	_juntas = juntas


func pode_cair() -> bool:
	return _esperando.size() < _juntas and _pegas + _esperando.size() < _total


## Ponto pra próxima estrela cair. Sem lugar que respeite tudo, o candidato
## mais longe da criança (e da Coruja).
func sortear(crianca: Vector2) -> Vector2:
	var melhor := _limites.get_center()
	var melhor_folga := -INF
	for k in TENTATIVAS:
		var p := Vector2(_rng.randf_range(_limites.position.x, _limites.end.x),
			_rng.randf_range(_limites.position.y, _limites.end.y))
		var folga := minf(p.distance_to(_coruja) - LONGE_DA_CORUJA, p.distance_to(crianca) - LONGE_DA_CRIANCA)
		for q: Vector2 in _esperando.values():
			folga = minf(folga, p.distance_to(q) - LONGE_DE_OUTRA)
		if folga >= 0.0:
			return p
		if folga > melhor_folga:
			melhor_folga = folga
			melhor = p
	return melhor


func cair(p: Vector2) -> int:
	var id := _proximo_id
	_proximo_id += 1
	_esperando[id] = p
	return id


func esperando() -> Dictionary:
	return _esperando.duplicate()


## "pegou", "fim" ou "ignorado" (não existe / já pega).
func pegar(id: int) -> String:
	if not _esperando.has(id):
		return "ignorado"
	_esperando.erase(id)
	_pegas += 1
	return "fim" if terminou() else "pegou"


func pegas() -> int:
	return _pegas


func terminou() -> bool:
	return _pegas >= _total
