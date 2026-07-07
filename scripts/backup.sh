#!/usr/bin/env bash
#
# backup.sh - creates a timestamped dump of the local database.
#
# Usage:
#   ./scripts/backup.sh
#
# Env vars (all optional, defaults match docker-compose.yml):
#   DB_HOST       (default: localhost)
#   DB_PORT       (default: 5432)
#   DB_NAME       (default: hotel_bookings)
#   DB_USER       (default: app_admin)
#   PGPASSWORD    (default: app_password)
#   BACKUP_DIR    (default: ./backups)

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-hotel_bookings}"
DB_USER="${DB_USER:-app_admin}"
export PGPASSWORD="${PGPASSWORD:-app_password}"
BACKUP_DIR="${BACKUP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups}"

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"

echo "Backing up database '${DB_NAME}' from ${DB_HOST}:${DB_PORT} -> ${BACKUP_FILE}"

pg_dump \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_USER" \
  --format=custom \
  --no-owner \
  --no-privileges \
  --file="$BACKUP_FILE" \
  "$DB_NAME"

echo "Backup complete: ${BACKUP_FILE}"
echo "$(du -h "$BACKUP_FILE" | cut -f1) written"

# Keep a stable pointer to the most recent backup for convenience.
ln -sf "$(basename "$BACKUP_FILE")" "${BACKUP_DIR}/latest.dump"
echo "Updated symlink: ${BACKUP_DIR}/latest.dump -> $(basename "$BACKUP_FILE")"
