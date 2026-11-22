# godot --headless --path . --script res://tests/teste_cemiterio.gd
# Regras puras da fase do cemitério (sem cena).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_chaves_novas"]:
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
