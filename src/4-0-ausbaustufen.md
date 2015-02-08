# Ausbaumöglichkeiten

## Empfehlungen basierend auf bisherigen Bewertungen

## Analyse von Protokoll-Daten

Die Server-Anwendung schreibt Informationen zu jeder gesendeten HTTP-Antwort sowie zu jeder SQL-Abfrage auf `stdout` (d.h., das Terminal, wenn die Anwendung im Vordergrund läuft, ansonsten das System-Log). Die Protokoll-Daten beinhalten einen Zeitstempel, Art der Anfrage, de Rückgabewert (Fehler-Code) und wie lange der Server brauchte, um die Anfrage zu bearbeiten. Diese Daten müssen im aktuellen Zustand von einem Enwtickler oder Administrator persönlich ausgewertet werden, was das Auffinden von Fehlern von Geschwindigkeits-Problemen erschwert.

Um diese Daten analysieren und darstellen zu können, gibt es passende Software, welche teilweise unter einer Open-Source-Lizenz (vgl. [@osslicenses]) verfügbar ist. Ein Beispiel hierfür ist die Kombination aus _Logstash_, _Elasticsearch_ und _Kibana_ ("ELK", [@elk]).

Mit einer angepassten Konfigration sollte es möglich sein, die Protokolle der EpisodeFever-Anwendung mit _Logstash_ einlesen zu lassen und die Daten in eine _Elasticsearch_-Datenbank zu schreiben. Mit _Kibana_ lassen sich diese dann grafisch darstellen, filtern und auswerten.
