class_name EstadoMissao
extends RefCounted
## Quem quer o quê, o que está na mão e quem já foi ajudado.
##
## Lógica pura, sem nó nem cena, para dar pra testar sem abrir o jogo.
## Regras pensadas para uma criança aprendendo: carrega uma coisa por vez,
## não dá pra soltar, e entregar para o monstro errado não tira nada dela.

## monstro -> item que ele quer
var pedidos: Dictionary[String, String] = {}
## item que está na mão agora ("" = mão vazia)
var carregando: String = ""
var _ajudados: Dictionary[String, bool] = {}


func _init(pedidos_iniciais: Dictionary[String, String]) -> void:
	pedidos = pedidos_iniciais.duplicate()
	for monstro: String in pedidos:
		_ajudados[monstro] = false


func pode_pegar(item: String) -> bool:
	return carregando == "" and _item_existe(item) and not item_entregue(item)


func pegar(item: String) -> bool:
	if not pode_pegar(item):
		return false
	carregando = item
	return true


## Entrega o que está na mão. Só funciona com o monstro certo; com o errado,
## nada muda (a criança continua com o item e o guia mostra o caminho).
func entregar(monstro: String) -> bool:
	if not pedidos.has(monstro) or _ajudados[monstro]:
		return false
	if carregando == "" or carregando != pedidos[monstro]:
		return false
	_ajudados[monstro] = true
	carregando = ""
	return true


func foi_ajudado(monstro: String) -> bool:
	return _ajudados.get(monstro, false)


func item_entregue(item: String) -> bool:
	var dono := dono_do_item(item)
	return dono != "" and foi_ajudado(dono)


func dono_do_item(item: String) -> String:
	for monstro: String in pedidos:
		if pedidos[monstro] == item:
			return monstro
	return ""


func todos_ajudados() -> bool:
	for monstro: String in _ajudados:
		if not _ajudados[monstro]:
			return false
	return true


func quantos_ajudados() -> int:
	var n := 0
	for monstro: String in _ajudados:
		if _ajudados[monstro]:
			n += 1
	return n


## Itens que ainda estão no chão esperando alguém pegar.
func itens_no_chao() -> Array[String]:
	var lista: Array[String] = []
	for monstro: String in pedidos:
		var item: String = pedidos[monstro]
		if not _ajudados[monstro] and item != carregando:
			lista.append(item)
	return lista


func _item_existe(item: String) -> bool:
	return dono_do_item(item) != ""
