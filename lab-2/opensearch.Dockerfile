FROM opensearchproject/opensearch:2.19.6

# Устанавливаем плагин, явно указав версию 2.19.6.0 в ссылке
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch https://github.com/aiven/prometheus-exporter-plugin-for-opensearch/releases/download/2.19.6.0/prometheus-exporter-2.19.6.0.zip
