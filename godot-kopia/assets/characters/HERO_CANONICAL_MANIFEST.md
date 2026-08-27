# Kanoniczne arkusze bohatera

Data normalizacji: 2026-08-26

## Pliki używane przez grę

- `collector_walk_sheet_v3_canonical.png` — wzorzec wyglądu, palety, skali i kamery; siatka 3×4, klatka 429×305.
- `collector_actions_v2_canonical.png` — grzebanie i podnoszenie; siatka 4×8, klatka 256×256, wspólna kotwica stóp `(128, 232)`.
- `collector_bag_hammer_attack_v3_canonical.png` — zamach reklamówką; siatka 4×2, klatka 640×480, wspólna kotwica `(320, 420)`.

Oryginały `collector_walk_sheet_v2.png`, `collector_actions_v1.png` i `collector_bag_hammer_attack_v2_packed.png` pozostały niezmienione. Ich kopia znajduje się także w `backups/player_sprites_2026-08-26/` oraz `backups/player_sprites_2026-08-26.zip`.

Arkusze kanoniczne można odtworzyć poleceniem `tools/normalize_hero_sprites.py`. Skrypt nie skaluje osobno klatek czynności: wycina kompletne sylwetki, umieszcza je względem wspólnego środka głowy i linii stóp oraz dopasowuje neutralne kolory do arkusza chodu.

## Jedyna próba korekty generatywnej

Tryb: edycja / style transfer na podstawie dwóch lokalnych obrazów referencyjnych. Model nie został ujawniony przez narzędzie.

Wynik nie został użyty, ponieważ generator wypalił szachownicę w obrazie RGB zamiast zwrócić prawdziwy kanał alfa. Zgodnie z zasadą jednego renderu nie wykonano drugiej próby; finalne assety powstały z zachowanych źródeł metodą deterministyczną.

Dokładny prompt:

```text
Use case: precise sprite-sheet character edit / style transfer.

Create a corrected action sprite sheet for a top-down/isometric 2D Godot game.

REFERENCE 1 is the canonical movement sprite sheet. Match it exactly for:
- the same adult male character identity and facial features,
- body proportions and apparent character height,
- olive-brown worn jacket, dark trousers, burgundy sweater, hair, skin, shopping bag colors,
- outline weight, texture density, contrast, lighting direction and camera angle.

REFERENCE 2 defines the required action sequence and ordering. Preserve its actions and directions:
- strict grid of 4 columns by 8 rows, exactly 32 distinct frames,
- rows 1-4: rummaging/searching animation for front, left, right, back,
- rows 5-8: picking up a red can animation for front, left, right, back,
- columns are the chronological animation frames.

Critical technical requirements:
- transparent RGBA background from the first render; no checkerboard, no black or colored background,
- equal-sized grid cells and generous transparent padding,
- every full body, hand, shopping bag and can entirely inside its own cell, with no clipping or overlap,
- the ground-contact point / lowest foot has exactly the same vertical baseline in every cell,
- the character's body center is anchored to the same horizontal point in every cell,
- consistent scale in all 32 frames; do not enlarge crouched poses,
- no labels, grid lines, shadows, props outside the actions, or extra characters.

The final asset must read as one cohesive sprite sheet matching REFERENCE 1, not a redesign.
```
