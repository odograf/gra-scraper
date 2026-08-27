# Zbieracz — lista mechanik

> Żywy dokument projektowy. Najpierw opisujemy zasady, dopiero później implementujemy je w grze.

## 1. Główna koncepcja

**Gatunek:** strategiczne RPG 2D z eksploracją niewielkich polskich lokacji i turową walką.

Gracz kieruje młodym chłopakiem próbującym przeżyć z dnia na dzień. Zaczyna od zbierania puszek do reklamówki. Z czasem zdobywa lepszy ekwipunek, poznaje nowe sposoby zarabiania, rozwija statystyki oraz wdaje się w konflikty rozgrywane w systemie turowym.

Strategia polega przede wszystkim na zarządzaniu:

- czasem dnia,
- miejscem w ekwipunku,
- pieniędzmi,
- głodem alkoholowym i nikotynowym,
- ryzykiem podejmowanych działań,
- kondycją bohatera,
- wyborem tras, narzędzi i źródeł dochodu.

## 2. Główna pętla rozgrywki

1. Bohater wychodzi na mapę z ograniczonym miejscem w ekwipunku.
2. Eksploruje lokację i szuka przedmiotów albo okazji do zarobku.
3. Decyduje, co warto zabrać, a co zostawić.
4. Wykorzystuje narzędzia, ryzykując hałas, wykrycie lub walkę.
5. Sprzedaje zdobyte przedmioty w odpowiednim punkcie.
6. Kupuje używki, wyposażenie albo ulepszenia.
7. Wraca do bezpiecznego miejsca i przygotowuje się na następny dzień.

## 3. Potrzeby bohatera

### MEC-001: Głód alkoholowy

- Osobny pasek zmniejszający się przy wykonywaniu działań, nie wraz z upływem czasu.
- Alkohol uzupełnia pasek, ale kosztuje pieniądze.
- Niski poziom może powodować negatywne efekty, np. drżenie, mniejszą zwinność albo gorszą skuteczność w walce.
- Bardzo niski poziom może odbierać życie lub blokować część bardziej wymagających działań.
- Różne alkohole mogą mieć inną cenę, siłę i skutki uboczne.

### MEC-002: Głód nikotynowy

- Drugi, niezależny pasek zmniejszający się przy wykonywaniu działań.
- Papierosy uzupełniają pasek nikotynowy.
- Niski poziom może zmniejszać koncentrację lub „kombinatorykę”.
- Palenie może na krótko poprawiać wybrane statystyki kosztem pieniędzy albo zdrowia.

### Do ustalenia

- Czy koszty potrzeb powinny zależeć również od statystyk, wyposażenia lub rodzaju wykonywanej akcji?
- Czy gracz może próbować ograniczać uzależnienia?
- Czy używki mają wyłącznie podtrzymywać bohatera, czy również dawać krótkie premie?
- Jak mocno system ma być realistyczny, a jak mocno satyryczny?

## 4. Ekwipunek i udźwig

### MEC-003: Ograniczona pojemność

- Każdy przedmiot zajmuje określoną ilość miejsca albo ma wagę.
- Bohater nie może zbierać wszystkiego bez zastanowienia.
- Puszki zajmują mało miejsca pojedynczo, ale szybko zapełniają początkową reklamówkę.
- Po zapełnieniu pojemnika gracz musi sprzedać zawartość, wyrzucić coś albo wrócić później.
- Narzędzia są osobnym wyposażeniem i **nie zajmują miejsca ani udźwigu** pojemnika.

### MEC-004: Rozwój pojemnika

| Poziom | Pojemnik | Charakterystyka |
|---:|---|---|
| 1 | Reklamówka | Bardzo mała pojemność, tania i dostępna od początku |
| 2 | Większa torba | Więcej miejsca, nadal łatwa do noszenia |
| 3 | Wiadro | Dobre na metal, ale zajmuje rękę i może hałasować |
| 4 | Plecak | Duża wygoda i wolne ręce, średnia pojemność |
| 5 | Wózek dziecięcy | Duża pojemność, trudniejsze poruszanie i gorszy teren |
| 6 | Wózek sklepowy | Największa pojemność, hałas, problemy ze schodami i przeszkodami |

Pojemniki nie muszą być zwykłymi ulepszeniami. Każdy może mieć zalety i wady, dzięki czemu wcześniejsze warianty nadal mogą być przydatne.

## 5. Puszki i pierwszy zarobek

### MEC-005: Zbieranie puszek

- Puszki leżą na mapie jako interaktywne przedmioty.
- Wyłącznie najbliższa puszka albo startowa reklamówka podświetla się automatycznie, gdy bohater znajdzie się w krótkim zasięgu.
- Podświetlenie przedmiotu jest subtelne, a nierotująca się podpowiedź `ENTER — PODNIEŚ` pojawia się w HUD-zie.
- Klawisz Enter podnosi najbliższy podświetlony przedmiot; kliknięcie pozostaje alternatywną metodą.
- Podniesienie jest możliwe tylko z niewielkiej odległości.
- Puszka trafia do aktualnego pojemnika, jeśli jest w nim miejsce.
- Licznik powinien pokazywać zajęte oraz maksymalne miejsce.

### MEC-006: Sprzedaż puszek

- Puszki można oddawać w skupie albo automacie kaucyjnym — zależnie od ich rodzaju.
- Zgniecione, zabrudzone i całe puszki mogą mieć różną wartość.
- Cena może zależeć od miejsca sprzedaży lub dnia.
- Sprzedaż zapewnia pierwsze pieniądze na używki i lepsze wyposażenie.
- **Wdrożone w etapie 1:** automat obok sklepu przyjmuje całą zawartość reklamówki i płaci 0,60 zł za puszkę.
- Automat jest łatwo dostępny, ale przyszły skup złomu będzie oferował lepszą cenę.

### MEC-020: Przeszukiwanie koszy

- Grupę starych koszy można przeszukać kliknięciem z niewielkiej odległości.
- Kosz losuje od 1 do 3 puszek.
- Niezależnie ma 25% szansy na kawałek drutu.
- Zawartość jest losowana tylko przy pierwszym przeszukaniu.
- Jeśli pojemnik jest pełny, niezabrane przedmioty pozostają w koszu.
- Kawałek drutu zajmuje 1 miejsce, waży 0,20 kg i Mirek kupuje go za 1,50 zł.

### MEC-027: FAB-03 — Zagubiony klucz

- Po ukończeniu zadania z siatką i pokonaniu Żula Mirek udostępnia nowe zlecenie.
- Mirek wysyła bohatera do Heńka Mechanika przy dolnych garażach. Heniek wymienia klucz do Żuka na 3 kawałki drutu.
- Trzy dalsze grupy kontenerów gwarantują po jednym drucie przy pierwszym przeszukaniu, dzięki czemu zadanie nie zależy od losowego dropu. Zwykłe losowanie drutu nadal wynosi 25%.
- Klucz do Żuka jest przedmiotem fabularnym bez miejsca i wagi.
- Oddanie klucza Mirkowi kończy `FAB-03` i daje 15 zł oraz 35 XP.
- Heniek ma osobny animowany model mapowy oraz portret dialogowy. Rozmowę można obsłużyć myszą albo klawiaturą.

### MEC-022: Pełna obsługa klawiaturą

- System wybiera jeden najbliższy obiekt interaktywny w zasięgu i pokazuje jego akcję w HUD-zie.
- Enter wykonuje akcję zależną od obiektu: podnosi przedmiot, otwiera sklep, uruchamia automat, rozpoczyna rozmowę, przeszukuje kontenery albo zaczyna cięcie siatki.
- W menu sklepu, ekwipunku i dialogach strzałki lub WASD zmieniają zaznaczoną opcję, a Enter ją zatwierdza.
- Wybrany przycisk ma czytelną złotą ramkę. Po otwarciu okna pierwsza dostępna opcja otrzymuje fokus automatycznie.
- Mysz pozostaje alternatywnym sposobem interakcji, ale nie jest wymagana do przejścia gry.

### MEC-023: Powiększona mapa

- Obszar świata ma 2800×1600 pikseli, a kamera korzysta z tych samych granic.
- Dotychczasowa lokacja startowa pozostaje bez zmian funkcjonalnych.
- Nowe rejony obejmują garaże, magazyn, pusty plac i dalszą część osiedla za ulicą.
- Na mapie znajdują się 24 stałe puszki oraz 4 niezależne grupy kontenerów z osobnym losowaniem zawartości.
- Za Mirkiem stoi stary Żuk, a skrzynki z puszkami i złomem zamykają skup z boków. Od frontu pozostaje jedno wąskie przejście.

## 6. Narzędzia i nowe źródła dochodu

### MEC-007: Narzędzia odblokowujące interakcje

Narzędzie nie jest tylko przedmiotem zwiększającym statystykę. Powinno otwierać nowe akcje na mapie.

**Wdrożone w etapie 2:** stare nożyce otrzymane od Mirka mają 6 punktów trwałości. Wycięcie siatki zużywa 1 punkt; przerwanie akcji nie niszczy narzędzia.

| Narzędzie | Nowa możliwość | Potencjalne ograniczenia |
|---|---|---|
| Nożyce do metalu | Wycinanie fragmentów metalowej siatki | Hałas, czas, zużycie, ryzyko zauważenia |
| Brzeszczot | Wycinanie katalizatorów albo cięcie drobnego metalu | Bardzo wolne działanie, duży hałas, wysokie ryzyko |
| Śrubokręt | Rozbieranie elektroniki i prostych urządzeń | Niewielki zarobek, możliwość uszkodzenia części |
| Łom | Otwieranie skrzyń i odrywanie elementów | Ciężki, widoczny, może służyć w walce |
| Magnes | Wyciąganie metalu z trudno dostępnych miejsc | Działa tylko w wybranych punktach |

### MEC-008: Czas wykonywania czynności

- Trudniejsze działania nie powinny być natychmiastowe.
- Potrzeby są odejmowane dopiero po udanym zakończeniu działania; samo czekanie lub przerwanie czynności ich nie zużywa.
- Lepsze narzędzia skracają czas oraz zmniejszają ryzyko niepowodzenia.

### MEC-009: Ryzyko i zainteresowanie otoczenia — propozycja

- Głośne lub podejrzane działania zwiększają poziom zainteresowania.
- Po przekroczeniu progów mogą pojawić się właściciele, ochroniarze, inne postacie albo policja.
- Gracz może przerwać działanie i uciec, zanim zdobędzie przedmiot.
- Ryzyko powinno być czytelne przed zatwierdzeniem akcji.

## 7. Walka turowa

### MEC-010: Spotkania

- Walka rozpoczyna się po konflikcie na mapie albo jako konsekwencja ryzykownej akcji.
- Widok przełącza się na osobny ekran walki, podobnie jak w klasycznych RPG.
- Każda strona wykonuje ruch zgodnie z kolejnością wynikającą ze zwinności.
- Gracz wybiera jedną akcję na turę.

### MEC-011: Podstawowe statystyki

| Statystyka | Znaczenie |
|---|---|
| Życie | Ilość obrażeń, które bohater może przyjąć |
| Atak | Siła zwykłych ataków i części ruchów specjalnych |
| Obrona | Zmniejszenie otrzymywanych obrażeń |
| Zwinność | Kolejność tur, uniki i możliwość ucieczki |
| Kombinatoryka | Improwizacja, nietypowe ruchy, wykorzystywanie otoczenia i narzędzi |
| Odporność | Wpływ zmęczenia, używek oraz negatywnych stanów |

### MEC-012: Ruchy w walce

Bohater może mieć kilka aktywnych ruchów wybranych przed walką. Przykładowe kategorie:

- zwykły atak,
- obrona lub unik,
- ruch wykorzystujący trzymane narzędzie,
- improwizacja zależna od kombinatoryki,
- użycie przedmiotu,
- próba ucieczki,
- rozmowa, zastraszenie albo odwrócenie uwagi.

### MEC-013: Narzędzia w walce

- Część narzędzi gospodarczych może być używana podczas walki.
- Użycie narzędzia może je zużywać albo uszkadzać.
- Ciężkie wyposażenie może zwiększać atak, ale zmniejszać zwinność.
- Kombinatoryka może odblokowywać nietypowe połączenia przedmiotów i ruchów.

### MEC-024: Prototyp fizycznej walki

- Dorosły zadymiarz stoi pod kioskiem. Podejście i naciśnięcie `Enter` albo kliknięcie postaci rozpoczyna prototypową walkę.
- Bohater i jeden dorosły przeciwnik mają osobne paski życia. Prototyp nie nakłada trwałych konsekwencji po wyniku.
- Walki nie można rozpocząć, jeśli alkohol albo nikotyna wynosi 0. Gracz musi najpierw uzupełnić oba paski.
- Gracz ma cztery ruchy: `Szybki cios`, `Silny atak`, `Garda` oraz `Skacz na boki`.
- Akcje są pokazywane kolejno: animacja ruchu gracza, płynne odjęcie punktów z paska celu, krótka pauza, a następnie osobna animacja ruchu przeciwnika i jego efektu.
- Szybki cios ma wysoką celność. Silny atak zużywa pierwszą turę na ładowanie, pozwala przeciwnikowi odpowiedzieć, a w następnej turze odpala się automatycznie i zadaje 14–17 obrażeń.
- Garda redukuje otrzymane obrażenia o 60%; zatrzymanie ciężkiego ataku daje przewagę. `Skacz na boki` daje przez trzy tury po 50% szansy uniknięcia każdego ataku przeciwnika.
- Przewaga dodaje 3 obrażenia i 8 punktów procentowych celności do następnego ataku, po czym znika.
- Przeciwnik wybiera między szybkim ciosem, ciężkim kopnięciem i gardą; przy niskim zdrowiu częściej się broni.
- Burek stoi dokładnie w świetle drzwi Żuka Gnojarza i blokuje sklep do pierwszego zwycięstwa. Jest przeciwnikiem wprowadzającym: ma 20 życia, obniżone obrażenia i celność. Po pokonaniu odsuwa się od wejścia.
- Po oddaniu siatki i przed pierwszym handlem drutem Żul 1 wchodzi w jedyne przejście do Mirka. Dalszy handel wymaga pokonania Żula. Żul ma 64 życia, premię do obrażeń i celności; zalecany poziom bohatera to 3. Po porażce odsuwa się z przejścia.
- Ekran walki pokazuje właściwy duży model i nazwę przeciwnika. Burek używa opisów ugryzienia, szarży i obronnego jeżenia sierści.
- Po zwycięstwie lub porażce gracz może wybrać rewanż albo wrócić na mapę.

### MEC-021: Bezkrwawy samouczek walki — propozycja

- Pierwsze spotkanie turowe odbywa się przy Żuku Mirka po zaspokojeniu początkowych potrzeb bohatera.
- Dzieciak rzucający kamieniami nie ma paska życia, lecz pasek Zuchwałości.
- Gracz uczy się obrony, uniku, skracania dystansu i zastraszania; zwykły atak oraz narzędzia są zablokowane.
- Zwycięstwo następuje po obniżeniu Zuchwałości do zera albo podejściu na odległość pozwalającą odebrać kamienie.
- Po trzech trafieniach Mirek przerywa starcie. Nie ma śmierci, utraty przedmiotów ani trwałej kary, a samouczek można powtórzyć.
- Późniejsza konfrontacja z dorosłym przeciwnikiem wprowadza pełne akcje ofensywne i konsekwencje przegranej.

### Do ustalenia

- Czy przegrana oznacza śmierć, utratę części przedmiotów, pobicie czy trafienie do szpitala?
- Ilu przeciwników może jednocześnie uczestniczyć w walce?
- Czy bohater walczy sam, czy później może mieć towarzyszy?
- Czy ruchy są uczone przez poziomy, przedmioty, NPC czy wykonywane czynności?

## 8. Rozwój bohatera

### MEC-014: Doświadczenie

- Każda podniesiona puszka, również znaleziona w koszu, daje 2 XP.
- Każde zwycięstwo nad zadymiarzem daje 20 XP; rewanże również nagradzają doświadczeniem.
- Pierwszy awans wymaga 25 XP. Każdy kolejny próg jest wyższy o 20 XP, a nadwyżka przechodzi na następny poziom.
- Każdy zdobyty poziom daje 1 punkt statystyki do rozdania w ekranie ekwipunku pod `I`.
- HUD stale pokazuje poziom, bieżące XP, następny próg oraz liczbę wolnych punktów.
- Planowane późniejsze źródła XP to zadania, eksploracja, używanie narzędzi i odkrywanie nowych sposobów zarobku.

### MEC-025: Statystyki z awansów

- `Siła`: każdy punkt dodaje 1 obrażenie do Szybkiego ciosu i 2 obrażenia do Silnego ataku.
- `Kondycja`: każdy punkt dodaje 5 maksymalnych punktów życia podczas walki.
- `Zwinność`: każdy punkt dodaje 2 punkty procentowe celności Szybkiego ciosu, 1 punkt procentowy celności Silnego ataku oraz 5 punktów procentowych szansy uniku podczas Skakania na boki.
- Celność ataków i szansa uniku są ograniczone do 98% oraz 80%, dzięki czemu rozwój nie usuwa całego ryzyka.
- Przyciski zwiększania statystyk są aktywne tylko wtedy, gdy bohater ma wolny punkt. Wydanego punktu nie można obecnie cofnąć.

### MEC-028: Bazowe statystyki i konfiguracja przeciwników

- Wszystkie bazowe parametry bohatera oraz archetypów przeciwników są ustawiane w jednym pliku `scripts/combatant_config.gd`.
- Każdy aktualny przeciwnik — zadymiarz, Burek i Żul 1 — oraz każdy członek przyszłej watahy korzysta z archetypu z tego pliku. Kod walki nie przyjmuje już parametrów przeciwnika podawanych poza konfiguracją.
- Bohater ma bazowo 100 życia, 10 ataku, 0 obrony, 10 zwinności i zasięg 2 pól.
- Pies z parku ma poziom 1, 30 życia, 5 ataku i zasięg 1 pola. Zwycięstwo daje 50 XP.
- Zasięg jest zapisany w polach przyszłej mapy taktycznej. Obecny osobny ekran walki nie ma jeszcze ruchu po siatce, więc nie egzekwuje odległości.
- Lewy klik bezpośrednio w model przeciwnika na ekranie walki wykonuje podstawowy atak. Przyciski pozostałych ruchów pozostają dostępne.
- Główny HUD stale pokazuje pasek i liczbowy stan zdrowia bohatera. Obrażenia z każdej walki są synchronizowane z tym paskiem, a kolejne starcie zaczyna się z aktualnym zdrowiem.

### MEC-015: Specjalizacje — propozycja

- **Zbieracz:** większa pojemność i lepsze ceny puszek.
- **Majster:** szybsze używanie narzędzi i mniejsze zużycie.
- **Kombinator:** więcej działań specjalnych i lepsze wykorzystywanie otoczenia.
- **Ulicznik:** przewaga w walce, zastraszaniu i ucieczce.

Specjalizacje nie muszą być sztywnymi klasami. Mogą wynikać z tego, co gracz faktycznie robi.

## 9. Ekonomia

### MEC-016: Pieniądze

Główne wydatki:

- alkohol,
- papierosy,
- lepsze pojemniki,
- narzędzia i ich naprawa,
- leczenie,
- informacje albo przysługi NPC,
- nocleg lub ulepszenie bezpiecznego miejsca.

### MEC-017: Źródła dochodu

Planowana drabina zarobku:

1. Zbieranie puszek.
2. Zbieranie zwykłego złomu.
3. Rozbieranie wyrzuconych urządzeń.
4. Wycinanie fragmentów metalowej siatki.
5. Zdobywanie droższych części, np. katalizatorów.
6. Zlecenia i handel z NPC.

Im wyższy potencjalny zarobek, tym większe powinny być wymagania, czas oraz ryzyko.

### MEC-019: Sklep osiedlowy

- Do sklepu wchodzi się przez kliknięcie drzwi z niewielkiej odległości.
- Sklep osiedlowy nazywa się **Żuk Gnojarz** i leży daleko od punktu startowego.
- Kiosk stoi blisko punktu startowego i sprzedaje papierosy taniej: 5,00 zł za +42 nikotyny.
- Podczas zakupów ruch bohatera jest zatrzymany.
- **Piwo:** koszt 4,00 zł, przywraca 35 punktów paska alkoholu.
- **Małpka:** koszt 7,50 zł, przywraca 60 punktów paska alkoholu.
- **Papierosy:** koszt 5,50 zł, przywracają 42 punkty paska nikotyny.
- Potrzeby nie spadają wraz z czasem. Zwykła udana akcja terenowa (podniesienie puszki, przeszukanie kosza albo sprzedaż puszek) kosztuje po 1 punkcie alkoholu i nikotyny.
- Zbieranie oraz sprzedaż puszek są możliwe także przy zerowych paskach; koszt zatrzymuje się na zerze.
- Wycinanie siatki wymaga minimum 5 punktów obu potrzeb i po udanej akcji odejmuje po 5 punktów.
- Bohater rozpoczyna prototyp z kwotą 5,00 zł.
- Wartości są testowe i zostaną zbalansowane po sprawdzeniu pełnej pętli.

## 10. Struktura dnia

### MEC-018: Upływ czasu — propozycja

- Czas płynie podczas chodzenia oraz wykonywania działań.
- Sklepy, skupy i konkretni NPC działają w określonych godzinach.
- W nocy pojawiają się inne okazje i zagrożenia.
- Bohater powinien planować trasę tak, aby zdążyć sprzedać zdobyte rzeczy i zaspokoić potrzeby.

## 11. Kolejność implementacji

### Etap 1 — podstawowe przetrwanie

- [x] `FAB-01 — Pierwszy kurs`: intro, reklamówka, 8 gwarantowanych puszek, dwa kursy, oba zakupy i cel prowadzący do Mirka.
- [x] Poruszanie postacią.
- [x] Kolizje z przeszkodami.
- [x] Klikanie i podnoszenie puszek.
- [x] Pojemność reklamówki — 6 puszek.
- [x] Licznik zajętego i maksymalnego miejsca.
- [x] Automat przy sklepie jako punkt sprzedaży puszek.
- [x] Pieniądze.
- [x] Wejście do sklepu i zakup używek.
- [x] Pasek głodu alkoholowego.
- [x] Pasek głodu nikotynowego.

### Etap 2 — rozwój zbieracza

- [x] Różne pojemniki — reklamówka, duża torba i wiadro.
- [x] Waga i rozmiar przedmiotów.
- [x] Ekran ekwipunku pod klawiszem I.
- [x] Pierwsze narzędzie — nożyce do metalu poza limitem pojemnika.
- [x] Zużycie i naprawa narzędzi.
- [x] Czas wykonywania oraz anulowanie akcji.
- [x] Pierwszy NPC — Mirek ze skupu złomu.
- [x] Zadanie: 4 puszki → nożyce → wycięcie siatki → sprzedaż.
- [x] Lepsza cena puszek na złomie.
- [x] Przeszukiwanie koszy: 1–3 puszki i 25% szansy na drut.

### Etap 3 — pierwsza walka

- [x] Grywalny prototyp osobnego ekranu walki uruchamiany przez zadymiarza pod kioskiem.
- [x] Prototypowe życie oraz stany `GOTOWY` i `PRZEWAGA`.
- [x] Jeden prototypowy przeciwnik z prostym AI.
- [x] Cztery podstawowe ruchy: dwa ofensywne i dwa obronne.
- [x] Sekwencyjne animacje akcji i pasków życia.
- [x] Obrażenia, garda, trzyturowy unik, ładowanie silnego ataku i przewaga.
- [ ] Fabularny kontekst spotkania oraz ucieczka.
- [ ] Konsekwencja wygranej oraz przegranej.

### Etap 4 — strategiczne RPG

- [x] Podstawowe poziomy, XP, punkty statystyk i ich wpływ na walkę.
- [ ] Specjalizacje wynikające ze stylu gry.
- [ ] Poziom zainteresowania otoczenia.
- [ ] Więcej lokacji i źródeł dochodu.
- [ ] Relacje z NPC.
- [x] Drugi NPC — Heniek Mechanik — oraz wieloetapowe zlecenie z wymianą przedmiotów i nagrodą XP.
- [ ] Generowanie wariantów map.
- [ ] Zapis i wczytywanie gry.

## 12. Najbliższa grywalna wersja

Najbliższy pionowy wycinek powinien pozwalać:

1. Zebrać ograniczoną liczbę puszek do reklamówki.
2. Zobaczyć koszt potrzeb naliczany za wykonane działania, a nie za upływ czasu.
3. Sprzedać puszki.
4. Kupić najtańszy alkohol albo papierosy.
5. Zdecydować, którą potrzebę zaspokoić przy ograniczonej ilości pieniędzy.
6. Wrócić następnego dnia i powtórzyć pętlę.

To wystarczy, aby sprawdzić, czy podstawowa decyzja ekonomiczna jest interesująca przed dodaniem walki i bardziej ryzykownych źródeł dochodu.

## 13. Bank pomysłów — postacie i mechaniki

Poniższe elementy są pomysłami do rozwinięcia. Nie są jeszcze wdrożone ani przypisane do konkretnego etapu fabuły.

### Postacie

#### Król Azbestu

- Lokalna osiedlowa legenda związana z rozbiórkami, starymi garażami i podejrzanymi materiałami budowlanymi.
- Może zlecać ryzykowne prace wymagające odpowiednich narzędzi albo ochrony.
- Dokładna rola, wygląd i relacja z bohaterem pozostają do ustalenia.

#### Grażyna z mięsnego

- Pracownica albo właścicielka osiedlowego sklepu mięsnego.
- Może być źródłem plotek, drobnych zleceń oraz przecenionej lub przeterminowanej żywności.
- Dokładna rola fabularna i mechaniczna pozostaje do ustalenia.

#### Dziadek osiedlowy

- Stały obserwator życia osiedla, znający mieszkańców, skróty i historie okolicy.
- Może uczyć bohatera praktycznych umiejętności, wskazywać znaleziska albo ostrzegać przed zagrożeniami.
- Jest kandydatem na nauczyciela zgniatania puszek, ale przypisanie tej umiejętności nie jest jeszcze ostateczne.

### MEC-026: Zgniatanie i ponowne pompowanie puszek — propozycja

- Bohater może nauczyć się **zgniatania puszek** od jednej z napotkanych postaci.
- Zgniecione puszki zajmują mniej miejsca, dzięki czemu w tym samym pojemniku można przenosić ich więcej.
- Automat kaucyjny nie przyjmuje zgniecionych puszek po standardowej cenie.
- Zgniecione puszki można sprzedać taniej na złomie jako aluminium.
- Późniejsza umiejętność **pompowania puszek** pozwala przywracać im kształt i ponownie sprzedawać je w automacie po lepszej cenie.
- Pompowanie wymaga dostępu do kompresora, na przykład na stacji paliw.
- Proces może kosztować czas, energię lub drobną opłatę, aby odzyskiwanie puszek nie usuwało całego kompromisu ekonomicznego.
- Stan puszki powinien być widoczny w ekwipunku: `cała`, `zgnieciona` albo `napompowana`.

Mechanika tworzy wybór między wygodą transportu a wartością towaru: gracz może zabrać więcej puszek i sprzedać je taniej albo zachować ich kształt, szybciej zapełnić pojemnik i otrzymać lepszą cenę.

### MEC-029: Rabusiostwo, demolowanie i zastraszanie — zatwierdzone do wdrożenia

- Przy koszu bohater ma dwie różne akcje:
  - **Zajrzyj do kosza** — cicha i legalniejsza czynność, obecny drop 1–3 puszek oraz 25% szansy na drut.
  - **Rozwal kosz** — wykorzystuje atak bohatera, robi dużo hałasu, niszczy obiekt i daje wyraźnie lepszy drop.
- Rozwalony kosz jest jednorazowy i nie może później zostać normalnie przeszukany ani ponownie farmiony.
- Przed potwierdzeniem demolowania UI pokazuje przewidywany lepszy łup, hałas oraz wzrost rabusiostwa. Gracz świadomie wybiera szybszy zarobek kosztem długoterminowych konsekwencji.
- **Rabusiostwo** jest trwałą reputacją stylu gry. Rośnie przez demolowanie, kradzieże, groźby oraz inne agresywne zdobywanie przedmiotów.
- **Zainteresowanie otoczenia** z `MEC-009` pozostaje osobnym, krótkotrwałym alarmem dla aktualnej lokacji lub działania. Wysokie rabusiostwo przyspiesza jego wzrost, skraca bezpieczne okno na kradzież i powoduje szybszą reakcję świadków lub policji.
- Wysokie rabusiostwo pogarsza nastawienie policji, mieszkańców oraz uczciwych sprzedawców. Mogą częściej obserwować bohatera, odmawiać pomocy, podnosić ceny albo szybciej zgłaszać podejrzane zachowanie.
- Jednocześnie część przestraszonych lub półświatkowych NPC może ustępować bohaterowi: oferować lepszą cenę skupu, niższą cenę zakupu, dodatkowe informacje albo unikać walki.
- Premia ze strachu nie działa u wszystkich handlarzy. Niektórzy reagują odmową, ochroną albo policją, dzięki czemu rabusiostwo nie jest prostym ulepszeniem ekonomii.
- Progi rabusiostwa powinny odblokowywać zauważalne reakcje świata, np. `nieznany`, `podejrzany`, `groźny`, `postrach osiedla`, zamiast dawać niewidoczną premię za każdy punkt.
- Stan rabusiostwa powinien być widoczny w ekranie postaci lub reputacji. Przy konkretnej interakcji gra pokazuje, czy cena wynika z sympatii, strachu czy normalnego handlu.

Mechanika ma tworzyć dwa style gry: spokojne przeszukiwanie z lepszymi relacjami i większą ilością czasu albo agresywne demolowanie z lepszym łupem, szybszym alarmem i dostępem do zastraszania.

### Do ustalenia

- Która postać uczy zgniatania puszek, a która pompowania?
- Czy zgniatanie jest osobną akcją w ekwipunku, czy odbywa się automatycznie po wybraniu odpowiedniego trybu pojemnika?
- Ile miejsca zajmuje puszka w każdym stanie?
- Czy napompowana puszka zawsze przechodzi kontrolę automatu, czy istnieje ryzyko odrzucenia?
- Czy korzystanie z kompresora na stacji wymaga zgody pracownika, opłaty albo wykonania zlecenia?
- Jaki dokładnie drop daje rozwalenie kosza i czy zależy od Ataku albo Siły?
- Ile rabusiostwa daje demolowanie bez świadków, a ile działanie zauważone przez mieszkańca lub kamerę?
- Czy rabusiostwo samo spada między dniami, czy wymaga łapówek, przysług, odpracowania szkód albo zmiany dzielnicy?
- Którzy handlarze reagują strachem lepszą ceną, a którzy zamykają handel lub wzywają pomoc?
- Czy rozwalenie kosza kosztuje 1 punkt obu potrzeb jak lekka akcja, czy więcej jako ciężkie działanie?
