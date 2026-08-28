# Zbieracz — prototyp przygodowy w Godot 4

Gra przygodowa 2D z widokiem z góry, ręcznie rysowaną polską mapą i bohaterem zbierającym puszki.

## Uruchomienie

1. Zainstaluj Godot 4.3 lub nowszy.
2. W menedżerze projektów wybierz **Import**.
3. Wskaż plik `project.godot` z tego katalogu.
4. Uruchom projekt klawiszem **F6/F5**.

Projekt nie wymaga żadnych dodatków do Godota.

## Grywalny mockup nowego prologu

Nowy układ startu jest osobną sceną i nie zastępuje jeszcze obecnej gry:

1. Otwórz `scenes/melina_prologue_mockup.tscn`.
2. Naciśnij **F6**, aby uruchomić tylko mockup.
3. W mockupie naciśnij **F1**, aby wrócić do obecnej sceny głównej.
4. **F5** uruchamia menu główne; właściwa rozgrywka zaczyna się po wybraniu `Nowa gra` albo slotu zapisu.

Melina i przedmieście są osobnymi scenami. Nowa gra zaczyna się w melinie. Drzwi po zebraniu sześciu puszek prowadzą na przedmieście, a północna brama prowadzi dalej na pełną mapę osiedla, zachowując reklamówkę, puszki i zdrowie. Jedyny kiosk i jedyny sklep Żuk Gnojarz znajdują się na osiedlu. **F2** uruchamia melinę od początku. Lista brakujących docelowych grafik znajduje się w `docs/PROLOG_MAP_MOCKUP.md`.

## Edycja mapy w Godocie

Mapa jest zapisana jako osobna scena [world_map.tscn](scenes/world_map.tscn) i jest widoczna bez uruchamiania gry.

Ustalenia dotyczące układu mapy zapisujemy prostym językiem w `MAPA.md`. Można dopisać pojedynczą linię zaczynającą się od `POMYSŁ:`, `DECYZJA:` albo `PROBLEM:`; skill `kartograf` wykorzysta ją podczas kolejnej pracy nad mapą.

1. W panelu `System plików` otwórz `scenes/world_map.tscn`.
2. Zaznacz `TerenBazowy`, aby malować trawę, chodniki i asfalt narzędziami `TileMapLayer`.
3. Rozwiń `PunktyRozgrywki`, aby przesuwać pozycję startową, interakcje, kontenery, watahy i puszki bez edytowania kodu.
4. Budynki, płoty i kolizje są osobnymi węzłami sceny i można je zaznaczać w drzewie po lewej stronie.

Żółte opisy oraz podglądy psów i puszek służą wyłącznie do układania mapy. Gra ukrywa je podczas uruchamiania i tworzy w ich miejscach właściwe obiekty interaktywne.

## Sterowanie

- **lewy przycisk na ziemi** — ruch bohatera do wskazanego punktu,
- **lewy przycisk na przeciwniku** — podejście w zasięg i atak wybranego celu,
- **prawy przycisk myszy** — szeroki zamach aktualnie wyposażoną torbą jak przy rzucie młotem,
- **strzałki** lub **WASD** — awaryjne sterowanie bezpośrednie i anulowanie marszu,
- **Enter** — wykonanie najbliższej podświetlonej akcji: podniesienie, rozmowa, sklep, walka, automat, kontenery lub siatka,
- **strzałki** albo **WASD w menu** — zmiana zaznaczonej opcji,
- **Enter w menu i dialogu** — zatwierdzenie zaznaczonej opcji,
- **lewy przycisk myszy na przedmiocie** — alternatywne podniesienie, gdy bohater jest blisko,
- **I** — ekwipunek i wybór broni torbowej; działa również w melinie i na przedmieściu po podniesieniu reklamówki,
- **ikona torby w dolnym HUD-zie** — otwiera ten sam ekran ekwipunku co klawisz I,
- **lewy przycisk na NPC, drzwiach, automacie lub płocie** — interakcja,
- **ESC** — zamknięcie aktywnego okna lub anulowanie wycinania siatki; na mapie otwiera menu pauzy z zapisem gry.

## Zapisywanie gry

- Menu główne pozwala rozpocząć nową grę albo wczytać jeden z trzech slotów.
- Podczas gry naciśnij **Esc**, wybierz **Zapisz grę**, a następnie wskaż slot.
- Zajęty slot jest zastępowany po wybraniu. Przy każdym zastąpieniu gra zachowuje kopię zapasową poprzedniego pliku.
- Zapisy znajdują się w katalogu Godota `user://`, a nie wewnątrz projektu.

## Obecna zawartość

- osobne menu główne z rozpoczęciem nowej gry, podglądem trzech slotów i wczytywaniem postępu,
- menu pauzy pod Esc z wyborem slotu zapisu, wznowieniem oraz powrotem do menu głównego,
- wersjonowany zapis stanu bohatera, ekwipunku, zadań, świata, przeciwników i leżących dropów,
- dolny HUD: duży centralny pasek życia, mniejsze paski alkoholu i nikotyny po bokach oraz przycisk torby; informacje o pieniądzach, pojemniku i poziomie pozostają w kompaktowym panelu u góry,
- ruch point & click z marszem po skosie, znacznikiem celu i zatrzymaniem przy kolizji; klik mapy podczas zamachu kolejkuje płynny ruch wykonywany zaraz po animacji,
- pierwszy atak czasu rzeczywistego: 8-klatkowy ruch ciała i osobna zsynchronizowana warstwa broni; reklamówkę można zamienić na czarny worek bez duplikowania animacji bohatera,
- wspólny system walki: bohater ma 100 HP, atak 10, obronę 0, zwinność 10 i zasięg 2; jego pasek życia jest widoczny w HUD-zie,
- pierwszy pełny przeciwnik czasu rzeczywistego: dziki pies poziomu 1 z 30 HP, atakiem 5, zasięgiem 1 i nagrodą 50 XP,
- prosty przeciwnik „Szczór”: trzy osobniki przy dolnych garażach, 12 HP, 2 obrażenia, krótki zasięg wykrywania, zapowiadane ugryzienie, 8 XP i osobna animacja śmierci,
- jeden plik `scripts/combatant_config.gd` ustawia statystyki bohatera, wszystkich watah oraz obecnych przeciwników; typowana definicja zasobu sprawdza dane przed użyciem,
- zaniedbany park za płotem w lewej dolnej części mapy z trzema watahami liczącymi kolejno 2, 3 i 4 psy,
- kanoniczny arkusz chodu bohatera: 3 pozy na kierunek, stała skala i prawdziwe przezroczyste tło,
- wyrównane animacje grzebania, podnoszenia puszek i zamachu: wspólna linia stóp, stabilny środek sylwetki, bez przycinania oraz z paletą dopasowaną do chodu,
- kamera śledząca postać,
- powiększona mapa 2800×1600 z nową częścią garażową, magazynem i pustym placem,
- mapa korzystająca z `TileMapLayer` i zestawu 128×128: trawa, stary chodnik, asfalt, warianty powierzchni oraz 24 kafle brzegów i narożników,
- osobna edytowalna scena mapy z widocznymi kafelkami, budynkami, kolizjami oraz markerami wszystkich puszek, NPC i watah,
- frontalne grafiki kiosku przy punkcie startowym oraz odległego sklepu „Żuk Gnojarz”, oba z kolizją i interakcją,
- kolizje ze sklepem, koszami, ławką, płotem, drzewami i wrakiem,
- 30 puszek rozmieszczonych na całej mapie, w tym sześć przy legowiskach watah w parku,
- cztery grupy kontenerów do przeszukania,
- subtelne podświetlenie wyłącznie najbliższej akcji i pełna obsługa świata, menu oraz dialogów klawiaturą,
- przeszukiwanie koszy z losowym dropem puszek i drutu,
- działające dropy po walce: watahy psów, legowiska Szczórów oraz nazwani przeciwnicy zostawiają fizyczne znajdźki podnoszone LPM lub Enterem; monety zasilają gotówkę, a pozostałe przedmioty trafiają do ekwipunku,
- osiem przezroczystych grafik dropów: dwie puste butelki, kapsle, grosze, złotówka, obroża, adresówka i sakiewka; katalog jest w `ITEMY_I_DROPY.md`,
- tymczasowo wyłączony limit miejsca i udźwigu pojemnika, widoczny w HUD-zie jako `BEZ LIMITU`,
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
- świadomy podział walki: fauna walczy na mapie w czasie rzeczywistym, a nazwani przeciwnicy fabularni przełączają grę na osobny system turowy,
- wspólny trwały stan zdrowia i statystyk bohatera używany przez HUD oraz oba tryby walki; Siła wzmacnia również atak mapowy, a Kondycja od razu zwiększa maksymalne życie,
- osobny prototyp walki turowej: szybki cios, ładowany silny atak, garda, trzyturowe skakanie na boki, zdrowie, przewaga, proste AI przeciwnika, rewanż i powrót na mapę,
- sekwencyjne animacje tur: ruch gracza, płynna zmiana właściwego paska życia, pauza i dopiero potem odpowiedź przeciwnika,
- poziomy i doświadczenie: 2 XP za podniesioną puszkę, 20 XP za wygraną walkę oraz rosnące progi awansu,
- jeden punkt statystyki za każdy poziom, rozdawany pod `I` między Siłę, Kondycję i Zwinność; statystyki zwiększają obrażenia, życie, celność oraz szansę uniku.
