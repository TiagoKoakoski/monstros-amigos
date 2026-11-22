# godot --headless --path . --script res://tests/teste_cemiterio.gd
# Regras puras da fase do cemitério (sem cena).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_chaves_novas", "teste_esconde_sorteio", "teste_esconde_achar_entregar"]:
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


func teste_chaves_novas() -> bool:
	var salas: Array[String] = ["a"]
	var e = _classe("estado_salas").new(salas, {"a": "rosa"}, {"b": "rosa"})
	igual(e.abre_por_sala("b"), false, "rosa é cor de chave (não sala)")
	igual(e.concluir("a"), "rosa", "sala a dá chave rosa")
	igual(e.tentar_abrir("b"), true, "chave rosa abre b")
	for cor: String in ["roxa", "amarela", "rosa"]:
		igual(e.CORES_CHAVE.has(cor), true, "cor de chave: %s" % cor)
	return true


func teste_esconde_sorteio() -> bool:
	var c = _classe("estado_esconde")
	var a = c.new(7)
	var b = c.new(7)
	var com := []
	for i in 10:
		if a.tem_fantasma(i):
			com.append(i)
		igual(a.tem_fantasma(i), b.tem_fantasma(i), "mesma semente, mesmo esconderijo %d" % i)
	igual(com.size(), 5, "5 fantasminhas em 10 esconderijos")
	var sempre_cinco := true
	var variou := false
	for semente in range(1, 51):
		var e = c.new(semente)
		var n := 0
		for i in 10:
			if e.tem_fantasma(i):
				n += 1
			if e.tem_fantasma(i) != a.tem_fantasma(i):
				variou = true
		if n != 5:
			sempre_cinco = false
	igual(sempre_cinco, true, "sementes 1..50: sempre 5")
	igual(variou, true, "sementes diferentes mudam os esconderijos")
	return true


func teste_esconde_achar_entregar() -> bool:
	var e = _classe("estado_esconde").new(7)
	var cheios := []
	var vazio := -1
	for i in 10:
		if e.tem_fantasma(i):
			cheios.append(i)
		elif vazio == -1:
			vazio = i
	igual(e.achar(vazio), "vazio", "esconderijo vazio")
	igual(e.seguindo().size(), 0, "vazio não muda nada")
	igual(e.achar(cheios[0]), "achou", "achou o 1º")
	igual(e.achar(cheios[1]), "achou", "achou o 2º")
	igual(e.achar(cheios[0]), "ja_achado", "o mesmo de novo: já achado")
	igual(e.seguindo().size(), 2, "2 seguindo")
	igual(e.faltam_achar().size(), 3, "faltam 3")
	igual(e.entregar(), 2, "entregou 2")
	igual(e.seguindo().size(), 0, "ninguém seguindo")
	igual(e.entregar(), 0, "entregar de novo: nada")
	for i in range(2, 5):
		e.achar(cheios[i])
	igual(e.terminou(), false, "achados mas não entregues")
	e.entregar()
	igual(e.entregues(), 5, "5 entregues")
	igual(e.terminou(), true, "terminou")
	return true
