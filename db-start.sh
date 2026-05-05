#!/bin/bash
# =============================================================================
# MilkGo Local DB — Start PostgreSQL 17 in Docker
# Container name : milkgo-local
# Port           : 5433 (matches Supabase local convention, avoids conflicts)
# DB             : milkgo / postgres / postgres
# =============================================================================

set -euo pipefail

CONTAINER="milkgo-local"
PG_PORT=5433
PG_DB=milkgo
PG_USER=postgres
PG_PASS=postgres

# ── Check Docker ──────────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "❌  Docker not found. Install Docker Desktop first."
  exit 1
fi

# ── Already running? ──────────────────────────────────────────────────────────
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "✅  ${CONTAINER} is already running."
  echo "    DATABASE_URL=postgresql://${PG_USER}:${PG_PASS}@localhost:${PG_PORT}/${PG_DB}"
  exit 0
fi

# ── Stopped but exists? ───────────────────────────────────────────────────────
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "▶   Starting existing container ${CONTAINER}..."
  docker start "${CONTAINER}"
else
  echo "🐳  Creating new container ${CONTAINER}..."
  docker run -d \
    --name "${CONTAINER}" \
    --restart unless-stopped \
    -e POSTGRES_DB="${PG_DB}" \
    -e POSTGRES_USER="${PG_USER}" \
    -e POSTGRES_PASSWORD="${PG_PASS}" \
    -p "${PG_PORT}:5432" \
    -v milkgo-local-data:/var/lib/postgresql/data \
    postgres:17
fi

# ── Wait for PostgreSQL to be ready ──────────────────────────────────────────
echo "⏳  Waiting for PostgreSQL to be ready..."
for i in $(seq 1 30); do
  if docker exec "${CONTAINER}" pg_isready -U "${PG_USER}" -d "${PG_DB}" &>/dev/null; then
    echo "✅  PostgreSQL is ready!"
    break
  fi
  sleep 1
done

echo ""
echo "    Container : ${CONTAINER}"
echo "    Port      : ${PG_PORT}"
echo "    DATABASE_URL=postgresql://${PG_USER}:${PG_PASS}@localhost:${PG_PORT}/${PG_DB}"
echo ""
echo "  Next steps:"
echo "    npm run db:migrate   — run all migrations"
echo "    npm run db:seed      — seed super admin"
echo "    npm run db:reset     — full reset (drop + migrate + seed)"
