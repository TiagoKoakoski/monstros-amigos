# Monstros Amigos

Jogo de explorar e ajudar monstros clássicos fofos, feito para uma criança de
5 anos que está aprendendo a jogar — com controle, na TV. Godot 4.7.

## Como jogar

- **Jogar na TV:** `./jogar.sh` (tela cheia). **Esc no teclado** fecha o jogo —
  de propósito, não existe "sair" no controle.
- **Andar:** analógico esquerdo ou setas do controle (teclado: setas/WASD).
- **Pegar e entregar:** é só encostar. Nenhum botão é obrigatório.
- Drácula perdeu o **morceguinho de pelúcia**, Frankenstein quer uma **flor**,
  a Múmia perdeu o **rolo de faixa** e o Lobisomem perdeu a **bola**. O balão
  em cima de cada um mostra o desenho do que ele quer — nada pra ler.
- Carrega uma coisa por vez. Levar pro monstro errado não tira nada: o balão
  dele balança lembrando o que ele quer.
- Ficou 5 segundos sem conseguir? Um **vaga-lume** aparece e voa até o próximo objetivo.
- Ajudou os quatro: festa com confete e dança, e **a porta do castelo se abre**.
  Os monstros entram e o vaga-lume mostra a porta.

Sem inimigos, sem tempo, sem perder, sem sustos.

## Fase 2 — dentro do castelo

Mais comprida e mais desafiadora (cerca de 8 a 12 minutos pra uma criança).
Um salão no meio e salas em volta, cada uma com uma brincadeira:

| Sala | O que fazer | Ganha |
|---|---|---|
| **Cozinha** (Frankenstein) | levar 3 ingredientes do bolo (ovo, morango, leite), um por vez | chave azul |
| **Música** (Drácula) | o órgão acende ladrilhos coloridos; repetir pisando neles. 3 rodadas (2, 3, 4 notas). Errou? Ele só toca de novo | chave vermelha |
| **Biblioteca** (Múmia, porta azul) | sala em penumbra: acender as 5 velas encostando; aparece o livro de figuras dela pra levar | — |
| **Corredor das caixas** (porta vermelha) | empurrar as 2 caixas até as marcas brilhando | abre o quarto |
| **Quarto** (Lobisomem) | pegar os 3 filhotinhos que fugiram (eles seguem em fila) e levar pra cama | festa! |

- **Chaves** vão pro cantinho de cima da tela (não ocupam a mão). A porta da mesma
  cor brilha; é só encostar. Porta trancada sem a chave só balança a fechadura.
- **Caixas nunca travam**: elas não chegam perto das paredes (sempre dá pra dar a
  volta e empurrar do outro lado). Se mesmo assim uma ficar parada muito tempo,
  ela some com um brilho e volta pro começo.
- Vaga-lume no castelo espera **9 s** (no jardim, 5 s).
- Festa no salão com todo mundo; qualquer botão volta pro jardim.
- **Progresso**: depois que ele entrou no castelo uma vez, nas próximas partidas
  a porta do castelo já começa aberta (dá pra ir direto). Pra zerar:
  `rm ~/.local/share/godot/app_userdata/Monstros\ Amigos/progresso.cfg`

## Teste com a criança (o que observar)

Isso nenhum teste automático mede:
0. **O Godot reconhece o controle?** Não havia controle conectado na hora dos
   testes. Ligue o controle, rode `./jogar.sh` e veja se o analógico anda. Se não
   andar, rode `godot --path . -- --autoplay` e veja a linha "controles conectados".
1. Ele entende o balão como "o que o monstro quer"?
2. Ele percebe o vaga-lume e segue?
3. Fica preso em algum lugar, ou se frustra em algum momento?
4. O volume e o ritmo estão confortáveis?

No castelo:
5. Ele entende que a chave colorida abre a porta da mesma cor?
6. Consegue repetir a música? Quantas vezes erra antes de pegar o jeito?
7. Acha as velas na penumbra? A penumbra incomoda ou assusta?
8. Entende empurrar a caixa (e dar a volta nela)?
9. Consegue pegar os filhotes? Quanto tempo leva o castelo inteiro?

## Verificação

```bash
godot --headless --path . --script res://tests/teste_missao.gd       # regras do jardim (28 verificações)
godot --headless --path . --script res://tests/teste_castelo.gd      # regras do castelo (68)
godot --headless --path . res://tests/teste_castelo_cena.tscn         # castelo montado: casos de controle real (6)
godot --headless --path . --script res://tests/teste_controle_real.gd # controle 0 e 1 + teclado (17)
godot --path . -- --autoplay --capturas=/tmp/fotos                     # joga o jogo inteiro sozinho e fotografa
godot --path . -- --fase=castelo --autoplay                            # começa direto no castelo
godot --path . -- --fase=castelo --autoplay --sala=caixas              # testa uma sala só (as anteriores dadas por feitas)
```

Opções de teste: `--manter-progresso` (não apaga o progresso de teste), `--depurar`
(imprime posições do piloto). O modo automático usa um progresso **separado**
(`progresso_teste.cfg`), nunca o da criança.

O modo `--autoplay` usa o mesmo movimento do jogador. No jardim: espera o
vaga-lume, leva um item pro monstro errado de propósito, ajuda os quatro e entra
pela porta. No castelo: espera o vaga-lume, encosta na porta trancada, faz a
cozinha, erra uma nota de propósito, acende as velas, empurra uma caixa contra a
borda e passa por trás dela, encaixa as caixas, leva os filhotes pra cama, vê a
festa, aperta o botão A (pelo caminho de um controle de verdade), confere que o
jardim voltou limpo **com a porta aberta**, e joga o jardim de novo até a porta.
Avisa se travar em algum obstáculo. Sai com código 0 se tudo deu certo.

## Estrutura

- `scripts/fase.gd` — base comum das fases: criança, câmera, vaga-lume, sons, festa, modo automático.
- `scripts/jogo.gd` — autoload `Jogo`: troca de fase com fade e progresso salvo.
- `scripts/jardim.gd` — fase 1. `scripts/castelo/castelo.gd` — fase 2 (salão, portas, chaves).
- `scripts/castelo/*.gd` — uma sala por arquivo (`cozinha`, `musica`, `biblioteca`,
  `corredor_caixas`, `quarto`) + peças (`porta`, `chaveiro`, `ladrilho`, `vela`, `caixa`, `filhote`).
- `scripts/estado_missao.gd`, `scripts/regras/*.gd` — regras puras, testadas sem cena.
- `scripts/jogador.gd`, `monstro.gd`, `item_perdido.gd`, `guia.gd`, `visual.gd`.
- `scripts/controles.gd` — mapa de controles (autoload), zona morta 0,25.
- `arte/*.svg` — toda a arte, desenhada à mão em SVG (sem imagem de terceiros).
- `sons/*.wav` — sintetizados por `ferramentas/gerar_sons.py` (sem áudio de terceiros).

## Próximos passos possíveis

- **Voz dos monstros** em português (VoiceStudio local, voz de banco — nunca
  clonar voz de pessoa real), pra ele ouvir o que cada um quer.
- Mais fases ou mais monstros depois de ver como ele joga o castelo.
- Design e plano do castelo: `docs/superpowers/specs/` e `docs/superpowers/plans/`.
