# Złomowy Baron

## Wersja Godot 4 — przygodowa gra 2D

Aktualna wersja z poruszającym się bohaterem, kolizjami i podnoszeniem puszek znajduje się w katalogu [`godot`](godot/README.md). Otwórz plik `godot/project.godot` w Godot 4.3 lub nowszym.

Poniższa część opisuje wcześniejszy prototyp przeglądarkowy.

Grywalny prototyp strategii ekonomicznej 2D o prowadzeniu złomowiska.

## Uruchomienie

Otwórz `index.html` w przeglądarce albo uruchom prosty serwer:

```bash
python3 -m http.server 8080
```

Następnie wejdź na `http://localhost:8080`.

## Obecna pętla gry

1. Kup dostawę niesortowanego złomu.
2. Sortownia przetwarza go na stal, miedź i tworzywa.
3. Obserwuj zmienne ceny i sprzedawaj surowce.
4. Zatrudniaj ludzi, stawiaj budynki i realizuj kontrakty.
5. Każdego ranka opłacasz załogę, a rynek oraz dostawy się zmieniają.

Stan gry nie jest jeszcze zapisywany. To pionowy prototyp do sprawdzenia, czy główna pętla daje satysfakcję przed rozbudową pełnej wersji.
