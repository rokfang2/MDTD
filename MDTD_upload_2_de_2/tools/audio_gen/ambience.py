#!/usr/bin/env python3
"""Ambientes por região e loops posicionais, todos com emenda perfeita (síntese circular).

Uso: python3 ambience.py <pasta_ambience> <pasta_loops> <pasta_tmp>
"""
import os
import sys
import numpy as np
from scipy.io import wavfile

import sfx_pack_v1 as v1
from engine import (SR, Loop, mtof, lp, hp, bp, glass, thump, tok, whisper, cricket, bird, fade_ends,
                    master, save_wav, check_loop, to_ogg, save_loop_wav)


def creak(r, d, f0, f1, rough):
    t = np.arange(int(d * SR)) / SR
    f = f0 * (f1 / f0) ** (t / d)
    saw = 2 * ((np.cumsum(f) / SR) % 1) - 1
    y = lp(saw, 1500) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * rough * t)))
    return fade_ends(y * np.sin(np.pi * t / d) ** 1.5, 0.005, 0.02)


def drip(r):
    d = 0.09
    t = np.arange(int(d * SR)) / SR
    f0 = r.uniform(1200, 2400)
    f = f0 * (0.55 + 0.45 * np.exp(-t / 0.012))
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.035)
    y[:60] += r.standard_normal(60) * 0.3
    return fade_ends(y, 0.0005, 0.01)


def bubble(r, lo=300, hi=1100):
    d = r.uniform(0.012, 0.03)
    t = np.arange(int(d * SR)) / SR
    f0 = r.uniform(lo, hi)
    f = f0 * (1 + 0.8 * t / d)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) ** 2


def events(lo, stem, gen, mean_gap, gain, pan=(-0.85, 0.85), start=0.2, jitter=0.4):
    t = start
    r = lo.rng
    while t < lo.L:
        lo.put(stem, gen(r), t, pan=float(r.uniform(*pan)), gain=gain)
        t += mean_gap * r.uniform(1 - jitter, 1 + jitter)


def periodic_mod(t, L, parts):
    y = np.ones_like(t)
    for cyc, depth, ph in parts:
        y = y + depth * np.sin(2 * np.pi * cyc * t / L + ph)
    return y


def stereo_bed(lo, stem, make, gain):
    for pan in (-1.0, 1.0):
        sig = make(pan) * gain
        th = (pan + 1) * np.pi / 4
        lo.put(stem, np.stack([sig * np.cos(th), sig * np.sin(th)]), 0.0)


# ------------------------------------------------------------------ ambientes (48 s)
def amb_floresta(n):
    lo = Loop(n, seed=101)
    t, L = lo.t(), lo.L
    stereo_bed(lo, "bed", lambda p: lo.pnoise(180, 900) * periodic_mod(t, L, [(3, 0.3, p), (7, 0.2, 2 * p)]), 0.030)
    stereo_bed(lo, "bed", lambda p: lo.pnoise(2500, 7500) * (0.3 + 0.25 * np.sin(2 * np.pi * 5 * t / L + p)), 0.016)
    for fc, per in ((4350, 0.95), (5050, 1.3)):
        events(lo, "life", lambda r, fc=fc: cricket(fc * (1 + 0.01 * r.standard_normal()), int(r.integers(2, 4)), int(r.integers(1_000_000))), per, 0.05, jitter=0.15)
    events(lo, "life", lambda r: bird(r, float(r.uniform(2800, 4300))), 5.0, 0.05, start=1.7, jitter=0.5)
    return lo, {"bed": dict(rev=(2.0, 6500, 0.08)), "life": dict(rev=(2.6, 8000, 0.30))}, -28.0


def amb_raizes(n):
    lo = Loop(n, seed=102)
    t, L = lo.t(), lo.L
    stereo_bed(lo, "bed", lambda p: lo.pnoise(110, 600) * periodic_mod(t, L, [(2, 0.3, p), (5, 0.2, 1.3 * p)]), 0.032)
    stereo_bed(lo, "bed", lambda p: lo.pnoise(5000, 7500) * (0.5 + 0.5 * np.sin(2 * np.pi * 38 * t)) * (0.4 + 0.35 * np.sin(2 * np.pi * 4 * t / L + p)), 0.008)
    events(lo, "life", lambda r: creak(r, float(r.uniform(0.35, 0.8)), float(r.uniform(240, 300)), float(r.uniform(170, 210)), float(r.uniform(70, 110))), 3.8, 0.045, jitter=0.5)

    def puff(r):
        d = 0.32
        tt = np.arange(int(d * SR)) / SR
        return bp(r.standard_normal(len(tt)), 400, 2500) * np.minimum(1, tt / 0.02) * np.exp(-tt / 0.09)
    events(lo, "life", puff, 6.0, 0.035, start=2.3, jitter=0.5)
    lo.put("bed", lo.drone(55.0, harmonics=((1, 1.0), (2, 0.3)), beat_cents=7.0), 0.0, gain=0.020)
    return lo, {"bed": dict(rev=(2.4, 6000, 0.10)), "life": dict(rev=(2.8, 6000, 0.35))}, -28.0


def amb_galerias(n):
    """Caverna úmida: goteiras com eco (ata 4.1), filete d'água e ronco grave."""
    lo = Loop(n, seed=103)
    t, L = lo.t(), lo.L
    stereo_bed(lo, "bed", lambda p: lo.pnoise(30, 160) * periodic_mod(t, L, [(2, 0.25, p), (3, 0.15, 2.0 * p)]), 0.055)
    events(lo, "drip", drip, 0.95, 0.09, jitter=0.75)
    events(lo, "trickle", lambda r: bubble(r), 0.045, 0.012, pan=(-0.4, 0.4), jitter=0.9)
    return lo, {"bed": dict(rev=(3.0, 4000, 0.20)),
                "drip": dict(rev=(3.6, 6000, 0.60), delay=(0.37, 0.36, 0.30)),
                "trickle": dict(rev=(2.6, 3500, 0.45))}, -27.0


def amb_ninho(n):
    lo = Loop(n, seed=104)
    t, L = lo.t(), lo.L

    def chitter(r):
        k = int(r.integers(3, 9))
        y = np.zeros(int(0.5 * SR))
        pos = 0
        for _ in range(k):
            c = v1.click(float(r.uniform(2200, 4000)), float(r.uniform(0.003, 0.006)))
            if pos + len(c) < len(y):
                y[pos:pos + len(c)] += c * r.uniform(0.4, 1.0)
            pos += int(r.uniform(0.015, 0.045) * SR)
        return y
    events(lo, "life", chitter, 1.3, 0.04, jitter=0.6)
    lo.put("bed", lo.drone(36.71, harmonics=((1, 1.0), (2, 0.5), (3, 0.15)), beat_cents=6.0), 0.0, gain=0.050)
    stereo_bed(lo, "bed", lambda p: lo.pnoise(90, 400) * periodic_mod(t, L, [(2, 0.35, p), (3, 0.2, 2.2 * p)]), 0.030)
    beat = 1.6
    k = 0
    while k * beat < L:
        lo.put("heart", lp(thump(80, 40, 0.5, 0.12), 300), k * beat, gain=0.10)
        lo.put("heart", lp(thump(72, 38, 0.4, 0.1), 300), k * beat + 0.42, gain=0.065)
        k += 1
    events(lo, "life", lambda r: hp(r.standard_normal(int(0.03 * SR)), 3500) * np.hanning(int(0.03 * SR)), 2.2, 0.02, jitter=0.7)
    return lo, {"bed": dict(rev=(2.8, 4500, 0.15)), "life": dict(rev=(3.0, 6000, 0.40)), "heart": dict(rev=(2.0, 2500, 0.30))}, -27.0


# ------------------------------------------------------------------ loops posicionais (mono)
def memoria_seiva(n):
    lo = Loop(n, seed=201)
    events(lo, "a", lambda r: bubble(r, 350, 900), 0.17, 0.10, pan=(-0.2, 0.2), jitter=0.9)
    events(lo, "b", lambda r: glass(float(mtof(r.choice([93, 96, 98, 100]))), 1.5, atk=0.004, tau=0.5), 1.6, 0.03, pan=(-0.2, 0.2), jitter=0.4)
    return lo, {"a": dict(rev=(1.8, 4000, 0.35)), "b": dict(rev=(2.4, 8000, 0.45))}


def memoria_madeira(n):
    lo = Loop(n, seed=202)
    events(lo, "a", lambda r: creak(r, float(r.uniform(0.3, 0.6)), float(r.uniform(260, 320)), float(r.uniform(180, 220)), float(r.uniform(60, 90))), 2.1, 0.08, pan=(-0.2, 0.2), jitter=0.4)
    events(lo, "a", lambda r: tok(float(r.uniform(150, 210)), 0.8, seed=int(r.integers(1_000_000))), 2.9, 0.07, pan=(-0.2, 0.2), start=1.0, jitter=0.4)
    lo.put("a", lo.drone(98.0, harmonics=((1, 1.0), (2, 0.25)), beat_cents=4.0) , 0.0, gain=0.015)
    return lo, {"a": dict(rev=(2.2, 3500, 0.40))}


def memoria_sussurro(n):
    lo = Loop(n, seed=203)
    r = lo.rng
    for k, vw in enumerate(("o", "a", "u", "e")):
        lo.put("a", whisper(float(r.uniform(2.4, 3.4)), vw, seed=k), k * lo.L / 4 + r.uniform(0, 0.6), gain=0.10)
    return lo, {"a": dict(rev=(2.8, 5000, 0.55))}


def lotus_foco(n):
    lo = Loop(n, seed=204)
    t, L = lo.t(), lo.L
    y = np.zeros(lo.n)
    for m, a in ((72, 1.0), (76, 0.7), (79, 0.6), (86, 0.35)):
        k = round(float(mtof(m)) * L)
        y += a * np.sin(2 * np.pi * k * t / L) * (0.75 + 0.25 * np.sin(2 * np.pi * (2 + m % 3) * t / L + m))
    lo.put("a", y, 0.0, gain=0.05)
    events(lo, "b", lambda r: glass(float(mtof(r.choice([96, 100, 103]))), 1.4, atk=0.004, tau=0.45), 1.3, 0.025, pan=(-0.2, 0.2), jitter=0.4)
    return lo, {"a": dict(rev=(2.0, 7000, 0.30)), "b": dict(rev=(2.6, 8000, 0.45))}


def lotus_oracao(n):
    """Zumbido da oração; o jogo sobe pitch/volume com o progresso (responsivo à oração de 1,4 s)."""
    lo = Loop(n, seed=205)
    t, L = lo.t(), lo.L
    src = np.zeros(lo.n)
    for m in (48, 55, 60):
        k = round(float(mtof(m)) * L)
        ph = (k * t / L) % 1.0
        src += 2 * ph - 1
    src3 = np.tile(src, 3)
    vox = sum(g * bp(src3, fc * 0.9, fc * 1.12) for fc, g in ((450, 1.0), (800, 0.45), (2830, 0.12)))[lo.n:2 * lo.n]
    hum = np.zeros(lo.n)
    for m, a in ((60, 0.5), (67, 0.35), (72, 0.3)):
        k = round(float(mtof(m)) * L)
        hum += a * np.sin(2 * np.pi * k * t / L)
    lo.put("a", vox / (np.std(vox) + 1e-9) * 0.05 + hum * 0.05, 0.0)
    return lo, {"a": dict(rev=(2.2, 5000, 0.35))}


def mosca_zumbido(n):
    """Zumbido periódico (frequências com ciclos inteiros por loop) para seguir as moscas no mapa."""
    lo = Loop(n, seed=206)
    t, L = lo.t(), lo.L
    y = np.zeros(lo.n)
    for fb, m, k, a in ((180, 0.04, 3, 1.0), (188, 0.05, 4, 0.8), (362, 0.04, 3, 0.5), (377, 0.05, 2, 0.4)):
        fb = round(fb * L) / L
        ph = fb * t + fb * m * (1 - np.cos(2 * np.pi * k * t / L * round(L))) / (2 * np.pi * k * round(L) / L)
        y += a * (2 * (ph % 1.0) - 1)
    y *= 1 + 0.5 * np.sin(2 * np.pi * round(7 * L) * t / L)
    y3 = bp(np.tile(y, 3), 140, 2800)
    lo.put("a", y3[lo.n:2 * lo.n], 0.0, gain=0.2)
    return lo, {"a": dict()}


def render_to(lo, spec, out_wav, lufs=None, peak=None, mono=False):
    mix = lo.render(spec)
    if mono:
        m = mix.mean(axis=0)
        mix = np.stack([m, m])
    if lufs is not None:
        y = master(mix, out_wav + ".tmp.wav", target_lufs=lufs)
    else:
        y = mix / (np.max(np.abs(mix)) + 1e-9) * peak
    save_wav(y, out_wav)
    return check_loop(out_wav, os.path.basename(out_wav))


def build(amb_dir, loop_dir, tmp):
    os.makedirs(amb_dir, exist_ok=True)
    os.makedirs(loop_dir, exist_ok=True)
    os.makedirs(tmp, exist_ok=True)
    for name, fn in (("amb_floresta", amb_floresta), ("amb_raizes", amb_raizes), ("amb_galerias", amb_galerias), ("amb_ninho", amb_ninho)):
        lo, spec, lufs = fn(int(48 * SR))
        w = os.path.join(tmp, name + ".wav")
        render_to(lo, spec, w, lufs=lufs)
        to_ogg(w, os.path.join(amb_dir, name + ".ogg"), quality=4)
    for name, fn, secs, peak in (("memoria_seiva", memoria_seiva, 6.0, 0.5), ("memoria_madeira", memoria_madeira, 8.0, 0.5),
                                 ("memoria_sussurro", memoria_sussurro, 8.0, 0.5), ("lotus_foco", lotus_foco, 8.0, 0.45),
                                 ("lotus_oracao", lotus_oracao, 4.0, 0.55),
                                 ("mosca_zumbido", mosca_zumbido, 2.0, 0.5)):
        lo, spec = fn(int(secs * SR))
        mix = lo.render(spec).mean(axis=0)
        mix = mix / (np.max(np.abs(mix)) + 1e-9) * peak
        out = os.path.join(loop_dir, name + ".wav")
        save_loop_wav(mix, out)
        print(f"[{name}] {secs:.3f}s loop WAV com smpl")


if __name__ == "__main__":
    build(sys.argv[1], sys.argv[2], sys.argv[3])
