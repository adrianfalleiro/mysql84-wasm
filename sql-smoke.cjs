const assert = require('node:assert/strict');
const mysql = require('mysql2/promise');
(async () => {
  const db = await mysql.createConnection({
    host: '127.0.0.1', port: Number(process.env.MYSQL_PORT || 13384), user: 'root', password: '',
    connectTimeout: 10000, charset: 'utf8mb4',
  });
  try {
    const [[version]] = await db.query('SELECT VERSION() AS version');
    assert.equal(version.version, '8.4.13');
    if (!process.argv.includes('--verify-existing')) {
      await db.query('CREATE DATABASE wasm_port_smoke CHARACTER SET utf8mb4');
      await db.query('CREATE TABLE wasm_port_smoke.ledger (id INT PRIMARY KEY, label VARCHAR(64), qty INT) ENGINE=InnoDB');
      await db.query('INSERT INTO wasm_port_smoke.ledger VALUES (?, ?, ?), (?, ?, ?)', [1, 'WASM', 7, 2, 'café 🐬', 11]);
      await db.beginTransaction();
      await db.query('UPDATE wasm_port_smoke.ledger SET qty=99 WHERE id=1');
      await db.rollback();
      await db.beginTransaction();
      await db.query('INSERT INTO wasm_port_smoke.ledger VALUES (3, ?, 5)', ['committed']);
      await db.commit();
    }
    const [rows] = await db.query('SELECT id, label, qty FROM wasm_port_smoke.ledger ORDER BY id');
    assert.deepEqual(rows.map(row => ({...row})), [
      {id: 1, label: 'WASM', qty: 7},
      {id: 2, label: 'café 🐬', qty: 11},
      {id: 3, label: 'committed', qty: 5},
    ]);
    const [[table]] = await db.query("SELECT ENGINE AS engine FROM information_schema.tables WHERE TABLE_SCHEMA='wasm_port_smoke' AND TABLE_NAME='ledger'");
    assert.equal(table.engine, 'InnoDB');
    if (process.argv.includes('--test-timer')) {
      await assert.rejects(db.query({sql: 'SELECT /*+ MAX_EXECUTION_TIME(50) */ SUM(SLEEP(0.2)) FROM wasm_port_smoke.ledger', timeout: 5000}), error => error.errno === 3024);
    }
    console.log(JSON.stringify({version: version.version, engine: table.engine, rows, persisted: process.argv.includes('--verify-existing'), timerVerified: process.argv.includes('--test-timer')}, null, 2));
    if (process.argv.includes('--shutdown')) await db.query('SHUTDOWN');
  } finally {
    await db.end();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
