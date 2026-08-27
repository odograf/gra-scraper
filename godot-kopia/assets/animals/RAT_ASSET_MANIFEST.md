# Szczór — manifest assetu

Data: 2026-08-26

## Pliki

- `sewer_rat_sheet_v1_generated_source.png` — jedyny wygenerowany arkusz źródłowy; 1672×941 RGB z wypaloną szachownicą.
- `sewer_rat_sheet_v1.png` — finalny arkusz używany w grze; 2048×1536 RGBA, siatka 4×4, klatka 512×384.
- `tools/prepare_rat_sprite.py` — deterministyczne usunięcie tła, rozdzielenie sylwetek i przepakowanie.

Wspólna kotwica łap: `(256, 330)`. Skala w Godot: `0.29`. Rzędy: `idle`, `walk`, `attack`, `defeat`. Generator nie zwrócił kanału alfa, dlatego zgodnie z zasadą jednego płatnego renderu nie wykonano kolejnej generacji. Jasne tło zostało usunięte lokalnie bez zmiany sylwetek.

## Generowanie

Tryb: wbudowane ImageGen, generowanie z obrazem referencyjnym / `style-transfer`. Model nie został ujawniony przez narzędzie.

Dokładny prompt:

```text
Use case: style-transfer
Asset type: production-ready animated enemy sprite sheet for a top-down 2D Godot game.
Input image: Image 1 is a style, camera-angle, rendering-density, outline, lighting and palette reference only. Do not reproduce the dog or its anatomy.
Primary request: create one complete sprite sheet for an enemy named "Szczór", an oversized, thin sewer rat that is an easy early-game opponent.
Subject: one consistent adult rat with dirty gray-brown patchy fur, a slightly balding back, one torn ear, small amber eyes, visible incisors, pink paws and a long mostly hairless pink tail. Menacing but not gory, no wounds or blood.
Style/medium: detailed hand-painted 2D game sprite matching Image 1, viewed from the same slightly top-down side angle. The rat faces right in every frame.
Layout: strict rectangular grid of exactly 4 columns by exactly 4 rows, equal-size cells, chronological frames from left to right.
Animation order:
- Row 1: idle/sniffing, four distinct subtle phases.
- Row 2: running, four distinct stride phases.
- Row 3: bite attack, four phases: crouched telegraph, launch, bite contact, recovery.
- Row 4: defeat, four phases: hit reaction, collapse, lying down, final still pose.
Technical constraints:
- all 16 frames show exactly the same rat identity, anatomy, fur pattern, colors, body scale and camera distance;
- one shared canvas, stable body center and exactly identical paws ground baseline in every cell;
- no per-frame zoom, crop, camera motion or pose-dependent rescaling;
- the long tail must be fully visible with generous transparent padding in every frame and must not determine the body anchor;
- true transparent RGBA pixels from the first render;
- no floor, shadow, scenery, checkerboard, matte color, labels, text, grid lines, borders, extra animals or props;
- no frame may touch or cross a cell boundary.
Composition: the rat should appear approximately 60% of the on-map body size of the reference dog, while every cell stays large enough for the full running, attack and tail silhouettes.
```
