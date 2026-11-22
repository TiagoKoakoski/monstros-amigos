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
			"teste_porta_fundos_fora_do_caminho", "teste_cemiterio_marca_progresso",
			"teste_fantasminha_segue_pela_porta", "teste_laco_semente_agua_nao_cala_o_vagalume",
			"teste_parado_no_poco_fica_com_a_agua", "teste_vagalume_labirinto_nao_atravessa",
			"teste_saida_do_labirinto_pelos_corredores", "teste_fantasmao_fica_na_arena", "teste_fantasmao_cansa",
			"teste_pegada_conta_uma_vez", "teste_ganha_devagar"]:
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


## Anda a criança na velocidade de verdade (380 px/s ≈ 6 px por quadro) até `ate`.
func _andar(c: FaseDeSalas, sala: Node, ate: Vector2) -> void:
	var de := c.jogador.global_position
	var passos := int(de.distance_to(ate) / 6.0) + 1
	for k in passos:
		c.jogador.global_position = de.lerp(ate, float(k + 1) / passos)
		sala._physics_process(1.0 / 60.0)


func teste_fantasminha_segue_pela_porta() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var lap := c.atividades["lapides"] as Lapides
	var i: int = lap.fantasminhas.keys()[0]
	c.jogador.global_position = lap.lugares[i]
	lap.checar(lap.lugares[i])
	igual(lap.esconde.seguindo().size(), 1, "achou um fantasminha")
	_andar(c, lap, Cemiterio.VAOS["lapides"].get_center() + Vector2(-140, 0))
	_andar(c, lap, Cemiterio.SALAO.get_center())
	var d := lap.fantasminhas[i].global_position.distance_to(c.jogador.global_position)
	igual(d < 300.0, true, "fantasminha veio junto até a praça (%.0f px)" % d)
	_fora(c)
	return true


func teste_laco_semente_agua_nao_cala_o_vagalume() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var h := c.atividades["horta"] as Horta
	c._tempo_sem_progresso = 0.0
	for i in 20:
		c._tempo_sem_progresso += 1.0
		h.checar(h.saco)  # pega semente
		h.checar(c.inicio)
		h.checar(h.saco)  # devolve
		h.checar(c.inicio)
		h.checar(h.poco)  # pega água
		h.checar(h.canteiros[0])  # água no vazio: hum
		h.checar(h.poco)  # devolve
		h.checar(c.inicio)
	igual(c.tempo_sem_progresso() >= 14.0, true, "20 s pegando e devolvendo semente/água: vaga-lume ainda vem")
	igual(c.estado.carregando, "", "mão vazia no fim (devolveu)")
	h.checar(h.saco)
	h.checar(h.canteiros[0])
	igual(c.tempo_sem_progresso(), 0.0, "plantar conta como avanço")
	_fora(c)
	return true


func teste_parado_no_poco_fica_com_a_agua() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var h := c.atividades["horta"] as Horta
	for i in 30:
		h.checar(h.poco)
	igual(c.estado.carregando, "agua", "parado no poço: pega a água uma vez e fica com ela")
	var borda := h.poco + Vector2(0, Horta.RAIO_COISA + 20.0)
	for i in 11:
		h.checar(borda + Vector2(0, -3.0 if i % 2 == 0 else 3.0))  # tremendo na borda do alcance
	igual(c.estado.carregando, "agua", "tremendo na borda do poço: não devolve")
	h.checar(c.inicio)
	h.checar(h.poco)
	igual(c.estado.carregando, "", "saiu e voltou: devolve")
	_fora(c)
	return true


func teste_vagalume_labirinto_nao_atravessa() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var lab := c.atividades["labirinto"] as Labirinto
	var ruins := 0
	for x in EstadoLabirinto.LARGURA:
		for y in EstadoLabirinto.ALTURA:
			var cel := Vector2i(x, y)
			c.jogador.global_position = lab.centro(cel)
			var alvo := lab.celula(lab.alvo())
			var ok := alvo == cel if cel == EstadoLabirinto.CHAVE else lab.lab.livre(cel, alvo)
			if not ok:
				ruins += 1
	igual(ruins, 0, "de toda célula, o vaga-lume aponta uma célula vizinha sem cerca no meio")
	_fora(c)
	return true


func teste_saida_do_labirinto_pelos_corredores() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var lab := c.atividades["labirinto"] as Labirinto
	c.jogador.global_position = lab.centro(EstadoLabirinto.CHAVE)
	lab.checar(c.jogador.global_position)
	igual(lab.terminada(), true, "pegou a chave")
	var alvo := c.alvo_atual()
	var prox := lab.celula(alvo)
	igual(Cemiterio.AREAS["labirinto"].has_point(alvo), true, "saindo: o vaga-lume fica dentro do labirinto")
	igual(lab.lab.livre(EstadoLabirinto.CHAVE, prox), true, "saindo: aponta a célula vizinha pelo corredor")
	_fora(c)
	return true


const QUADRO := 1.0 / 60.0


func _fantasmao(c: Cemiterio) -> Fantasmao:
	return (c.atividades["arena"] as Arena).fantasmao


func teste_fantasmao_fica_na_arena() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var f := _fantasmao(c)
	var area: Rect2 = Cemiterio.AREAS["arena"]
	var fora := 0
	for lado: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized()]:
		for i in 120:
			f.mover(QUADRO, f.global_position + lado * 200.0)  # empurrando de um lado
			if not area.has_point(f.global_position):
				fora += 1
	igual(fora, 0, "Fantasmão nunca sai da arena")
	_fora(c)
	return true


func teste_fantasmao_cansa() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var f := _fantasmao(c)
	f.global_position = Cemiterio.AREAS["arena"].get_center()
	igual(f.velocidade() <= Fantasmao.MAX + 0.1, true, "começa no máximo (≤ 60% da criança)")
	for i in 8 * 60:
		f.mover(QUADRO, f.global_position + Vector2(-300, 0))
	igual(f.velocidade() <= 100.0, true, "depois de 8 s fugindo, cansado (%.0f)" % f.velocidade())
	f.mover(QUADRO, f.global_position)  # pegou
	for i in 2 * 60:
		f.mover(QUADRO, f.global_position + Vector2(-300, 0))  # descansa e volta a fugir
	igual(f.velocidade() > 180.0, true, "depois de pego, foge descansado (%.0f)" % f.velocidade())
	_fora(c)
	return true


func teste_pegada_conta_uma_vez() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var f := _fantasmao(c)
	var parado := f.global_position + Vector2(40, 0)
	for i in 6 * 60:
		f.mover(QUADRO, parado)  # criança parada ali, encostada, 6 s
	igual(f.pegadas, 1, "criança parada encostada: conta uma vez só (ele pula pra longe depois do descanso)")
	_fora(c)
	return true


func teste_ganha_devagar() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var f := _fantasmao(c)
	var area: Rect2 = Cemiterio.AREAS["arena"]
	var p := area.position + Vector2(600, 120)
	for i in 40 * 60:
		p += (f.global_position - p).normalized() * 150.0 * QUADRO  # analógico meio inclinado
		f.mover(QUADRO, p)
	igual(f.pegadas >= 3, true, "perseguindo a 150 px/s, pega 3 vezes em 40 s (%d)" % f.pegadas)
	_fora(c)
	return true
