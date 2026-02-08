FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Environment variables should be passed at runtime using docker-compose
SECRET_KEY = (irgendein langer String, z.B. "your-secret-key-here-123456789")
