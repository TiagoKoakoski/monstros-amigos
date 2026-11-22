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
- Ajudou os quatro: festa com confete e dança. Qualquer botão do controle recomeça.

Sem inimigos, sem tempo, sem perder, sem sustos.

## Teste com a criança (o que observar)

Isso nenhum teste automático mede:
0. **O Godot reconhece o controle?** Não havia controle conectado na hora dos
   testes. Ligue o controle, rode `./jogar.sh` e veja se o analógico anda. Se não
   andar, rode `godot --path . -- --autoplay` e veja a linha "controles conectados".
1. Ele entende o balão como "o que o monstro quer"?
2. Ele percebe o vaga-lume e segue?
3. Fica preso em algum lugar, ou se frustra em algum momento?
4. O volume e o ritmo estão confortáveis?

## Verificação

```bash
godot --headless --path . --script res://tests/teste_missao.gd       # regras (28 verificações)
godot --headless --path . --script res://tests/teste_controle_real.gd # controle 0 e 1 + teclado (17)
godot --path . -- --autoplay --capturas=/tmp/fotos                     # joga a partida sozinho e fotografa
```

O modo `--autoplay` usa o mesmo movimento do jogador, espera o vaga-lume
aparecer, leva um item de propósito pro monstro errado, ajuda os quatro e
confere a festa, aperta o botão A (pelo caminho de um controle de verdade) e
confere que o jogo recomeça limpo. Avisa se travar em algum obstáculo. Sai com
código 0 se tudo deu certo.

## Estrutura

- `scripts/estado_missao.gd` — regras puras (quem quer o quê), testadas sem cena.
- `scripts/main.gd` — monta o jardim e conduz a partida; também o modo automático.
- `scripts/jogador.gd`, `monstro.gd`, `item_perdido.gd`, `guia.gd`, `visual.gd`.
- `scripts/controles.gd` — mapa de controles (autoload), zona morta 0,25.
- `arte/*.svg` — toda a arte, desenhada à mão em SVG (sem imagem de terceiros).
- `sons/*.wav` — sintetizados por `ferramentas/gerar_sons.py` (sem áudio de terceiros).

## Próximos passos possíveis

- **Voz dos monstros** em português (VoiceStudio local, voz de banco — nunca
  clonar voz de pessoa real), pra ele ouvir o que cada um quer.
- Mais fases ou mais monstros depois de ver como ele joga esta.
