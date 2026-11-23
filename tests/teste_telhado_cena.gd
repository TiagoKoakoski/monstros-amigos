# godot --headless --path . res://tests/teste_telhado_cena.tscn
# A escada da torre do cemitério e o telhado montados de verdade (cenas),
# sem o piloto automático. É cena (não --script) porque precisa do autoload Jogo.
extends Node

const PROGRESSO := "user://progresso_teste_telhado_cena.cfg"

var passou := 0
var falhou := 0


func _ready() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var jogo := Jogo
	jogo.ja_iniciou = true
	jogo.progresso = Progresso.new(PROGRESSO)  # nunca o da criança
	jogo.progresso.apagar()
	for t: String in ["teste_escada_apagada_sem_progresso", "teste_escada_acesa_com_progresso",
			"teste_escada_fora_do_caminho", "teste_telhado_marca_progresso", "teste_fundo_transparente_so_no_telhado",
			"teste_parado_nao_pega_estrela", "teste_estrelas_andando_pega_todas",
			"teste_estrela_errada_nao_cala_o_vagalume", "teste_constelacoes_andando_termina",
			"teste_planetinha_sai_do_canto", "teste_ninho_de_outra_cor_nao_pega", "teste_empurrar_nao_cala_o_vagalume",
			"teste_ovelhinha_solta_fica_na_area", "teste_ovelhinha_segue_pelo_portao", "teste_ovelhinha_mais_lenta",
			"teste_ovelhinhas_andando_termina", "teste_festa_com_os_amigos",
			"teste_planetinha_piloto_de_qualquer_lugar", "teste_vagalume_planetinha_nao_aponta_na_crianca",
			"teste_ovelhinha_nao_cruza_cercado"]:
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


## Anda a criança na velocidade de verdade (380 px/s ≈ 6 px por quadro) até `ate`,
## rodando a física de `no` a cada passo.
func _andar(c: FaseDeSalas, no: Node, ate: Vector2) -> void:
	var de := c.jogador.global_position
	var passos := int(de.distance_to(ate) / 6.0) + 1
	for k in passos:
		c.jogador.global_position = de.lerp(ate, float(k + 1) / passos)
		no._physics_process(1.0 / 60.0)


func teste_escada_apagada_sem_progresso() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	igual(c.escada.aberta, false, "sem progresso: escada apagada")
	c.jogador.global_position = Cemiterio.PE_DA_ESCADA
	c.checar_interacoes()
	igual(c._subindo, false, "apagada: encostar não sobe")
	_fora(c)
	return true


func teste_escada_acesa_com_progresso() -> bool:
	Jogo.progresso.marcar("telhado")
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	igual(c.escada.aberta, true, "com telhado no progresso: escada já acesa")
	_fora(c)
	return true


func teste_escada_fora_do_caminho() -> bool:
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	var pontos: Array[Vector2] = [c.inicio]
	for id: String in Cemiterio.VAOS:
		pontos.append(c._passar(Cemiterio.VAOS[id], Cemiterio.SALAO))
	for i in pontos.size():
		for j in range(i + 1, pontos.size()):
			var perto := Geometry2D.get_closest_point_to_segment(Cemiterio.PE_DA_ESCADA, pontos[i], pontos[j])
			var d := perto.distance_to(Cemiterio.PE_DA_ESCADA)
			igual(d > PortaFundos.RAIO + 60.0, true, "caminho %s -> %s longe da escada (%.0f px)" % [pontos[i], pontos[j], d])
	_fora(c)
	return true


func teste_telhado_marca_progresso() -> bool:
	var c := await _cena(Jogo.TELHADO)
	for f: String in ["castelo", "laboratorio", "cemiterio", "telhado"]:
		igual(Jogo.progresso.alcancou(f), true, "telhado marca %s" % f)
	_fora(c)
	return true


func teste_fundo_transparente_so_no_telhado() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	igual(t.cor_fundo.a, 0.0, "telhado: fundo do mapa transparente (céu aparece)")
	igual(t.ceu != null, true, "telhado tem céu")
	_fora(t)
	var c := await _cena(Jogo.CEMITERIO) as Cemiterio
	igual(c.cor_fundo.a, 1.0, "cemitério: fundo opaco como antes")
	_fora(c)
	return true


func teste_parado_nao_pega_estrela() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var e := t.atividades["estrelas"] as EstrelasCadentes
	var meio := e.area.get_center()
	t.jogador.global_position = meio
	t._tempo_sem_progresso = 0.0
	var max_esperando := 0
	for k in 1200:  # 20 s parado no meio da área
		t._tempo_sem_progresso += 1.0 / 60.0
		e.checar(meio)
		max_esperando = maxi(max_esperando, e.estrelas.esperando().size())
	igual(e.estrelas.pegas(), 0, "parado: nenhuma estrela caiu em cima dele")
	igual(max_esperando, 3, "chegou a 3 esperando e não passou disso")
	igual(t.tempo_sem_progresso() >= 14.0, true, "parado 20 s: vaga-lume vem")
	_fora(t)
	return true


## Seguindo o alvo da sala na velocidade de verdade, pega as 6 e termina.
func teste_estrelas_andando_pega_todas() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var e := t.atividades["estrelas"] as EstrelasCadentes
	t.jogador.global_position = t._passar(Telhado.VAOS["estrelas"], e.area)
	for k in 60 * 90:
		if e.terminada():
			break
		var p := t.jogador.global_position
		t.jogador.global_position = p.move_toward(e.alvo(), 6.0)
		e.checar(t.jogador.global_position)
	igual(e.terminada(), true, "6 estrelas em menos de 90 s andando")
	igual(e.estrelas.pegas(), 6, "pegou 6")
	_fora(t)
	return true


func teste_estrela_errada_nao_cala_o_vagalume() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var c := t.atividades["constelacoes"] as Constelacoes
	var errada := c._pos(3)
	var longe := c.area.get_center() + Vector2(0, 380)
	t._tempo_sem_progresso = 0.0
	for k in 20:
		t._tempo_sem_progresso += 1.0
		c.checar(errada)
		c.checar(longe)
	igual(c.constelacoes.acesas(), 0, "estrela errada não acende")
	igual(t.tempo_sem_progresso() >= 14.0, true, "20 toques errados: vaga-lume ainda vem")
	c.checar(c._pos(0))
	igual(t.tempo_sem_progresso(), 0.0, "a certa conta como avanço")
	_fora(t)
	return true


## Desenha as 3 constelações seguindo o vaga-lume na velocidade de verdade.
func teste_constelacoes_andando_termina() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var c := t.atividades["constelacoes"] as Constelacoes
	t.jogador.global_position = t._passar(Telhado.VAOS["constelacoes"], c.area)
	for k in 60 * 120:
		if c.terminada():
			break
		t.jogador.global_position = t.jogador.global_position.move_toward(c.alvo(), 6.0)
		c.checar(t.jogador.global_position)
	igual(c.terminada(), true, "3 desenhos em menos de 120 s")
	igual(t.ceu.constelacoes(), 3, "3 constelações no céu")
	_fora(t)
	return true


## Piloto empurrando a 6 px/quadro, cada planetinha posto em cada canto.
func teste_planetinha_sai_do_canto() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var pl := t.atividades["planetas"] as Planetinhas
	var L := pl.limites
	var cantos: Array[Vector2] = [L.position, Vector2(L.end.x, L.position.y), L.end, Vector2(L.position.x, L.end.y)]
	for i in pl.planetas.size():
		for canto: Vector2 in cantos:
			# só este planetinha solto: os outros ficam nos ninhos
			for j in pl.planetas.size():
				pl.planetas[j].no_ninho = j != i
				pl.planetas[j].vel = Vector2.ZERO
			pl._auto_i = -1
			pl.planetas[i].global_position = canto
			t.jogador.global_position = pl.area.get_center()
			pl._no_ninho = 0
			var quadros := 0
			while not pl.planetas[i].no_ninho and quadros < 60 * 40:
				t.jogador.global_position = t.jogador.global_position.move_toward(pl.alvo_auto(), 6.0)
				pl.checar(t.jogador.global_position)
				quadros += 1
			igual(quadros < 60 * 40, true, "planetinha %s do canto %s chega no ninho (%.1f s)" % [pl.planetas[i].cor, canto, quadros / 60.0])
	_fora(t)
	return true


func teste_ninho_de_outra_cor_nao_pega() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var pl := t.atividades["planetas"] as Planetinhas
	pl.planetas[0].global_position = pl.ninhos[1]  # vermelho parado no ninho azul
	t.jogador.global_position = pl.area.get_center() + Vector2(0, 400)
	for k in 60:
		pl.checar(t.jogador.global_position)
	igual(pl.planetas[0].no_ninho, false, "vermelho no ninho azul: não encaixa")
	igual(pl._no_ninho, 0, "nenhum no ninho")
	_fora(t)
	return true


func teste_empurrar_nao_cala_o_vagalume() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var pl := t.atividades["planetas"] as Planetinhas
	t._tempo_sem_progresso = 0.0
	var bola := pl.planetas[1]
	for k in 20:
		t._tempo_sem_progresso += 1.0
		bola.global_position = pl.area.get_center() + Vector2(0, 250)
		bola.vel = Vector2.ZERO
		# empurra pra baixo (longe dos ninhos)
		pl.checar(bola.global_position + Vector2(0, -60))
		for f in 30:
			pl.checar(pl.area.get_center() + Vector2(-400, 0))
	igual(pl._no_ninho, 0, "nada no ninho")
	igual(t.tempo_sem_progresso() >= 14.0, true, "20 empurrões: vaga-lume ainda vem")
	_fora(t)
	return true


func teste_ovelhinha_solta_fica_na_area() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var ov := t.atividades["ovelhas"] as Ovelhinhas
	var fora := 0
	var no_cercado := 0
	var entrada := t._passar(Telhado.VAOS["ovelhas"], ov.area)
	t.jogador.global_position = entrada
	for k in 3000:
		if k % 500 == 0:  # cutuca: cada uma dá o pulinho pra perto de uma borda
			for b: Ovelhinha in ov.bichos:
				b.pular_longe(b.global_position + Vector2(cos(k), sin(k)) * 50.0, ov.limites, ov.cercado)
		ov._physics_process(1.0 / 60.0)
		for b: Ovelhinha in ov.bichos:
			if not ov.area.has_point(b.global_position):
				fora += 1
			if ov.cercado.has_point(b.global_position):
				no_cercado += 1
	igual(fora, 0, "soltas não saem da área")
	igual(no_cercado, 0, "soltas não entram no cercadinho")
	_fora(t)
	return true


func teste_ovelhinha_segue_pelo_portao() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var ov := t.atividades["ovelhas"] as Ovelhinhas
	var b := ov.bichos[0]
	ov.ovelhas.assustar(0)  # já deu o pulinho
	t.jogador.global_position = b.global_position
	ov.checar(b.global_position)
	igual(ov.ovelhas.seguindo(), [0], "pegou a ovelhinha")
	_andar(t, ov, Telhado.VAOS["ovelhas"].get_center() + Vector2(0, 140))
	_andar(t, ov, Telhado.VAOS["ovelhas"].get_center() + Vector2(0, -140))
	_andar(t, ov, Telhado.SALAO.get_center())
	var d := b.global_position.distance_to(t.jogador.global_position)
	igual(d < 300.0, true, "ovelhinha veio junto até o terraço (%.0f px)" % d)
	_fora(t)
	return true


func teste_ovelhinha_mais_lenta() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var ov := t.atividades["ovelhas"] as Ovelhinhas
	t.jogador.global_position = t.inicio  # longe: ninguém pula
	var b := ov.bichos[1]
	var maior := 0.0
	for k in 900:
		var antes := b.global_position
		ov._physics_process(1.0 / 60.0)
		maior = maxf(maior, antes.distance_to(b.global_position) * 60.0)
	igual(maior <= 115.0, true, "passeando a no máximo 115 px/s (%.0f)" % maior)
	igual(maior > 50.0, true, "mas passeia (%.0f)" % maior)
	_fora(t)
	return true


## Pegando e levando pra porteira na velocidade de verdade, guarda as 4.
func teste_ovelhinhas_andando_termina() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var ov := t.atividades["ovelhas"] as Ovelhinhas
	t.jogador.global_position = t._passar(Telhado.VAOS["ovelhas"], ov.area)
	for k in 60 * 120:
		if ov.terminada():
			break
		t.jogador.global_position = t.jogador.global_position.move_toward(ov.alvo(), 6.0)
		ov._physics_process(1.0 / 60.0)
		ov.checar(t.jogador.global_position)
	igual(ov.terminada(), true, "4 ovelhinhas guardadas em menos de 120 s")
	_fora(t)
	return true


## A festa no céu fecha o jogo: amigos de todas as fases sobem pelo alçapão.
func teste_festa_com_os_amigos() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	t.festa_final()
	var nomes: Array[String] = []
	for a: Node2D in t.amigos:
		nomes.append(String(a.get_meta("quem")))
	nomes.sort()
	igual(nomes, ["dracula", "fantasma_mamae", "fantasmao", "frankenstein", "lobisomem", "mumia"], "os amigos das outras fases vieram")
	igual(t.em_festa, true, "em festa")
	igual(t.ceu.festa_na_frente(), true, "na festa constelações e fogos ficam na frente do telhado")
	_fora(t)
	return true


## Revisão: com a bola e a criança em qualquer lugar, o piloto não fica
## indo e voltando entre dois pontos (o vaga-lume usa a mesma conta).
func teste_planetinha_piloto_de_qualquer_lugar() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var pl := t.atividades["planetas"] as Planetinhas
	var anda := pl.area.grow(-38.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	var casos: Array = [[Vector2(2960.4, 1884.2), Vector2(2944.6, 1308.8)]]  # o caso que a revisão achou
	for k in 120:
		casos.append([Vector2(rng.randf_range(pl.limites.position.x, pl.limites.end.x), rng.randf_range(pl.limites.position.y, pl.limites.end.y)),
			Vector2(rng.randf_range(anda.position.x, anda.end.x), rng.randf_range(anda.position.y, anda.end.y))])
	var presos := 0
	for caso: Array in casos:
		for j in pl.planetas.size():
			pl.planetas[j].no_ninho = j != 0
			pl.planetas[j].vel = Vector2.ZERO
		pl._auto_i = -1
		pl._no_ninho = 0
		pl.planetas[0].global_position = caso[0]
		t.jogador.global_position = caso[1]
		var quadros := 0
		while not pl.planetas[0].no_ninho and quadros < 60 * 40:
			t.jogador.global_position = t.jogador.global_position.move_toward(pl.alvo_auto(), 6.0).clamp(anda.position, anda.end)
			pl.checar(t.jogador.global_position)
			quadros += 1
		if not pl.planetas[0].no_ninho:
			presos += 1
			push_error("preso: bola %s criança %s" % [caso[0], caso[1]])
	igual(presos, 0, "121 começos: o piloto sempre leva o planetinha pro ninho")
	_fora(t)
	return true


## Revisão: parado no ponto de empurrar, o vaga-lume aponta pra frente (não pra cabeça dele).
func teste_vagalume_planetinha_nao_aponta_na_crianca() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var pl := t.atividades["planetas"] as Planetinhas
	var bola := pl.planetas[0].global_position
	t.jogador.global_position = Rolagem.ponto_de_empurrar(bola, pl.ninhos[0], bola + Vector2(0, 300), pl.limites)
	var d := pl.alvo().distance_to(t.jogador.global_position)
	igual(d > 80.0, true, "no ponto de empurrar: vaga-lume aponta adiante (%.0f px)" % d)
	_fora(t)
	return true


## Revisão: passeando, a ovelhinha solta nunca atravessa o cercadinho.
func teste_ovelhinha_nao_cruza_cercado() -> bool:
	var t := await _cena(Jogo.TELHADO) as Telhado
	var ov := t.atividades["ovelhas"] as Ovelhinhas
	var cruzou := 0
	for semente in range(1, 41):
		var b := Ovelhinha.new()
		b.configurar(semente)
		t.add_child(b)
		b.global_position = ov.area.position + Vector2(300, 300)
		for k in 60:
			var de := b.global_position
			var para := b._sortear(ov.limites, ov.cercado)
			for f in 21:
				if ov.cercado.has_point(de.lerp(para, f / 20.0)):
					cruzou += 1
					break
			b.global_position = para
		b.free()
	igual(cruzou, 0, "2400 passeios sorteados: nenhum caminho passa pelo cercadinho")
	_fora(t)
	return true
