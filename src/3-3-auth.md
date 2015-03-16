## Benutzer-Authentifizierung

Schon im Planungsstadium des Projekts war vorgesehen, dass es eine Benutzer-Authentifizierung geben muss, da nur registrierte Benutzer die Möglichkeit haben sollen abzustimmen.

Dafür ist der Auth Service zuständig, der im wesentlichen die folgenden Module umfasst:

Register
Die Registrierung der Benutzer unter Angabe der E-Mail Adresse, des Passworts und des Benutzernamen. Die Validierung der Eingabe und bei Erfolg das Speichern der Daten in der Datenbank, wobei das Passwort verschlüsselt hinterlegt wird. Anschließend das versenden einer E-Mail mit einem Verifizierungslink, der den Benutzer verifiziert und die Registrierung abschließt.

Login
Das Anmelden mit dem der E-Mail Adresse. Wobei der Benutzer bei erfolgreicher Anmeldung einen Session Token bekommt.

Verify
Die Sessionverwaltung, die sicherstellt, dass der Benutzer einen validen Sessiontoken bekommt, vorausgesetzt der Benutzer ist verifiziert.

Im folgenden Schaubild sieht man wie die Kommunikation bei der Authentifizierung zwischen dem Client, dem Server und der Datenbank abläuft.

[BILD]

Nachfolgend ein detailierter Einblick in die einzelnen Module.


### Registrierung

Die Registrierung läuft folgendermaßen ab:

Der Benutzer gibt seine Benutzerdaten ein und gibt beim Absenden den POST Request an den Server. Die Daten werden aus dem Request extrahiert, normalisiert und validiert.

Für die Validierung würde die Open Source Library Checkit verwendet. Diese ermöglicht Javascript Objekte zu validieren, indem für die Daten Anforderungen definiert werden.
Diese sind z.B. bei uns, dass das Feld E-Mail auch das Format einer E-Mail Adresse hat, das Passwort aus mindestens 6 Zeichen besteht und alle Felder nicht leer sein dürfen.
Damit stellen wir sicher, dass keine Spam-Anmeldungen möglich sind.

Wenn die vorliegenden Daten den geforderten Standards entsprechen, wird überprüft, ob die Daten nicht bereits existieren.
Sollte das nicht der Fall sein, wird das Passwort an einen Helper übergeben, der mittels bcrypt, einen Salt generiert und das Passwort hasht. Zusätzlich wird ein Token für die Verifizierung erzeugt. Der generierte Hash, sowie der Token werden dann zusammen mit den eingegebenen Daten in der Datenbank hinterlegt und anschließend eine E-Mail mit einem Verifizierungslink versandt.

Die Benutzer ist verifiziert und die Registrierung abgeschlossen, wenn man auf den Link geht.


### Login

Ursprünglich wollten wir die Open Source Library Passport für die Anmeldung verwenden, doch im Laufe des Projekts haben wir festgestellt, dass es uns kaum Vorteile bringt, da wir den größten Teil der Funktionalitäten trotzdem selber schreiben mussten. Deshalb haben wir beschlossen auf die zusätzliche Abhängigkeit zu verzichten, die Library deshalb nicht zu verwenden und stattdessen eine eigene Lösung zu schreiben.

Die Anmeldung wurde von uns auf folgende Art gelöst:

Der Benutzer gibt seine Anmeldedaten ein und gibt beim Absenden den POST Request an den Server. Die versendeten Daten werden aus dem Request extrahiert.
Mit den extrahierten Daten wird zuerst überprüft, ob es in der Datenbank einen Benutzer gibt mit der angegebenen E-Mail und ob dieser Benutzer verifiziert ist. Sollte dies der Fall sein wird ein User Objekt erstellt, dass die Informationen über den Benutzer aus der Datenbank enthält.

Ein Helper überprüft, dann ob das vom Benutzer eingebene Passwort mit dem hinterlegten Passwort übereinstimmt. Da das in der Datenbank abgespeicherte Passwort gehasht vorliegt, benutzen wir die compare Methode von bcrypt, die uns erlaubt das eingebene Passwort mit dem gehashten Passwort abzugleichen. Stimmen diese überein wird ein Sessiontoken generiert und zurückgegeben.
Damit ist der Anmeldeprozess abgeschlossen.


### Verifizierung

Die Verifizierungsfunktionalität wurde bereits bei der Planung vorgesehen, da wir sicherstellen wollten, dass die bei der Registrierung eingegebenen E-Mail Adressen auch wirklich existieren und der Benutzer dies durch das klicken auf einen Verifizierungslink bestätigt.

Wir sahen diese Funktionalität deshalb als wichtig an, da wir die Erstellung von Spam-Accounts einschränken wollten.

Die Verifizierung läuft wie folgt ab:

Wie bereits vorher erläutert wurde beim registrieren ein Verifizierungstoken erstellt und in der Datenbank abgelegt.
Dieser Token wird dann mithilfe der JWT Library in ein sogenanntes JSON Webtoken konvertiert. Dieses ist ein verschlüsselter Token der aus einem JSON Objekt erzeugt wird, dass den zuvor generierten Token und die ID des Benutzers enthält. Der JWT wird dann an die vom Benutzer eingegebene E-Mail in Form eines Verifizierungslinks gesendet.

Zum versenden der E-Mail haben wir die Nodemailer Library benutzt, weil diese sehr leicht zu implementieren war und viele Funktionalitäten bot.

Beim Aufruf des Verifizierungslinks dekodieren wir zuerst den JWT, extrahieren daraus die Benutzer ID und den Verifizierungstoken und überprüfen ob die Daten in valider Form vorliegen.
Dann überprüfen wir, ob der Benutzer bereits verifiziert ist und ob der extrahierte Token mit dem Token in der Datenbank übereinstimmen. Falls der Benutzer nicht bereits verifiziert und der Token korrekt ist, wird der Benutzer verifiziert und die Verifizierung ist abgeschlossen.
