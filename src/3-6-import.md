## Import von Daten {#sec:import}

Informationen zu TV-Serien und deren Episoden sind von verschiedenen Diensten verfügbar. Ein wichtiger Teil des Episode-Fever-Projektes ist es, diese Informationen abzufragen und in der lokalen Datenbank so zu speichern, dass die restliche Anwendung effizient darauf zugreifen kann.

Eine der bekanntesten Plattformen für diese Daten ist TheTVDB [@thetvdb], auf welcher Freiwillige Metadaten, Beschreibungen und sogar Grafiken zu Serien in verschiedenen Sprachen eintragen können, welche dann unter einer freien Lizenz[^cc3-by-us] zur Verfügung stehen.

Außerdem bietet TheTVDB eine XML-API, mit der es möglich ist, nach Serien zu suchen und die gesamten Daten zu einer Serie (inkl. Daten zu Episoden) abzufragen.

[^cc3-by-us]: "Creative Commons Attribution 3.0 United States", vgl. @cc3-by-us.

### XML-Daten abfragen und verarbeiten {#sec:import-requests}

Um mit der XML-API über HTTP zu kommunizieren, wurde _superagent_ [@superagent] eingesetzt. Basierend auf den von Node mitgelieferten HTTP-Client-Funktionen[^superagent-browser] bietet es eine übersichtliche Schnittstelle zum Erstellen von komplexen HTTP-Requests. Um den Umgang mit asynchronen Funktionen zu vereinfachen, wurde der Prototyp von _superagent_ um die Methode `.exec()` erweitert, welche ein _Promise_ zurückgibt (siehe [verwendete Technologien](#sec:technologien)).

[^superagent-browser]: _superagent_ kann auch im Browser-Kontext verwendet werden und bietet so eine einheitliche Schnittstelle auf beiden Plattformen.

Um das Arbeiten mit den API-Antworten im XML-Format zu vereinfachen, wurde das Modul _xml2js_ [@xml2js] ausgewählt. Dieses basiert auf dem Streaming-Parser _sax-js_ [@saxjs] und konvertiert XML-Strukturen in JavaScript-Objekte. Hierbei werden einige Optionen angeboten, welche das resultierende Objekt stark vereinfachen können, u.a. um Knoten mit nur einem Kind als direkten Datensatz (und nicht als Array) auszugeben. Da die APIs XML-Dokumente zurückgeben, welche sehr wenig Gebrauch von verschachtelten Knoten oder Attributen machen, kann _xml2js_ Objekte mit flacher Struktur erzeugen, welche einfach zu verwenden sind.

Die gesamte Konfiguration zur Abfrage und Verarbeitung der API-Anfragen kann in der Datei `import/apis/xml_api_helper.js` gefunden werden.

### Verwenden der XML-API von TheTVDB

Jede Anfrage zu der TheTVDB-API muss mit einem API-Key versehen werden (als Teil der URL). Ein solcher Schlüssel kann über [ein Formular](http://thetvdb.com/?tab=apiregister) beantragt werden.

Um die Daten einer TV-Serie auszulesen, muss zunächst die TVDB-eigene ID dieser Serie gefunden werden. Mit dieser kann dann die URL zu dem gesamten Datensatz der Serie generiert werden. Vergleiche hierzu die Abbildung zu [API-Abfragen](#fig:requesting-show-data).

<section id="fig:requesting-show-data">
![Abfragen und Verarbeiten der Daten von TheTVDB und TVRage\label{fig:requesting-show-data}](illustrations/requesting-show-data)

</section>

Obwohl die Daten der API nun als XML (bzw. JavaScript Objekt) vorliegen, müssen noch kleine Transformationen durchgeführt werden, um sie verwenden zu können. So beinhalten einige Felder zwar Zeichenketten, inhaltlich handelt es sich jedoch um Listen von Werten. Das "Genre"-Feld einer Serie kann beispielsweise den Wert `"|Action|Adventure|Comedy|Drama|"` haben.

### Datum und Zeit einer Episode auslesen

Des Weiteren ist das Verarbeiten von Datumsformaten notwendig. Ziel ist es, jeder Episode sowohl Datum als auch Uhrzeit zuzuordnen, wann sie (zuerst) ausgestrahlt wurde. Dies ermöglicht es insbesondere, zukünftige Episoden abzufragen, z.B. um einen Kalender zu implementieren und Benutzer im Voraus zu benachrichtigen.

Die API von TheTVDB beinhaltet hierzu nur ungenaue Daten [@local-time]. Jede Episode besitzt zwar ein `FirstAired`-Feld, dieses beinhaltet jedoch nur das Datum (z.B. `"2009-02-03"`). Die Uhrzeit der Ausstrahlung ist jedoch im Datensatz der Serie verfügbar (`Airs_Time`), vermutlich unter der Annahme, dass diese typischerweise nicht variiert. Das Format der Uhrzeit ist jedoch nicht eindeutig, da Werte wie `"8:00 PM"` verwendet werden, und keine Zeitzone angegeben wird. Es scheint immer die Zeitzone des TV-Senders, auf dem die Serie initial ausgestrahlt wird, verwendet zu werden. Da aber keine Zuordnung von Sendern zu Zeitzonen verfügbar ist, kann hierdurch auch keine genaue Zeitangabe berechnet werden.

Diese Lücke in der TheTVDB-API bedeutet für EpisodeFever, dass entweder nur unvollständige Daten verfügbar sind, oder zusätzlich Daten aus einer zweiten Quelle geladen werden müssen.

### Kombination von TheTVDB und TVRage

Eine weitere Quelle für Daten zu TV-Serien ist TVRage [@tvrage]. Diese Webseite bietet ähnliche Daten wie TheTVDB und wird (zum Teil) ebenfalls von Freiwilligen gepflegt. TVRage bietet ebenfalls eine XML-API, über die Metadaten zu Serien und Episoden abgefragt werden können. Die Endpunkte von TVRage sind ähnlich zu denen von TheTVDB, verwenden aber unterschiedliche URL-Strukturen und Feld-Bezeichnungen.

Die Daten von TVRage beinhalten vor allem aber neben dem Feld `airtime` (welches zudem das 24-Stunden-Format für Uhrzeiten verwendet) auch noch das Feld `timezone`, welches Zeitzonen in Repräsentationen wie `"GMT-5 +DST"` beinhaltet. 

An TVRage werden die identischen Anfragen gestellt wie an TheTVDB (mit Angepassten URLs und Parametern), sodass nun pro Serie zwei Datensätze zur Verfügung stehen[^api-misses]. Da die Daten von TVRage keine Beschreibungen beinhalten[^tvrage-descriptions] und die weiteren Informationen identisch sein sollten, werden nur die Informationen zum Ausstrahlungs-Zeitpunkt von TVRage übernommen.

[^api-misses]: Tatsächlich wird bei der initialen Abfrage der Daten der von TheTVDB zurückgegebene Name der Serie für die Suche mit der TVRage-API verwendet. So wird mit großer Sicherheit die selbe Serie von beiden APIs geliefert. Durch Vergleiche zusätzlicher Daten beim Import kann dies zusätzlich geprüft werden.

[^tvrage-descriptions]: Die Beschreibungen von TVRage können nur mit API-Keys mit speziellen Berechtigungen geladen werden.

### Aktualisieren von Serien

Beim initialen Hinzufügen von Serien werden diese anhand ihres Namens gesucht. Das Aktualisieren von Serien kann diesen Schritt überspringen, da mit jedem Serien-Eintrag in der Datenbank ebenfalls die IDs von TheTVDB und TVRage gespeichert werden.

Dazu werden zugehörige Episoden anhand von Staffel und Nummer eideutig identifiziert und können so auch aktualisiert werden.

Im derzeitigen Stadium werden alle Serien aktualisiert. Eine mögliche Verbesserung wäre, nur dann neue Daten abzufragen, wenn Aktualisierungen am wahrscheinlichsten oder am relevantesten sind. Das könnte für laufende Serien beispielsweise am Tag vor dem Ausstrahlen neuer Episoden sein. Außerdem könnte für beendete Serien ein sehr viel geringerer Rhythmus gewählt werden.

### Import automatisiert testen

Wie die restliche Anwendung auch, soll der Import von Serien testbar sein, um Regressionen zu vermeiden. Da der Import jedoch von externen Diensten abhängt, gibt es hier einige zusätzliche Problemquellen. Die Dienste könnten offline sein, die Struktur ihre Antworten ändern oder auch abgeschaltet werden.

#### HTTP-Anfragen aufzeichnen

Es erschien sinnvoll, die HTTP-Anfragen an externe Dienste zwischen zu speichern und nur zu bestimmten Zeitpunkten zu aktualisieren[^external-api-breakage].

Das Modul _replay_ [@replay] erlaubt es, das in _node_ integriert HTTP-Modul so zu überschreiben, dass es in verschiedenen Modi operieren kann, vor allem `record` and `replay`. (Ursprünglich konnte _replay_ URLs nicht anhand ihrer Query-Parameter unterscheiden, dies wurde als Patch hinzugefügt, wie in ["Beiträge zu Open Source"](#sec:opensource) erwähnt.)

So können Tests ganz normal auf externe HTTP-Server zugreifen und _replay_ schreibt im `record`-Modus alle erhaltenen Antworten in ein vorher definiertes Verzeichnis. Sobald die Tests erfolgreich ausgeführt wurden, kann auch `replay` umgestellt werden. Von nun an werden die aufgezeichneten Antworten verwendet.

Dieses Vorgehen hat auch den Vorteil, dass Tests sehr viel schneller laufen und unabhängig von einer Internetverbindung sind.

_replay_ zeichnet außerdem sehr viele Header auf und speichert den HTTP-Body komprimiert, wenn die ursprüngliche Antwort komprimiert war. Um die Lesbarkeit der Test-Daten zu verbessern, wurden die Daten manuell entpackt, überflüssige Header entfernt und sprechend benannt.

[^external-api-breakage]: Es könnte beispielsweise alle zwei Wochen ein spezieller Test laufen, welcher die Antworten der APIs vergleicht und einen Entwickler benachrichtigt, wenn es Änderungen gibt. Dies ist unter Umständen auch zuverlässiger als z.B. ein News-Feed zu API-Änderungen eines Dienstes.

#### Tests für zwei APIs

Da zwei kleine Module verwendet werden, um den Zugriff auf die APIs zu abstrahieren, war es möglich, jedem Modul ein identische Interface zu geben. Die Daten-Strukturen in den Antworten der APIs werden jedoch nicht vereinheitlicht.

Alle API-Tests werden unabhängig von der verwendeten API geschrieben und sind Teil einer `testApi`-Funktion. Diese wird mit Test-Daten und einer API-Schnittstelle aufgerufen. So können mit jeder API die identischen Tests aufgerufen werden und es ist sichergestellt, dass die Daten auf die selbe Art und Weise verarbeitet werden können.
