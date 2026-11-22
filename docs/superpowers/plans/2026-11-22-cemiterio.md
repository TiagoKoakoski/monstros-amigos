# Cemitério das abóboras — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fase 4 ao ar livre atrás do castelo: praça + Lápides (esconde-esconde),
Horta, Labirinto e Arena (pega-pega), com passagem pela porta dos fundos do
laboratório.

**Architecture:** `Cemiterio extends FaseDeSalas` (cercas vivas = paredes, portões =
`Porta`). Regras puras em `scripts/regras/` testadas com `--script`; casos de
controle real em `tests/teste_cemiterio_cena.tscn`. Uma mudança na base:
`Atividade.caminho_ate()` pra rota sair do labirinto pelos corredores.

**Tech Stack:** Godot 4.7.2 GDScript tipado; `ferramentas/gerar_sons.py`; SVG à mão.

**Spec:** `docs/superpowers/specs/2026-11-22-cemiterio-design.md`

## Global Constraints

- Nada pra ler; nada pra perder; zero susto (fantasmas fofos, noite clara); tudo encostando.
- Vaga-lume do cemitério espera **14 s**.
- Coisas infinitas (pegar semente, pegar água) **não** contam como avanço.
- Pegáveis/acionáveis nunca em fila no caminho uns dos outros; "parado" medido pelo ponto onde parou.
- Fantasmão: velocidade ≤ 60% da criança (380 px/s → ≤ 228) e cansa até ~25% (95).
- Testes/autoplay nunca escrevem `user://progresso.cfg`.
- Autoplay inteiro com `timeout 900`, em segundo plano (vai passar de ~6 pra ~9 min).

## Review Focus

1. **Vaga-lume nunca atravessa cerca no labirinto** (dentro dele e saindo dele pra outra área) — Task 5.
2. **Laço semente/água** na horta não cala o vaga-lume — Task 4.
3. **Pega-pega ganhável com analógico devagar** (Fantasmão cansa e não sai da arena) — Task 6.
4. **Fantasminhas seguindo** atravessam portões/cercas sem travar e não se perdem ao trocar de área — Task 3.
5. **Porta dos fundos do lab** não é pega sem querer nos caminhos (escada → portas) — Task 2.

---

### Task 1: Base pronta pro cemitério

**Files:** Modify `scripts/jogo.gd`, `scripts/regras/estado_salas.gd`, `scripts/salas/chaveiro.gd`, `scripts/salas/atividade.gd`, `scripts/salas/fase_de_salas.gd`. Test: `tests/teste_cemiterio.gd` (novo, `--script`, esqueleto igual a `teste_laboratorio.gd`).

**Interfaces (produz):**
- `Jogo.CEMITERIO := "res://scenes/cemiterio.tscn"`, argumento `--fase=cemiterio`.
- `EstadoSalas.CORES_CHAVE` += `"roxa"`, `"amarela"`, `"rosa"`; `Chaveiro.CORES` += roxa `#a66bff`, amarela `#ffd23f`, rosa `#ff9ecb`.
- `Atividade.caminho_ate(destino: Vector2) -> Vector2` (padrão: `destino`) — próximo ponto pra andar dentro da sala rumo a `destino`.
- `FaseDeSalas.rota()`: quando a criança está numa sala com atividade, o ponto de saída (`_passar(...)`) passa por `atividades[aqui].caminho_ate(...)`.

- [ ] **Step 1:** teste `teste_chaves_novas`: `EstadoSalas.new(["a"], {"a": "rosa"}, {"b": "rosa"})` → `abre_por_sala("b") == false`; `concluir("a")` → `tentar_abrir("b") == true`.
- [ ] **Step 2:** FAIL (rosa tratada como sala) → **Step 3:** implementar → **Step 4:** PASS; suíte toda PASS (castelo/lab não mudam).
- [ ] **Step 5: Commit** `Base pronta pro cemitério: chaves novas, caminho_ate, --fase=cemiterio`.

### Task 2: Porta dos fundos do laboratório + esqueleto do cemitério

**Files:** Create `scripts/cemiterio/cemiterio.gd` (`class_name Cemiterio extends FaseDeSalas`), `scenes/cemiterio.tscn`, `scripts/laboratorio/porta_fundos.gd` (`class_name PortaFundos`). Modify `scripts/laboratorio/laboratorio.gd`, `scripts/jardim.gd` (resumo), `ferramentas/gerar_sons.py` (`cemiterio(saida)`: `musica_cemiterio`, `risadinha`, `achei`, `plantar`, `regar`, `crescer`, `carroca`, `peguei`). Arte: `porta_fundos_fechada.svg`, `porta_fundos_aberta.svg`, `portinha.svg`, `cerca.svg` (bloco de cerca viva, opcional se desenhar por código), `lanterna.svg`, `lapide_flor.svg`, `lapide_coracao.svg`, `lapide_gato.svg`, `abobora_grande.svg`, `fantasma_mamae.svg`, `fantasminha.svg`, `fantasmao.svg`. Test: `tests/teste_cemiterio_cena.gd` + `.tscn`.

**Layout (W 4000, H 3400):**
- `SALAO` (praça) `Rect2(1500, 1200, 1200, 1000)`; `inicio = Vector2(1700, 1450)` (portinha em `(1700, 1330)`).
- `AREAS`: `lapides Rect2(100, 800, 1300, 1800)`, `horta Rect2(2800, 1200, 1100, 1000)`, `labirinto Rect2(1500, 100, 1200, 1000)`, `arena Rect2(1500, 2300, 1200, 1000)`.
- `VAOS`: `lapides Rect2(1400, 1600, 100, 200)` (aberto), `horta Rect2(2700, 1600, 100, 200)` (roxo), `labirinto Rect2(1900, 1100, 200, 100)` (amarelo), `arena Rect2(2000, 2200, 200, 100)` (rosa).
- `PAREDES`: `(1400,0,1400,100)`, `(1400,100,100,1500)`, `(1400,1800,100,1600)`, `(2700,100,100,1500)`, `(2700,1800,100,1600)`, `(1500,1100,400,100)`, `(2100,1100,600,100)`, `(1500,2200,500,100)`, `(2200,2200,500,100)`, `(1400,3300,1400,100)`, `(0,700,1400,100)`, `(0,700,100,2000)`, `(0,2600,1400,100)`, `(2800,1100,1200,100)`, `(3900,1100,100,1200)`, `(2800,2200,1200,100)`.
- `CHAVE_DA_SALA`: `lapides: "roxa"`, `horta: "amarela"`, `labirinto: "rosa"`. `PORTAS`: `horta: "roxa"`, `labirinto: "amarela"`, `arena: "rosa"`. Cores dos portões iguais às das chaves.
- Cores: fundo `#1f2a4a`, cerca (parede) `#3f7a5a`, face `#5a9a72`; chão da praça terra clara `#cdb48a`, gramas `#7fb8a0`/`#8cc4ab`. `ordem` começa vazia (cada sala se adiciona).

**Interfaces:**
- `Cemiterio`: `configurar_mapa()` marca `castelo`, `laboratorio`, `cemiterio`; `espera_guia = 14.0`; música `musica_cemiterio`; `decorar()`: praça, portinha, lanternas, abóboras acesas de enfeite (sem colisão), escada da torre fechada de enfeite; sem salas → `festa_final.call_deferred()`; `festa_final()`: monstros das áreas + Fantasma mamãe pra praça, dançam, `comecar_festa(foco, true)`, `marco("festa_cemiterio", 4.0)`; `ao_recomecar()` → jardim; `pilotar_auto`/`iniciar_auto`/`marcos_obrigatorios` como o laboratório (marcos crescem a cada task).
- `PortaFundos` (no lab): igual ao `Alcapao` em interface: `configurar(pos, aberta)`, `abrir()`, `aberta`, `perto(p)` (raio 90). Fica em `PORTA_FUNDOS := Vector2(2300, 960)` (parede de cima da sala da máquina, sprite em pé com os pés em y 900).
- `Laboratorio`: começa aberta se `alcancou("cemiterio")`; festa: `comecar_festa(foco, false)`, ~5 s depois abre a porta, a Múmia anda até ela e some, confete para, `seguir_jogador()`, `_ir_pra_porta = true`, vaga-lume logo; `guia_ligado()`/`alvo_atual()` como o castelo (saindo antes da sala onde está: `rota`); `checar_interacoes()` entra na porta quando aberta e perto (atalho também); `_sair()` no autoplay roda `verificar_fim_auto()` (falha ou `--sala=` → `_sair_com`), senão `trocar_fase(Jogo.CEMITERIO)`; `marcos_obrigatorios()` troca `pode_recomecar` por `porta_fundos_aberta`, `porta_fundos` (com `--sala=`: `festa_laboratorio`, `porta_fundos`).
- `jardim.gd` resumo: `"jogo completo: jardim, castelo, laboratório, cemitério, festa, volta ao jardim com a porta aberta e entrada de novo"`.

- [ ] **Step 1: Testes de cena que falham** (`teste_cemiterio_cena.gd`, progresso `user://progresso_teste_cemi_cena.cfg` antes de instanciar): `teste_porta_fundos_fechada_sem_progresso`, `teste_porta_fundos_aberta_com_progresso` (`marcar("cemiterio")`), `teste_porta_fundos_fora_do_caminho` (segmentos `inicio`→`_passar(vao, SALAO)` de cada sala do lab e `inicio`→`_passar(VAOS.formas)` passam a > 150 px de `PORTA_FUNDOS`), `teste_cemiterio_marca_progresso` (castelo, laboratorio, cemiterio).
- [ ] **Step 2:** FAIL → **Step 3:** implementar (arte, sons, cena) → **Step 4:** PASS + suíte toda.
- [ ] **Step 5:** autoplay inteiro (`timeout 900`, segundo plano) → laboratório passa por `porta_fundos`, cemitério vazio vai direto pra festa → A → jardim → `AUTOPLAY OK` com o resumo novo; `--fase=cemiterio --autoplay` OK; `--fase=laboratorio --autoplay --sala=formas` OK (sai na porta).
- [ ] **Step 6: Commit** `Porta dos fundos do laboratório e esqueleto do cemitério`.

### Task 3: Esconde-esconde dos fantasminhas (Lápides)

**Files:** Create `scripts/regras/estado_esconde.gd` (`EstadoEsconde`), `scripts/cemiterio/lapides.gd` (`Lapides extends Atividade`), `scripts/cemiterio/fantasminha.gd` (`Fantasminha extends Node2D`). Modify `cemiterio.gd` (`ordem` + `lapides`).

**Interfaces:**
- `EstadoEsconde._init(semente: int, esconderijos: int = 10, fantasmas: int = 5)`; `tem_fantasma(i) -> bool`; `achar(i) -> String` ∈ `"achou"`, `"vazio"`, `"ja_achado"`; `seguindo() -> Array[int]` (esconderijos achados não entregues); `entregar() -> int` (quantos entregou agora); `entregues() -> int`; `faltam_achar() -> Array[int]`; `terminou() -> bool` (5 entregues).
- `Lapides`: 10 esconderijos (lápides 3 desenhos, abóboras grandes, arbustos) em posições locais à mão espalhadas na área (`o + ...`, nenhum a < 220 px de outro, nenhum no corredor `vão → mamãe`); mamãe em `o + (1050, 700)`; achar = criança a < 110 px do esconderijo; fantasminha pula pra fora (`achei`) e segue em fila (rastro como `Quarto`, `ESPACO_FILA` igual, sem física); encostar na mamãe (`RAIO_MONSTRO`) entrega os que seguem (voam pra ela, `marcar_icone`), `progresso_feito()` em achar e entregar; vazio: `hum` baixinho com intervalo, `marco("vazio")`, sem avanço. Risadinha: a cada 3 s, `volume_db` de −30 (longe, ≥ 1400 px) a −6 (perto) pelo fantasminha não achado mais perto, só com a criança na área; brilho espiando de trás do esconderijo a cada ~4 s.
- `alvo()`: esconderijo não achado mais perto; se nenhum, a mamãe. `alvo_auto()`: primeiro encosta num esconderijo vazio de propósito; depois vai achando o mais perto; entrega quando não falta achar. `marco("lapides")` + `terminar()` no 5º entregue.

- [ ] **Step 1: Testes que falham** (`teste_cemiterio.gd`): `teste_esconde_sorteio` (5 distintos entre 10; mesma semente = mesmos; sementes 1..50 sempre 5); `teste_esconde_achar_entregar` (vazio não muda nada; achar 2 → `seguindo().size()==2`; `entregar()==2`; achar o mesmo de novo → `ja_achado`; 5 entregues → `terminou()`).
- [ ] **Step 2:** FAIL → **Step 3:** `estado_esconde.gd` → **Step 4:** PASS.
- [ ] **Step 5: Teste de cena que falha:** `teste_fantasminha_segue_pela_porta` — achar um, mover a criança da área pra praça em passos de 20 px atravessando o vão → o fantasminha fica a < 300 px dela.
- [ ] **Step 6:** Implementar sala; PASS; `--fase=cemiterio --autoplay` → `vazio`, `lapides`, `chave_roxa`, festa OK.
- [ ] **Step 7: Commit** `Esconde-esconde dos fantasminhas`.

### Task 4: Horta de abóboras

**Files:** Create `scripts/regras/estado_horta.gd` (`EstadoHorta`), `scripts/cemiterio/horta.gd` (`Horta extends Atividade`). Arte: `saco_sementes.svg`, `semente.svg`, `broto.svg`, `poco.svg`, `regador.svg`, `abobora_gigante.svg`, `carroca.svg`. Modify `cemiterio.gd` (`ordem` + `horta`).

**Interfaces:**
- `EstadoHorta._init(canteiros := 3)`; `canteiro(i) -> String` ∈ `vazio`, `plantado`, `crescendo`, `pronta`, `colhida`; `usar(i: int, na_mao: String) -> String` (`na_mao` ∈ `""`, `semente`, `agua`, `abobora`): semente+vazio → `"plantou"`; agua+plantado → `"regou"` (vira `crescendo`); `""`+pronta → `"colheu"`; o resto → `"hum"` (nada muda); `crescer(i)` (crescendo → pronta); `entregar() -> String` (`"entregou"` ou `"fim"` na 3ª); `entregues() -> int`; `proximo_passo(na_mao) -> String` ∈ `canteiro_vazio`, `canteiro_plantado`, `carroca`, `pronta`, `poco`, `sementes` (regra do vaga-lume do spec).
- `Horta` (o = área): sementes `o+(150,250)`, poço `o+(950,250)`, canteiros `o+(300,650)`, `o+(550,820)`, `o+(800,650)`, carroça `o+(950,880)`; a carroça é do **Lobisomem** (reusa `lobisomem.svg`; ele gosta de plantas desde o lab), balão com 3 abóboras gigantes. Raios: itens 100, canteiros 100. Pegar semente/água = `dar_na_mao(..., false)`. Avanço em plantou/regou/colheu/entregou. Crescer: tween 2 s (broto → abóbora gigante) e `crescer(i)`. `marco("hum_horta")` no 1º "hum"; `marco("horta")` + `terminar()` no `fim`.
- `alvo()`/`alvo_auto()`: a partir de `proximo_passo`; o piloto leva água a um canteiro vazio uma vez de propósito.

- [ ] **Step 1: Testes que falham:** `teste_horta_passos` (ciclo completo de uma abóbora; 3 → `fim`); `teste_horta_erros_nao_perdem` (água em vazio, semente em plantado, abóbora em canteiro → `hum` e estados iguais); `teste_horta_proximo_passo` (cada caso do spec).
- [ ] **Step 2–4:** FAIL → implementar → PASS.
- [ ] **Step 5: Teste de cena que falha:** `teste_laco_semente_agua_nao_cala_o_vagalume` — 20 ciclos pegar semente / pegar água (soltando no canteiro errado) com `_tempo_sem_progresso += 1` → `>= 14`.
- [ ] **Step 6:** Implementar sala; PASS; autoplay do cemitério → `hum_horta`, `horta`, `chave_amarela`.
- [ ] **Step 7: Commit** `Horta de abóboras`.

### Task 5: Labirinto de cerca viva

**Files:** Create `scripts/regras/estado_labirinto.gd` (`EstadoLabirinto`), `scripts/cemiterio/labirinto.gd` (`Labirinto extends Atividade`). Arte: `pegada.svg`. Modify `cemiterio.gd`.

**Grade:** 6 colunas × 5 linhas, célula 200 px, origem no canto da área (`x 1500`, `y 100`). Entrada pela célula `(2, 4)` (portão amarelo embaixo, `x 1900–2100`). Chave em `(0, 0)`. Desenho como texto em `EstadoLabirinto.PADRAO` (13 × 11 caracteres: `#` parede, `.` livre; células nas posições ímpares), feito à mão com 2–3 becos e um só caminho até a chave. Cercas internas: retângulos de 40 px de espessura centrados nas divisas das células (`StaticBody2D` da própria sala, desenho verde).

**Interfaces:**
- `EstadoLabirinto._init(texto: Array[String])`; `static padrao()`; `livre(de: Vector2i, para: Vector2i) -> bool` (vizinhas sem parede); `caminho(de, ate) -> Array[Vector2i]` (BFS, inclui as pontas); `proximo(de, ate) -> Vector2i`; `becos() -> int` (células com 1 saída, fora entrada e chave); `paredes() -> Array[Rect2i]` (segmentos de parede em coordenadas de grade, pra montar colisão).
- `Labirinto`: `celula(p: Vector2) -> Vector2i`, `centro(c: Vector2i) -> Vector2`; pegadas fracas no caminho `ENTRADA → CHAVE` (brilham mais a < 300 px da criança); chave flutuando em `centro(CHAVE)`; encostar (< 90) → `terminar()` com a chave voando da posição dela (o `_ao_concluir` da base usa `monstro()`; sem monstro, `Labirinto.origem_da_chave()` — mudar a base: `Atividade.origem_da_chave() -> Vector2` padrão = posição do monstro).
- `alvo()`: `centro(proximo(celula(criança), CHAVE))` (na própria célula da chave → a chave). `caminho_ate(destino)`: `centro(proximo(celula(criança), celula(destino) se dentro da grade, senão ENTRADA))`; já na entrada → `destino`.
- `alvo_auto()`: primeiro entra num beco de propósito (`marco("beco")`), depois segue `alvo()`.

- [ ] **Step 1: Testes que falham:** `teste_labirinto_solucionavel` (caminho entrada→chave existe; `becos() >= 2`); `teste_labirinto_proximo_vizinho` (de toda célula, `proximo(c, CHAVE)` é vizinha e `livre(c, proximo)`); `teste_labirinto_paredes_fecham` (não há passagem entre células separadas por `#`).
- [ ] **Step 2–4:** FAIL → `estado_labirinto.gd` → PASS.
- [ ] **Step 5: Testes de cena que falham:** `teste_vagalume_labirinto_nao_atravessa` (criança no centro de cada célula: o alvo do vaga-lume é o centro de uma célula vizinha livre ou a própria chave); `teste_saida_do_labirinto_pelos_corredores` (labirinto terminado, criança na chave, `alvo_atual()` = centro de célula vizinha livre, não o vão).
- [ ] **Step 6:** Implementar sala + `caminho_ate` + `origem_da_chave`; PASS; autoplay → `beco`, `labirinto`, `chave_rosa`.
- [ ] **Step 7: Commit** `Labirinto de cerca viva`.

### Task 6: Pega-pega com o Fantasmão (Arena)

**Files:** Create `scripts/cemiterio/arena.gd` (`Arena extends Atividade`), `scripts/cemiterio/fantasmao.gd` (`Fantasmao extends Node2D`). Modify `cemiterio.gd`.

**Interfaces:**
- `Fantasmao`: `const MAX := 228.0`, `MIN := 95.0`, `CANSA := 8.0` (s até chegar no mínimo), `FOGE := 450.0` (distância que faz fugir), `PEGA := 130.0`, `DESCANSO := 1.5`; `configurar(limites: Rect2)` (área encolhida 90 px); `mover(delta, crianca: Vector2) -> bool` (true quando foi pego neste quadro); `velocidade() -> float`; `pegadas: int`. Foge na direção oposta à criança; perto da borda, projeta a fuga ao longo da borda; nos cantos fica (dá pra encurralar). Velocidade = `lerp(MAX, MIN, clamp(tempo_fugindo / CANSA, 0, 1))`; zera `tempo_fugindo` depois de cada pegada. Pego: ri (`peguei`), gira, fica parado `DESCANSO` s (não conta de novo enquanto descansa).
- `Arena`: monta o Fantasmão no meio; `checar(p)` chama `mover` só com a criança dentro da arena (fora, ele passeia devagar no meio); a cada pegada `progresso_feito()`, `marco("pegou_%d")`; na 3ª: ele se rende (comemora), `marco("arena")`, `terminar()`. `alvo()` = Fantasmão; `alvo_auto()` = posição do Fantasmão.

- [ ] **Step 1: Testes de cena que falham:** `teste_fantasmao_fica_na_arena` (600 quadros com a criança empurrando de vários lados → sempre dentro de `area`); `teste_fantasmao_cansa` (velocidade cai de ~228 pra ≤ 100 em 8 s de fuga; volta ao máximo depois de uma pegada); `teste_pegada_conta_uma_vez` (criança parada encostada 120 quadros → `pegadas == 1`); `teste_ganha_devagar` (perseguição simulada a 150 px/s em linha reta na direção dele por 40 s → `pegadas == 3`).
- [ ] **Step 2:** FAIL → **Step 3:** implementar → **Step 4:** PASS; autoplay → `pegou_1..3`, `arena`, festa.
- [ ] **Step 5: Commit** `Pega-pega com o Fantasmão`.

### Task 7: Festa, partida inteira e documentação

**Files:** Modify `cemiterio.gd` (festa com mamãe + fantasminhas + Fantasmão + Lobisomem; piloto: parado até o vaga-lume, encosta uma vez no portão roxo trancado `marco("trancada")`), `README.md`.

- `marcos_obrigatorios()` = `["inicio_cemiterio", "guia", "trancada", "vazio", "lapides", "chave_roxa", "abriu_horta", "hum_horta", "horta", "chave_amarela", "abriu_labirinto", "beco", "labirinto", "chave_rosa", "abriu_arena", "pegou_1", "pegou_2", "pegou_3", "arena", "festa_cemiterio", "pode_recomecar"]`; com `--sala=`: festa + pode_recomecar.

- [ ] **Step 1:** `--fase=cemiterio --autoplay --capturas=<scratchpad>/fotos` OK; olhar fotos (nada escuro demais, nada atrás de cerca, festa visível); `--sala=` de cada área OK.
- [ ] **Step 2:** autoplay de ponta a ponta (`timeout 900`) OK com o resumo novo.
- [ ] **Step 3:** suíte toda PASS; nenhum `progresso.cfg` real criado.
- [ ] **Step 4:** README: fase 4 (tabela, o que observar, comandos, estrutura).
- [ ] **Step 5: Commit** `Festa do cemitério, partida inteira e README`.
