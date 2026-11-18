#!/usr/bin/env python3
"""Rede Micelial — raízes e cogumelos roxos, o território da Rede (ré frígio, 60 BPM, 24 compassos = 96 s, loop)."""
import sys
import numpy as np
from engine import *

OUT = sys.argv[1]
BPM = 60.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
N = int(round(24 * BAR * SR))
lo = Loop(N, seed=41)
L = lo.L


def T(bar, beat=1.0):
    return ((bar - 1) * 4 + (beat - 1)) * BEAT


# (nome, sub, pad, motivo [(compasso_rel, tempo, midi, dur)], intensidade do coração)
CH = [
    ("Dfrigio",     38, [50, 57, 60, 63, 65],
     [(0, 1, 74, 2), (0, 2, 77, 2), (0, 3, 81, 2), (0, 4, 79, 2), (1, 1, 75, 2), (1, 3, 74, 2)], 0.18),
    ("Ebmaj7",      39, [51, 58, 62, 67, 70],
     [(0, 1, 70, 2), (0, 2, 74, 2), (0, 3, 79, 2), (0, 4, 77, 2), (1, 1, 74, 2), (1, 3, 70, 2)], 0.22),
    ("D7b9",        38, [54, 57, 60, 63, 66],
     [(0, 1, 78, 2), (0, 2, 81, 2), (0, 3, 84, 2), (0, 4, 87, 2), (1, 1, 81, 2), (1, 3, 78, 2)], 0.40),
    ("Bbmaj7#11",   34, [58, 62, 65, 69, 76],
     [(0, 1, 74, 2), (0, 2, 77, 2), (0, 3, 81, 2), (0, 4, 76, 2), (1, 1, 77, 2), (1, 3, 74, 2)], 0.26),
    ("Gm9",         31, [55, 58, 62, 65, 69],
     [(0, 1, 70, 2), (0, 2, 74, 2), (0, 3, 79, 2), (0, 4, 77, 2), (1, 1, 74, 2), (1, 3, 70, 2)], 0.24),
    ("A7sus4",      33, [52, 55, 62, 64, 69],
     [(0, 1, 74, 2), (0, 2, 76, 2), (0, 3, 81, 2), (0, 4, 79, 2), (1, 1, 76, 2), (1, 3, 74, 2)], 0.28),
]
HEART_BASE = [0.18, 0.22, 0.40, 0.26, 0.24, 0.28]

SCHED = []
for k, (name, subm, pad, motif, hb) in enumerate(CH):
    b0 = 1 + 4 * k
    t0, dur = T(b0), 4 * BAR
    SCHED.append((name, t0, t0 + dur, pad + [subm, 26]))
    for j, m in enumerate(pad):
        f = float(mtof(m))
        for side, pan in ((0, -0.6), (1, 0.6)):
            lo.put("pad", pad_note(f, dur + 0.6, atk=3.2, rel=4.0, bright=0.12 + 0.12 * (k == 2), cents=(-11, 0, 10),
                                   t0=t0 - 0.3, seed=30 * k + 5 * j + side), t0 - 0.3, pan=pan, gain=0.048)
    # sub da fundamental do acorde (bate contra o drone em ré => tensão)
    lo.put("sub", sub(float(mtof(subm)), dur + 0.4, atk=1.5, rel=3.0, drive=1.4), t0 - 0.3, gain=0.06)
    # pad de vidro (agudo, trêmulo)
    for j, m in enumerate(pad[1:]):
        lo.put("glassp", sine_pad(float(mtof(m + 12)), dur + 0.2, atk=3.0, rel=4.0, trem=(0.23 + 0.03 * j, 0.35), seed=9 * k + j),
               t0 - 0.2, pan=(-0.7, 0.7, -0.3, 0.3)[j % 4], gain=0.05)
    # sopro de coro grave
    for j, m in enumerate([pad[0], pad[2]]):
        lo.put("choir", choir_note(float(mtof(m)), dur, "o" if j == 0 else "u", atk=3.0, rel=4.0, seed=21 * k + j),
               t0, pan=(-0.4, 0.4)[j], gain=0.13)
    # leitmotiv em sinos de vidro (versão frígia, lenta)
    for rb, beat, m, d in motif:
        lo.put("mel", glass(float(mtof(m)), 6.0, atk=0.03, tau=2.8), T(b0 + rb, beat), pan=float(np.clip((m - 76) / 20.0, -0.5, 0.5)),
               gain=0.12)
        if k in (2, 3):  # eco oitava abaixo mais suave perto do pico
            lo.put("mel", glass(float(mtof(m - 12)), 6.0, atk=0.05, tau=2.8), T(b0 + rb, beat) + 0.02, gain=0.05)
    # coração micelial: lub-dub por compasso
    for bb in range(b0, b0 + 4):
        lo.put("heart", thump(92, 44, 0.5, 0.12), T(bb), gain=hb)
        lo.put("heart", thump(80, 42, 0.38, 0.09), T(bb) + 0.72, gain=hb * 0.65)

# drone principal em Ré (periodico): D1 e D2 com batimento
d1 = lo.drone(36.71, harmonics=((1, 1.0), (2, 0.55), (3, 0.18)), beat_cents=6.0)
d2 = lo.drone(73.42, harmonics=((1, 0.6), (2, 0.2)), beat_cents=5.0, am=((2, 0.15, 0.7), (7, 0.07, 2.2)))
lo.put("drone", d1 + 0.6 * d2, 0.0, gain=0.085)

# ---------------------------------------------------------------- texturas
tt = lo.t()
for pan, seed in ((-1.0, 0), (1.0, 1)):
    rumble = lo.pnoise(40, 260) * (0.55 + 0.25 * np.sin(2 * np.pi * 2 * tt / L + seed) + 0.1 * np.sin(2 * np.pi * 7 * tt / L))
    air = lo.pnoise(3500, 9000) * (0.25 + 0.2 * np.sin(2 * np.pi * 5 * tt / L + seed))
    th = (pan + 1) * np.pi / 4
    sig = 0.030 * rumble + 0.005 * air
    lo.put("tex", np.stack([sig * np.cos(th), sig * np.sin(th)]), 0.0)

r = lo.rng


def chord_at(t):
    for (_, t0, t1, midis) in SCHED:
        if t0 <= t % L < t1:
            return midis[:-5]
    return SCHED[0][3][:-5]


# sinais da Rede: pings de seno viajando pelo estéreo, sempre em notas do acorde
t = 1.0
while t < L:
    pad = chord_at(t)
    if r.random() < 0.7:
        m = int(r.choice(pad)) + 24
        lo.put("net", glass(float(mtof(m)), 1.6, atk=0.003, tau=0.38), t, pan=0.85 * np.sin(2 * np.pi * t / 17.0), gain=0.050)
    t += 1.0 + (0.5 if r.random() < 0.35 else 0.0)

# gotas/esporos raros, mais agudos
t = 3.0
while t < L:
    pad = chord_at(t)
    m = int(r.choice(pad)) + 36
    lo.put("spark", glass(float(mtof(m)), 2.4, atk=0.004, tau=0.5), t, pan=float(r.uniform(-0.9, 0.9)), gain=0.040)
    t += r.exponential(3.0) + 1.0

# sussurros da Rede (2 por acorde)
for k in range(6):
    for j, (beat_off, vw) in enumerate(((6.5, "o"), (11.0, "u" if k % 2 else "a"))):
        t = T(1 + 4 * k) + beat_off
        lo.put("fx", whisper(3.4, vw, seed=11 * k + j), t, pan=(-0.6, 0.6)[(k + j) % 2], gain=0.055)

# viradas: vidro invertido + impacto no pico (acorde 3) e riser final para o loop
for tb, ns in ((T(9), (78, 87)), (T(1), (74, 81)), (T(13), (77,)), (T(17), (74,)), (T(21), (76,))):
    for j, n in enumerate(ns):
        lo.put("fx", rev_glass(float(mtof(n)), 3.2), tb - 3.2, pan=(-0.3, 0.3)[j % 2], gain=0.13)
lo.put("fx", riser(BAR * 2.0, 300, 6500, seed=8), T(23, 1), gain=0.038)
lo.put("heart", thump(70, 34, 2.4, 0.5), T(9), gain=0.50)

if "--perigo" in sys.argv:
    # Camada de perigo: mesmo comprimento/andamento/acordes, toca sincronizada por cima (inimigos em perseguição).
    lp2 = Loop(N, seed=lo.rng.integers(1 << 30))
    chords = [(lambda e: (e[1], e[2], e[3][:-2], e[3][-2]))(e) for e in SCHED]
    spec2 = danger_layer(lp2, BEAT, chords, seed=7, swing=0.0)
    y2 = master(lp2.render(spec2), OUT + ".tmp.wav", target_lufs=-24.0)
    save_wav(y2, OUT)
    check_loop(OUT, "perigo")
    sys.exit(0)

spec = {
    "pad": dict(rev=(4.2, 5000, 0.36)),
    "glassp": dict(rev=(5.0, 6500, 0.50)),
    "choir": dict(rev=(4.8, 4000, 0.55)),
    "sub": dict(),
    "drone": dict(),
    "mel": dict(rev=(4.2, 6500, 0.45), delay=(1.5 * BEAT, 0.38, 0.40)),
    "heart": dict(rev=(2.0, 3000, 0.25)),
    "tex": dict(rev=(2.4, 6000, 0.10)),
    "net": dict(rev=(3.6, 7500, 0.45), delay=(0.75 * BEAT, 0.40, 0.30)),
    "spark": dict(rev=(3.6, 8000, 0.45), delay=(1.5 * BEAT, 0.42, 0.35)),
    "fx": dict(rev=(5.0, 6500, 0.52)),
}
mix = lo.render(spec)
for name, buf in lo.stems.items():
    print(f"  stem {name:7s} rms {20 * np.log10(np.sqrt((buf.astype(float) ** 2).mean()) + 1e-9):6.1f} dB")
y = master(mix, OUT + ".tmp.wav", target_lufs=-22.0)
save_wav(y, OUT)
check_loop(OUT, "rede")
chord_check(OUT, SCHED)
