"""Yıldız Ekspresi ses efektleri ve müzik döngüleri üreticisi.

Gerçek kayıt gelene kadar efektler bu betikle sentezlenir; dosya adları
`Sfx` kimlikleriyle eşleşir, gerçek kayıt geldiğinde aynı adla değiştirilir.

Çalıştırma:  python tool/gen_sfx.py   (assets/sfx altına .wav yazar)
"""

from __future__ import annotations

import math
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")


def env(n, attack=0.005, decay=0.2, sustain=0.0, release=0.05):
    """Basit ADSR zarfı (saniye cinsinden)."""
    a, d, r = int(SR * attack), int(SR * decay), int(SR * release)
    s = max(n - a - d - r, 0)
    parts = [
        np.linspace(0, 1, a, endpoint=False),
        np.linspace(1, sustain, d, endpoint=False),
        np.full(s, sustain),
        np.linspace(sustain, 0, r),
    ]
    e = np.concatenate(parts)
    return e[:n] if len(e) >= n else np.pad(e, (0, n - len(e)))


def tone(freq, dur, wave_fn=np.sin, vibrato=0.0, glide=0.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = freq * (1 + glide * t / dur) * (1 + vibrato * np.sin(2 * math.pi * 6 * t))
    phase = 2 * math.pi * np.cumsum(f) / SR
    return wave_fn(phase)


def noise(dur):
    return np.random.default_rng(1).uniform(-1, 1, int(SR * dur))


def lowpass(x, alpha):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def square(p):
    return np.sign(np.sin(p)) * 0.5


def triangle(p):
    return 2 / math.pi * np.arcsin(np.sin(p))


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def delay(x, offset, gain):
    d = int(SR * offset)
    out = np.concatenate([x, np.zeros(d)])
    out[d:] += x * gain
    return out


def seq(notes, dur, wave_fn=triangle, gap=0.02, decay=None):
    """Nota dizisi: (frekans, uzunluk çarpanı) ya da frekans (None: sus)."""
    out = []
    for item in notes:
        f, m = item if isinstance(item, tuple) else (item, 1.0)
        n = int(SR * dur * m)
        if f is None:
            out.append(np.zeros(n))
            continue
        d = decay if decay is not None else dur * m * 0.9
        out.append(tone(f, dur * m, wave_fn) * env(n, 0.005, d, 0.0, 0.02))
        out.append(np.zeros(int(SR * gap)))
    return np.concatenate(out)


def write(name, x, gain=0.8):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    data = (x * 32767).astype("<i2")
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name}.wav  {len(x) / SR:.2f}s")


N = {  # nota frekansları
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.0,
    "A4": 440.0, "B4": 493.88, "C5": 523.25, "D5": 587.33, "E5": 659.25,
    "F5": 698.46, "G5": 783.99, "A5": 880.0, "C6": 1046.5, "E6": 1318.5,
    "G6": 1568.0, "A3": 220.0, "G3": 196.0, "F3": 174.61, "E3": 164.81,
    "C3": 130.81, "D3": 146.83, "B3": 246.94,
}


def main():
    # --- efektler ---
    # tık: elin bir adıma oturması
    n = int(SR * 0.05)
    write("tick", tone(1800, 0.05, glide=-0.3) * env(n, 0.001, 0.04, 0, 0.01), 0.5)

    # pop: kart/parça yerine oturdu
    n = int(SR * 0.12)
    write("pop", tone(500, 0.12, glide=0.8) * env(n, 0.002, 0.1, 0, 0.02), 0.7)

    # başarı: kısa parlak arpej
    write("success", seq([N["C5"], N["E5"], N["G5"], (N["C6"], 2)], 0.09, triangle), 0.8)

    # büyük kutlama: durak bitti
    write("cheer", mix(
        seq([N["C5"], N["E5"], N["G5"], N["C6"], N["E6"], (N["G6"], 3)], 0.1, triangle),
        delay(seq([N["C4"], N["E4"], N["G4"], N["C5"], N["E5"], (N["G5"], 3)], 0.1, np.sin), 0.0, 0.6),
    ), 0.85)

    # yanlış: yumuşak düşen iki nota (ceza hissi yok)
    write("wrong", seq([(N["E4"], 1.2), (N["C4"], 1.8)], 0.14, triangle), 0.6)

    # düdük: tren düdüğü, iki tonlu
    n = int(SR * 0.9)
    w = mix(tone(N["A4"], 0.9, vibrato=0.01), tone(N["C5"] * 1.01, 0.9, vibrato=0.01) * 0.7,
            tone(N["E5"], 0.9) * 0.3)
    write("whistle", w * env(n, 0.05, 0.1, 0.8, 0.25), 0.8)

    # buhar: filtrelenmiş gürültü
    n = int(SR * 1.2)
    write("steam", lowpass(noise(1.2), 0.15) * env(n, 0.02, 0.4, 0.5, 0.6), 0.7)

    # zil: köprü zili
    n = int(SR * 1.4)
    bell = mix(tone(N["E6"], 1.4), tone(N["E6"] * 2.76, 1.4) * 0.3, tone(N["E6"] * 5.4, 1.4) * 0.1)
    write("bell", bell * env(n, 0.002, 1.2, 0, 0.1), 0.8)

    # dişli: takırtı dizisi
    parts = []
    for i in range(6):
        n = int(SR * 0.06)
        parts.append(tone(300 + i * 40, 0.06, square) * env(n, 0.002, 0.05, 0, 0.01))
        parts.append(np.zeros(int(SR * 0.05)))
    write("gear", np.concatenate(parts), 0.5)

    # çan: fener/kilit açıldı
    n = int(SR * 0.8)
    write("chime", mix(tone(N["G5"], 0.8), tone(N["C6"], 0.8) * 0.6) * env(n, 0.003, 0.7, 0, 0.1), 0.7)

    # damla
    n = int(SR * 0.15)
    write("drop", tone(900, 0.15, glide=-0.5) * env(n, 0.002, 0.12, 0, 0.02), 0.6)

    # horlama: Pamuk
    n = int(SR * 0.7)
    sn = lowpass(noise(0.7), 0.05) * (1 + np.sin(2 * math.pi * 18 * np.arange(n) / SR)) * 0.5
    write("snore", sn * env(n, 0.1, 0.3, 0.6, 0.3), 0.6)

    # kar/rüzgâr
    n = int(SR * 1.5)
    write("wind", lowpass(noise(1.5), 0.03) * env(n, 0.3, 0.4, 0.7, 0.6), 0.5)

    # vagon eşyası eklendi
    write("item", seq([N["G5"], (N["C6"], 2)], 0.1, np.sin), 0.6)

    # tren çuf çuf (döngü)
    parts = []
    for i in range(4):
        n = int(SR * 0.12)
        parts.append(lowpass(noise(0.12), 0.3) * env(n, 0.005, 0.08, 0.1, 0.03) * (1.0 if i % 2 == 0 else 0.6))
        parts.append(np.zeros(int(SR * 0.13)))
    write("chug", np.concatenate(parts), 0.45)

    # --- müzik döngüleri (yumuşak, düşük ses) ---
    def loop(melody, bass, dur, wave_m=triangle):
        m = seq(melody, dur, wave_m, gap=0.01)
        b = seq(bass, dur * 2, np.sin, gap=0.01)
        out = mix(m, b * 0.5)
        return delay(out, 0.25, 0.25)[: len(m)]

    # sonbahar: neşeli, hafif
    write("music_autumn", loop(
        [N["C5"], N["E5"], N["G5"], N["E5"], N["A4"], N["C5"], N["E5"], N["C5"],
         N["F4"], N["A4"], N["C5"], N["A4"], N["G4"], N["B4"], N["D5"], N["B4"]],
        [N["C3"], N["A3"], N["F3"], N["G3"]], 0.22), 0.35)

    # gece: sakin, yavaş
    write("music_night", loop(
        [N["E4"], N["G4"], N["B4"], (None, 1), N["A4"], N["G4"], N["E4"], (None, 1),
         N["D4"], N["F4"], N["A4"], (None, 1), N["G4"], N["E4"], N["D4"], (None, 1)],
        [N["E3"], N["A3"], N["D3"], N["G3"]], 0.4, np.sin), 0.3)

    # kış: parlak, tınlayan
    write("music_winter", loop(
        [N["G5"], N["E5"], N["C5"], N["E5"], N["A5"], N["E5"], N["C5"], N["E5"],
         N["F5"], N["D5"], N["B4"], N["D5"], N["G5"], N["D5"], N["B4"], N["D5"]],
        [N["C3"], N["A3"], N["G3"], N["G3"]], 0.2), 0.32)


if __name__ == "__main__":
    main()
