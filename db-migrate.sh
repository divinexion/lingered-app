#!/bin/bash
# =============================================================================
# MilkGo — Run all migrations against local Docker PostgreSQL
# Migrations are plain PostgreSQL — no Supabase/auth schema needed.
# =============================================================================

set -euo pipefail

CONTAINER="milkgo-local"
PG_PORT=5433
PG_DB=milkgo
PG_USER=postgres
PG_PASS=postgres

DB_URL="postgresql://${PG_USER}:${PG_PASS}@localhost:${PG_PORT}/${PG_DB}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
MIGRATIONS_DIR="${PROJECT_ROOT}/migrations"

# ── Check psql ────────────────────────────────────────────────────────────────
# Add Homebrew postgresql to PATH if not already there
for pg_path in /opt/homebrew/opt/postgresql@17/bin /usr/local/opt/postgresql@17/bin; do
  [ -d "$pg_path" ] && export PATH="$pg_path:$PATH" && break
done

if ! command -v psql &>/dev/null; then
  echo "❌  psql not found."
  echo "    Install: brew install postgresql@17"
  exit 1
fi

# ── Check container running ───────────────────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "❌  Container ${CONTAINER} is not running."
  echo "    Run: npm run db:start"
  exit 1
fi

# ── Wait for ready ────────────────────────────────────────────────────────────
echo "⏳  Waiting for PostgreSQL..."
for i in $(seq 1 15); do
  if psql "${DB_URL}" -c "SELECT 1" &>/dev/null 2>&1; then break; fi
  sleep 1
done

echo "🔧  Running migrations..."
for f in $(ls "${MIGRATIONS_DIR}"/*.sql | sort); do
  echo "    → $(basename "${f}")"
  psql "${DB_URL}" -f "${f}" -v ON_ERROR_STOP=1 -q
done

echo ""
echo "✅  All migrations applied!"
echo "    Run: npm run db:seed   — to seed super admin"
