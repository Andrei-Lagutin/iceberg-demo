#!/usr/bin/env bash
set -euo pipefail


mkdir -p ./data
mkdir -p ./catalog

# Проверим важные файлы и подскажем, если их нет
if [[ ! -f ./env.list ]]; then
  cat <<'MSG'
[!] Не найден env.list — создайте его со значениями из инструкции, например:
CATALOG_WAREHOUSE=s3://warehouse/
CATALOG_IO__IMPL=org.apache.iceberg.aws.s3.S3FileIO
CATALOG_S3_ENDPOINT=http://minio:9000
CATALOG_S3_PATH-STYLE-ACCESS=true
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_REGION=us-east-1
MSG
  exit 1
fi

if [[ ! -f ./catalog/iceberg.properties ]]; then
  cat <<'MSG'
[!] Не найден catalog/iceberg.properties — создайте его:
connector.name=iceberg
iceberg.catalog.type=rest
iceberg.rest-catalog.uri=http://iceberg-rest:8181/
iceberg.rest-catalog.warehouse=s3://warehouse/
iceberg.file-format=PARQUET
hive.s3.endpoint=http://minio:9000
hive.s3.path-style-access=true
MSG
  exit 1
fi

# Запуск в фоне
docker compose up -d

echo
echo "  Всё запущено."
echo "   Trino UI:      http://localhost:8080"
echo "   MinIO Console: http://localhost:9001  (логин/пароль: minioadmin/minioadmin)"
echo "   Iceberg REST:  http://localhost:8181"
echo
echo "Подключиться к Trino CLI: docker exec -it trino trino"
