#!/bin/bash
# =============================================================================
# MilkGo — Full local DB reset (drops + recreates + migrates + seeds)
# WARNING: destroys ALL local data
# =============================================================================

set -euo pipefail

CONTAINER="milkgo-local"
PG_PORT=5433
PG_DB=milkgo
PG_USER=postgres
PG_PASS=postgres
DB_URL="postgresql://${PG_USER}:${PG_PASS}@localhost:${PG_PORT}/postgres"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v psql &>/dev/null; then
  echo "❌  psql not found. Install: brew install postgresql@17"
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "❌  Container ${CONTAINER} is not running. Run: npm run db:start"
  exit 1
fi

echo "⚠️   This will DROP and recreate the '${PG_DB}' database."
read -p "    Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "🗑   Dropping database ${PG_DB}..."
psql "${DB_URL}" -c "DROP DATABASE IF EXISTS ${PG_DB};" -v ON_ERROR_STOP=1
psql "${DB_URL}" -c "CREATE DATABASE ${PG_DB};" -v ON_ERROR_STOP=1

echo ""
bash "${SCRIPT_DIR}/db-migrate.sh"

echo ""
bash "${SCRIPT_DIR}/db-seed.sh"

echo ""
echo "✅  Local DB reset complete!"
