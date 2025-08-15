# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION}-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# System deps (chromadb يحتاج build-essential أحيانًا)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     build-essential git \
  && rm -rf /var/lib/apt/lists/*

# Install deps أولاً عشان الكاش
COPY requirements.txt ./
RUN python -m pip install --upgrade pip setuptools wheel \
  && pip install --no-cache-dir -r requirements.txt

# نسخ الكود
COPY . .

# إعدادات التشغيل الافتراضية
ENV GUNICORN_WORKERS=2 \
    GUNICORN_THREADS=8 \
    GUNICORN_TIMEOUT=120

# Cloud Run بيحدد PORT؛ هنستخدم 8080 كافتراضي لو مش متوفر
ENV PORT=8080
EXPOSE 8080

# إصلاح صلاحيات ومسار cache (لو كودك بيستعمل مجلد اسمه cache)
RUN useradd -m appuser \
  && mkdir -p /app/cache \
  && chown -R appuser:appuser /app
USER appuser

# Healthcheck على /ready
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["python", "-c", "import os,sys,urllib.request; \
port=os.environ.get('PORT','8080'); \
url=f'http://127.0.0.1:{port}/ready'; \
import urllib.error as e; \
import urllib.request as r; \
import sys as s; \
import time; \
try: resp=r.urlopen(url, timeout=3); s.exit(0 if resp.getcode()==200 else 1) \
except Exception: s.exit(1)"]

# تشغيل Gunicorn على main:app
CMD ["sh","-c","gunicorn \
  -w ${GUNICORN_WORKERS:-1} -k gthread --threads ${GUNICORN_THREADS:-8} \
  --timeout ${GUNICORN_TIMEOUT:-120} \
  -b 0.0.0.0:${PORT:-8080} \
  --access-logfile - --error-logfile - --log-level debug \
  main:app"]
