#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source emsdk/emsdk_env.sh
bison_executable="${BISON_EXECUTABLE:-$(command -v bison)}"
if [[ -z "${BISON_EXECUTABLE:-}" && -x /opt/homebrew/opt/bison/bin/bison ]]; then
  bison_executable=/opt/homebrew/opt/bison/bin/bison
fi
emcmake cmake -S mysql-server -B build-wasm64 -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  '-DCMAKE_C_FLAGS=-pthread -m64' \
  '-DCMAKE_CXX_FLAGS=-pthread -m64 -fexceptions' \
  '-DCMAKE_EXE_LINKER_FLAGS=-fexceptions -sNODERAWFS=1 -sNODERAWSOCKETS=1 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=67108864 -sSTACK_SIZE=8388608 -sPROXY_TO_PTHREAD=1 -sEXIT_RUNTIME=1' \
  -DWITH_UNIT_TESTS=OFF -DWITH_ROUTER=OFF -DWITH_NDB=OFF \
  -DWITH_NDBCLUSTER_STORAGE_ENGINE=OFF \
  -DWITH_SSL=system -DOPENSSL_ROOT_DIR="$PWD/openssl-wasm64" \
  -DOPENSSL_INCLUDE_DIR="$PWD/openssl-wasm64/include" \
  -DOPENSSL_CRYPTO_LIBRARY="$PWD/openssl-wasm64/lib/libcrypto.a" \
  -DOPENSSL_SSL_LIBRARY="$PWD/openssl-wasm64/lib/libssl.a" \
  -DWITH_AUTHENTICATION_CLIENT_PLUGINS=OFF -DWITH_AUTHENTICATION_LDAP=OFF \
  -DWITH_AUTHENTICATION_KERBEROS=OFF -DWITH_AUTHENTICATION_WEBAUTHN=OFF \
  -DWITH_MYSQLX=OFF -DWITH_GROUP_REPLICATION=OFF \
  -Dprotobuf_BUILD_SHARED_LIBS=OFF \
  -DBISON_EXECUTABLE="$bison_executable" \
  -DWITH_ZLIB=bundled \
  -DWITH_ZSTD=bundled -DWITH_LZ4=bundled -DWITH_EDITLINE=bundled \
  "$@"
cmake --build build-wasm64 --target mysqld --parallel 4
