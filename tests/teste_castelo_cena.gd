# godot --headless --path . res://tests/teste_castelo_cena.tscn
# O castelo montado de verdade (cena), sem o piloto automático: casos que só
# aparecem com a criança jogando no controle. É cena (não --script) porque
# precisa do autoload Jogo.
extends Node

var passou := 0
var falhou := 0
var c: Castelo


func _ready() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var jogo := Jogo
	jogo.ja_iniciou = true
	jogo.progresso = Progresso.new("user://progresso_teste_cena.cfg")  # nunca o da criança
	c = (load("res://scenes/castelo.tscn") as PackedScene).instantiate() as Castelo
	add_child(c)
	await get_tree().process_frame
	await get_tree().process_frame
	for t: String in ["teste_musica_do_castelo", "teste_vagalume_nao_pousa_na_crianca",
			"teste_volta_pra_musica_toca_de_novo", "teste_caixa_nao_volta_com_crianca_fora",
			"teste_fechadura_do_quarto_quieta"]:
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


func teste_musica_do_castelo() -> bool:
	var tocando: AudioStream = c._musica.stream
	igual(is_equal_approx(snappedf(tocando.get_length(), 0.01), 25.26), true, "castelo toca musica_castelo (25,26 s)")
	return true


func teste_vagalume_nao_pousa_na_crianca() -> bool:
	var m := c.atividades["musica"] as Musica
	m.fase = "vez"
	m._sobre = m.seq.proxima_cor()
	igual(m.alvo(), m._meio, "parado no ladrilho certo: vaga-lume mostra o meio (sair e entrar)")
	m._sobre = -1
	igual(m.alvo(), m.ladrilhos[m.seq.proxima_cor()].global_position, "fora do ladrilho: mostra o ladrilho certo")
	return true


func teste_volta_pra_musica_toca_de_novo() -> bool:
	var m := c.atividades["musica"] as Musica
	m.fase = "vez"
	m._dentro = false
	m.checar(Castelo.SALAO.get_center())
	m.checar(m._meio)
	igual(m.fase, "demo", "voltou pra sala no meio da rodada: Drácula toca de novo")
	return true


func teste_caixa_nao_volta_com_crianca_fora() -> bool:
	var k := c.atividades["caixas"] as CorredorCaixas
	var caixa := k.caixas[0]
	caixa.global_position = caixa.inicio + Vector2(150, 0)
	k._ultima[0] = caixa.global_position
	k._parada[0] = 30.0
	c._tempo_sem_progresso = 30.0
	k.checar(Castelo.SALAO.get_center())
	igual(k._parada[0] > 0.0, true, "criança fora do corredor: caixa fica onde ela deixou")
	return true


func teste_fechadura_do_quarto_quieta() -> bool:
	var porta := c.portas["quarto"]
	c.jogador.global_position = porta.ponto + Vector2(0, -110)
	var antes := porta._ultimo
	c.checar_interacoes()
	igual(porta._ultimo, antes, "porta do quarto (abre pelas caixas) não balança a fechadura")
	return true
