#!/bin/bash
# Скрипт установки MongoDB 7.0 для Lubuntu
set -e

echo "... Обновление системы ..."
sudo apt update
echo "-------------------------------------------"
echo "... Установка ключей и репозитория MongoDB ..."
sudo apt install -y gnupg curl
echo "-------------------------------------------"
# Загрузка ключа с официального сайта mongodb.org
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor --yes
echo "-------------------------------------------"
# Используем репозиторий jammy, потому что так сказали в интернете
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
echo "-------------------------------------------"
echo "... Установка пакетов MongoDB ..."
sudo apt update
sudo apt install -y mongodb-org
echo "-------------------------------------------"
echo "... Настройка автозапуска службы ..."
sudo systemctl enable mongod
sudo systemctl start mongod

echo "-------------------------------------------"
echo "Установка завершена! Проверка статуса:"
sudo systemctl status mongod --no-pager