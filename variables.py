# variables.py
import os

ENV = os.getenv("ENV", "production").lower()
IS_PROD = ENV == "production"

def _get(name, default=None, required=False):
    v = os.getenv(name, default)
    if required and (v is None or v == ""):
        raise RuntimeError(f"Missing env var: {name}")
    return v

# Gemini
GEMINI_API_KEY   = _get("GEMINI_API_KEY", required=IS_PROD)
GEMINI_MODEL_NAME = _get("GEMINI_MODEL_NAME", default="gemini-2.5-flash")

# Database
DB_HOST     = _get("DB_HOST", required=True)
DB_PORT     = int(_get("DB_PORT", default="3306"))
DB_NAME     = _get("DB_NAME", required=True)
DB_USER     = _get("DB_USER", required=True)
DB_PASSWORD = _get("DB_PASSWORD", required=IS_PROD)

# Email
EMAIL_HOST     = _get("EMAIL_HOST", default="smtp.gmail.com")
EMAIL_PORT     = int(_get("EMAIL_PORT", default="587"))
EMAIL_USER     = _get("EMAIL_USER", required=IS_PROD)
EMAIL_PASSWORD = _get("EMAIL_PASSWORD", required=IS_PROD)
TEAM_EMAIL     = _get("TEAM_EMAIL", default=None)

# APIs
USER_INFO_API_URL = _get("USER_INFO_API_URL", default="https://sharyproperties.com/api/UserInfo")

# Cache / Chroma (اكتب على /tmp في Cloud Run)
CACHE_DIR                 = _get("CACHE_DIR", default="/tmp/cache")
LEADS_CACHE_FILE          = _get("LEADS_CACHE_FILE", default="leads_cache.json")
CONVERSATIONS_CACHE_FILE  = _get("CONVERSATIONS_CACHE_FILE", default="conversations_cache.json")
UNITS_CACHE_FILE          = _get("UNITS_CACHE_FILE", default="units.json")
NEW_LAUNCHES_CACHE_FILE   = _get("NEW_LAUNCHES_CACHE_FILE", default="new_launches.json")
DEVELOPERS_CACHE_FILE     = _get("DEVELOPERS_CACHE_FILE", default="developers.json")
CHROMA_DIR                = _get("CHROMA_DIR", default="/tmp/chroma_db")

# App
APP_HOST   = _get("APP_HOST", default="0.0.0.0")
APP_PORT   = int(_get("PORT", default="8080"))  # Cloud Run يمرّر PORT
DEBUG_MODE = _get("DEBUG_MODE", default="false").lower() == "true"

# Scheduler
CACHE_SYNC_HOUR = int(_get("CACHE_SYNC_HOUR", default="4"))
DB_SYNC_HOUR    = int(_get("DB_SYNC_HOUR", default="3"))

# Logging
LOG_LEVEL = _get("LOG_LEVEL", default="INFO")
