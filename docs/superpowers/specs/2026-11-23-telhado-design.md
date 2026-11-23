# Monstros Amigos — Fase 5: Telhado das estrelas

Data: 2026-11-23. Status: design (o Tiago autorizou o processo completo sem
perguntas; as decisões dele estão marcadas como dele, o resto está em "Calls do
Claude").

## Intenção e o porquê

Mesma criança (5 anos, TV com controle). Ordem combinada com o Tiago:
laboratório → cemitério → **telhado** (dois jogadores por último). Ele pediu
**progressão** (cada fase um pouco mais difícil) e descreveu o telhado assim:
topo da torre, a escada da torre na praça do cemitério leva até lá; **noite
calma pra antes de dormir**; pegar **estrelas cadentes**; **ligar estrelas na
ordem pra formar desenhos no céu** (gato, morcego); **festa grande no céu pra
fechar o jogo**.

Sucesso: é a fase mais calma e mais bonita do jogo (pode ser a última coisa
antes de dormir), um pouco mais difícil que o cemitério porque junta habilidades
(seguir uma ordem, empurrar com jeito, juntar e levar coisas que se mexem), e
termina numa festa que reúne todo mundo do jogo. Ele nunca fica preso, nunca
leva susto.

## Princípios (valem desde o jardim)

Nada pra ler; nada pra perder (erro nunca tira progresso); zero susto; tudo
encostando; vaga-lume quando ele fica sem avanço (coisas infinitas — pegar de
novo e de novo — não contam como avanço); Esc só no teclado; arte SVG à mão;
sons sintetizados por `ferramentas/gerar_sons.py`. Coisas acionáveis nunca em
fila no caminho umas das outras; acionar na chegada (com folga pra sair e
voltar); "ficar parado" medido pelo ponto onde parou; bases de colisão mais
estreitas que o raio de encostar; teste de cena com velocidade realista
(lições do castelo, laboratório e cemitério).

## Objetivos

1. Fase do telhado sobre a base `FaseDeSalas`: um **terraço** no meio e 4
   telhadinhos em volta, cada um com uma brincadeira nova.
2. Passagem cemitério → telhado pela **escada da torre** (já desenhada na praça
   do cemitério) que acende na festa do cemitério.
3. Progresso `telhado`: com ele, a escada da torre já começa acesa (atalho).
4. A festa do telhado fecha o jogo: botão de jogar → jardim.

## Não-objetivos

- Dois jogadores (próxima etapa).
- Mudar jardim, castelo e laboratório. O cemitério só muda na festa (e a escada
  vira passagem de verdade).

## Anti-objetivos

- Qualquer coisa assustadora ou agitada: nada de escuro de verdade (céu azul
  profundo com lua grande e muitas estrelas), nada de altura assustadora (o
  telhado tem muretas; nada de cair), nada que corra atrás da criança.
- Brincadeira que dependa de reflexo rápido ou de memória longa (o castelo já
  tem a de memória; aqui não repete).
- Estado travado que exija reiniciar (bola presa no canto, ovelha presa).

## Abordagem

Consideradas:

1. **Estender `FaseDeSalas`** (como laboratório e cemitério): telhadinhos =
   salas, muretas = paredes, pontezinhas = vãos com portão de chave. Rota,
   portas, chaveiro, piloto por sala e `--sala=` vêm de graça.
2. Fase aberta (sem salas, como o jardim), brincadeiras soltas no telhado. Mais
   "céu aberto", mas perde a progressão por chaves que ele já conhece e
   duplicaria rota e piloto.
3. Fase em sequência linear (uma brincadeira depois da outra, sem mapa). Mais
   simples, mas quebra o padrão de explorar das fases 2–4.

Escolhida a 1 (call do Claude): é o padrão que ele já domina, e o "mais
difícil" vem das brincadeiras, não de uma navegação nova.

## Fluxo

1. Festa do cemitério muda: sem botão de jogar; uns 5 s depois da dança a
   **escada da torre acende** (brilho + som), o Fantasmão flutua até ela, o
   vaga-lume aponta (saindo antes da área onde a criança estiver).
2. Encostar no pé da escada → fade → telhado (chega no terraço saindo de um
   alçapãozinho no chão).
3. Telhado: 4 brincadeiras com chaves → **festa no céu** → botão de jogar →
   jardim.

## O telhado

Noite calma: telhas azul-acinzentadas, muretas de pedra clara, céu azul
profundo com uma **lua grande** sorridente e estrelas piscando no fundo,
lanterninhas de papel penduradas, chaminés. Música: **canção de ninar**
(caixinha de música lenta). Vaga-lume espera **14 s**.

```
                 [Constelações]
                 (Gato astrônomo)
                       │ portão azul
 [Estrelas]═════[ TERRAÇO ]═════portão verde═════[Planetinhas]
 (Coruja,         (chegada)                       (Dona Lua)
  aberta)              │ portão laranja
                 [Ovelhinhas]
                 (Ovelhona)
```
Topologia decidida (é a mesma do cemitério, que já funciona com rota e piloto);
posições e tamanhos ficam pro construtor.

### Ordem e chaves

- **Estrelas** (aberta) → chave **azul**.
- **Constelações** (portão azul) → chave **verde**.
- **Planetinhas** (portão verde) → chave **laranja**.
- **Ovelhinhas** (portão laranja) → terminar = festa.

### 1. Estrelas cadentes (Coruja)

- A **Coruja** (personagem nova, de óculos redondos) tem um **pote** de
  estrelas; balão com **6 estrelas** (silhuetas que acendem).
- Estrelas caem devagar do céu em pontos sorteados da área (semente fixa no
  teste): primeiro aparece uma **sombra brilhante** no chão onde ela vai cair
  (~1,5 s), depois ela desce e fica no chão piscando. No máximo **3** estrelas
  esperando ao mesmo tempo; nunca caem em cima da Coruja nem perto de outra
  estrela esperando.
- Encostar numa estrela no chão = pegou: ela voa sozinha pro pote da Coruja
  (sem carregar nada), um ícone do balão acende. Nada se perde: estrela no chão
  espera pra sempre.
- Avanço = pegar uma estrela. 6 estrelas → termina.
- Vaga-lume: a estrela esperando mais perto da criança (ou onde a próxima vai
  cair).

### 2. Constelações (Gato astrônomo)

- O **Gato astrônomo** (personagem nova, com lunetinha) mostra no balão o
  desenho que vai ser formado.
- No chão da área há **estrelas grandes** formando o contorno de um desenho. A
  **próxima** estrela pisca grande e dourada; as outras ficam apagadas e
  pequenas. Encostar na próxima: ela acende, toca uma nota (subindo a escala) e
  um **risco de luz** liga a anterior a ela — a criança desenha andando.
- Encostar numa estrela que não é a próxima: só uma cintilada baixinha; nada
  se perde, nada volta.
- Fechou o desenho: as linhas brilham, o desenho **sobe pro céu** e fica lá
  como constelação (vai aparecer de novo na festa). Aparece o próximo.
- **3 desenhos, cada um com mais estrelas**: gato (6), morcego (7), peixe (8).
- Geometria: o caminho reto de uma estrela até a próxima nunca passa perto de
  outra estrela do mesmo desenho (nada em fila no caminho).
- Avanço = acender a próxima estrela. Tocar estrela errada não é avanço.
- Vaga-lume: a próxima estrela.

### 3. Planetinhas (Dona Lua)

- A **Dona Lua** (personagem nova, uma luazinha de touca de dormir) perdeu 3
  **planetinhas** (bolas: vermelho, azul, amarelo com anel) que rolaram pelo
  telhado. Os 3 **ninhos** (crateras redondas da mesma cor) ficam perto dela.
- Mecânica nova: **empurrar**. Encostar no planetinha empurra ele pra longe da
  criança (na direção dela → bola); ele rola e vai parando; bate nas bordas e
  volta (quica). Não dá pra carregar.
- Planetinha que passa perto do ninho da **mesma cor** cai nele (encaixe +
  som) e fica. Passar por cima de ninho de outra cor: nada (segue rolando).
- Nunca trava: os planetinhas ficam sempre longe das muretas o bastante pra
  criança passar por trás deles (dá pra empurrar de qualquer lado, inclusive
  tirar do canto). Funciona com o analógico devagar (o empurrão não depende da
  velocidade da criança).
- Avanço = um planetinha no ninho. Empurrar não é avanço (é infinito). 3 →
  termina.
- Vaga-lume: o ponto "atrás" do planetinha que falta mais perto (do lado
  oposto ao ninho dele), de onde empurrar leva ele pro ninho.

### 4. Ovelhinhas de nuvem (Ovelhona)

- Hora de dormir: **4 ovelhinhas de nuvem** passeiam devagar pelo telhado. A
  **Ovelhona** (personagem nova, de nuvem, com touca) espera no **cercadinho**
  (curral com uma porteira aberta).
- Ovelhinha passeia andando devagar entre pontos sorteados (sempre mais devagar
  que a criança, ~30% da velocidade dela). Na **primeira** vez que a criança
  chega perto, ela dá **um pulinho brincalhão** pra longe (uma vez só por
  ovelhinha; depois deixa pegar). Ela nunca foge de novo.
- Encostar = ela boceja e passa a **seguir a criança em fila** (como os
  fantasminhas). Chegar na porteira do cercadinho com ovelhinhas seguindo: cada
  uma **pula a cerquinha** (uma de cada vez, com um "boing" e uma nota da
  canção de ninar, contando) e deita pra dormir (zzz). Pode entregar aos
  poucos.
- Avanço = pegar uma ovelhinha, entregar. 4 → termina.
- Vaga-lume: a ovelhinha solta mais perto; se todas estão seguindo, a porteira.

### Festa no céu (fecha o jogo)

- No terraço: Coruja, Gato astrônomo, Dona Lua, Ovelhona, as 4 ovelhinhas e
  também **os amigos das outras fases** (Drácula, Frankenstein, Múmia,
  Lobisomem, Fantasma mamãe, Fantasmão) aparecem e dançam juntos.
- As 3 constelações acendem no céu, **fogos de estrelinha** (partículas
  coloridas suaves, sem estouro alto), a lua grande sorri, confete.
- Botão de jogar → jardim.

## Mudança no cemitério

- Festa: sem botão de jogar; a escada da torre acende ~5 s depois da dança; o
  Fantasmão flutua até ela; vaga-lume aponta (saindo antes da área onde a
  criança estiver, como a porta dos fundos do laboratório).
- Com `telhado` no progresso a escada já começa acesa (atalho).
- A escada deixa de ficar desenhada por cima da criança (ordem de desenho
  certa: ela entra na ordem por altura do mundo).
- A conferência do autoplay do cemitério roda ao subir a escada.

## Testes e verificação

- Todos os testes atuais continuam passando (o do cemitério ajustado pro fim
  novo da festa).
- Regras puras novas: estrelas (sorteio determinístico pela semente, nunca
  perto da Coruja nem de outra esperando, no máximo 3 esperando, 6 pegas →
  fim); constelações (só a próxima conta, errada não muda nada, 3 desenhos
  crescentes, nenhum segmento passa perto de outra estrela); rolagem dos
  planetinhas (empurrão, desacelera até parar, quica e nunca sai dos limites,
  encaixa só no ninho da mesma cor); ovelhinhas (pulinho uma vez só, seguir,
  entregar aos poucos, fim com 4); progresso `telhado`.
- Teste de cena: escada da torre do cemitério apagada sem progresso / acesa
  com; planetinha num canto pode ser tirado de lá; empurrar planetinha não cala
  o vaga-lume; estrela errada da constelação não é avanço; ovelhinha solta não
  sai da área; ovelhinha seguindo acompanha a criança pelo portão.
- `--autoplay` de ponta a ponta: jardim → castelo → laboratório → cemitério →
  escada → telhado (com um erro de propósito: estrela errada na constelação e
  portão trancado; ninho de outra cor fica num teste de cena) → festa no céu →
  A → jardim. `--fase=telhado` e `--sala=` funcionam.

## Conteúdo novo

- Arte: alçapãozinho de chegada, escada da torre acesa, telha/mureta (blocos),
  chaminé, lanterninha de papel, lua grande de fundo, Coruja, pote de estrelas,
  estrela (pequena/grande), sombra de queda, Gato astrônomo, ícones de desenho
  (gato/morcego/peixe), Dona Lua, planetinha (3 cores), ninho, Ovelhona,
  ovelhinha, cercadinho com porteira.
- Sons: estrela (pegar, plim), queda (whoosh suave), nota da constelação
  (escala), constelação pronta, rolar, encaixe (já existe), ovelhinha (méé
  fofo), boing (pular a cerca), música do telhado (canção de ninar), fogos de
  estrelinha.

## Fica para o construtor

Layout e coordenadas; desenho exato das constelações (dentro das regras);
posições de ninhos e pontos de queda; tempos, velocidades e atrito exatos
(dentro dos limites acima); arte e sons exatos.

## Calls do Claude (para o Tiago conferir)

- 4 brincadeiras: estrelas cadentes e constelações (pedidas por ele) +
  **planetinhas** (empurrar, mecânica nova) + **ovelhinhas de nuvem** (contar
  carneirinhos, tema de dormir). Memória de sequência ficou de fora porque o
  castelo já tem.
- Personagens novas: Coruja, Gato astrônomo, Dona Lua, Ovelhona (e as
  ovelhinhas).
- Constelações: gato, morcego e peixe (6, 7 e 8 estrelas) — a dificuldade cresce
  dentro da própria brincadeira.
- Estrelas cadentes sem carregar: a estrela voa sozinha pro pote (é a primeira,
  aberta e fácil).
- Ovelhinha dá um pulinho pra longe só uma vez (brincadeira, não fuga).
- Mesma topologia do cemitério (terraço + 4 telhadinhos); chaves azul, verde e
  laranja.
- Escada da torre como passagem; botão de jogar passa pra festa do telhado.
- Festa no céu com os amigos de todas as fases e as constelações.
- Progresso `telhado` (e os anteriores) marcado ao chegar no telhado.
- Vaga-lume 14 s; música de caixinha de ninar.
- Ovelhinhas seguindo acompanham a criança pra qualquer lugar (atravessam
  portões como os fantasminhas, sem física); só entram no cercadinho pela
  porteira. Soltas (ainda não pegas) passeiam só dentro da área delas.
- O **céu** é uma camada fixa na tela, atrás de tudo (lua grande, estrelas
  piscando, e as constelações prontas aparecem nele, pequenas, no alto); o
  fundo do mapa fica transparente, então o céu aparece entre os telhadinhos,
  de qualquer área e na festa.
- **Ajuda na mira** dos planetinhas: se o empurrão sai até ~60° torto em
  relação ao ninho do planetinha, ele vai reto pro ninho; o ninho "puxa" o
  planetinha da cor dele de um pouco longe. Sem isso empurrar com jeito seria
  difícil demais pra 5 anos.
- Estrela cadente nunca cai perto da criança (ficar parado não pega estrela).
- Planetinhas não batem uns nos outros (passam por cima) e nem em
  personagens; planetinha no ninho certo fica lá pra sempre.
