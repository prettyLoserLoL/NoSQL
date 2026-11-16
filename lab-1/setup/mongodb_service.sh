#!/bin/bash

ACTION=$1

case "$ACTION" in
    start)
        echo "Запуск MongoDB..."
        sudo systemctl start mongod
        ;;
    stop)
        echo "Остановка MongoDB..."
        sudo systemctl stop mongod
        ;;
    restart)
        echo "Перезапуск MongoDB..."
        sudo systemctl restart mongod
        ;;
    status)
        echo "Статус MongoDB:"
        sudo systemctl status mongod
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac