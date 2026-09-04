# LeLion

Un lion doit colorier la ville en vomissant un arc-en-ciel, tout en évitant des ennemis.
Un jeu absurde et délicieusement coloré, fait avec [Godot 4](https://godotengine.org).

![Capture du jeu](docs/capture.png)

## Comment jouer

Attrape les pastilles de couleur pour enrichir ta gerbe, puis maintiens la touche de vomi
en survolant la ville. La partie est gagnée quand 85 % de la skyline est peinte.
Une soucoupe ou une coccinelle qui te touche, et c'est terminé. Les ennemis arrivent de
plus en plus vite à mesure que la ville se colore.

| Action | Clavier | Manette |
|---|---|---|
| Se déplacer | Flèches, WASD / ZQSD | Stick gauche, croix |
| Vomir | Espace, Entrée | A |
| Pause | Échap, P | Start |

## Lancer le jeu

Ouvre le dossier dans Godot 4.4 ou plus récent et lance la scène principale, ou en ligne
de commande :

```sh
godot .
```

## Structure

```
Scenes/     Main (racine), Lion, Ville, HUD, GameOver, ColorPickup, Soucoupe, Coccinelle
Scripts/    un script par scène + autoloads GameState (état de partie) et Audio (sons)
Shaders/    Ville.gdshader : applique le masque de peinture sur la skyline
Assets/     Sprites (utilisés), Sons (générés), src (matériel de référence, ignoré par Godot)
tests/      smoke_test.gd (headless) et screenshots.gd (captures pilotées)
tools/      generer_sons.py : synthèse des effets sonores
```

La peinture est un masque RGBA de la taille de la skyline, tamponné par blit natif là où
la gerbe touche la ville. La progression est comptée sur une grille de cellules de 8 px qui
ne couvre que les zones opaques de la skyline.

## Tests

Le test de fumée charge la scène principale sans affichage, débloque une couleur, fait
vomir le lion sur la ville, provoque une défaite puis une victoire :

```sh
godot --headless --script tests/smoke_test.gd
```

Pour vérifier visuellement (ouvre une fenêtre quelques secondes et écrit des PNG) :

```sh
godot --rendering-driver opengl3 --script tests/screenshots.gd -- --dossier=/chemin/de/sortie
```

Les sons se régénèrent avec `python3 tools/generer_sons.py`.

## Export

Un preset Web est défini dans `export_presets.cfg`. Avec les templates d'export installés :

```sh
godot --headless --export-release Web export/web/index.html
```
