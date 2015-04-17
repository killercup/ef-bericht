## Informations-Architektur

EpisodeFever soll sowohl _Serien-_ als auch _Episoden_-Daten umfassen. Zusätzlich soll es _Benutzer_ geben, welche _Bewertungen_ anlegen können. Diese vier Entitäten sollen über die API verfügbar sein.

Serien und Episoden können nur gelesen werden; Aktualisierung dieser Daten findet über das [Import-Modul](#sec:import) statt. Benutzer können erstellt und (eingeschränkt) bearbeitet werden. Zudem können Benutzer pro Episode eine Bewertung abgeben.

### Datenbank-Schema {#sec:db-schema}

Aus den Ansprüchen an die API lässt sich ableiten, welche Daten zur Verfügung stehen müssen. Daraus lässt sich wiederum ein Datenbank-Schema entwerfen. Dieses sollte normalisiert und erweiterbar sein [@kleinschmidt2005relationale, S. 75-81].

Wie [oben](#sec:technologien) erwähnt, wurde als Alternative zu einer SQL-Datenbank auch die NoSQL-Datenbank MongoDB in Betracht gezogen. Diese eignet sich besonders, wenn zu bestimmten Datensätzen immer zusätzliche Relationen ausgelesen werden. Würden beispielsweise zu Serien immer alle Episoden geladen werden, könnte man in MongoDB die Episoden in das Serien-Dokument einbetten.

In EpisodeFever ist dies aber nicht gegeben. Episoden sollten keine eingebetteten Dokumente sein, da es möglich sein soll, die in den nächsten Tagen ausgestrahlten Episoden leicht zu bestimmen. Ebenso können Bewertungen nicht problemlos in andere Dokument eingebettet werden (z.B. als Teil der bewerteten Episode oder des bewertenden Benutzers), da man sie im Kontext eines Benutzers, einer Episode oder einer Serie abfragen können soll. Aus diesen Gründen erschien eine SQL-Datenbank die bessere Wahl zu sein.

Das Diagramm ["EpisodeFevers Datenbankschema"](#fig:database-schema) stellt das verwendete Schema als gerichteten Graphen dar. Verbindung zwischen Feldern symbolisieren Relationen zwischen Tabellen (mit Foreign Keys). Die Episoden-Tabelle beinhaltet z.B. eine Referenz auf einen Eintrag der Serien-Tabelle.

Zu den vier abgebildeten Tabellen existiert auch noch eine `knex_migrations`-Tabelle. Diese wird von _knex_ [@knex] automatisch angelegt und gefüllt, um festzuhalten, welche Schema-Migrationen in dieser Datenbank bereits durchgeführt wurden.

<section id="fig:database-schema">
![EpisodeFevers Datenbankschema\label{fig:database-schema}](illustrations/database-schema)

</section>
