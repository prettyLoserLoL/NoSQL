#!/usr/bin/env bash
DB_NAME="$1"
BACKUP_ROOT="$HOME/mongodb_backups"
mkdir -p "$BACKUP_ROOT"
BACKUP_DIR="$BACKUP_ROOT/backup_$(date +%Y%m%d_%H%M%S)"

# ВОТ ЭТА СТРОЧКА ИСПРАВИТ ОШИБКУ:
mkdir -p "$BACKUP_DIR"

mongodump \
  --host 127.0.0.1 \
  --port 27017 \
  --username adminSofia \
  --password password123 \
  --authenticationDatabase admin \
  --db "$DB_NAME" \
  --archive="$BACKUP_DIR/${DB_NAME}.archive.gz" \
  --gzip

echo "Бэкап базы $DB_NAME завершен: $BACKUP_DIR"