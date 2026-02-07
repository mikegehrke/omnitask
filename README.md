# OmniTask Platform

OmniTask ist eine autonome digitale Assistenten-Plattform, die Aufgaben durch KI-Agenten plant und ausführt.

## Projektstruktur

- `backend/`: FastAPI App, PostgreSQL Models, Redis Worker, AI Agents.
- `frontend/`: Flutter App (iOS, Android, Web).
- `docker-compose.yml`: Orchestrierung aller Dienste.

## Voraussetzungen

- Docker & Docker Compose
- Flutter SDK (für Frontend Entwicklung)

## Installation & Start

1. **Backend & Infrastruktur starten**
   ```bash
   # Im Hauptverzeichnis
   docker-compose up --build
   ```
   Dienste sind dann verfügbar unter:
   - API: http://localhost:8000
   - Redis: localhost:6379
   - DB: localhost:5432

2. **Frontend starten**
   ```bash
   cd frontend
   flutter user
   # Wähle Device (z.B. Chrome oder Simulator)
   ```
   *Hinweis: Wenn du im Android Simulator testest, musst du `localhost` in `lib/providers/task_provider.dart` durch `10.0.2.2` ersetzen.*

## Features (MVP Scope)

- **Task Erstellung**: User sendet Anfrage.
- **Triage & Planung**: KI analysiert und plant Schritte (Mock).
- **Execution**: Simuierte Ausführung der Schritte.
- **Chat UI**: Echtzeit-ähnliche Übersicht der Aufgaben.

## Lizenz
Private
