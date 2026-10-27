"""Gera sons originais simples. Sem dependências externas; não é necessário para jogar."""
import math
import random
import struct
import wave
from pathlib import Path

DEST = Path(__file__).resolve().parents[1] / "assets"
RATE = 22050
random.seed(17)

def write(name, duration, frequencies, noise=0.0, ambient=False):
    frames = bytearray()
    count = int(duration * RATE)
    for i in range(count):
        t = i / RATE
        envelope = min(1.0, t * 5, (duration - t) * 5) if ambient else math.sin(math.pi * i / count) ** 2
        tone = sum(math.sin(math.tau * (f * t + (0 if ambient else 30 * t * t))) for f in frequencies) / len(frequencies)
        value = envelope * (tone * (1 - noise) + random.uniform(-1, 1) * noise)
        frames.extend(struct.pack("<h", int(max(-1, min(1, value)) * 17000)))
    with wave.open(str(DEST / (name + ".wav")), "wb") as f:
        f.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        f.writeframes(frames)

write("ambience", 12, [110, 164.81, 220.5, 329.63], ambient=True)
write("slash", .12, [480, 610], .65)
write("dash", .17, [190, 290], .5)
write("hit", .10, [150, 225], .35)
write("hurt", .25, [85, 93], .45)
write("lotus", .8, [523.25, 659.25, 783.99])
write("warning", .28, [196, 207.65])
