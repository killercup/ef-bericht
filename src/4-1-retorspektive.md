## Rückblick

Nach Abschluss des Projekts gibt es einige Punkte, die wir im Nachhinein anders machen würden. Im Allgemeinen sind dies jedoch eher kleiner Punkte; keine der im Verlauf der Entwicklung aufgetretenen Probleme waren ein unüberwindbare Hindernisse.

Die in ["Technologie"](#sec:technologien) beschriebenen Entscheidungen haben sich bewährt. Sie haben es ermöglicht, alle gewollten Funktionen umzusetzen, sowie einige zusätzliche zu ermöglichen, z.B. den Kalender-Feed oder die Suche. Auf dieser Basis könnten auch viele Erweiterungen problemlos umgesetzt werden. Außerdem sind wir zuversichtlich, dass die Software in einer Produktivumgebung stabil und performant laufen wird.

### Technologie-Entscheidungen

Zwei Entscheidungen zu Modulen, die wir einsetzen wollten, haben wir revidiert.

Zu Beginn war geplant, die Benutzer-Authentifizierung auf Basis von _Passport_ [@passport] zu implementieren. Dieses Modul ist im Grunde jedoch nur eine Sammlung von Adaptern verschiedener Authentifizierungsmethoden, um Benutzer z.B. über deren vorhandene Facebook-, Twitter- und OpenID-Accounts zu registrieren. Das Modul für eine lokale Benutzerverwaltung, _passport-local_ ist ein recht einfacher Adapter, welcher jedoch verlangt, dass die Repräsentation des Benutzers in der Datenbank (Auslesen und Ändern) selbst geschrieben wird. Da dies das mit Abstand komplexeste Unterfangen der Benutzer-Authentifizierung ist und _passport-local_ sonst kaum Funktionen mitbringt, haben wir uns entschieden ganz darauf zu verzichten und den gesamten Workflow selbst zu implementieren. Hätten wir MongoDB verwendet, wäre es jedoch möglich gewesen, _passort-local-mongo_ zu verwenden, welches Session-Handling und das Benutzer-Schema für diese Datenbank implementiert.

Ein weiteres Modul, welches wir letztendlich nicht verwendet haben, ist _node-tvdb_ [@node-tvdb], eine Implementierung der TheTVDB-API. Dieses Modul ließ sich schnell durch die direkte Verwendung von _xml2js_ [@xml2js] und _superagent_ [@superagent] ersetzen. Dies hat den zusätzlichen Vorteil, dass auf die selbe Weise auch die Schnittstelle zur TVRage-API geschrieben werden konnte.

### Zu node.js und der Zukunft von JavaScript

Das ursprüngliche Vorhaben für das Projekt war, eine Applikation auf Basis von _node.js_ zu entwickeln. Abschließend sind wir zufrieden mit dieser Wahl. _Node_ ist zwar noch nicht als "1.0"-Version erschienen, da es aber von einigen großen Unternehmen bereits für wichtige Projekte verwendet wird, sind große Teile von _Node_ dennoch als stabil und gut getestet einzustufen. Es werden eine Reihe aktueller (wie auch älterer Versionen) regelmäßig mit Sicherheits-Aktualisierungen versehen und viele APIs der Kern-Module sind als stabil markiert.

Dass _node_ trotz seinem Fokus auf Asynchronität auf dem Ausführen von JavaScript basiert, bedeutet zur Zeit, dass viele Programmier-Techniken zur Abstraktion und Verbesserung der Ergonomie nur als Module verfügbar sind, die Sprache selbst diesen aber agnostisch gegenüber ist. Auch, wenn sich dies mit einer zukünftigen Version von _node_ ändern sollte (z.B. durch die Unterstützung neuer Funktionen aus dem "ECMAScript 2015"-Standard [@ecma6]), wird es noch viele Module geben, die diese Techniken nicht verwenden, sowie andere, welche ähnliche, aber inkompatible oder obsolete Implementierungen einsetzen.

Ein Beispiel hierfür ist die von uns verwendete Bibliothek _bluebird_ [@bluebird], um Promises abzubilden. Unsere Wahl fiel explizit auf diese Bibliothek, da sie verspricht, kompatibel zu den nativen Promises in ECMAScript 2015 zu sein. Dass andere von uns verwendeten Module wie _knex_ und _bookshelf_ ebenfalls _bluebird_ als Abhängigkeit haben, war ein ziemlich Glücksgriff. Aus anderen Projekten war bekannt, dass es sonst nötig gewesen wäre, an vielen Stellen Promise-Instanzen der einen in Promise-Instanzen der anderen Bibliothek zu konvertieren, was weder für Performance noch für Entwickler-Effizient gut ist.

Sobald _node_ in einer stabilen Version einen Großteil der Funktionen von ECMAScript 2015 (und nachfolgenden Revisionen) unterstützt, wird es möglich sein, einige andere Pattern zu verwenden, um Applikationen auf eine andere Weise zu implementieren. Konkret existiert beispielsweise mit _koa.js_ [@koa] schon eine Alternative zu _express.js_ [@expressjs], welche Middlewares auf Basis von Generatoren[^generatoren] implementiert.

[^generatoren]: Generatoren sind vergleichbar mit den z.B. aus Lua bekannten Coroutinen. Im Grunde sind es Funktionen, welche an gewissen Punkten pausiert werden und später fortgesetzt werden können.

Die Grenzen von JavaScript sind auch an anderen Stellen zu sehen. Gerade für größere Projekte kann es problematisch sein, Interfaces korrekt zu definieren und zuversichtlich verwenden zu können, da JavaScript als dynamische Sprache hier von sich aus kaum Sicherheiten bietet. Abhilfe schaffen hier Ansätze wie statische Code-Überprüfung (z.B. mit _ESLint_ [@eslint]) oder auf JavaScript aufsetzende Type Systeme wie _TypeScript_ [@typescript] oder _Flow_ [@flow].

Bei der Entwicklung EpisodeFever konnten wir mit den Nachteilen von _Node_ und JavaScript gut umgehen und die Vorteile – eine einfach zu lernende Sprache und ein großen Ökosystem von Modulen – erfolgreich ausnutzen. Für ähnliche Projekte, gerade für kleinere Webserver, würden wir es wieder verwenden.
