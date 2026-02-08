#!/bin/bash

# 🚀 OmniTask - Automatisches Deployment Script
# Deployed Frontend → Vercel, Backend → Railway

set -e  # Bei Fehler stoppen

# Farben für Output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀  OmniTask - Automatisches Deployment  🚀${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================
# 1. DEPENDENCIES CHECK
# ============================================

echo -e "${YELLOW}📦 Prüfe Dependencies...${NC}"

# Node.js check
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js ist nicht installiert!${NC}"
    echo -e "   Installiere mit: brew install node"
    exit 1
fi

# NPM check
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm ist nicht installiert!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js & npm gefunden${NC}"

# Railway CLI check & install
if ! command -v railway &> /dev/null; then
    echo -e "${YELLOW}📥 Installiere Railway CLI...${NC}"
    npm i -g @railway/cli
fi

# Vercel CLI check & install
if ! command -v vercel &> /dev/null; then
    echo -e "${YELLOW}📥 Installiere Vercel CLI...${NC}"
    npm i -g vercel
fi

echo -e "${GREEN}✅ Alle CLIs installiert${NC}"
echo ""

# ============================================
# 2. BACKEND DEPLOYMENT (Railway)
# ============================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🐍  Backend Deployment (Railway)         ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Railway Login
echo -e "${YELLOW}🔐 Railway Login...${NC}"
echo -e "   (Browser öffnet sich - bitte anmelden)"
railway login

# Ins Backend-Verzeichnis wechseln
cd backend

# Railway Projekt initialisieren
echo -e "${YELLOW}🏗️  Erstelle Railway Projekt...${NC}"
railway init

# PostgreSQL hinzufügen
echo -e "${YELLOW}🗄️  Füge PostgreSQL hinzu...${NC}"
railway add --database postgresql

# Redis hinzufügen
echo -e "${YELLOW}🔴 Füge Redis hinzu...${NC}"
railway add --database redis

# Environment Variables setzen
echo -e "${YELLOW}⚙️  Setze Environment Variables...${NC}"

# Generiere SECRET_KEY
SECRET_KEY=$(openssl rand -hex 32)
railway variables --set SECRET_KEY="$SECRET_KEY"
railway variables --set ALGORITHM="HS256"

# OpenAI API Key (optional)
echo ""
echo -e "${YELLOW}🤖 OpenAI API Key (optional - Enter für Skip):${NC}"
read -p "   API Key: " OPENAI_KEY
if [ ! -z "$OPENAI_KEY" ]; then
    railway variables --set OPENAI_API_KEY="$OPENAI_KEY"
fi

# Backend deployen
echo ""
echo -e "${YELLOW}🚀 Deploye Backend zu Railway...${NC}"
echo -e "   (Das dauert 2-3 Minuten...)"
railway up

# Warte auf Deployment
sleep 5

# Domain abrufen
echo ""
echo -e "${YELLOW}🌐 Erstelle Domain...${NC}"
railway domain

# Domain extrahieren
BACKEND_URL=$(railway domain 2>&1 | grep -o 'https://[^[:space:]]*' | head -1)

if [ -z "$BACKEND_URL" ]; then
    echo -e "${RED}❌ Konnte Backend-URL nicht ermitteln!${NC}"
    echo -e "${YELLOW}   Bitte manuell abrufen mit: railway domain${NC}"
    read -p "   Backend URL eingeben: " BACKEND_URL
fi

echo ""
echo -e "${GREEN}✅ Backend deployed!${NC}"
echo -e "${GREEN}   URL: ${BACKEND_URL}${NC}"

# Zurück ins Hauptverzeichnis
cd ..

# ============================================
# 3. FRONTEND CONFIG UPDATE
# ============================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚙️  Frontend Konfiguration               ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}📝 Update API-URL in Frontend...${NC}"

# Backend-URL in Frontend-Config eintragen
sed -i.bak "s|http://localhost:8000|${BACKEND_URL}|g" frontend/lib/config/constants.dart
rm -f frontend/lib/config/constants.dart.bak

echo -e "${GREEN}✅ API-URL aktualisiert: ${BACKEND_URL}${NC}"

# Änderungen committen
echo ""
echo -e "${YELLOW}💾 Committe Änderungen...${NC}"
git add frontend/lib/config/constants.dart
git commit -m "chore: Update API baseUrl to Railway production URL

Backend deployed to: ${BACKEND_URL}
Ready for Vercel frontend deployment" || true

git push origin main || true

echo -e "${GREEN}✅ Änderungen committed & gepusht${NC}"

# ============================================
# 4. FRONTEND DEPLOYMENT (Vercel)
# ============================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🌐  Frontend Deployment (Vercel)         ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}🚀 Deploye Frontend zu Vercel...${NC}"
echo -e "   (Beim ersten Mal werden ein paar Fragen gestellt)"
echo ""

# Vercel Deployment
vercel --prod

# ============================================
# 5. FERTIG!
# ============================================

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉  DEPLOYMENT ERFOLGREICH ABGESCHLOSSEN!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ Backend:  ${BACKEND_URL}${NC}"
echo -e "${GREEN}✅ Frontend: https://[deine-domain].vercel.app${NC}"
echo ""
echo -e "${BLUE}📋 Nächste Schritte:${NC}"
echo -e "   1. Teste Backend: curl ${BACKEND_URL}/health"
echo -e "   2. Öffne Frontend in Browser"
echo -e "   3. Erstelle ersten Account im Frontend"
echo ""
echo -e "${YELLOW}💡 Tipps:${NC}"
echo -e "   - Railway Dashboard: railway open"
echo -e "   - Vercel Dashboard: vercel dashboard"
echo -e "   - Logs ansehen: railway logs"
echo ""
echo -e "${GREEN}🚀 Viel Erfolg mit OmniTask!${NC}"
echo ""
