#!/usr/bin/env bash

ARCHIVE="$1"
DB_NAME="$2"

mongorestore \
  --username adminSofia \
  --password password123 \
  --authenticationDatabase admin \
  --archive="$ARCHIVE" \
  --gzip \
  --nsInclude="${DB_NAME}.*" \
  --drop

echo "Восстановление базы $DB_NAME завершено"