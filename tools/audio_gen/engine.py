#!/usr/bin/env python3
"""Motor de síntese para as trilhas de Mushrooms Deserve to Die.

Tudo é gerado de forma CIRCULAR: eventos que passam do fim do loop voltam para o começo,
reverbs são convoluções circulares e ruídos são periódicos. Resultado: loop sem emenda.
"""
import os
import re
import subprocess
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100


# ------------------------------------------------------------------ básico
def mtof(m):
    return 440.0 * 2.0 ** ((np.asarray(m, dtype=float) - 69.0) / 12.0)


def _sos(kind, f, order):
    nyq = SR / 2
    if kind == "bp":
        lo, hi = f
        return signal.butter(order, [max(lo, 15) / nyq, min(hi, nyq * 0.95) / nyq], "band", output="sos")
    return signal.butter(order, min(max(f, 15), nyq * 0.95) / nyq, kind, output="sos")


def lp(x, f, o=2):
    return signal.sosfilt(_sos("low", f, o), x, axis=-1)


def hp(x, f, o=2):
    return signal.sosfilt(_sos("high", f, o), x, axis=-1)


def bp(x, lo, hi, o=2):
    return signal.sosfilt(_sos("bp", (lo, hi), o), x, axis=-1)


def smoothstep(x, a, b):
    t = np.clip((np.asarray(x, dtype=float) - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def fade_ends(x, a=0.004, b=0.03):
    x = x.copy()
    na, nb = int(a * SR), int(b * SR)
    if na and len(x) > na:
        x[:na] *= np.linspace(0, 1, na)
    if nb and len(x) > nb:
        x[-nb:] *= np.linspace(1, 0, nb)
    return x


def svf_bp(x, fc, q=2.0):
    """Passa-banda de frequência variável no tempo (para risers)."""
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


# ------------------------------------------------------------------ loop / mix
class Loop:
    def __init__(self, n_samples, seed=1):
        self.n = int(n_samples)
        self.L = self.n / SR
        self.rng = np.random.default_rng(seed)
        self.stems = {}

    def t(self):
        return np.arange(self.n) / SR

    def put(self, stem, x, t0, pan=0.0, gain=1.0):
        """Soma x (mono ou 2xN) no stem a partir de t0 (s), com wrap circular."""
        if stem not in self.stems:
            self.stems[stem] = np.zeros((2, self.n), dtype=np.float32)
        buf = self.stems[stem]
        x = np.asarray(x, dtype=np.float64)
        if x.ndim == 1:
            th = (pan + 1.0) * np.pi / 4.0
            x = np.stack([x * np.cos(th), x * np.sin(th)])
        x = x * gain
        total = x.shape[1]
        pos = int(round(t0 * SR)) % self.n
        k = 0
        while k < total:
            m = min(total - k, self.n - pos)
            buf[:, pos:pos + m] += x[:, k:k + m]
            k += m
            pos = 0

    def pnoise(self, lo=None, hi=None, order=2):
        """Ruído periódico (período = loop), filtrado."""
        r = self.rng.standard_normal(self.n)
        x = np.tile(r, 3)
        if lo and hi:
            x = bp(x, lo, hi, order)
        elif hi:
            x = lp(x, hi, order)
        elif lo:
            x = hp(x, lo, order)
        y = x[self.n:2 * self.n]
        return y / (np.std(y) + 1e-9)

    def drone(self, f, harmonics=((1, 1.0), (2, 0.45), (3, 0.15)), beat_cents=5.0, am=((3, 0.12, 0.0), (5, 0.08, 1.7))):
        """Drone periódico: frequências ajustadas para ciclos inteiros por loop (emenda perfeita)."""
        t = np.arange(self.n) / SR
        y = np.zeros(self.n)
        for c in (-beat_cents / 2, beat_cents / 2):
            k = round(f * 2 ** (c / 1200) * self.L)
            for h, a in harmonics:
                y += a * np.sin(2 * np.pi * (k * h) * t / self.L + 0.37 * h)
        mod = np.ones(self.n)
        for cyc, depth, ph in am:
            mod += depth * np.sin(2 * np.pi * cyc * t / self.L + ph)
        return np.tanh(1.2 * y * mod / 2.0)

    # ---- efeitos circulares
    def _ir(self, rt60, damp, seed, pre=0.018):
        r = np.random.default_rng(seed)
        n = int(rt60 * SR)
        t = np.arange(n) / SR
        env = np.exp(-6.91 * t / rt60)
        dark = lp(r.standard_normal(n), damp * 0.30)
        bright = lp(r.standard_normal(n), damp) * np.exp(-t / (rt60 * 0.10))
        ir = (dark + 0.9 * bright) * env
        ir[: int(0.006 * SR)] *= np.linspace(0, 1, int(0.006 * SR))
        ir = np.concatenate([np.zeros(int(pre * SR)), ir])
        return ir / (np.sqrt(np.sum(ir ** 2)) + 1e-12)

    def _circ_reverb(self, x, rt60, damp, seed):
        out = np.zeros_like(x)
        for ch in range(2):
            ir = self._ir(rt60, damp, seed * 7 + ch * 101)
            full = signal.fftconvolve(x[ch], ir)
            o = full[: self.n].copy()
            tail = full[self.n:]
            o[: len(tail)] += tail[: self.n]
            out[ch] = o
        return out

    def render(self, spec):
        out = np.zeros((2, self.n))
        for i, (name, buf) in enumerate(self.stems.items()):
            s = spec.get(name, {})
            x = buf.astype(np.float64)
            if "delay" in s:
                d, fb, mix = s["delay"]
                dl = np.zeros_like(x)
                cur = x
                for _ in range(7):
                    cur = fb * np.roll(cur[::-1], int(round(d * SR)), axis=1)  # ping-pong
                    dl += cur
                x = x + mix * dl
            if "rev" in s:
                rt, damp, mix = s["rev"]
                wet = self._circ_reverb(x, rt, damp, seed=i + 3)
                x = x * s.get("dry", 1.0) + mix * wet
            out += s.get("gain", 1.0) * x
        return out


# ------------------------------------------------------------------ instrumentos
FORMANTS = {
    "a": [(800, 1.0), (1150, 0.5), (2900, 0.2)],
    "o": [(450, 1.0), (800, 0.45), (2830, 0.15)],
    "u": [(325, 1.0), (700, 0.4), (2530, 0.1)],
    "e": [(400, 1.0), (1700, 0.4), (2600, 0.15)],
}


def _env_ar(n, dur, atk, rel):
    t = np.arange(n) / SR
    a = np.clip(t / max(atk, 1e-3), 0, 1)
    a = a * a * (3 - 2 * a)
    r = np.where(t < dur, 1.0, np.exp(-(t - dur) / (rel / 3.5)))
    return a * r


def pad_note(f, dur, atk=1.5, rel=2.4, cents=(-9, 0, 8), bright=0.3, t0=0.0, seed=0, vib=0.0014):
    """Pad de serra detunada e filtrada; 'bright' pode ser escalar ou função do tempo absoluto."""
    r = np.random.default_rng(seed)
    n = int((dur + rel) * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for c in cents:
        drift = 1 + vib * np.sin(2 * np.pi * (0.07 + 0.06 * r.random()) * t + r.uniform(0, 6.28))
        ph = np.cumsum(f * 2 ** (c / 1200) * drift) / SR
        sig += 2 * (ph % 1.0) - 1
    sig /= len(cents)
    dark = lp(sig, min(max(f * 3.0, 280), 1300))
    light = lp(sig, min(max(f * 9.0, 1500), 5200))
    b = bright(t0 + t) if callable(bright) else bright
    return (dark * (1 - b) + light * b) * _env_ar(n, dur, atk, rel)


def sine_pad(f, dur, atk=1.8, rel=2.8, cents=(-7, 0, 6), trem=(0.31, 0.25), seed=0):
    r = np.random.default_rng(seed)
    n = int((dur + rel) * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for c in cents:
        ph = 2 * np.pi * f * 2 ** (c / 1200) * t + r.uniform(0, 6.28)
        y += np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
    y /= len(cents)
    y *= 1 - trem[1] * (0.5 + 0.5 * np.sin(2 * np.pi * trem[0] * t + r.uniform(0, 6.28)))
    return y * _env_ar(n, dur, atk, rel)


def choir_note(f, dur, vowel="o", atk=1.4, rel=2.2, seed=0):
    r = np.random.default_rng(seed)
    n = int((dur + rel) * SR)
    t = np.arange(n) / SR
    vib = 0.005 * np.minimum(1, t / 1.5) * np.sin(2 * np.pi * (5.0 + 0.4 * r.random()) * t + r.uniform(0, 6.28))
    src = np.zeros(n)
    for c in (-12, 0, 11):
        ph = np.cumsum(f * 2 ** (c / 1200) * (1 + vib)) / SR
        src += 2 * (ph % 1.0) - 1
    src /= 3
    y = np.zeros(n)
    for fc, g in FORMANTS[vowel]:
        y += g * bp(src, fc * 0.9, fc * 1.12)
    y += 0.25 * lp(r.standard_normal(n), 3000) * bp(src, 300, 1200) * 0.0  # reservado
    return y * _env_ar(n, dur, atk, rel)


def pluck(f, dur=2.5, tau=1.0, harm=7, click=0.12, ting=0.0, vel=1.0, seed=0):
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for h in range(1, harm + 1):
        fh = f * h
        if fh > 9500:
            break
        y += (1.0 / h ** 1.15) * np.sin(2 * np.pi * fh * t) * np.exp(-t * (1 + 0.55 * (h - 1)) / tau)
    if ting:
        y += ting * np.sin(2 * np.pi * f * 5.43 * t) * np.exp(-t / 0.07)
    c = int(0.012 * SR)
    y[:c] += click * bp(r.standard_normal(c), 1800, 7000) * np.exp(-np.arange(c) / SR / 0.003)
    y[: int(0.0015 * SR)] *= np.linspace(0, 1, int(0.0015 * SR))
    return fade_ends(y * vel, 0, 0.03)


def kalimba(f, dur=2.6, vel=1.0, seed=0):
    return pluck(f, dur, tau=1.15, harm=4, click=0.10, ting=0.20, vel=vel, seed=seed)


def harp(f, dur=3.2, vel=1.0, seed=0):
    return pluck(f, dur, tau=1.9, harm=8, click=0.05, ting=0.0, vel=vel, seed=seed)


def glass(f, dur=4.0, atk=0.02, tau=1.8, vel=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for ratio, amp, dec in [(1.0, 1.0, 1.0), (1.0035, 0.7, 1.0), (2.756, 0.30, 0.55), (5.404, 0.14, 0.30), (8.93, 0.06, 0.18)]:
        if f * ratio > 11000:
            continue
        y += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-t / (tau * dec))
    a = np.clip(t / max(atk, 1e-3), 0, 1)
    return fade_ends(y * a * vel, 0, 0.05)


def rev_glass(f, dur=2.5, vel=1.0):
    y = glass(f, dur, atk=0.003, tau=dur / 2.6, vel=vel)[::-1].copy()
    return fade_ends(y, 0.02, 0.004)


def sub(f, dur, atk=0.9, rel=1.8, drive=1.6):
    n = int((dur + rel) * SR)
    t = np.arange(n) / SR
    y = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.0042 * t)
    y = np.tanh(drive * y / 1.5)
    return y * _env_ar(n, dur, atk, rel)


def thump(f0=95, f1=44, dur=0.5, tau=0.12, vel=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t / 0.035)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / tau)
    y[: int(0.002 * SR)] *= np.linspace(0, 1, int(0.002 * SR))
    return fade_ends(y * vel, 0, 0.02)


def tok(f=330, vel=1.0, seed=0):
    r = np.random.default_rng(seed)
    n = int(0.16 * SR)
    t = np.arange(n) / SR
    fr = f * (1 + 0.55 * np.exp(-t / 0.012))
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / 0.032)
    y += 0.4 * np.sin(2 * np.pi * np.cumsum(fr * 2.38) / SR) * np.exp(-t / 0.018)
    y += 0.5 * bp(r.standard_normal(n), 1400, 4200) * np.exp(-t / 0.006)
    return fade_ends(y * vel, 0.0008, 0.02)


def shaker(vel=1.0, seed=0, length=0.06):
    r = np.random.default_rng(seed)
    n = int(length * SR)
    t = np.arange(n) / SR
    y = hp(r.standard_normal(n), 5200) * np.minimum(1, t / 0.004) * np.exp(-t / 0.022)
    return fade_ends(y * vel, 0, 0.01)


def cricket(f=4400, groups=3, seed=0):
    r = np.random.default_rng(seed)
    pulse, gap = int(0.010 * SR), int(0.042 * SR)
    n = groups * (pulse + gap) + pulse
    y = np.zeros(n)
    for g in range(groups):
        i = g * (pulse + gap)
        tt = np.arange(pulse) / SR
        y[i:i + pulse] += np.sin(2 * np.pi * (f * (1 + 0.02 * r.standard_normal())) * tt) * np.hanning(pulse)
    return y


def bird(r, base=3200):
    notes = r.integers(2, 6)
    y = np.zeros(int(0.9 * SR))
    pos = 0
    for _ in range(notes):
        d = r.uniform(0.05, 0.12)
        n = int(d * SR)
        t = np.arange(n) / SR
        fa = base * r.uniform(0.75, 1.35)
        fb = fa * r.choice([0.7, 0.8, 1.25, 1.4])
        f = fa + (fb - fa) * (t / d) ** 1.3
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.15 * np.sin(4 * np.pi * np.cumsum(f) / SR)
        s *= np.hanning(n)
        if pos + n < len(y):
            y[pos:pos + n] += s
        pos += n + int(r.uniform(0.03, 0.09) * SR)
        if pos > len(y) - int(0.15 * SR):
            break
    return fade_ends(y[: pos + int(0.02 * SR)], 0, 0.01)


def whisper(dur=3.0, vowel="o", seed=0):
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    nz = r.standard_normal(n)
    y = np.zeros(n)
    for fc, g in FORMANTS[vowel]:
        y += g * bp(nz, fc * 0.92, fc * 1.1)
    env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2.2
    return y * env * (0.7 + 0.3 * np.sin(2 * np.pi * 5.1 * t))


def riser(dur=3.0, lo=300, hi=6500, seed=0, tail=1.5):
    """Subida de ruído filtrado que passa pelo tempo forte e se dissipa em 'tail' s (sem corte seco)."""
    r = np.random.default_rng(seed)
    n = int((dur + tail) * SR)
    t = np.arange(n) / SR
    prog = np.clip(t / dur, 0, 1)
    fc = lo * (hi / lo) ** (prog ** 1.4)
    y = svf_bp(r.standard_normal(n), fc, 1.4)
    y /= np.max(np.abs(y)) + 1e-9
    amp = np.where(t < dur, (t / dur) ** 2.2, np.exp(-(t - dur) / 0.45))
    return fade_ends(y * amp, 0.01, 0.12)


# ------------------------------------------------------------------ master / export / verificação
def lufs_of(path):
    p = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true", "-f", "null", "-"],
                       capture_output=True, text=True)
    txt = p.stderr
    sm = txt[txt.rfind("Summary:"):]
    i = float(re.search(r"I:\s+(-?[\d.]+)\s+LUFS", sm).group(1))
    pk = re.search(r"Peak:\s+(-?[\d.]+)\s+dBFS", sm)
    return i, (float(pk.group(1)) if pk else None)


def master(x, path_tmp, target_lufs=-19.0, hp_hz=28, ceiling=0.93):
    n = x.shape[1]
    t3 = np.tile(x, (1, 3))
    y = signal.sosfilt(_sos("high", hp_hz, 2), t3, axis=1)[:, n:2 * n]  # HP circular
    wavfile.write(path_tmp, SR, (np.clip(y, -1, 1) * 32767).astype(np.int16).T)
    I, _ = lufs_of(path_tmp)
    g = 10 ** ((target_lufs - I) / 20)
    y = y * g
    pk = np.max(np.abs(y))
    if pk > ceiling:
        y = ceiling * np.tanh(y / ceiling)  # soft limit (memoryless => segue periódico)
    return y


def save_wav(y, path, seed=5):
    r = np.random.default_rng(seed)
    dith = (r.random(y.shape) - r.random(y.shape)) / 32768.0
    q = np.clip((y + dith) * 32767.0, -32768, 32767).round().astype(np.int16)
    wavfile.write(path, SR, q.T)


def check_loop(path, label=""):
    sr, x = wavfile.read(path)
    f = x.astype(np.float64).T / 32768.0
    n = f.shape[1]
    seam = np.abs(f[:, 0] - f[:, -1]).max()
    step = np.abs(np.diff(f, axis=1)).mean()
    two = np.concatenate([f, f], axis=1)
    h = hp(two, 6000, 4)
    w = int(0.01 * SR)
    seam_hf = np.sqrt((h[:, n - w:n + w] ** 2).mean())
    ref = np.sqrt((h ** 2).mean())
    win = int(0.25 * SR)
    r0 = np.sqrt((two[:, n - win:n] ** 2).mean())
    r1 = np.sqrt((two[:, n:n + win] ** 2).mean())
    pk = np.abs(f).max()
    print(f"[{label}] {n / sr:.3f}s | pico {20 * np.log10(pk):.1f} dBFS | salto na emenda {seam:.4f} (passo medio {step:.4f}) | "
          f"HF na emenda/ref {seam_hf / ref:.2f} | RMS antes/depois da emenda {r0:.4f}/{r1:.4f}")
    return dict(seam=seam, step=step, hf=seam_hf / ref, r0=r0, r1=r1, peak=pk)


NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]


def chord_check(path, sched, skip=1.3):
    """sched: lista de (nome, t0, t1, [midis]). Mede quanto da energia (60-1500 Hz) cai nas notas do acorde."""
    sr, x = wavfile.read(path)
    m = x.astype(np.float64).mean(axis=1) / 32768.0
    worst = 100.0
    for name, t0, t1, midis in sched:
        pcs = {NAMES[int(v) % 12] for v in midis}
        seg = m[int((t0 + skip) * sr): int(t1 * sr)]
        if len(seg) < 4096:
            continue
        S = np.abs(np.fft.rfft(seg * np.hanning(len(seg)))) ** 2
        f = np.fft.rfftfreq(len(seg), 1 / sr)
        sel = (f > 60) & (f < 1500)
        pc = np.round(12 * np.log2(f[sel] / 440.0) + 69).astype(int) % 12
        c = np.bincount(pc, weights=S[sel], minlength=12)
        c = c / c.sum()
        inside = sum(c[NAMES.index(n)] for n in pcs) * 100
        worst = min(worst, inside)
        top = [NAMES[i] for i in np.argsort(c)[::-1][:len(pcs)]]
        print(f"   {name:14s} notas no acorde: {inside:5.1f}% | top {sorted(top)} vs {sorted(pcs)}")
    print(f"   pior acorde: {worst:.1f}%")
    return worst


# ------------------------------------------------------------------ percussão de combate e camadas de perigo
def taiko(f=70.0, vel=1.0, seed=0, dur=0.7):
    """Tambor grave tipo taiko: corpo com queda de afinação + pele + tapa."""
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    fr = f * (1 + 0.9 * np.exp(-t / 0.025))
    body = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / 0.22)
    skin = bp(r.standard_normal(n), 150, 1500) * np.exp(-t / 0.03) * 0.5
    slap = bp(r.standard_normal(n), 1500, 5000) * np.exp(-t / 0.006) * 0.25
    y = np.tanh(1.5 * (body + skin + slap)) / np.tanh(1.5)
    y[: int(0.0015 * SR)] *= np.linspace(0, 1, int(0.0015 * SR))
    return fade_ends(y * vel, 0, 0.03)


def snare(vel=1.0, seed=0, dur=0.35):
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    tone = (np.sin(2 * np.pi * 146.8 * t) + 0.6 * np.sin(2 * np.pi * 220.0 * t)) * np.exp(-t / 0.05)  # Ré/Lá
    wires = bp(r.standard_normal(n), 1500, 7500) * np.exp(-t / 0.11)
    y = 0.6 * tone + 0.8 * wires
    y[: int(0.001 * SR)] *= np.linspace(0, 1, int(0.001 * SR))
    return fade_ends(y * vel, 0, 0.03)


def danger_layer(lo, beat, chords, seed=0, swing=0.0):
    """Camada de perigo/combate para sobrepor a uma faixa de exploração.
    chords: lista de (t0, t1, pad_midis, raiz_midi). Mesmo comprimento/andamento da faixa base."""
    r = np.random.default_rng(seed)
    s16 = beat / 4
    bar = 4 * beat
    nbars = int(round(lo.L / bar))
    for b in range(nbars):
        tb = b * bar
        root, pad = None, None
        for (t0, t1, p, rt) in chords:
            if t0 - 1e-6 <= tb < t1:
                root, pad = rt, p
        if root is None:
            root, pad = chords[0][3], chords[0][2]
        fill = (b % 4) == 3
        for step, vel in ((0, 1.0), (6, 0.6), (8, 0.9), (11, 0.55)):
            lo.put("dr", taiko(float(mtof(root)), vel, seed=b * 17 + step), tb + step * s16, gain=0.30)
        for step, vel in ((3, 0.5), (14, 0.7)):
            lo.put("dr", taiko(float(mtof(root + 12)), vel, seed=b * 31 + step, dur=0.45), tb + step * s16, pan=0.25, gain=0.20)
        if fill:
            for i, step in enumerate((12, 13, 14, 15)):
                lo.put("dr", taiko(float(mtof(root + 12)) * (1.25 - 0.08 * i), 0.45 + 0.15 * i, seed=b * 7 + step, dur=0.4), tb + step * s16, pan=-0.25, gain=0.20)
        for step in range(0, 16, 2):
            off = swing * s16 if (step // 2) % 2 else 0.0
            lo.put("dr", shaker(0.55 if step % 4 == 0 else 0.32, seed=b * 5 + step), tb + step * s16 + off, pan=0.35, gain=0.05)
        for step in (4, 12):
            lo.put("dr", tok(float(mtof(pad[1] + 12)), 0.7, seed=b + step), tb + step * s16, pan=-0.3, gain=0.06)
        seq = [0, 0, 12, 0, 7, 0, 12, 7]
        for i, st in enumerate(seq):
            lo.put("ost", pluck(float(mtof(root + 12 + st)), 0.5, tau=0.22, harm=5, click=0.06, vel=0.9 if i % 2 == 0 else 0.7),
                   tb + i * 2 * s16, gain=0.14)
        for i in range(8):
            m = pad[2 + (i % 2)] + 12
            lo.put("pulse", pluck(float(mtof(m)), 0.35, tau=0.12, harm=6, click=0.02, vel=0.6), tb + i * 2 * s16 + s16,
                   pan=(-0.4 if i % 2 else 0.4), gain=0.045)
    return {"dr": dict(rev=(1.4, 5000, 0.14)), "ost": dict(rev=(1.0, 3000, 0.08)), "pulse": dict(rev=(2.2, 6500, 0.30))}


def to_ogg(wav_path, ogg_path, quality=5, mono=False):
    cmd = ["ffmpeg", "-v", "error", "-y", "-i", wav_path]
    if mono:
        cmd += ["-ac", "1"]
    cmd += ["-c:a", "libvorbis", "-q:a", str(quality), ogg_path]
    subprocess.run(cmd, check=True)


def save_loop_wav(y, path):
    """WAV mono 16-bit com chunk 'smpl' (loop forward 0..n): o importador do Godot detecta o loop
    (edit/loop_mode = Detect From WAV) e a emenda fica exata por amostra, sem artefatos do Vorbis."""
    import struct
    y = np.asarray(y, dtype=float)
    if y.ndim > 1:
        y = y.mean(axis=0)
    q = np.clip(np.round(y * 32767.0), -32768, 32767).astype("<i2").tobytes()
    n = len(q) // 2
    fmt = struct.pack("<4sIHHIIHH", b"fmt ", 16, 1, 1, SR, SR * 2, 2, 16)
    data = struct.pack("<4sI", b"data", len(q)) + q
    smpl_body = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0) + struct.pack("<6I", 0, 0, 0, n, 0, 0)
    smpl = struct.pack("<4sI", b"smpl", len(smpl_body)) + smpl_body
    body = b"WAVE" + fmt + data + smpl
    with open(path, "wb") as fh:
        fh.write(struct.pack("<4sI", b"RIFF", len(body)) + body)
    return n
