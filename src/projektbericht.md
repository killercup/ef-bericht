---
title: "Projektgruppe Web-Technologie: EpisodeFever"
author:
- Pascal Hertleif
- Andreas Diesendorf
date: "1\\. März 2015"
lang: german
locale: de
documentclass: article
papersize: a4paper
---

# Ziele

Ziel des Projekts "EpisodeFever" ist es, eine Plattform zur Bewertung von Fernseh-Serien zu erstellen.

Daten über Serien und Episoden sollen von externen Diensten abgefragt bzw. zu aktualisiert werden. Es soll möglich sein, Benutzer-Konten zu erstellen und zu verwalten, und als ein Benutzer Zugriff auf bestimmte Daten zu haben und Bewertungen zu Episoden abzugeben.

Die Plattform soll zunächst nur eine JSON-Schnittstelle bieten, über welche die genannten Daten abgefragt und verändert werden können. Diese soll den Prinzipien von REST folgen [@fielding2000rest] und es ermöglichen, dass verschiedene Anwendungen darauf zugreifen.

Des Weiteren soll das Projekt dazu dienen, das Team mit den verwendeten Technologien vertraut zu machen und eine effiziente Architektur für _node.js_-basierte Server-Anwendungen zu finden. Dies beinhaltet auch das Schreiben von automatisierten Tests für die implementierte Software. Durch das Programmieren wiederverwendbarer Module soll außerdem die Entwicklung zukünftiger Systeme vereinfacht werden.

# Überblick über die verwendeten Technologien

Jede im weiteren Verlauf erwähnte Software ist unter eine OpenSource-Lizenz verfügbar (vgl. [@osslicenses]).

Als Software-Plattform wurde _node.js_ [@nodejs] gewählt[^node-alternativen], welches JavaScript-Applikationen ausführt und Zugriff auf System-Schnittstellen bietet. Da es auf Basis eines Event-Loop arbeitet, geschieht jeglicher Zugriff auf System-Ressourcen wie Dateisystem oder Netzwerk asynchron. Es sind sehr viele mit _node.js_ geschriebene Bibliotheken über _npm_ [@npm] verfügbar, welche leicht in eigene Software integriert werden können.

[^node-alternativen]: Da es ein explizites Ziel des Projektes war, eine Plattform auf Basis von _node.js_ zu entwickeln, wurden Alternativen nicht weiter betrachtet. Da _node.js_ im Grunde eine Bibliothek und Laufzeit-Umgebung für JavaScript ist, sind mögliche Alternativen andere Programmiersprachen wie PHP, Ruby oder Python, welche ähnlich Schnittstellen bieten, aber auch Java, C# oder C++ mit entsprechenden Bibliotheken.

Zur Speicherung und Abfrage von Daten wurde _PostgreSQL_ [@postgres] ausgewählt, ein stabiles und performantes relationales Datenbanksystem. Die Alternative _MongoDB_, eine NoSQL-Datenbank wurde ebenfalls betrachtet. Da jedoch die zu speichernden Daten in einem sehr fest vorgegeben Schema vorliegen und ihr voraussichtliches Ausmaß nicht besonders groß ist, erschienen mögliche Vorteile von NoSQL für nicht relevant. Neuere Versionen von PostgreSQL unterstützen außerdem äquivalente Funktionen wie das Speichern und Abfragen von JSON-Strukturen sowie das Erzeugen von Volltext-Such-Indizes.

## Node.js-spezifische Module

_express.js_ [@expressjs] wird zur Abstraktion der über HTTP bereitgestellten Ressourcen verwendet. Mit Hilfe von _Middlewares_ lassen sich HTTP-Anfragen in mehreren Stufen verarbeiten und Antworten senden. Mit express wird auch der HTTP-Server selbst gestartet. Alternativen zu _express.js_ sind _restify_ [@restify], _Hapi_ [@hapi] oder _koa_ [@koa], welche ebenfalls auf _node.js_ aufsetzen. Ansonsten hätte man auch _Ruby on Rails_ (Ruby, [@rails]), _Django_ (Python, [@django]), _Laravel_ (PHP, [@laravel]) oder _Martini_ (Go, [@martini]) wählen können.

Um Zugriffe auf die Datenbank zu vereinfachen und ausgelesene Daten direkt verarbeiten zu können, wird _bookshelf.js_ eingesetzt. Dieses erlaubt es, Datenbank-Inhalt wie JavaScript-Objekte zu verwenden und Relationen im Code abzubilden. Intern wird _knex.js_ verwendet, um SQL-Abfragen zu generieren und Schema-Migrationen durchzuführen. Alternative hierzu wäre vor allem _mongoose_, wäre statt PostgreSQL auf MongoDB gesetzt worden.

## Module bezüglich Code-Struktur

Ebenso wie die in _node.js_ integrierten Module, verwenden auch viele externe Bibliotheken _Callbacks_, um Rückgabewerte asynchroner Schnittstellen zu übertragen. Dies führt bei vielen voneinander abhängigen Aufrufen zu Programmen, deren Programmfluss auf Grund von ineinander verschachtelten Funktionsaufrufen schwer nachzuvollziehen muss. Ebenso ist das Behandeln aller Fehlerfälle in solchen Programmen oft komplex. Viele dieser Probleme werden durch den Einsatz von Promises [@promisesaplus] gelöst. Die Standard-konforme Implementierung _bluebird_ [@bluebird] wird in EpisodeFever verwendet, da sie sehr performant ist [@promiseperformance] und viele Hilfsfunktionen mitliefert (um beispielsweise in _node_ integrierte Module mit Promises zu verwenden).

Das Schreiben und Ausführen von automatisierten Tests wird durch _mocha_ ermöglicht, einem kleinen Test-Framework, welches mit dem von Ruby bekannten _rspec_ [@rpec] vergleichbar ist. Die Bibliothek _chai.js_ [@chai] bietet eine Vielzahl von Hilfs-Funktionen, mit welchen Werte von Objekten überprüft werden können. Um Anfragen an den zu testenden Teil des Servers zu simulieren, wurde _supertest_ [@supertest] eingesetzt[^supertest-promises].

[^supertest-promises]: _supertest_ wurde um die Verwendung von _Promises_ erweitert, sodass asynchrone Tests einfach zu schreiben sind. Ist der Rückgabe-Wert eines Tests ein Promise, wird dieses von _mocha_ automatisch ausgewertet.

# Vorgehen bei der Projekt-Umsetzung

## API-Design: Welche Endpunkte sollen am Ende existieren?

## Projekt-Struktur aufsetzen: Verzeichnis-Struktur, Aufteilung nach Services

## Auth
### Registrierung
### Login
### Benutz-Daten ändern

## Datenabfrage: Endpunkte Serien und Episoden

## Import von Daten aus TheTVDB und TVRage.com

## Bewertungen abgeben
### Zuletzt bewertete Serien abfragen

## Suche

# Anhang

## Bibliographie
