#!/usr/bin/env bash
# Abre o Monstros Amigos em tela cheia (pra jogar na TV com o controle).
# Esc no teclado fecha o jogo — de propósito, não existe "sair" no controle.
cd "$(dirname "$0")" && exec godot --path . --fullscreen
