## Suche

Eine Suchfunktionalität ein wichtiger Bestandteil jeder Anwendung, die große Mengen an Daten für die Benutzer zur Verfügung stellt. Sie soll zum einen die Suche nach Information erleichtern und beschleunigen.

Die wesentlichen Features, die diese bieten sollte sind unter anderem:

- Wörter auf ihren Wortstamm reduzieren
- Stopwörter entfernen (ein, das, im, mit, etc.)
- Gewichtung von Suchergebnissen
- Rechtschreibkorrektur

Aufgrund der von _PostgreSQL_ zur Verfügung gestellten Funktionen für die Volltextsuche hat sich unsere Entscheidung, eben dieses Datenbanksystem zu benutzen, als richtig erwiesen, da es all die oben genannten Features, aber auch andere nützliche Funktionen, wie z.B. den Support von Fremdsprachen bietet.

Ein alternatives Systeme für eine dedizierte Volltextsuche ist _ElasticSearch_ [@elasticsearch]. Dies ist ein auf Apache Lucence [@lucence] basierendes NoSQL-System, welches darauf ausgelegt ist, große Mengen an Textdaten zu indexieren und effizient durchsuchbar zu machen.

### Anforderungen an die Suche

Die Überlegung die wir uns dazu gemacht haben waren folgende:
Es gibt 3 Arten von Benutzern:

1. Der Benutzer weiß genau was er sucht. Er will etwas in die Suche eingeben, das richtige Ergebnis zurückbekommen und schnell auf die Daten zugreifen.

    *Beispiel:*
    Der Benutzer will eine Bewertung zu seiner Lieblingsserie abgeben und will möglichst schnell auf die entsprechende Seite geleitet werden. Er gibt den Titel der Serie in die Suchleiste ein und gelangt zur Serie.


2. Der Benutzer hat wenig Informationen und möchte, dass ihm dementsprechend Vorschläge gemacht werden, die am ehesten seiner Informationen entsprechen.

    *Beispiel:*
    Der Benutzer hat 5 Minuten einer ihm unbekannten Serie/Episode geschaut und weiß deshalb nur die Namen von 1-2 Charakteren oder nur einen Teil der Hintergründe, aber nicht den Titel der Serie/Episode. Er tippt was er weiß ein und bekommt nach Relevanz sortierte Vorschläge.


3. Der Benutzer hat keine Informationen und sucht nichts spezifisches. Er wird die Suchfunktion deshalb nicht benutzen und sich höchstens umschauen, welche Serien es gibt, bzw. welche Bewertungen diese haben.


Da der dritte Benutzertyp für die Suchfunktion keine Rolle spielt sind nur die Anforderungen der ersten beiden Benutzer wichtig.

Die Anforderungen an die Suchfunktion sind somit zusammengefasst:
Schnelligkeit, richtige Ergebnisse bei präzisen Anfragen und nach Relevanz sortierte Vorschläge bei unpräzisen Anfragen.


### Die Queries

Im wesentlichen besteht die Suche aus 2 SQL Anfragen, der Rechtschreibkorrektur und der Suche nach der Episode oder der Serie, wobei die Rechtschreibkorrektur vor der Suche nach den Serien/Episoden stattfindet. Weshalb dies so umgesetzt wurde, wird im Kapitel ["Idee und Umsetzung"](#sec:search-ideas) erläutert.

### Suche nach Episoden

```sql
SELECT
  shows.name AS show,
  episodes.name AS episode,
  episodes.season, episodes.number, episodes.id, episodes.show_id
FROM episodes JOIN shows ON shows.id = episodes.show_id
WHERE
    to_tsvector('english_nostop', coalesce(episodes.name, '')) ||
    to_tsvector('english', coalesce(episodes.description, '')) @@
    to_tsquery(input)
ORDER BY
    ts_rank((
      setweight(to_tsvector('english_nostop',coalesce(episodes.name,'')),'A') ||
      setweight(to_tsvector('english',coalesce(episodes.description,'')),'B')),
      to_tsquery('english_nostop', input)) DESC
```

Wie man sieht wird der Name, die Season, die Episodennummer, sowie der Name und die ID der Serie zurückgegeben. Dafür werden die Tabellen `episodes` und `shows` gejoint.
Der interessante Teil ist der `WHERE` und `ORDER BY`-Teil, denn dabei werden die Features der _PostgreSQL_-Volltextsuche in Anspruch genommen:

`to_tsvector([ config regconfig , ] document text)` reduziert Text zu einem `tsvector`, der die Lexeme und deren Position innerhalb des Textes enthält. Ein Lexem ist die "Einheit des Wortschatzes, die die begriffliche Bedeutung trägt" [@Duden].

`to_tsquery([ config regconfig , ] query text)` normalisiert Wörter und wird zum durchsuchen des ts_vector benutzt.

`setweight(tsvector, "char")` Gibt den Lexemen des tsvectors Gewichtungen. "Char" ist dabei A,B,C oder D, mit A höchstes und D niedrigstes Gewicht.

`ts_rank([ weights float4[], ] vector tsvector, query tsquery [, normalization integer ])` gibt dem Query einen Rang.

Der `@@` Operator überprüft, ob `tsvector` und `tsquery` übereinstimmen und liefert `true` oder `false`.

Beispiel                                                          Ergebnis
----------------------------------------------------------------  ----------------------
`to_tsvector('english', 'The Fat Rats')`                          `'fat':2 'rat':3`
`to_tsquery('english', 'The & Fat & Rats')`                       `'fat' & 'rat'`
`setweight('fat:2,4 cat:3 rat:5B'::tsvector, 'A')`                `'cat':3A 'fat':2A,4A 'rat':5A`
`ts_rank(textsearch, query)`                                      `0.818`
`to_tsvector('fat cats ate rats') @@ to_tsquery('cat & rat')`     `t`

> – [PostgreSQL Dokumentation zu _Text Search Functions_](http://www.postgresql.org/docs/8.3/static/functions-textsearch.html)

Die Episoden-Namen und -Beschreibungen werden zu `tsvector` umgewandelt, gewichtet und mit `tsquery` untersucht.
Was besonders ins Auge fällt, ist dass für die Beschreibungen die Sprache 'english' und für die Titel 'english_nostop' verwendet wurde.
Die Sprache 'english_nostop' wurde von uns angelegt und der Unterschied zu 'english' besteht darin, dass Stop Wörter nicht entfernt werden. Dies ist besonders wichtig, da Titel durchaus Stop Wörter enthalten können.

*Beispiel:*
Wenn man die Serie "Doctor Who" sucht und in die Suche "who" eingibt würde, die Suche die Serie nicht finden, weil "who" ein Stop Wort ist.

Die Ergebnisse der Suche werden abschließend nach Relevanz absteigend sortiert, sodass das Ergebnis mit dem höchsten Rang als erstes ausgegeben wird.

#### Query zur Rechtschreibkorrektur

```sql
SELECT word
FROM unique_lexeme
WHERE word % input AND similarity(word, input) >= 0.5
ORDER BY similarity(word,input) DESC
LIMIT 1;
```

Für die Rechtschreibkorrektur haben wir eine Materialized View `unique_lexeme` angelegt, die alle Lexeme aus den Serien und Episoden Tabellen enthält.
Dafür haben wir die `ts_stat` Funktion von _PostgreSQL_ benutzt, welche Statistiken über jedes einzelne Lexem aus den `tsvector`-Daten zurückgibt.

Zusätzlich haben wir die _PostgreSQL_ Extension `pg_trgm` (Trigram) verwendet: Diese stellt uns einige wichtige Funktionen und Operationen zur Verfügung um Wörter auf Ähnlichkeit zu untersuchen.
Dazu wird ein String in die sogenannten Trigramme zerlegt, diese sind die aufeinanderfolge von 3 Buchstaben aus dem String.
Die Trigramme von "Trigram" wären also beispielsweise `[Tri],[rig],[igr],[gra],[ram]`, wobei Leerzeichen als Unterstriche dargestellt werden.

#### Der `%`-Operator und die `similarity`-Funktion

Der `%`-Operator untersucht, ob die Ähnlichkeit von 2 Argumenten über einem bestimmten Wert liegt (Default: `0.3`) und gibt, falls dem so ist true zurück.
Similarity gibt eine Zahl zurück, wie Ähnlich 2 Argumente sind, wobei `0` keine Ähnlichkeit entspricht und `1`, dass sie identisch sind.

Wir benutzen beide, da wir zum einen, einen Index benutzen und dieser mit dem `%`-Operator effizienter genutzt wird und zum anderen benutzen wir  
Similarity als Post-Filter bei dem wir die Ergebnisse vom `%`-Operator nochmal filtern.


### Such-Indizes

Um die Laufzeit der SQL-Abfragen drastisch zu verringern, stellt _PostgreSQL_ sogenannte Indizes zur Verfügung. Diese sind sozusagen eine Verknüpfung oder eine Art Lesezeichen, auf die bei der Indexerstellung definierte Spalte einer Tabelle.

Dabei gibt es 2 Arten von Indizes: Den GIN und GiST Index.

> "As a rule of thumb, GIN indexes are best for static data because lookups are faster. For dynamic data, GiST indexes are faster to update. Specifically, GiST indexes are very good for dynamic data and fast if the number of unique words (lexemes) is under 100,000, while GIN indexes will handle 100,000+ lexemes better but are slower to update."
>
> – [PostgreSQL Dokumentation zu _Full Text Search_](http://www.postgresql.org/docs/9.4/static/textsearch-indexes.html)

Da die Serien- und Episoden-Daten zum größten Teil statisch sind, eine niedrige Laufzeit der Queries für uns wichtig ist und die GiST Indizes auch falsche Ergebnisse liefern können, haben wir entschieden, die GIN-Indizes sowohl für die Suche nach Serien/Episoden, als auch für die Rechtschreibkorrektur zu verwenden.


### Idee und Umsetzung {#sec:search-ideas}

In diesem Abschnitt behandeln wir unsere Idee für die Suche und deren Umsetzung.

Die Überlegung war es, dass wir im Frontend eine Library benutzen wollen, welche uns ermöglicht die Suchanfragen periodisch oder besser live, also während der Benutzer noch eintippt, zu senden.

Wir haben uns mehrere Librarys angeschaut, unter anderem _typeahead.js_ [@typeahead] und _rx.js_ [@rxjs],
haben uns aber letztendlich für _kefir.js_ [@kefir] entschieden, da dieses sehr kompakt und besonders performant ist.

Im wesentlichen sieht das Skript für das Autocompletion-Feature wie folgt aus:

```js
var inputField = this.refs.queryInput.getDOMNode();

var queries = Kefir.fromEvent(inputField, 'keyup')
.debounce(250)
.map(ev => ev.target.value)
.filter(val => val.length > 0)
.skipDuplicates()
.map(data => {
  this.transitionTo('search', null, {query: data});
  var searchQuery = {query: data, limit: this.props.limit}

  return [
  { type: 'SEARCH_SHOWS_QUERY', data: searchQuery },
  { type: 'SEARCH_EPISODES_QUERY', data: searchQuery }
  ];
  })
  .flatten();

  Bus.plug(queries);
```

Tippt der Benutzer tippt etwas ein, wird die Suchanfrage als `GET`-Request gesendet und das eingegebene Wort wird mit den Lexemen aus der Materialized View `unique_lexeme` verglichen. Dabei wird das Lexem mit der größten Ähnlichkeit ausgewählt und dieses an die Suche nach der Serie/Episode als Parameter übergeben.
Anschließend werden die Ergebnisse nach Relevanz sortiert zurückgegeben.

Auf diese Weise haben wir somit alle unsere Anforderungen an die Suche erfüllt: Schnelligkeit, richtige Ergebnisse bei präzisen Anfragen und nach Relevanz sortierte Vorschläge bei unpräzisen Anfragen.


### Beispiel für eine Suche

Wir wollen "Mike", den Namen des Protagonisten aus der Serie "Suits" in die Suche eingeben und ebendiese Serie zurückbekommen.

Wir tippen also "m" ein, der `GET`-Request wird abgeschickt, die Fehlerkorrektur bestimmt das Lexem das die höchste Bewertung für "m" hat z.B. "mia", übergibt es an die Suche und liefert alle relevanten Ergebnisse.

Während die Suche durchgeführt wird, tippen wir aber weiter, sodass wir "mik" in der Suchleiste stehen haben.

Der `GET`-Request wird erneut abgeschickt, die Fehlerkorrektur bestimmt, dass das Lexem mit der höchsten Bewertung für "mik", "mike" ist und gibt es an die Suche weiter. Diese gibt uns wieder alle relevanten Ergebnisse zurück. In diesem Beispiel gehen wir davon aus, dass eine andere Serie relevanter ist. Deshalb präzisieren wir unsere Suche und tippen ein "mike suit".
`GET`-Request wird abgeschickt, da "mike" und "suit" 2 Wörter sind die durch ein Leerzeichen getrennt sind, aber wir nur 1 Wort an die Fehlerkorrektur übergeben können, wird der Input getrennt und ein Array erzeugt. Zuvor wird die Eingabe jedoch bei jeder Suchanfrage normalisiert.
Dafür werden unter anderem Leer- und Sonderzeichen durch '+' ersetzt, sodass immer eine gültige Suchanfrage vorliegt.

```js
function normalize(word){
  var word = word.toLowerCase()
  .replace("%20","+")
  .replace(/([+])+/g,"+")
  .match(/([A-Za-z0-9+])+/g);

  if ((word === undefined)||(word ==='')||(word === null)){
    throw new E.BadRequestError("Please enter a valid search query!");
  }
  else return word.join("+");
}
```

Dann wird die normalisierte Eingabe getrennt und ein Array erzeugt. Das Array wird dann an die Rechtschreibkorrektur übergeben, diese gibt für "suit", "suits" zurück.

"mike" und "suits" werden dann zusammengefügt und durch das Zeichen für ein logisches Und getrennt:

```js
Promise.all(
  input.split('+').map(function (word) { return spellcheck(word); })
  )
  .then(function (words) {
    var query;
    input = words
    .filter(function (word) { return word && word[0]; })
    .map(function (word) { return word[0].word; })
    .join('&');
```

Als Input wird nun `"mike&suits"` an die Suche übergeben und wir bekommen als relevantestes Ergebnis die Serie "Suits".
