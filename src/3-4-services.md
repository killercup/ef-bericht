## Datenabfrage: Endpunkte für Serien und Episoden

Einer der ersten Schritte im Projekt-Verlauf war das Implementieren der der JSON-Endpunkte zur Abfrage von Serien und Episoden. Es soll für beide Entitäten eine Liste mit Einträgen sowie einzelne Einträge abgefragt werden können.

Dazu wurden zunächst die zwei _Services_ "shows" und "episodes" erstellt. Wie [oben](#sec:struktur) beschrieben, sind dies Verzeichnisse, welche den möglichst isolierten Code für einen Bereich der Anwendung beinhalten. Für beide _Services_ wurde eine `model.js` erstellt, welche Informationen zur Datenbank-Repräsentation der Daten beschreibt, sowie eine `index.js`, welche die möglichen HTTP-Anfragen beschreibt und einen _express Router_ exportiert.

Der initiale Inhalt einer solchen `index.js` sieht so aus:

```js
var express = require('express');
var app = express.Router();
module.exports = app;
```

### Abfragen vieler Einträge

Unter dem relativen Pfad `/` soll eine Liste von Einträgen abgefragt werden können. Standardmäßig sind dies alle Einträge, später wird die Anzahl limitiert und Seiten-weises Abfragen eingeführt. Diese Liste kann je nach Entität mit bestimmten Filtern versehen werden, welche als Teil der URL in Form von Query-Parametern übertragen werden. Für Serien gibt es beispielsweise `show_ids` (eine Komma-getrennte Liste von natürlichen Zahlen), wodurch nur Einträge zurückgegeben werden, deren ID angegeben wurde.

Eine triviale Variante eines solchen Endpunkts könnte so programmiert werden (anschließend an den oben gezeigten Code der `index.js`):

```js
app.get('/', function (request, response) {
  Show.query()
  .then(function (shows) {
    response.send(shows);
  })
  .catch(function (error) {
    response.status(500).send({error: error});
  });
});
```

### Fehlerfälle abstrakt behandeln {#sec:wrap-route}

Im vorigen Code-Beispiel wird ein möglicher Fehlerfall bei der Abfrage von Serien dadurch behandelt, dass eine Antwort mit HTTP-Status `500` und der JSON-Darstellung des erhaltenen Fehlers gesendet wird. Dieser Fall ist sehr allgemein, muss aber standardmäßig in jedem Endpunkt behandelt werden.

Um doppelten Code zu vermeiden, wurde die Funktion `wrapRoute` geschrieben (vgl. `server/helpers/wrap_route.js`). Diese wird statt einem direkten Callback beim Erstellen des Endpunkts verwendet und erwartet als einzigen Parameter eine Funktion, die ein Promise zurückgibt. Je nach Wert des aufgelösten Promises wird die entsprechende Antwort zurückgesendet.

Der benötigte Code für den trivialen Endpunkt von oben reduziert sich damit drastisch:

```js
var wrapRoute = require('../../helpers/wrap_route');

app.get('/', wrapRoute(function (request) {
  return Show.query();
}));
```

### HTTP-Antworten bei Fehlerfällen {#sec:http-errors}

Es sollte nicht auf jeden Fehler mit HTTP-Status `500` geantwortet werden, da dieser für `Internal Server Error` steht und daher nur sehr allgemein ist [@vinay2013pragmatic; @fielding2000rest].

Häufige Fehlerfälle, die zusätzlich beachtet werden sollen, und ihre korrekten Status-Codes, sind:

- `401`: Keine Zugriffsberechtigung.
- `404`: Angefragte Ressource konnte nicht gefunden werden.
- `409`: Daten-Konflikt (beim Erstellen eines neuen Eintrags).
- `422`: Daten konnten nicht verarbeitet werden (z.B. weil eine Validierung gescheitert ist).
