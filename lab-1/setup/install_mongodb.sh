#!/bin/bash
# Обновление пакетов и установка зависимостей
sudo apt-get update
sudo apt-get install -y gnupg curl

# Добавление официального GPG ключа MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Добавление репозитория MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Обновление списков пакетов и установка MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# Включение автозапуска и запуск службы
sudo systemctl enable mongod
sudo systemctl start mongod

echo "Установка MongoDB завершена!"