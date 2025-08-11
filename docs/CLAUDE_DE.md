# CLAUDE.md - Deutsche Version

Diese Datei bietet Orientierung für Claude Code (claude.ai/code) bei der Arbeit mit Code in diesem Repository.

## Projektübersicht

BemedaPersonal ist eine Phoenix LiveView-Anwendung für Job-Matching zwischen Arbeitgebern und Arbeitssuchenden. Entwickelt mit Elixir/Phoenix, umfasst es:

### Bestehende Funktionen
- Benutzerauthentifizierung mit rollenbasiertem Routing (Arbeitssuchende vs. Arbeitgeber)
- Job-Posting und Bewerbungsmanagement
- Lebenslauf-Erstellung und -Verwaltung
- Firmenprofil und -Management
- Digitale Signatur-Workflows (SignWell-Integration)
- Echtzeit-Messaging zwischen Arbeitgebern und Arbeitssuchenden
- Dokumentenverarbeitung und -speicherung (Tigris)
- Mehrsprachige Unterstützung (Englisch, Deutsch, Französisch, Italienisch)
- Bewertungssystem für Jobs und Bewerbungen

### <span style="background-color: #e3f2fd;">Neue Funktionen - Pool Worker System</span>

#### <span style="background-color: #e8f5e8;">Pool Worker Management</span>
- **Pool Worker Registrierung**: Spezielle Benutzerrolle für temporäre/flexible Arbeitskräfte
- **Verfügbarkeitskalender**: Integriertes Kalendersystem für Pool Worker
- **Einsatz-Benachrichtigungen**: Push-Benachrichtigungen für verfügbare Einsätze
- **Automatisches Matching**: KI-basiertes Matching zwischen Verfügbarkeiten und Anforderungen

#### <span style="background-color: #e8f5e8;">Erweiterte Job-Matching-Features</span>
- **Angebots-Vergleichstool**: Dashboard für Arbeitssuchende zum Vergleichen von Stellenangeboten
- **Bewertungsbasiertes Ranking**: Höher bewertete Pool Worker werden bei bekannten Unternehmen bevorzugt
- **Skill-basiertes Matching**: Automatische Zuordnung basierend auf Fähigkeiten und Erfahrungen
- **Einsatzhistorie**: Tracking von vergangenen Einsätzen und Performance-Metriken

#### <span style="background-color: #e8f5e8;">Personalisierte Rekrutierungsdienste</span>
- **Headhunting-Service**: Personalisierte Rekrutierungsdienstleistungen von Bemeda Personal
- **Social Media Marketing**: Gezielte Kampagnen zur Ansprache passiver Kandidaten
- **Talent Pool Management**: Verwaltung von Kandidaten-Pools für spezifische Branchen
- **Executive Search**: Spezialisierte Suche für Führungspositionen

## Entwicklungskommandos

### Setup
```bash
mix setup                    # Vollständiges Projekt-Setup (deps, database, assets)
mix ecto.setup              # Nur Datenbank-Setup
mix ecto.reset              # Datenbank löschen und neu erstellen
```

### Entwicklungsserver
```bash
mix phx.server              # Phoenix Server starten (http://localhost:4000)
```

### Datenbank
```bash
mix ecto.create             # Datenbank erstellen
mix ecto.migrate            # Migrationen ausführen
mix ecto.rollback           # Migrationen zurückrollen
```

### Testen
```bash
mix test                    # Tests ausführen
mix coveralls               # Tests mit Abdeckung
mix coveralls.html          # HTML-Abdeckungsbericht generieren
```

### Code-Qualität
```bash
make check_code             # Alle Qualitätsprüfungen (empfohlen vor Commits)
mix check_code              # Alternativer Befehl
mix credo --strict          # Linting
mix dialyzer                # Statische Analyse
mix sobelow                 # Sicherheitsanalyse
mix format                  # Code formatieren
npx prettier -w .           # Frontend-Assets formatieren
```

## Architektur

### Context Module
- `BemedaPersonal.Accounts` - Benutzerverwaltung und Authentifizierung
- `BemedaPersonal.Companies` - Firmenverwaltung
- `BemedaPersonal.JobPostings` - Job-Posting CRUD und Filterung
- `BemedaPersonal.JobApplications` - Bewerbungslebenszyklus mit State Machine
- `BemedaPersonal.Resumes` - Lebenslauf-Erstellung
- `BemedaPersonal.DigitalSignatures` - Anbieter-agnostische Signatur-Workflows
- `BemedaPersonal.Chat` - Messaging zwischen Benutzern
- `BemedaPersonal.Ratings` - Bewertungssystem
- `BemedaPersonal.Documents` - Dateiverarbeitung und -speicherung
- `BemedaPersonal.Media` - Medien-Asset-Management

### <span style="background-color: #e3f2fd;">Neue Context Module</span>
- <span style="background-color: #e8f5e8;">`BemedaPersonal.PoolWorkers` - Pool Worker Verwaltung und Matching</span>
- <span style="background-color: #e8f5e8;">`BemedaPersonal.Availability` - Verfügbarkeitsmanagement und Kalender</span>
- <span style="background-color: #e8f5e8;">`BemedaPersonal.Notifications` - Erweiterte Benachrichtigungssystem</span>
- <span style="background-color: #e8f5e8;">`BemedaPersonal.Comparisons` - Angebots-Vergleichsfunktionalität</span>
- <span style="background-color: #e8f5e8;">`BemedaPersonal.HeadhuntingServices` - Personalisierte Rekrutierung</span>
- <span style="background-color: #e8f5e8;">`BemedaPersonal.SocialMediaIntegration` - Social Media Marketing Tools</span>

## <span style="background-color: #e3f2fd;">Erweiterte User Stories</span>

### <span style="background-color: #e8f5e8;">Pool Worker Funktionalitäten</span>

#### **Als Pool Worker möchte ich:**
1. **Verfügbarkeitskalender verwalten**
   - Meine verfügbaren Zeiten im Kalender eintragen
   - Wiederkehrende Verfügbarkeiten definieren
   - Kurzfristige Änderungen vornehmen
   - Urlaubszeiten blockieren

2. **Einsatz-Benachrichtigungen erhalten**
   - Push-Benachrichtigungen für passende Einsätze
   - SMS/Email-Benachrichtigungen bei dringenden Anfragen
   - Filterbare Benachrichtigungen nach Branche/Standort
   - Eskalations-Benachrichtigungen bei nicht reagierten Anfragen

3. **Automatisches Matching nutzen**
   - Automatische Vorschläge basierend auf Skills und Verfügbarkeit
   - Prioritäre Behandlung bei Stammunternehmen
   - Bewertungsbasierte Rangfolge bei Einsätzen
   - Smart Matching basierend auf vergangener Performance

### <span style="background-color: #e8f5e8;">Arbeitssuchenden-Funktionalitäten</span>

#### **Als Arbeitssuchender möchte ich:**
1. **Stellenangebote vergleichen**
   - Side-by-side Vergleich von Stellenangeboten
   - Gewichtete Kriterien (Gehalt, Benefits, Standort)
   - Bewertungsmatrix mit Punktesystem
   - Export-Funktion für Vergleichstabellen
   - Historische Gehaltsvergleiche

2. **Passive Kandidatensuche profitieren**
   - Von Headhunting-Services kontaktiert werden
   - Personalisierte Stellenangebote erhalten
   - Diskreten Jobwechsel-Service nutzen
   - Premium-Profil für erhöhte Sichtbarkeit

### <span style="background-color: #e8f5e8;">Unternehmens-Funktionalitäten</span>

#### **Als Unternehmen möchte ich:**
1. **Pool Worker Management**
   - Stammpool von bewährten Pool Workern aufbauen
   - Automatische Matching-Algorithmen nutzen
   - Performance-Tracking von Pool Workern
   - Langfristige Verfügbarkeitsplanung

2. **Erweiterte Rekrutierungsdienstleistungen**
   - Headhunting-Services von Bemeda Personal buchen
   - Social Media Kampagnen für passive Kandidatensuche
   - Executive Search für Führungspositionen
   - Employer Branding Services

## <span style="background-color: #e3f2fd;">Neue Geschäftswert-Szenarien</span>

### <span style="background-color: #e8f5e8;">1. Personalisierte Headhunting-Services</span>
**Geschäftsmodell:** Premium-Service von Bemeda Personal
- **Zielgruppe:** Unternehmen mit schwer zu besetzenden Positionen
- **Service:** Maßgeschneiderte Rekrutierungskampagnen
- **Mehrwert:** Zugang zu passiven Kandidaten, höhere Erfolgsquote
- **Umsatzpotential:** Provisionsbasis oder Pauschalgebühren

### <span style="background-color: #e8f5e8;">2. Social Media Marketing für Rekrutierung</span>
**Geschäftsmodell:** Vermarktungsservice für Stellenanzeigen
- **Plattformen:** LinkedIn, XING, Facebook, Instagram
- **Targeting:** Geo-lokalisiert, skill-basiert, verhaltensbezogen
- **Mehrwert:** Erreichen passiver Kandidaten, erhöhte Bewerberzahl
- **Metriken:** Click-through-Rate, Conversion-Rate, Cost-per-Application

### <span style="background-color: #e8f5e8;">3. KI-basierte Matching-Optimierung</span>
**Technologie:** Machine Learning Algorithmen
- **Datenquellen:** Bewerbungshistorie, Erfolgsquoten, Bewertungen
- **Vorhersagen:** Wahrscheinlichkeit einer erfolgreichen Bewerbung
- **Optimierung:** Kontinuierliche Verbesserung durch Feedback-Loops
- **Mehrwert:** Höhere Match-Qualität, reduzierte Time-to-Hire

### <span style="background-color: #e8f5e8;">4. Premium-Mitgliedschaften</span>
**Monetarisierungsstrategie:** Gestaffelte Abonnements
- **Basic:** Grundfunktionen kostenlos
- **Professional:** Erweiterte Matching-Features, Vergleichstools
- **Enterprise:** Headhunting-Services, API-Zugang, Analytics
- **Executive:** Persönlicher Berater, diskreter Service

### <span style="background-color: #e8f5e8;">5. Marktplatz für Rekrutierungsdienstleistungen</span>
**Plattform-Erweiterung:** Ecosystem für HR-Services
- **Services:** Bewerbungstraining, CV-Optimierung, Interview-Coaching
- **Anbieter:** Externe HR-Berater, Coaches, Trainer
- **Bemeda-Rolle:** Plattform-Betreiber, Qualitätssicherung
- **Umsatzmodell:** Provision auf vermittelte Services

## <span style="background-color: #e3f2fd;">Technische Implementierung neuer Features</span>

### <span style="background-color: #e8f5e8;">Datenbank-Erweiterungen</span>
```sql
-- Pool Worker spezifische Tabellen
CREATE TABLE pool_workers (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  specializations TEXT[],
  hourly_rate DECIMAL,
  minimum_notice_hours INTEGER,
  preferred_work_types TEXT[]
);

-- Verfügbarkeitsmanagement
CREATE TABLE availabilities (
  id UUID PRIMARY KEY,
  pool_worker_id UUID REFERENCES pool_workers(id),
  start_datetime TIMESTAMP,
  end_datetime TIMESTAMP,
  recurring_pattern JSONB,
  is_blocked BOOLEAN DEFAULT FALSE
);

-- Angebots-Vergleiche
CREATE TABLE job_comparisons (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  job_postings JSONB,
  comparison_criteria JSONB,
  created_at TIMESTAMP
);
```

### <span style="background-color: #e8f5e8;">LiveView-Erweiterungen</span>
- `PoolWorkerDashboardLive` - Zentrales Dashboard für Pool Worker
- `AvailabilityCalendarLive` - Interaktiver Kalender
- `JobComparisonLive` - Vergleichstool für Stellenangebote
- `NotificationCenterLive` - Benachrichtigungszentrale
- `HeadhuntingServiceLive` - Interface für Premium-Services

### <span style="background-color: #e8f5e8;">Background Jobs</span>
```elixir
# Automatisches Matching
defmodule BemedaPersonal.Workers.PoolWorkerMatcher do
  use Oban.Worker
  
  def perform(%{"job_posting_id" => job_id}) do
    # Matching-Logik für Pool Worker
  end
end

# Social Media Kampagnen
defmodule BemedaPersonal.Workers.SocialMediaCampaigner do
  use Oban.Worker
  
  def perform(%{"campaign_id" => campaign_id}) do
    # Social Media Posting Logic
  end
end
```

### <span style="background-color: #e8f5e8;">API-Erweiterungen</span>
```elixir
# REST API für mobile Apps
defmodule BemedaPersonalWeb.API.PoolWorkerController do
  def availability_update(conn, params) do
    # Verfügbarkeit via API aktualisieren
  end
  
  def notification_preferences(conn, params) do
    # Push-Benachrichtigungen konfigurieren
  end
end
```

## Abhängigkeiten

### <span style="background-color: #e8f5e8;">Neue externe Services</span>
- **Firebase Cloud Messaging** - Push-Benachrichtigungen
- **Google Calendar API** - Kalender-Integration
- **LinkedIn API** - Social Media Integration
- **Stripe/PayPal** - Payment Processing für Premium-Services
- **Twilio** - SMS-Benachrichtigungen
- **SendGrid** - Email-Marketing-Kampagnen

### <span style="background-color: #e8f5e8;">Zusätzliche Elixir-Pakete</span>
```elixir
# mix.exs
defp deps do
  [
    # Bestehende Abhängigkeiten...
    {:quantum, "~> 3.0"},           # Cron-Jobs für wiederkehrende Tasks
    {:timex, "~> 3.7"},             # Erweiterte Datums-/Zeitfunktionen
    {:ex_fcm, "~> 1.0"},           # Firebase Cloud Messaging
    {:sweet_xml, "~> 0.7"},        # XML-Parsing für API-Integrationen
    {:machine_learning_toolkit, "~> 0.1"}, # ML für Matching-Algorithmen
    {:calendar, "~> 1.0"}           # Kalender-Funktionalitäten
  ]
end
```

## <span style="background-color: #e3f2fd;">Qualitätssicherung und Testing</span>

### <span style="background-color: #e8f5e8;">Erweiterte Teststrategie</span>
```elixir
# Pool Worker Tests
defmodule BemedaPersonal.PoolWorkersTest do
  use BemedaPersonal.DataCase
  
  test "automatic matching finds suitable pool workers" do
    # Matching-Algorithmus testen
  end
  
  test "availability calendar prevents double bookings" do
    # Kalender-Logik testen
  end
end

# Performance Tests
defmodule BemedaPersonal.PerformanceTest do
  use BemedaPersonal.DataCase
  
  test "matching algorithm performs within 500ms" do
    # Performance-Anforderungen validieren
  end
end
```

### <span style="background-color: #e8f5e8;">Monitoring und Analytics</span>
- **AppSignal** - Erweiterte Performance-Überwachung
- **Custom Metrics** - Matching-Erfolgsraten, User-Engagement
- **A/B Testing** - Feature-Optimierung
- **User Behavior Tracking** - Anonymisierte Nutzungsstatistiken

Diese erweiterte deutsche Dokumentation stellt eine umfassende Roadmap für die Evolution der BemedaPersonal-Plattform dar, mit Fokus auf Pool Worker Management, erweiterte Matching-Algorithmen und Premium-Rekrutierungsdienstleistungen.