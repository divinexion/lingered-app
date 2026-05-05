#!/bin/bash
# Run all migrations against Neon DB in order.
# Usage: DATABASE_URL="postgresql://..." ./scripts/migrate.sh
#   OR:  ./scripts/migrate.sh postgresql://user:pass@host/db

DB_URL="${1:-$DATABASE_URL}"

if [ -z "$DB_URL" ]; then
  echo "❌ No DATABASE_URL set."
  echo "Usage: DATABASE_URL='postgresql://...' ./scripts/migrate.sh"
  echo "   or: ./scripts/migrate.sh 'postgresql://...'"
  exit 1
fi

MIGRATIONS_DIR="$(dirname "$0")/../migrations"

echo "🚀 Running migrations from: $MIGRATIONS_DIR"
echo ""

for file in $(ls "$MIGRATIONS_DIR"/*.sql | sort); do
  filename=$(basename "$file")
  echo -n "  ▶ $filename ... "

  if psql "$DB_URL" -f "$file" -q 2>&1 | grep -i "error"; then
    echo "❌ FAILED"
    echo "Fix the error above, then re-run from this file."
    exit 1
  else
    echo "✅"
  fi
done

echo ""
echo "✅ All migrations applied successfully."
