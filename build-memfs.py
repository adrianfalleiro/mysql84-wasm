#!/usr/bin/env python3
"""Relink existing MySQL objects with MEMFS, preserving the disk build."""
import pathlib, shlex, subprocess
root = pathlib.Path(__file__).resolve().parent
build = root / 'build-wasm64'
lines = subprocess.check_output(['ninja', '-t', 'commands', 'mysqld'], cwd=build, text=True).splitlines()
command = next(line for line in reversed(lines) if ' -o runtime_output_directory/mysqld.js ' in line)
args = shlex.split(command)
assert args[:2] == [':', '&&'] and args[-2:] == ['&&', ':']
args = args[2:-2]
args.remove('-sNODERAWFS=1')
output = root / 'build-memfs'
output.mkdir(exist_ok=True)
args[args.index('-o') + 1] = str(output / 'mysqld.js')
args += ['--pre-js', str(root / 'memfs-pre.js')]
subprocess.run(args, cwd=build, check=True)
