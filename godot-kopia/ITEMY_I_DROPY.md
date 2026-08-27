# Złomowy Baron — katalog przedmiotów i dropów

> Status: wdrożone w prototypie. Dropy pojawiają się fizycznie na mapie i można je podnosić LPM albo klawiszem Enter.

Ten plik jest czytelnym spisem projektowym. Źródłem danych działającej gry jest `scripts/item_catalog.gd`, a stan posiadanych przedmiotów przechowuje `scripts/player_inventory.gd`.

## Nowe grafiki

| ID | Nazwa | Plik | Rola |
|---|---|---|---|
| `empty_beer_bottle` | Pusta butelka po piwie | `assets/items/empty_beer_bottle.png` | zwykły złom szklany |
| `empty_vodka_bottle` | Pusta małpka | `assets/items/empty_vodka_bottle.png` | zwykły złom szklany |
| `bottle_caps` | Garść kapsli | `assets/items/bottle_caps.png` | drobny złom |
| `grosz_coins` | Garść groszy | `assets/items/grosz_coins.png` | mała wypłata bez zajmowania miejsca |
| `one_zloty` | Złotówka | `assets/items/one_zloty.png` | rzadka wypłata bez zajmowania miejsca |
| `dog_collar` | Stara obroża | `assets/items/dog_collar.png` | rzadki łup lub przedmiot zadaniowy |
| `dog_tag` | Adresówka psa | `assets/items/dog_tag.png` | ślad fabularny lub przedmiot zadaniowy |
| `coin_pouch` | Sakiewka z drobnymi | `assets/items/coin_pouch.png` | łup z przyszłego nazwanego przeciwnika |

Wszystkie grafiki są osobnymi plikami PNG 1536×1024 z prawdziwym kanałem alfa. Na mapie i w ekwipunku należy je skalować, nie używać w pełnej rozdzielczości.

## Proponowane parametry

| ID | Miejsce | Waga | Proponowana wartość | Uwagi |
|---|---:|---:|---:|---|
| `empty_beer_bottle` | 2 | 0,35 kg | 0,30 zł | większa od puszki, mniej opłacalna na miejsce |
| `empty_vodka_bottle` | 1 | 0,18 kg | 0,20 zł | drobny łup z koszy i przyszłych ludzkich przeciwników |
| `bottle_caps` | 1 | 0,05 kg | 0,15 zł | jedna sztuka ekwipunku oznacza garść kapsli |
| `grosz_coins` | 0 | 0 kg | 0,05–0,30 zł | po podniesieniu od razu zwiększa gotówkę |
| `one_zloty` | 0 | 0 kg | 1,00 zł | rzadki bezpośredni przychód |
| `dog_collar` | 2 | 0,15 kg | do ustalenia | lepiej wykorzystać u konkretnego handlarza lub w zadaniu |
| `dog_tag` | 1 | 0,03 kg | do ustalenia | nie sprzedawać automatycznie; może prowadzić do właściciela |
| `coin_pouch` | 1 | 0,10 kg | 0,50–3,00 zł | otwierana akcją; nie jest zwykłym dropem zwierząt |

## Wdrożone tabele łupu

Łup powinien być losowany po pokonaniu całej grupy, nie osobno za każdego przeciwnika. Ogranicza to farmienie i nie dokłada dziewięciu niezależnych nagród pieniężnych do 50 XP za każdego psa.

### Wataha psów w parku — jeden rzut za oczyszczenie polany

| Wynik | Szansa |
|---|---:|
| `dog_collar` | 65% |
| `dog_tag` | 35% |

### Grupa Szczórów — jeden rzut za oczyszczenie legowiska

| Wynik | Szansa |
|---|---:|
| `bottle_caps` | 55% |
| `grosz_coins` | 35% |
| `one_zloty` | 10% |

Kapsle i monety są znaleziskiem z legowiska, a nie dosłowną zawartością ciała zwierzęcia.

### Przeciwnicy z osobnego ekranu walki

- Zadymiarz pozostawia jednorazowo pustą butelkę po piwie (70%) albo pustą małpkę (30%).
- Burek pozostawia jednorazowo obrożę albo adresówkę po 50%.
- Żul 1 pozostawia jednorazowo sakiewkę (70%) albo pustą małpkę (30%).
- Rewanż może nadal dawać XP, ale nie tworzy kolejnego przedmiotu z tego samego nazwanego przeciwnika.

## Zasady wdrożenia

- Monety po podniesieniu trafiają bezpośrednio do gotówki i nie zajmują reklamówki.
- Limity miejsca i wagi są chwilowo wyłączone przełącznikiem `PlayerInventory.LIMITS_ENABLED = false`; nominalne parametry pojemników pozostają w danych.
- Po późniejszym przywróceniu limitów przedmiot, który nie mieści się w pojemniku, ma pozostać na mapie.
- Obroża i adresówka nie powinny być gwarantowane; ich znaczenie fabularne jest większe niż cena złomu.
- Drop nie zastępuje puszek i złomu jako podstawowego źródła utrzymania.

## Prompt użyty do finalnych ikon

Tryb: wbudowany `imagegen`, osobna generacja dla każdego przedmiotu.

Prompt bazowy:

> Create a single production-ready collectible sprite for a top-down 2D Godot RPG, matching the gritty hand-painted realistic style and dark outline of the reference. Center exactly one complete object with generous padding. Transparent background. Isolated cutout. No backdrop, checkerboard, ground, glow, UI, text, extra objects, or watermark.

Warianty obiektu: pusta brązowa butelka po piwie, pusta mała butelka z przezroczystego szkła, garść zardzewiałych kapsli, garść fikcyjnych monet groszowych, jedna fikcyjna złotówka, zużyta skórzana obroża, pusta zardzewiała adresówka oraz brudna sakiewka z drobnymi.
