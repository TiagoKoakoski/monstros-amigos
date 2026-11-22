# Monstros Amigos — Fase 4: Cemitério das abóboras

Data: 2026-11-22. Status: design para aprovação.

## Intenção e o porquê

Mesma criança (5 anos, TV com controle). Sequência combinada com o Tiago:
laboratório → **cemitério** → telhado (dois jogadores por último). Ele pediu
**progressão** (cada fase um pouco mais difícil) e aprovou a proposta abaixo
("pode seguir com essa proposta"). O menino ainda não jogou o laboratório,
então não há retorno de dificuldade: seguimos a proposta como está.

Sucesso: o cemitério tem cara de "explorar" (área grande, coisas escondidas,
labirinto), com mais etapas que o laboratório, e ele termina sozinho ou com o
vaga-lume. Nunca fica preso, nunca leva susto.

## Princípios (valem desde o jardim)

Nada pra ler; nada pra perder (erro nunca tira progresso); zero susto; tudo
encostando; vaga-lume quando ele fica sem avanço (e coisas infinitas — pegar de
novo e de novo — não contam como avanço); Esc só no teclado; arte SVG à mão;
sons sintetizados por `ferramentas/gerar_sons.py`. Coisas pegáveis/acionáveis
nunca em fila no caminho umas das outras; "ficar parado" medido pelo ponto onde
parou (lições do castelo e do laboratório).

## Objetivos

1. Fase do cemitério sobre a base `FaseDeSalas`: uma praça no meio e 4 áreas
   cercadas por cerca viva, cada uma com uma brincadeira nova.
2. Passagem laboratório → cemitério por uma **porta dos fundos** que abre na
   festa do laboratório.
3. Progresso `cemiterio`: com ele, a porta dos fundos do laboratório já começa
   aberta (atalho).

## Não-objetivos

- Telhado (próxima fase) e dois jogadores.
- Mudar jardim e castelo. O laboratório só muda no fim da festa.

## Anti-objetivos

- Qualquer coisa assustadora: fantasmas são fofos, riem, nunca "atacam"; nada
  de escuro de verdade (noite clara, abóboras acesas, lanternas).
- Pega-pega impossível de ganhar ou que dependa de reflexo rápido.
- Labirinto onde ele se perde sem ajuda.
- Estado travado que exija reiniciar.

## Abordagem

Uma só faz sentido: estender `FaseDeSalas` (como o laboratório). O cemitério é
ao ar livre, mas "áreas cercadas por cerca viva com portões" é exatamente o
mapa de salas, vãos e portas com chave; as cercas são as paredes (verdes).
Copiar ou montar à parte duplicaria rota, portas, chaveiro e piloto.

## Fluxo

1. Festa do laboratório muda: depois da dança, a **porta dos fundos** da sala
   da máquina abre (som + brilho), a Múmia passa por ela, o vaga-lume aponta.
   O botão de jogar sai do laboratório e vai pra festa do cemitério.
2. Encostar na porta → fade → cemitério (chega na praça, saindo de uma
   portinha de porão).
3. Cemitério: 4 brincadeiras com chaves → **festa na praça** → botão de jogar →
   jardim. (Quando o telhado existir, a festa abre a escada da torre.)

## O cemitério

Noite fofa: grama azul-esverdeada clara, caminhos de terra, abóboras com
carinha acesa, lanternas, vaga-lumes de enfeite, lápides arredondadas com
desenhos (flor, coração, gato). Vaga-lume guia espera **14 s**.

```
                [Labirinto]
                (chave rosa no fim)
                     │ portão amarelo
 [Lápides]═══════[ PRAÇA ]═══portão roxo═══[Horta]
 (Fantasma mamãe,  (chegada)                (carroça)
  aberta)            │ portão rosa
                 [Arena do Fantasmão]
```
Topologia decidida; posições e tamanhos ficam pro construtor.

### Ordem e chaves

- **Lápides** (aberta) → chave **roxa**.
- **Horta** (portão roxo) → chave **amarela**.
- **Labirinto** (portão amarelo) → a chave **rosa** está no fim do labirinto.
- **Arena** (portão rosa) → terminar = festa.

### 1. Esconde-esconde dos fantasminhas (Lápides)

- **Fantasma mamãe** (personagem nova, fofa, com touquinha) perto da entrada da
  área; balão com 5 fantasminhas (silhuetas que ficam coloridas).
- ~10 esconderijos (lápides, abóboras grandes, arbustos) espalhados pela área;
  **5 fantasminhas** sorteados entre eles a cada partida (semente fixa no teste).
- Pistas: uma **risadinha** a cada ~3 s cujo volume cresce quanto mais perto
  ele está do fantasminha não achado mais próximo; e um **brilho** que espia
  de trás do esconderijo de vez em quando.
- Achar = encostar no esconderijo: o fantasminha pula pra fora rindo e passa a
  **seguir a criança em fila** (como os filhotes do castelo). Encostar na
  mamãe entrega todos os que estão seguindo (pode entregar aos poucos).
- Esconderijo vazio: nada acontece (no máximo um "hum" baixinho), nada se perde.
- Vaga-lume: o fantasminha não achado mais perto; se todos já foram achados,
  a mamãe.

### 2. Horta de abóboras

- 3 **canteiros**, um **saco de sementes** (nunca acaba), um **poço** (água
  nunca acaba) e a **carroça** — espaçados, nada no caminho de nada.
- Cada abóbora: pegar **semente** no saco → encostar num canteiro vazio
  (planta, aparece um brotinho) → encostar no **poço** com a mão vazia (pega o
  regador cheio) → encostar no canteiro plantado (rega; a abóbora cresce em
  ~2 s até ficar gigante) → encostar na abóbora pronta (pega) → levar na
  **carroça**. 3 abóboras.
- Mão = 1 coisa. Levar a coisa errada a um lugar (água em canteiro vazio,
  semente em canteiro plantado) = "hum", nada se perde.
- Avanço (pro vaga-lume) = plantar, regar, colher, entregar. Pegar semente ou
  água não conta.
- Vaga-lume: o próximo passo (com semente → canteiro vazio; com água →
  canteiro plantado; com abóbora → carroça; mão vazia → abóbora pronta, ou
  poço se há canteiro plantado, ou sementes).

### 3. Labirinto de cerca viva

- Grade pequena desenhada à mão (por volta de 5×4 células), com 2–3 becos sem
  saída; **pegadas brilhantes** fracas no chão marcando o caminho certo (é a
  ajuda visual; brilham mais perto dele).
- No fim, a **chave rosa** flutuando: encostar pega a chave (vai pro chaveiro).
- Vaga-lume no labirinto segue os corredores (nunca aponta através da cerca):
  dentro do labirinto, a próxima célula do caminho até o objetivo (a chave ou,
  depois, a saída).
- A rota do vaga-lume pra sair do labirinto (indo pra outra área) também segue
  os corredores.

### 4. Pega-pega com o Fantasmão (Arena)

- **Fantasmão**: um fantasma gigante bonachão. Ao chegar perto, ele foge rindo,
  **mais devagar que a criança**, e **cansa**: a velocidade cai com o tempo de
  perseguição; nos cantos ele escorrega pela borda (dá pra encurralar).
- Encostar nele = "peguei!": ele ri, gira e fica parado ~1,5 s; depois foge de
  novo descansado. **3 pegadas** → ele se rende feliz.
- Funciona com analógico devagar: a velocidade dele nunca passa de ~60% da
  velocidade máxima da criança e cai até ~25%.
- Vaga-lume: o Fantasmão.

### Festa

Fantasma mamãe com os 5 fantasminhas, Fantasmão e as abóboras gigantes na
praça; confete; botão de jogar → jardim.

## Mudança no laboratório

- Festa: sem botão de jogar; a porta dos fundos (parede de cima da sala da
  máquina, longe dos caminhos e da escada) abre ~5 s depois da dança; a Múmia
  entra nela; vaga-lume aponta (saindo antes da sala onde a criança estiver).
- Com `cemiterio` no progresso a porta já começa aberta (atalho).
- A conferência do autoplay do laboratório roda ao entrar na porta (como o
  castelo no alçapão).

## Testes e verificação

- Todos os testes atuais continuam passando.
- Regras puras novas: esconde-esconde (sorteio de 5 entre os esconderijos,
  distintos, determinístico pela semente; achar/seguir/entregar; achar
  esconderijo vazio não muda nada); horta (cada passo, erros não perdem nada,
  3 abóboras → fim; pegar semente/água não é avanço); labirinto (caminho existe,
  há becos, próximo passo nunca atravessa parede, de qualquer célula); progresso
  `cemiterio`.
- Teste de cena: porta dos fundos do laboratório fechada sem progresso / aberta
  com; Fantasmão fica dentro da arena e cansa (velocidade cai); pegar o
  Fantasmão conta uma vez por encostada; vaga-lume no labirinto aponta pra uma
  célula vizinha alcançável; laço de pegar semente/água não cala o vaga-lume.
- `--autoplay` de ponta a ponta: jardim → castelo → laboratório → porta dos
  fundos → cemitério (com um erro de propósito: esconderijo vazio, "hum" na
  horta, um beco no labirinto) → festa → A → jardim. `--fase=cemiterio` e
  `--sala=` funcionam.

## Conteúdo novo

- Arte: porta dos fundos (aberta/fechada), portinha de chegada, cerca viva
  (blocos), portão (usa a Porta com cor), lápides (3 desenhos), abóbora grande
  de esconderijo, arbusto, lanterna, Fantasma mamãe, fantasminha, Fantasmão,
  saco de sementes, semente, brotinho, poço, regador, abóbora gigante, carroça,
  pegada, chave (já existe).
- Sons: risadinha (fantasminha), "achei" (pulo pra fora), plantar, regar (água),
  crescer, carroça (entrega), "peguei" do Fantasmão, porta dos fundos (pode
  reusar `porta`), música do cemitério (valsinha noturna, calma e alegre).

## Fica para o construtor

Layout e coordenadas; desenho exato do labirinto (dentro das regras); posições
dos esconderijos; tempos e velocidades exatas (dentro dos limites acima); arte e
sons exatos.

## Calls do Claude (para o Tiago conferir)

- Personagem nova: Fantasma mamãe (dona dos fantasminhas) e o Fantasmão.
- Esconderijos sorteados a cada partida (rejogar fica diferente).
- Pegadas brilhantes no labirinto como ajuda visual (sem elas seria difícil
  demais pra 5 anos).
- Fantasmão sempre mais lento que a criança e cansando (ninguém perde no pega-pega).
- Vaga-lume 14 s.
- Porta dos fundos do laboratório como passagem; botão de jogar passa pra festa
  do cemitério.
- Progresso `cemiterio` (e os anteriores) marcado ao chegar no cemitério.
- Lápides termina quando os 5 fantasminhas foram entregues; o Labirinto termina
  ao pegar a chave rosa (a chave voa da própria posição pro chaveiro).
- Chaves novas: roxa, amarela e rosa (entram na lista de cores de chave).
