#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
clone_pinned() {
  local url="$1" dir="$2" ref="$3" commit="$4"
  if [[ ! -d "$dir" ]]; then
    git clone --depth 1 --branch "$ref" "$url" "$dir"
  fi
  [[ "$(git -C "$dir" rev-parse HEAD)" == "$commit" ]] || {
    echo "Unexpected revision in $dir; refusing to modify it." >&2
    exit 1
  }
}
clone_pinned https://github.com/mysql/mysql-server.git mysql-server mysql-8.4.13 8a180268d832300c09a375115dfa0ea77d83f1af
clone_pinned https://github.com/openssl/openssl.git openssl openssl-3.5.4 c1eeb9406b6142148f267594197d853403d10208
if [[ ! -d emsdk ]]; then
  git init emsdk
  git -C emsdk remote add origin https://github.com/emscripten-core/emsdk.git
  git -C emsdk fetch --depth 1 origin d7b4130688bfa348392b921ab04015aa15c4f154
  git -C emsdk checkout --detach FETCH_HEAD
fi
[[ "$(git -C emsdk rev-parse HEAD)" == d7b4130688bfa348392b921ab04015aa15c4f154 ]]
./emsdk/emsdk install 6.0.13
./emsdk/emsdk activate 6.0.13
apply_patch_once() {
  local directory="$1" patch_file="$PWD/$2"
  if (cd "$directory" && git apply --reverse --check "$patch_file") 2>/dev/null; then
    echo "Already applied: $2"
  else
    (cd "$directory" && git apply --check "$patch_file" && git apply "$patch_file")
  fi
}
apply_patch_once mysql-server patches/mysql-wasm.patch
apply_patch_once emsdk/upstream/emscripten patches/emscripten-wasm64.patch
