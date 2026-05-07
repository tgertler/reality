ARCHITECTURE
Ziel der Architektur
Dieses Projekt folgt Clean Architecture auf Feature‑Basis.
Ziele:

saubere Trennung von UI, Business‑Logik und Infrastruktur
bessere Wartbarkeit und Testbarkeit
kontrollierbarer Einsatz von Copilot
parallele Weiterentwicklung ohne Seiteneffekte

Grundprinzip:
Änderungen an UI oder Supabase dürfen die Business‑Logik nicht beeinflussen.

Architekturüberblick
Die Abhängigkeiten verlaufen immer einseitig:
presentation → domain ← data

presentation: Darstellung und UI‑State
domain: fachliche Logik und Regeln
data: technische Umsetzung (Supabase, APIs)


Feature‑Struktur (verbindlich)
Jedes Feature ist vollständig in sich gekapselt, z. B. feed:
features/feed

data

repositories
sources


domain

entities
repositories
use_cases


presentation

pages
provider
widgets



Jede Datei muss eindeutig einer dieser Schichten zuordenbar sein.

presentation
Verantwortung

UI (Widgets, Pages)
Screens
State‑Management (z. B. Provider / Riverpod)
Navigation und User‑Interaktionen

Erlaubt

Verwendung von Use Cases aus der Domain
Nutzung von Domain‑Entities
UI‑State und Orchestrierung von Abläufen

Verboten

direkter Zugriff auf Supabase oder andere Datenquellen
technische Infrastruktur (API, SDKs, SQL)
Business‑Logik oder fachliche Entscheidungen

Strukturregeln

pages: vollständige Screens (z. B. mit Scaffold)
widgets: wiederverwendbare UI‑Bausteine
provider: UI‑State und Steuerung der Use Cases

Die Präsentationsschicht ist bewusst „dumm“ und trifft keine fachlichen Entscheidungen.

domain
Verantwortung
Die Domain ist das fachliche Herz des Features.
Sie enthält:

Business‑Logik
fachliche Regeln
Anwendungsfälle (Use Cases)

Struktur

entities: fachliche Modelle
repositories: Interfaces / Contracts
use_cases: konkrete fachliche Handlungen

Harte Regeln

keine Abhängigkeit zu Flutter
keine Abhängigkeit zu Supabase
keine JSON‑Modelle oder DTOs
nur reine Dart‑Logik

Business‑Logik ist jede Entscheidung, die beantwortet:
„Darf etwas fachlich passieren?“
Solche Entscheidungen gehören ausschließlich in die Domain.

data
Verantwortung
Die Data‑Schicht setzt die technischen Details um und verbindet die Domain mit der Außenwelt.
sources

Supabase
APIs
Persistenz
alles, was IO oder externe Systeme betrifft

Hier ist Infrastruktur erlaubt, überall sonst verboten.
repositories

Implementieren die Domain‑Repository‑Interfaces
kapseln die Nutzung der Sources
übernehmen Mapping zwischen technischen Modellen und Domain‑Entities

Die Data‑Schicht enthält keine UI‑ oder Business‑Logik.

Abhängigkeitsregeln
Die Abhängigkeiten sind fest definiert:

presentation darf domain nutzen
data darf domain nutzen
domain darf nichts importieren

Diese Regeln werden technisch überprüft (z. B. durch Lints).

Widget‑Regeln
Ein Widget gilt als zu groß, wenn:

es deutlich über ca. 200 Zeilen liegt
es mehr als eine Verantwortung hat
es Layout, State und Logik mischt

Rollenverständnis:

Pages orchestrieren
Widgets stellen dar
Provider steuern
Domain entscheidet fachlich


Umgang mit bestehendem Code
Das Projekt wird inkrementell saniert.
Regeln:

bestehender Code darf vorübergehend unsauber sein
neuer Code muss die Architektur einhalten
bestehender Code wird nur angepasst, wenn er berührt wird

Leitlinie:
Code soll nach jeder Änderung sauberer sein als zuvor.

Copilot‑Regeln
Copilot‑generierter Code muss dieser Architektur folgen.
Bei neuen Implementierungen ist explizit darauf zu achten:

saubere Trennung von presentation, domain und data
kein Datenzugriff außerhalb von data/sources
keine Business‑Logik in der presentation

Die Architektur hat Vorrang vor Geschwindigkeit.

Entscheidungs‑Checkliste vor Commit

Enthält presentation fachliche Entscheidungen?
Greift presentation direkt auf data oder sources zu?
Ist ein Widget zu groß oder zu komplex?
Gehört diese Entscheidung eigentlich in einen Use Case?

Wenn eine Frage mit Ja beantwortet wird, ist Refactoring notwendig.

Zielzustand

klare Schichtentrennung
schlanke, wiederverwendbare Widgets
testbare Business‑Logik
austauschbare Infrastruktur
Copilot erzeugt konsistenten, wartbaren Code