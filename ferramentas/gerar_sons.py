#!/usr/bin/env python3
"""
Sintetiza os sons do Monstros Amigos (nada de áudio de terceiros).

Regras pra criança pequena: ataque sempre suave (nunca um "clique" seco),
volume moderado (pico ~ -10 dBFS) e timbres de sino/caixinha de música.
As músicas são laços sem emenda: a cauda das notas que passa do fim volta
pro começo do arquivo.

Uso: python3 ferramentas/gerar_sons.py sons/
"""
import sys
import wave
from pathlib import Path

import numpy as np

SR = 44100
PICO = 0.32  # ~ -10 dBFS


def freq(nota: str) -> float:
    nomes = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3,
             "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    nome, oitava = nota[:-1], int(nota[-1])
    return 440.0 * 2 ** ((nomes[nome] + 12 * (oitava - 4)) / 12)


def sino(f: float, dur: float, decai: float = 4.0, brilho: float = 0.35) -> np.ndarray:
    t = np.arange(int(SR * dur)) / SR
    onda = np.sin(2 * np.pi * f * t) + brilho * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * decai * 1.5)
    onda += 0.12 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t * decai * 2.5)
    ataque = np.clip(t / 0.012, 0, 1)  # 12 ms: suave, sem clique
    return onda * ataque * np.exp(-t * decai)


def normaliza(x: np.ndarray, pico: float = PICO) -> np.ndarray:
    return x / (np.abs(x).max() + 1e-9) * pico


def salvar(x: np.ndarray, caminho: Path) -> None:
    dados = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(caminho), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(dados.tobytes())
    print(f"gerado: {caminho} ({len(x) / SR:.2f}s)")


def sequencia(notas, passo: float, total: float, decai: float = 5.0) -> np.ndarray:
    buf = np.zeros(int(SR * total))
    for i, n in enumerate(notas):
        s = sino(freq(n), 0.9, decai)
        ini = int(i * passo * SR)
        fim = min(len(buf), ini + len(s))
        buf[ini:fim] += s[: fim - ini]
    return buf


def laco(eventos, total_s: float) -> np.ndarray:
    """eventos: (inicio_s, nota, dur_s, volume, decai). Cauda volta pro início."""
    n = int(SR * total_s)
    buf = np.zeros(n)
    for ini, nota, dur, vol, decai in eventos:
        s = sino(freq(nota), dur, decai) * vol
        idx = (int(ini * SR) + np.arange(len(s))) % n
        np.add.at(buf, idx, s)
    return buf


def palma(total_s: float, batidas_s) -> np.ndarray:
    n = int(SR * total_s)
    buf = np.zeros(n)
    rng = np.random.default_rng(7)
    for b in batidas_s:
        d = int(0.08 * SR)
        t = np.arange(d) / SR
        ruido = rng.standard_normal(d)
        ruido = np.convolve(ruido, np.ones(6) / 6, mode="same")  # tira o chiado agudo
        s = ruido * np.clip(t / 0.004, 0, 1) * np.exp(-t * 45) * 0.18
        idx = (int(b * SR) + np.arange(d)) % n
        np.add.at(buf, idx, s)
    return buf


def main() -> None:
    saida = Path(sys.argv[1])
    saida.mkdir(parents=True, exist_ok=True)

    salvar(normaliza(sequencia(["G5", "C6"], 0.11, 0.7, decai=6)), saida / "pegar.wav")
    entrega = sequencia(["C5", "E5", "G5", "C6"], 0.11, 1.6, decai=4.5)
    t = np.arange(len(entrega)) / SR
    acorde = sum(sino(freq(n), 1.6, 2.8) for n in ["C5", "E5", "G5", "C6"]) * 0.45
    entrega += np.where(t >= 0.44, np.roll(acorde, int(0.44 * SR)), 0)
    salvar(normaliza(entrega), saida / "entregar.wav")
    salvar(normaliza(sequencia(["E5", "C5"], 0.16, 0.6, decai=7), PICO * 0.7), saida / "hum.wav")
    salvar(normaliza(sequencia(["C6", "E6", "G6", "C7"], 0.06, 0.6, decai=9), PICO * 0.55), saida / "brilho.wav")

    # Caixinha de música da noite: 8 compassos, 84 bpm, Dó maior.
    bpm = 84
    seminima = 60 / bpm
    melodia = ["C5", "E5", "G5", "E5", "F5", "A5", "G5", None, "E5", "G5", "C6", "G5", "A5", "G5", "E5", None,
               "D5", "F5", "A5", "F5", "G5", "E5", "C5", None, "D5", "E5", "F5", "D5", "C5", None, None, None]
    baixo = ["C3", "F3", "C3", "F3", "D3", "C3", "G3", "C3"]
    ev = [(i * seminima, n, 1.6, 1.0, 3.2) for i, n in enumerate(melodia) if n]
    ev += [(c * 4 * seminima, b, 2.8, 0.55, 1.6) for c, b in enumerate(baixo)]
    ev += [(c * 4 * seminima + 2 * seminima, b.replace("3", "4"), 1.5, 0.25, 2.4) for c, b in enumerate(baixo)]
    salvar(normaliza(laco(ev, 32 * seminima), PICO * 0.75), saida / "musica_noite.wav")

    # Festa: 8 compassos, 120 bpm, colcheias saltitantes + palmas suaves.
    bpm = 120
    colcheia = 60 / bpm / 2
    frases = [["C5", "E5", "G5", "E5", "C6", "G5", "E5", "G5"], ["F5", "A5", "C6", "A5", "F5", "A5", "C6", "A5"],
              ["G5", "B5", "D6", "B5", "G5", "B5", "D6", "B5"], ["C6", "G5", "E5", "G5", "C6", None, "C6", None]]
    mel = [n for f in frases + frases for n in f]
    raizes = ["C3", "F3", "G3", "C3"] * 2
    ev = [(i * colcheia, n, 0.8, 0.9, 6.0) for i, n in enumerate(mel) if n]
    for c, r in enumerate(raizes):
        quinta = {"C3": "G3", "F3": "C4", "G3": "D4"}[r]
        for b, nota in enumerate([r, quinta, r, quinta]):
            ev.append((c * 8 * colcheia + b * 2 * colcheia, nota, 0.6, 0.6, 5.0))
    total = 64 * colcheia
    musica = laco(ev, total)
    musica = normaliza(musica, PICO * 0.8) + palma(total, [c * 8 * colcheia + k * 2 * colcheia for c in range(8) for k in (1, 3)])
    salvar(normaliza(musica, PICO * 0.85), saida / "musica_festa.wav")


if __name__ == "__main__":
    main()
