class_name EstadoPocoes
extends RefCounted
## As poções do Frankenstein: duas cores no caldeirão viram uma mistura.
## Se for a cor pedida, sai a poção e vem o próximo pedido; se não, "plop":
## o caldeirão esvazia (nada mais se perde).

const PEDIDOS: Array[String] = ["verde", "laranja", "roxo", "rosa"]
const RECEITAS := {
	"verde": ["azul", "amarelo"],
	"laranja": ["vermelho", "amarelo"],
	"roxo": ["vermelho", "azul"],
	"rosa": ["vermelho", "branco"],
}

var caldeirao: Array[String] = []
var _feitos := 0


## Ordem não importa; mesma cor duas vezes = a própria cor.
static func misturar(a: String, b: String) -> String:
	if a == b:
		return a
	for cor: String in RECEITAS:
		var r: Array = RECEITAS[cor]
		if r.has(a) and r.has(b):
			return cor
	return "marrom"


static func receita(pedido: String) -> Array[String]:
	var r: Array[String] = []
	r.assign(RECEITAS.get(pedido, []))
	return r


func pedido_atual() -> String:
	return PEDIDOS[_feitos] if _feitos < PEDIDOS.size() else ""


func feitos() -> int:
	return _feitos


## "dentro" (1ª cor), "certo", "fim" (último pedido), "plop" ou "ignorado".
func colocar(cor: String) -> String:
	if pedido_atual() == "":
		return "ignorado"
	if caldeirao.is_empty():
		caldeirao.append(cor)
		return "dentro"
	var mistura := misturar(caldeirao[0], cor)
	caldeirao.clear()
	if mistura != pedido_atual():
		return "plop"
	_feitos += 1
	return "fim" if pedido_atual() == "" else "certo"


## Cores da receita atual que ainda não estão no caldeirão.
func faltam() -> Array[String]:
	var f: Array[String] = []
	for c: String in receita(pedido_atual()):
		if not caldeirao.has(c):
			f.append(c)
	return f


## Pôr esta cor agora ajuda? (é da receita e o caldeirão não tem cor errada)
func ajuda(cor: String) -> bool:
	for c: String in caldeirao:
		if not receita(pedido_atual()).has(c):
			return false
	return faltam().has(cor)
