#!/usr/bin/env python3
"""Encontro com flor sagrada (ata 4.1): Dó lídio, 72 BPM, 16 compassos = 53,3 s, loop.
Toca quando a flor/fragmento surge após o chefe e durante a bênção (oração de recompensa)."""
import sys
import numpy as np
from engine import *

OUT = sys.argv[1]
BPM = 72.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
S16 = BEAT / 4
N = int(round(16 * BAR * SR))
lo = Loop(N, seed=71)
L = lo.L


def T(bar, beat=1.0):
    return ((bar - 1) * 4 + (beat - 1)) * BEAT


CH = [
    ("Cmaj9", 36, [52, 55, 59, 62, 67], [[(1, 72, 1), (2, 76, 1), (3, 79, 1.5), (4.5, 78, .5)], [(1, 74, 2), (3, 72, 2)]]),
    ("D/C", 36, [54, 57, 62, 66], [[(1, 74, 1), (2, 78, 1), (3, 81, 1.5), (4.5, 79, .5)], [(1, 76, 2), (3, 74, 2)]]),
    ("Am9", 33, [57, 60, 64, 67, 71], [[(1, 69, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 74, .5)], [(1, 71, 2), (3, 69, 2)]]),
    ("Fmaj7#11", 41, [53, 57, 60, 64, 71], [[(1, 69, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 74, .5)], [(1, 72, 2), (3, 69, 2)]]),
    ("Cmaj9", 36, [52, 55, 59, 62, 67], [[(1, 67, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 74, .5)], [(1, 71, 2), (3, 67, 2)]]),
    ("Em7", 40, [52, 55, 59, 62], [[(1, 67, 1), (2, 71, 1), (3, 76, 1.5), (4.5, 74, .5)], [(1, 71, 2), (3, 67, 2)]]),
    ("Fmaj7", 41, [53, 57, 60, 64], [[(1, 69, 1), (2, 72, 1), (3, 77, 1.5), (4.5, 76, .5)], [(1, 72, 2), (3, 69, 2)]]),
    ("G6", 43, [55, 59, 62, 64], [[(1, 71, 1), (2, 74, 1), (3, 79, 1.5), (4.5, 76, .5)], [(1, 74, 2), (3, 71, 2)]]),
]
SCHED = []
for k, (name, root, pad, mel) in enumerate(CH):
    b0 = 1 + 2 * k
    t0, dur = T(b0), 2 * BAR
    SCHED.append((name, t0, t0 + dur, pad + [root]))
    for j, m in enumerate(pad):
        for side, pan in ((0, -0.55), (1, 0.55)):
            lo.put("pad", pad_note(float(mtof(m)), dur + 0.4, atk=1.6, rel=2.4, bright=0.30, t0=t0 - 0.2, seed=30 * k + 5 * j + side),
                   t0 - 0.2, pan=pan, gain=0.045)
    lo.put("sub", sub(float(mtof(root)), dur + 0.2, atk=0.9, rel=1.8), t0 - 0.1, gain=0.075)
    for j, m in enumerate([pad[1], pad[-1]]):
        lo.put("choir", choir_note(float(mtof(m)), dur, "a" if j else "o", atk=1.6, rel=2.4, seed=11 * k + j), t0, pan=(-0.4, 0.4)[j], gain=0.13)
    for bi, notes in enumerate(mel):
        for beat, m, d in notes:
            t = T(b0 + bi, beat)
            lo.put("mel", glass(float(mtof(m)), 5.0, atk=0.02, tau=2.0), t, pan=float(np.clip((m - 74) / 20, -0.5, 0.5)), gain=0.085)
            lo.put("mel", kalimba(float(mtof(m)), 2.6, seed=int(t * 10)), t, pan=-0.2, gain=0.045)
    for bb in (b0, b0 + 1):
        for i, ix in enumerate([0, 2, 1, 3, 2, 3, 1, 2]):
            t = T(bb) + i * 2 * S16
            lo.put("harp", harp(float(mtof(pad[ix % len(pad)] + 12)), 3.0, seed=int(t * 9)), t, pan=(-0.4 if i % 2 else 0.4), gain=0.050)

r = lo.rng
t = 0.5
while t < L:
    pad = [s for (_, t0, t1, s) in SCHED if t0 <= t < t1][0][:-1]
    lo.put("spark", glass(float(mtof(int(r.choice(pad)) + 24 + 12 * int(r.integers(0, 2)))), 2.4, atk=0.004, tau=0.7), t,
           pan=float(r.uniform(-0.8, 0.8)), gain=0.040)
    t += r.exponential(1.1) + 0.4

spec = {
    "pad": dict(rev=(3.6, 6000, 0.36)), "sub": dict(), "choir": dict(rev=(4.4, 5000, 0.55)),
    "mel": dict(rev=(3.6, 7500, 0.40), delay=(0.75 * BEAT, 0.34, 0.35)), "harp": dict(rev=(3.0, 7000, 0.40)),
    "spark": dict(rev=(3.8, 8000, 0.45), delay=(0.75 * BEAT, 0.42, 0.35)),
}
mix = lo.render(spec)
y = master(mix, OUT + ".tmp.wav", target_lufs=-21.0)
save_wav(y, OUT)
check_loop(OUT, "flor")
chord_check(OUT, SCHED)
