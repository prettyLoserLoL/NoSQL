#!/bin/bash

# Проверяем ответ от MongoDB через mongosh

if mongosh --quiet --eval 'db.adminCommand({ ping: 1 })' | grep -q '"ok": 1'; then
    echo "УСПЕШНЫЙ УСПЕХ: MongoDB работает и отвечает на запросы :)"
else
    echo "ОШИБОЧНАВЯ ОШИБКА: MongoDB недоступен :("
fi