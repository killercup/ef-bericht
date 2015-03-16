## Suche

Die Suchfunktionalität ein wichtiger Bestandteil jeder Anwendung, die große Mengen an Daten für die Benutzer zur Verfügung stellt. Sie soll zum einen die Suche nach Information erleichtern und beschleunigen.

Die wesentlichen Features, die diese bieten sollte sind unter anderem:

Wörter auf ihren Wortstamm reduzieren
Stopwörter entfernen (ein, das, im, mit, etc.)
Gewichtung von Suchergebnissen
Rechtschreibkorrektur

Aufgrund der von _PostgreSQL_ zur Verfügung gestellten Funktionen für die Volltextsuche hat sich unsere Entscheidung eben dieses Datenbankschema zu benutzen als richtig erwiesen, da es all die oben genannten Features, aber auch andere nützliche Features, wie z.B. den Support von Fremdsprachen bietet.


### Anforderungen an die Suche

Die Überlegung die wir uns dazu gemacht haben waren folgende:
Es gibt 3 Arten von Benutzern:

1.) Der Benutzer weiß genau was er sucht. Er will etwas in die Suche eingeben, das richtige Ergebnis zurückbekommen und schnell auf die Daten zugreifen.

Beispiel:
Der Benutzer will eine Bewertung zu seiner Lieblingsserie abgeben und will möglichst schnell auf die entsprechende Seite geleitet werden. Er gibt den Titel der Serie in die Suchleiste ein und gelangt zur Serie.


2.) Der Benutzer hat wenig Informationen und möchte dass ihm dementsprechend Vorschläge gemacht werden, die am meisten seiner Informationen entsprechen.

Beispiel:
Der Benutzer hat 5 Minuten einer ihm unbekannten Serie/Episode geschaut und weiß deshalb nur die Namen von 1-2 Charakteren oder nur einen Teil der Hintergründe, aber nicht den Titel der Serie/Episode. Er tippt was er weiß ein und bekommt nach Relevanz sortierte Vorschläge.


3.) Der Benutzer hat keine Informationen und sucht nichts spezifisches. Er wird die Suchfunktion deshalb nicht benutzen und sich höchstens umschauen welche Serien es so gibt, bzw. welche Bewertungen diese haben.


Da der dritte Benutzertyp für die Suchfunktion keine Rolle spielt sind nur die Anforderungen der ersten beiden Benutzer wichtig.

Die Anforderungen an die Suchfunktion sind somit zusammengefasst:
Schnelligkeit, richtige Ergebnisse bei präzisen Anfragen und nach Relevanz sortierte Vorschläge bei unpräzisen Anfragen.


### Die Queries

Im wesentlichen besteht die Suche aus 2 SQL Anfragen:
Der Rechtschreibkorrektur und der Suche nach der Episode oder der Serie, wobei die Rechtschreibkorrektur vor der Suche nach den Serien/Episoden stattfindet.
Weshalb dies so umgesetzt wurde, wird im Kapitel "Idee und Umsetzung" erläutert.

Query zur Suche nach Episoden:

SELECT shows.name AS show, episodes.name AS episode, episodes.season, episodes.number, episodes.id, episodes.show_id')
FROM episodes JOIN shows ON shows.id = episodes.show_id
WHERE setweight(to_tsvector('english', coalesce(episodes.name,'')),'A') || setweight(to_tsvector('english', coalesce(episodes.description,'')),'B')) @@ to_tsquery(input)
ORDER BY ts_rank(to_tsvector(coalesce(episodes.name,''))||to_tsvector(coalesce(episodes.description,'')),to_tsquery(input)) DESC
LIMIT 10;

Wie man sieht wird der Name, die Season, die Episodennummer, sowie der Name und die ID der Serie zurückgegeben. Dafür werden die Tabellen episodes und shows gejoint.
Der interessante Teil ist der WHERE und ORDER BY Teill, denn dabei werden die Features von der _PostgreSQL_ Volltextsuche in Anspruch genommen:

to_tsvector([ config regconfig , ] document text)
Reduziert Text zu einem tsvector, der die Lexeme und deren Position innerhalb des Textes enthält. Ein Lexem ist die "Einheit des Wortschatzes, die die begriffliche Bedeutung trägt" [Duden]

to_tsquery([ config regconfig , ] query text)
Normalisiert Wörter und wird zum durchsuchen des ts_vector benutzt.

setweight(tsvector, "char")
Gibt den Lexemen des tsvectors Gewichtungen. "Char" ist dabei A,B,C oder D, mit A höchstes und D niedrigstes Gewicht.

ts_rank([ weights float4[], ] vector tsvector, query tsquery [, normalization integer ])
Gibt dem Query einen Rang.

@@ Operator: Überprüft, ob tsvector und tsquery übereinstimmen und liefert true oder false.

Beispiel:                                                   Ergebnis:
to_tsvector('english', 'The Fat Rats') 	                    => 'fat':2 'rat':3
to_tsquery('english', 'The & Fat & Rats')                   => 'fat' & 'rat'
setweight('fat:2,4 cat:3 rat:5B'::tsvector, 'A')            => 'cat':3A 'fat':2A,4A 'rat':5A
ts_rank(textsearch, query) 	                                => 0.818
to_tsvector('fat cats ate rats') @@ to_tsquery('cat & rat') => t

Die Episoden Namen und Beschreibungen werden zu tsvector umgewandelt, gewichtet und mit tsquery untersucht.
Anschließend werden die Ergebnisse nach Relevanz absteigend sortiert, sodass das Ergebnis mit dem höchsten Rang als erstes ausgegeben wird.
LIMIT 10 beschränkt die Ausgabe auf 10 Ergebnisse.

Query zur Rechtschreibkorrektur:

SELECT word
FROM unique_lexeme
WHERE word % input AND similarity(word, input) >= 0.5
ORDER BY similarity(word,input) DESC
LIMIT 1;

Für die Rechtschreibkorrektur haben wir eine Materialized View "unique_lexeme" angelegt, die alle Lexeme aus den Serien und Episoden Tabellen enthält.
Dafür haben wir die ts_stat Funktion von _PostgreSQL_ benutzt, welche Statistiken über jedes einzelne Lexem aus den tsvector Daten zurückgibt.

Zusätzlich haben wir die _PostgreSQL_ Extension pg_trgm (Trigram) verwendet: Diese stellt uns einige wichtige Funktionen und Operationen zur Verfügung um Wörter auf Ähnlichkeit zu untersuchen.
Dazu wird ein String in die sogenannten Trigramme zerlegt, diese sind die aufeinanderfolge von 3 Buchstaben aus dem String.
Die Trigramme von "Trigram" wären also beispielsweise: [Tri],[rig],[igr],[gra],[ram] wobei Leerzeichen als Unterstriche dargestellt werden.
Der %-Operator und die Similarity-Funktion, die wir in unserem Query benutzen.

Der %-Operator untersucht, ob die Ähnlichkeit von 2 Argumenten über einem bestimmten Wert liegt (Default: 0.3) und gibt, falls dem so ist true zurück.
Similarity gibt eine Zahl zurück, wie Ähnlich 2 Argumente sind, wobei 0 keine Ähnlichkeit entspricht und 1, dass sie identisch sind.

Wir benutzen beide, da wir zum einen, einen Index benutzen und dieser mit dem %-Operator effizienter genutzt wird und zum anderen benutzen wir  
Similarity als Post-Filter bei dem wir die Ergebnisse vom %-Operator nochmal filtern.


### Suchindezes

Um die Laufzeit der SQL Queries drastisch zu verringern, stellt _PostgreSQL_ sogenannte Indezes zur Verfügung. Diese sind sozusagen eine Verknüpfung oder eine Art Lesezeichen auf die bei der Indexerstellung definierte Spalte einer Tabelle.
Dabei gibt es 2 Arten von Indezes: Den GIN und GiST Index.

_"As a rule of thumb, GIN indexes are best for static data because lookups are faster. For dynamic data, GiST indexes are faster to update. Specifically, GiST indexes are very good for dynamic data and fast if the number of unique words (lexemes) is under 100,000, while GIN indexes will handle 100,000+ lexemes better but are slower to update."_

Da die Serien und Episoden Daten zum größten Teil statisch sind, eine niedrige Laufzeit der Queries für uns wichtig ist und die GiST Indezes auch falsche Ergebnisse liefern können, haben wir entschieden die GIN Indezes sowohl für die Suche nach Serien/Episoden, als auch für die Rechtschreibkorrektur zu verwenden.


### Idee und Umsetzung

In diesem Abschnitt behandeln wir unsere Idee für die Suche und deren Umsetzung.

Die Überlegung war es, dass wir im Frontend eine Library benutzen wollen, welche uns ermöglicht die Suchanfragen periodisch oder besser live, also während der Benutzer noch eintippt, zu senden.

Wir haben dafür die Library typeahead.js ausgesucht, die von Twitter entwickelt wurde und Open Source zur Verfügung steht.

Der Benutzer tippt also etwas ein, die Suchanfrage wird als GET Request gesendet und das eingegebene Wort wird mit den Lexemen aus der Materialized View "unique_lexeme" verglichen. Dabei wird das Lexem mit der größten Ähnlichkeit ausgewählt und dieses an die Suche nach der Serie/Episode als Parameter übergeben.
Anschließend werden die 10 relevantesten Ergebnisse zurückgegeben.

Auf diese Weise haben wir somit alle unsere Anforderungen an die Suche erfüllt, also Schnelligkeit, richtige Ergebnisse bei präzisen Anfragen und nach Relevanz sortierte Vorschläge bei unpräzisen Anfragen.


### Beispiel für eine Suche

Wir wollen "Mike" den Namen des Protagonisten aus der Serie "Suits" in die Suche eingeben und ebendiese Serie zurückbekommen.
Wir tippen also "m" ein, der GET Request wird abgeschickt, die Fehlerkorrektur bestimmt das Lexem das die höchste Bewertung für "m" hat z.B. "mia", übergibt es an die Suche und liefert die 10 relevantesten Ergebnisse.

Während die Suche durchgeführt wird tippen wir aber weiter, sodass wir "mik" in der Suchleiste stehen haben.
Der GET Request wird erneut abgeschickt, die Fehlerkorrektur bestimmt, dass das Lexem mit der höchsten Bewertung für "mik", "mike" ist und gibt es an die Suche weiter. Diese gibt uns wieder die 10 relevantesten Ergebnisse zurück. Wir stellen fest, dass eine andere Serie relevanter ist. Deshalb präzisieren wir unsere Suche und tippen ein "mike suit". GET Request wird abgeschickt, da zwischen mike und suit ein Leerzeichen ist, aber wir nur 1 Wort an die Fehlerkorrektur übergeben können wird der Input getrennt und ein Array erzeugt:

var inputSplit = input.split(' ');

Es wird der letzte Eintrag des Arrays ausgewählt und übergeben ihn an die Rechtschreibkorrektur, diese gibt für "suit", "suits" zurück und speichert es im Array.

"mike" und "suits" werden dann zusammengefügt und durch ein "oder" getrennt:

input = input.join('|');

Als Input wird nun "mike|suits" an die Suche übergeben und wir bekommen als relevantestes Ergebnis die Serie "Suits".
