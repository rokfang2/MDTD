#!/usr/bin/env python3
"""Combate: Cordyceps, o Hospedeiro (ré frígio dominante, 126 BPM, 32 compassos = 60,95 s, loop).

python3 compose_cordyceps.py saida.wav            -> fase I (faixa base)
python3 compose_cordyceps.py saida.wav --fase2    -> camada da fase II (mesmo comprimento; toca sincronizada por cima)

Legibilidade (ata 4.1): a trilha fica concentrada em graves/médios, SEM risers, swells invertidos ou
rolos de cliques, que poderiam ser confundidos com os avisos de ataque (tell_*, faixa de 1-5 kHz).
"""
import sys
import numpy as np
from engine import *

OUT = sys.argv[1]
FASE2 = "--fase2" in sys.argv
BPM = 126.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
S16 = BEAT / 4
N = int(round(32 * BAR * SR))
lo = Loop(N, seed=61 if not FASE2 else 62)
L = lo.L


def T(bar, beat=1.0):
    return ((bar - 1) * 4 + (beat - 1)) * BEAT


CD = {
    "Dmb9": [50, 57, 63, 65], "Dm": [50, 53, 57, 62], "Eb": [51, 55, 58, 62], "Ddom": [50, 54, 57, 60],
    "Bb": [53, 58, 62, 65], "C": [52, 55, 60, 64], "Gm": [50, 55, 58, 62], "A7b9": [49, 52, 55, 58],
}
PROG = [("Dmb9", 38), ("Eb", 39), ("Dmb9", 38), ("Ddom", 38),
        ("Dm", 38), ("Bb", 34), ("C", 36), ("Ddom", 38),
        ("Gm", 43), ("Eb", 39), ("Gm", 43), ("A7b9", 45),
        ("Dmb9", 38), ("Eb", 39), ("Bb", 34), ("A7b9", 45)]
# melodia (leitmotiv 1-3-5-4 | b2-1 adaptado a cada acorde): (compasso, [(tempo, midi, dur)])
MEL = {
    9: [(1, 62, 1), (2, 65, 1), (3, 69, 1.5), (4.5, 67, .5)], 10: [(1, 63, 2), (3, 62, 2)],
    11: [(1, 65, 1), (2, 70, 1), (3, 74, 1.5), (4.5, 72, .5)], 12: [(1, 69, 2), (3, 65, 2)],
    13: [(1, 64, 1), (2, 67, 1), (3, 72, 1.5), (4.5, 70, .5)], 14: [(1, 67, 2), (3, 64, 2)],
    15: [(1, 66, 1), (2, 69, 1), (3, 72, 1.5), (4.5, 70, .5)], 16: [(1, 63, 2), (3, 62, 2)],
    25: [(1, 62, 1), (2, 65, 1), (3, 69, 1.5), (4.5, 67, .5)], 26: [(1, 63, 2), (3, 62, 2)],
    27: [(1, 63, 1), (2, 67, 1), (3, 70, 1.5), (4.5, 74, .5)], 28: [(1, 72, 2), (3, 70, 2)],
    29: [(1, 65, 1), (2, 70, 1), (3, 74, 1.5), (4.5, 72, .5)], 30: [(1, 70, 2), (3, 65, 2)],
    31: [(1, 73, 1), (2, 76, 1), (3, 79, 1.5), (4.5, 77, .5)], 32: [(1, 76, 2), (3, 73, 2)],
}

SCHED = []
for k, (name, root) in enumerate(PROG):
    b0 = 1 + 2 * k
    t0, dur = T(b0), 2 * BAR
    pad = CD[name]
    sec = "ABCD"[k // 4]
    SCHED.append((name, t0, t0 + dur, pad + [root]))
    if not FASE2:
        for j, m in enumerate(pad):
            for side, pan in ((0, -0.5), (1, 0.5)):
                lo.put("pad", pad_note(float(mtof(m)), dur + 0.2, atk=0.25, rel=1.0, bright=0.30, seed=40 * k + 5 * j + side),
                       t0 - 0.05, pan=pan, gain=0.040)
        lo.put("sub", sub(float(mtof(root)), dur, atk=0.05, rel=0.6, drive=2.0), t0, gain=0.10)
        for bb in (b0, b0 + 1):
            tb = T(bb)
            half = sec == "C"
            seq = [0, 0, 12, 0, 7, 0, 12, 1 if root == 38 else 7]
            for i, st in enumerate(seq):
                if half and i % 2:
                    continue
                lo.put("bass", pluck(float(mtof(root + 12 + st)), 0.45, tau=0.20, harm=6, click=0.08, vel=1.0 if i % 2 == 0 else 0.75),
                       tb + i * 2 * S16, gain=0.16)
            kicks = (0, 8) if half else (0, 7, 8, 10)
            for st in kicks:
                lo.put("drums", thump(105, 45, 0.4, 0.11), tb + st * S16, gain=0.36)
            for st in (4, 12):
                lo.put("drums", snare(0.9, seed=bb * 3 + st), tb + st * S16, pan=0.1, gain=0.20)
            for st in range(0, 16, 2):
                lo.put("drums", shaker(0.6 if st % 4 == 2 else 0.35, seed=bb * 7 + st), tb + st * S16, pan=0.35, gain=0.05)
            if sec == "C":
                for st in (3, 6, 11, 14):
                    lo.put("drums", taiko(float(mtof(root + 12)), 0.7, seed=bb * 11 + st), tb + st * S16, pan=-0.2, gain=0.22)
            if bb % 8 == 0:  # virada de taikos (ritmo, sem subida de afinação)
                for st in (12, 13, 14, 15):
                    lo.put("drums", taiko(float(mtof(root + 12)) * (1.2 - 0.06 * (st - 12)), 0.8, seed=bb + st, dur=0.4), tb + st * S16, pan=-0.2, gain=0.22)
        if sec in "CD":
            for j, m in enumerate(pad[:3]):
                lo.put("choir", choir_note(float(mtof(m)), 0.35, "a", atk=0.02, rel=0.5, seed=k * 3 + j), t0, pan=(-0.4, 0.0, 0.4)[j], gain=0.07)
    else:
        # camada da fase II: mais densidade, sem novas frequências agudas sustentadas
        for bb in (b0, b0 + 1):
            tb = T(bb)
            for st in range(16):
                lo.put("drums", shaker(0.45 if st % 2 else 0.25, seed=bb * 13 + st), tb + st * S16, pan=-0.35, gain=0.040)
            for st in (2, 5, 9, 13):
                lo.put("drums", taiko(float(mtof(root + 12)), 0.75, seed=bb * 17 + st), tb + st * S16, pan=0.25, gain=0.24)
            lo.put("drums", thump(62, 30, 1.0, 0.3), tb, gain=0.30)
            arp = [pad[0], pad[1], pad[2], pad[3]] * 4
            for st, m in enumerate(arp):
                lo.put("arp", pluck(float(mtof(m + 12)), 0.25, tau=0.09, harm=5, click=0.02, vel=0.8 if st % 4 == 0 else 0.55),
                       tb + st * S16, pan=(-0.45 if st % 2 else 0.45), gain=0.040)
        for j, m in enumerate(pad[:3]):
            lo.put("choir", choir_note(float(mtof(m)), dur, "o", atk=0.6, rel=1.2, seed=90 + k * 3 + j), t0, pan=(-0.5, 0.0, 0.5)[j], gain=0.075)

if not FASE2:
    for b, notes in MEL.items():
        for beat, m, d in notes:
            t = T(b, beat)
            f = float(mtof(m))
            lo.put("lead", pad_note(f, d * BEAT * 0.92, atk=0.015, rel=0.22, cents=(-6, 0, 6), bright=0.85, seed=int(t * 13)), t, pan=-0.1, gain=0.075)
            lo.put("lead", kalimba(f * 2, 1.2, seed=int(t * 7)), t, pan=0.25, gain=0.035)
    spec = {
        "pad": dict(rev=(1.8, 5000, 0.22)), "sub": dict(), "bass": dict(rev=(0.8, 3000, 0.06)),
        "drums": dict(rev=(1.2, 5000, 0.12)), "choir": dict(rev=(2.4, 4500, 0.40)),
        "lead": dict(rev=(1.8, 6000, 0.25), delay=(0.75 * BEAT, 0.25, 0.22)),
    }
    target = -20.0
else:
    spec = {"drums": dict(rev=(1.2, 5000, 0.12)), "arp": dict(rev=(1.6, 6000, 0.25)), "choir": dict(rev=(2.6, 4500, 0.45))}
    target = -22.0

mix = lo.render(spec)
for name, buf in lo.stems.items():
    print(f"  stem {name:6s} rms {20 * np.log10(np.sqrt((buf.astype(float) ** 2).mean()) + 1e-9):6.1f} dB")
y = master(mix, OUT + ".tmp.wav", target_lufs=target)
save_wav(y, OUT)
check_loop(OUT, "cordyceps" + (" fase2" if FASE2 else ""))
if not FASE2:
    chord_check(OUT, SCHED)
