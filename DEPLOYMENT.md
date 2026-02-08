# 🚀 Deployment Guide - OmniTask

## Übersicht

Das Projekt besteht aus **2 getrennten Services**:
- **Frontend**: Flutter Web App (statische Dateien)
- **Backend**: FastAPI + PostgreSQL + Redis (Docker)

Diese müssen **separat** deployed werden!

---

## 📱 Frontend Deployment (Vercel)

### Option 1: Vercel CLI (Empfohlen)

```bash
# Vercel CLI installieren
npm i -g vercel

# Im Projektverzeichnis deployen
cd /Users/mikegehrke/.gemini/antigravity/scratch/omnitask
vercel

# Bei Fragen:
# - Set up and deploy? → Yes
# - Which scope? → Dein Account
# - Link to existing project? → No
# - Project name? → omnitask
# - Directory? → ./ (Root)
# - Override settings? → No
```

### Option 2: Vercel Dashboard

1. Gehe zu [vercel.com](https://vercel.com)
2. "Add New Project" → "Import Git Repository"
3. Verbinde GitHub Repository: `mikegehrke/omnitask`
4. **Wichtig**: Root Directory auf `./` lassen (nicht frontend/)
5. Build Command: `cd frontend && flutter build web --release`
6. Output Directory: `frontend/build/web`
7. Deploy!

### ⚠️ Nach dem Deployment: API-URL anpassen

Wenn dein Backend deployed ist (siehe unten), musst du die API-URL ändern:

```dart
// frontend/lib/config/constants.dart
static const String baseUrl = 'https://deine-backend-url.com';
```

Dann neu deployen: `vercel --prod`

---

## 🐍 Backend Deployment

Das Backend läuft mit Docker und braucht PostgreSQL + Redis.
**Vercel kann das NICHT hosten!**

### Empfohlene Plattformen:

#### 1️⃣ **Railway** (Einfachste Option)

```bash
# Railway CLI installieren
npm i -g @railway/cli

# Login
railway login

# Projekt erstellen
railway init

# PostgreSQL hinzufügen
railway add postgresql

# Redis hinzufügen
railway add redis

# Backend deployen
railway up

# Domain notieren für Frontend!
```

**Automatisch konfiguriert**: PostgreSQL, Redis, HTTPS, Domain

#### 2️⃣ **Render** (Kostenlos)

1. [render.com](https://render.com) → New → Web Service
2. Repository: `mikegehrke/omnitask`
3. Root Directory: `backend`
4. Environment: Docker
5. Füge Services hinzu:
   - PostgreSQL Database
   - Redis
6. Environment Variables setzen:
   ```
   DATABASE_URL=<from-render>
   REDIS_URL=<from-render>
   SECRET_KEY=<generate-random>
   ```

#### 3️⃣ **DigitalOcean App Platform**

1. App erstellen → GitHub Repository
2. Dockerfile detected → Backend deployen
3. Dev Database (PostgreSQL) hinzufügen
4. Managed Redis hinzufügen

---

## 🔧 Environment Variables (Backend)

Diese müssen beim Backend-Deployment gesetzt werden:

```bash
# Datenbank
DATABASE_URL=postgresql://user:pass@host:5432/omnitask

# Redis
REDIS_URL=redis://host:6379

# Security
SECRET_KEY=<mindestens-32-zeichen-random-string>
ALGORITHM=HS256

# OpenAI (für KI-Features)
OPENAI_API_KEY=<dein-openai-key>

# Optional: Ollama
OLLAMA_API_URL=http://localhost:11434
```

---

## ✅ Deployment-Checklist

### Frontend (Vercel):
- [ ] `vercel.json` vorhanden
- [ ] Build läuft erfolgreich
- [ ] Domain notiert (z.B. `omnitask-xyz.vercel.app`)

### Backend (Railway/Render/DO):
- [ ] PostgreSQL Database erstellt
- [ ] Redis Service läuft
- [ ] Environment Variables gesetzt
- [ ] Domain/URL notiert (z.B. `omnitask-backend.railway.app`)

### Verbindung:
- [ ] Backend-URL in `frontend/lib/config/constants.dart` eingetragen
- [ ] CORS im Backend erlaubt Frontend-Domain
- [ ] Frontend neu deployed
- [ ] Alles funktioniert! 🎉

---

## 🐛 Troubleshooting

### "CORS Error" im Frontend

Backend `main.py` anpassen:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://deine-frontend-domain.vercel.app"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### "Build Failed" bei Vercel

Flutter muss installiert sein. Vercel hat kein Flutter pre-installed.
**Lösung**: Build lokal machen und nur `build/web` deployen:

```bash
cd frontend
flutter build web --release

# Dann nur build/web zu Vercel hochladen
vercel frontend/build/web --prod
```

### Backend startet nicht

Prüfe Logs:
```bash
# Railway
railway logs

# Render
→ Dashboard → Logs

# DigitalOcean
→ App → Runtime Logs
```

---

## 💰 Kosten Übersicht

| Service | Frontend (Vercel) | Backend (Railway) |
|---------|------------------|------------------|
| **Free Tier** | ✅ Unlimitiert | ✅ 500h/Monat |
| **Datenbank** | - | ✅ Inkludiert |
| **Redis** | - | ✅ Inkludiert |
| **HTTPS** | ✅ Automatisch | ✅ Automatisch |
| **Domain** | ✅ `.vercel.app` | ✅ `.railway.app` |

**Empfehlung**: Railway für Backend (am einfachsten + free tier)

---

## 🚀 Quick Start - Komplettes Deployment

```bash
# 1. Backend zu Railway
npm i -g @railway/cli
railway login
cd backend
railway init
railway add postgresql
railway add redis
railway up
# Notiere die URL: https://omnitask-backend.railway.app

# 2. Frontend API-URL anpassen
# Editiere: frontend/lib/config/constants.dart
# baseUrl = 'https://omnitask-backend.railway.app'

# 3. Frontend zu Vercel
npm i -g vercel
cd ..
vercel --prod

# 4. FERTIG! 🎉
```

---

## 📞 Support

Bei Problemen:
1. Check Logs (siehe Troubleshooting)
2. Prüfe Environment Variables
3. Teste Backend-URL direkt: `https://backend-url/health`
