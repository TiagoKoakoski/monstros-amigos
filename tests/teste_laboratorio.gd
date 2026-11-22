# godot --headless --path . --script res://tests/teste_laboratorio.gd
# Regras puras da fase do laboratório (sem cena).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_progresso_por_fase"]:
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
