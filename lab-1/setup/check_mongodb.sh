#!/bin/bash

# Выполняем ping команду через mongosh
PING_RESULT=$(mongosh --quiet --eval 'db.adminCommand({ ping: 1 })' 2>/dev/null)

if echo "$PING_RESULT" | grep -q '"ok": 1'; then
    echo "все топ и воркает"
else
    echo "что-то не воркает"
fi