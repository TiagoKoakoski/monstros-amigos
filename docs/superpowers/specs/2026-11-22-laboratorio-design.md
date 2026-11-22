# Monstros Amigos — Fase 3: Laboratório do Frankenstein

Data: 2026-11-22. Status: design para aprovação.

## Intenção e o porquê

Mesma criança (5 anos, TV com controle). O Tiago pediu as próximas fases em
sequência — laboratório → cemitério → telhado (dois jogadores fica pra depois)
— e que **haja progressão: o laboratório pode ser mais difícil que o castelo**.

Sucesso: ele sente que o laboratório é "o próximo nível" (mais etapas, mais
raciocínio), termina sozinho ou com o vaga-lume, e aprende algo de quebra
(misturar cores, formas). Nunca fica preso.

## Princípios (valem desde o jardim)

Nada pra ler; nada pra perder (erro nunca tira progresso); zero susto; tudo
encostando; vaga-lume quando ele fica sem progresso; Esc só no teclado; arte SVG
à mão; sons sintetizados por `ferramentas/gerar_sons.py`.

## Objetivos

1. Fase do laboratório (porão do castelo): uma sala central com a **máquina** e
   3 salas com brincadeiras novas, mais difíceis que as do castelo.
2. Passagem castelo → laboratório por um **alçapão** que abre na festa do castelo.
3. Progresso salvo por fase (castelo, laboratório) — a próxima vez já começa com
   as passagens abertas.
4. Separar a parte comum do castelo numa base **"fase de salas"** que o castelo e
   o laboratório usam (e depois o cemitério e o telhado).

## Não-objetivos

- Dois jogadores (fica pra depois, decisão do Tiago).
- Cemitério e telhado (próximas fases, cada uma com seu design).
- Mudar o jardim (só o fim do castelo muda).

## Anti-objetivos

- Uma brincadeira que dependa de saber ler, ou de já saber misturar cores sem ajuda visual.
- Atravessar o chão e girar/acionar coisas sem querer (lição dos ladrilhos do castelo).
- Estado travado que exija reiniciar.
- Regredir o castelo: ele tem que continuar igual até a festa.

## Abordagens (decidido: 1)

1. **Base "fase de salas"** extraída do `castelo.gd` (salas, paredes, vãos, portas
   com chave, chaveiro, rota do vaga-lume, registro de atividades, piloto automático
   por sala, `--sala=`). Castelo e laboratório estendem. **Escolhida pelo Tiago.**
2. Copiar o que precisa do castelo — descartada (correção em até 4 lugares).
3. Laboratório como mais salas dentro da cena do castelo — descartada (mapa
   gigante, perde a sensação de fase nova).

## Fluxo do jogo

1. Jardim (igual) → porta → castelo.
2. **Festa do castelo muda:** depois da dança, um **alçapão** abre no meio do
   salão (som + brilho), o Frankenstein pula pra dentro e o vaga-lume aponta pro
   alçapão. Não aparece mais o botão de jogar no castelo.
3. Encostar no alçapão → fade → laboratório.

### Onde fica o alçapão (decisão do Claude)

Num **canto do salão** (embaixo à esquerda), fora dos caminhos entre as portas,
pra ele não cair sem querer. Fechado durante a partida normal; abre na festa.
Com `laboratorio` no progresso ele já começa aberto e funciona a qualquer momento
(atalho, como a porta do jardim); o vaga-lume do castelo continua mostrando as
salas e só aponta pro alçapão depois da festa.
4. Laboratório: 3 salas + máquina → **festa no laboratório** → botão de jogar →
   qualquer botão volta pro jardim. (Quando o cemitério existir, a festa abre a
   porta dos fundos em vez do botão — fora do escopo agora.)

### Progresso (decisão do Claude)

`user://progresso.cfg` passa a guardar **cada fase alcançada** (`castelo`,
`laboratorio`, …). Jardim: porta aberta se `castelo`. Castelo: alçapão já aberto
desde o início se `laboratorio`. Testes e autoplay continuam usando o arquivo
separado.

## O laboratório

Vista de cima, mesmo estilo; porão fofo: pedra lilás clara, tubos de vidro
borbulhando, luzes coloridas, nada escuro. Vaga-lume espera **12 s**.

```
   [Poções]═══════[ MÁQUINA ]═══porta VERDE═══[Canos]
  (Frankenstein)   (Múmia, escada    │          (Lobisomem)
   aberta           de chegada)  porta LARANJA
                                     │
                                 [Formas]
                                 (Drácula)
```
Topologia decidida; posições e tamanhos ficam pro construtor. **A criança chega
pela escada dentro da sala da máquina**; Poções é um vão aberto, Canos fica atrás
da porta verde, Formas atrás da porta laranja.

### Ordem e chaves (mesmo mecanismo do castelo)

- **Poções** aberta desde o início → dá **chave verde**.
- **Canos** (porta verde) → dá **chave laranja**.
- **Formas** (porta laranja) → terminar liga a máquina.
- A máquina mostra o avanço: um cabo acende a cada sala terminada (3 cabos).
  Os 3 acesos → máquina liga → festa.

### 1. Poções do Frankenstein — misturar cores

- 4 **baldes** de cor: vermelho, azul, amarelo, branco (nunca acabam).
- Encostar num balde com a mão vazia → pega um frasquinho daquela cor (mão = 1 coisa, regra de sempre).
- Encostar no **caldeirão** com um frasco → a cor cai dentro (o caldeirão mostra a cor).
- Com **2 cores** dentro, o caldeirão borbulha:
  - mistura = cor pedida → sai a poção, voa até o Frankenstein, próximo pedido;
  - mistura errada → "plop" suave, o caldeirão esvazia. Nada mais se perde.
- **4 pedidos**, nesta ordem: **verde** (azul+amarelo), **laranja**
  (vermelho+amarelo), **roxo** (vermelho+azul), **rosa** (vermelho+branco).
  Mesma cor duas vezes = a própria cor (não é nenhum pedido → plop).
- Balão do Frankenstein: a cor pedida (um frasco daquela cor) + 4 bolinhas de
  progresso (pedidos feitos ficam coloridos).
- **Quadro de receitas na parede** (sem texto): desenhos "bolinha azul + bolinha
  amarela = bolinha verde" para as 4 misturas. É a ajuda visual — sem ele a
  brincadeira dependeria de saber misturar cores.
- Vaga-lume: aponta o balde da próxima cor que falta (se o caldeirão tem a cor
  errada, primeiro o caldeirão — que esvazia ao receber a 2ª cor errada).

### 2. Canos do Lobisomem — levar água até a planta

- Uma grade de peças de cano no chão (por volta de 3×4), de uma **torneira** até
  o **vaso** da planta do Lobisomem. Peças retas e curvas; **6 a 7 peças no
  caminho certo** começam viradas errado, mais **1 cano-armadilha** (não leva a
  lugar nenhum) pra pensar.
- **Girar = ficar parado em cima da peça** (nunca só de passar): depois de
  ~0,5 s parado, ela gira 90°; continuando em cima, gira de novo a cada ~1 s.
  Passar correndo por cima não gira nada (lição dos ladrilhos).
- Peças espaçadas o suficiente pra andar entre elas.
- Quando a torneira liga ao vaso por canos encaixados: a água corre pelos canos
  (animação), a planta cresce gigante e floresce, Lobisomem comemora.
- Quebra-cabeça desenhado à mão (não aleatório), sempre solucionável; qualquer
  rotação é alcançável ficando parado.
- Vaga-lume: a próxima peça do caminho certo que está virada errado.

### 3. Formas do Drácula — luzes e botões

- Na parede da própria sala das Formas há um **painel com 3 lâmpadas** (a
  criança precisa ver as lâmpadas enquanto pisa — a máquina fica em outra sala;
  decisão do Claude). A máquina no meio só repete o painel, de enfeite.
- No chão, 4 **botões grandes** em quadrado 2×2
  com formas: **círculo, estrela, coração, triângulo** (cada uma com sua cor).
- As lâmpadas acendem mostrando formas; ele pisa nos botões das mesmas formas,
  **na ordem da esquerda pra direita** (a lâmpada da vez pulsa).
- **3 rodadas**: 1 forma de cada vez (3 vezes), depois 2 formas de uma vez
  (2 vezes), depois 3 formas de uma vez (2 vezes). As lâmpadas **ficam acesas**
  (é reconhecer e seguir a ordem, não memorizar — diferente da música).
- Errou: "hum", recomeça só o grupo atual. Nunca volta rodada.
- Contar só na borda de entrada no botão (como a música); nunca duas formas em
  cantos opostos seguidas (lição do direcional).
- Vaga-lume: o botão da forma da vez; se ele está em cima dele, o meio.

### Máquina e festa

- Terminar Formas → os 3 cabos acesos → a máquina liga: engrenagens giram,
  bolhas de arco-íris sobem, luzes piscam (sem barulho alto).
- Todos os monstros dançam em volta da máquina; confete; botão de jogar.

## Testes e verificação

- Os testes atuais continuam passando (jardim, controle, castelo, cena do castelo).
- Regras puras novas testadas: mistura de cores (todas as combinações, ordem não
  importa, mesma cor duas vezes), pedidos em ordem, caldeirão esvazia no erro;
  canos (rotação, conectividade, o quebra-cabeça desenhado é solucionável, a
  armadilha não conecta); formas (rodadas 1/2/3, erro recomeça o grupo, sem
  cantos opostos seguidos); progresso por fase.
- Teste de cena (como `teste_castelo_cena`): passar correndo por cima de uma peça
  de cano não gira; ficar parado gira; volta do castelo com alçapão aberto quando
  o progresso tem `laboratorio`.
- `--autoplay` de ponta a ponta: jardim → castelo → alçapão → laboratório (com um
  erro de propósito em cada sala) → festa → A → jardim com porta aberta → jardim
  de novo até a porta. `--fase=laboratorio` e `--sala=` funcionam no laboratório.

## Conteúdo novo

- Arte (SVG à mão): alçapão (fechado/aberto), escada, máquina (com 3 cabos e 3
  lâmpadas), baldes de tinta (4), frasco (branco, recebe cor), caldeirão, quadro
  de receitas, peças de cano (reta, curva), torneira, vaso + planta (pequena e
  gigante), botões de forma (4), tubos de vidro de enfeite.
- Sons: plop do caldeirão, borbulha/poção pronta, cano girando (clique suave),
  água correndo, planta crescendo, botão de forma (uma nota por forma), máquina
  ligando, música do laboratório (laço curioso e alegre, diferente do castelo).

## Fica para o construtor

Layout e coordenadas; desenho exato do quebra-cabeça de canos (dentro das
regras acima); tempos exatos (dwell, animações); sons e artes exatos; como
organizar a base "fase de salas" (contanto que o castelo não mude de comportamento).

## Calls do Claude (para o Tiago conferir)

- Ligação castelo → laboratório por alçapão na festa do castelo; o botão de jogar
  sai do castelo e vai pra festa do laboratório.
- Progresso guarda cada fase alcançada.
- Monstros: Poções = Frankenstein, Canos = Lobisomem, Formas = Drácula, Múmia
  perto da máquina.
- Quadro de receitas na parede como ajuda das cores.
- Girar cano = ficar parado em cima (passar não gira).
- Formas com lâmpadas acesas (reconhecer, não memorizar), 3 rodadas.
- Vaga-lume 12 s.
- Painel de lâmpadas dentro da sala das Formas (a máquina só repete).
- Alçapão num canto do salão, fora dos caminhos; com progresso, é atalho aberto.
