# Überblick über die verwendeten Technologien {#sec:technologien}

Falls nichte explizit erwähnt, ist jede im weiteren Verlauf erwähnte Software unter einer OpenSource-Lizenz verfügbar (vgl. [@osslicenses]).

Als Software-Plattform wurde _node.js_ ("node", [@nodejs]) gewählt[^node-alternativen], welches JavaScript-Applikationen ausführt und Zugriff auf System-Schnittstellen bietet. Da es auf Basis eines Event-Loop arbeitet, geschieht jeglicher Zugriff auf System-Ressourcen wie Dateisystem oder Netzwerk asynchron. Es sind sehr viele[^npm-size] mit _node.js_ kompatible Bibliotheken über _npm_ [@npm] verfügbar, welche leicht in eigene Software integriert werden können.

[^node-alternativen]: Da es ein explizites Ziel des Projektes war, eine Plattform auf Basis von _node.js_ zu entwickeln, wurden Alternativen nicht weiter betrachtet. Da _node.js_ im Grunde eine Bibliothek und Laufzeit-Umgebung für JavaScript ist, sind mögliche Alternativen andere Programmiersprachen wie PHP, Ruby oder Python, welche ähnlich Schnittstellen bieten, aber auch Java, C# oder C++ mit entsprechenden Bibliotheken.

[^npm-size]: Am 7. Februar 2015 01:32 Uhr (MEZ) waren laut _npmjs.org_ [@npm] 123.800 Pakete verfügbar.

Zum Speichern und Abfrage von Daten wurde _PostgreSQL_ ("Postgres", [@postgres])ausgewählt, ein stabiles und performantes relationales Datenbanksystem. Die Alternative _MongoDB_ [@mongodb], ein Dokument-basiertes ("NoSQL") Datenbanksystem, wurde ebenfalls betrachtet. Da die zu speichernden Daten in einem fest vorgegeben Schema vorliegen und untereinander verknüpft sind (es aber nicht sinnvoll ist, die verknüpften Daten einzubetten), erschienen mögliche Vorteile eines NoSQL-Ansatzes für nicht relevant[^see-schema-chapter]. Neuere Versionen von PostgreSQL unterstützen außerdem NoSQL-ähnliche Funktionen wie das Speichern und Abfragen von JSON-Strukturen (seit Version 9.3) sowie das Erzeugen von Volltext-Such-Indizes (seit Version 8.3). Diese Funktionen sind auch Gründe, warum nicht ein anderes SQL-Datenbanksystem wie MariaDB [@mariadb] verwendet wurde.

[^see-schema-chapter]: Weitere Informationen zum verwendeten Datenbank-Schema werden [weiter unten](#sec:db-schema) beschrieben.

## Node.js-spezifische Module

_express.js_ in Version 4 [@expressjs] wird zur Abstraktion der über HTTP bereitgestellten Ressourcen verwendet. Mit Hilfe von _Middlewares_ lassen sich HTTP-Anfragen in mehreren Stufen verarbeiten und Antworten senden. Mit express wird auch der HTTP-Server selbst gestartet. Alternativen zu _express.js_ sind _restify_ [@restify], _Hapi_ [@hapi] oder _koa_ [@koa], welche ebenfalls auf _node.js_ aufsetzen. Ansonsten hätte man auch _Ruby on Rails_ (Ruby, [@rails]), _Django_ (Python, [@django]), _Laravel_ (PHP, [@laravel]) oder _Martini_ (Go, [@martini]) wählen können.

Um Zugriffe auf die Datenbank zu vereinfachen und ausgelesene Daten direkt verarbeiten zu können, wird _bookshelf.js_ [@bookshelf] eingesetzt. Dieses erlaubt es, Datenbank-Inhalt wie JavaScript-Objekte zu verwenden und Relationen im Code abzubilden. Intern wird _knex.js_ [@knex] verwendet, um SQL-Abfragen zu generieren und Schema-Migrationen durchzuführen. Alternative hierzu ist vor allem _mongoose_ [@mongoose], wäre statt PostgreSQL MongoDB gewählt worden.

## Module bezüglich Code-Struktur

Ebenso wie die in _node.js_ integrierten Module, verwenden auch viele externe Bibliotheken _Callbacks_, um Rückgabewerte asynchroner Schnittstellen zu übertragen. Dies führt bei vielen voneinander abhängigen Aufrufen zu Software, deren Programmfluss auf Grund von ineinander verschachtelten Funktionsaufrufen schwer nachzuvollziehen muss. Ebenso ist das Behandeln aller Fehlerfälle in solchen Programmen oft komplex. Viele dieser Probleme werden durch den Einsatz von Promises [@promisesaplus] gelöst. Die Standard-konforme Implementierung _bluebird_ [@bluebird] wird in EpisodeFever verwendet, da sie sehr performant ist [@promiseperformance] und viele Hilfsfunktionen mitliefert (um beispielsweise in _node_ integrierte Module mit Promises zu verwenden).

Das Schreiben und Ausführen von automatisierten Tests wird durch _mocha_ ermöglicht, einem kleinen Test-Framework, welches mit dem von Ruby bekannten _rspec_ [@rspec] vergleichbar ist. Die Bibliothek _chai.js_ [@chai] bietet eine Vielzahl von Hilfs-Funktionen, mit welchen Werte von Objekten überprüft werden können.

Um Anfragen an den zu testenden Teil des Servers zu simulieren, wurde _supertest_ [@supertest] eingesetzt. _Supertest_ basiert auf _superagent_ [@superagent], welches schon für den Zugriff auf externe APIs verwendet wird, wie in ["XML-Daten abfragen und verarbeiten"](#sec:import-requests) beschrieben. _Supertest_ bietet einfache Möglichkeiten zur Überprüfung von HTTP-Antworten. Es wurde um die Verwendung von _Promises_ erweitert, sodass asynchrone Tests einfach zu schreiben sind. (Ist der Rückgabe-Wert eines Tests ein Promise, wird dieses von _mocha_ automatisch ausgewertet.)
