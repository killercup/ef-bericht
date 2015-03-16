## Testen von REST-Anfragen {#sec:tests-rest}

Um sicherzustellen, dass die für einen Service vorgesehenen Funktionen korrekt implemtiert wurden und um zu vermeiden, dass in Zukunft Änderungen gemacht werden, welche die erwarteten Funktionsweisen brechen, werden zu jedem Service automatisierte Tests geschrieben. Dazu werden die [oben beschriebenen](#sec:tests-tech) Module _mocha_, _chai_ und _supertest_ verwendet.

Durch _supertest_ ist es möglich, einen auf _Express.js_ basierten Server in einem Test-Kontext zu starten, ohne ihn auf einem bestimmten Port zu starten. An diesen Server werden dann Anfragen gestellt, und die Antworten auf erwartet Werte und Strukturen überprüft. Ein einfacher Test sieht so aus:

```javascript
var request = require('supertest');
var app = require('express')();
app.use('/', require('./index'));

// `describe` beginnt Test-Suite
describe("API index", function () {
  var agent = request.agent(app);

  // `it` beschreibt einen konkreten Test-Fall
  it("returns a JSON response", function () {
    return agent.get('/')
    .expect(200) // Test auf HTTP-Status (Supertest)
    .set('Accept', 'application/json')
    .expect('Content-Type', /json/)
    .exec() // Konvertiere Anfrage-Objekt zu Promise
    .then(function (response) {
      // Teste Antwort auf korrekt Struktur
      expect(response.body).to.be.an('object');
    });
  });
});
```

### Test-Daten

Eine Herausforderung beim Schreiben von Tests ist es, dynamisch Test-Daten in die Datenbank einfügen zu können. Um beispielsweise testen zu können, ob ein Entpunkt die Liste aller Episoden ausgibt, welche nach einem bestimmten Datum ausgestrahlt werden, müssen zunächst Episoden-Daten mit verschiedenen Ausstrahlungsdaten eingefügt werden.

Um dies zu vereinfachen, wurde jedem _bookshelf_-Model eine statische `fake`-Methode hinzugefügt. Diese generiert standardmäßig einen Datensatz mit zufällen Daten (mit Hilfe von _faker.js_ [@fakerjs]), es können jedoch einzelne Felder beliebig überschrieben werden.

Da `fake()` ein Promise mit dem zu speichernden Datensatz zurückliefert, kann das Erstellen von Test-Daten direkt innerhalb eines Tests ausgeführt werden. Sollen die Daten in allen Tests einer Test-Suite verliegen, können sie auch in einem `before`-Block eingefügt werden (auf der selben Ebene wie die mit `it` registrierten konkreten Tests). In solchen `before`-Blöcken werden zu Beginn einer Tests-Suite oft auch die schon in der Datenbank vorhandenen Einträge gelöscht, um konsistent testen zu können.

Im folgenden Beispiel wird eine Serie eingefügt und anschließend ein Test für `/shows` ausgeführt:

```javascript
var request = require('supertest');
var Show = require('./model');
var app = require('express')();
app.use('/', require('./index'));
var F = require('../../helpers/faking_helpers');

describe("Shows API", function () {
  var agent = request.agent(app);

  before(function () {
    return F.dropAllTheData()
    .then(function () {
      return Show.fake();
    })
  });

  it("returns a list of shows", function () {
    return agent.get('/')
    .expect(200)
    .exec()
    .then(function (res) {
      expect(res.body).to.be.an('object');
      expect(res.body.shows).to.be.an('array');
      expect(res.body.shows).to.have.length(1);
    });
  });
});
```

