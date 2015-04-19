# EpisodeFever Ausarbeitung

Quelldaten finden sich als "Markdown"-Dateien im Verzeichnis `src/`.

Mittels Pandoc können diese zu HTML und (via LaTeX) zu PDF konvertiert werden. Dazu reicht es, `make` in diesem Verzeichnis auszuführen.

Ausgabe-Daten finden sich in `dist/`.

## Details

Informationen zu Markdown: http://daringfireball.net/projects/markdown/syntax

Informationen zu Pandoc: http://johnmacfarlane.net/pandoc/README.html

## Vorraussetzungen

Folgendes sollte installiert sein:

- make
- Pandoc, siehe hier: http://johnmacfarlane.net/pandoc/installing.html
- Für PDF-Ausgabe muss außerdem eine aktuelle LaTeX-Distribution installiert sein (inkl. pdflatex, xelatex).
