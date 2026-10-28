#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source emsdk/emsdk_env.sh >/dev/null 2>&1
mkdir -p "$PWD/run"
exec "$EMSDK_NODE" "$PWD/build-wasm64/runtime_output_directory/mysqld.js" --no-defaults \
  --basedir="$PWD/build-wasm64" --datadir="$PWD/run/data" \
  --lc-messages-dir="$PWD/build-wasm64/share" \
  --bind-address=127.0.0.1 --port=13384 --socket="$PWD/run/mysql.sock" \
  --pid-file="$PWD/run/mysql.pid" --log-error="$PWD/run/mysql.err" \
  --innodb-buffer-pool-size=64M --innodb-redo-log-capacity=64M \
  --max-connections=20 --skip-log-bin "$@"
