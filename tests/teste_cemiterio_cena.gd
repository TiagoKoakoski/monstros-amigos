# godot --headless --path . res://tests/teste_cemiterio_cena.tscn
# A porta dos fundos do laboratório e o cemitério montados de verdade (cenas),
# sem o piloto automático. É cena (não --script) porque precisa do autoload Jogo.
extends Node

const PROGRESSO := "user://progresso_teste_cemi_cena.cfg"

var passou := 0
var falhou := 0


func _ready() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var jogo := Jogo
	jogo.ja_iniciou = true
	jogo.progresso = Progresso.new(PROGRESSO)  # nunca o da criança
	jogo.progresso.apagar()
	for t: String in ["teste_porta_fundos_fechada_sem_progresso", "teste_porta_fundos_aberta_com_progresso",
			"teste_porta_fundos_fora_do_caminho", "teste_cemiterio_marca_progresso"]:
		if await call(t) != true:
			falhou += 1
			push_error("FALHOU %s: não terminou" % t)
	jogo.progresso.apagar()
	print("Resultado: %d ok, %d falhas" % [passou, falhou])
	get_tree().quit(1 if falhou > 0 else 0)


func igual(atual: Variant, esperado: Variant, rotulo: String) -> void:
	if atual == esperado:
		passou += 1
	else:
		falhou += 1
		push_error("FALHOU %s: esperado %s, veio %s" % [rotulo, esperado, atual])


func _cena(caminho: String) -> Node:
	var c := (load(caminho) as PackedScene).instantiate()
	add_child(c)
	await get_tree().process_frame
	await get_tree().process_frame
	return c


func _fora(c: Node) -> void:
	remove_child(c)
	c.free()
	Jogo.progresso.apagar()


func teste_porta_fundos_fechada_sem_progresso() -> bool:
	var l := await _cena(Jogo.LABORATORIO) as Laboratorio
	igual(l.porta_fundos.aberta, false, "sem progresso: porta dos fundos fechada")
	l.jogador.global_position = Laboratorio.PORTA_FUNDOS
	l.checar_interacoes()
	igual(l._pela_porta, false, "fechada: encostar não sai")
	_fora(l)
	return true


func teste_porta_fundos_aberta_com_progresso() -> bool:
	Jogo.progresso.marcar("cemiterio")
	var l := await _cena(Jogo.LABORATORIO) as Laboratorio
	igual(l.porta_fundos.aberta, true, "com cemitério no progresso: porta já aberta")
	_fora(l)
	return true


func teste_porta_fundos_fora_do_caminho() -> bool:
	var l := await _cena(Jogo.LABORATORIO) as Laboratorio
	for sala: String in ["pocoes", "canos", "formas"]:
		var ate := l._passar(Laboratorio.VAOS[sala], Laboratorio.SALAO)
		var perto := Geometry2D.get_closest_point_to_segment(Laboratorio.PORTA_FUNDOS, l.inicio, ate)
		var d := perto.distance_to(Laboratorio.PORTA_FUNDOS)
		igual(d > PortaFundos.RAIO + 60.0, true, "caminho escada -> %s longe da porta dos fundos (%.0f px)" % [sala, d])
	_fora(l)
	return true


func teste_cemiterio_marca_progresso() -> bool:
	var c := await _cena(Jogo.CEMITERIO)
	for f: String in ["castelo", "laboratorio", "cemiterio"]:
		igual(Jogo.progresso.alcancou(f), true, "cemitério marca %s" % f)
	_fora(c)
	return true

