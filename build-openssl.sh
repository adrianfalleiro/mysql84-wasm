#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source emsdk/emsdk_env.sh
root="$PWD"
cd openssl
emconfigure ./Configure linux-generic64 --cross-compile-prefix= --prefix="$root/openssl-wasm64" --libdir=lib \
  no-afalgeng no-shared no-asm no-dso no-module no-tests no-ui-console no-apps no-async \
  CC=emcc CXX=em++ AR=emar RANLIB=emranlib '-m64' '-pthread'
emmake make -j4 build_libs
emmake make install_dev
