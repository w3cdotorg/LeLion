#!/usr/bin/env python3
"""Synthétise la musique du jeu en couches synchronisées (Assets/Sons, 22,05 kHz mono 16 bits).

Deux ensembles de trois pistes de même durée, jouées ensemble et mixées selon la progression :
- ville  : Do majeur, 120 BPM (I V vi IV)      → ville_base, ville_arp, ville_melodie
- boss   : La mineur, 132 BPM (i VI iv V)      → boss_base, boss_arp, boss_melodie
« base » = grosse caisse, charley, basse. « arp » = arpèges. « melodie » = lead.
Usage : python3 tools/generer_musique.py
"""
import math
import random
import struct
import wave
from pathlib import Path

SR = 22050
MESURES = 8
DOSSIER = Path(__file__).resolve().parent.parent / "Assets" / "Sons"


def note(n):
    """n en demi-tons par rapport à La4 (440 Hz)."""
    return 440.0 * 2 ** (n / 12.0)


def carre(ph, duty=0.25):
    return 1.0 if (ph % 1.0) < duty else -1.0


def triangle(ph):
    return 4.0 * abs((ph % 1.0) - 0.5) - 1.0


def env_note(t, dur, decay=6.0):
    return math.exp(-decay * t) if t < dur else 0.0


def ecrire(nom, out):
    m = max(abs(x) for x in out) or 1.0
    data = b"".join(struct.pack("<h", int(max(-1, min(1, x / m * 0.85)) * 32767)) for x in out)
    with wave.open(str(DOSSIER / f"{nom}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(f"{nom}.wav  {len(out) / SR:.1f} s  {len(data) / 1024:.0f} Ko")


class Ensemble:
    def __init__(self, nom, bpm, progression, arpeges, melodie, duty_lead=0.25, basse_gain=0.35):
        self.nom = nom
        self.beat = 60.0 / bpm
        self.croche = self.beat / 2
        self.duree = MESURES * 4 * self.beat
        self.n = int(SR * self.duree)
        self.progression = progression
        self.arpeges = arpeges
        self.melodie = melodie
        self.duty_lead = duty_lead
        self.basse_gain = basse_gain

    def vide(self):
        return [0.0] * (self.n + SR)  # marge pour les queues de notes, tronquée à l'écriture

    def base(self):
        out = self.vide()
        for mesure in range(MESURES):
            racine = self.progression[mesure]
            t0 = mesure * 4 * self.beat
            for temps in range(4):
                n_basse = racine - 12 if temps % 2 == 0 else racine - 12 + 7
                f = note(n_basse)
                debut = int((t0 + temps * self.beat) * SR)
                for i in range(int(self.beat * 0.9 * SR)):
                    t = i / SR
                    out[debut + i] += self.basse_gain * triangle(f * t) * env_note(t, self.beat, 2.5)
        for temps in range(MESURES * 4):
            debut = int(temps * self.beat * SR)
            for i in range(int(0.12 * SR)):
                t = i / SR
                f = 120 * math.exp(-18 * t) + 40
                out[debut + i] += 0.5 * math.sin(2 * math.pi * f * t) * math.exp(-22 * t)
            debut_ch = int((temps * self.beat + self.croche) * SR)
            for i in range(int(0.04 * SR)):
                t = i / SR
                out[debut_ch + i] += 0.12 * random.uniform(-1, 1) * math.exp(-90 * t)
        return out[: self.n]

    def arp(self):
        out = self.vide()
        for mesure in range(MESURES):
            arp = self.arpeges[self.progression[mesure]]
            t0 = mesure * 4 * self.beat
            for k in range(8):
                f = note(arp[k])
                debut = int((t0 + k * self.croche) * SR)
                for i in range(int(self.croche * SR)):
                    t = i / SR
                    out[debut + i] += 0.12 * carre(f * t, 0.5) * env_note(t, self.croche, 9.0)
        return out[: self.n]

    def lead(self):
        out = self.vide()
        for mesure in range(MESURES):
            t0 = mesure * 4 * self.beat
            phrase = self.melodie[mesure]
            for k, deg in enumerate(phrase):
                if deg is None:
                    continue
                f = note(deg)
                debut = int((t0 + k * self.croche) * SR)
                tenue = k + 1 < 8 and phrase[k + 1] is None
                longueur = self.croche * (1.9 if tenue else 0.95)
                for i in range(int(longueur * SR)):
                    t = i / SR
                    vib = 1.0 + 0.004 * math.sin(2 * math.pi * 6 * t)
                    out[debut + i] += 0.22 * carre(f * vib * t, self.duty_lead) * env_note(t, longueur, 3.0)
        return out[: self.n]

    def ecrire_tout(self):
        random.seed(11)
        ecrire(f"{self.nom}_base", self.base())
        ecrire(f"{self.nom}_arp", self.arp())
        ecrire(f"{self.nom}_melodie", self.lead())


# Degrés en demi-tons depuis La4 : C4=-9 D4=-7 E4=-5 F4=-4 G4=-2 A4=0 B4=2 C5=3 D5=5 E5=7 G5=10
C, D, E, F, G, A, B, C5, D5, E5, G5 = -9, -7, -5, -4, -2, 0, 2, 3, 5, 7, 10
VILLE = Ensemble(
    "ville", 120,
    progression=[C, C, G, G, A, A, F, G],
    arpeges={
        C: [C, E, G, C5, E5, C5, G, E],
        G: [G - 12, B - 12, D, G, B, G, D, B - 12],
        A: [A - 12, C, E, A, C5, A, E, C],
        F: [F - 12, A - 12, C, F, A, F, C, A - 12],
    },
    melodie=[
        [E5, None, D5, C5, None, E5, G5, None],
        [E5, D5, None, C5, D5, None, G, None],
        [D5, None, B, G, None, B, D5, None],
        [D5, B, None, G, A, None, B, None],
        [C5, None, E5, A, None, C5, E5, None],
        [E5, C5, None, A, C5, None, E5, None],
        [F, A, C5, None, A, C5, F, None],
        [G, B, D5, None, B, D5, G5, None],
    ],
)

# La mineur : A3=-12, C4=-9, D4=-7, E4=-5, F4=-4, G#4=-1, A4=0, C5=3, E5=7, F5=8, G#5=11
Am, Fm_, Dm, Em = A - 12, F - 12, D - 12, E - 12
GS4, F5, GS5 = -1, 8, 11
BOSS = Ensemble(
    "boss", 132,
    progression=[Am, Am, Fm_, Fm_, Dm, Dm, Em, Em],
    arpeges={
        Am: [Am, C, E, A, C5, A, E, C],
        Fm_: [Fm_, A - 12, C, F, A, F, C, A - 12],
        Dm: [Dm, F - 12, A - 12, D, F, D, A - 12, F - 12],
        Em: [Em, GS4 - 12, B - 12, E, GS4, E, B - 12, GS4 - 12],
    },
    melodie=[
        [A, None, C5, E5, None, C5, A, None],
        [E5, None, F5, E5, C5, None, A, None],
        [F, A, C5, None, F5, None, C5, None],
        [C5, A, F, None, E, None, F, None],
        [D, F, A, None, D5, None, A, None],
        [F, D, None, F, A, None, C5, None],
        [E, GS4, B, None, E5, None, GS5, None],
        [E5, None, D5, None, B, None, GS4, None],
    ],
    duty_lead=0.5,
    basse_gain=0.45,
)

if __name__ == "__main__":
    DOSSIER.mkdir(parents=True, exist_ok=True)
    (DOSSIER / "musique.wav").unlink(missing_ok=True)
    (DOSSIER / "musique.wav.import").unlink(missing_ok=True)
    VILLE.ecrire_tout()
    BOSS.ecrire_tout()
