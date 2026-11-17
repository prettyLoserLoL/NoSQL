#!/bin/bash
# Установка MongoDB для Lubuntu
set -e

echo "... Обновление системы ..."
sudo apt update && sudo apt upgrade -y
echo "-------------------------------------------"

echo "... Установка ключей и репозитория MongoDB ..."
sudo apt install -y gnupg curl
curl -fsSL https://www.pgp.mongodb.com/server-7.0.asc | \
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
sudo systemctl status mongod --no-pager