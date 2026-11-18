#!/usr/bin/env python3
"""Menu principal: loop de 45.9626 s (mesma duração do vídeo do pan verde -> roxo -> verde)."""
import sys
import numpy as np
from engine import *

OUT = sys.argv[1]
VIDEO_DUR = 45.9626
N = int(round(VIDEO_DUR * SR))
lo = Loop(N, seed=11)
L = lo.L
BEAT = L / 64.0
BAR = 4 * BEAT


def T(bar, beat=1.0):
    return ((bar - 1) * 4 + (beat - 1)) * BEAT


def purple(t):
    """0 = floresta verde (início/fim do vídeo), 1 = cogumelos roxos (meio do vídeo)."""
    return smoothstep(0.5 - 0.5 * np.cos(2 * np.pi * np.asarray(t) / L), 0.30, 0.80)


# ---------------------------------------------------------------- harmonia (2 compassos por acorde)
CH = [
    # nome,            bars, baixo, pad
    ("Dm9",            2, 38, [50, 53, 57, 60, 64]),
    ("Bbmaj7",         2, 34, [58, 62, 65, 69]),
    ("Gadd9/6",        2, 43, [55, 59, 62, 64, 69]),
    ("Ebmaj7/D",       2, 38, [51, 55, 58, 62, 67]),
    ("D7b9 (F#dim7)",  2, 38, [54, 57, 60, 63, 66]),
    ("Bbmaj7#11/D",    2, 38, [58, 62, 65, 69, 76]),
    ("Fmaj9",          2, 41, [53, 57, 60, 64, 67]),
    ("A7sus4",         2, 45, [52, 55, 62, 64, 69]),
]
bar = 1
CHORD_AT = []  # (t0, t1, pad)
for k, (name, nb, bass, pad) in enumerate(CH):
    t0, dur = T(bar), nb * BAR
    CHORD_AT.append((t0, t0 + dur, pad))
    mid = t0 + dur / 2
    P = float(purple(mid))
    # pad quente (serra detunada), mais brilhante no roxo; dois lados para largura
    for j, m in enumerate(pad):
        f = float(mtof(m))
        for side, pan in ((0, -0.55), (1, 0.55)):
            lo.put("pad", pad_note(f, dur + 0.4, atk=1.7, rel=2.6, bright=lambda tt: 0.22 + 0.65 * purple(tt),
                                   t0=t0 - 0.2, seed=100 * k + 10 * j + side), t0 - 0.2, pan=pan, gain=0.050)
    # pad de vidro (roxo): sinos puros uma oitava acima
    if P > 0.25:
        for j, m in enumerate(pad[1:]):
            lo.put("glassp", sine_pad(float(mtof(m + 12)), dur + 0.3, atk=2.0, rel=3.0, seed=7 * k + j), t0 - 0.2,
                   pan=(-0.7, 0.7, -0.3, 0.3)[j % 4], gain=0.050 * P)
    # coro 'ooh' orgânico no verde
    if P < 0.8:
        for j, m in enumerate([pad[2], pad[-1]]):
            lo.put("choir", choir_note(float(mtof(m)), dur, "o" if j == 0 else "u", atk=1.8, rel=2.6, seed=31 * k + j),
                   t0, pan=(-0.4, 0.4)[j], gain=0.16 * (1 - P))
    # sub (baixo)
    lo.put("sub", sub(float(mtof(bass)), dur + 0.2, atk=0.9, rel=1.9), t0 - 0.1, gain=0.09)
    bar += nb

# ---------------------------------------------------------------- melodia (leitmotiv do druida)
# (compasso, [(tempo, midi, duracao_em_tempos)])
MEL = [
    (1, [(1, 62, 1), (2, 65, 1), (3, 69, 1.5), (4.5, 67, .5)]), (2, [(1, 64, 2), (3, 62, 2)]),
    (3, [(1, 65, 1), (2, 69, 1), (3, 74, 1.5), (4.5, 72, .5)]), (4, [(1, 69, 2), (3, 65, 2)]),
    (5, [(1, 74, 1), (2, 71, 1), (3, 76, 1.5), (4.5, 74, .5)]), (6, [(1, 71, 2), (3, 67, 2)]),
    (7, [(1, 67, 2), (3, 70, 2)]), (8, [(1, 74, 2), (3, 75, 2)]),
    (9, [(1, 78, 2), (1.5, 81, 2), (2, 84, 2), (2.5, 87, 2.5), (3.5, 81, 2)]), (10, [(1, 84, 2), (3, 78, 2)]),
    (11, [(1, 69, 1), (2, 74, 1), (3, 76, 1.5), (4.5, 77, .5)]), (12, [(1, 74, 2), (3, 69, 2)]),
    (13, [(1, 69, 1), (2, 72, 1), (3, 76, 1.5), (4.5, 74, .5)]), (14, [(1, 72, 2), (3, 69, 2)]),
    (15, [(1, 76, 1), (2, 74, 1), (3, 69, 1.5), (4.5, 67, .5)]), (16, [(1, 64, 2), (3, 69, 2)]),
]
for b, notes in MEL:
    for beat, m, d in notes:
        t = T(b, beat)
        P = float(purple(t))
        f = float(mtof(m))
        pan = float(np.clip((m - 70) / 28.0, -0.5, 0.5))
        if 1 - P > 0.06:
            lo.put("mel", kalimba(f, 2.8, seed=int(t * 10)), t, pan=pan, gain=0.090 * (1 - P))
        if P > 0.06:
            lo.put("mel", glass(f, 5.0, atk=0.03, tau=2.2), t, pan=-pan, gain=0.085 * P)

# harpa suave nas contratempos (só no verde)
for k, (t0, t1, pad) in enumerate(CHORD_AT):
    b0 = 1 + 2 * k
    for bb in (b0, b0 + 1):
        for beat, idx in ((1.5, 2), (2.5, 4), (3.5, 3), (4.5, 1)):
            t = T(bb, beat)
            P = float(purple(t))
            if P < 0.7:
                m = pad[idx % len(pad)] + 12
                lo.put("harp", harp(float(mtof(m)), 3.0, seed=int(t * 7)), t, pan=((idx % 3) - 1) * 0.5, gain=0.070 * (1 - P))

# ---------------------------------------------------------------- texturas
tt = lo.t()
Pt = purple(tt)
G = 1 - Pt
# vento (verde) e brisa grave (roxo)
for pan, seed in ((-1.0, 0), (1.0, 1)):
    wnd = lo.pnoise(180, 900) * (0.5 + 0.3 * np.sin(2 * np.pi * 3 * tt / L + seed) + 0.2 * np.sin(2 * np.pi * 5 * tt / L + 2 * seed))
    leaf = lo.pnoise(2500, 7000) * (0.25 + 0.2 * np.sin(2 * np.pi * 4 * tt / L + 1.3 * seed)) * G
    rumble = lo.pnoise(40, 260) * (0.5 + 0.2 * np.sin(2 * np.pi * 2 * tt / L)) * Pt
    th = (pan + 1) * np.pi / 4
    sig = (0.016 * wnd * (0.55 + 0.45 * G) + 0.010 * leaf + 0.030 * rumble)
    lo.put("tex", np.stack([sig * np.cos(th), sig * np.sin(th)]), 0.0)

# grilos (verde)
r = lo.rng
for fc, period, off, pan in ((4350, 0.93, 0.0, -0.6), (5050, 1.31, 0.4, 0.55), (3900, 1.67, 0.9, 0.1)):
    t = off
    while t < L:
        g = (1 - float(purple(t))) ** 2
        if g > 0.05:
            lo.put("cric", cricket(fc * (1 + 0.01 * r.standard_normal()), groups=int(r.integers(2, 4)), seed=int(t * 13)), t,
                   pan=pan, gain=0.075 * g)
        t += period * r.uniform(0.9, 1.15)

# vaga-lumes (verde) e brilhos de esporo (roxo): sempre notas do acorde corrente
def chord_at(t):
    for (t0, t1, pad) in CHORD_AT:
        if t0 <= t % L < t1:
            return pad
    return CHORD_AT[0][2]

t = 0.6
while t < L:
    pad = chord_at(t)
    P = float(purple(t))
    m = int(r.choice(pad)) + 12 * int(r.choice([2, 2, 3]))
    pan = r.uniform(-0.8, 0.8)
    if r.random() > P:
        lo.put("spark", glass(float(mtof(m)), 2.4, atk=0.004, tau=0.7), t, pan=pan, gain=0.050 * (1 - P))
    else:
        lo.put("spark", glass(float(mtof(m + 12)), 3.2, atk=0.01, tau=1.3), t, pan=pan, gain=0.050 * P)
    t += r.exponential(1.15) + 0.35

# coração micelial (roxo): "lub-dub" a cada compasso
for b in range(1, 17):
    t = T(b)
    P = float(purple(t))
    if P > 0.15:
        lo.put("heart", thump(92, 44, 0.45, 0.11), t, gain=0.30 * P)
        lo.put("heart", thump(80, 42, 0.35, 0.09), t + 0.62 * BEAT * 1.0, gain=0.20 * P)

# sussurros de micélio (roxo)
for b, beat, pan, vw in ((8, 2.0, -0.6, "o"), (9, 3.0, 0.6, "u"), (10, 3.5, -0.2, "a"), (11, 1.5, 0.4, "o")):
    t = T(b, beat)
    lo.put("fx", whisper(3.2, vw, seed=b), t, pan=pan, gain=0.050 * float(purple(t)))

# transição para o pico roxo (compasso 9): riser + vidro invertido + impacto grave
t_peak = T(9)
lo.put("fx", riser(BAR * 1.2, 400, 7000, seed=2), t_peak - BAR * 1.2, gain=0.050)
lo.put("fx", rev_glass(float(mtof(81)), 2.6), t_peak - 2.6, pan=-0.3, gain=0.17)
lo.put("fx", rev_glass(float(mtof(87)), 2.6), t_peak - 2.6, pan=0.3, gain=0.12)
lo.put("heart", thump(70, 34, 1.6, 0.35), t_peak, gain=0.55)
# retorno ao verde: pequeno brilho de vidro invertido no fim do loop (resolve no início)
t_end = T(16, 3)
lo.put("fx", rev_glass(float(mtof(74)), 2.2), t_end, pan=0.0, gain=0.10)

# ---------------------------------------------------------------- mix
spec = {
    "pad": dict(gain=1.0, rev=(3.8, 5500, 0.34)),
    "glassp": dict(gain=1.0, rev=(5.0, 6500, 0.50)),
    "choir": dict(gain=1.0, rev=(4.6, 4500, 0.55)),
    "sub": dict(gain=1.0),
    "mel": dict(gain=1.0, rev=(3.4, 6500, 0.38), delay=(0.75 * BEAT, 0.36, 0.42)),
    "harp": dict(gain=1.0, rev=(3.0, 6500, 0.40)),
    "tex": dict(gain=1.0, rev=(2.4, 6000, 0.10)),
    "cric": dict(gain=1.0, rev=(2.0, 7000, 0.18)),
    "spark": dict(gain=1.0, rev=(3.6, 8000, 0.45), delay=(0.75 * BEAT, 0.42, 0.35)),
    "heart": dict(gain=1.0, rev=(1.8, 3000, 0.22)),
    "fx": dict(gain=1.0, rev=(4.6, 6500, 0.50)),
}
mix = lo.render(spec)
for name, buf in lo.stems.items():
    print(f"  stem {name:7s} rms {20*np.log10(np.sqrt((buf.astype(float)**2).mean())+1e-9):6.1f} dB")
y = master(mix, OUT + ".tmp.wav", target_lufs=-19.0)
save_wav(y, OUT)
check_loop(OUT, "menu")
