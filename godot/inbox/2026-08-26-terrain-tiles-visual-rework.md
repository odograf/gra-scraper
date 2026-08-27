# TODO — przeprojektowanie kafli terenu

Status: odłożone do późniejszej iteracji.

Screen referencyjny: `2026-08-26-terrain-tiles-current-problem.png`.

## Problem

Aktualne podłoże oparte na `TileMapLayer` działa technicznie, ale wizualnie nie
pasuje jeszcze do gry:

- kafle 128×128 są zbyt duże i ich granice są bardzo czytelne;
- asfalt tworzy regularne, powtarzalne kwadraty i ciemne plamy;
- chodnik wygląda jak powiększona krata, a płyty mają niewłaściwą skalę;
- przejścia trawa–chodnik–asfalt są szerokimi, twardymi pasami;
- obracane warianty nadal zdradzają symetrię i powtórzenia tekstury;
- poziom detalu oraz realizm terenu nie pasują do prostszych budynków i części
  ręcznie rysowanych elementów mapy;
- linie drogowe i dekoracje nakładane proceduralnie nie łączą się naturalnie z
  nową nawierzchnią.

## Kierunek następnej wersji

- sprawdzić mniejszą siatkę, prawdopodobnie 64×64 lub 96×96;
- przygotować tekstury o niższym kontraście i bardziej malowanym charakterze;
- stworzyć więcej niezależnych wariantów zamiast obrotów jednego kafla;
- oddzielić bazową powierzchnię od drobnych nakładek: pęknięć, plam, trawy,
  śmieci i łat asfaltu;
- przygotować poprawny zestaw krawędzi i narożników do automatycznego malowania
  terenu;
- dopasować wielkość płyt chodnikowych do postaci;
- rozbić długie, idealnie proste granice materiałów i dodać nieregularne pobocza;
- zrobić pełny podgląd mapy przed ponownym włączeniem zestawu do gry.

## Pliki, których dotyczy zadanie

- `assets/terrain/terrain_atlas_v1.png`
- `assets/terrain/terrain_tileset_v1.tres`
- `scripts/world_map.gd`
- `tests/terrain_kit_test.gd`

Nie poprawiać tego punktowo. Następna iteracja powinna zacząć się od ustalenia
docelowej skali i stylu na małym fragmencie mapy, a dopiero potem objąć cały
świat.
