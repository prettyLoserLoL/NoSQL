#!/usr/bin/env bash
BACKUP_ROOT="$HOME/mongodb_backups"
mkdir -p "$BACKUP_ROOT"
BACKUP_DIR="$BACKUP_ROOT/all_$(date +%Y%m%d_%H%M%S)"

# И ЗДЕСЬ ТОЖЕ:
mkdir -p "$BACKUP_DIR"

for DB_NAME in "edu_db1" "edu_db2"; do
  mongodump \
    --username adminSofia \
    --password password123 \
    --authenticationDatabase admin \
    --db "$DB_NAME" \
    --archive="$BACKUP_DIR/${DB_NAME}.archive.gz" \
    --gzip
  echo "База $DB_NAME сохранена"
done