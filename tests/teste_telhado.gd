# godot --headless --path . --script res://tests/teste_telhado.gd
# Regras puras da fase do telhado (sem cena).
extends SceneTree

var passou := 0
var falhou := 0


func _initialize() -> void:
	for t: String in ["teste_estrelas_sorteio", "teste_estrelas_no_maximo_3", "teste_estrelas_fim",
			"teste_constelacoes_ordem", "teste_constelacoes_crescem", "teste_constelacoes_geometria",
			"teste_rolagem_para", "teste_rolagem_nao_sai", "teste_rolagem_mira", "teste_rolagem_encaixa_so_perto",
			"teste_rolagem_ponto_de_empurrar",
			"teste_ovelhas_pulinho_uma_vez", "teste_ovelhas_guardar_aos_poucos", "teste_ovelhas_pegar_duas_vezes"]:
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


# ---------------------------------------------------------------- estrelas cadentes

const LIMITES := Rect2(250, 950, 1000, 1500)
const CORUJA := Vector2(1150, 1150)


func teste_estrelas_sorteio() -> bool:
	var C = _classe("estado_estrelas")
	var a = C.new(5, LIMITES, CORUJA)
	var b = C.new(5, LIMITES, CORUJA)
	var crianca := Vector2(700, 1700)
	igual(a.sortear(crianca), b.sortear(crianca), "mesma semente, mesmo ponto")
	var ruins := 0
	for semente in range(1, 51):
		var e = C.new(semente, LIMITES, CORUJA)
		var rng := RandomNumberGenerator.new()
		rng.seed = semente * 31
		for k in 4:
			var cri := Vector2(rng.randf_range(LIMITES.position.x, LIMITES.end.x), rng.randf_range(LIMITES.position.y, LIMITES.end.y))
			if not e.pode_cair():
				break
			var p: Vector2 = e.sortear(cri)
			var esperando: Dictionary = e.esperando()
			var perto_de_outra := false
			for q: Vector2 in esperando.values():
				if p.distance_to(q) < C.LONGE_DE_OUTRA:
					perto_de_outra = true
			if not LIMITES.has_point(p) or p.distance_to(CORUJA) < C.LONGE_DA_CORUJA \
					or p.distance_to(cri) < C.LONGE_DA_CRIANCA or perto_de_outra:
				ruins += 1
			e.cair(p)
	igual(ruins, 0, "150+ sorteios: dentro, longe da Coruja, da criança e das outras")
	return true


func teste_estrelas_no_maximo_3() -> bool:
	var e = _classe("estado_estrelas").new(3, LIMITES, CORUJA)
	var ids: Array[int] = []
	for k in 3:
		igual(e.pode_cair(), true, "pode cair a %dª" % (k + 1))
		ids.append(e.cair(e.sortear(Vector2(300, 1000))))
	igual(e.pode_cair(), false, "3 esperando: não cai mais")
	igual(e.pegar(ids[0]), "pegou", "pegou uma")
	igual(e.pode_cair(), true, "2 esperando: cai de novo")
	return true


func teste_estrelas_fim() -> bool:
	var e = _classe("estado_estrelas").new(9, LIMITES, CORUJA)
	igual(e.pegar(42), "ignorado", "estrela que não existe")
	var r := ""
	for k in 6:
		var id: int = e.cair(e.sortear(Vector2(300, 1000)))
		r = e.pegar(id)
		igual(e.pegar(id), "ignorado", "pegar a mesma de novo")
	igual(r, "fim", "6ª pega termina")
	igual(e.pegas(), 6, "6 pegas")
	igual(e.terminou(), true, "terminou")
	igual(e.pode_cair(), false, "terminou: não cai mais")
	return true


# ---------------------------------------------------------------- constelações

func teste_constelacoes_ordem() -> bool:
	var C = _classe("estado_constelacoes")
	var e = C.new(C.padrao())
	igual(e.desenho(), 0, "começa no gato")
	igual(e.tocar(3), "errado", "estrela fora da ordem")
	igual(e.acesas(), 0, "errada não acende nada")
	igual(e.tocar(0), "certo", "primeira")
	igual(e.tocar(0), "ignorado", "já acesa")
	igual(e.tocar(2), "errado", "pulou uma")
	igual(e.acesas(), 1, "errada não apaga nada")
	for i in range(1, 5):
		igual(e.tocar(i), "certo", "gato %d" % i)
	igual(e.tocar(5), "desenho", "fechou o gato")
	igual(e.desenho(), 1, "agora o morcego")
	igual(e.acesas(), 0, "morcego começa apagado")
	for i in 6:
		e.tocar(i)
	igual(e.tocar(6), "desenho", "fechou o morcego")
	for i in 7:
		igual(e.tocar(i), "certo", "peixe %d" % i)
	igual(e.tocar(7), "fim", "fechou o peixe: fim")
	igual(e.terminou(), true, "terminou")
	igual(e.tocar(0), "ignorado", "depois do fim nada conta")
	return true


func teste_constelacoes_crescem() -> bool:
	var d: Array = _classe("estado_constelacoes").padrao()
	igual(d.size(), 3, "3 desenhos")
	igual([d[0].size(), d[1].size(), d[2].size()], [6, 7, 8], "gato 6, morcego 7, peixe 8")
	return true


func teste_constelacoes_geometria() -> bool:
	var C = _classe("estado_constelacoes")
	var dentro := Rect2(150, 150, 900, 650)
	for pontos: Array in C.padrao():
		igual(C.menor_distancia(pontos) >= 240.0, true, "estrelas espaçadas (%.0f)" % C.menor_distancia(pontos))
		igual(C.folga_dos_riscos(pontos) >= 170.0, true, "risco longe das outras (%.0f)" % C.folga_dos_riscos(pontos))
		var fora := 0
		for p: Vector2 in pontos:
			if not dentro.grow(0.5).has_point(p):
				fora += 1
		igual(fora, 0, "todas dentro do quadro")
	return true


# ---------------------------------------------------------------- planetinhas

const CAMPO := Rect2(2950, 1350, 800, 700)


func teste_rolagem_para() -> bool:
	var R = _classe("rolagem")
	var pos := Vector2(3300, 1700)
	var vel: Vector2 = R.empurrao(pos, pos + Vector2(-50, 0), Vector2(3300, 2600))  # ninho longe, fora da mira
	igual(is_equal_approx(vel.length(), R.EMPURRAO), true, "empurrão com força fixa")
	for k in 300:
		var r: Array = R.rolar(pos, vel, 1.0 / 60.0, CAMPO)
		pos = r[0]
		vel = r[1]
	igual(vel, Vector2.ZERO, "5 s depois parou")
	return true


func teste_rolagem_nao_sai() -> bool:
	var R = _classe("rolagem")
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var pos := CAMPO.get_center()
	var vel := Vector2.ZERO
	var fora := 0
	for k in 1000:
		var a := rng.randf() * TAU
		vel = R.empurrao(pos, pos - Vector2(cos(a), sin(a)) * 60.0, Vector2(-9999, -9999))
		for f in 20:
			var r: Array = R.rolar(pos, vel, 1.0 / 60.0, CAMPO)
			pos = r[0]
			vel = r[1]
			if not CAMPO.grow(0.01).has_point(pos):
				fora += 1
	igual(fora, 0, "1000 empurrões: nunca sai dos limites")
	return true


func teste_rolagem_mira() -> bool:
	var R = _classe("rolagem")
	var bola := Vector2(3300, 1700)
	var ninho := bola + Vector2(0, -400)  # ninho em cima
	var torto40 := bola + Vector2(sin(deg_to_rad(40)), cos(deg_to_rad(40))) * 80.0  # empurra 40° torto pra cima
	var v: Vector2 = R.empurrao(bola, torto40, ninho)
	igual(v.normalized().is_equal_approx(Vector2(0, -1)), true, "40° torto: vai reto pro ninho")
	var de_lado := bola + Vector2(-80, 0)  # empurra pra direita: 90° do ninho
	v = R.empurrao(bola, de_lado, ninho)
	igual(v.normalized().is_equal_approx(Vector2(1, 0)), true, "90° torto: vai pra onde empurrou")
	return true


func teste_rolagem_encaixa_so_perto() -> bool:
	var R = _classe("rolagem")
	var ninho := Vector2(3200, 1420)
	igual(R.encaixa(ninho + Vector2(109, 0), ninho), true, "109 px: encaixa")
	igual(R.encaixa(ninho + Vector2(111, 0), ninho), false, "111 px: não")
	return true


func teste_rolagem_ponto_de_empurrar() -> bool:
	var R = _classe("rolagem")
	var bola := Vector2(3300, 1800)
	var ninho := Vector2(3300, 1420)
	var p: Vector2 = R.ponto_de_empurrar(bola, ninho, Vector2(3300, 2000), CAMPO)
	igual(p.is_equal_approx(Vector2(3300, 1930)), true, "atrás da bola, do lado oposto ao ninho (%s)" % p)
	# criança do lado do ninho, perto: dá a volta por um lado
	var desvio: Vector2 = R.ponto_de_empurrar(bola, ninho, Vector2(3340, 1700), CAMPO)
	igual(absf(desvio.x - bola.x) >= 150.0, true, "do lado do ninho: desvia de lado (%s)" % desvio)
	# chegou no desvio (de lado da bola): agora vai pra trás dela
	var depois: Vector2 = R.ponto_de_empurrar(bola, ninho, desvio, CAMPO)
	igual(depois.is_equal_approx(Vector2(3300, 1930)), true, "do desvio vai pra trás da bola (%s)" % depois)
	# canto de baixo à direita: parado ao lado da bola (um tico pro lado do ninho), vai pra trás dela
	var canto := Vector2(CAMPO.end.x, CAMPO.end.y)
	var de_lado: Vector2 = R.ponto_de_empurrar(canto, Vector2(3200, 1420), Vector2(3607, 2105), CAMPO)
	igual(de_lado.distance_to(canto + Vector2(85, 98)) < 5.0, true, "no canto: vai pra trás da bola (%s)" % de_lado)
	# bola encostada no limite de baixo: o ponto fica dentro da área da criança
	var no_canto: Vector2 = R.ponto_de_empurrar(Vector2(3300, CAMPO.end.y), ninho, Vector2(3300, 1500), CAMPO)
	igual(CAMPO.grow(150.0).has_point(no_canto), true, "ponto dentro de onde a criança anda")
	return true


# ---------------------------------------------------------------- ovelhinhas

func teste_ovelhas_pulinho_uma_vez() -> bool:
	var e = _classe("estado_ovelhas").new()
	igual(e.assustar(0), true, "1º encontro: pulinho")
	igual(e.assustar(0), false, "depois: deixa pegar")
	igual(e.pegar(1), true, "pegou a 1 sem pulinho")
	igual(e.assustar(1), false, "pega não pula")
	return true


func teste_ovelhas_guardar_aos_poucos() -> bool:
	var e = _classe("estado_ovelhas").new()
	igual(e.guardar().size(), 0, "ninguém seguindo: nada")
	e.pegar(0)
	e.pegar(2)
	igual(e.seguindo(), [0, 2], "seguindo na ordem em que pegou")
	igual(e.soltas(), [1, 3], "soltas")
	igual(e.guardar(), [0, 2], "guardou as 2")
	igual(e.guardadas(), 2, "2 guardadas")
	igual(e.seguindo().size(), 0, "ninguém seguindo")
	igual(e.terminou(), false, "faltam 2")
	e.pegar(1)
	e.pegar(3)
	e.guardar()
	igual(e.terminou(), true, "4 guardadas: fim")
	return true


func teste_ovelhas_pegar_duas_vezes() -> bool:
	var e = _classe("estado_ovelhas").new()
	igual(e.pegar(1), true, "pegou")
	igual(e.pegar(1), false, "de novo: não")
	e.guardar()
	igual(e.pegar(1), false, "guardada: não")
	igual(e.pegar(9), false, "não existe")
	return true
