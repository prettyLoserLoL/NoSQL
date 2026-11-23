#!/bin/bash
echo "Генерация 500 запросов к Nginx для создания логов..."
for i in {1..500}; do
  curl -s http://localhost:8080/ > /dev/null
  if (( i % 50 == 0 )); then
    echo "Отправлено запросов: $i"
  fi
done
echo "Готово! Fluent Bit пересылает эти логи в OpenSearch."
