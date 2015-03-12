## Projekt-Struktur: Verzeichnis-Struktur, Aufteilung nach Services {#sec:struktur}

Zu Beginn des Projektes wurde neben der Informationsarchitektur auch beschlossen, wie die Code-Struktur sein soll. Diese lässt sich gut durch die [verwendete Verzeichnisstruktur](#fig:code-structure) darstellen.

<section id="fig:code-structure">
![Verzeichnisstruktur\label{fig:code-structure}](illustrations/code-structure)

</section>

### Services

Die Anwendung wurde in verschiedene _Services_ aufgeteilt, welche möglichst isoliert von einander funktionsfähig sein sollen. Deren Code ist in einzelnen Verzeichnissen in `server/services/` zu finden.

Diese Aufteilung soll es ermöglichen, einzelne Teile der Applikation einfacher überblicken und getrennt voneinander entwickeln zu können. Idealerweise sind Services so modular aufgebaut, dass sie in zukünftigen Projekten wiederverwendet werden können.

Wie in der [Verzeichnisstruktur](#fig:code-structure) zu sehen ist, sind Kern-Bestandteile eines Services:

- der Einstiegspunkt (`index.js`), welcher die Schnittstellen des Services exportiert,
- das Daten-Modell (`model.js` über welches Abfragen und Änderungen an der Datenbank ausgeführt werden, 
- Tests (`tests.js`), welche beschreiben, was der Service behandelt und sicherstellen, dass keine Regressionen auftreten.

### Alternativen

Eine alternative Strukturierung ist das Gruppieren nach Typen, d.h. in Verzeichnisse wie `models`, `controllers` und `specs` (Tests). Dies ist beispielsweise bei Anwendungen basierend auf _Ruby on Rails_ [@rails] typisch. Da dies auf den Code aber nur minimale Auswirkungen hat, ist es letztendlich Geschmacks-Sache. Wir entschieden uns für die oben beschriebe Aufteilung, da diese die inhaltliche Aufteilung in den Vordergrund stellt, nicht die strukturelle.
