# Laboratório do Frankenstein — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fase 3 (porão do castelo): sala da máquina + Poções, Canos e Formas, com
passagem por um alçapão que abre na festa do castelo, tudo sobre uma base comum
"fase de salas" extraída do castelo.

**Architecture:** `FaseDeSalas extends Fase` concentra o que hoje está no
`castelo.gd` (mapa de salas/vãos/paredes, portas com chave, chaveiro, rota do
vaga-lume, piloto por sala, `--sala=`). `Castelo` e `Laboratorio` só configuram
o mapa e criam suas atividades. Regras novas são classes `RefCounted` puras em
`scripts/regras/`, testadas com `--script`; o que depende de cena vai num teste
de cena (como `teste_castelo_cena`).

**Tech Stack:** Godot 4.7.2, GDScript tipado, GL Compatibility; sons por
`ferramentas/gerar_sons.py` (numpy); arte SVG à mão.

**Spec:** `docs/superpowers/specs/2026-11-22-laboratorio-design.md`

## Global Constraints

- Nada pra ler; nada pra perder (erro nunca tira progresso); zero susto; tudo encostando.
- Vaga-lume do laboratório espera **12 s** (`espera_guia = 12.0`); o do castelo continua 9 s.
- O castelo tem que se comportar igual até a festa (nenhuma regressão).
- Testes e autoplay **nunca** escrevem `user://progresso.cfg` (o da criança).
- Estilo da arte: contorno `#2b2346` largura 5, cantos redondos, cores quentes chapadas; porão claro (pedra lilás), nada escuro.
- Sons sintetizados e determinísticos em `gerar_sons.py`; nada alto (máquina ligando sem barulho alto).
- Pedidos das poções, nesta ordem: verde (azul+amarelo), laranja (vermelho+amarelo), roxo (vermelho+azul), rosa (vermelho+branco). Mesma cor duas vezes = a própria cor.
- Canos: girar só ficando parado (~0,5 s o primeiro giro, depois a cada ~1 s); passar correndo não gira.
- Formas: rodadas 1 forma ×3, 2 formas ×2, 3 formas ×2; lâmpadas ficam acesas; erro recomeça só o grupo; conta só na borda de entrada; nunca cantos opostos seguidos (nem entre grupos).
- Monstros: Poções = Frankenstein, Canos = Lobisomem, Formas = Drácula, Múmia na máquina.
- Rodar o autoplay completo com `timeout 600` e em segundo plano (deve passar de ~190 s pra ~350 s).

## Review Focus

1. **Guia nunca some com recurso infinito:** pegar frasco/plop em laço ou ficar girando o cano-armadilha não pode zerar o tempo do vaga-lume. Progresso = cor certa no caldeirão, pedido feito, cano do caminho ficando certo, forma certa (testes nas Tasks 4, 5, 6).
2. **Alçapão aberto (com progresso) pego sem querer** no caminho entre a porta de entrada e as portas do salão (teste de cena na Task 3).
3. **Conferência do castelo continua rodando no autoplay** mesmo sem botão de jogar: roda ao entrar no alçapão (Task 3).
4. **Criança parada em cima da peça certa / do botão certo:** o vaga-lume não fica preso nela de um jeito que confunda (Canos: aponta a própria peça = "fica aí"; Formas: aponta o meio quando ela está em cima do botão da vez) (Tasks 5, 6).
5. **Mudar de grupo nas Formas com a criança em cima de um botão** não conta pisada (só a borda de entrada conta) (Task 6).

---

### Task 1: Progresso por fase e `--fase=laboratorio`

**Files:**
- Modify: `scripts/regras/progresso.gd`
- Modify: `scripts/jogo.gd`
- Test: `tests/teste_laboratorio.gd` (novo, `--script`, mesmo esqueleto de `teste_castelo.gd`)

**Interfaces:**
- Produces: `Progresso.alcancou(fase: String) -> bool`, `Progresso.marcar(fase: String) -> void`; `castelo_aberto()` = `alcancou("castelo")` (também lê a chave antiga `jogo/castelo_aberto`), `marcar_castelo_aberto()` = `marcar("castelo")`. Guarda em `fases/<nome> = true`.
- Produces: `Jogo.LABORATORIO := "res://scenes/laboratorio.tscn"`; argumento `--fase=laboratorio`.

- [ ] **Step 1: Teste que falha** — `teste_progresso_por_fase` em `tests/teste_laboratorio.gd` (caminho `user://progresso_teste_lab.cfg`):
  - novo: `alcancou("castelo") == false`, `alcancou("laboratorio") == false`;
  - `marcar("laboratorio")` → relido: `alcancou("laboratorio") == true`, `alcancou("castelo") == false`;
  - arquivo antigo escrito à mão com `ConfigFile` `jogo/castelo_aberto = true` → `castelo_aberto() == true` e `alcancou("castelo") == true`;
  - `apagar()` zera tudo.
- [ ] **Step 2:** `godot --headless --path . --script res://tests/teste_laboratorio.gd` → FAIL (método não existe).
- [ ] **Step 3:** Implementar em `progresso.gd`; em `jogo.gd`, const `LABORATORIO` e `--fase=laboratorio`. Atualizar o comentário de topo dos dois.
- [ ] **Step 4:** O mesmo comando → PASS; `teste_castelo.gd` (68) continua PASS.
- [ ] **Step 5: Linha de base do castelo (pra Task 2)** — rodar `timeout 600 godot --path . -- --autoplay > .superpowers/sdd/2026-11-22-laboratorio/base_autoplay.log 2>&1` e guardar a lista de marcos: `grep -o 'AUTOPLAY: [a-z_]*' base_autoplay.log > base_marcos.txt`. Expected: termina em `AUTOPLAY OK`.
- [ ] **Step 6: Commit** `Progresso guarda cada fase alcançada; --fase=laboratorio`.

### Task 2: Base "fase de salas" (só refatoração)

**Files:**
- Create: `scripts/salas/fase_de_salas.gd` (`class_name FaseDeSalas extends Fase`)
- Create: `scripts/regras/estado_salas.gd` (`class_name EstadoSalas extends RefCounted`)
- Move (git mv): `scripts/castelo/atividade.gd`, `porta.gd`, `chaveiro.gd` → `scripts/salas/`
- Modify: `scripts/regras/estado_castelo.gd` (vira `extends EstadoSalas`, mantém `SALAS`, `CHAVE_DA_SALA`, `PORTAS`)
- Modify: `scripts/castelo/castelo.gd`, `scripts/castelo/{cozinha,musica,biblioteca,corredor_caixas,quarto}.gd`
- Test: `tests/teste_laboratorio.gd` (`teste_estado_salas`)

**Interfaces:**
- Produces `EstadoSalas`: `_init(salas: Array[String], chave_da_sala: Dictionary, portas: Dictionary)`; tudo o que `EstadoCastelo` tem hoje (`carregando`, `pegar`, `soltar`, `concluir`, `concluida`, `tem_chave`, `porta_aberta`, `pode_abrir`, `tentar_abrir`, `todas_salas`) + `cor_da_porta(porta) -> String` + `abre_por_sala(porta) -> bool` (verdadeiro quando o requisito não é uma cor de `CORES_CHAVE := ["azul","vermelha","verde","laranja"]`, como o quarto que abre com `"caixas"`). Requisito que não é cor = sala concluída, mesmo que não esteja em `salas` (o castelo não lista `caixas` em `SALAS`). `todas_salas()` com `salas` vazio = `true`.
- `EstadoCastelo._init()` chama `super(SALAS, CHAVE_DA_SALA, PORTAS)`; constantes ficam (os testes usam).
- Produces `FaseDeSalas` (vars preenchidas em `configurar_mapa()`): `salao: Rect2`, `areas: Dictionary`, `vaos: Dictionary`, `paredes: Array`, `ordem: Array[String]`, `cores_porta: Dictionary`, `cor_fundo`, `cor_parede`, `cor_face: Color`, `estado: EstadoSalas`, `atividades`, `portas`, `chaveiro`.
  - Virtuais: `configurar_mapa()`, `nova_atividade(id: String) -> Atividade`, `decorar()` (depois das paredes e do `_mundo`), `festa_final()`, `rota(destino: String, alvo: Vector2) -> Vector2` (padrão: sai pelo vão da sala atual pro salão, depois entra pelo vão do destino), `marcos_obrigatorios() -> Array[String]`.
  - `montar()` é da base: `configurar_mapa()` → fundo → `_pisos` → atividades (`nova_atividade` + `configurar(self, areas[id])` + `montar()` + sinal) → paredes → `add_child(_mundo)` → `decorar()` → portas (para cada id em `cores_porta` que está em `ordem`) → interface + chaveiro.
  - Serviços que saem do castelo sem mudar: `no_mundo`, `mao_vazia`, `dar_na_mao(item, id, conta_progresso := true)`, `tirar_da_mao`, `sala_do_jogador`, `na_tela`, `piso`, `enfeite`, `tocha`, `checar_interacoes`, `_abrir_porta`, `_ao_concluir`, `proxima_atividade`, `alvo_atual`, `alvo_auto`, `_passar`, `_pular_ate`, `verificar_fim_auto` (lista = `marcos_obrigatorios()`).
  - `checar_interacoes`: a fechadura só balança se `not estado.abre_por_sala(id)` (substitui o `id != "quarto"`). `_abrir_porta` usa `estado.cor_da_porta(id)`. Depois de `_ao_concluir`, portas que `abre_por_sala` e `tentar_abrir` dão certo abrem sozinhas (substitui o caso fixo do quarto).
- `Atividade.castelo: Castelo` vira `Atividade.mapa: FaseDeSalas` (`configurar(p_mapa: FaseDeSalas, p_area: Rect2)`); nas 5 salas do castelo, `castelo.` → `mapa.` e `castelo.estado` continua funcionando (é `EstadoSalas`). (`fase` não serve: a Música já tem `var fase`.)
- `Castelo` fica com: constantes de layout (`SALAO`, `AREAS`, `VAOS`, `PAREDES`, `ORDEM`, `CORES_PORTA` — os testes usam `Castelo.SALAO`), `configurar_mapa()` copiando-as, `nova_atividade`, `decorar()` (salão: tapete, tochas, abóboras, porta de entrada), `festa_final()` (a de hoje), `rota()` (casos do quarto/corredor de hoje), `ao_recomecar`, `iniciar_auto`, `pilotar_auto`, `marcos_obrigatorios()` (a lista de hoje) e `Jogo.progresso.marcar_castelo_aberto()`.
- `Chaveiro.CORES` ganha `"verde": Color("#5bd17a")`, `"laranja": Color("#ff9f43")`.

- [ ] **Step 1: Teste que falha** — `teste_estado_salas`: `EstadoSalas.new(["a","b"], {"a": "verde"}, {"b": "verde", "c": "b"})`: `pode_abrir("b") == false`; `concluir("a") == "verde"`; `tentar_abrir("b") == true`; `abre_por_sala("c") == true`, `abre_por_sala("b") == false`; `pode_abrir("c") == false` até `concluir("b")`; `todas_salas()` só depois de a e b; `EstadoSalas.new([], {}, {}).todas_salas() == true`.
- [ ] **Step 2:** rodar `teste_laboratorio.gd` → FAIL.
- [ ] **Step 3:** Criar `estado_salas.gd`, mudar `estado_castelo.gd`, mover os três arquivos, criar `fase_de_salas.gd`, enxugar `castelo.gd`, trocar `castelo.` por `mapa.` nas salas. Depois: `godot --headless --path . --import` (cache de classes).
- [ ] **Step 4:** Todos os testes PASS: `teste_laboratorio`, `teste_castelo` (68), `teste_missao` (28), `teste_controle_real` (17), `teste_castelo_cena.tscn` (6).
- [ ] **Step 5: Portão da refatoração** — autoplay completo de novo; `grep -o 'AUTOPLAY: [a-z_]*'` → `diff` com `base_marcos.txt`. Expected: sem diferença e `AUTOPLAY OK` com o mesmo resumo. Também `--fase=castelo --autoplay --sala=quarto` → OK.
- [ ] **Step 6: Commit** `Base FaseDeSalas extraída do castelo (sem mudar o castelo)`.

### Task 3: Esqueleto do laboratório + alçapão no castelo

**Files:**
- Create: `scripts/laboratorio/laboratorio.gd` (`class_name Laboratorio extends FaseDeSalas`), `scenes/laboratorio.tscn`
- Create: `scripts/laboratorio/maquina.gd` (`class_name Maquina extends Node2D`)
- Create: `scripts/castelo/alcapao.gd` (`class_name Alcapao extends Node2D`)
- Create arte: `alcapao_fechado.svg`, `alcapao_aberto.svg`, `escada.svg`, `maquina.svg`, `engrenagem.svg`, `tubo_vidro.svg`
- Modify: `scripts/castelo/castelo.gd`, `scripts/jardim.gd` (resumo), `ferramentas/gerar_sons.py` (`laboratorio(saida)`: `alcapao`, `maquina`, `musica_laboratorio`)
- Create: `tests/teste_laboratorio_cena.gd` + `.tscn`

**Layout do laboratório** (W 3800, H 3000; salão = sala da máquina):
- `SALAO := Rect2(1300, 900, 1200, 1000)`
- `AREAS`: `pocoes Rect2(100, 900, 1100, 1000)`, `canos Rect2(2600, 700, 1100, 1400)`, `formas Rect2(1300, 2000, 1200, 900)`
- `VAOS`: `pocoes Rect2(1200, 1300, 100, 200)` (aberto), `canos Rect2(2500, 1300, 100, 200)` (porta verde), `formas Rect2(1800, 1900, 200, 100)` (porta laranja)
- `PAREDES`: `(2600,600,1200,100)`, `(3700,600,100,1600)`, `(2600,2100,1200,100)`, `(0,800,2600,100)`, `(2500,600,100,700)`, `(2500,1500,100,700)`, `(0,800,100,1200)`, `(0,1900,1300,100)`, `(1200,900,100,400)`, `(1200,1500,100,400)`, `(1300,1900,500,100)`, `(2000,1900,500,100)`, `(1200,1900,100,1100)`, `(2500,2100,100,900)`, `(1200,2900,1400,100)`
- `inicio = Vector2(1900, 1150)` (pé da escada, encostada na parede de cima); máquina com os pés em `(1900, 1560)`, base de colisão `(360, 90)`; Múmia em `(2250, 1450)`.
- `PORTAS`: `canos: "verde"`, `formas: "laranja"`; `CHAVE_DA_SALA`: `pocoes: "verde"`, `canos: "laranja"`. `ordem` começa **vazia** nesta task (cada task de sala se adiciona).
- Cores: fundo `#cdbfe8`-ish/pedra lilás clara, parede `#7a68b0`, face `#9887c9`.

**Interfaces:**
- `Laboratorio`: `montar()` marca `Jogo.progresso.marcar("castelo")` **e** `marcar("laboratorio")`; `espera_guia = 12.0`; `musica_inicial = "res://sons/musica_laboratorio.wav"`; se `estado.todas_salas()` logo depois de montar (sala vazia) → `festa_final()` adiado (`call_deferred`); `festa_final()`: `maquina.ligar()`, monstros das salas + Múmia andam pra volta da máquina e dançam, `comecar_festa(foco, true)`, `marco("festa_laboratorio", 4.0)`; `ao_recomecar()` → `Jogo.trocar_fase(Jogo.JARDIM)`; `marcos_obrigatorios()` = `["inicio_laboratorio", "guia", ...salas..., "festa_laboratorio", "pode_recomecar"]` (o `guia` só quando há sala).
- `Maquina`: `acender_cabo(i: int)` (0..2), `espelhar(formas: Array[int], vez: int)` (lâmpadas da máquina copiam o painel — enfeite), `ligar()` (engrenagens giram, bolhas de arco-íris `CPUParticles2D`, luzes piscando, som `maquina`).
- `Alcapao`: `configurar(pos: Vector2, aberto: bool)`, `abrir()` (som `alcapao` + brilho), `aberto: bool`, `perto(p: Vector2) -> bool` = `p.distance_to(pos) < 90.0`.
- `Castelo`:
  - alçapão em `ALCAPAO := Vector2(1300, 1820)` (a abóbora desse canto vai pra `(1480, 1840)`); começa aberto se `Jogo.progresso.alcancou("laboratorio")`.
  - `festa_final()`: igual a hoje, mas `comecar_festa(foco, false)`; depois de ~5 s: `alcapao.abrir()`, o Frankenstein pula dentro (tween até o alçapão, encolhe e some), confete para, `seguir_jogador()`, `_ir_pro_alcapao = true`, vaga-lume logo (`_tempo_sem_progresso = espera_guia - 1.0`).
  - `guia_ligado()` = `not em_festa or _ir_pro_alcapao`; `alvo_atual()` = `ALCAPAO` quando `_ir_pro_alcapao`.
  - `checar_interacoes()`: alçapão aberto e `perto` → `_descer()` (vale também fora da festa, como atalho).
  - `_descer()` (uma vez): no autoplay, `marco("alcapao")`, `falhas := _auto_falhas + verificar_fim_auto()`; se tem falha **ou** `--sala=` → `_sair_com(falhas)`; senão `Jogo.trocar_fase(Jogo.LABORATORIO)`.
  - `marcos_obrigatorios()`: troca `"pode_recomecar"` por `"alcapao"`; com `--sala=`: `["festa_castelo", "alcapao"]`.
  - piloto: na festa, anda até o alçapão quando `_ir_pro_alcapao`.
- `jardim.gd`: resumo vira `"jogo completo: jardim, castelo, laboratório, festa, volta ao jardim com a porta aberta e entrada de novo"`.

- [ ] **Step 1: Testes de cena que falham** — `tests/teste_laboratorio_cena.gd` (cena, progresso `user://progresso_teste_lab_cena.cfg` setado **antes** de instanciar, apagado no fim):
  - `teste_alcapao_fechado_sem_progresso`: castelo sem progresso → `c.alcapao.aberto == false`; criança em `ALCAPAO` + `checar_interacoes()` → não desce (`c._descendo == false`).
  - `teste_alcapao_aberto_com_progresso`: `marcar("laboratorio")`, novo castelo → `aberto == true`.
  - `teste_alcapao_fora_do_caminho`: para cada vão do salão (`cozinha`, `musica`, `biblioteca`, `caixas`), a menor distância do segmento `inicio → _passar(vao, SALAO)` até `ALCAPAO` é > 90 + 60 (raio + folga do corpo).
  - `teste_laboratorio_marca_progresso`: instanciar o laboratório → `alcancou("castelo")` e `alcancou("laboratorio")`.
- [ ] **Step 2:** `godot --headless --path . res://tests/teste_laboratorio_cena.tscn` → FAIL.
- [ ] **Step 3:** Implementar (arte, sons `python3 ferramentas/gerar_sons.py`, cena, castelo, laboratório, máquina).
- [ ] **Step 4:** Teste de cena PASS; todos os anteriores PASS.
- [ ] **Step 5: Autoplay** completo (`timeout 600`, em segundo plano). Expected: castelo passa pelos marcos de antes + `alcapao`, laboratório vazio vai direto pra `festa_laboratorio` → `pode_recomecar` → A → jardim → `AUTOPLAY OK` com o resumo novo. `--fase=laboratorio --autoplay` → OK. `--fase=castelo --autoplay --sala=quarto` → OK (sai no alçapão).
- [ ] **Step 6: Commit** `Alçapão na festa do castelo e esqueleto do laboratório`.

### Task 4: Poções do Frankenstein

**Files:**
- Create: `scripts/regras/estado_pocoes.gd` (`class_name EstadoPocoes`), `scripts/laboratorio/pocoes.gd` (`class_name Pocoes extends Atividade`)
- Create arte: `balde.svg` (corpo neutro; a tinta é um polígono colorido por código), `frasco.svg` (branco, recebe `modulate`), `caldeirao.svg`, `quadro_receitas.svg` (4 linhas "bolinha + bolinha = bolinha", sem texto)
- Modify: `laboratorio.gd` (`ordem` ganha `"pocoes"`; `nova_atividade`), `gerar_sons.py` (`plop`, `borbulha`)
- Test: `teste_laboratorio.gd`, `teste_laboratorio_cena.gd`

**Interfaces:**
- `EstadoPocoes`: `const PEDIDOS: Array[String] = ["verde","laranja","roxo","rosa"]`; `static misturar(a: String, b: String) -> String` (ordem não importa; iguais → a própria cor; fora da tabela → `"marrom"`); `static receita(pedido: String) -> Array[String]`; `caldeirao: Array[String]`; `pedido_atual() -> String` (`""` no fim); `feitos() -> int`; `colocar(cor: String) -> String` ∈ `"dentro"`, `"certo"`, `"fim"`, `"plop"`, `"ignorado"` (a 2ª cor sempre esvazia o caldeirão); `faltam() -> Array[String]` (cores da receita atual que ainda não estão no caldeirão); `ajuda(cor: String) -> bool` (a cor está em `faltam()` e o caldeirão não tem cor errada).
- `Pocoes`: 4 baldes (vermelho `#ff5d73`, azul `#4aa3ff`, amarelo `#ffd23f`, branco `#ffffff`) em fila na parede de baixo da sala; caldeirão no meio; quadro na parede de cima; Frankenstein perto do caldeirão com balão `mostrar_varios` = 4 frascos (pedidos) e `marcar_icone(i)` a cada pedido; o frasco do pedido atual aparece no balão com a cor pedida.
  - Mão vazia + balde (`RAIO_ITEM`) → novo `ItemPerdido` `"frasco_<cor>"` tingido, `mapa.dar_na_mao(item, id, false)` (**não** conta progresso).
  - Com frasco + caldeirão (`RAIO_MONSTRO`) → `tirar_da_mao()`, frasco voa e cai, `colocar`. `progresso_feito()` só se a cor `ajuda` (antes de colocar) ou o resultado é `certo`/`fim`. `plop` → som `plop` + `marco("plop")`; `certo` → `borbulha`, poção voa pro Frankenstein, `voltinha()`; `fim` → `concluir()`, `marco("pocoes")`, `terminar()`.
  - `dona_de(item)` = `item.begins_with("frasco_")`.
  - `alvo()`: com frasco → caldeirão; senão balde da 1ª cor de `faltam()` (com cor errada dentro, `faltam()` ainda diz qual balde — a 2ª cor esvazia).
  - `alvo_auto()`: no 1º pedido, de propósito, coloca azul + **vermelho** (plop) antes de acertar.

- [ ] **Step 1: Testes que falham** (`teste_laboratorio.gd`):
  - `teste_mistura`: as 4 receitas nas duas ordens; `misturar("azul","azul") == "azul"`; `misturar("azul","branco")` não está em `PEDIDOS`.
  - `teste_pedidos_em_ordem`: azul → `dentro`; amarelo → `certo`; `pedido_atual() == "laranja"`; vermelho+azul (roxo fora da vez) → `plop`, caldeirão vazio, `feitos() == 1`; completar os 3 → último `fim`; depois `colocar` → `ignorado`.
  - `teste_ajuda`: pedido verde com caldeirão vazio: `ajuda("azul")`, `not ajuda("vermelho")`; com vermelho dentro: `not ajuda("azul")`.
- [ ] **Step 2:** FAIL → **Step 3:** implementar `estado_pocoes.gd` → **Step 4:** PASS.
- [ ] **Step 5: Teste de cena que falha** — `teste_plop_nao_cala_o_vagalume` (pocoes direto no laboratório): 20 ciclos de pegar vermelho + colocar vermelho com `mapa._tempo_sem_progresso` acumulando 1 s por ciclo → `tempo_sem_progresso() >= 12.0`; e uma cor que ajuda zera.
- [ ] **Step 6:** Implementar `pocoes.gd`, arte, sons; ligar no laboratório. Teste de cena PASS; suíte toda PASS.
- [ ] **Step 7:** `--fase=laboratorio --autoplay` → marcos `plop`, `pocoes`, `chave_verde`, festa. Expected `AUTOPLAY OK`.
- [ ] **Step 8: Commit** `Poções do Frankenstein`.

### Task 5: Canos do Lobisomem

**Files:**
- Create: `scripts/regras/estado_canos.gd` (`class_name EstadoCanos`), `scripts/laboratorio/canos.gd` (`class_name Canos extends Atividade`), `scripts/laboratorio/peca_cano.gd` (`class_name PecaCano extends Node2D`)
- Create arte: `cano_reta.svg`, `cano_curva.svg` (as duas com e sem água: a água é uma camada que aparece por `modulate`/visibilidade), `torneira.svg`, `vaso.svg`, `planta_pequena.svg`, `planta_gigante.svg`
- Modify: `laboratorio.gd` (`ordem` + `"canos"`, porta verde), `gerar_sons.py` (`clique`, `agua`, `planta`)
- Test: `teste_laboratorio.gd`, `teste_laboratorio_cena.gd`

**Quebra-cabeça (grade 3 colunas × 4 linhas, `Vector2i(coluna, linha)`)**: lados `N=1, E=2, S=4, W=8`; `reta` rot 0 = N|S, rot 1 = E|W (rot 2/3 repetem); `curva` rot 0 = N|E, 1 = E|S, 2 = S|W, 3 = W|N; girar = rot+1 (horário). Torneira entra por **N** em `(0,0)`; o vaso sai por **S** de `(1,3)`.

| célula | tipo | solução | começa |
|---|---|---|---|
| (0,0) | curva | 0 (N-E) | 2 |
| (1,0) | reta | 1 (E-W) | 1 (já certa) |
| (2,0) | curva | 2 (S-W) | 0 |
| (2,1) | reta | 0 (N-S) | 1 |
| (2,2) | curva | 3 (W-N) | 1 |
| (1,2) | reta | 1 (E-W) | 0 |
| (0,2) | curva | 1 (E-S) | 3 |
| (0,3) | curva | 0 (N-E) | 2 |
| (1,3) | curva | 2 (S-W) | 2 (já certa) |
| (1,1) | curva | — armadilha | 0 |

(7 peças do caminho começam erradas; a armadilha no meio não liga a nada que leve ao vaso.)

**Interfaces:**
- `EstadoCanos`: `_init(pecas: Dictionary)` (célula → `{"tipo", "rot", "solucao"}`; solução `-1` = armadilha); `girar(cel: Vector2i) -> void`; `lados(cel) -> int`; `agua() -> Array[Vector2i]` (células cheias, seguindo da torneira); `conectado() -> bool`; `certas() -> int` (peças do caminho com lados iguais aos da solução — reta compara `rot % 2`); `proxima_errada() -> Vector2i` (`Vector2i(-1,-1)` se nenhuma), na ordem do caminho; `static padrao() -> EstadoCanos` (a tabela acima).
- `PecaCano`: `configurar(tipo)`, `girar_para(rot)` (tween 90°, som `clique`), `encher(atraso)` (água aparece), `contem(p)` (quadrado de lado 170). Células com centro em `area.position + Vector2(300 + c*260, 330 + l*260)`; torneira acima de `(0,0)`, vaso e planta abaixo de `(1,3)`, Lobisomem ao lado do vaso.
- `Canos.checar(p)`: peça sob a criança; se `p` mudou < 4 px desde o último `checar` **e** está na mesma peça → `_parado += get_physics_process_delta_time()`; senão `_parado = 0`, `_proximo_giro = 0.5`. Quando `_parado >= _proximo_giro` → `girar`, `_proximo_giro += 1.0`. Depois de girar: `certas()` maior que o maior já visto → `progresso_feito()`; `conectado()` → água corre peça a peça (`encher` com atraso crescente), planta cresce (`planta`), Lobisomem comemora, `marco("canos")`, `terminar()`. Girar a armadilha: `marco("armadilha")`, sem progresso.
- `alvo()` = centro de `proxima_errada()` (se ela está em cima, continua sendo ali: "fica parado"). `alvo_auto()`: antes de tudo, para em cima da armadilha até ela girar uma vez; depois cada `proxima_errada()` até ficar certa.

- [ ] **Step 1: Testes que falham** (`teste_laboratorio.gd`):
  - `teste_canos_rotacao`: reta rot 0 → `N|S`, depois de girar → `E|W`; curva gira pelos 4 e volta.
  - `teste_canos_padrao`: `padrao()` começa desconectado, `certas() == 2`, `proxima_errada() == Vector2i(0,0)`; girando cada peça errada até a solução → `conectado() == true`, `agua()` tem as 9 do caminho e **não** tem `(1,1)`.
  - `teste_canos_armadilha_nao_conecta`: no padrão resolvido, girar `(1,1)` 4 vezes → continua `conectado()`, `(1,1)` nunca em `agua()`.
  - `teste_canos_toda_rotacao_alcancavel`: cada peça volta à rotação inicial em 4 giros.
- [ ] **Step 2:** FAIL → **Step 3:** `estado_canos.gd` → **Step 4:** PASS.
- [ ] **Step 5: Testes de cena que falham** (`teste_laboratorio_cena.gd`, canos ligada, porta aberta à força):
  - `teste_passar_correndo_nao_gira`: 60 chamadas de `checar` com `p` andando 10 px por chamada atravessando `(0,0)` → rotação igual.
  - `teste_parado_gira`: 31 chamadas com `p` parado no centro de `(0,0)` → girou 1 vez; mais 60 → girou mais 1.
  - `teste_armadilha_nao_cala_o_vagalume`: 300 chamadas paradas na armadilha com `_tempo_sem_progresso` subindo → `tempo_sem_progresso() > 0` (não zerou).
- [ ] **Step 6:** Implementar sala, peças, arte, sons. PASS; suíte toda PASS.
- [ ] **Step 7:** `--fase=laboratorio --autoplay` → `armadilha`, `canos`, `chave_laranja`. `--sala=canos` → OK.
- [ ] **Step 8: Commit** `Canos do Lobisomem`.

### Task 6: Formas do Drácula

**Files:**
- Modify: `scripts/regras/estado_sequencia.gd` (parâmetro novo)
- Create: `scripts/laboratorio/formas.gd` (`class_name Formas extends Atividade`), `scripts/laboratorio/botao_forma.gd`, `scripts/laboratorio/painel.gd` (`class_name Painel extends Node2D`)
- Create arte: `forma_circulo.svg`, `forma_estrela.svg`, `forma_coracao.svg`, `forma_triangulo.svg`, `botao_forma.svg` (base), `lampada.svg`, `painel.svg`
- Modify: `laboratorio.gd` (`ordem` + `"formas"`, porta laranja; a máquina espelha o painel), `gerar_sons.py` (`forma_0`..`forma_3`, uma nota por forma; reaproveita `rodada`)
- Test: `teste_laboratorio.gd`, `teste_laboratorio_cena.gd`, `teste_castelo.gd` continua igual

**Interfaces:**
- `EstadoSequencia._init(semente, tamanhos, cores, opostos, entre_grupos := false)`: com `entre_grupos`, a 1ª forma de cada grupo também respeita (diferente e não oposta) a última do grupo anterior. Com `false`, **nenhum** número aleatório a mais (as sequências da música com semente 7 ficam idênticas).
- `Formas`: `const FORMAS := ["circulo","estrela","coracao","triangulo"]` (cores `#ff6f91`, `#ffd23f`, `#ff5d73`, `#4aa3ff`), `OPOSTOS := {0:3, 3:0, 1:2, 2:1}`; `seq = EstadoSequencia.new(7 if Jogo.auto else randi(), [1,1,1,2,2,3,3], 4, OPOSTOS, true)`; botões 2×2 em volta de `_meio = area.position + Vector2(600, 520)` com cantos `(±240, ±180)`; painel com 3 lâmpadas na parede de cima, à esquerda da porta (`area.position + Vector2(260, 0)`); Drácula à direita com 3 ícones (um por etapa: marca depois dos grupos 3, 5 e 7).
  - Painel: `mostrar(grupo: Array[int], feitos: int)` — lâmpadas com as formas do grupo (as que sobram apagadas), a da vez pulsa, as feitas ficam acesas firmes. `laboratorio.maquina.espelhar(...)` copia.
  - `checar(p)`: borda de entrada (como a Música: `_sobre`, `entrou`). Só conta em `fase == "vez"`. Certo → nota `forma_<i>`, `progresso_feito()`, painel atualiza. Grupo fechado → `rodada`, pausa 1,0 s (`fase = "pausa"`), próximo grupo no painel. Erro → `hum`, `drac.lembrar_pedido()`, `marco("forma_errada")`, grupo recomeça (`feitos = 0`). Fim → `concluir()`, `marco("formas")`, `terminar()` (liga a máquina: é a última sala).
  - `alvo()`: botão da forma da vez; se `_sobre` é esse botão → `_meio`. `alvo_auto()`: erra de propósito uma vez no 1º grupo de 2 formas; sai pro `_meio` pra entrar de novo no mesmo botão.
- `Laboratorio._ao_concluir`: além da base, `maquina.acender_cabo(i)` (pocoes 0, canos 1, formas 2).

- [ ] **Step 1: Testes que falham** (`teste_laboratorio.gd`):
  - `teste_formas_grupos`: `_percorrer` (copiar o helper de `teste_castelo.gd`) da sequência das formas → `[1,1,1,2,2,3,3]`.
  - `teste_formas_sem_oposto_nem_repeticao`: sementes 1..300, todas as formas em ordem (atravessando grupos): nunca igual à anterior, nunca `OPOSTOS[anterior]`.
  - `teste_formas_erro_recomeca_grupo`: no grupo 3 (2 formas), acerta a 1ª, erra → `proxima_cor()` volta à 1ª do mesmo grupo e `rodada` não muda.
  - `teste_musica_igual`: `EstadoSequencia.new(7, [2,3,4], 4, OPOSTOS).sequencia()` de cada rodada igual ao valor gravado **antes** de mudar o arquivo (rodar uma vez, colar os números no teste).
- [ ] **Step 2:** FAIL → **Step 3:** parâmetro `entre_grupos` → **Step 4:** PASS (e `teste_castelo` 68 PASS).
- [ ] **Step 5: Testes de cena que falham**:
  - `teste_formas_borda`: criança parada em cima do botão certo enquanto o grupo muda (`fase` vira `vez` com ela em cima) → nenhuma pisada contada até sair e entrar.
  - `teste_formas_vagalume`: em cima do botão da vez → `alvo() == _meio`; fora → o botão.
- [ ] **Step 6:** Implementar sala, painel, botões, arte, sons, espelho na máquina. PASS; suíte toda PASS.
- [ ] **Step 7:** `--fase=laboratorio --autoplay` e `--sala=formas` → `forma_errada`, `formas`, festa → OK.
- [ ] **Step 8: Commit** `Formas do Drácula`.

### Task 7: Festa da máquina, partida inteira e documentação

**Files:**
- Modify: `scripts/laboratorio/laboratorio.gd` (`iniciar_auto`, `pilotar_auto`, `marcos_obrigatorios` estrita, decoração: tubos de vidro borbulhando, luzes coloridas), `scripts/laboratorio/maquina.gd`
- Modify: `README.md` (fase 3 na tabela, o que observar, comandos de teste, estrutura)

**Interfaces:**
- `Laboratorio.pilotar_auto`: parado até o vaga-lume aparecer (12 s) como o castelo; encosta uma vez na porta verde trancada (`marco("trancada")`); depois `alvo_auto()`. `tempo_limite_auto() = 600.0`.
- `marcos_obrigatorios()` = `["inicio_laboratorio", "guia", "trancada", "plop", "pocoes", "chave_verde", "abriu_canos", "armadilha", "canos", "chave_laranja", "abriu_formas", "forma_errada", "formas", "festa_laboratorio", "pode_recomecar"]`; com `--sala=`: `["festa_laboratorio", "pode_recomecar"]`.
- Festa: máquina liga, Frankenstein, Lobisomem, Drácula e Múmia em volta da máquina dançando, confete, botão de jogar.

- [ ] **Step 1:** Ajustar a lista estrita e o piloto; `--fase=laboratorio --autoplay --capturas=<scratchpad>/fotos_lab` → `AUTOPLAY OK`. Olhar as fotos (chegada, cada sala, festa): nada escuro, nada atrás de parede, monstros visíveis na festa.
- [ ] **Step 2:** Autoplay de ponta a ponta (`timeout 600`, segundo plano) → `AUTOPLAY OK: jogo completo: jardim, castelo, laboratório, festa, volta ao jardim com a porta aberta e entrada de novo`.
- [ ] **Step 3:** Suíte toda: `teste_missao` (28), `teste_castelo` (68), `teste_controle_real` (17), `teste_castelo_cena` (6), `teste_laboratorio`, `teste_laboratorio_cena` → PASS. `ls ~/.local/share/godot/app_userdata/Monstros\ Amigos/` não tem `progresso.cfg` novo criado pelos testes.
- [ ] **Step 4:** README atualizado (comandos novos: `--fase=laboratorio`, `--sala=pocoes|canos|formas`, os dois testes novos com contagem).
- [ ] **Step 5: Commit** `Festa da máquina, partida inteira com o laboratório e README`.
