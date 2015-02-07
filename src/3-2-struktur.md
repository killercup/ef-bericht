## Projekt-Struktur: Verzeichnis-Struktur, Aufteilung nach Services {#sec:struktur}

Zu Beginn des Projektes wurde nebem der Informationsarchitektur auch beschlossen, wie die Code-Struktur sein soll. Diese lässt sich gut durch die [verwendete Verzeichnisstruktur](#fig:code-structure) darstellen.

<section id="fig:code-structure">
![Verzeichnisstruktur\label{fig:code-structure}](illustrations/code-structure)

</section>

### Services

Die Anwendung wurde in verschiedene _Services_ aufgeteilt, welche möglichst isoliert von einander funktionsfähig sein sollen. Deren Code ist in einzelnen Verzeichnissen in `server/services/` zu finden.

Diese Aufteilung soll es ermöglichen, einzelne Teile der Applikation einfacher überblicken und getrennt voneinander entwickeln zu können. Idealerweise sind Services so modular aufgebaut, dass sie in zukünftigen Projekten wiederverwendet werden können.

