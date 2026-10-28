# MySQL 8.4 on WebAssembly

Experimental MySQL **8.4.13** server compiled to **wasm64** with Emscripten
**6.0.13**, running under its bundled Node **24.19.0**. Includes disk-backed
and volatile in-memory (MEMFS) variants. This is not a browser build or a
production-qualified MySQL distribution.

## Build

Tested on macOS with CMake, Ninja, GNU Make, Python 3, Perl, Git and modern
Bison. On Apple Silicon, the build script prefers Homebrew's Bison;
elsewhere set `BISON_EXECUTABLE` to your Bison binary if needed.

```sh
bash bootstrap.sh
bash build-openssl.sh
bash configure-wasm64.sh
```

Bootstrap fetches pinned upstream sources, installs the SDK and applies the
patches. The server outputs are `build-wasm64/runtime_output_directory/mysqld.js`
and `mysqld.wasm`; both are required. Generated artifacts are excluded from Git.

## Disk-backed server

```sh
# Only for a new database; let MySQL create run/data itself.
bash run-mysqld.sh --initialize-insecure
bash run-mysqld.sh
```

Connect to `127.0.0.1:13384`, user `root`, empty password. Data persists in
`run/data`. These defaults are for isolated local experiments. Stop with SQL
`SHUTDOWN`. The launcher ignores host MySQL configuration files.

## In-memory server

```sh
bash initialize-memfs-seed.sh
source emsdk/emsdk_env.sh
python3 build-memfs.py
bash run-mysqld-memfs.sh
```

Connect to `127.0.0.1:13385`, user `root`, empty password. Each startup copies
`memfs-seed` and MySQL support files from disk into MEMFS. Subsequent database,
redo, temporary and PID file writes stay in memory; **all changes disappear
on process exit**. There is no writeback. The seed initializer refuses to
overwrite an existing seed. The Node process does not need host root;
`--user=root` handles Emscripten's emulated UID. Only TCP is enabled.

## Verification

```sh
bash test-port.sh
npm install
source emsdk/emsdk_env.sh
# With a fresh disk server running:
"$EMSDK_NODE" sql-smoke.cjs --test-timer --shutdown
# Restart that same server, then:
"$EMSDK_NODE" sql-smoke.cjs --verify-existing --test-timer --shutdown
# With a fresh MEMFS server running:
MYSQL_PORT=13385 "$EMSDK_NODE" sql-smoke.cjs --test-timer --shutdown
# Restart MEMFS, then verify its changes disappeared:
MYSQL_PORT=13385 "$EMSDK_NODE" memfs-lifecycle.cjs --expect-empty
```

Verified: initialization, InnoDB inserts, commit/rollback, Unicode, query
timeouts, disk persistence, MEMFS reset, and clean shutdown. Low-level probes
cover timers, OpenSSL, signals, and wasm64 address resolution. The full
upstream MySQL suite and concurrency/load testing have not been run.

## Performance

`benchmark.cjs` performs 100 transactions of 10 inserts, followed by 100
aggregate SELECTs, with three samples. Run with `MYSQL_PORT=13384` or `13385`
and the SDK Node. Raw observations are in `benchmark-disk.json` and
`benchmark-memfs.json`.

| Backend | Median writes | Median reads |
| --- | ---: | ---: |
| Disk-backed WASM | 90.6 ms | 168.4 ms |
| MEMFS WASM | 140.3 ms | 224.3 ms |

This small local test showed no MEMFS speedup. Causes have not been profiled.
Both used a clean seed, a 64 MB buffer pool and redo capacity, and no binary
log. MEMFS is useful for disposable databases, not a demonstrated performance
optimization. Observed WASM memory grew to roughly 1 GB, plus MEMFS storage.

## Porting changes and limitations

`patches/mysql-wasm.patch` adds an Emscripten timer backend, cross-build
support, signal handling and shutdown polling, enables tested InnoDB memory
barriers, and fixes a 64-bit varargs pointer sentinel during bootstrap.
`patches/emscripten-wasm64.patch` fixes address-resolution pointer handling.
OpenSSL 3.5.4 is built statically.

Router, NDB, MySQL X, Group Replication, optional authentication clients,
DNS SRV and interactive readline are disabled. Dynamic plugins and CPU
affinity are unsupported. A nonfatal optional component load error and
unavailable Performance Schema CYCLE timer warnings are expected. Browser
operation would require further host integration work.

Upstream source is fetched separately and remains subject to its respective
licenses: MySQL GPLv2 (including applicable exceptions), OpenSSL Apache-2.0,
and Emscripten MIT/University of Illinois-NCSA. Patches retain upstream
context and notices. No upstream binaries or database/key files are vendored.
