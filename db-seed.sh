#!/bin/bash
# =============================================================================
# MilkGo — Seed super admin + plans into local DB
# =============================================================================

set -euo pipefail

PG_PORT=5433
PG_DB=milkgo
PG_USER=postgres
PG_PASS=postgres
DB_URL="postgresql://${PG_USER}:${PG_PASS}@localhost:${PG_PORT}/${PG_DB}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v psql &>/dev/null; then
  echo "❌  psql not found. Install: brew install postgresql@17"
  exit 1
fi

echo "🌱  Seeding local database..."
psql "${DB_URL}" -f "${SCRIPT_DIR}/seed.sql" -v ON_ERROR_STOP=1

echo ""
echo "    Phone : +918758223351"
echo "    PIN   : 12345678"
