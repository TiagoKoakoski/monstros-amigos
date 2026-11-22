# godot --headless --path . res://tests/teste_laboratorio_cena.tscn
# O alçapão do castelo e o laboratório montados de verdade (cenas), sem o
# piloto automático. É cena (não --script) porque precisa do autoload Jogo.
extends Node

const PROGRESSO := "user://progresso_teste_lab_cena.cfg"

var passou := 0
var falhou := 0


func _ready() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var jogo := Jogo
	jogo.ja_iniciou = true
	jogo.progresso = Progresso.new(PROGRESSO)  # nunca o da criança
	jogo.progresso.apagar()
	for t: String in ["teste_alcapao_fechado_sem_progresso", "teste_alcapao_aberto_com_progresso",
			"teste_alcapao_fora_do_caminho", "teste_laboratorio_marca_progresso", "teste_plop_nao_cala_o_vagalume",
			"teste_caminho_pro_alcapao_sai_da_sala"]:
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


## Monta uma fase de verdade e espera ela ficar pronta.
func _cena(caminho: String) -> Node:
	var c := (load(caminho) as PackedScene).instantiate()
	add_child(c)
	await get_tree().process_frame
	await get_tree().process_frame
	return c


func _fora(c: Node) -> void:
	remove_child(c)
	c.free()


func teste_alcapao_fechado_sem_progresso() -> bool:
	Jogo.progresso.apagar()
	var c := await _cena(Jogo.CASTELO) as Castelo
	igual(c.alcapao.aberto, false, "sem progresso: alçapão fechado")
	c.jogador.global_position = Castelo.ALCAPAO
	c.checar_interacoes()
	igual(c._descendo, false, "alçapão fechado: encostar não desce")
	_fora(c)
	return true


func teste_alcapao_aberto_com_progresso() -> bool:
	Jogo.progresso.apagar()
	Jogo.progresso.marcar("laboratorio")
	var c := await _cena(Jogo.CASTELO) as Castelo
	igual(c.alcapao.aberto, true, "com laboratório no progresso: alçapão já aberto")
	_fora(c)
	Jogo.progresso.apagar()
	return true


func teste_alcapao_fora_do_caminho() -> bool:
	var c := await _cena(Jogo.CASTELO) as Castelo
	for sala: String in ["cozinha", "musica", "biblioteca", "caixas"]:
		var ate := c._passar(Castelo.VAOS[sala], Castelo.SALAO)
		var perto := Geometry2D.get_closest_point_to_segment(Castelo.ALCAPAO, c.inicio, ate)
		var d := perto.distance_to(Castelo.ALCAPAO)
		igual(d > Alcapao.RAIO + 60.0, true, "caminho entrada -> %s passa longe do alçapão (%.0f px)" % [sala, d])
	_fora(c)
	Jogo.progresso.apagar()
	return true


func teste_laboratorio_marca_progresso() -> bool:
	Jogo.progresso.apagar()
	var l := await _cena(Jogo.LABORATORIO)
	igual(Jogo.progresso.alcancou("castelo"), true, "laboratório marca o castelo")
	igual(Jogo.progresso.alcancou("laboratorio"), true, "laboratório marca o laboratório")
	_fora(l)
	Jogo.progresso.apagar()
	return true


func teste_plop_nao_cala_o_vagalume() -> bool:
	var l := await _cena(Jogo.LABORATORIO) as Laboratorio
	var p := l.atividades["pocoes"] as Pocoes
	l._tempo_sem_progresso = 0.0
	for i in 20:
		l._tempo_sem_progresso += 1.0
		p._pegar("vermelho")
		p._colocar("vermelho")  # verde pedido: vermelho não ajuda (dentro, depois plop)
	igual(l.tempo_sem_progresso() >= 12.0, true, "20 s pegando e fazendo plop: vaga-lume ainda vem")
	p._pegar("azul")
	p._colocar("azul")
	igual(l.tempo_sem_progresso(), 0.0, "cor que ajuda conta como avanço")
	_fora(l)
	Jogo.progresso.apagar()
	return true


func teste_caminho_pro_alcapao_sai_da_sala() -> bool:
	var c := await _cena(Jogo.CASTELO) as Castelo
	c._ir_pro_alcapao = true
	c.jogador.global_position = Castelo.AREAS["quarto"].get_center()
	igual(c.alvo_atual(), c._passar(Castelo.VAOS["quarto"], Castelo.AREAS["caixas"]), "no quarto: vaga-lume mostra a saída pro corredor")
	c.jogador.global_position = Castelo.AREAS["cozinha"].get_center()
	igual(c.alvo_atual(), c._passar(Castelo.VAOS["cozinha"], Castelo.SALAO), "na cozinha: mostra a porta pro salão")
	c.jogador.global_position = Castelo.SALAO.get_center()
	igual(c.alvo_atual(), Castelo.ALCAPAO, "no salão: mostra o alçapão")
	_fora(c)
	Jogo.progresso.apagar()
	return true

