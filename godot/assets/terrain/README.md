# Zestaw terenu v1

Podstawowy moduł mapy korzysta z siatki **128×128 px**. Plik
`terrain_tileset_v1.tres` można przypisać bezpośrednio do węzła `TileMapLayer`,
a `terrain_atlas_v1.png` jest jego atlasem 8×4 (32 kafle).

## Układ atlasu

| Wiersz | Kafle od lewej |
| --- | --- |
| 0 | trawa ×3, chodnik ×2, asfalt ×3 |
| 1 | trawa/chodnik: góra, prawa, dół, lewa, narożniki TL, TR, BR, BL |
| 2 | trawa/asfalt: góra, prawa, dół, lewa, narożniki TL, TR, BR, BL |
| 3 | asfalt/chodnik: góra, prawa, dół, lewa, narożniki TL, TR, BR, BL |

Pierwsze warianty pełnych powierzchni można mieszać, żeby ograniczyć widoczne
powtórzenia. Kafle brzegowe i narożne służą do ręcznego wykańczania dróg,
placów oraz chodników. Żółta siatka występuje wyłącznie na pliku podglądowym
`terrain_atlas_preview_v1.png` i nie jest częścią atlasu używanego przez grę.

Pliki `grass_base_v1.png`, `sidewalk_base_v1.png` i `asphalt_base_v1.png` to
osobne, bezszwowe materiały bazowe przydatne także w shaderach lub większych
wypełnieniach.
