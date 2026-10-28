#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source emsdk/emsdk_env.sh
em++ -pthread -m64 -fexceptions -sNODERAWFS=1 -sALLOW_MEMORY_GROWTH=1 \
  -sINITIAL_MEMORY=67108864 -sPROXY_TO_PTHREAD=1 -sEXIT_RUNTIME=1 \
  -Itimer-test-config -Imysql-server/include \
  mysql-server/mysys/emscripten_timers.cc timer-test.cc -o timer-test-proxy.js
"$EMSDK_NODE" timer-test-proxy.js
emcc -pthread -m64 -Iopenssl-wasm64/include openssl-test.c \
  openssl-wasm64/lib/libssl.a openssl-wasm64/lib/libcrypto.a -o openssl-test.js
"$EMSDK_NODE" openssl-test.js

emcc -pthread -m64 -sNODERAWFS=1 -sNODERAWSOCKETS=1 addrinfo-test.c -o addrinfo-test.js
"$EMSDK_NODE" addrinfo-test.js
em++ -pthread -m64 -sPROXY_TO_PTHREAD=1 -sEXIT_RUNTIME=1 signal-test.cc -o signal-test.js
"$EMSDK_NODE" signal-test.js
