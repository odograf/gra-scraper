# Kanoniczne arkusze bohatera

Data normalizacji: 2026-08-26

## Pliki używane przez grę

- `collector_walk_sheet_v3_canonical.png` — wzorzec wyglądu, palety, skali i kamery; siatka 3×4, klatka 429×305.
- `collector_actions_v2_canonical.png` — grzebanie i podnoszenie; siatka 4×8, klatka 256×256, wspólna kotwica stóp `(128, 232)`.
- `collector_bag_hammer_attack_v3_canonical.png` — zamach reklamówką; siatka 4×2, klatka 640×480, wspólna kotwica `(320, 420)`.
- `collector_bag_attack_body_v1.png` — warstwa samego ciała dla zamachu; siatka 4×2, klatka 512×384, wspólna kotwica `(256, 336)`, skala mapowa `0,43`.
- `../weapons/plastic_bag_attack_overlay_v1.png` — osobna ośmioklatkowa warstwa reklamówki.
- `../weapons/black_sack_attack_overlay_v1.png` — osobna ośmioklatkowa warstwa czarnego worka.

Od 2026-08-28 gra nie odtwarza już połączonego arkusza ciała i reklamówki. `player.gd` synchronizuje `BohaterSprite` oraz `BronTorbaSprite`, a `bag_weapon_catalog.gd` przechowuje dane wariantów. Stary połączony arkusz pozostaje niezmieniony jako źródło i kopia bezpieczeństwa.

Generator zachował kanał alfa warstwy reklamówki, ale zwrócił czarne tło w arkuszu ciała i jasną szachownicę w arkuszu worka. Nie wykonano kolejnej płatnej próby. Gra usuwa te dwa jednolite tła wyłącznie podczas renderowania materiałami `key_black_background.gdshader` i `key_light_checkerboard.gdshader`; pliki źródłowe pozostają bez destrukcyjnego czyszczenia.

Prompty użyte w trybie wbudowanego generatora obrazów:

```text
Use case: precise-object-edit
Asset type: production Godot 2D character attack sprite sheet, BODY LAYER ONLY
Input image: edit target and exact source of truth for composition, character identity, poses, grid, timing and camera
Primary request: Remove only the shopping bag weapon, all cans visible inside it, and every bag motion-smear / attack trail from all eight frames. Reconstruct only the small hand, sleeve, torso, or leg areas that were hidden behind the bag so the same character remains complete in the exact same attack poses.
Style/medium: preserve the original hand-painted Polish gritty RPG sprite style exactly.
Composition/framing: preserve exact 2560x960 canvas; strict 4 columns x 2 rows; each cell exactly 640x480; chronological order unchanged; shared ground anchor at pixel (320,420) inside every cell; identical character scale and body center.
Constraints: true transparent RGBA pixels outside the character; keep the character identity, face, hair, clothes, anatomy, pose, lighting, palette, outline, rendering density and every body pixel not covered by the removed weapon as unchanged as possible. No per-frame zoom, drift, crop or rescaling. Keep generous transparent padding. No bag, no cans, no motion trails, no shadow, no floor, no scenery, no grid lines, no text, no watermark.
```

```text
Use case: precise-object-edit
Asset type: production Godot 2D attack sprite sheet, WEAPON OVERLAY ONLY
Input image: edit target and exact source of truth for positions, timing, camera and style
Primary request: Remove the character completely from all eight frames. Preserve only the transparent grocery shopping bag weapon, its handles, the cans/content inside it, and the existing bag motion-smear / attack trail for each frame, in their exact original position and chronological order. Where the character overlapped the handle, reconstruct only the tiny missing handle segment needed for a complete weapon overlay.
Composition/framing: preserve the source layout as strictly as possible; strict 4 columns x 2 rows with eight equal cells; every weapon placement must align with the matching frame of the source attack sheet; no per-frame drift, crop, zoom or rescaling.
Style/medium: preserve original gritty hand-painted Polish RPG sprite texture, palette, lighting and outlines.
Constraints: true transparent RGBA pixels everywhere except the bag and its motion trail; absolutely no character, no hands, no arms, no body parts, no shadow, no floor, no scenery, no labels, no grid lines, no text, no watermark. Keep generous transparent padding around every bag arc.
```

```text
Use case: precise-object-edit
Asset type: production Godot 2D attack sprite sheet, BLACK SACK WEAPON OVERLAY ONLY
Input image: edit target and exact source of truth for weapon positions, swing timing, camera and style
Primary request: Remove the character completely from all eight frames and replace the transparent grocery shopping bag with a tied black plastic rubbish sack used as an improvised swinging weapon. Preserve the exact handle/grip point, weapon direction, swing phase, reach, silhouette scale and motion-smear position of the original bag in each matching frame. The sack should look opaque, heavy, scuffed and loosely filled, near-black charcoal with subtle dirty gray highlights; no contents visible through it. Preserve a muted brown/charcoal motion trail on the wide swing frames.
Composition/framing: preserve the source layout as strictly as possible; strict 4 columns x 2 rows with eight equal cells; every black sack placement must align with the matching source attack frame; no per-frame drift, crop, zoom or rescaling.
Style/medium: same gritty hand-painted Polish RPG sprite texture, lighting, outline weight and top-down camera as the source.
Constraints: true transparent RGBA pixels everywhere except the black sack and its motion trail; absolutely no character, no hands, no arms, no body parts, no floor, no shadow, no scenery, no labels, no grid lines, no text, no watermark. Keep generous transparent padding around every attack arc.
```

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
