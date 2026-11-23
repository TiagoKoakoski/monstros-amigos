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

    castelo(saida)
    laboratorio(saida)
    cemiterio(saida)
    telhado(saida)


def ruido_madeira(dur: float, semente: int = 3) -> np.ndarray:
    """Batida abafada de madeira: ruído filtrado com ataque suave."""
    n = int(SR * dur)
    t = np.arange(n) / SR
    rng = np.random.default_rng(semente)
    r = np.convolve(rng.standard_normal(n), np.ones(40) / 40, mode="same")
    return r * np.clip(t / 0.012, 0, 1) * np.exp(-t * 30)


def castelo(saida: Path) -> None:
    """Sons da fase 2 (dentro do castelo)."""
    # notas dos ladrilhos: vermelho, azul, amarelo, verde (pentatônica, sem dissonância)
    for i, nota in enumerate(["C5", "D5", "E5", "G5"]):
        salvar(normaliza(sino(freq(nota), 0.9, 3.5), PICO * 0.85), saida / f"nota_{i}.wav")
    salvar(normaliza(sequencia(["C5", "E5", "G5", "C6", "E6"], 0.08, 1.2, decai=4)), saida / "rodada.wav")

    # porta abrindo: sino grave descendo + arrasto suave
    porta = sequencia(["G4", "E4", "C4"], 0.18, 1.2, decai=3.5)
    t = np.arange(len(porta)) / SR
    rng = np.random.default_rng(5)
    arrasto = np.convolve(rng.standard_normal(len(porta)), np.ones(120) / 120, mode="same")
    arrasto *= np.clip(t / 0.15, 0, 1) * np.exp(-t * 3.5) * 1.6
    salvar(normaliza(porta + arrasto, PICO * 0.8), saida / "porta.wav")

    salvar(normaliza(sequencia(["E6", "G6", "E6", "C7"], 0.05, 0.7, decai=8), PICO * 0.6), saida / "chave.wav")
    salvar(normaliza(sequencia(["C4", "C4"], 0.14, 0.5, decai=9), PICO * 0.6), saida / "fechadura.wav")
    salvar(normaliza(sequencia(["G5", "D6"], 0.05, 0.9, decai=5) + 0.4 * sino(freq("G6"), 0.9, 6)), saida / "vela.wav")
    salvar(normaliza(ruido_madeira(0.5) * 2.0 + 0.6 * sino(freq("C4"), 0.5, 9), PICO * 0.85), saida / "encaixe.wav")

    # filhote: "auf" fofinho = glissando rápido de sino agudo
    dur = 0.35
    t = np.arange(int(SR * dur)) / SR
    f = 900 + 500 * np.exp(-t * 18)
    fase = 2 * np.pi * np.cumsum(f) / SR
    au = (np.sin(fase) + 0.3 * np.sin(2 * fase)) * np.clip(t / 0.012, 0, 1) * np.exp(-t * 9)
    salvar(normaliza(np.concatenate([au, np.zeros(int(SR * 0.05)), au * 0.7]), PICO * 0.6), saida / "filhote.wav")

    # música do castelo: Fá maior, 76 bpm, 8 compassos, calma
    bpm = 76
    sem = 60 / bpm
    melodia = ["F5", "A5", "C6", "A5", "G5", "E5", "F5", None, "A5", "C6", "D6", "C6", "A5", "G5", "F5", None,
               "D5", "F5", "A5", "G5", "E5", "G5", "C5", None, "F5", "G5", "A5", "G5", "F5", None, None, None]
    baixo = ["F3", "C3", "F3", "C3", "D3", "C3", "A#2", "C3"]
    baixo = [b.replace("A#2", "A#2") for b in baixo]
    ev = [(i * sem, n, 1.8, 0.9, 2.8) for i, n in enumerate(melodia) if n]
    ev += [(c * 4 * sem, b, 3.2, 0.6, 1.3) for c, b in enumerate(baixo)]
    ev += [(c * 4 * sem + 2 * sem, b[:-1] + str(int(b[-1]) + 1), 1.6, 0.22, 2.2) for c, b in enumerate(baixo)]
    salvar(normaliza(laco(ev, 32 * sem), PICO * 0.7), saida / "musica_castelo.wav")


def ruido_suave(dur: float, janela: int, semente: int) -> np.ndarray:
    """Ruído filtrado (água, vapor): só graves, sem chiado."""
    n = int(SR * dur)
    rng = np.random.default_rng(semente)
    return np.convolve(rng.standard_normal(n), np.ones(janela) / janela, mode="same")


def glissando(f0: float, f1: float, dur: float, decai: float = 6.0) -> np.ndarray:
    t = np.arange(int(SR * dur)) / SR
    f = f0 + (f1 - f0) * (t / dur)
    fase = 2 * np.pi * np.cumsum(f) / SR
    return (np.sin(fase) + 0.25 * np.sin(2 * fase)) * np.clip(t / 0.012, 0, 1) * np.exp(-t * decai)


def laboratorio(saida: Path) -> None:
    """Sons da fase 3 (laboratório do Frankenstein)."""
    # alçapão abrindo: rangido suave subindo + sininho
    rang = glissando(180, 320, 0.7, 3.5) * 0.7 + ruido_madeira(0.7, 9) * 1.5
    alcapao = np.zeros(int(SR * 1.0))
    alcapao[: len(rang)] += rang
    alcapao[int(SR * 0.2):] += sequencia(["C6", "G6"], 0.1, 0.8, 6)
    salvar(normaliza(alcapao, PICO * 0.75), saida / "alcapao.wav")

    # caldeirão: plop (gota grave descendo) e borbulha (bolhas subindo + acorde)
    salvar(normaliza(glissando(420, 140, 0.35, 9), PICO * 0.7), saida / "plop.wav")
    bolhas = np.zeros(int(SR * 1.3))
    for k, (ini, f) in enumerate([(0.0, 500), (0.12, 650), (0.22, 560), (0.34, 760), (0.45, 900)]):
        b = glissando(f, f * 1.6, 0.16, 14)
        i = int(ini * SR)
        bolhas[i:i + len(b)] += b * 0.6
    bolhas += sequencia(["C5", "E5", "G5", "C6"], 0.12, 1.3, decai=4) * 0.8
    salvar(normaliza(bolhas, PICO * 0.8), saida / "borbulha.wav")

    # canos: clique suave de girar, água correndo, planta crescendo
    salvar(normaliza(ruido_madeira(0.25, 11) * 1.4 + 0.5 * sino(freq("G5"), 0.25, 14), PICO * 0.6), saida / "clique.wav")
    dur = 2.2
    t = np.arange(int(SR * dur)) / SR
    agua = ruido_suave(dur, 60, 13) * (0.6 + 0.4 * np.sin(2 * np.pi * 5 * t)) * np.clip(t / 0.3, 0, 1) * np.clip((dur - t) / 0.5, 0, 1)
    for ini in (0.2, 0.6, 1.1, 1.5):
        g = glissando(700, 1100, 0.12, 16)
        i = int(ini * SR)
        agua[i:i + len(g)] += g * 0.08
    salvar(normaliza(agua, PICO * 0.6), saida / "agua.wav")
    salvar(normaliza(np.pad(glissando(300, 900, 1.2, 2.5), (0, int(SR * 0.4))) * 0.6 + sequencia(["C5", "D5", "E5", "G5", "A5", "C6"], 0.16, 1.6, decai=4)), saida / "planta.wav")

    # botões das formas: uma nota por forma (mesma pentatônica da música, uma oitava abaixo e marimba)
    for i, nota in enumerate(["G4", "A4", "C5", "D5"]):
        salvar(normaliza(sino(freq(nota), 0.7, 6, brilho=0.6), PICO * 0.85), saida / f"forma_{i}.wav")

    # máquina ligando: zumbido grave crescendo suave + arpejo brilhante (nada alto)
    dur = 2.6
    t = np.arange(int(SR * dur)) / SR
    zumbido = (np.sin(2 * np.pi * 110 * t) + 0.5 * np.sin(2 * np.pi * 165 * t)) * np.clip(t / 1.2, 0, 1) * np.exp(-np.clip(t - 1.6, 0, None) * 3)
    arpejo = np.zeros(len(t))
    arp = sequencia(["C5", "E5", "G5", "C6", "E6", "G6"], 0.11, 1.4, decai=4)
    arpejo[int(SR * 1.1): int(SR * 1.1) + len(arp)] += arp[: len(t) - int(SR * 1.1)]
    salvar(normaliza(zumbido * 0.35 + arpejo, PICO * 0.7), saida / "maquina.wav")

    # música do laboratório: Lá menor dórico brincalhão, 96 bpm, pizzicato
    bpm = 96
    col = 60 / bpm / 2
    melodia = ["A5", None, "C6", "A5", "E5", None, "G5", "A5", "B5", None, "D6", "B5", "G5", None, "A5", None,
               "C6", "D6", "E6", None, "D6", "C6", "B5", None, "A5", "G5", "E5", "G5", "A5", None, None, None]
    baixo = ["A2", "A2", "G2", "G2", "F2", "F2", "E2", "E2"]
    ev = [(i * col, n, 0.5, 0.8, 7.0) for i, n in enumerate(melodia) if n]
    for c, b in enumerate(baixo):
        for k in range(2):
            ev.append(((c * 4 + k * 2) * col, b, 0.6, 0.7, 5.0))
            ev.append(((c * 4 + k * 2 + 1) * col, b[:-1] + "3", 0.4, 0.3, 7.0))
    salvar(normaliza(laco(ev, 32 * col), PICO * 0.7), saida / "musica_laboratorio.wav")


def cemiterio(saida: Path) -> None:
    """Sons da fase 4 (cemitério das abóboras)."""
    # risadinha de fantasminha: "hi-hi-hi" agudo, descendo um pouquinho
    hi = np.zeros(int(SR * 0.75))
    for k, f in enumerate([1250, 1150, 1050]):
        g = glissando(f, f * 1.15, 0.12, 14)
        i = int(k * 0.2 * SR)
        hi[i:i + len(g)] += g
    salvar(normaliza(hi, PICO * 0.7), saida / "risadinha.wav")
    # achei: "uhuu" subindo + sininho
    achei = np.zeros(int(SR * 0.9))
    g = glissando(500, 1100, 0.45, 4)
    achei[: len(g)] += g
    sq = sequencia(["E6", "G6", "C7"], 0.08, 0.5, decai=7)
    achei[int(SR * 0.35): int(SR * 0.35) + len(sq)] += sq * 0.7
    salvar(normaliza(achei, PICO * 0.8), saida / "achei.wav")
    # horta
    salvar(normaliza(ruido_madeira(0.35, 21) * 1.2 + 0.5 * sino(freq("C5"), 0.35, 10), PICO * 0.6), saida / "plantar.wav")
    dur = 1.0
    t = np.arange(int(SR * dur)) / SR
    regar = ruido_suave(dur, 25, 23) * np.clip(t / 0.1, 0, 1) * np.clip((dur - t) / 0.3, 0, 1)
    salvar(normaliza(regar, PICO * 0.5), saida / "regar.wav")
    crescer = np.zeros(int(SR * 2.0))
    g = glissando(200, 700, 1.6, 1.8)
    crescer[: len(g)] += g * 0.6
    sq = sequencia(["C5", "E5", "G5", "C6"], 0.4, 2.0, decai=3)
    crescer[: len(sq)] += sq
    salvar(normaliza(crescer, PICO * 0.75), saida / "crescer.wav")
    salvar(normaliza(ruido_madeira(0.5, 25) * 1.6 + sequencia(["G4", "C5"], 0.12, 0.5, decai=6), PICO * 0.75), saida / "carroca.wav")
    # pega-pega: risada grave e boba do Fantasmão
    ho = np.zeros(int(SR * 1.0))
    for k, f in enumerate([330, 300, 270]):
        g = glissando(f, f * 0.8, 0.22, 7)
        i = int(k * 0.26 * SR)
        ho[i:i + len(g)] += g
    salvar(normaliza(ho, PICO * 0.75), saida / "peguei.wav")
    # música do cemitério: valsinha em Sol maior, 3/4, 112 bpm, caixinha de música
    bpm = 112
    sem = 60 / bpm
    melodia = ["D5", "G5", "B5", "A5", "G5", "E5", "D5", None, "B4",
               "C5", "E5", "G5", "F#5", "E5", "C5", "D5", None, None,
               "D5", "G5", "B5", "D6", "C6", "A5", "B5", "G5", "E5",
               "F#5", "A5", "D5", "G5", None, None, None, None, None]
    baixo = ["G3", "G3", "C3", "D3", "G3", "E3", "C3", "D3", "G3", "E3", "D3", "G3"]  # um por compasso
    ev = [(i * sem, n, 1.4, 0.85, 3.2) for i, n in enumerate(melodia) if n]
    total = len(melodia) * sem
    passo = total / len(baixo)
    for c, b in enumerate(baixo):
        ev.append((c * passo, b, 1.8, 0.55, 2.0))
        acorde = b[:-1] + str(int(b[-1]) + 1)
        ev.append((c * passo + sem, acorde, 0.6, 0.2, 5.0))
        ev.append((c * passo + 2 * sem, acorde, 0.6, 0.2, 5.0))
    salvar(normaliza(laco(ev, total), PICO * 0.7), saida / "musica_cemiterio.wav")


def telhado(saida: Path) -> None:
    """Sons da fase 5 (telhado das estrelas): tudo suave, de dormir."""
    # estrela pega: "plim" agudo com brilho
    salvar(normaliza(sequencia(["E6", "B6", "E7"], 0.05, 0.8, decai=6), PICO * 0.6), saida / "estrela.wav")
    # estrela caindo: brilho descendo baixinho
    queda = glissando(2200, 900, 0.8, 3) * 0.5 + sequencia(["C7", "G6", "E6"], 0.18, 0.8, decai=8) * 0.4
    salvar(normaliza(queda, PICO * 0.4), saida / "queda.wav")
    # notas das constelações: escala de Dó subindo, sino
    for i, n in enumerate(["C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"]):
        salvar(normaliza(sino(freq(n), 1.2, 3.0, 0.4), PICO * 0.65), saida / f"astro_{i}.wav")
    # constelação pronta: arpejo e acorde brilhando
    pronta = sequencia(["C5", "E5", "G5", "C6", "E6"], 0.1, 2.2, decai=3)
    acorde = sum(sino(freq(n), 1.6, 2.2) for n in ["C6", "E6", "G6"]) * 0.35
    pronta[int(0.5 * SR): int(0.5 * SR) + len(acorde)] += acorde[: len(pronta) - int(0.5 * SR)]
    salvar(normaliza(pronta, PICO * 0.7), saida / "constelacao.wav")
    # planetinha rolando: ronquinho grave e curto
    dur = 0.5
    t = np.arange(int(SR * dur)) / SR
    rolar = ruido_suave(dur, 60, 31) * np.clip(t / 0.05, 0, 1) * np.exp(-t * 5) + 0.4 * glissando(160, 110, dur, 5)
    salvar(normaliza(rolar, PICO * 0.45), saida / "rolar.wav")
    # méé fofo: tom médio tremido, baixinho
    dur = 0.7
    t = np.arange(int(SR * dur)) / SR
    f = 620 * (1 + 0.04 * np.sin(2 * np.pi * 9 * t))
    fase = 2 * np.pi * np.cumsum(f) / SR
    mee = (np.sin(fase) + 0.3 * np.sin(2 * fase) + 0.15 * np.sin(3 * fase)) * np.clip(t / 0.06, 0, 1) * np.clip((dur - t) / 0.25, 0, 1)
    salvar(normaliza(mee, PICO * 0.5), saida / "mee.wav")
    # boing: sobe e desce (ovelhinha pulando a cerca)
    boing = np.concatenate([glissando(300, 700, 0.18, 2), glissando(700, 420, 0.3, 6)])
    salvar(normaliza(boing, PICO * 0.55), saida / "boing.wav")
    # fogos de estrelinha: brilhos espalhados, nada de estouro
    rng = np.random.default_rng(41)
    fogos = np.zeros(int(SR * 2.0))
    for k in range(14):
        n = ["C6", "E6", "G6", "C7", "E7"][rng.integers(0, 5)]
        s = sino(freq(n), 0.6, 7, 0.5)
        i = int(rng.uniform(0, 1.4) * SR)
        fogos[i:i + len(s)] += s * rng.uniform(0.3, 0.7)
    salvar(normaliza(fogos, PICO * 0.5), saida / "fogos.wav")
    # canção de ninar: 3/4, 72 bpm, Fá maior, caixinha de música bem calma
    bpm = 72
    sem = 60 / bpm
    melodia = ["C5", "F5", "A5", "G5", "F5", None, "E5", "G5", "C6", "A5", None, None,
               "A5", "G5", "F5", "D5", "F5", None, "E5", "G5", "E5", "F5", None, None,
               "C5", "F5", "A5", "C6", "A5", None, "A#5", "A5", "G5", "A5", None, None,
               "F5", "E5", "D5", "C5", "E5", "G5", "F5", None, None, None, None, None]
    baixo = ["F3", "C3", "D3", "C3", "F3", "A#2", "C3", "F3"]  # 2 compassos cada
    ev = [(i * sem, n, 2.0, 0.8, 2.4) for i, n in enumerate(melodia) if n]
    total = len(melodia) * sem
    passo = total / len(baixo)
    for c, b in enumerate(baixo):
        ev.append((c * passo, b, 3.0, 0.5, 1.4))
        ev.append((c * passo + 3 * sem, b, 2.0, 0.3, 1.8))
    salvar(normaliza(laco(ev, total), PICO * 0.6), saida / "musica_telhado.wav")


if __name__ == "__main__":
    main()
