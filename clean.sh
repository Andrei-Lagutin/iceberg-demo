#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOS'
clean.sh — полностью очистить локальное окружение Iceberg demo.

Действия по умолчанию:
  - docker compose down -v (удалить контейнеры и связанные тома)
  - удалить ./data (данные MinIO)

Флаги:
  --all     Также удалить docker-образы (minio, iceberg-rest, trino)
  --yes,-y  Не спрашивать подтверждение
  --help,-h Показать эту справку

Примеры:
  ./clean.sh
  ./clean.sh --yes
  ./clean.sh --all -y
EOS
}

YES=0
ALL=0

for arg in "${@:-}"; do
  case "$arg" in
    --yes|-y) YES=1 ;;
    --all)    ALL=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "[!] Неизвестный аргумент: $arg"; usage; exit 1 ;;
  esac
done

echo "Это удалит контейнеры, тома Docker и папку ./data."
[[ $ALL -eq 1 ]] && echo "Дополнительно будут удалены docker-образы minio/iceberg-rest/trino."

if [[ $YES -ne 1 ]]; then
  read -r -p "Продолжить? [y/N] " reply
  case "$reply" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Отменено."; exit 0 ;;
  esac
fi

# Остановить и удалить контейнеры + тома
if command -v docker &>/dev/null; then
  docker compose down -v || true
else
  echo "[!] Docker не найден в PATH."
fi

# Удалить данные MinIO
if [[ -d ./data ]]; then
  rm -rf ./data
  echo "🧹 Удалена папка ./data."
else
  echo "ℹ️  Папка ./data не найдена — пропускаю."
fi

# Опционально удалить образы
if [[ $ALL -eq 1 ]]; then
  IMAGES=(
    "quay.io/minio/minio:RELEASE.2024-09-13T20-26-02Z.fips"
    "tabulario/iceberg-rest:1.6.0"
    "trinodb/trino:449"
  )
  for img in "${IMAGES[@]}"; do
    docker rmi -f "$img" || true
  done
  echo "🗑️  Образы удалены (если были)."
fi

echo " Очистка завершена."
