#!/usr/bin/env python3
"""SFX novos da ata de 27/10/2026 (áudio por ambiente, combate legível, lótus, memórias e falas).

Uso: python3 sfx_ata.py <pasta_sfx> <pasta_voice>
Os avisos (tell_*, *_aviso) têm o CLÍMAX no tempo indicado em CLIMAX: o jogo inicia a reprodução
deslocada para que o clímax coincida exatamente com o golpe, qualquer que seja a duração do aviso.
"""
import os
import sys
import numpy as np
from scipy.io import wavfile

import sfx_pack_v1 as v1
from engine import SR, lp, hp, bp, glass, rev_glass, thump, tok, svf_bp, fade_ends, choir_note, sine_pad, mtof

rng = np.random.default_rng(2710)
CLIMAX = {"tell": 1.36, "aviso": 0.62}
REG = []


def T(d):
    return np.arange(int(SR * d)) / SR


def N(d):
    return rng.standard_normal(int(SR * d))


def mix(*xs):
    """Soma sinais de comprimentos diferentes (completa com silêncio)."""
    n = max(len(x) for x in xs)
    y = np.zeros(n)
    for x in xs:
        y[:len(x)] += x
    return y


def place(total, parts):
    y = np.zeros(int(SR * total))
    for x, at, g in parts:
        i = int(at * SR)
        m = min(len(x), len(y) - i)
        if m > 0:
            y[i:i + m] += g * x[:m]
    return y


def save(folder, name, x, peak=0.8, trim=True):
    x = np.asarray(x, float)
    x = x - np.mean(x)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    if trim:
        above = np.where(np.abs(x) > 0.002 * peak)[0]
        if len(above):
            x = x[: above[-1] + int(0.03 * SR)]
    x = fade_ends(x, 0.001, 0.012)
    os.makedirs(folder, exist_ok=True)
    wavfile.write(os.path.join(folder, name + ".wav"), SR, (x * 32767).astype(np.int16))
    REG.append((name, len(x) / SR))


def creak(d=0.07, f0=380, f1=240, rough=90):
    t = T(d)
    f = f0 * (f1 / f0) ** (t / d)
    ph = np.cumsum(f) / SR
    saw = 2 * (ph % 1) - 1
    y = lp(saw, 1800) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * rough * t)))
    return fade_ends(y * np.minimum(1, t / 0.006) * np.exp(-t / (d * 0.6)), 0, 0.01)


def blip(f0, d=0.03, up=1.6):
    t = T(d)
    f = f0 * (1 + (up - 1) * t / d)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) ** 2


def build_curve(d, climax, power=1.6, tail=0.05):
    t = T(d)
    return np.where(t < climax, (t / climax) ** power, np.exp(-(t - climax) / tail))


# ------------------------------------------------------------------ avisos do chefe (clímax = golpe)
def tell_raizes():
    d, c = 1.5, CLIMAX["tell"]
    rumble = lp(N(d), 170) * build_curve(d, c, 1.5, 0.06)
    parts = [(rumble, 0, 1.0)]
    t, gap = 0.12, 0.28
    while t < c - 0.03:
        parts.append((creak(0.07, rng.uniform(340, 420), rng.uniform(220, 260)), t, 0.25 + 0.6 * (t / c)))
        t += gap
        gap = max(0.045, gap * 0.82)
    crack = mix(v1.crackles(0.25, 900, f_range=(900, 3800), decay=0.06), v1.sweep(0.2, 130, 45) * v1.env(0.2, 0.001, 0.06))
    parts.append((crack, c, 1.0))
    return place(d + 0.1, parts)


def tell_esporos():
    d, c = 1.5, CLIMAX["tell"]
    t = T(d)
    fc = 500 * (3200 / 500) ** np.clip(t / c, 0, 1)
    inhale = svf_bp(N(d), fc, 2.0)
    inhale = inhale / (np.max(np.abs(inhale)) + 1e-9) * build_curve(d, c, 1.3, 0.03)
    parts = [(inhale, 0, 0.8)]
    k = 0.2
    while k < c:
        parts.append((blip(rng.uniform(180, 420), rng.uniform(0.025, 0.05), 1.4), k, 0.15 + 0.35 * k / c))
        k += rng.uniform(0.03, 0.12) * (1.2 - k / c)
    pop = v1.sweep(0.06, 300, 1300) * v1.env(0.06, 0.001, 0.02) + v1.click(2600, 0.004, 0.06)
    parts.append((pop, c, 1.0))
    return place(d + 0.1, parts)


def tell_pulso():
    d, c = 1.5, CLIMAX["tell"]
    t = T(d)
    f = 220 * (4.0 ** np.clip(t / c, 0, 1))
    trem_rate = 4 + 18 * np.clip(t / c, 0, 1) ** 1.5
    trem = 0.55 + 0.45 * np.sin(2 * np.pi * np.cumsum(trem_rate) / SR)
    tone = (np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.5 * np.sin(2 * np.pi * np.cumsum(f * 1.5) / SR)) * trem
    shimmer = sum(np.sin(2 * np.pi * np.cumsum(f * r) / SR) * a for r, a in ((2.76, 0.18), (5.4, 0.08)))
    y = (tone + shimmer) * build_curve(d, c, 1.8, 0.04)
    whomp = v1.sweep(0.3, 110, 45) * v1.env(0.3, 0.001, 0.09)
    return place(d + 0.15, [(y, 0, 0.8), (whomp, c, 1.0)])


def tell_mandibulas():
    d, c = 1.5, CLIMAX["tell"]
    t = T(d)
    parts = []
    k, rate = 0.08, 6.0
    while k < c:
        parts.append((v1.click(rng.uniform(2900, 3600), 0.004, 0.05), k, 0.3 + 0.7 * (k / c)))
        k += 1.0 / rate
        rate = min(42.0, rate * 1.13)
    f = 70 + 25 * np.clip(t / c, 0, 1)
    saw = 2 * ((np.cumsum(f) / SR) % 1) - 1
    growl = lp(saw, 600) * (0.7 + 0.3 * np.sin(2 * np.pi * 23 * t)) * build_curve(d, c, 1.4, 0.05)
    parts.append((growl, 0, 0.7))
    roar = v1.fm_squeal(0.25, 950, 600, 1.7, 3.2) * v1.env(0.25, 0.004, 0.1)
    parts.append((roar, c, 0.6))
    parts.append((v1.sweep(0.15, 140, 60) * v1.env(0.15, 0.001, 0.04), c, 0.8))
    return place(d + 0.15, parts)


# ------------------------------------------------------------------ golpes do chefe
def raizes_irrompem():
    d = 0.8
    boom = v1.sweep(d, 140, 38) * v1.env(d, 0.001, 0.16)
    crack = v1.crackles(d, 800, f_range=(900, 3800), decay=0.12)
    dirt = lp(N(d), 2000) * v1.env(d, 0.002, 0.14)
    debris = v1.crackles(0.6, 120, f_range=(500, 1500), tau_range=(0.006, 0.012), decay=0.2)
    return v1.soft_clip(place(d + 0.4, [(boom, 0, 1.0), (crack, 0, 0.8), (dirt, 0, 0.7), (debris, 0.1, 0.5)]) / 1.6, 1.8)


def esporos_lancados():
    parts = []
    for k in range(3):
        d = 0.35
        t = T(d)
        pop = v1.sweep(0.1, 220 + 40 * k, 1000) * v1.env(0.1, 0.001, 0.03)
        puff = bp(N(d), 400, 2600) * np.minimum(1, t / 0.01) * np.exp(-t / 0.09)
        parts += [(pop, 0.07 * k, 0.6), (puff, 0.07 * k, 0.8)]
    parts.append((hp(N(0.5), 3500) * v1.env(0.5, 0.03, 0.15), 0.05, 0.2))
    return place(0.8, parts)


def pulso_inversao():
    d = 0.9
    t = T(d)
    fc = 3000 * (300 / 3000) ** (t / d)
    whoosh = svf_bp(N(d), fc, 1.4)
    whoosh = whoosh / (np.max(np.abs(whoosh)) + 1e-9) * np.sin(np.pi * t / d) ** 1.2
    chord = sum(np.sin(2 * np.pi * f * t) for f in (293.7, 311.1, 440.0, 445.0)) / 4 * v1.env(d, 0.02, 0.3)
    return place(d + 0.1, [(whoosh, 0, 0.8), (chord, 0, 0.6)])


def investida_mandibulas():
    d = 0.75
    t = T(d)
    fc = np.where(t < 0.18, 700 + 3300 * t / 0.18, 4000 - 2500 * (t - 0.18) / (d - 0.18))
    air = svf_bp(N(d), fc, 1.5)
    air = air / (np.max(np.abs(air)) + 1e-9) * np.exp(-((t - 0.18) / 0.15) ** 2)
    roar = v1.fm_squeal(0.45, 900, 420, 1.7, 3.4) * v1.env(0.45, 0.01, 0.18)
    sk = v1.crackles(0.5, 300, f_range=(2500, 4500), decay=0.15)
    return place(d + 0.1, [(air, 0, 1.0), (roar, 0.02, 0.5), (sk, 0.05, 0.4)])


def cordyceps_dor():
    sq = v1.fm_squeal(0.35, 2400, 1400, 1.6, 3.0, vib=(38, 0.05)) * v1.env(0.35, 0.004, 0.13)
    return place(0.45, [(sq, 0, 0.7), (v1.crackles(0.2, 400, decay=0.06), 0, 0.5)])


def fase_dois():
    d = 2.4
    boom = v1.sweep(d, 70, 30) * v1.env(d, 0.002, 0.6)
    choir = sum(choir_note(float(mtof(m)), 0.5, "a", atk=0.02, rel=1.2, seed=m) for m in (50, 51, 57)) / 3
    ring = glass(float(mtof(75)), 2.2, atk=0.005, tau=0.9) * 0.4
    return v1.reverb(place(d, [(boom, 0, 1.0), (choir, 0.01, 1.4), (ring, 0.02, 0.6)]), 1.2, 0.3)


def chefe_colapso():
    d = 2.2
    big = mix(v1.crackles(0.5, 1200, f_range=(800, 3500), decay=0.12), v1.sweep(0.6, 110, 35) * v1.env(0.6, 0.001, 0.2))
    falls = v1.crackles(1.6, 260, f_range=(600, 2600), tau_range=(0.004, 0.01), decay=0.6)
    rumble = lp(N(d), 220) * v1.env(d, 0.05, 0.7)
    return v1.soft_clip(place(d, [(big, 0, 1.0), (falls, 0.2, 0.6), (rumble, 0, 0.7)]) / 1.8, 1.6)


def colapso_estalo(i):
    d = 0.5
    c = v1.crackles(0.3, 700 + 150 * i, f_range=(700, 3200), decay=0.07)
    th = v1.sweep(0.3, 120 - 15 * i, 50) * v1.env(0.3, 0.001, 0.07)
    return place(d, [(c, 0, 0.9), (th, 0, 0.8), (lp(N(0.3), 1500) * v1.env(0.3, 0.002, 0.06), 0, 0.4)])


def chefe_silencia():
    d = 4.0
    low = glass(110.0, d, atk=0.01, tau=1.6) + 0.6 * glass(164.8, d, atk=0.01, tau=1.4)
    ch = choir_note(float(mtof(50)), 1.6, "o", atk=0.4, rel=1.8, seed=3)
    return v1.reverb(place(d + 0.5, [(low, 0, 0.8), (ch, 0.3, 0.5)]), 1.6, 0.35)


def bencao_calendula():
    d = 4.6
    pad = sum(sine_pad(float(mtof(m)), 2.6, atk=0.6, rel=1.6, seed=m) for m in (60, 64, 67, 71, 74)) / 5
    arp = [(glass(float(mtof(m)), 2.4, atk=0.004, tau=1.0), 0.35 + 0.11 * k, 0.5) for k, m in enumerate((72, 76, 79, 83, 86))]
    ch = choir_note(float(mtof(64)), 2.0, "a", atk=0.5, rel=1.6, seed=9)
    spark = hp(N(2.0), 6500) * v1.env(2.0, 0.2, 0.6) * 0.15
    return v1.reverb(place(d, [(pad, 0, 0.9), (ch, 0.2, 0.6), (spark, 0.4, 1.0)] + arp), 1.8, 0.4)


# ------------------------------------------------------------------ lótus, memórias, flor, estados
def lotus_plantar():
    d = 0.8
    wood = tok(170, 1.0, seed=1)
    th = thump(115, 52, 0.45, 0.09)
    soil = v1.crackles(0.35, 380, f_range=(300, 1300), tau_range=(0.004, 0.01), decay=0.12) + lp(N(0.35), 1100) * v1.env(0.35, 0.002, 0.07)
    cr = creak(0.22, 300, 210, 70)
    return place(d, [(th, 0, 0.9), (wood, 0.005, 0.7), (soil, 0.01, 0.7), (cr, 0.12, 0.35)])


def lotus_interrompida():
    a = glass(float(mtof(72)), 0.6, atk=0.003, tau=0.12)
    b = glass(float(mtof(73)), 0.6, atk=0.003, tau=0.12)
    br = bp(N(0.4), 300, 2500) * v1.env(0.4, 0.01, 0.1)
    return place(0.65, [(a, 0, 0.6), (b, 0.01, 0.6), (br, 0.02, 0.4)])


def lotus_reafirmado():
    a = glass(float(mtof(79)), 1.4, atk=0.004, tau=0.6)
    b = glass(float(mtof(84)), 1.4, atk=0.004, tau=0.7)
    pad = sine_pad(float(mtof(72)), 0.6, atk=0.15, rel=0.8, seed=2) * 0.4
    return v1.reverb(place(1.6, [(a, 0, 0.6), (b, 0.16, 0.6), (pad, 0, 1.0)]), 0.9, 0.3)


def memoria_revelada():
    sw = rev_glass(float(mtof(76)), 1.0)
    pops = sum(blip(rng.uniform(380, 800), 0.03, 1.6) for _ in range(1))
    chime = glass(float(mtof(81)), 1.4, atk=0.003, tau=0.6)
    return v1.reverb(place(2.4, [(sw, 0, 0.6), (pops, 1.0, 0.5), (chime, 1.0, 0.6)]), 1.2, 0.35)


def calendula_cura():
    d = 0.5
    t = T(d)
    inhale = svf_bp(N(d), 600 * (4.5 ** (t / d)), 2.0)
    inhale = inhale / (np.max(np.abs(inhale)) + 1e-9) * (t / d) ** 1.4
    arp = [(glass(float(mtof(m)), 1.0, atk=0.003, tau=0.35), 0.45 + 0.07 * k, 0.5) for k, m in enumerate((84, 88, 91))]
    return v1.reverb(place(1.3, [(inhale, 0, 0.5)] + arp), 0.8, 0.3)


def dormencia_inicio():
    d = 0.85
    t = T(d)
    tingle = sum(np.sin(2 * np.pi * f * t) for f in (3050, 3110, 4180)) / 3 * (0.5 + 0.5 * np.sin(2 * np.pi * 31 * t)) * v1.env(d, 0.005, 0.28)
    thud = lp(N(0.15), 500) * v1.env(0.15, 0.001, 0.03)
    return place(d, [(tingle, 0, 0.5), (thud, 0, 0.7)])


def controles_invertidos():
    d = 0.8
    t = T(d)
    bend = 600 * (1 - 0.35 * np.sin(np.pi * t / d))
    vib = 1 + (0.01 + 0.05 * t / d) * np.sin(2 * np.pi * 9 * t)
    a = np.sin(2 * np.pi * np.cumsum(bend * vib) / SR)
    b = np.sin(2 * np.pi * np.cumsum(bend * vib * 1.012) / SR)
    return (a + b) * 0.5 * v1.env(d, 0.01, 0.3)


def pulso_evitado():
    d = 0.6
    t = T(d)
    air = hp(N(d), 2500) * np.sin(np.pi * t / d) * 0.25
    return place(d, [(glass(1568.0, 0.6, atk=0.003, tau=0.18), 0, 0.5), (glass(2093.0, 0.6, atk=0.003, tau=0.2), 0.05, 0.4), (air, 0, 1.0)])


def esporo_impacto():
    d = 0.45
    splat = lp(N(d), 1400) * v1.env(d, 0.001, 0.05)
    bub = sum(blip(rng.uniform(250, 600), 0.03, 1.5) for _ in range(1))
    tin = np.sin(2 * np.pi * 3300 * T(0.3)) * v1.env(0.3, 0.005, 0.08) * (0.5 + 0.5 * np.sin(2 * np.pi * 31 * T(0.3)))
    return place(d, [(splat, 0, 0.9), (bub, 0.04, 0.4), (tin, 0.03, 0.25)])


def ui_swish(up=True, d=0.35):
    t = T(d)
    rustle = bp(N(d), 1000, 6000) * (0.6 + 0.4 * (np.abs(lp(N(d), 60)) > 0.02)) * np.sin(np.pi * t / d) ** 1.5
    f = (660 * (880 / 660) ** (t / d)) if up else (880 * (660 / 880) ** (t / d))
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * v1.env(d, 0.01, 0.12)
    return rustle * 0.5 + tone * 0.35


def pausa(up):
    d = 0.45
    t = T(d)
    f = (262 * (392 / 262) ** (t / d)) if up else (392 * (262 / 392) ** (t / d))
    tone = (np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / SR)) * np.sin(np.pi * t / d)
    breath = bp(N(d), 300, 1800) * np.sin(np.pi * t / d) * 0.2
    return tone + breath


# ------------------------------------------------------------------ passos por superfície (ata: passos mais úmidos)
def passo_umido(i):
    d = 0.24
    thud = lp(N(d), 700) * v1.env(d, 0.002, 0.03)
    sq = mix(*[blip(rng.uniform(280, 700), rng.uniform(0.02, 0.04), rng.uniform(1.3, 1.8)) for _ in range(2)])
    splash = hp(N(0.1), 2500) * v1.env(0.1, 0.002, 0.02)
    drip = blip(rng.uniform(1300, 1900), 0.025, 0.6)
    return place(d, [(thud, 0, 0.8), (sq, 0.01, 0.35), (splash, 0.005, 0.35), (drip, 0.06 + 0.02 * i, 0.15)])


def passo_madeira(i):
    d = 0.2
    knock = tok(rng.uniform(180, 240), 1.0, seed=i)
    res = np.sin(2 * np.pi * rng.uniform(110, 135) * T(d)) * v1.env(d, 0.001, 0.05)
    rustle = bp(N(d), 2500, 7000) * v1.env(d, 0.004, 0.03)
    return place(d, [(knock, 0, 0.7), (res, 0, 0.5), (rustle, 0, 0.25)])


def aterrissagem_umida():
    d = 0.4
    thud = lp(N(d), 600) * v1.env(d, 0.002, 0.06) + v1.sweep(d, 110, 45) * v1.env(d, 0.001, 0.06)
    splash = hp(N(0.2), 2000) * v1.env(0.2, 0.002, 0.04)
    sq = sum(blip(rng.uniform(250, 600), 0.04, 1.5) for _ in range(3))
    return place(d, [(thud, 0, 0.9), (splash, 0.005, 0.5), (sq, 0.02, 0.35)])


# ------------------------------------------------------------------ avisos dos inimigos (clímax = golpe, 0.65 s de aviso)
def formiga_aviso():
    d, c = 0.8, CLIMAX["aviso"]
    parts = []
    k, rate = 0.0, 10.0
    while k < c:
        parts.append((v1.click(rng.uniform(2800, 3500), 0.004, 0.05), k, 0.35 + 0.65 * k / c))
        k += 1.0 / rate
        rate = min(45.0, rate * 1.18)
    parts.append((v1.fm_squeal(0.15, 1700, 1300, 1.5, 2.6) * v1.env(0.15, 0.005, 0.05), c - 0.02, 0.4))
    return place(d, parts)


def cuspidor_aviso():
    d, c = 0.8, CLIMAX["aviso"]
    t = T(d)
    inhale = svf_bp(N(d), 450 * (5.0 ** np.clip(t / c, 0, 1)), 2.0)
    inhale = inhale / (np.max(np.abs(inhale)) + 1e-9) * build_curve(d, c, 1.4, 0.03)
    parts = [(inhale, 0, 0.7)]
    k = 0.05
    while k < c:
        parts.append((blip(rng.uniform(170, 380), 0.04, 1.3), k, 0.25))
        k += rng.uniform(0.04, 0.1)
    return place(d, parts)


def mosca_aviso():
    d, c = 0.8, CLIMAX["aviso"]
    t = T(d)
    f = 180 * (2.4 ** np.clip(t / c, 0, 1))
    saw = 2 * ((np.cumsum(f) / SR) % 1) - 1
    y = lp(saw, 2600) * (0.55 + 0.45 * np.sin(2 * np.pi * 31 * t)) * build_curve(d, c, 1.2, 0.04)
    return y


# ------------------------------------------------------------------ falas (voz da seiva / voz da flor)
VOWELS = ["a", "e", "i", "o", "u", "a", "o", "e"]


def consonant(kind, d=0.04):
    if kind == "s":
        return hp(N(d), 4200) * v1.env(d, 0.006, 0.015)
    if kind == "k":
        return v1.click(2200, 0.003, 0.03)
    if kind == "h":
        return bp(N(d), 600, 3000) * v1.env(d, 0.006, 0.015)
    return np.zeros(int(SR * 0.005))


def voz_seiva(i):
    d = rng.uniform(0.12, 0.16)
    f0 = rng.uniform(118, 150)
    v = v1.voice(d, lambda t: f0 * (1 - 0.06 * t / d), VOWELS[i], vib=(5.0, 0.01), jitter=0.02, breath=0.35, atk=0.015, rel=0.05)
    c = consonant(["s", "h", "k", "", "h", "s", "k", ""][i])
    y = place(d + 0.06, [(c, 0, 0.35), (lp(v, 3500), len(c) / SR * 0.7, 1.0)])
    return y


def voz_flor(i):
    d = rng.uniform(0.10, 0.13)
    f0 = rng.uniform(330, 395)
    v = v1.voice(d, lambda t: f0 * (1 + 0.04 * t / d), VOWELS[i], vib=(6.0, 0.012), jitter=0.006, breath=0.12, atk=0.01, rel=0.04, shift=1.08)
    bell = glass(f0 * 2, d + 0.15, atk=0.004, tau=0.12) * 0.25
    c = consonant(["", "s", "h", "", "k", "", "s", "h"][i], 0.03)
    return place(d + 0.18, [(c, 0, 0.25), (v, len(c) / SR * 0.7, 1.0), (bell, 0.005, 1.0)])


def build(sfx, voice):
    save(sfx, "tell_raizes", tell_raizes(), 0.85, trim=False)
    save(sfx, "tell_esporos", tell_esporos(), 0.85, trim=False)
    save(sfx, "tell_pulso", tell_pulso(), 0.85, trim=False)
    save(sfx, "tell_mandibulas", tell_mandibulas(), 0.85, trim=False)
    save(sfx, "raizes_irrompem", raizes_irrompem(), 0.9)
    save(sfx, "esporos_lancados", esporos_lancados(), 0.8)
    save(sfx, "pulso_inversao", pulso_inversao(), 0.8)
    save(sfx, "investida_mandibulas", investida_mandibulas(), 0.85)
    save(sfx, "cordyceps_dor", cordyceps_dor(), 0.7)
    save(sfx, "fase_dois", fase_dois(), 0.9)
    save(sfx, "chefe_colapso", chefe_colapso(), 0.9)
    for i in range(3):
        save(sfx, f"colapso_estalo_{i + 1:02d}", colapso_estalo(i), 0.8)
    save(sfx, "chefe_silencia", chefe_silencia(), 0.75)
    save(sfx, "bencao_calendula", bencao_calendula(), 0.8)
    save(sfx, "lotus_plantar", lotus_plantar(), 0.8)
    save(sfx, "lotus_interrompida", lotus_interrompida(), 0.6)
    save(sfx, "lotus_reafirmado", lotus_reafirmado(), 0.6)
    save(sfx, "memoria_revelada", memoria_revelada(), 0.6)
    save(sfx, "calendula_cura", calendula_cura(), 0.7)
    save(sfx, "dormencia_inicio", dormencia_inicio(), 0.6)
    save(sfx, "controles_invertidos", controles_invertidos(), 0.6)
    save(sfx, "pulso_evitado", pulso_evitado(), 0.55)
    save(sfx, "esporo_impacto", esporo_impacto(), 0.7)
    save(sfx, "mapa_abrir", ui_swish(True), 0.45)
    save(sfx, "mapa_fechar", ui_swish(False, 0.3), 0.4)
    save(sfx, "pausa_abrir", pausa(False), 0.45)
    save(sfx, "pausa_fechar", pausa(True), 0.45)
    for i in range(4):
        save(sfx, f"passo_umido_{i + 1:02d}", passo_umido(i), 0.5)
    for i in range(3):
        save(sfx, f"passo_madeira_{i + 1:02d}", passo_madeira(i), 0.45)
    save(sfx, "aterrissagem_umida", aterrissagem_umida(), 0.65)
    save(sfx, "formiga_aviso", formiga_aviso(), 0.75, trim=False)
    save(sfx, "cuspidor_aviso", cuspidor_aviso(), 0.75, trim=False)
    save(sfx, "mosca_aviso", mosca_aviso(), 0.7, trim=False)
    for i in range(8):
        save(voice, f"voz_seiva_{i + 1:02d}", voz_seiva(i), 0.6)
        save(voice, f"voz_flor_{i + 1:02d}", voz_flor(i), 0.55)


if __name__ == "__main__":
    build(sys.argv[1], sys.argv[2])
    for name, d in REG:
        print(f"{name:28s} {d:5.2f}s")
    print(len(REG), "arquivos")
