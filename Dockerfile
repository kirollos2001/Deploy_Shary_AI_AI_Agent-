# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION}-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential git \
 && rm -rf /var/lib/apt/lists/*

# deps أولاً
COPY requirements.txt ./
RUN python -m pip install --upgrade pip setuptools wheel \
 && pip install --no-cache-dir -r requirements.txt

# الكود
COPY . .

# runtime
ENV PORT=8080 \
    GUNICORN_WORKERS=2 \
    GUNICORN_THREADS=8 \
    GUNICORN_TIMEOUT=120

EXPOSE 8080

# أمان
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["python","-c","import os,sys,urllib.request; url=f'http://127.0.0.1:{os.environ.get(\"PORT\",\"8080\")}/ready';\nimport urllib.error\ntry:\n r=urllib.request.urlopen(url, timeout=3); sys.exit(0 if r.getcode()==200 else 1)\nexcept Exception:\n sys.exit(1)"]

# شغّل Gunicorn على PORT اللي Cloud Run بيبعتها
CMD ["sh","-c","gunicorn -w ${GUNICORN_WORKERS:-2} -k gthread --threads ${GUNICORN_THREADS:-8} --timeout ${GUNICORN_TIMEOUT:-120} -b 0.0.0.0:${PORT:-8080} --access-logfile - --error-logfile - --log-level debug main:app"]
