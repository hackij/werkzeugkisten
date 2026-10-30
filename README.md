# Werkzeugkisten Spengler · BS1 Bayreuth

Kontrolle der Werkzeugkisten für MKP11 und MKP12 mit Live-Tauschbörse.

## Einrichten (einmalig, ca. 15 Minuten)

### 1. Supabase (kostenlos)
1. Auf https://supabase.com mit GitHub anmelden → **New project**.
2. Name z. B. `werkzeugkisten`, Region **Central EU (Frankfurt)**, Datenbank-Passwort vergeben (wird später nicht gebraucht).
3. Links **SQL Editor** → **New query** → Inhalt von `supabase-setup.sql` einfügen.
   **Vorher ganz unten die PIN `1234` durch eine eigene ersetzen.** → **Run**.
4. Links **Project Settings → API**: die **Project URL** und den **anon public** Key kopieren.

### 2. App konfigurieren
In `index.html` oben im Block `CONFIG` eintragen:
- `SUPABASE_URL` und `SUPABASE_ANON_KEY` (aus Schritt 1.4)
- `ANZAHL_KISTEN` (steht auf 22)
- `BASIS_URL` = Adresse der veröffentlichten Seite, z. B. `https://hackij.github.io/werkzeugkisten/`

Der anon-Key darf öffentlich sein. Er erlaubt nur, was in den Zugriffsregeln steht: lesen und melden, kein Löschen, keine PIN.

### 3. GitHub Pages
Neues Repository `werkzeugkisten` anlegen, alle Dateien hochladen, unter **Settings → Pages** den Branch `main` wählen.

### 4. Fotos
Fotos liegen im Ordner `bilder/` als WebP, benannt nach der Nummer in der Werkzeugliste: `01.webp` (Idealschere links) bis `16.webp` (Falzklotz).
Fehlt ein Foto, zeigt die App ein Piktogramm.

### 5. QR-Bögen
Seite aufrufen → **Kistenlisten mit QR-Code** → **Alle Bögen drucken** → laminieren.

## Ansichten
- `#start` alle Kisten und Tauschbörse
- `#kiste-7` Kontrolle für Kiste 7 (Ziel der QR-Codes)
- `#lehrer` Bestand aller Kisten und Chronik (PIN)
- `#druck` Bögen zum Laminieren

## Hinweis
Supabase pausiert kostenlose Projekte nach 7 Tagen ohne Zugriff. Mit einem Klick auf **Restore** im Supabase-Dashboard läuft es wieder. Bei wöchentlicher Nutzung passiert das in der Regel nicht, in den Ferien schon.
