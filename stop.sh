#!/usr/bin/env bash
set -euo pipefail

docker compose down

echo " Остановлено. Данные в ./data сохранены. Чтобы очистить и тома: docker compose down -v"
