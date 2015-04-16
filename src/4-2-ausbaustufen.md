## Ausbaumöglichkeiten {#sec:ausbaustufen}

### Zeitpunkte für Daten-Aktualisierung

Mit steigender Anzahl von Serien in der Datenbank wird das Aktualisieren der Daten und damit auch das Laden neuer Episoden über die APIs immer länger dauern. Aktuell existiere nur die Möglichkeit, alle Serien-Daten zu aktualisieren.

Eine Verbesserungs-Möglichkeit wäre, ein Scheduling-System zu verwenden, indem einzelne Serien zu bestimmten Zeitpunkten aktualisiert werden. Während laufende Serien so z.B. einmal pro Woche (etwa zwei Tage vor dem Ausstrahlen einer neuen Episode) aktualisiert werden, könnten beendete Serien weniger häufig aktualisiert werden, da sich diese Daten mit hoher Wahrscheinlichkeit nicht mehr ändern werden.

### Durchschnitts-Bewertungen speichern

Aktuell werden Durchschnitts-Bewertungen immer dynamisch berechnet. Für Serien ist dies jedoch mit steigender Anzahl Bewertung recht zeitaufwendig, da immer alle Bewertungs-Einträge gelesen werden müssen. Würde man diese Durchschnitt beim Anlegen bzw. Aktualisieren einer Bewertung berechnen und in der Serie oder Episode speichern, könnte diese Zeit sparen. (Es wird angenommen, dass die Serien bzw. Episoden und deren Durchschnitte häufiger abgefragt werden als Bewertungen gespeichert werden.)

Dies könnte entweder in der _node_-Anwendung beim Speichern einer Bewertung oder aber in der _Postgres_-Datenbank über _Trigger_ realisiert werden.

### Empfehlungen basierend auf bisherigen Bewertungen

Als Benutzer von EpisodeFever möchte ich nicht nur mir bekannte Serien bewerten, sondern auch neue entdecken. Ein bekannter und hilfreicher Mechanismus dazu ist das Darstellen von Empfehlungen, welche auf Basis von den von mir und den von anderen Benutzern abgegebenen Bewertungen.

Viele Algorithmen zum Bestimmen von Empfehlungen beziehen sich auf den E-Commerce-Markt, bei dem es darum geht, Benutzern Produkte zu empfehlen, die sie vielleicht auch kaufen wollen. Häufig sind die einzigen Metriken dazu positive Ereignisse, z.B. "Benutzer A hat Produkt X angesehen" oder "Benutzer A kaufte Produkt X".

Die von EpisodeFever erfassten Bewertungen bieten dabei detailliertere Informationen. Sie bilden dabei nicht nur die Relation "Benutzer A mag Episode X" (und darüber transitiv auch "Benutzer A mag Serie Z") ab, sondern auch "Benutzer gefällt Episode B nicht" bzw. "Benutzer ist Episode C gegenüber indifferent". Ein möglicher Empfehlungs-Mechanismus muss auch diese Zu- oder Abneigung verarbeiten, um alle Informationen auszunutzen und möglichst genau zu arbeiten.

### Benutzern das explizite Verwalten von betrachteten Serien erlauben {#sec:watches}

In der aktuellen Form der Anwendung werden die Relationen zwischen Benutzern und Serien nur implizit über die abgegebenen Bewertungen gesetzt. Wurde eine Serie bewertet, so wird angenommen, dass der Benutzer sie schaut.

Dies hat jedoch zwei Schwachstellen:

1. Der Benutzer kann keine Serie explizit entfernen, sodass sie nicht mehr in seiner Liste zukünftiger Episoden auftaucht.
2. Es können keine Serien vorgemerkt werden, welche zwar schon angekündigt wurden, wo aber noch keine Episode ausgestrahlt wurde.

Möglicher Lösungsansatz wäre hier, eine neue Relation _Watch_[^name-watch] hinzuzufügen. In dieser wird bei der ersten Bewertung automatisch ein Eintrag mit Benutzer- und Serien-ID erzeugt. Zusätzlich wird dem Benutzer aber auch ermöglicht, selbst diese Relation zu erzeugen, eine Liste mit _Watches_ einzusehen und Einträge daraus zu entfernen.

[^name-watch]: Von engl. _schauen_, _betrachten_ ("eine Fernsehserie schauen"), nicht _Armbanduhr_.

### Server-Infrastruktur

Um die entwickelte Software betreiben zu können, wird (mindestens) ein korrekt konfigurierter Server benötigt, auf welchen die _node_-Anwendung sowie _Postgres_ ausgeführt wird. Dies ist bereits nötig, um die Software entwickeln und testen zu können. Die Hardware-Anforderungen für einen solchen Server sind im Vergleich zu existierenden Angeboten[^vserver-preise] nicht besonders hoch; Die _node_-Anwendung braucht auf dem Entwicklungssystem etwa 36MB RAM und minmal CPU-Leistung. Da die in der Postgres-Datenbank gespeicherten Daten ebenfalls nicht sehr groß sind, sollte es möglich sein, auf einem Server mit 2GB RAM die gesamte Datenbank im Hauptspeicher zu halten.

Um statische Dateien performant auszuliefern (z.B. Grafiken) und komprimierte Verbindungen sowie verschlüsselte Protokolle wie HTTPS und HTTP2 verwenden, sollte zudem ein Web-Server wie [nginx](http://nginx.org/) als _Reverse Proxy_ verwendet werden, welcher im vor der _node_-Anwendung liegt und an diese die relevanten HTTP-Anfragen weitergibt.

Es ist zu bedenken, dass Anwendungen auf Basis von _node_ standardmäßig zwar asynchronen Kontrollfluss verwenden, jedoch JavaScript nur in einem Thread ausführen. Auf diese Weise kann der JavaScript-Teil einer _node_-Anwendung keinen Gebrauch von Mehrprozessor-Systemen machen. Eine recht einfache Lösung dafür ist es, die Anwendung in einem _Cluster_ zu verwenden. Dabei startet ein Master-Prozess die Anwendung in einer beliebigen Anzahl von Kind-Prozessen und gibt Netzwerk-Anfragen an diese weiter.

_Cluster_ ist ein mit _node_ mitgeliefertes Modul. Es ist jedoch von Vorteil, auf einen komplexeres Tool wie [PM2](https://github.com/Unitech/pm2) zurückzugreifen. Dieses kann nicht nur mehrere Anwendungen ohne Code-Änderungen als Cluster starten, sondern stellt auch fest, wenn diese abstürzen und kann sie dann neu starten. Des Weiteren bietet es einige Möglichkeiten, Log-Ausgaben mitzuschreiben und CPU- und Speicher-Auslastung pro Prozess einzusehen.

### Analyse von Protokoll-Daten

Die Server-Anwendung schreibt Informationen zu jeder gesendeten HTTP-Antwort sowie zu jeder SQL-Abfrage auf `stdout` (d.h., das Terminal, wenn die Anwendung im Vordergrund läuft, ansonsten das System-Log). Die Protokoll-Daten beinhalten einen Zeitstempel, Art der Anfrage, de Rückgabewert (Fehler-Code) und wie lange der Server brauchte, um die Anfrage zu bearbeiten. Diese Daten müssen im aktuellen Zustand von einem Entwickler oder Administrator persönlich ausgewertet werden, was das Auffinden von Fehlern von Geschwindigkeits-Problemen erschwert.

Um diese Daten analysieren und darstellen zu können, gibt es passende Software, welche teilweise unter einer Open-Source-Lizenz (vgl. [@osslicenses]) verfügbar ist. Ein Beispiel hierfür ist die Kombination aus _Logstash_, _Elasticsearch_ und _Kibana_ ("ELK", [@elk]).

Mit einer angepassten Konfiguration sollte es möglich sein, die Protokolle der EpisodeFever-Anwendung mit _Logstash_ einlesen zu lassen und die Daten in eine _Elasticsearch_-Datenbank zu schreiben. Mit _Kibana_ lassen sich diese dann grafisch darstellen, filtern und auswerten.
