#!/usr/bin/env bash
#
# restore.sh - restores a backup produced by backup.sh into a fresh
# local database, so restore is always tested against a clean target
# rather than merged on top of existing data.
#
# Usage:
#   ./scripts/restore.sh                       # restores backups/latest.dump
#   ./scripts/restore.sh backups/mydump.dump    # restores a specific file
#
# Env vars (all optional, defaults match docker-compose.yml):
#   DB_HOST           (default: localhost)
#   DB_PORT           (default: 5432)
#   DB_NAME           (default: hotel_bookings)      - source DB name, for reference only
#   RESTORE_DB_NAME   (default: hotel_bookings_restore) - the fresh DB restore lands in
#   DB_USER           (default: app_admin)
#   PGPASSWORD        (default: app_password)
#   BACKUP_DIR        (default: ./backups)

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-hotel_bookings}"
RESTORE_DB_NAME="${RESTORE_DB_NAME:-hotel_bookings_restore}"
DB_USER="${DB_USER:-app_admin}"
export PGPASSWORD="${PGPASSWORD:-app_password}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-${REPO_ROOT}/backups}"

BACKUP_FILE="${1:-${BACKUP_DIR}/latest.dump}"

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Backup file not found: ${BACKUP_FILE}" >&2
  echo "Run ./scripts/backup.sh first, or pass a path explicitly." >&2
  exit 1
fi

echo "Restoring ${BACKUP_FILE} into a fresh database '${RESTORE_DB_NAME}' on ${DB_HOST}:${DB_PORT}"

# Drop and recreate the target database so restore always runs against
# a clean slate (connect via the 'postgres' maintenance DB, since you
# cannot drop the DB you're connected to).
psql --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" --dbname=postgres -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS ${RESTORE_DB_NAME};"
psql --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" --dbname=postgres -v ON_ERROR_STOP=1 \
  -c "CREATE DATABASE ${RESTORE_DB_NAME};"

pg_restore \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_USER" \
  --dbname="$RESTORE_DB_NAME" \
  --no-owner \
  --no-privileges \
  "$BACKUP_FILE"

echo "Restore complete into database '${RESTORE_DB_NAME}'."
echo ""
echo "Verification:"

BOOKING_COUNT=$(psql --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" --dbname="$RESTORE_DB_NAME" \
  -t -A -c "SELECT COUNT(*) FROM hotel_bookings;")
EVENT_COUNT=$(psql --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" --dbname="$RESTORE_DB_NAME" \
  -t -A -c "SELECT COUNT(*) FROM booking_events;")
INDEX_COUNT=$(psql --host="$DB_HOST" --port="$DB_PORT" --username="$DB_USER" --dbname="$RESTORE_DB_NAME" \
  -t -A -c "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'hotel_bookings';")

echo "  hotel_bookings rows : ${BOOKING_COUNT}"
echo "  booking_events rows : ${EVENT_COUNT}"
echo "  indexes on hotel_bookings : ${INDEX_COUNT}"
echo ""
echo "Compare these counts against the source database (${DB_NAME}) to confirm the restore matches."
