# Zbieracz — prototyp przygodowy w Godot 4

Gra przygodowa 2D z widokiem z góry, ręcznie rysowaną polską mapą i bohaterem zbierającym puszki.

## Uruchomienie

1. Zainstaluj Godot 4.3 lub nowszy.
2. W menedżerze projektów wybierz **Import**.
3. Wskaż plik `project.godot` z tego katalogu.
4. Uruchom projekt klawiszem **F6/F5**.

Projekt nie wymaga żadnych dodatków do Godota.

## Sterowanie

- **strzałki** lub **WASD** — poruszanie bohaterem,
- **Enter** — wykonanie najbliższej podświetlonej akcji: podniesienie, rozmowa, sklep, walka, automat, kontenery lub siatka,
- **strzałki** albo **WASD w menu** — zmiana zaznaczonej opcji,
- **Enter w menu i dialogu** — zatwierdzenie zaznaczonej opcji,
- **lewy przycisk myszy na przedmiocie** — alternatywne podniesienie, gdy bohater jest blisko,
- **I** — ekwipunek, pojemniki, trwałość narzędzi i rozwój statystyk,
- **lewy przycisk na NPC, drzwiach, automacie lub płocie** — interakcja,
- **lewy przycisk na przeciwniku podczas walki** — podstawowy atak,
- **ESC** — zamknięcie menu lub anulowanie wycinania siatki.

## Obecna zawartość

- płynny ruch w czterech kierunkach,
- przywrócony oryginalny arkusz bohatera wskazany przez użytkownika: 3 pozy na kierunek, stała skala i prawdziwe przezroczyste tło,
- animacje grzebania w koszu oraz podnoszenia puszek w czterech kierunkach,
- kamera śledząca postać,
- powiększona mapa 2800×1600 z nową częścią garażową, magazynem i pustym placem,
- mapa korzystająca z `TileMapLayer` i zestawu 128×128: trawa, stary chodnik, asfalt, warianty powierzchni oraz 24 kafle brzegów i narożników,
- frontalne grafiki kiosku przy punkcie startowym oraz odległego sklepu „Żuk Gnojarz”, oba z kolizją i interakcją,
- kolizje ze sklepem, koszami, ławką, płotem, drzewami i wrakiem,
- 24 puszki rozmieszczone na całej mapie,
- cztery grupy kontenerów do przeszukania,
- subtelne podświetlenie wyłącznie najbliższej akcji i pełna obsługa świata, menu oraz dialogów klawiaturą,
- przeszukiwanie koszy z losowym dropem puszek i drutu,
- licznik zawartości reklamówki,
- ekwipunek z miejscem i wagą,
- narzędzia przechowywane poza limitem pojemnika,
- duża torba i wiadro,
- Mirek w złomowym zakątku: stary Żuk za plecami oraz osobne skrzynki puszek i złomu tworzą tylko jedno dojście do skupu,
- `FAB-03 — Zagubiony klucz`: nowe zlecenie Mirka prowadzi do Heńka Mechanika przy dolnych garażach; wymiana 3 drutów na klucz kończy się nagrodą 15 zł i 35 XP,
- Heniek ma osobny animowany sprite mapowy, portret i pełny dialog obsługiwany myszą oraz klawiaturą,
- Burek stojący w drzwiach Żuka Gnojarza jako łatwy pierwszy przeciwnik oraz mocniejszy Żul 1 wchodzący w jedyne przejście do Mirka po oddaniu siatki i przed handlem drutem; po zwycięstwie obaj odsuwają się na bok, a walki wymagają dodatniego poziomu alkoholu i nikotyny,
- każda klatka animacji Żula i Burka jest osobno kotwiczona do środka głowy oraz podstawy stóp lub łap,
- bohater i NPC są sortowani według położenia stóp na osi Y, więc postać stojąca niżej prawidłowo zasłania tę stojącą wyżej,
- duże modele Żula 1 i Burka są zachowane osobno jako grafiki przeznaczone do przyszłych ekranów rozmowy i walki, bez używania ich jako sprite'ów mapowych,
- nożyce, trwałość, naprawa i czasowe wycinanie siatki,
- potrzeby rozliczane za wykonane akcje zamiast za upływ czasu: zwykła akcja kosztuje 1/1, a cięcie siatki 5/5 i wymaga odpowiedniego poziomu,
- kiosk z tańszymi papierosami oraz Żuk Gnojarz z piwem, małpkami i droższymi papierosami,
- ręcznie malowany płot z wyraźnie oznaczonym przęsłem do wycięcia i osobnym stanem po przecięciu,
- krótki ekran ładowania wykorzystujący concept art,
- `FAB-01 — Pierwszy kurs`: pobudka, podniesienie reklamówki, panel celu, dwa kursy do automatu, zakupy i skierowanie do Mirka,
- modułowa mapa przygotowana pod późniejsze generowanie lokacji,
- zadymiarz stojący pod kioskiem, z którym można rozpocząć walkę Enterem albo kliknięciem,
- osobny prototyp walki turowej: szybki cios, ładowany silny atak, garda, trzyturowe skakanie na boki, zdrowie, przewaga, proste AI przeciwnika, rewanż i powrót na mapę,
- centralny plik `scripts/combatant_config.gd` z bazowymi statystykami bohatera i każdego typu przeciwnika, w tym psa z parku: poziom 1, 30 HP, 5 ataku, zasięg 1 i 50 XP,
- zadymiarz, Burek, Żul 1 i wszystkie przyszłe egzemplarze watah korzystają wyłącznie z archetypów tego pliku,
- stale widoczny w HUD-zie pasek zdrowia bohatera, synchronizowany z obrażeniami i przenoszony do kolejnej walki,
- podstawowy atak wykonywany lewym kliknięciem bezpośrednio w model przeciwnika na ekranie walki,
- sekwencyjne animacje tur: ruch gracza, płynna zmiana właściwego paska życia, pauza i dopiero potem odpowiedź przeciwnika,
- poziomy i doświadczenie: 2 XP za podniesioną puszkę, 20 XP za wygraną walkę oraz rosnące progi awansu,
- jeden punkt statystyki za każdy poziom, rozdawany pod `I` między Siłę, Kondycję i Zwinność; statystyki zwiększają obrażenia, życie, celność oraz szansę uniku.
