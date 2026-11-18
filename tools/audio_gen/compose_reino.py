#!/usr/bin/env python3
"""Reino Verdejante — floresta verde ao entardecer (Sol lídio, 80 BPM, 28 compassos = 84 s, loop)."""
import sys
import numpy as np
from engine import *

OUT = sys.argv[1]
BPM = 80.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
N = int(round(28 * BAR * SR))
lo = Loop(N, seed=31)
L = lo.L
S16 = BEAT / 4


def T(bar, beat=1.0):
    return ((bar - 1) * 4 + (beat - 1)) * BEAT


_xs = [0, T(8, 3), T(9, 3), T(16, 3), T(17, 3), T(24, 3), T(25, 3), T(28, 3), L]
_ys = [0.40, 0.40, 1.0, 1.0, 0.85, 0.85, 0.40, 0.40, 0.40]


def rich(t):
    return np.interp(np.asarray(t) % L, _xs, _ys)


CD = {
    "Gmaj9":     dict(sub=31, pad=[55, 59, 62, 66, 69],
                      m=[[(1, 67, 1), (2, 71, 1), (3, 74, 1.5), (4.5, 73, .5)], [(1, 69, 2), (3, 67, 2)]]),
    "D6/9":      dict(sub=38, pad=[50, 54, 59, 64, 69],
                      m=[[(1, 66, 1), (2, 69, 1), (3, 74, 1.5), (4.5, 76, .5)], [(1, 71, 2), (3, 69, 2)]]),
    "Em9":       dict(sub=40, pad=[52, 55, 59, 62, 66],
                      m=[[(1, 67, 1), (2, 71, 1), (3, 76, 1.5), (4.5, 74, .5)], [(1, 71, 2), (3, 67, 2)]]),
    "Cmaj7#11":  dict(sub=36, pad=[48, 52, 55, 59, 66],
                      m=[[(1, 67, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 78, .5)], [(1, 74, 2), (3, 71, 2)]]),
    "Bm7":       dict(sub=35, pad=[54, 57, 62, 66, 71],
                      m=[[(1, 71, 1), (2, 74, 1), (3, 78, 1.5), (4.5, 76, .5)], [(1, 74, 2), (3, 71, 2)]]),
    "Am9":       dict(sub=33, pad=[57, 60, 64, 67, 71],
                      m=[[(1, 69, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 74, .5)], [(1, 71, 2), (3, 69, 2)]]),
}
PROG = (["Gmaj9", "D6/9", "Em9", "Cmaj7#11"] +      # A  1-8
        ["Em9", "Cmaj7#11", "Gmaj9", "D6/9"] +      # B  9-16
        ["Bm7", "Am9", "Cmaj7#11", "D6/9"] +        # C  17-24 (ponte)
        ["Gmaj9", "D6/9"])                          # D  25-28 (volta; D6/9 -> Gmaj9 fecha o loop)

SCHED = []
for k, name in enumerate(PROG):
    b0 = 1 + 2 * k
    t0, dur = T(b0), 2 * BAR
    c = CD[name]
    sec = "A" if b0 <= 8 else "B" if b0 <= 16 else "C" if b0 <= 24 else "D"
    SCHED.append((name, t0, t0 + dur, c["pad"] + [c["sub"]]))
    for j, m in enumerate(c["pad"]):
        f = float(mtof(m))
        for side, pan in ((0, -0.55), (1, 0.55)):
            lo.put("pad", pad_note(f, dur + 0.4, atk=1.6, rel=2.4, bright=lambda tt: 0.28 + 0.30 * rich(tt),
                                   t0=t0 - 0.2, seed=40 * k + 5 * j + side), t0 - 0.2, pan=pan, gain=0.050)
    lo.put("sub", sub(float(mtof(c["sub"])), dur + 0.2, atk=0.8, rel=1.8), t0 - 0.1, gain=0.085)
    # coro orgânico
    for j, m in enumerate([c["pad"][1], c["pad"][3]]):
        lo.put("choir", choir_note(float(mtof(m)), dur, "o" if j == 0 else "a", atk=1.8, rel=2.4, seed=17 * k + j),
               t0, pan=(-0.45, 0.45)[j], gain=0.15 * float(rich(t0 + dur / 2)))
    # melodia
    for bi, notes in enumerate(c["m"]):
        for beat, m, d in notes:
            t = T(b0 + bi, beat)
            f = float(mtof(m))
            pan = float(np.clip((m - 72) / 24.0, -0.5, 0.5))
            lo.put("mel", kalimba(f, 2.8, seed=int(t * 10)), t, pan=pan, gain=0.10)
            if sec in "BC":  # oitava acima, suave: brilho de harpa
                lo.put("mel", harp(f * 2, 2.2, seed=int(t * 11)), t + 0.012, pan=-pan, gain=0.030)
    # arpejo de harpa (rich alto)
    for bb in (b0, b0 + 1):
        pat = [0, 2, 4, 3, 1, 3, 4, 2]
        for i, ix in enumerate(pat):
            t = T(bb) + i * 2 * S16
            if float(rich(t)) < 0.55:
                continue
            lo.put("arp", harp(float(mtof(c["pad"][ix] + 12)), 2.4, seed=int(t * 9)), t, pan=(-0.45 if i % 2 else 0.45),
                   gain=0.060 * float(rich(t)))
    # baixo suave (B/C)
    if sec in "BC":
        for bb in (b0, b0 + 1):
            for g, st, vel in ((0, 0, 1.0), (8, 7, 0.55)):
                lo.put("bass", pluck(float(mtof(c["sub"] + 12 + st)), 1.1, tau=0.7, harm=3, click=0.04, vel=vel),
                       T(bb) + g * S16, gain=0.11)
    # pad de vidro na ponte
    if sec == "C":
        for j, m in enumerate(c["pad"][2:]):
            lo.put("glassp", sine_pad(float(mtof(m + 12)), dur + 0.2, atk=1.6, rel=2.4, seed=3 * k + j), t0 - 0.2,
                   pan=(-0.6, 0.6, 0.0)[j % 3], gain=0.04)

# ---------------------------------------------------------------- texturas
tt = lo.t()
for pan, seed in ((-1.0, 0), (1.0, 1)):
    wnd = lo.pnoise(180, 900) * (0.5 + 0.3 * np.sin(2 * np.pi * 3 * tt / L + seed) + 0.2 * np.sin(2 * np.pi * 7 * tt / L + 2 * seed))
    leaf = lo.pnoise(2500, 7500) * (0.30 + 0.22 * np.sin(2 * np.pi * 4 * tt / L + 1.3 * seed) + 0.1 * np.sin(2 * np.pi * 9 * tt / L))
    th = (pan + 1) * np.pi / 4
    sig = 0.015 * wnd + 0.011 * leaf
    lo.put("tex", np.stack([sig * np.cos(th), sig * np.sin(th)]), 0.0)

r = lo.rng
# grilos (entardecer) — mais presentes na calma (A/D)
for fc, period, off, pan in ((4350, 0.95, 0.0, -0.6), (5050, 1.30, 0.4, 0.55), (3900, 1.70, 0.9, 0.1)):
    t = off
    while t < L:
        g = 1.25 - float(rich(t))
        lo.put("cric", cricket(fc * (1 + 0.01 * r.standard_normal()), groups=int(r.integers(2, 4)), seed=int(t * 13)), t, pan=pan,
               gain=0.060 * g)
        t += period * r.uniform(0.9, 1.15)

# pássaros: gorjeios curtos e espaçados
t = 2.5
while t < L - 1.0:
    lo.put("bird", bird(r, base=float(r.uniform(2800, 4200))), t, pan=float(r.uniform(-0.9, 0.9)), gain=0.040)
    t += r.uniform(3.2, 7.5)


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
    t += r.exponential(1.0) / (0.5 + float(rich(t))) + 0.35

# viradas de seção: vidro invertido
for tb, ns in ((T(9), (76, 83)), (T(17), (71,)), (T(25), (79,)), (T(1), (74, 81))):
    for j, n in enumerate(ns):
        lo.put("fx", rev_glass(float(mtof(n)), 2.4), tb - 2.4, pan=(-0.3, 0.3)[j % 2], gain=0.13)
lo.put("fx", riser(BAR * 1.0, 500, 7500, seed=6), T(28, 1), gain=0.040)

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
    "pad": dict(rev=(3.2, 6000, 0.32)),
    "glassp": dict(rev=(4.8, 6500, 0.50)),
    "choir": dict(rev=(4.0, 5000, 0.50)),
    "sub": dict(),
    "bass": dict(rev=(1.2, 3000, 0.10)),
    "mel": dict(rev=(3.2, 7000, 0.36), delay=(0.75 * BEAT, 0.34, 0.38)),
    "arp": dict(rev=(2.8, 7000, 0.38), delay=(0.75 * BEAT, 0.30, 0.30)),
    "tex": dict(rev=(2.4, 6500, 0.10)),
    "cric": dict(rev=(2.2, 7000, 0.18)),
    "bird": dict(rev=(2.6, 8000, 0.35)),
    "spark": dict(rev=(3.6, 8000, 0.45), delay=(0.75 * BEAT, 0.42, 0.35)),
    "fx": dict(rev=(4.6, 6500, 0.50)),
}
mix = lo.render(spec)
for name, buf in lo.stems.items():
    print(f"  stem {name:7s} rms {20 * np.log10(np.sqrt((buf.astype(float) ** 2).mean()) + 1e-9):6.1f} dB")
y = master(mix, OUT + ".tmp.wav", target_lufs=-21.0)
save_wav(y, OUT)
check_loop(OUT, "reino")
chord_check(OUT, SCHED)
