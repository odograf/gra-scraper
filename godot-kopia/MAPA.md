# Pamięć mapy — Złomiarz RPG

Ten plik jest krótką pamięcią wspólnej pracy nad mapą. Możesz dopisywać tu zwykłym językiem nowe informacje, nawet pojedynczym zdaniem. Skill `kartograf` przed zmianą mapy sprawdza ten plik, scenę i kod, a po wdrożeniu aktualizuje stan oraz dziennik.

## Jak dopisać informację

Najprostszy format:

```text
POMYSŁ: Przy garażach ma być wejście do kanałów.
DECYZJA: Wejście do kanałów jest za magazynem i wymaga łomu.
PROBLEM: Pies z drugiej watahy blokuje przejście do kontenerów.
```

`POMYSŁ` nie jest jeszcze kanonem. `DECYZJA` oznacza regułę zaakceptowaną do wdrożenia. `PROBLEM` wymaga sprawdzenia na mapie.

## Zatwierdzone zasady

- Aktywny projekt to `/Users/konradodo/Documents/gra/godot-kopia`.
- Mapa ma rozmiar 2800×1600 px, a bazowy kafel terenu 128×128 px.
- Główna scena mapy to `scenes/world_map.tscn`; podłoże edytuje się w `TerenBazowy`.
- Pozycje rozgrywki ustawia się markerami w `PunktyRozgrywki`. `scripts/main.gd` powinien je odczytywać, a współrzędne awaryjne są tylko fallbackiem.
- Budynki i duże obiekty zachowują prosty frontalny rzut z lekko widocznym dachem. Bez perspektywy 3/4, ukośnych ścian i izometrii.
- Grafika, collision shape i punkt interakcji muszą tworzyć jedno czytelne miejsce z dostępnym dojściem.
- Typowy zasięg interakcji wynosi 150–175 px.
- Stabilnych nazw markerów i obiektów nie zmieniamy bez migracji, ponieważ korzystają z nich kod, testy i zapisy gry.
- Nowa gra zaczyna się w melinie, potem prowadzi na przedmieście, a północne wyjście z przedmieścia wczytuje pełną mapę osiedla.
- Pełna mapa osiedla nie może być przesunięta względem granic kamery ani ucięta.
- W aktywnym świecie istnieje jeden kiosk i jeden sklep Żuk Gnojarz; oba znajdują się na mapie osiedla, nie na przedmieściu.

## Stan wdrożony

### Główne strefy

- Melina startowa: pobudka, reklamówka i sześć puszek samouczka.
- Przedmieście: rozwalona szopa, samotny pies, wataha dwóch psów, cztery szczury i północna brama na osiedle. Bez duplikatów kiosku i sklepu.
- Rejon startowy: bohater, reklamówka, kiosk, automat, zadymiarz i początkowe kontenery.
- Północny wschód: sklep Żuk Gnojarz z Burkiem przy wejściu.
- Środek mapy: zamknięty z trzech stron punkt Mirka przy starym Żuku; dojście od dołu może być blokowane przez Żula 1.
- Lewy dół: zaniedbany park za płotem, przejście przez wycinany fragment siatki i trzy watahy psów 2/3/4.
- Dolna część: garaże, Heniek Mechanik oraz trzy Szczóry podzielone na samotnego i parę.
- Wschód i południowy wschód: magazyn, pusty plac, dodatkowe kontenery oraz rozrzucony złom.

### Markery rozgrywki

- `Start/Bohater` — pozycja startowa.
- `Start/WejscieZPrzedmiescia` — południowe wejście na pełną mapę po opuszczeniu przedmieścia.
- `Interakcje` — reklamówka, automat, sklep, kiosk, zadymiarz, Mirek, Heniek i siatka.
- `StanyNPC` — pozycje Burka oraz Żula przed walką, podczas blokady i po przegranej.
- `Kontenery` — cztery grupy kontenerów; trzy dalsze gwarantują drut.
- `Szczory` — grupy dropu oznaczone metadanymi `rat_group`.
- `WatahyPsow` — identyfikatory watahy i psa w `pack_id` oraz `dog_index`.
- `Puszki` — 30 ręcznie rozmieszczonych punktów z trwałymi nazwami.

### Drogi i kolizje

- Główna ulica biegnie pionowo, a dojazd do garaży poziomo.
- Świat ma zamknięte granice kolizji.
- Kolizje mają kiosk, sklep, kontenery, ławka, samochód, punkt Mirka, magazyn, garaże, płot, drzewa i parkowe przeszkody.
- Przejście do Mirka od dołu ma pozostać czytelne i wystarczające dla bohatera oraz stanów Żula.
- Park ma szeroką wydeptaną trasę od przerwy w płocie do polan watah.

## Otwarte decyzje

- Dalszy podział osiedla na osobne dzielnice lub ładowane sceny poza ustalonym ciągiem melina → przedmieście → osiedle.
- Wejścia do wnętrz budynków i kanałów.
- Docelowy system dnia, ruchu przechodniów i zmian mapy zależnych od pory.
- Które dekoracje mają być wyłącznie wizualne, a które otrzymają kolizję albo interakcję.

## Pomysły do rozważenia

- Brak zapisanych pomysłów. Dopisz pierwszy w formacie `POMYSŁ: ...`.

## Dziennik zmian

- 2026-08-28 — podłączono właściwy początek gry: menu → melina → przedmieście → pełna mapa osiedla; dodano południowy punkt wejścia, usunięto z przedmieścia duplikaty kiosku i Żuka oraz wyzerowano przesunięcie ucinające mapę.
- 2026-08-28 — utworzono jednoplikową pamięć mapy i skill `kartograf`; zapisano aktualny układ stref, markery oraz najważniejsze zasady spójności.
