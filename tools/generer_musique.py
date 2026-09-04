#!/usr/bin/env python3
"""Synthétise une boucle chiptune (Assets/Sons/musique.wav, 22,05 kHz mono 16 bits, 16 s).

Do majeur, 120 BPM, 8 mesures : basse triangle (I V vi IV), lead carré, grosse caisse, charley.
Usage : python3 tools/generer_musique.py
"""
import math
import random
import struct
import wave
from pathlib import Path

SR = 22050
BPM = 120
BEAT = 60.0 / BPM
MESURES = 8
DUREE = MESURES * 4 * BEAT
DOSSIER = Path(__file__).resolve().parent.parent / "Assets" / "Sons"


def note(n):
    """n en demi-tons par rapport à La4 (440 Hz)."""
    return 440.0 * 2 ** (n / 12.0)


# Degrés (demi-tons depuis La4) : C4=-9, D4=-7, E4=-5, F4=-4, G4=-2, A4=0, B4=2, C5=3
C, D, E, F, G, A, B, C5, D5, E5, G5 = -9, -7, -5, -4, -2, 0, 2, 3, 5, 7, 10
PROGRESSION = [C, C, G, G, A, A, F, G]  # racine de basse par mesure
ARPEGES = {
    C: [C, E, G, C5, E5, C5, G, E],
    G: [G - 12, B - 12, D, G, B, G, D, B - 12],
    A: [A - 12, C, E, A, C5, A, E, C],
    F: [F - 12, A - 12, C, F, A, F, C, A - 12],
}
MELODIE = [  # une phrase par mesure, 8 croches (None = silence)
    [E5, None, D5, C5, None, E5, G5, None],
    [E5, D5, None, C5, D5, None, G, None],
    [D5, None, B, G, None, B, D5, None],
    [D5, B, None, G, A, None, B, None],
    [C5, None, E5, A, None, C5, E5, None],
    [E5, C5, None, A, C5, None, E5, None],
    [F, A, C5, None, A, C5, F, None],
    [G, B, D5, None, B, D5, G5, None],
]


def carre(ph, duty=0.25):
    return 1.0 if (ph % 1.0) < duty else -1.0


def triangle(ph):
    return 4.0 * abs((ph % 1.0) - 0.5) - 1.0


def env_note(t, dur, decay=6.0):
    return math.exp(-decay * t) if t < dur else 0.0


def main():
    random.seed(11)
    n = int(SR * DUREE)
    out = [0.0] * n
    croche = BEAT / 2

    # basse + arpège + mélodie, note par note
    for mesure in range(MESURES):
        racine = PROGRESSION[mesure]
        t0 = mesure * 4 * BEAT
        # basse : racine sur les temps 1 et 3, quinte sur 2 et 4, une octave sous
        for temps in range(4):
            n_basse = racine - 12 if temps % 2 == 0 else racine - 12 + 7
            f = note(n_basse)
            debut = int((t0 + temps * BEAT) * SR)
            for i in range(int(BEAT * 0.9 * SR)):
                t = i / SR
                out[debut + i] += 0.35 * triangle(f * t) * env_note(t, BEAT, 2.5)
        # arpège en croches, doux
        arp = ARPEGES[racine]
        for k in range(8):
            f = note(arp[k])
            debut = int((t0 + k * croche) * SR)
            for i in range(int(croche * SR)):
                t = i / SR
                out[debut + i] += 0.12 * carre(f * t, 0.5) * env_note(t, croche, 9.0)
        # mélodie
        for k, deg in enumerate(MELODIE[mesure]):
            if deg is None:
                continue
            f = note(deg)
            debut = int((t0 + k * croche) * SR)
            longueur = croche * (1.9 if k + 1 < 8 and MELODIE[mesure][k + 1] is None else 0.95)
            for i in range(int(longueur * SR)):
                t = i / SR
                vib = 1.0 + 0.004 * math.sin(2 * math.pi * 6 * t)
                out[debut + i] += 0.22 * carre(f * vib * t, 0.25) * env_note(t, longueur, 3.0)

    # percussions : grosse caisse sur chaque temps, charley sur les contretemps
    for temps in range(MESURES * 4):
        debut = int(temps * BEAT * SR)
        for i in range(int(0.12 * SR)):
            t = i / SR
            f = 120 * math.exp(-18 * t) + 40
            out[debut + i] += 0.5 * math.sin(2 * math.pi * f * t) * math.exp(-22 * t)
        debut_ch = int((temps * BEAT + croche) * SR)
        for i in range(int(0.04 * SR)):
            t = i / SR
            out[debut_ch + i] += 0.12 * random.uniform(-1, 1) * math.exp(-90 * t)

    m = max(abs(x) for x in out)
    data = b"".join(struct.pack("<h", int(max(-1, min(1, x / m * 0.85)) * 32767)) for x in out)
    DOSSIER.mkdir(parents=True, exist_ok=True)
    with wave.open(str(DOSSIER / "musique.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(f"musique.wav  {DUREE:.1f} s  {len(data) / 1024:.0f} Ko")


if __name__ == "__main__":
    main()
