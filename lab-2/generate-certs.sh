#!/bin/bash
set -e

mkdir -p certs
cd certs

echo "=== 1. Root CA ==="
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -out root-ca.pem -days 730 \
  -subj "/C=RU/ST=SPb/O=SofiaEdu/CN=Sofia-Root-CA"

echo "=== 2. Admin Certificate ==="
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -topk8 -inform PEM -outform PEM -in admin-key-temp.pem -out admin-key.pem -nocrypt
openssl req -new -key admin-key.pem -out admin.csr \
  -subj "/C=RU/ST=SPb/O=SofiaEdu/CN=admin"
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -out admin.pem -days 730 -sha256

echo "=== 3. Node Shared Certificate with SAN ==="
openssl genrsa -out node-key-temp.pem 2048
openssl pkcs8 -topk8 -inform PEM -outform PEM -in node-key-temp.pem -out node-key.pem -nocrypt

cat << 'EXT' > node.ext
subjectAltName = @alt_names
[alt_names]
DNS.1 = sofia-os-manager
DNS.2 = sofia-os-hot
DNS.3 = sofia-os-warm
DNS.4 = localhost
IP.1 = 127.0.0.1
EXT

openssl req -new -key node-key.pem -out node.csr \
  -subj "/C=RU/ST=SPb/O=SofiaEdu/CN=node"
openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -out node.pem -days 730 -sha256 -extfile node.ext

rm -f *-temp.pem *.csr node.ext
chmod 644 *.pem

echo "=== Сертификаты сгенерированы! ==="
