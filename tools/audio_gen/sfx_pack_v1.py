#!/usr/bin/env python3
"""Mushrooms Deserve to Die - pack de SFX procedurais (placeholder de alta qualidade)."""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
import sys
OUT = sys.argv[1] if len(sys.argv) > 1 else "mdtd_sfx_v1"
rng = np.random.default_rng(1337)
TWO_PI = 2 * np.pi


# ---------------------------------------------------------------- utilidades
def T(d):
    return np.arange(int(SR * d)) / SR


def N(d):
    return rng.standard_normal(int(SR * d))


def _sos(kind, freq, order):
    nyq = SR / 2
    if kind == "bp":
        lo, hi = freq
        return signal.butter(order, [max(lo, 20) / nyq, min(hi, nyq * 0.95) / nyq], btype="band", output="sos")
    return signal.butter(order, min(max(freq, 20), nyq * 0.95) / nyq, btype=kind, output="sos")


def lp(x, f, o=2):
    return signal.sosfilt(_sos("low", f, o), x)


def hp(x, f, o=2):
    return signal.sosfilt(_sos("high", f, o), x)


def bp(x, lo, hi, o=2):
    return signal.sosfilt(_sos("bp", (lo, hi), o), x)


def env(d, atk=0.002, tau=0.05):
    t = T(d)
    return np.minimum(1, t / max(atk, 1e-4)) * np.exp(-t / tau)


def tone(f):
    """Seno a partir de um array de frequência instantânea."""
    return np.sin(TWO_PI * np.cumsum(f) / SR)


def sweep(d, f0, f1):
    t = T(d)
    return tone(f0 * (f1 / f0) ** (t / d))


def svf_bp(x, fc, q=2.0):
    """Passa-banda variável no tempo (state variable filter)."""
    n = len(x)
    fc = np.broadcast_to(np.asarray(fc, dtype=float), (n,))
    f = 2 * np.sin(np.pi * np.clip(fc, 20, SR / 6) / SR)
    qq = 1.0 / q
    out = np.zeros(n)
    low = band = 0.0
    for i in range(n):
        low += f[i] * band
        high = x[i] - low - qq * band
        band += f[i] * high
        out[i] = band
    return out


def rms(x):
    return np.sqrt(np.mean(x ** 2) + 1e-12)


def reverb(x, decay=0.8, mix=0.3, damp=5000):
    n = int(SR * decay * 1.6)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / SR / (decay / 4.5))
    ir = lp(ir, damp)
    ir[: int(0.004 * SR)] *= 0.1
    wet = signal.fftconvolve(x, ir)
    dry = np.pad(x, (0, len(wet) - len(x)))
    wet = wet / (np.max(np.abs(wet)) + 1e-9) * np.max(np.abs(x))
    return dry + mix * wet * 1.4


def mixdown(parts):
    L = max(int(at * SR) + len(x) for x, at, g in parts)
    y = np.zeros(L)
    for x, at, g in parts:
        i = int(at * SR)
        y[i:i + len(x)] += g * x
    return y


def click(f=3000, tau=0.005, d=0.05, partial=2.3):
    t = T(d)
    return (np.sin(TWO_PI * f * t) + 0.5 * np.sin(TWO_PI * f * partial * t)) * np.exp(-t / tau)


def bell(f, d=1.2, tau=0.5, partials=((1, 1.0), (2.76, 0.45), (5.4, 0.22), (8.93, 0.1))):
    t = T(d)
    y = np.zeros_like(t)
    for r, a in partials:
        y += a * np.sin(TWO_PI * f * r * t) * np.exp(-t * (r ** 0.7) / tau)
    y *= np.minimum(1, t / 0.002)
    return y


def soft_clip(x, drive=2.0):
    return np.tanh(x * drive) / np.tanh(drive)


VOW = {
    "a": [(800, 1.0), (1200, 0.5), (2800, 0.25)],
    "o": [(450, 1.0), (800, 0.5), (2830, 0.15)],
    "u": [(325, 1.0), (700, 0.4), (2700, 0.1)],
    "e": [(530, 1.0), (1840, 0.5), (2480, 0.2)],
    "i": [(270, 1.0), (2290, 0.4), (3010, 0.2)],
    "uh": [(600, 1.0), (1170, 0.5), (2400, 0.2)],
}


def voice(d, f0, vowel="a", vib=(5.5, 0.01), jitter=0.005, breath=0.08, atk=0.02, rel=0.05, shift=1.0):
    n = int(SR * d)
    t = np.arange(n) / SR
    f0a = f0(t) if callable(f0) else np.full(n, float(f0))
    j = lp(rng.standard_normal(n), 30)
    j /= (np.std(j) + 1e-9)
    f = f0a * (1 + vib[1] * np.sin(TWO_PI * vib[0] * t + rng.uniform(0, 6.28))) * (1 + jitter * j)
    ph = np.cumsum(f) / SR
    src = lp(2 * (ph % 1) - 1, 5000, 1)
    nz = rng.standard_normal(n)
    y = np.zeros(n)
    for fc, g in VOW[vowel]:
        fc *= shift
        y += g * bp(src, fc * 0.92, fc * 1.08) + breath * g * bp(nz, fc * 0.9, fc * 1.1) * 3
    e = np.minimum(1, t / atk) * np.minimum(1, np.maximum(d - t, 0) / rel)
    return y * e


def fm_squeal(d, f0, f1, ratio=1.7, index=3.0, vib=(35, 0.04)):
    t = T(d)
    f = f0 * (f1 / f0) ** (t / d)
    f = f * (1 + vib[1] * np.sin(TWO_PI * vib[0] * t))
    ph = np.cumsum(f) / SR
    return np.sin(TWO_PI * ph + index * np.sin(TWO_PI * ph * ratio))


def crackles(d, density, tau_range=(0.002, 0.005), f_range=(2000, 5500), decay=None):
    """Estalos estilo quitina quebrando; densidade em cliques/seg."""
    y = np.zeros(int(SR * d) + int(0.06 * SR))
    t = 0.0
    while t < d:
        dens = density * (np.exp(-t / decay) if decay else 1.0)
        if dens < 15:  # evita estalos soltos no fim da cauda
            break
        t += rng.exponential(1.0 / dens)
        if t >= d:
            break
        c = click(rng.uniform(*f_range), rng.uniform(*tau_range)) * rng.uniform(0.3, 1.0)
        i = int(t * SR)
        y[i:i + len(c)] += c
    return y[: int(SR * d)]


def finish(x, peak=0.8, fade_in=0.001, fade_out=0.012, loop=False):
    x = np.asarray(x, dtype=float)
    x = x - np.mean(x)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    if not loop:
        # corta a cauda inaudível (abaixo de ~-54 dB do pico), mantendo 30 ms de folga
        above = np.where(np.abs(x) > 0.002 * peak)[0]
        if len(above):
            x = x[: min(len(x), above[-1] + int(0.03 * SR))]
        ni, no = int(fade_in * SR), int(fade_out * SR)
        if ni:
            x[:ni] *= np.linspace(0, 1, ni)
        if no:
            x[-no:] *= np.linspace(1, 0, no)
    return x


REGISTRY = []


def save(folder, name, x, peak=0.8, loop=False, note=""):
    path = os.path.join(OUT, folder)
    os.makedirs(path, exist_ok=True)
    y = finish(x, peak, loop=loop)
    wavfile.write(os.path.join(path, name + ".wav"), SR, (y * 32767).astype(np.int16))
    REGISTRY.append((folder, name, len(y) / SR, peak, loop, note))


# ================================================================ PROTAGONISTA
def footstep_grass(i):
    d = 0.17
    thump = sweep(d, rng.uniform(90, 120), 55) * env(d, 0.002, 0.03) * rng.uniform(0.5, 0.8)
    rustle = bp(N(d), rng.uniform(1800, 2600), rng.uniform(5000, 7500)) * env(d, 0.006, 0.045)
    blades = hp(N(d), 4500) * env(d, 0.01, 0.03) * 0.25
    return thump + rustle * 0.9 + blades


def footstep_dirt(i):
    d = 0.16
    thump = sweep(d, rng.uniform(80, 105), 45) * env(d, 0.002, 0.04) * 0.9
    grit = bp(N(d), 600, rng.uniform(2200, 3200)) * env(d, 0.003, 0.03)
    pebble = crackles(d, 120, f_range=(2500, 4500), decay=0.04) * 0.4
    return thump + grit * 0.8 + pebble


def jump():
    d = 0.2
    t = T(d)
    swoosh = svf_bp(N(d), 500 + 2500 * (t / d), 1.5) * np.sin(np.pi * t / d) ** 1.5
    leaf = hp(N(d), 3500) * env(d, 0.01, 0.06) * 0.25
    return swoosh / (np.max(np.abs(swoosh)) + 1e-9) + leaf + sweep(d, 180, 420) * env(d, 0.01, 0.06) * 0.12


def land():
    d = 0.26
    thump = sweep(d, 110, 40) * env(d, 0.002, 0.07)
    body = lp(N(d), 1600) * env(d, 0.002, 0.05) * 0.6
    leaf = bp(N(d), 2000, 7000) * env(d, 0.01, 0.08) * 0.4
    return thump + body + leaf


def dash():
    d = 0.32
    t = T(d)
    fc = np.where(t < 0.1, 300 + 3700 * (t / 0.1) ** 1.2, 4000 - 3300 * ((t - 0.1) / (d - 0.1)))
    air = svf_bp(N(d), fc, 1.3)
    air = air / (np.max(np.abs(air)) + 1e-9) * (np.sin(np.pi * np.clip(t / d, 0, 1)) ** 1.2)
    low = sweep(d, 260, 95) * env(d, 0.01, 0.12) * 0.35
    push = sweep(0.1, 140, 55) * env(0.1, 0.002, 0.03) * 0.7
    leaf = hp(N(d), 5000) * env(d, 0.02, 0.1) * 0.15
    return mixdown([(air, 0, 1.0), (low, 0, 1.0), (push, 0, 1.0), (leaf, 0, 1.0)])


def dash_blocked():
    """Dormência de input (Azurescens): dash 'engasga' e não sai."""
    d = 0.24
    t = T(d)
    f = 120 * (0.6 ** (t / d))
    saw = 2 * ((np.cumsum(f) / SR) % 1) - 1
    buzz = lp(saw, 420) * (0.55 + 0.45 * np.sin(TWO_PI * 32 * t)) * env(d, 0.004, 0.08)
    thud = sweep(0.08, 150, 60) * env(0.08, 0.001, 0.025)
    return mixdown([(buzz, 0, 1.0), (thud, 0, 0.8), (lp(N(0.05), 900) * env(0.05, 0.001, 0.02), 0, 0.4)])


def dash_recharge():
    parts = []
    for k, f in enumerate([880, 1318.5, 1760]):
        parts.append((bell(f, 0.35, 0.18, ((1, 1), (2, 0.3), (3.01, 0.1))), k * 0.045, 0.7))
    return mixdown(parts)


def swing(i):
    d = 0.24
    t = T(d)
    peak_t = 0.07 + 0.01 * i
    fc = np.where(t < peak_t, 500 + (5200 + 400 * i) * (t / peak_t) ** 1.1, 5700 - 3200 * ((t - peak_t) / (d - peak_t)))
    air = svf_bp(N(d), fc, 1.6 + 0.3 * i)
    air = air / (np.max(np.abs(air)) + 1e-9) * np.exp(-((t - peak_t) / 0.07) ** 2)
    shing = (np.sin(TWO_PI * (4200 + 300 * i) * t) + 0.6 * np.sin(TWO_PI * (6100 + 200 * i) * t)) * env(d, 0.01, 0.045) * 0.12
    body = lp(N(d), 900) * np.exp(-((t - peak_t) / 0.06) ** 2) * 0.35
    return air + shing + body


def thorn_sprout():
    d = 0.16
    t = T(d)
    f = 150 * (4.8 ** (t / 0.06)) * (t < 0.06) + 720 * (t >= 0.06)
    creak = np.sin(TWO_PI * np.cumsum(f) / SR) * (0.6 + 0.4 * np.sin(TWO_PI * 90 * t)) * env(d, 0.002, 0.04)
    snap = click(2400, 0.004) * 0.9
    wood = crackles(d, 220, f_range=(1500, 3500), decay=0.05) * 0.5
    sap = lp(N(d), 1800) * env(d, 0.004, 0.03) * 0.25
    return mixdown([(creak, 0, 0.6), (snap, 0, 0.7), (wood, 0, 0.7), (sap, 0, 1.0)])


def hit_enemy(i):
    d = 0.3
    base = [210, 250, 180][i]
    thump = sweep(d, base, 55) * env(d, 0.001, 0.07)
    slap = bp(N(d), 700, 5200) * env(d, 0.001, 0.028)
    crunch = crackles(d, 500, tau_range=(0.002, 0.006), f_range=(1200, 4200), decay=0.035) * 0.7
    wet = lp(N(d), 2500) * env(d, 0.001, 0.05) * 0.4
    y = mixdown([(thump, 0, 0.9), (slap, 0, 0.9), (crunch, 0, 1.0), (wet, 0, 1.0)])
    return soft_clip(y / (np.max(np.abs(y)) + 1e-9), 1.8)


def hit_heavy():
    d = 0.6
    boom = sweep(d, 140, 38) * env(d, 0.001, 0.18)
    slap = bp(N(d), 400, 6000) * env(d, 0.001, 0.05)
    crack = crackles(d, 700, f_range=(900, 3800), decay=0.08) * 0.8
    rumble = lp(N(d), 400) * env(d, 0.005, 0.2) * 0.8
    shock = hp(N(0.12), 2500) * env(0.12, 0.001, 0.03)
    y = mixdown([(boom, 0, 1.0), (slap, 0, 1.0), (crack, 0, 1.0), (rumble, 0, 0.8), (shock, 0, 0.5)])
    return soft_clip(y / (np.max(np.abs(y)) + 1e-9), 2.2)


def player_hurt(i):
    d = 0.3
    f0s, f0e = [(210, 130), (180, 105)][i]
    v = voice(d, lambda t: f0s + (f0e - f0s) * (t / d), "uh" if i == 0 else "a", atk=0.012, rel=0.12, breath=0.18, jitter=0.02)
    v *= env(d, 0.012, 0.2)
    leaf = bp(N(d), 2500, 7000) * env(d, 0.003, 0.05) * 0.5
    thump = sweep(0.1, 160, 60) * env(0.1, 0.001, 0.03) * 0.6
    return soft_clip(mixdown([(v, 0, 1.0), (leaf, 0, 0.5), (thump, 0, 0.6)]) / 2.0, 1.5)


def player_death():
    d = 1.2
    t = T(d)
    v = voice(d, lambda t: 230 * np.exp(-1.0 * t), "a", atk=0.02, rel=0.4, breath=0.3, jitter=0.03, vib=(5, 0.02))
    v *= np.exp(-t / 0.55)
    # folhas se desfazendo
    flutter = hp(N(d), 3500) * (np.abs(lp(N(d), 18)) / 0.05).clip(0, 1) * np.exp(-t / 0.6) * 0.25
    thump = sweep(0.25, 120, 40) * env(0.25, 0.002, 0.08) * 0.7
    y = mixdown([(v, 0, 1.0), (flutter, 0, 1.0), (thump, 0, 0.8)])
    return reverb(y, 0.6, 0.25)


def thorn_counter():
    d = 0.5
    f = 1900
    clink = bell(f, d, 0.12, ((1, 1), (1.51, 0.6), (2.32, 0.45), (3.7, 0.3), (5.1, 0.15)))
    burst = bp(N(d), 3000, 9000) * env(d, 0.001, 0.02)
    spine = crackles(0.2, 300, f_range=(3000, 6500), decay=0.06) * 0.6
    return mixdown([(clink, 0, 0.8), (burst, 0, 0.7), (spine, 0.01, 0.7), (sweep(0.1, 250, 90) * env(0.1, 0.001, 0.03), 0, 0.5)])


# ================================================================ INIMIGOS (Formiga Cordyceps)
def ant_idle():
    d = 0.9
    y = np.zeros(int(SR * d))
    t = 0.05
    while t < d - 0.1:
        n = rng.integers(1, 6)
        for k in range(n):
            c = click(rng.uniform(2200, 4200), rng.uniform(0.004, 0.008)) * rng.uniform(0.4, 1.0)
            i = int((t + k * rng.uniform(0.012, 0.02)) * SR)
            if i + len(c) < len(y):
                y[i:i + len(c)] += c
        t += rng.uniform(0.12, 0.3)
    gurgle = voice(d, 68, "uh", breath=0.5, jitter=0.05, atk=0.15, rel=0.2) * 0.12
    return mixdown([(y, 0, 1.0), (lp(gurgle, 800), 0, 1.0)])


def ant_step(i):
    d = 0.14
    c1 = click(rng.uniform(2800, 3600), 0.004)
    c2 = click(rng.uniform(2200, 3000), 0.004) * 0.7
    scr = hp(N(d), 3500) * env(d, 0.002, 0.015) * 0.35
    thump = sweep(0.06, 200, 90) * env(0.06, 0.001, 0.02) * 0.35
    return mixdown([(c1, 0, 1.0), (c2, 0.045 + 0.01 * i, 1.0), (scr, 0, 1.0), (thump, 0, 1.0)])


def ant_melee():
    d = 0.45
    t = T(d)
    pt = 0.12
    fc = np.where(t < pt, 700 + 4800 * (t / pt), 5500 - 3800 * ((t - pt) / (d - pt)))
    air = svf_bp(N(d), fc, 1.8)
    air = air / (np.max(np.abs(air)) + 1e-9) * np.exp(-((t - pt) / 0.09) ** 2)
    scr = fm_squeal(0.3, 1700, 850, 1.7, 3.5) * env(0.3, 0.01, 0.12) * 0.35
    clk = click(3000, 0.005) * 0.9
    rake = crackles(0.2, 250, f_range=(1800, 4800), decay=0.07) * 0.5
    return mixdown([(air, 0, 1.0), (scr, 0.03, 1.0), (clk, 0.08, 1.0), (rake, 0.11, 1.0)])


def ant_spore_shot():
    d = 0.5
    t = T(d)
    pop = sweep(0.12, 220, 1100) * env(0.12, 0.001, 0.03)
    fc = 350 + 1500 * np.clip(t / 0.25, 0, 1)
    whoomp = svf_bp(N(d), fc, 1.2)
    whoomp = whoomp / (np.max(np.abs(whoomp)) + 1e-9) * env(d, 0.01, 0.12)
    hiss = hp(N(d), 3500) * env(d, 0.03, 0.18) * 0.25
    return mixdown([(pop, 0, 0.8), (whoomp, 0, 1.0), (hiss, 0, 1.0)])


def ant_spore_cloud():
    d = 0.6
    t = T(d)
    n = bp(N(d), 500, 4500)
    w = np.exp(-t / 0.15)  # começa brilhante e vai abafando
    puff = (w * lp(n, 4000) + (1 - w) * lp(n, 1500)) * np.minimum(1, t / 0.04) * np.exp(-t / 0.2)
    pops = crackles(d, 60, f_range=(800, 1800), tau_range=(0.006, 0.012), decay=0.2) * 0.4
    return puff + pops


def ant_dive():
    d = 0.6
    t = T(d)
    whistle = fm_squeal(d, 2600, 480, 2.0, 1.2, vib=(11, 0.02)) * (0.3 + 0.7 * np.minimum(1, t / 0.15)) * 0.4
    fc = 4500 - 3600 * (t / d)
    wind = svf_bp(N(d), fc, 1.4)
    wind = wind / (np.max(np.abs(wind)) + 1e-9) * (0.3 + 0.7 * (t / d))
    scr = fm_squeal(0.3, 1900, 1100, 1.5, 3.0) * env(0.3, 0.01, 0.2) * 0.2
    return mixdown([(whistle, 0, 1.0), (wind, 0, 0.8), (scr, 0, 1.0)])


def ant_dive_impact():
    d = 0.9
    boom = sweep(d, 130, 32) * env(d, 0.001, 0.2)
    dirt = lp(N(d), 2200) * env(d, 0.002, 0.18) * 0.9
    crunch = crackles(d, 600, f_range=(900, 3500), decay=0.1) * 0.8
    dust = bp(N(d), 1500, 7000) * env(d, 0.02, 0.28) * 0.35
    spores = crackles(0.4, 80, f_range=(700, 1600), tau_range=(0.008, 0.015), decay=0.12) * 0.3
    y = mixdown([(boom, 0, 1.0), (dirt, 0, 0.9), (crunch, 0, 1.0), (dust, 0.02, 1.0), (spores, 0.1, 1.0)])
    return soft_clip(y / (np.max(np.abs(y)) + 1e-9), 2.0)


def ant_hurt():
    d = 0.3
    sq = fm_squeal(d, 2500, 1500, 1.6, 3.2, vib=(40, 0.05)) * env(d, 0.005, 0.12)
    cl = click(3300, 0.005) + 0.7 * click(2400, 0.005)
    return mixdown([(sq, 0, 0.6), (cl, 0, 0.8), (crackles(0.15, 300, decay=0.05) * 0.5, 0.02, 1.0)])


def ant_death():
    d = 1.1
    t = T(d)
    sq = fm_squeal(0.8, 2300, 160, 1.7, 3.8, vib=(30, 0.06)) * env(0.8, 0.005, 0.35)
    crack = crackles(d, 320, tau_range=(0.003, 0.008), f_range=(1200, 4500), decay=0.35)
    pop = sweep(0.2, 520, 90) * env(0.2, 0.002, 0.05)
    wet = lp(N(0.25), 1800) * env(0.25, 0.002, 0.06)
    puff = bp(N(0.5), 600, 3500) * env(0.5, 0.02, 0.15) * 0.5
    return mixdown([(sq, 0, 0.55), (crack, 0, 0.8), (pop, 0.75, 0.9), (wet, 0.75, 0.6), (puff, 0.78, 0.5)])


def ant_block():
    d = 0.25
    cl = bell(1250, d, 0.04, ((1, 1), (1.9, 0.7), (3.1, 0.5), (4.6, 0.25)))
    burst = bp(N(d), 1000, 6500) * env(d, 0.001, 0.012)
    return mixdown([(cl, 0, 0.9), (burst, 0, 0.8)])


def ant_swarm_loop():
    d = 1.0
    t = T(d)

    def saw(fb, m, k):
        ph = fb * t + fb * m * (1 - np.cos(TWO_PI * k * t)) / (TWO_PI * k)
        return 2 * (ph % 1) - 1

    y = np.zeros_like(t)
    for fb, m, k in [(180, 0.04, 3), (188, 0.05, 4), (195, 0.03, 5), (362, 0.04, 3), (377, 0.05, 2)]:
        y += saw(fb, m, k)
    y *= 1 + 0.55 * np.sin(TWO_PI * 7 * t)
    tiled = np.tile(y, 3)
    tiled = lp(tiled, 2600, 2)
    tiled = bp(tiled, 120, 3200, 1)
    return tiled[len(y):2 * len(y)]


def hatchling():
    d = 0.35
    parts = []
    for k, (a, b) in enumerate([(1300, 2300), (1500, 2600)]):
        sq = fm_squeal(0.14, a, b, 1.3, 1.5, vib=(60, 0.03)) * env(0.14, 0.005, 0.07)
        parts.append((sq, k * 0.17, 0.8))
    return mixdown(parts)


# ================================================================ BOSSES (voz / presença)
def boss_azurescens():
    d = 1.4
    t = T(d)
    v = voice(d, lambda t: 62 - 12 * (t / d), "uh", vib=(3, 0.02), jitter=0.04, breath=0.3, atk=0.12, rel=0.35, shift=0.8)
    v *= (0.65 + 0.35 * np.sin(TWO_PI * 22 * t))  # formigamento/dormência
    sub = sweep(d, 52, 36) * env(d, 0.1, 0.8) * 0.5
    y = lp(v, 1500) + sub
    return soft_clip(y / (np.max(np.abs(y)) + 1e-9), 2.2)


def boss_psilocybe():
    d = 2.2
    t = T(d)
    fc = 900 + 700 * np.sin(TWO_PI * 0.9 * t) + 300 * np.sin(TWO_PI * 5 * t)
    whisper = svf_bp(N(d), fc, 4.0)
    whisper = whisper / (np.max(np.abs(whisper)) + 1e-9)
    swell = np.minimum(1, t / 0.5) * np.minimum(1, (d - t) / 0.6)
    ta = tone(740 * (1 + 0.015 * np.sin(TWO_PI * 4.5 * t)))
    tb = tone(1110 * (1 + 0.02 * np.sin(TWO_PI * 3.7 * t)))
    y = (whisper * 0.8 + 0.18 * ta + 0.1 * tb) * swell
    return reverb(y, 1.0, 0.35)


def boss_claviceps_choir():
    d = 2.4
    t = T(d)
    parts = []
    for f in [146.8, 155.6, 220.0, 233.1, 293.7]:
        v = voice(d, lambda tt, f=f: f * (1 - 0.03 * (tt / d)), "a", vib=(5.3, 0.012), jitter=0.01, breath=0.1, atk=0.4, rel=0.6)
        parts.append((v, rng.uniform(0, 0.08), 0.5))
    y = mixdown(parts)
    return reverb(y, 1.6, 0.45)


def boss_claviceps_false_calm():
    notes = [523.25, 659.25, 783.99, 659.25, 523.25, 392.0]
    parts = []
    for k, f in enumerate(notes):
        parts.append((bell(f, 1.6, 0.7, ((1, 1), (2, 0.25), (3, 0.1))), k * 0.3, 0.6))
    d = 3.2
    pad = (tone(np.full(int(SR * d), 261.6)) + 0.6 * tone(np.full(int(SR * d), 392.0))) * np.minimum(1, T(d) / 0.8) * np.minimum(1, (d - T(d)) / 1.0)
    parts.append((pad, 0, 0.12))
    return reverb(mixdown(parts), 1.4, 0.4)


def boss_phalloides():
    d = 1.5
    v1 = voice(d, lambda t: 520 - 60 * (t / d), "a", vib=(5.5, 0.015), jitter=0.006, breath=0.25, atk=0.12, rel=0.5)
    v2 = voice(d, lambda t: 650 - 70 * (t / d), "o", vib=(5.2, 0.015), jitter=0.006, breath=0.25, atk=0.14, rel=0.5)
    sweetbell = bell(1568, 1.2, 0.5, ((1, 1), (2, 0.3))) * 0.2
    return reverb(mixdown([(v1, 0, 0.6), (v2, 0.03, 0.5), (sweetbell, 0.2, 1.0)]), 0.9, 0.35)


def boss_pantherina():
    d = 1.3
    t = T(d)
    v = voice(d, lambda tt: 170 - 55 * (tt / d), "e", vib=(7, 0.03), jitter=0.05, breath=0.5, atk=0.06, rel=0.4)
    v *= 0.7 + 0.3 * np.sin(TWO_PI * 11 * t)
    hiss = hp(N(d), 4000) * env(d, 0.1, 0.5) * 0.4
    return soft_clip(mixdown([(v, 0, 0.8), (hiss, 0, 1.0)]) / 1.5, 1.6)


def boss_amanita_final():
    d = 3.6
    t = T(d)
    swell = np.minimum(1, t / 1.0) * np.minimum(1, (d - t) / 1.2)
    layers = [
        voice(d, lambda tt: 65 - 6 * (tt / d), "o", vib=(3.5, 0.015), jitter=0.015, breath=0.2, atk=0.9, rel=1.2, shift=0.9),
        voice(d, lambda tt: 130 - 10 * (tt / d), "a", vib=(4.0, 0.015), jitter=0.015, breath=0.15, atk=1.0, rel=1.2),
        voice(d, lambda tt: 195.5 - 12 * (tt / d), "u", vib=(4.8, 0.02), jitter=0.02, breath=0.15, atk=1.2, rel=1.2),
    ]
    sub = tone(np.full(len(t), 32.7)) * swell * 0.5
    y = mixdown([(layers[0], 0, 0.8), (layers[1], 0.05, 0.55), (layers[2], 0.1, 0.35), (sub, 0, 0.6)])
    return reverb(soft_clip(y / (np.max(np.abs(y)) + 1e-9), 1.5), 2.2, 0.5)


def boss_amanita_scale():
    """Delírio de escala: cresce... e encolhe."""
    d = 1.4
    t = T(d)
    f = np.where(t < d / 2, 180 * (9 ** (t / (d / 2))), 1620 * ((110 / 1620) ** ((t - d / 2) / (d / 2))))
    ph = np.cumsum(f) / SR
    y = np.sin(TWO_PI * ph + 1.5 * np.sin(TWO_PI * ph * 0.5))
    y *= 1 + 0.4 * np.sin(TWO_PI * 9 * t)
    y *= np.minimum(1, t / 0.05) * np.minimum(1, (d - t) / 0.1)
    return reverb(y, 0.8, 0.3)


# ================================================================ MUNDO / ITENS
def lotus_checkpoint():
    d = 2.4
    notes = [(523.25, 0), (587.33, 0.09), (783.99, 0.18), (880.0, 0.27), (1046.5, 0.4)]
    parts = [(bell(f, 2.0, 0.9, ((1, 1), (2, 0.35), (3, 0.15), (4.2, 0.07))), at, 0.6) for f, at in notes]
    pad = (tone(np.full(int(SR * d), 261.6)) + 0.5 * tone(np.full(int(SR * d), 392.0))) * np.minimum(1, T(d) / 0.5) * np.exp(-T(d) / 1.2)
    parts.append((pad, 0, 0.15))
    return reverb(mixdown(parts), 1.6, 0.5)


def lotus_respawn():
    d = 1.8
    t = T(d)
    fc = 300 + 5700 * (t / 0.9).clip(0, 1) ** 1.6
    shimmer = svf_bp(N(d), fc, 3.0)
    shimmer = shimmer / (np.max(np.abs(shimmer)) + 1e-9) * np.minimum(1, t / 0.3) * np.exp(-np.maximum(t - 0.9, 0) / 0.4)
    rise = sweep(0.9, 200, 800) * np.minimum(1, T(0.9) / 0.2) * np.minimum(1, (0.9 - T(0.9)) / 0.1) * 0.25
    b1 = bell(1046.5, 1.6, 0.7) * 0.7
    b2 = bell(1568.0, 1.4, 0.6) * 0.4
    return reverb(mixdown([(shimmer, 0, 0.7), (rise, 0, 1.0), (b1, 0.85, 1.0), (b2, 0.95, 1.0)]), 1.3, 0.45)


def flower_pickup():
    d = 2.0
    parts = [(bell(f, 1.4, 0.5, ((1, 1), (2.76, 0.4), (5.4, 0.2))), k * 0.06, 0.6) for k, f in enumerate([1318.5, 1568.0, 1975.5, 2637.0])]
    sparkle = hp(N(1.2), 6000) * env(1.2, 0.05, 0.4) * 0.15
    flash = sweep(0.25, 400, 3000) * env(0.25, 0.01, 0.1) * 0.2
    parts += [(sparkle, 0.05, 1.0), (flash, 0, 1.0)]
    return reverb(mixdown(parts), 1.1, 0.45)


def amulet_gem():
    d = 2.6
    t = T(d)
    sub = tone(np.full(len(t), 110.0)) * np.minimum(1, t / 0.15) * np.exp(-t / 1.0) * 0.6
    b1 = bell(440, 2.4, 1.1, ((1, 1), (2.76, 0.4), (5.4, 0.2)))
    b2 = bell(659.25, 2.2, 1.0, ((1, 1), (2.76, 0.3))) * 0.7
    tick = click(2500, 0.006) * 0.4
    shim = hp(N(1.5), 5000) * env(1.5, 0.05, 0.5) * 0.1
    return reverb(mixdown([(sub, 0, 1.0), (b1, 0, 0.7), (b2, 0.08, 0.6), (tick, 0, 1.0), (shim, 0.05, 1.0)]), 1.8, 0.45)


def heal_true():
    a = bell(660, 0.5, 0.25, ((1, 1), (2, 0.3), (3.01, 0.1)))
    b = bell(990, 0.7, 0.35, ((1, 1), (2, 0.3), (3.01, 0.1)))
    return reverb(mixdown([(a, 0, 0.7), (b, 0.09, 0.8)]), 0.5, 0.2)


def heal_fake():
    """Isca (Irmãs Amanita): parecido com o verdadeiro, mas azedo/desafinado."""
    t = T(0.8)
    a = bell(655, 0.5, 0.25, ((1, 1), (2, 0.35), (3.1, 0.15)))
    b = bell(940, 0.8, 0.4, ((1, 1), (2.03, 0.35), (3.15, 0.2))) * (1 + 0.35 * np.sin(TWO_PI * 11 * T(0.8)))
    sour = lp(sweep(0.4, 420, 250), 900) * env(0.4, 0.01, 0.2) * 0.25
    return reverb(mixdown([(a, 0, 0.7), (b, 0.1, 0.7), (sour, 0.18, 1.0)]), 0.5, 0.2)


def menu_move():
    return bell(880, 0.12, 0.05, ((1, 1), (2, 0.25))) * 0.8


def menu_confirm():
    return mixdown([(bell(784, 0.3, 0.14, ((1, 1), (2, 0.3), (3.01, 0.1))), 0, 0.7),
                    (bell(1175, 0.45, 0.22, ((1, 1), (2, 0.3), (3.01, 0.1))), 0.07, 0.8)])


# ================================================================ EXPORTAR
def build():
    P, E, B, W, U = "01_protagonista", "02_inimigos_formiga_cordyceps", "03_bosses", "04_mundo_itens", "05_ui"
    for i in range(4):
        save(P, f"passo_grama_{i+1:02d}", footstep_grass(i), 0.45, note="andando na grama")
    for i in range(3):
        save(P, f"passo_terra_raiz_{i+1:02d}", footstep_dirt(i), 0.5, note="andando em terra/raízes")
    save(P, "pulo", jump(), 0.55)
    save(P, "aterrissagem", land(), 0.65)
    save(P, "dash", dash(), 0.8, note="dash do druida")
    save(P, "dash_bloqueado_dormencia", dash_blocked(), 0.7, note="dash travado (Azurescens)")
    save(P, "dash_recarregado", dash_recharge(), 0.6, note="recarga do dash (Irmãs Amanita)")
    for i in range(3):
        save(P, f"ataque_espinho_{i+1:02d}", swing(i), 0.75, note="corte da lâmina de espinho")
    save(P, "espinho_brota", thorn_sprout(), 0.65, note="lâmina brota da palma")
    for i in range(3):
        save(P, f"hit_inimigo_{i+1:02d}", hit_enemy(i), 0.85, note="golpe acertando inimigo")
    save(P, "hit_pesado", hit_heavy(), 0.9, note="golpe forte / finalizador")
    for i in range(2):
        save(P, f"druida_dano_{i+1:02d}", player_hurt(i), 0.8, note="protagonista sofrendo dano")
    save(P, "druida_morte", player_death(), 0.8)
    save(P, "contra_ataque_espinhoso", thorn_counter(), 0.75, note="Coroa-de-Cristo")

    save(E, "formiga_idle_chiado", ant_idle(), 0.5)
    for i in range(2):
        save(E, f"formiga_passo_{i+1:02d}", ant_step(i), 0.5)
    save(E, "formiga_ataque_melee", ant_melee(), 0.8)
    save(E, "formiga_tiro_esporo", ant_spore_shot(), 0.75)
    save(E, "formiga_nuvem_esporo", ant_spore_cloud(), 0.6)
    save(E, "formiga_mergulho_aereo", ant_dive(), 0.8)
    save(E, "formiga_impacto_mergulho", ant_dive_impact(), 0.95)
    save(E, "formiga_dano", ant_hurt(), 0.75)
    save(E, "formiga_morte", ant_death(), 0.85)
    save(E, "formiga_bloqueio", ant_block(), 0.75)
    save(E, "enxame_voador_LOOP", ant_swarm_loop(), 0.5, loop=True, note="loop sem emenda de 1s")
    save(E, "larva_infectada_chiado", hatchling(), 0.6)

    save(B, "boss_azurescens_rugido", boss_azurescens(), 0.9, note="Tato")
    save(B, "boss_psilocybe_sussurro", boss_psilocybe(), 0.8, note="Visão")
    save(B, "boss_claviceps_coro", boss_claviceps_choir(), 0.8, note="Audição - coro dissonante")
    save(B, "boss_claviceps_falsa_calma", boss_claviceps_false_calm(), 0.7, note="Audição - música falsa antes de ataque forte")
    save(B, "boss_phalloides_voz", boss_phalloides(), 0.75, note="Irmã isca")
    save(B, "boss_pantherina_voz", boss_pantherina(), 0.75, note="Irmã confusão")
    save(B, "boss_amanita_final_voz", boss_amanita_final(), 0.9, note="Boss final")
    save(B, "boss_amanita_delirio_escala", boss_amanita_scale(), 0.75, note="cresce/encolhe")

    save(W, "lotus_checkpoint_ativado", lotus_checkpoint(), 0.75)
    save(W, "lotus_renascimento", lotus_respawn(), 0.75)
    save(W, "flor_sagrada_coletada", flower_pickup(), 0.75)
    save(W, "fragmento_amuleto", amulet_gem(), 0.8)
    save(W, "cura_verdadeira", heal_true(), 0.7)
    save(W, "cura_falsa_isca", heal_fake(), 0.7)

    save(U, "menu_mover", menu_move(), 0.5)
    save(U, "menu_confirmar", menu_confirm(), 0.6)


if __name__ == "__main__":
    import shutil
    shutil.rmtree(OUT, ignore_errors=True)
    build()
    print(len(REGISTRY), "arquivos")
    for r in REGISTRY:
        print(f"{r[0]}/{r[1]}.wav  {r[2]:.2f}s")
