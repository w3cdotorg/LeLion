# LeLion

Un lion doit colorier la ville en vomissant un arc-en-ciel, tout en évitant des ennemis.
Un jeu absurde et délicieusement coloré, fait avec [Godot 4](https://godotengine.org).

**Jouer dans le navigateur : <https://w3cdotorg.github.io/LeLion/>** (déployé par la CI à chaque push sur `main`).

![Capture du jeu](docs/capture.png)

![Le peintre géant au Village](docs/boss.png)

## Comment jouer

Attrape les pastilles de couleur pour enrichir ta gerbe, puis maintiens la touche de vomi
en survolant la ville. La partie est gagnée quand 85 % de la skyline est peinte.
Une soucoupe ou une coccinelle qui te touche, et c'est terminé. Les ennemis arrivent de
plus en plus vite à mesure que la ville se colore.

Trois difficultés se choisissent sur l'écran titre : **Facile** (3 cœurs, des cœurs à
ramasser réapparaissent), **Moyen** (3 cœurs, sans rab) et **Hardcore** (un seul coup et
c'est fini). Après un coup, le lion clignote et reste invulnérable une seconde et demie.
Puis trois niveaux (Skyline, Métropole, Village), avec ton meilleur temps pour la difficulté
choisie. Au Village, un peintre géant s'invite : il s'annonce d'un côté de l'écran, avance
jusqu'au centre, marque une pause et repart, puis revient de l'autre côté. Peins la moitié
qu'il libère, traverse quand il recule. Une étoile arc-en-ciel apparaît de temps en temps : ramasse-la
pour doubler la largeur de ta gerbe pendant huit secondes.

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
Scenes/     Titre, Main (partie), Lion, Ville, HUD, GameOver, ColorPickup, BonusPickup, CoeurPickup, Soucoupe, Coccinelle, Boss
Scripts/    un script par scène + autoloads GameState (partie, vies, niveaux, difficultés), Scores (records), Audio (sons)
Shaders/    Ville.gdshader : applique le masque de peinture sur la skyline
Assets/     Sprites (utilisés), Sons (générés), src (matériel de référence, ignoré par Godot)
tests/      smoke_test.gd (headless) et screenshots.gd (captures pilotées)
tools/      generer_sons.py (effets sonores) et generer_skylines.py (skylines, étoile, cœur)
```

La peinture est un masque RGBA de la taille de la skyline, tamponné par blit natif là où
la gerbe touche la ville. La progression est comptée sur une grille de cellules de 8 px qui
ne couvre que les zones opaques de la skyline. Un niveau, c'est simplement un PNG de
silhouette : ajoute une entrée dans `GameState.NIVEAUX` pour en créer un, avec `"boss": true`
pour y faire venir le peintre. Sa collision est générée depuis l'alpha de son sprite SVG, donc
remplacer `Assets/Sprites/boss_peintre.svg` suffit à changer sa silhouette.

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

Les sons se régénèrent avec `python3 tools/generer_sons.py`, les skylines avec
`python3 tools/generer_skylines.py`.

## Export et CI

Un preset Web est défini dans `export_presets.cfg`. Avec les templates d'export installés :

```sh
godot --headless --export-release Web export/web/index.html
```

Le workflow `.github/workflows/ci.yml` installe Godot, lance le smoke test et exporte en Web
à chaque push ou pull request. Sur `main`, il déploie le résultat sur GitHub Pages.
