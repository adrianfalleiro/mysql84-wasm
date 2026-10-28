#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source emsdk/emsdk_env.sh >/dev/null 2>&1
exec "$EMSDK_NODE" "$PWD/build-memfs/mysqld.js" --no-defaults \
  --user=root --lower-case-table-names=1 --basedir=/mysql --datadir=/mysql/data --lc-messages-dir=/mysql/share \
  --bind-address=127.0.0.1 --port=13385 --socket= \
  --pid-file=/mysql/run/mysql.pid --tmpdir=/tmp \
  --innodb-buffer-pool-size=64M --innodb-redo-log-capacity=64M \
  --max-connections=20 --skip-log-bin "$@"
