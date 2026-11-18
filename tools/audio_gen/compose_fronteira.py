#!/usr/bin/env python3
"""Fronteira Fúngica — tema de exploração da fase azulada (A dórico, 96 BPM, 32 compassos = 80 s, loop)."""
import sys
import numpy as np
from engine import *

OUT = sys.argv[1]
BPM = 96.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
N = int(round(32 * BAR * SR))
lo = Loop(N, seed=21)
L = lo.L
S16 = BEAT / 4


def T(bar, beat=1.0):
    return ((bar - 1) * 4 + (beat - 1)) * BEAT


# nível de "riqueza" por seção (A=calmo, B=cheio, C=névoa de cogumelos, D=cheio->volta)
_xs = [0, T(8, 3), T(9, 3), T(16, 3), T(17, 3), T(24, 3), T(25, 3), T(32, 3), L]
_ys = [0.35, 0.35, 1.0, 1.0, 0.0, 0.0, 0.9, 0.9, 0.35]


def rich(t):
    return np.interp(np.asarray(t) % L, _xs, _ys)


CD = {
    "Am9": dict(sub=33, pad=[57, 60, 64, 67, 71]),
    "D9": dict(sub=38, pad=[54, 57, 60, 64, 69]),
    "Gmaj7": dict(sub=31, pad=[55, 59, 62, 66, 71]),
    "Em7": dict(sub=40, pad=[52, 55, 59, 62, 66]),
    "Cmaj7": dict(sub=36, pad=[52, 55, 59, 64, 67]),
    "Fmaj7": dict(sub=41, pad=[53, 57, 60, 64, 67]),
    "F#m7b5": dict(sub=42, pad=[54, 57, 60, 64, 69]),
    "E7sus4": dict(sub=40, pad=[52, 57, 59, 62, 64]),
}
PROG = (["Am9", "D9", "Gmaj7", "Em7"] +        # A  bars 1-8
        ["Am9", "Cmaj7", "D9", "Gmaj7"] +      # B  bars 9-16
        ["Fmaj7", "Gmaj7", "F#m7b5", "E7sus4"] +  # C  bars 17-24
        ["Am9", "D9", "Gmaj7", "E7sus4"])      # D  bars 25-32

SCHED = []
for k, name in enumerate(PROG):
    b0 = 1 + 2 * k
    t0, dur = T(b0), 2 * BAR
    c = CD[name]
    sec = "ABCD"[k // 4]
    SCHED.append((name, t0, t0 + dur, c["pad"] + [c["sub"]]))
    mid = t0 + dur / 2
    R = float(rich(mid))
    # pad
    for j, m in enumerate(c["pad"]):
        f = float(mtof(m))
        for side, pan in ((0, -0.55), (1, 0.55)):
            lo.put("pad", pad_note(f, dur + 0.4, atk=1.4, rel=2.0, bright=lambda tt: 0.16 + 0.30 * rich(tt),
                                   t0=t0 - 0.2, seed=50 * k + 7 * j + side), t0 - 0.2, pan=pan, gain=0.050)
    # sub
    lo.put("sub", sub(float(mtof(c["sub"])), dur + 0.2, atk=0.7, rel=1.6), t0 - 0.1, gain=0.09)
    # coro "ooh" (B/D) e pad de vidro (C)
    if sec in "BD":
        for j, m in enumerate([c["pad"][2], c["pad"][-1]]):
            lo.put("choir", choir_note(float(mtof(m)), dur, "o" if j == 0 else "u", atk=1.4, rel=2.0, seed=13 * k + j),
                   t0, pan=(-0.4, 0.4)[j], gain=0.12)
    if sec == "C":
        for j, m in enumerate(c["pad"][1:]):
            lo.put("glassp", sine_pad(float(mtof(m + 12)), dur + 0.2, atk=1.6, rel=2.4, seed=5 * k + j), t0 - 0.2,
                   pan=(-0.7, 0.7, -0.3, 0.3)[j % 4], gain=0.050)
    # baixo pluck (B/D)
    if sec in "BD":
        for bb in (b0, b0 + 1):
            for g, st, vel in ((0, 0, 1.0), (6, 0, .65), (10, 7, .6)):
                t = T(bb) + g * S16
                lo.put("bass", pluck(float(mtof(c["sub"] + 12 + st)), 0.9, tau=0.55, harm=3, click=0.05, vel=vel), t, gain=0.13)
    # arpejo de kalimba (A leve, B/D cheio)
    if sec in "ABD":
        for bb in (b0, b0 + 1):
            pat = [0, 2, 1, 3, 2, 4, 3, 1]
            for i, ix in enumerate(pat):
                t = T(bb) + i * 2 * S16
                if float(rich(t)) < 0.55:
                    continue
                lo.put("arp", kalimba(float(mtof(c["pad"][ix] + 12)), 1.4, seed=int(t * 9)), t, pan=(-0.4 if i % 2 else 0.4),
                       gain=0.050 * float(rich(t)))
    # percussão
    for bb in (b0, b0 + 1):
        Rb = float(rich(T(bb)))
        if sec == "C":
            lo.put("perc", thump(88, 44, 0.45, 0.12), T(bb), gain=0.15)
            continue
        lo.put("perc", thump(95, 46, 0.4, 0.10), T(bb), gain=0.20 * (0.4 + 0.6 * Rb))
        lo.put("perc", thump(90, 46, 0.36, 0.09), T(bb) + 8 * S16, gain=0.16 * (0.4 + 0.6 * Rb))
        grids = (6, 14) if sec == "A" else (3, 6, 10, 14)
        for gi, g in enumerate(grids):
            f = float(mtof(c["pad"][(gi * 2) % 5] + (12 if gi % 2 else 0)))
            lo.put("perc", tok(f, vel=1.0 if g in (6, 14) else 0.55, seed=gi + bb), T(bb) + g * S16, pan=(-0.3, 0.3)[gi % 2],
                   gain=0.075 * (0.55 + 0.45 * Rb))
        if sec in "BD":
            for g in (2, 6, 10, 14):
                lo.put("perc", shaker(0.9 if g in (6, 14) else 0.5, seed=bb * 3 + g), T(bb) + g * S16, pan=0.4, gain=0.040)

# ---------------------------------------------------------------- melodia (leitmotiv do druida, em Lá dórico)
MEL = [
    # A
    (1, "k", [(1, 69, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 74, .5)]), (2, "k", [(1, 71, 2), (3, 69, 2)]),
    (3, "k", [(1, 66, 1), (2, 69, 1), (3, 74, 1.5), (4.5, 72, .5)]), (4, "k", [(1, 69, 2), (3, 66, 2)]),
    (5, "k", [(1, 74, 1), (2, 71, 1), (3, 78, 1.5), (4.5, 76, .5)]), (6, "k", [(1, 74, 2), (3, 71, 2)]),
    (7, "k", [(1, 67, 1), (2, 71, 1), (3, 76, 1.5), (4.5, 74, .5)]), (8, "k", [(1, 71, 2), (3, 69, 2)]),
    # B (variação mais ativa)
    (9, "k", [(1, 69, 1), (2, 72, .5), (2.5, 76, .5), (3, 81, 1.5), (4.5, 79, .5)]), (10, "k", [(1, 76, 1), (2, 72, 1), (3, 71, 2)]),
    (11, "k", [(1, 76, 1), (2, 79, .5), (2.5, 76, .5), (3, 72, 1.5), (4.5, 74, .5)]), (12, "k", [(1, 71, 2), (3, 67, 2)]),
    (13, "k", [(1, 78, 1), (2, 81, 1), (3, 78, 1), (4, 76, 1)]), (14, "k", [(1, 74, 2), (3, 72, 2)]),
    (15, "k", [(1, 71, 1), (2, 74, 1), (3, 78, 1.5), (4.5, 76, .5)]), (16, "k", [(1, 74, 2), (3, 71, 2)]),
    # C (sinos de vidro, lento)
    (17, "g", [(1, 72, 4)]), (18, "g", [(1, 69, 4)]), (19, "g", [(1, 78, 4)]), (20, "g", [(1, 74, 4)]),
    (21, "g", [(1, 76, 4)]), (22, "g", [(1, 72, 4)]), (23, "g", [(1, 71, 4)]), (24, "g", [(1, 69, 2), (3, 74, 2)]),
    # D (retorno do tema)
    (25, "k", [(1, 69, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 74, .5)]), (26, "k", [(1, 71, 2), (3, 69, 2)]),
    (27, "k", [(1, 66, 1), (2, 69, 1), (3, 74, 1.5), (4.5, 72, .5)]), (28, "k", [(1, 69, 2), (3, 66, 2)]),
    (29, "k", [(1, 74, 1), (2, 71, 1), (3, 78, 1.5), (4.5, 76, .5)]), (30, "k", [(1, 74, 2), (3, 71, 2)]),
    (31, "k", [(1, 76, 1), (2, 74, 1), (3, 69, 1.5), (4.5, 71, .5)]), (32, "k", [(1, 69, 2), (3, 76, 2)]),
]
for b, inst, notes in MEL:
    for beat, m, d in notes:
        t = T(b, beat)
        f = float(mtof(m))
        pan = float(np.clip((m - 72) / 24.0, -0.5, 0.5))
        if inst == "k":
            lo.put("mel", kalimba(f, 2.8, seed=int(t * 10)), t, pan=pan, gain=0.105)
        else:
            lo.put("mel", glass(f, 5.5, atk=0.03, tau=2.4), t, pan=-pan, gain=0.085)

# ---------------------------------------------------------------- texturas
tt = lo.t()
for pan, seed in ((-1.0, 0), (1.0, 1)):
    wnd = lo.pnoise(160, 800) * (0.5 + 0.3 * np.sin(2 * np.pi * 3 * tt / L + seed) + 0.2 * np.sin(2 * np.pi * 7 * tt / L + 2 * seed))
    mist = lo.pnoise(3000, 8000) * (0.2 + 0.15 * np.sin(2 * np.pi * 5 * tt / L + seed)) * (1 - rich(tt))
    th = (pan + 1) * np.pi / 4
    sig = 0.014 * wnd + 0.007 * mist
    lo.put("tex", np.stack([sig * np.cos(th), sig * np.sin(th)]), 0.0)

r = lo.rng
for fc, period, off, pan in ((5100, 1.9, 0.3, -0.6), (4400, 2.4, 1.1, 0.5)):  # grilos distantes, bem baixos
    t = off
    while t < L:
        lo.put("cric", cricket(fc * (1 + 0.01 * r.standard_normal()), groups=int(r.integers(2, 4)), seed=int(t * 13)), t,
               pan=pan, gain=0.05)
        t += period * r.uniform(0.9, 1.2)


def chord_at(t):
    for (_, t0, t1, midis) in SCHED:
        if t0 <= t % L < t1:
            return midis[:-1]
    return SCHED[0][3][:-1]


t = 0.8
while t < L:
    pad = chord_at(t)
    m = int(r.choice(pad)) + 12 * int(r.choice([2, 2, 3]))
    lo.put("spark", glass(float(mtof(m)), 2.4, atk=0.004, tau=0.7), t, pan=r.uniform(-0.8, 0.8), gain=0.045)
    t += r.exponential(1.2) + 0.45

# sussurros e vidro invertido nas viradas de seção
for b, beat, pan, vw in ((18, 2.0, -0.6, "o"), (20, 3.0, 0.6, "u"), (22, 3.5, -0.3, "a"), (23, 2.0, 0.4, "o")):
    lo.put("fx", whisper(3.0, vw, seed=b), T(b, beat), pan=pan, gain=0.060)
for tb, ns in ((T(9), (76, 83)), (T(17), (69,)), (T(25), (76, 83)), (T(1), (81,))):
    for j, n in enumerate(ns):
        lo.put("fx", rev_glass(float(mtof(n)), 2.4), tb - 2.4, pan=(-0.3, 0.3)[j % 2], gain=0.14)
lo.put("fx", riser(BAR * 1.0, 400, 7000, seed=4), T(32, 1), gain=0.045)
lo.put("perc", thump(70, 36, 1.4, 0.3), T(9), gain=0.35)
lo.put("perc", thump(70, 36, 1.4, 0.3), T(25), gain=0.32)

if "--perigo" in sys.argv:
    # Camada de perigo: mesmo comprimento/andamento/acordes, toca sincronizada por cima (inimigos em perseguição).
    lp2 = Loop(N, seed=lo.rng.integers(1 << 30))
    chords = [(lambda e: (e[1], e[2], e[3][:-1], e[3][-1]))(e) for e in SCHED]
    spec2 = danger_layer(lp2, BEAT, chords, seed=7, swing=0.0)
    y2 = master(lp2.render(spec2), OUT + ".tmp.wav", target_lufs=-24.0)
    save_wav(y2, OUT)
    check_loop(OUT, "perigo")
    sys.exit(0)

spec = {
    "pad": dict(rev=(3.4, 5500, 0.34)),
    "glassp": dict(rev=(5.0, 6500, 0.50)),
    "choir": dict(rev=(4.2, 4500, 0.50)),
    "sub": dict(),
    "bass": dict(rev=(1.2, 3000, 0.10)),
    "mel": dict(rev=(3.2, 6500, 0.36), delay=(0.75 * BEAT, 0.36, 0.40)),
    "arp": dict(rev=(2.6, 6500, 0.36), delay=(0.75 * BEAT, 0.30, 0.30)),
    "perc": dict(rev=(1.6, 5000, 0.14)),
    "tex": dict(rev=(2.4, 6000, 0.10)),
    "cric": dict(rev=(2.2, 7000, 0.18)),
    "spark": dict(rev=(3.6, 8000, 0.45), delay=(0.75 * BEAT, 0.42, 0.35)),
    "fx": dict(rev=(4.6, 6500, 0.50)),
}
mix = lo.render(spec)
for name, buf in lo.stems.items():
    print(f"  stem {name:7s} rms {20 * np.log10(np.sqrt((buf.astype(float) ** 2).mean()) + 1e-9):6.1f} dB")
y = master(mix, OUT + ".tmp.wav", target_lufs=-21.0)
save_wav(y, OUT)
check_loop(OUT, "fronteira")
chord_check(OUT, SCHED)
