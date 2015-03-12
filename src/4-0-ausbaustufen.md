# Ausbaumöglichkeiten

## Zeitpunkte für Daten-Aktualisierung

Mit steigender Anzahl von Serien in der Datenbank wird das Aktualisieren der Daten und damit auch das Laden neuer Episoden über die APIs immer länger dauern. Aktuell existiere nur die Möglichkeit, alle Serien-Daten zu aktualisieren.

Eine Verbesserungs-Möglichkeit wäre, ein Scheduling-System zu verwenden, indem einzelne Serien zu bestimmten Zeitpunkten aktualisiert werden. Während laufende Serien so z.B. einmal pro Woche (etwa zwei Tage vor dem Ausstrahlen einer neuen Episode) aktualisiert werden, könnten beendete Serien weniger häufig aktualisiert werden, da sich diese Daten mit hoher Wahrscheinlichkeit nicht mehr ändern werden.

## Durchschnitts-Bewertungen speichern

Aktuell werden Durchschnitts-Bewertungen immer dynamisch berechnet. Für Serien ist dies jedoch mit steigender Anzahl Bewertung recht zeitaufwendig, da immer alle Bewertungs-Einträge gelesen werden müssen. Würde man diese Durchschitt beim Anlegen bzw. Aktualisieren einer Bewertung berechnen und in der Serie oder Episode speichern, könnte diese Zeit sparen. (Es wird angenommen, dass die Serien bzw. Episoden und deren Durchschnitte häufiger abgefragt werden als Bewertungen gespeichert werden.)

Dies könnte entweder in der _node_-Anwendung beim Speichern einer Bewertung oder aber in der _Postgres_-Datenbank über _Trigger_ realisiert werden.

## Empfehlungen basierend auf bisherigen Bewertungen

## Benutzern das explizite Verwalten von betrachteten Serien erlauben {#sec:watches}

## Server-Infrastruktur

## Analyse von Protokoll-Daten

Die Server-Anwendung schreibt Informationen zu jeder gesendeten HTTP-Antwort sowie zu jeder SQL-Abfrage auf `stdout` (d.h., das Terminal, wenn die Anwendung im Vordergrund läuft, ansonsten das System-Log). Die Protokoll-Daten beinhalten einen Zeitstempel, Art der Anfrage, de Rückgabewert (Fehler-Code) und wie lange der Server brauchte, um die Anfrage zu bearbeiten. Diese Daten müssen im aktuellen Zustand von einem Enwtickler oder Administrator persönlich ausgewertet werden, was das Auffinden von Fehlern von Geschwindigkeits-Problemen erschwert.

Um diese Daten analysieren und darstellen zu können, gibt es passende Software, welche teilweise unter einer Open-Source-Lizenz (vgl. [@osslicenses]) verfügbar ist. Ein Beispiel hierfür ist die Kombination aus _Logstash_, _Elasticsearch_ und _Kibana_ ("ELK", [@elk]).

Mit einer angepassten Konfigration sollte es möglich sein, die Protokolle der EpisodeFever-Anwendung mit _Logstash_ einlesen zu lassen und die Daten in eine _Elasticsearch_-Datenbank zu schreiben. Mit _Kibana_ lassen sich diese dann grafisch darstellen, filtern und auswerten.
