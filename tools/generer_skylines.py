#!/usr/bin/env python3
"""Génère des silhouettes de skyline (PNG RGBA, bâtiments noirs sur fond transparent)
dans Assets/Sprites, ainsi que le sprite du bonus Gerbe XXL.

Usage : python3 tools/generer_skylines.py
"""
import math
import random
import struct
import zlib
from pathlib import Path

DOSSIER = Path(__file__).resolve().parent.parent / "Assets" / "Sprites"


def ecrire_png(chemin, largeur, hauteur, pixels):
    """pixels : liste de lignes, chaque ligne = bytes RGBA."""
    raw = b"".join(b"\x00" + ligne for ligne in pixels)

    def chunk(typ, data):
        c = struct.pack(">I", len(data)) + typ + data
        return c + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", largeur, hauteur, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    Path(chemin).write_bytes(png)
    print(f"{Path(chemin).name}  {largeur}x{hauteur}")


class Toile:
    def __init__(self, largeur, hauteur):
        self.l, self.h = largeur, hauteur
        self.a = [bytearray(largeur) for _ in range(hauteur)]  # alpha 0/255

    def rect(self, x0, y0, x1, y1):
        for y in range(max(0, y0), min(self.h, y1)):
            ligne = self.a[y]
            for x in range(max(0, x0), min(self.l, x1)):
                ligne[x] = 255

    def triangle(self, xg, xd, y_base, y_sommet):
        """Toit : base entre xg et xd à y_base, sommet centré à y_sommet."""
        xc = (xg + xd) / 2
        for y in range(max(0, y_sommet), min(self.h, y_base)):
            t = (y - y_sommet) / max(1, y_base - y_sommet)
            demi = (xd - xg) / 2 * t
            self.rect(int(xc - demi), y, int(xc + demi) + 1, y + 1)

    def disque(self, cx, cy, r):
        for y in range(max(0, cy - r), min(self.h, cy + r + 1)):
            for x in range(max(0, cx - r), min(self.l, cx + r + 1)):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.a[y][x] = 255

    def png(self, chemin, couleur=(0, 0, 0)):
        lignes = []
        for y in range(self.h):
            ligne = bytearray()
            for x in range(self.l):
                a = self.a[y][x]
                ligne += bytes(couleur) + bytes([a])
            lignes.append(bytes(ligne))
        ecrire_png(chemin, self.l, self.h, lignes)


def metropole(largeur=2000, hauteur=320):
    random.seed(2024)
    t = Toile(largeur, hauteur)
    t.rect(0, hauteur - 24, largeur, hauteur)  # sol
    x = -10
    while x < largeur:
        w = random.randint(28, 90)
        h = random.randint(70, hauteur - 40)
        if random.random() < 0.15:
            h = random.randint(hauteur - 60, hauteur - 12)  # gratte-ciel
        y0 = hauteur - h
        t.rect(x, y0, x + w, hauteur)
        if random.random() < 0.5:  # étage en retrait
            retrait = random.randint(4, w // 4 + 4)
            t.rect(x + retrait, y0 - random.randint(10, 40), x + w - retrait, y0)
        if random.random() < 0.35:  # antenne
            ax = x + random.randint(4, max(5, w - 4))
            t.rect(ax, max(0, y0 - random.randint(20, 60)), ax + 3, y0)
        x += w + random.randint(-6, 14)
    t.png(DOSSIER / "skyline_metropole.png")


def village(largeur=2000, hauteur=180):
    random.seed(77)
    t = Toile(largeur, hauteur)
    t.rect(0, hauteur - 18, largeur, hauteur)  # sol
    x = 10
    eglise_faite = False
    while x < largeur - 40:
        if not eglise_faite and x > largeur * 0.45:
            # église : nef + clocher + flèche
            t.rect(x, hauteur - 70, x + 110, hauteur)
            t.triangle(x - 6, x + 116, hauteur - 70, hauteur - 100)
            t.rect(x + 110, hauteur - 120, x + 140, hauteur)
            t.triangle(x + 104, x + 146, hauteur - 120, hauteur - 175)
            x += 160
            eglise_faite = True
            continue
        if random.random() < 0.2:  # arbre
            cx = x + 14
            t.rect(cx - 3, hauteur - 40, cx + 3, hauteur)
            t.disque(cx, hauteur - 50, random.randint(12, 20))
            x += 40
            continue
        w = random.randint(44, 84)
        h = random.randint(36, 70)
        y0 = hauteur - h
        t.rect(x, y0, x + w, hauteur)
        t.triangle(x - 4, x + w + 4, y0, y0 - random.randint(18, 34))
        if random.random() < 0.6:  # cheminée
            cx = x + random.randint(8, w - 12)
            t.rect(cx, y0 - random.randint(22, 38), cx + 7, y0)
        x += w + random.randint(6, 26)
    t.png(DOSSIER / "skyline_village.png")


def etoile(taille=64):
    t = Toile(taille, taille)
    c = taille / 2
    for y in range(taille):
        for x in range(taille):
            dx, dy = x - c + 0.5, y - c + 0.5
            r = math.hypot(dx, dy)
            ang = math.atan2(dy, dx)
            rayon = c * (0.55 + 0.45 * (0.5 + 0.5 * math.cos(5 * ang)))
            if r <= rayon:
                t.a[y][x] = 255
    t.png(DOSSIER / "etoile.png", couleur=(255, 255, 255))


if __name__ == "__main__":
    metropole()
    village()
    etoile()
