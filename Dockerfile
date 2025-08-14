# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION}-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# System deps (minimal). build-essential helps compile wheels such as hnswlib used by chromadb
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first for better layer caching
COPY requirements.txt ./ 
RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Default runtime config
# مفيش PORT ثابت هنا، خلي Cloud Run هو اللي يحدد
ENV GUNICORN_WORKERS=2 \
    GUNICORN_THREADS=8 \
    GUNICORN_TIMEOUT=120

# بدل EXPOSE 5000، خليه 8080 أو سيبه Cloud Run يتحكم
EXPOSE 8080

# Non-root user for security
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Healthcheck hitting readiness endpoint (use portable python -c)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["python", "-c", "import os,sys,urllib.request,urllib.error; port=os.environ.get('PORT','8080'); url=f'http://127.0.0.1:{port}/ready';\ntry:\n r=urllib.request.urlopen(url, timeout=3); sys.exit(0 if r.getcode()==200 else 1)\nexcept Exception:\n sys.exit(1)"]

# Start with Gunicorn; the Flask app instance is `app` in `main.py`
# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION}-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# System deps (minimal). build-essential helps compile wheels such as hnswlib used by chromadb
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first for better layer caching
COPY requirements.txt ./
RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Default runtime config
ENV PORT=8080 \
    GUNICORN_WORKERS=2 \
    GUNICORN_THREADS=8 \
    GUNICORN_TIMEOUT=120

EXPOSE 8080

# Non-root user for security
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Healthcheck hitting readiness endpoint (use portable python -c)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["python", "-c", "import os,sys,urllib.request,urllib.error; url='http://127.0.0.1:%s/ready' % os.environ.get('PORT','8080');\ntry:\n r=urllib.request.urlopen(url, timeout=3); sys.exit(0 if r.getcode()==200 else 1)\nexcept Exception:\n sys.exit(1)"]

# Start with Gunicorn; the Flask app instance is `app` in `main.py`
CMD ["sh","-c","gunicorn \
  -w ${GUNICORN_WORKERS:-1} -k gthread --threads ${GUNICORN_THREADS:-8} \
  --timeout ${GUNICORN_TIMEOUT:-120} \
  -b 0.0.0.0:${PORT:-8080} \
  --access-logfile - --error-logfile - --log-level debug \
  main:app"]
