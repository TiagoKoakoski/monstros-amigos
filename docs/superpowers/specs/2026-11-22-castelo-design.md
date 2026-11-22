# Monstros Amigos — Fase 2: dentro do castelo

Data: 2026-11-22. Status: design para aprovação.

## Intenção e o porquê

O jogo é para o filho de 5 anos do Tiago, jogando na TV com controle. Ele já
jogou a fase do jardim, **gostou e achou rápido**. O Tiago quer mais
dinâmicas e uma fase **dentro do castelo**, e topou que ela seja **mais
desafiadora**. Tiago aprovou todas as atividades propostas e pediu também
uma parte de **empurrar caixas** para poder passar.

Sucesso: ele joga o castelo inteiro com vontade, leva mais tempo que o
jardim (alvo ~8–12 min vs ~2–3 min), sente que superou algo, e nunca fica
preso nem frustrado ao ponto de largar.

## Princípios que continuam valendo (do jardim)

- Nada pra ler. Tudo comunicado por desenho, cor, som e animação.
- Nada pra perder: sem vida, sem tempo, sem game over. Erro nunca tira progresso.
- Zero susto: nada de escuro de verdade, barulho alto, coisa que pula na tela.
- Tudo acontece encostando. Nenhum botão é obrigatório para jogar.
- Vaga-lume guia quando ele fica um tempo sem progresso.
- Esc (só teclado) fecha; no controle não existe "sair".
- Arte em SVG feita à mão; sons sintetizados por `ferramentas/gerar_sons.py`.

## Objetivos

1. Fase do castelo com um salão central e 5 áreas, cada uma com uma dinâmica diferente.
2. Passagem jardim → castelo pela porta do castelo, depois da festa do jardim.
3. Mais desafio que o jardim: atividades em várias etapas, portas encadeadas
   por chaves, vaga-lume mais paciente.
4. Reorganizar o código para que cada fase seja uma cena e as peças comuns sejam
   compartilhadas (sem quebrar o jardim nem o teste automático).

## Não-objetivos

- Voz dos monstros (continua como próximo passo separado).
- Salvar no meio do castelo. Se o jogo fechar no meio, volta ao jardim
  (com a porta do castelo já aberta — ver Progresso).
- Mais de um jogador, menus, configurações.
- Fase 3. A arquitetura deve facilitar, mas não entra agora.

## Anti-objetivos (falhou mesmo que funcione)

- Uma sala que ele não consegue terminar sozinho (ou com o vaga-lume).
- Caixa presa sem saída / qualquer estado travado que exija reiniciar.
- Biblioteca que dê medo (preto total, sombras ameaçadoras).
- Filhotes rápidos demais a ponto de ele não conseguir alcançar.
- Regredir o jardim: ele tem que continuar exatamente como está hoje.

## Abordagens consideradas

1. **Cada fase vira uma cena; um maestro pequeno troca de fase; peças comuns
   compartilhadas** — escolhida. Mais trabalho agora (reorganizar o
   `main.gd`), mas cada atividade nova e cada fase futura encaixa sem duplicar.
2. Copiar `main.gd` e fazer o castelo em cima da cópia — rápido, mas toda
   correção vira duas, e com 5 dinâmicas novas vira bagunça. Descartada.
3. Fase descrita só por dados (dicionário/JSON) com motor genérico — exagero
   para duas fases com atividades muito diferentes entre si. Descartada.

## Fluxo do jogo

1. **Jardim** como hoje. Na festa, em vez do botão "jogar de novo", a **porta
   do castelo se abre** (animação + som) e o vaga-lume passa a apontar para ela.
   Os 4 monstros vão andando para dentro.
2. Encostar na porta → transição suave (fade) para o **castelo**.
3. **Castelo**: ajudar os 4 monstros nas suas salas (abaixo).
4. **Festa no salão** com todos os monstros e os filhotes dançando, confete.
   Depois aparece o botão de jogar (como hoje); qualquer botão recomeça **do jardim**.

### Progresso (decisão do Claude)

Depois que ele chega no castelo uma vez, isso fica salvo em
`user://progresso.cfg`. Da próxima vez que o jogo abrir, o jardim começa
normal, mas **a porta do castelo já está aberta** desde o início: ele pode
ajudar os monstros do jardim de novo ou ir direto pro castelo. Sem tela de
escolha, sem texto. (Se a porta estiver aberta, os monstros do jardim
continuam no jardim esperando ajuda, normalmente.)

Com a porta já aberta desde o início (decisões do Claude):
- Os mesmos 4 monstros estão no jardim e no castelo; pra uma criança de 5
  anos isso não é problema, e cada fase é independente.
- O vaga-lume do jardim continua apontando pros itens/monstros, como hoje:
  o jardim segue sendo o caminho guiado; a porta aberta é só um atalho.
- Se ele ajudar os 4 no jardim, a festa termina igual: monstros vão pra
  dentro e o vaga-lume aponta pra porta (que já estava aberta).

### Sem volta no meio (decisão do Claude)

Não dá pra voltar andando do castelo pro jardim no meio da partida: a porta
de entrada fecha atrás dele com um som suave (é decoração por dentro). Assim
cada fase é criada do zero quando começa e o maestro não precisa guardar
estado de sala nenhuma entre trocas. A única coisa que atravessa fases é o
progresso salvo (porta do castelo aberta).

Testes e `--autoplay` usam um arquivo de progresso separado (nunca o
`user://progresso.cfg` de verdade), pra não mexer na partida dele.

## O castelo

Vista de cima, mesmo estilo do jardim (luz quente, y-sort, câmera seguindo,
abertura mostrando o salão). Um mapa contínuo (sem carregar cena por sala),
com paredes e portas. Piso de pedra clara/tapetes, tochas e lustres quentes.

```
   [Música]      [Biblioteca]
  (Drácula)       (Múmia)
       \  porta   / porta AZUL
        [  SALÃO  ]────[Cozinha]
        [ central ]    (Frankenstein)
             |  porta VERMELHA
      [Corredor das caixas]
             |  porta que abre com as caixas
       [Quarto do Lobisomem]
```

**Entrada**: a criança entra pela porta principal, que dá direto no
**salão** (na parede oposta às salas, ou onde o layout permitir). A abertura
da fase mostra o salão. O quarto só tem uma porta, a que vem do corredor.

O layout exato (tamanhos, posições) fica para o construtor; a topologia
acima é a decisão.

### Ordem e chaves

- Abertas desde o início: **Cozinha** e **Música**.
- Terminar a Cozinha → Frankenstein dá a **chave azul** → abre a **Biblioteca**.
- Terminar a Música → Drácula dá a **chave vermelha** → abre o **Corredor das caixas**.
- Terminar as caixas → abre o **Quarto do Lobisomem**.
- As 4 salas terminadas (Cozinha, Música, Biblioteca, Quarto) → festa.

**Chaves não ocupam a mão** (decisão do Claude): ao ganhar, a chave voa até um
"chaveiro" no canto da tela (só ícone). A porta da mesma cor brilha; encostar
nela com a chave no chaveiro abre (a chave voa até a fechadura). Isso evita
conflito com ingrediente na mão. Portas trancadas sem a chave: encostar só
faz a fechadura balançar com um "hum" suave, mostrando a cor da chave que falta.

### 1. Cozinha do Frankenstein — receita do bolo

- Balão do Frankenstein mostra **3 ingredientes** (ex.: ovo, morango, leite).
- Os 3 estão espalhados pela cozinha (alguns atrás de mesa/fogão, para ter que contornar).
- Mesma regra do jardim: carrega um por vez, encostar no Frankenstein entrega.
- No balão, o ingrediente entregue fica marcado (ganha um coração/fica colorido;
  os que faltam ficam em silhueta). Entregar algo que não é da receita (não
  acontece nesta sala, mas a regra vale): balão balança, nada se perde.
- Os 3 entregues: aparece o bolo, Frankenstein comemora, dá a chave azul.

### 2. Sala de música do Drácula — repetir a sequência

- Um órgão e **4 ladrilhos grandes coloridos** no chão (vermelho, azul,
  amarelo, verde), cada um com sua nota (sino suave, notas de uma escala agradável).
- Drácula "toca": os ladrilhos acendem em sequência com a nota. Durante a
  demonstração, pisar não conta.
- Ele repete **pisando** nos ladrilhos (entrar no ladrilho = uma nota; para
  repetir a mesma cor, sair e entrar de novo — por isso a sequência nunca
  repete a mesma cor duas vezes seguidas).
- **3 rodadas**: 2 notas, depois 3, depois 4. Rodada completa → acorde alegre,
  Drácula dá uma voltinha. Rodada seguinte começa sozinha após uma pausa.
- **Erro**: som "hum" suave, Drácula toca **a mesma sequência de novo**. Nada
  volta para trás (não perde rodada já feita).
- Vaga-lume nesta sala: depois do tempo de espera, pousa no ladrilho certo seguinte.
- Fim: Drácula comemora e dá a chave vermelha.

### 3. Biblioteca da Múmia — acender as velas

- Sala em **penumbra azulada** (escurecida, nunca preta; os contornos dos
  móveis continuam visíveis). Em volta da criança, um círculo de luz quente
  da lanterna (ela já carrega uma lanterna no desenho).
- **5 velas** apagadas, cada uma com um brilho fraco pulsando para ser achada.
- Encostar numa vela acende (chama + som de "plim") e ilumina bem o
  entorno; a sala vai clareando conforme acende.
- Com as 5 acesas, a sala fica toda clara e aparece o que a Múmia perdeu:
  o **livro de figuras** dela (item novo). Pegar e levar até a Múmia (regra do jardim).
- Fim: Múmia comemora (sala termina).

### 4. Corredor das caixas — empurrar até as marcas

- Corredor largo com **2 caixas de madeira** e **2 marcas brilhando** no chão.
- Empurrar = andar contra a caixa; a caixa anda na direção do empurrão,
  um pouco mais devagar que a criança.
- Caixa que chega perto da marca **encaixa** sozinha (desliza pro centro,
  som de "toc", marca acende). Encaixada, ela não sai mais.
- As 2 encaixadas: a porta do quarto abre.
- **Nunca travar** (decisão do Claude, regra mais importante desta sala):
  - As caixas batem numa **borda invisível só delas**, afastada das paredes
    o suficiente para a criança passar por trás. Assim nenhuma caixa encosta
    em parede nem em canto: sempre dá para dar a volta e empurrar de outro lado.
  - A borda das caixas também mantém as caixas fora das portas.
  - Rede de segurança: se uma caixa ficar parada fora da marca, sem ser
    empurrada, por um tempo longo e com a criança sem progresso, ela some com
    um brilho e reaparece no ponto inicial.
- Vaga-lume nesta sala: aponta para a caixa que falta e, quando ele está
  encostado nela, para a marca.
- Disposição inicial pensada para exigir contornar pelo menos uma caixa (é o
  "desafio"), mas solucionável empurrando de forma óbvia.

### 5. Quarto do Lobisomem — levar os filhotes pra cama

- **3 filhotinhos de lobo** fofos andando devagar pelo quarto.
- Quando a criança chega perto, o filhote dá uma "fugidinha" curta e
  brincalhona (pulinho), mais devagar que a criança, e nunca foge para dentro
  de canto (fuga desvia de paredes). Desafio pequeno, alcance garantido.
- Encostar → o filhote **segue a criança em fila** (como patinhos). Pode
  juntar vários de uma vez.
- Levar até a **cama** grande do Lobisomem: filhotes que chegam lá deitam e dormem (Zzz desenhado).
- Os 3 na cama: Lobisomem comemora.

### Vaga-lume no castelo

- Espera **9 s** sem progresso (no jardim continua 5 s).
- Alvo: a próxima coisa útil — dentro de uma sala, o objetivo daquela sala
  (ingrediente/Frankenstein, próximo ladrilho, vela mais perto, caixa/marca,
  filhote mais perto/cama); fora das salas, a porta da sala disponível mais
  perto (ou a porta trancada cuja chave ele já tem).

## Arquitetura (decidido: abordagem 1)

- `scenes/jardim.tscn` e `scenes/castelo.tscn`; `main.tscn` deixa de ser a fase
  (ou vira o jardim) — o construtor escolhe a forma, mantendo `./jogar.sh` funcionando.
- **Autoload `Jogo`**: troca de fase com fade, guarda e lê o progresso
  (`user://progresso.cfg`).
- **Classe base de fase** com o que é comum: jogador, câmera e abertura, guia
  (com tempo de espera configurável), áudio, festa, interface (confete, botão),
  e o arcabouço do modo `--autoplay`/`--capturas`.
- **Classe base de atividade** (cada sala/corredor): sinal de concluída,
  `alvo()` para o vaga-lume, aviso de progresso. Fase do castelo só orquestra
  atividades, portas e chaves.
- **Lógica pura testável sem cena**, no espírito do `EstadoMissao`: receita,
  sequência de música, velas, caixas (encaixe), filhotes, portas/chaves e o
  progresso do castelo como um todo. `EstadoMissao` continua servindo o jardim.

## Testes e verificação

- Os testes atuais continuam passando (`teste_missao.gd`, `teste_controle_real.gd`).
- Testes novos de regra pura para cada estado novo (incluindo: erro na
  música não regride rodada; sequência nunca repete cor seguida; caixa
  encaixada não sai; chave certa abre só a porta da sua cor; progresso salvo).
- `--autoplay` passa a jogar **o jogo inteiro**: jardim → porta → castelo
  → as 4 salas e o corredor → festa → botão A → volta ao jardim limpo, com
  fotos de cada momento. Inclui de propósito: errar uma nota, encostar em
  porta trancada, empurrar caixa contra a borda. Avisa se travar.
- Teste do progresso: com progresso salvo, o jardim abre com a porta aberta.

## Conteúdo novo

- **Arte (SVG à mão)**: piso/paredes/portas do interior, porta do castelo
  aberta, chaves azul e vermelha, chaveiro, ingredientes (3), bolo, órgão,
  ladrilhos (4 cores), vela apagada/acesa, livro de figuras, estantes, caixa,
  marca, filhote, cama, tochas/lustre, Zzz.
- **Sons (sintetizados)**: 4 notas dos ladrilhos, acorde de rodada, porta
  abrindo, chave, fechadura "hum", vela, caixa encaixando, filhote (pio/latidinho
  fofo sintetizado), música do castelo (laço calmo, diferente da do jardim).
  Mesmas regras de hoje: ataque suave, pico ~ −10 dBFS.

## Fica para o construtor

- Layout e coordenadas do castelo, tamanhos das salas, posição das coisas.
- Desenho exato das artes e timbres dos sons, dentro das regras acima.
- Velocidades exatas (caixa, filhotes), raios de toque, tempo da rede de
  segurança das caixas — ajustar jogando com o autoplay.
- Ingredientes exatos da receita, notas exatas da música.
- Forma de organizar cenas/arquivos, desde que siga a arquitetura acima.

## Calls do Claude (para o Tiago conferir)

- Progresso salvo abre a porta do castelo no próximo jogo (sem menu).
- Chaves vão pro chaveiro, não ocupam a mão.
- Caixas com borda própria afastada das paredes + reaparecer se travar.
- Penumbra azulada (não escuro) na biblioteca, com luz da lanterna.
- Música com 3 rodadas (2, 3, 4 notas); erro repete a mesma sequência.
- Vaga-lume espera 9 s no castelo.
- Mesmos monstros no jardim e no castelo; vaga-lume do jardim segue os itens mesmo com a porta aberta.
- Sem voltar do castelo pro jardim no meio; testes usam arquivo de progresso separado.
- Ordem: Cozinha e Música livres; chave azul → Biblioteca; chave vermelha → caixas → Quarto.
