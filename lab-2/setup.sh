#!/bin/bash
set -e

source .env
OS_URL="https://localhost:9200"

echo "=== Ожидание доступности OpenSearch... ==="
until curl -sk -u "admin:${ADMIN_PASSWORD}" "${OS_URL}" > /dev/null; do
    echo "Ждем готовности кластера..."
    sleep 3
done
echo "Кластер готов!"

echo "=== 1. Установка интервала ISM на 1 минуту ==="
curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_cluster/settings" \
  -H 'Content-Type: application/json' \
  -d '{
    "persistent": {
      "plugins.index_state_management.job_interval": 1
    }
  }'
echo -e "\n"

echo "=== 2. Создание политики ISM logs_policy ==="
curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_plugins/_ism/policies/logs_policy" \
  -H 'Content-Type: application/json' \
  -d '{
    "policy": {
      "description": "Hot-Warm lifecycle policy for logs",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "actions": [
            {
              "rollover": {
                "min_index_age": "1m",
                "min_primary_shard_size": "1mb"
              }
            }
          ],
          "transitions": [
            {
              "state_name": "warm"
            }
          ]
        },
        {
          "name": "warm",
          "actions": [
            {
              "retry": {
                "count": 3,
                "backoff": "exponential",
                "delay": "1m"
              }
            }
          ],
          "transitions": [
            {
              "state_name": "delete",
              "conditions": {
                "min_index_age": "10m"
              }
            }
          ]
        },
        {
          "name": "delete",
          "actions": [
            {
              "delete": {}
            }
          ],
          "transitions": []
        }
      ],
      "ism_template": [
        {
          "index_patterns": ["logs*"],
          "priority": 100
        }
      ]
    }
  }'
echo -e "\n"

echo "=== 3. Создание Index Template для logs ==="
curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_index_template/logs-template" \
  -H 'Content-Type: application/json' \
  -d '{
    "index_patterns": ["logs*"],
    "data_stream": {},
    "template": {
      "settings": {
        "index.number_of_shards": 1,
        "index.number_of_replicas": 0,
        "index.routing.allocation.require.temp": "hot",
        "plugins.index_state_management.policy_id": "logs_policy"
      }
    },
    "priority": 100
  }'
echo -e "\n"

echo "=== 4. Настройка ролей RBAC ==="
# Роль logs_writer
curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_plugins/_security/api/roles/logs_writer" \
  -H 'Content-Type: application/json' \
  -d '{
    "cluster_permissions": ["indices:data/write*", "cluster:monitor/main"],
    "index_permissions": [
      {
        "index_patterns": ["logs*"],
        "allowed_actions": ["write", "create_index", "indices:data/write*"]
      }
    ]
  }'

# Роль logs_reader
curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_plugins/_security/api/roles/logs_reader" \
  -H 'Content-Type: application/json' \
  -d '{
    "cluster_permissions": ["cluster:monitor/main"],
    "index_permissions": [
      {
        "index_patterns": ["logs*"],
        "allowed_actions": ["read", "indices:data/read*"]
      }
    ]
  }'

# Роль metrics_monitor
curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_plugins/_security/api/roles/metrics_monitor" \
  -H 'Content-Type: application/json' \
  -d '{
    "cluster_permissions": ["cluster:monitor/*", "cluster_composite_ops_ro"]
  }'
echo -e "\n"

echo "=== 5. Создание пользователей ==="
curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_plugins/_security/api/internalusers/sofia_writer" \
  -H 'Content-Type: application/json' \
  -d "{\"password\": \"${WRITER_PASSWORD}\", \"opendistro_security_roles\": [\"logs_writer\"]}"

curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_plugins/_security/api/internalusers/sofia_reader" \
  -H 'Content-Type: application/json' \
  -d "{\"password\": \"${READER_PASSWORD}\", \"opendistro_security_roles\": [\"logs_reader\"]}"

curl -sk -u "admin:${ADMIN_PASSWORD}" -X PUT "${OS_URL}/_plugins/_security/api/internalusers/sofia_monitor" \
  -H 'Content-Type: application/json' \
  -d "{\"password\": \"${MONITOR_PASSWORD}\", \"opendistro_security_roles\": [\"metrics_monitor\"]}"
echo -e "\n"

echo "=== Настройка успешно завершена! ==="
