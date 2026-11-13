"""Rebuild Downstack's original synthesized sounds. Python standard library only."""
from array import array
import math
from pathlib import Path
import random
import wave

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
random.seed(19)

def tone(freq, duration, volume=0.45, end=None, texture=0.12):
    result = []
    phase = 0.0
    for n in range(round(RATE * duration)):
        t = n / RATE
        u = t / duration
        hz = freq if end is None else freq * (end / freq) ** u
        phase += 2 * math.pi * hz / RATE
        envelope = min(1.0, t / 0.004) * max(0.0, 1 - u) ** 2
        value = math.sin(phase) + texture * math.sin(phase * 2)
        result.append(volume * envelope * value)
    return result

def phrase(notes, step=0.09, volume=0.35):
    size = round(RATE * (len(notes) * step + 0.28))
    result = [0.0] * size
    for index, freq in enumerate(notes):
        mix(result, tone(freq, 0.23, volume), round(index * step * RATE))
    return result

def mix(target, samples, offset=0):
    for i, v in enumerate(samples):
        if offset + i < len(target):
            target[offset + i] += v

def save(name, samples):
    peak = max(abs(v) for v in samples) or 1
    scale = min(1.0, 0.88 / peak)
    pcm = array("h", (round(max(-1, min(1, v * scale)) * 32767) for v in samples))
    with wave.open(str(OUT / (name + ".wav")), "wb") as f:
        f.setparams((1, 2, RATE, len(pcm), "NONE", "not compressed"))
        f.writeframes(pcm.tobytes())

effects = {
    "move": tone(660, 0.035, 0.16, 490),
    "rotate": tone(420, 0.07, 0.25, 760),
    "hold": phrase([523.25, 783.99], 0.05, 0.25),
    "drop": tone(160, 0.13, 0.6, 48, 0.4),
    "lock": tone(250, 0.055, 0.25, 170),
    "clear1": phrase([659.25, 783.99], 0.065),
    "clear2": phrase([523.25, 659.25, 783.99], 0.065),
    "clear3": phrase([523.25, 659.25, 783.99, 1046.5], 0.065),
    "clear4": phrase([523.25, 659.25, 783.99, 1046.5, 1567.98], 0.07),
    "tspin": phrase([587.33, 739.99, 880, 1174.66], 0.065),
    "perfect": phrase([523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98], 0.085),
    "garbage": tone(90, 0.24, 0.4, 55, 0.5),
    "warning": phrase([440, 440], 0.13, 0.22),
    "tick": tone(520, 0.12, 0.35),
    "go": phrase([659.25, 1046.5], 0.06, 0.4),
    "win": phrase([523.25, 659.25, 783.99, 1046.5], 0.15, 0.4),
    "lose": phrase([440, 349.23, 261.63, 196], 0.15, 0.3),
    "menu": tone(720, 0.045, 0.22, 620),
}
for name, samples in effects.items():
    save(name, samples)

# Original 16-second, eight-bar loop: restrained electronic pulse and arpeggios.
music = [0.0] * (16 * RATE)
chords = [(146.83, 174.61, 220), (116.54, 146.83, 174.61),
          (130.81, 164.81, 196), (130.81, 174.61, 220)]
for bar in range(8):
    chord = chords[bar % len(chords)]
    start = bar * 2.0
    for beat in range(4):
        offset = round((start + beat * 0.5) * RATE)
        mix(music, tone(chord[0] / 2, 0.42, 0.16, texture=0.2), offset)
        mix(music, tone(95, 0.1, 0.18, 40), offset)
    for note in range(8):
        offset = round((start + note * 0.25) * RATE)
        freq = chord[[0, 1, 2, 1, 0, 2, 1, 2][note]] * (4 if bar % 2 else 2)
        mix(music, tone(freq, 0.22, 0.10, texture=0.05), offset)
save("music", music)
print(f"Created {len(effects)} effects and one original loop in {OUT}")
