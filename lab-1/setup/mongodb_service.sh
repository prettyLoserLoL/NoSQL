#!/bin/bash
# Управление службой MongoDB: запуск, остановка, перезапуск

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
        sudo systemctl status mongod --no-pager
        ;;
    *)
        echo "Ошибка! Надо: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac