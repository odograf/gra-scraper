# Mockup nowego początku — `PROLOG-00`

Status: **właściwy początek nowej gry**, połączony z pełną mapą osiedla.

## Uruchamianie i przełączanie

- `F5` uruchamia menu główne; opcja **NOWA GRA** otwiera melinę.
- Otwórz `scenes/melina_prologue_mockup.tscn` i naciśnij `F6`, aby uruchomić nowy prolog.
- Drzwi przełączają scenę na `scenes/start_suburb_mockup.tscn`.
- `F2` uruchamia melinę od początku, a `F1` pozostaje skrótem deweloperskim do obecnej gry.
- Północne wyjście z przedmieścia prowadzi do pełnej `scenes/main.tscn`; mapa nie jest przesunięta ani przycięta.

## Hierarchia sceny

```text
MelinaPrologueMockup (osobna scena)
├── Player + Camera2D
├── reklamówka
├── 6 puszek
├── drzwi wyjściowe
└── UI prologu

StartSuburbMockup (osobna scena)
├── Player + Camera2D
├── samotny pies przy szopie
├── wataha 2 psów dalej od wyjścia
├── stado 4 szczurów przy odpływie
├── północne wyjście na osiedle
└── UI

PrologueMockupState (statyczne dane przejściowe)
└── reklamówka, puszki i zdrowie zachowane podczas zmian scen
```

## Przebieg

1. Bohater budzi się w melinie między budynkami. Przejście ma dokładnie 3 kratki szerokości (`3 × 64 px`).
2. Dialog, przeklikiwany lewym przyciskiem:

   > Ale mam kaca. No nic, pora go wyleczyć. Problem jest taki, że nie ma za co. Wezmę siateczkę i idę po puszki.

3. Gracz podnosi reklamówkę.
4. Drugi dialog:

   > Jest i siateczka. Nie tylko bagaż, ale i broń prawdziwego mężczyzny. Zbiorę kilka puszek w melinie. Jestem jak perpetuum mobile.

5. Gracz zbiera wszystkie 6 puszek znajdujących się w melinie.
6. Trzeci dialog:

   > Pora iść do automatu i zarobić nieco grosza. Ciekawe, czy te wygłodniałe psy nadal kręcą się na zewnątrz.

7. Dopiero teraz można użyć drzwi. Godot zwalnia scenę meliny i wczytuje osobną scenę przedmieścia, gdzie bohater pojawia się przed rozwaloną szopą.
8. Przy wyjściu kręci się samotny pies. Dalej stoi wataha dwóch psów, a przy odpływie żerują cztery szczury.
9. Przejście przez północną bramę wczytuje pełną mapę osiedla i ustawia bohatera przy jej południowej krawędzi.
10. Jedyny kiosk i jedyny sklep Żuk Gnojarz znajdują się na pełnej mapie osiedla; przedmieście ich nie powiela.

## Assety wykorzystane w mockupie

- bohater i jego animacje ruchu/zbierania/ataku reklamówką,
- proceduralna reklamówka startowa,
- puszka `crushed_can.png`,
- dziki pies `wild_emaciated_dog_sheet_v2_packed.png`,
- szczur `sewer_rat_sheet_v1.png`,
- płot, kosze, skrzynki złomu,
- asfalt, chodnik i trawa z obecnego zestawu terenu.

## Grafiki do wygenerowania

### Priorytet A — potrzebne do właściwej wersji prologu

1. **Rozwalona szopa — front zewnętrzny**, dwa stany drzwi: zamknięte i otwarte.
2. **Wnętrze meliny — moduły 64×64:** brudna podłoga, popękane ściany, narożniki, próg i prześwit drzwi.
3. **Boczne ściany budynków tworzące przejście szerokie na 3 kratki**, frontalne/ortograficzne, bez perspektywy 3/4.
4. **Reklamówka jako właściwy sprite mapowy** leżący na ziemi; obecnie jest czytelnym rysunkiem proceduralnym.
5. **Automat na puszki jako osobny sprite mapowy**, zgodny kątem z kioskiem i sklepem.

### Priorytet B — klimat meliny i przedmieścia

6. Materac, koc, gazety, puste butelki, wiadro, stary taboret i sterta ubrań.
7. Gruz, deski, kawałki blachy, przewrócone ogrodzenie oraz ślady błota.
8. Studzienka/odpływ i szczurze gniazdo dla stada czterech szczurów.
9. Fronty małych domów, szeregu garaży i opuszczonego warsztatu.
10. Słupy, latarnie, skrzynki elektryczne, znaki i przydrożne chwasty.

### Priorytet C — warianty i czytelność zagrożeń

11. 2–3 warianty umaszczenia dzikiego psa, nadal korzystające z tych samych wymiarów i kotwicy animacji.
12. 2 warianty szczura oraz większy szczur-przewodnik stada.
13. Ślady łap, odchody, rozszarpane worki i kości sygnalizujące teren watahy przed wejściem w zasięg agresji.
14. Portret dialogowy bohatera do monologów; obecny model mapowy nie powinien być skalowany do dużego portretu.

## Otwarte decyzje przed podmianą `FAB-01`

- Czy samotnego psa trzeba pokonać, ominąć, czy można odciągnąć puszką?
- Czy puszki z meliny zużywają potrzeby, skoro jest to samouczek przed pierwszym zakupem?
- Czy reklamówka od początku odblokowuje atak obszarowy, czy dopiero dialog po jej podniesieniu?
- Docelowa oprawa przejścia: natychmiastowa zmiana, krótkie wygaszenie czy ekran ładowania.
- Gdzie na przedmieściu stoi pierwszy automat i jak bezpieczna jest droga do niego?
