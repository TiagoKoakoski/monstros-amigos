# godot --headless --path . --script res://tests/teste_castelo.gd
# Regras puras da fase do castelo (sem cena).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_receita", "teste_sequencia_tamanhos", "teste_sequencia_erro_nao_regride",
			"teste_sequencia_demo_e_reentrada", "teste_velas", "teste_caixas", "teste_filhotes",
			"teste_chaves_e_portas", "teste_mao_cheia_entre_salas", "teste_progresso"]:
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


func teste_receita() -> bool:
	var itens: Array[String] = ["ovo", "morango", "leite"]
	var r = _classe("estado_receita").new(itens)
	igual(r.quer("ovo"), true, "receita quer ovo")
	igual(r.entregar("bola"), false, "bola não é da receita")
	igual(r.entregar("ovo"), true, "entrega ovo")
	igual(r.entregar("ovo"), false, "ovo não entra duas vezes")
	igual(r.quer("ovo"), false, "já não quer ovo")
	igual(r.falta(), ["morango", "leite"] as Array[String], "falta morango e leite")
	igual(r.completa(), false, "ainda incompleta")
	r.entregar("morango")
	r.entregar("leite")
	igual(r.completa(), true, "receita completa")
	igual(r.entregues().size(), 3, "três entregues")
	return true


func _percorrer(s) -> Array:
	var tamanhos := []
	while not s.terminou():
		var n := 0
		var r := ""
		while true:
			r = s.pisar(s.proxima_cor())
			n += 1
			if r != "certo":
				break
		tamanhos.append(n)
	return tamanhos


func teste_sequencia_tamanhos() -> bool:
	var classe = _classe("estado_sequencia")
	igual(_percorrer(classe.new(1)), [2, 3, 4], "rodadas de 2, 3 e 4 notas")
	var repetiu := false
	var fora := false
	for semente in 50:
		var s = classe.new(semente)
		for rod in 3:
			s.rodada = rod
			var seq: Array[int] = s.sequencia()
			for i in seq.size():
				if seq[i] < 0 or seq[i] > 3:
					fora = true
				if i > 0 and seq[i] == seq[i - 1]:
					repetiu = true
	igual(repetiu, false, "nunca a mesma cor duas vezes seguidas")
	igual(fora, false, "cores sempre de 0 a 3")
	return true


func teste_sequencia_erro_nao_regride() -> bool:
	var s = _classe("estado_sequencia").new(3)
	s.pisar(s.proxima_cor())
	igual(s.pisar(s.proxima_cor()), "rodada", "fecha a rodada 0")
	igual(s.rodada, 1, "foi pra rodada 1")
	var primeira: int = s.sequencia()[0]
	s.pisar(s.proxima_cor())
	var errada: int = (s.proxima_cor() + 1) % 4
	igual(s.pisar(errada), "erro", "cor errada é erro")
	igual(s.rodada, 1, "erro não volta rodada")
	igual(s.proxima_cor(), primeira, "erro recomeça a mesma sequência")
	var ultimo := ""
	while not s.terminou():
		ultimo = s.pisar(s.proxima_cor())
	igual(ultimo, "fim", "última nota dá fim")
	igual(s.pisar(0), "ignorado", "depois do fim é ignorado")
	return true


func teste_sequencia_demo_e_reentrada() -> bool:
	# A demo e a reentrada são da sala (autoplay da Task 5); aqui: errar no
	# meio de uma rodada nunca muda a rodada.
	var s = _classe("estado_sequencia").new(9)
	s.pisar(s.proxima_cor())
	s.pisar(s.proxima_cor())
	s.pisar(s.proxima_cor())
	igual(s.rodada, 1, "na rodada 1 depois de 3 notas certas")
	s.pisar((s.proxima_cor() + 2) % 4)
	igual(s.rodada, 1, "erro no meio mantém rodada")
	return true


func teste_velas() -> bool:
	var v = _classe("estado_velas").new(5)
	igual(v.acender(2), true, "acende a vela 2")
	igual(v.acender(2), false, "vela 2 já acesa")
	igual(v.acender(9), false, "vela que não existe")
	igual(v.acesa(2), true, "vela 2 acesa")
	for i in 5:
		v.acender(i)
	igual(v.todas(), true, "todas acesas")
	igual(v.acesas(), 5, "cinco acesas")
	return true


func teste_caixas() -> bool:
	var marcas: Array[Vector2] = [Vector2(0, 0), Vector2(500, 0)]
	var c = _classe("estado_caixas").new(marcas, 70.0)
	igual(c.tentar_encaixar(0, Vector2(200, 0)), -1, "longe da marca não encaixa")
	igual(c.tentar_encaixar(0, Vector2(40, 30)), 0, "perto encaixa na marca 0")
	igual(c.encaixada(0), true, "caixa 0 encaixada")
	igual(c.tentar_encaixar(1, Vector2(10, 0)), -1, "marca ocupada")
	igual(c.completo(), false, "falta uma")
	igual(c.tentar_encaixar(1, Vector2(480, 10)), 1, "caixa 1 na marca 1")
	igual(c.tentar_encaixar(0, Vector2(480, 10)), -1, "caixa encaixada não sai")
	igual(c.completo(), true, "completo")
	return true


func teste_filhotes() -> bool:
	var f = _classe("estado_filhotes").new(3)
	igual(f.estado(0), "solto", "começa solto")
	igual(f.pegar(0), true, "pega filhote 0")
	igual(f.pegar(0), false, "não pega duas vezes")
	igual(f.seguidores(), [0] as Array[int], "filhote 0 seguindo")
	igual(f.deitar_seguidores(), 1, "deita um")
	igual(f.estado(0), "cama", "filhote 0 na cama")
	igual(f.pegar(0), false, "da cama não sai")
	f.pegar(1)
	f.pegar(2)
	igual(f.deitar_seguidores(), 2, "deita dois")
	igual(f.todos_na_cama(), true, "todos na cama")
	return true


func teste_chaves_e_portas() -> bool:
	var c = _classe("estado_castelo").new()
	igual(c.tentar_abrir("biblioteca"), false, "biblioteca trancada")
	igual(c.concluir("cozinha"), "azul", "cozinha dá chave azul")
	igual(c.concluir("cozinha"), "", "concluir de novo não dá chave")
	igual(c.tentar_abrir("caixas"), false, "chave azul não abre a vermelha")
	igual(c.tentar_abrir("biblioteca"), true, "chave azul abre biblioteca")
	igual(c.tem_chave("azul"), false, "chave gasta")
	igual(c.porta_aberta("biblioteca"), true, "biblioteca aberta")
	igual(c.tentar_abrir("biblioteca"), true, "porta aberta continua abrindo")
	igual(c.tentar_abrir("quarto"), false, "quarto trancado")
	igual(c.concluir("musica"), "vermelha", "música dá chave vermelha")
	igual(c.tentar_abrir("caixas"), true, "vermelha abre corredor")
	igual(c.concluir("caixas"), "", "caixas não dá chave")
	igual(c.tentar_abrir("quarto"), true, "caixas abrem quarto")
	igual(c.todas_salas(), false, "faltam salas")
	c.concluir("biblioteca")
	c.concluir("quarto")
	igual(c.todas_salas(), true, "todas as salas")
	return true


func teste_mao_cheia_entre_salas() -> bool:
	var c = _classe("estado_castelo").new()
	igual(c.pegar("ovo"), true, "pega ovo")
	igual(c.pegar("livro"), false, "mão cheia não pega livro")
	igual(c.carregando, "ovo", "continua com ovo")
	igual(c.soltar(), "ovo", "solta ovo")
	igual(c.pegar("livro"), true, "agora pega livro")
	return true


func teste_progresso() -> bool:
	var classe = _classe("progresso")
	var caminho := "user://progresso_teste_unit.cfg"
	var p = classe.new(caminho)
	p.apagar()
	igual(p.castelo_aberto(), false, "começa fechado")
	p.marcar_castelo_aberto()
	igual(classe.new(caminho).castelo_aberto(), true, "progresso salvo e lido de novo")
	p.apagar()
	igual(classe.new(caminho).castelo_aberto(), false, "apagar zera")
	return true
