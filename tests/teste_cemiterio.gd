# godot --headless --path . --script res://tests/teste_cemiterio.gd
# Regras puras da fase do cemitério (sem cena).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_chaves_novas", "teste_esconde_sorteio", "teste_esconde_achar_entregar",
			"teste_horta_passos", "teste_horta_erros_nao_perdem", "teste_horta_proximo_passo",
			"teste_labirinto_solucionavel", "teste_labirinto_proximo_vizinho", "teste_labirinto_paredes_fecham"]:
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


func _horta():
	return _classe("estado_horta").new()


func teste_horta_passos() -> bool:
	var h = _horta()
	igual(h.canteiro(0), "vazio", "começa vazio")
	igual(h.usar(0, "semente"), "plantou", "semente no vazio: planta")
	igual(h.canteiro(0), "plantado", "plantado")
	igual(h.usar(0, "agua"), "regou", "água no plantado: rega")
	igual(h.canteiro(0), "crescendo", "crescendo")
	h.crescer(0)
	igual(h.canteiro(0), "pronta", "pronta")
	igual(h.usar(0, ""), "colheu", "mão vazia na pronta: colhe")
	igual(h.canteiro(0), "colhida", "colhida")
	igual(h.entregar(), "entregou", "1ª na carroça")
	for i in [1, 2]:
		h.usar(i, "semente")
		h.usar(i, "agua")
		h.crescer(i)
		h.usar(i, "")
		var r: String = h.entregar()
		igual(r, "fim" if i == 2 else "entregou", "abóbora %d" % (i + 1))
	igual(h.entregues(), 3, "3 entregues")
	return true


func teste_horta_erros_nao_perdem() -> bool:
	var h = _horta()
	igual(h.usar(0, "agua"), "hum", "água no vazio: hum")
	igual(h.canteiro(0), "vazio", "continua vazio")
	h.usar(0, "semente")
	igual(h.usar(0, "semente"), "hum", "semente no plantado: hum")
	igual(h.usar(0, "abobora"), "hum", "abóbora no canteiro: hum")
	igual(h.usar(0, ""), "hum", "mão vazia no plantado: hum")
	igual(h.canteiro(0), "plantado", "continua plantado")
	igual(h.entregues(), 0, "nada entregue")
	return true


func teste_horta_proximo_passo() -> bool:
	var h = _horta()
	igual(h.proximo_passo(""), "sementes", "nada feito: sementes")
	igual(h.proximo_passo("semente"), "canteiro_vazio", "com semente: canteiro vazio")
	h.usar(0, "semente")
	igual(h.proximo_passo(""), "poco", "plantado: poço")
	igual(h.proximo_passo("agua"), "canteiro_plantado", "com água: canteiro plantado")
	h.usar(0, "agua")
	h.crescer(0)
	igual(h.proximo_passo(""), "pronta", "pronta: colher")
	igual(h.proximo_passo("abobora"), "carroca", "com abóbora: carroça")
	igual(h.canteiro_para("canteiro_vazio"), 1, "primeiro canteiro vazio")
	igual(h.canteiro_para("pronta"), 0, "canteiro pronto")
	var nova = _horta()
	igual(nova.proximo_passo("agua"), "poco", "água sem nada plantado: devolve no poço")
	for i in 3:
		nova.usar(i, "semente")
	igual(nova.proximo_passo("semente"), "sementes", "semente sem canteiro vazio: devolve no saco")
	return true


func _lab():
	return _classe("estado_labirinto").padrao()


func teste_labirinto_solucionavel() -> bool:
	var l = _lab()
	var c: Array = l.caminho(l.ENTRADA, l.CHAVE)
	igual(c.is_empty(), false, "existe caminho da entrada até a chave")
	igual(c[0], l.ENTRADA, "começa na entrada")
	igual(c[-1], l.CHAVE, "termina na chave")
	igual(l.becos() >= 2, true, "tem becos sem saída (%d)" % l.becos())
	return true


func teste_labirinto_proximo_vizinho() -> bool:
	var l = _lab()
	var ruins := 0
	for x in l.LARGURA:
		for y in l.ALTURA:
			var de := Vector2i(x, y)
			if de == l.CHAVE:
				continue
			var p: Vector2i = l.proximo(de, l.CHAVE)
			if (p - de).abs().x + (p - de).abs().y != 1 or not l.livre(de, p):
				ruins += 1
	igual(ruins, 0, "de toda célula, o próximo passo é vizinho e sem cerca no meio")
	igual(l.proximo(l.CHAVE, l.CHAVE), l.CHAVE, "na chave: fica")
	return true


func teste_labirinto_paredes_fecham() -> bool:
	var l = _lab()
	igual(l.livre(Vector2i(2, 0), Vector2i(3, 0)), false, "cerca entre (2,0) e (3,0)")
	igual(l.livre(Vector2i(0, 0), Vector2i(1, 0)), true, "passagem entre (0,0) e (1,0)")
	igual(l.livre(Vector2i(0, 0), Vector2i(0, 1)), false, "cerca entre (0,0) e (0,1)")
	igual(l.livre(Vector2i(5, 0), Vector2i(6, 0)), false, "fora da grade: fechado")
	# cada parede interna separa duas células sem passagem
	for r: Rect2i in l.paredes():
		igual(r.size.x > 0 and r.size.y > 0, true, "parede %s com tamanho" % r)
	return true
