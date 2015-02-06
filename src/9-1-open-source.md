## Beiträge zu Open Source {#sec:opensource}

Im Rahmen des Projektes wurden einige Beiträge zu Open-Source-Software gemacht bzw. neue Software-Module unter einer Open-Source-Lizenz veröffentlicht.

- [`sortStringToSql`](https://github.com/killercup/sortStringToSql)

    Ein von Pascal Hertleif geschriebenes Node-Module, welches eine Funktion bereitstellt um URL-kompatible Anweisungen für Sortierung in SQL zu konvertieren. So wird z.B. `"-date,id"` zu `"date DESC NULLS LAST, id ASC NULLS LAST"` konvertiert.

- [`replay`](https://github.com/assaf/node-replay/pull/50) [@replay]

    Pascal Hertleif reichte hierzu einen Patch ein, um Query-Strings beim Aufnehmen von HTTP-Anfragen zu speichern (und somit auch URLs anhand der Query-Strings unterscheiden zu können). Dieser Patch ist als Teil von Version 0.11 verfügbar.
