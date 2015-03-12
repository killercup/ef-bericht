## Bewertungen abgeben

Kern-Funktion von EpisodeFever ist das Bewerten von Episoden. Ein Bewertungs-Datensatz beinhaltet zu der Bewertung-Zahl selbst[^rating] Referenzen zu einem Benutzer, einer Serie und einer Episode. Jeder Benutzer kann genau eine Bewertung zu einer Episode abgeben, diese kann jedoch bearbeitet werden.

[^rating]: Aktuell sind die Bewertungen "Gut", "Mittel" und "Schlecht" (als Zahlen 3 bis 1 gepeichert) möglich. Diese Skala kann in Zukunft jedoch einfach geändert werden.

Aus diesen Informationen lassen sich viele weitere Daten berechnen, beispielsweise die Durchschnittsbewertungen für Episoden, Staffeln, Serien oder Benutzer. Außerdem lassen sich darüber die Serien bestimmen, die ein Benutzer schaut, ohne dass diese explizit angegeben werden müssen[^watches].

[^watches]: Es wurde überlegt, die Relation zwischen Benutzer und Serien, die dieser schaut, explizit zu speichern. Die Vorteile hiervon werden im Kapitel ["Ausbaustufen"](#sec:watches) beschrieben.

### Motivation: Auflisten von zukünftig relevanten Episoden

Als Benutzer möchte ich es möglichst einfach haben, die Episoden zu finden, die ich bewerten möchte. Meist sind das genau die Episoden, die auf die zuvor von mir bewerteten folgen.

Daher ist eine sehr wichtige Funktion für ein Interface zu EpisodeFever das Auflisten der von einem Benutzer zuvor bewerteten Episoden sowie der darauf folgenden. Wurde zu einer Serie die 14. Episode der dritten Staffel bewerten, sollen z.b. die Episoden 14 bis 19 angezeigt werden. (Es ist zusätzlich zu beachten, dass nur Episoden bewerten werden können, die bereits ausgestrahlt wurden.)

### Zuletzt bewertete Serien abfragen

Um an die zuvor beschriebenen Daten zu gelagen, wird zunächst eine Liste mit den zuletzt abgegebenen Bewertungen benötigt, gruppiert nach Serie. Eine passende SQL-Abfrage lässt sich wie folgt formulieren:

```sql
SELECT *
FROM (
  SELECT
    ROW_NUMBER() OVER (
      PARTITION BY
        show_id
      ORDER BY
        updated_at DESC NULLS LAST,
        id DESC NULLS LAST
    ) AS row_number,
    t.*
  FROM
    votes AS t
  WHERE
    user_id = ?
) AS latest_votes
WHERE "latest_votes"."row_number" <= ?
LIMIT ?
```

Die Parameter für diese Abfrage (im Code als `?` gekennzeichnet) sind die Benutzer-ID und die Anzahl der abzufragenden Bewertungen.

Hat man durch diese Abfrage nun eine Liste mit Bewertungen, lassen sich über die darin referenzierten Episoden- und Serien-IDs einfach die weiteren Episoden abfragen, indem man Episoden nach der Serien filtert, nach Staffel und Nummer sortiert und dann nur die ausgibt, welche auf die zuletzt bewertete folgen.
