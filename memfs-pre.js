// Seed once from host files; all MySQL filesystem operations then use MEMFS.
Module['preRun'] = Module['preRun'] || [];
Module['preRun'].push(function () {
  if (ENVIRONMENT_IS_PTHREAD) return;
  const hostFs = require('node:fs');
  const path = require('node:path');
  const root = path.resolve(__dirname, '..');
  function copyTree(source, destination) {
    FS.mkdirTree(destination);
    for (const entry of hostFs.readdirSync(source, {withFileTypes: true})) {
      const from = path.join(source, entry.name);
      const to = destination + '/' + entry.name;
      if (entry.isDirectory()) copyTree(from, to);
      else if (entry.isFile()) { FS.writeFile(to, hostFs.readFileSync(from)); FS.chmod(to, 0o600); }
      else throw new Error('Unsupported seed entry: ' + from);
    }
  }
  copyTree(path.join(root, 'memfs-seed'), '/mysql/data');
  copyTree(path.join(root, 'build-wasm64/share'), '/mysql/share');
  FS.mkdirTree('/mysql/run');
  console.error('MySQL MEMFS: seed loaded; database writes are volatile.');
});
