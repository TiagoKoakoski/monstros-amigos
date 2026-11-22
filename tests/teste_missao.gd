# godot --headless --path . --script res://tests/teste_missao.gd
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_inicio", "teste_pegar_um_por_vez", "teste_entregar_errado_nao_perde",
			"teste_entregar_certo", "teste_jogo_completo", "teste_nao_pega_item_ja_entregue",
			"teste_controles"]:
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


func novo() -> EstadoMissao:
	var p: Dictionary[String, String] = {
		"dracula": "morcego", "frankenstein": "flor", "mumia": "faixa", "lobisomem": "bola"}
	return EstadoMissao.new(p)


func teste_inicio() -> bool:
	var m := novo()
	igual(m.carregando, "", "começa de mão vazia")
	igual(m.itens_no_chao().size(), 4, "quatro itens no chão")
	igual(m.todos_ajudados(), false, "ninguém ajudado no início")
	return true


func teste_pegar_um_por_vez() -> bool:
	var m := novo()
	igual(m.pegar("bola"), true, "pega a bola")
	igual(m.pegar("flor"), false, "não pega segundo item com a mão cheia")
	igual(m.carregando, "bola", "continua com a bola")
	igual(m.itens_no_chao().has("bola"), false, "bola saiu do chão")
	return true


func teste_entregar_errado_nao_perde() -> bool:
	var m := novo()
	m.pegar("bola")
	igual(m.entregar("dracula"), false, "drácula não quer a bola")
	igual(m.carregando, "bola", "entregar errado não tira o item da mão")
	igual(m.foi_ajudado("dracula"), false, "drácula segue esperando")
	return true


func teste_entregar_certo() -> bool:
	var m := novo()
	m.pegar("bola")
	igual(m.entregar("lobisomem"), true, "lobisomem recebe a bola")
	igual(m.carregando, "", "mão fica vazia")
	igual(m.foi_ajudado("lobisomem"), true, "lobisomem ajudado")
	igual(m.entregar("lobisomem"), false, "não ajuda duas vezes")
	return true


func teste_jogo_completo() -> bool:
	var m := novo()
	for monstro: String in ["dracula", "frankenstein", "mumia", "lobisomem"]:
		m.pegar(m.pedidos[monstro])
		m.entregar(monstro)
	igual(m.todos_ajudados(), true, "todos ajudados ao final")
	igual(m.quantos_ajudados(), 4, "contagem final 4")
	igual(m.itens_no_chao().size(), 0, "nada sobra no chão")
	return true


func teste_nao_pega_item_ja_entregue() -> bool:
	var m := novo()
	m.pegar("flor")
	m.entregar("frankenstein")
	igual(m.pode_pegar("flor"), false, "flor entregue não volta pra mão")
	igual(m.pode_pegar("inexistente"), false, "item que não existe")
	return true


func teste_controles() -> bool:
	load("res://scripts/controles.gd").configurar()
	for acao: String in ["mover_esquerda", "mover_direita", "mover_cima", "mover_baixo", "acao", "sair"]:
		igual(InputMap.has_action(acao), true, "ação %s existe" % acao)
	igual(InputMap.action_get_deadzone("mover_esquerda"), 0.25, "zona morta do analógico")
	var tem_controle := false
	var tem_teclado := false
	for ev: InputEvent in InputMap.action_get_events("acao"):
		if ev is InputEventJoypadButton:
			tem_controle = true
		if ev is InputEventKey:
			tem_teclado = true
	igual(tem_controle and tem_teclado, true, "ação no controle e no teclado")
	var sair_no_controle := false
	for ev: InputEvent in InputMap.action_get_events("sair"):
		if ev is InputEventJoypadButton:
			sair_no_controle = true
	igual(sair_no_controle, false, "sair NÃO está no controle")
	return true
