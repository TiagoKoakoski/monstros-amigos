# godot --headless --path . --script res://tests/teste_laboratorio.gd
# Regras puras da fase do laboratório (sem cena).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_progresso_por_fase", "teste_estado_salas", "teste_mistura", "teste_pedidos_em_ordem",
			"teste_ajuda"]:
		if call(t) != true:
			falhou += 1
			push_error("FALHOU %s: não terminou (erro em tempo de execução?)" % t)
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	quit(1 if falhou > 0 else 0)


func igual(atual: Variant, esperado: Variant, rotulo: String) -> void:
	if atual == esperado:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU %s: esperado %s, veio %s" % [rotulo, esperado, atual])


func _classe(nome: String) -> Variant:
	return load("res://scripts/regras/%s.gd" % nome)


func teste_progresso_por_fase() -> bool:
	var classe = _classe("progresso")
	var caminho := "user://progresso_teste_lab.cfg"
	var p = classe.new(caminho)
	p.apagar()
	igual(p.alcancou("castelo"), false, "novo: castelo não alcançado")
	igual(p.alcancou("laboratorio"), false, "novo: laboratório não alcançado")
	p.marcar("laboratorio")
	var relido = classe.new(caminho)
	igual(relido.alcancou("laboratorio"), true, "laboratório salvo e lido de novo")
	igual(relido.alcancou("castelo"), false, "marcar o laboratório não marca o castelo sozinho")
	p.apagar()
	# arquivo do formato antigo (antes do laboratório)
	var antigo := ConfigFile.new()
	antigo.set_value("jogo", "castelo_aberto", true)
	antigo.save(caminho)
	var velho = classe.new(caminho)
	igual(velho.castelo_aberto(), true, "formato antigo: castelo aberto")
	igual(velho.alcancou("castelo"), true, "formato antigo conta como castelo alcançado")
	velho.apagar()
	igual(classe.new(caminho).alcancou("castelo"), false, "apagar zera")
	return true


func teste_estado_salas() -> bool:
	var classe = _classe("estado_salas")
	var salas: Array[String] = ["a", "b"]
	var e = classe.new(salas, {"a": "verde"}, {"b": "verde", "c": "b"})
	igual(e.pode_abrir("b"), false, "porta b sem chave")
	igual(e.concluir("a"), "verde", "sala a dá chave verde")
	igual(e.tentar_abrir("b"), true, "chave verde abre b")
	igual(e.abre_por_sala("c"), true, "porta c abre por sala (não é cor)")
	igual(e.abre_por_sala("b"), false, "porta b abre por chave")
	igual(e.cor_da_porta("b"), "verde", "cor da porta b")
	igual(e.pode_abrir("c"), false, "c fechada até b terminar")
	igual(e.todas_salas(), false, "falta b")
	e.concluir("b")
	igual(e.pode_abrir("c"), true, "b terminou: c pode abrir")
	igual(e.todas_salas(), true, "a e b feitas")
	var vazio: Array[String] = []
	igual(classe.new(vazio, {}, {}).todas_salas(), true, "sem salas = todas feitas")
	return true


func teste_mistura() -> bool:
	var c = _classe("estado_pocoes")
	for par: Array in [["azul", "amarelo", "verde"], ["vermelho", "amarelo", "laranja"],
			["vermelho", "azul", "roxo"], ["vermelho", "branco", "rosa"]]:
		igual(c.misturar(par[0], par[1]), par[2], "%s + %s" % [par[0], par[1]])
		igual(c.misturar(par[1], par[0]), par[2], "%s + %s (ordem trocada)" % [par[1], par[0]])
	igual(c.misturar("azul", "azul"), "azul", "mesma cor duas vezes = a própria cor")
	igual(c.PEDIDOS.has(c.misturar("azul", "branco")), false, "azul + branco não é pedido")
	igual(c.receita("verde"), ["azul", "amarelo"] as Array[String], "receita do verde")
	return true


func teste_pedidos_em_ordem() -> bool:
	var e = _classe("estado_pocoes").new()
	igual(e.pedido_atual(), "verde", "primeiro pedido: verde")
	igual(e.colocar("azul"), "dentro", "uma cor: fica no caldeirão")
	igual(e.caldeirao, ["azul"] as Array[String], "caldeirão com azul")
	igual(e.colocar("amarelo"), "certo", "azul + amarelo = verde")
	igual(e.pedido_atual(), "laranja", "depois: laranja")
	igual(e.caldeirao.is_empty(), true, "caldeirão esvazia depois da poção")
	e.colocar("vermelho")
	igual(e.colocar("azul"), "plop", "roxo fora da vez: plop")
	igual(e.caldeirao.is_empty(), true, "plop esvazia")
	igual(e.feitos(), 1, "plop não tira o que já foi feito")
	igual(e.pedido_atual(), "laranja", "plop não muda o pedido")
	e.colocar("amarelo")
	igual(e.colocar("vermelho"), "certo", "laranja")
	e.colocar("vermelho")
	igual(e.colocar("azul"), "certo", "roxo")
	e.colocar("branco")
	igual(e.colocar("vermelho"), "fim", "rosa: último")
	igual(e.pedido_atual(), "", "sem pedido no fim")
	igual(e.colocar("azul"), "ignorado", "depois do fim: ignorado")
	return true


func teste_ajuda() -> bool:
	var e = _classe("estado_pocoes").new()
	igual(e.ajuda("azul"), true, "verde: azul ajuda")
	igual(e.ajuda("vermelho"), false, "verde: vermelho não ajuda")
	igual(e.faltam(), ["azul", "amarelo"] as Array[String], "faltam azul e amarelo")
	e.colocar("azul")
	igual(e.ajuda("azul"), false, "azul já está dentro")
	igual(e.faltam(), ["amarelo"] as Array[String], "falta amarelo")
	var e2 = _classe("estado_pocoes").new()
	e2.colocar("vermelho")
	igual(e2.ajuda("azul"), false, "com cor errada dentro: nada ajuda (vai dar plop)")
	return true

