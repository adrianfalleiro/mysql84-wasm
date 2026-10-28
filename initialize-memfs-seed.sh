#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -e memfs-seed ]]; then
  echo 'memfs-seed already exists; refusing to overwrite it.' >&2
  exit 1
fi
bash run-mysqld.sh --initialize-insecure --lower-case-table-names=1 \
  --datadir="$PWD/memfs-seed" --log-error="$PWD/memfs-seed-init.err"
