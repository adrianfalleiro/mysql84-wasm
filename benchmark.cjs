const mysql = require('mysql2/promise');
const assert = require('node:assert/strict');
const {performance} = require('node:perf_hooks');
(async () => {
  const db = await mysql.createConnection({host:'127.0.0.1',port:Number(process.env.MYSQL_PORT),user:'root'});
  const samples=[];
  try {
    for(let run=0;run<3;run++) {
      await db.query('CREATE DATABASE IF NOT EXISTS memfs_benchmark');
      await db.query('DROP TABLE IF EXISTS memfs_benchmark.rows_test');
      await db.query('CREATE TABLE memfs_benchmark.rows_test (id INT PRIMARY KEY, payload VARCHAR(256)) ENGINE=InnoDB');
      let started=performance.now();
      for(let i=0;i<100;i++) {
        await db.beginTransaction();
        await db.query('INSERT INTO memfs_benchmark.rows_test VALUES ?', [Array.from({length:10},(_,j)=>[i*10+j,'x'.repeat(200)])]);
        await db.commit();
      }
      const writeMs=performance.now()-started;
      started=performance.now();
      for(let i=0;i<100;i++) {
        const [[row]]=await db.query('SELECT COUNT(*) AS n, SUM(id) AS total FROM memfs_benchmark.rows_test');
        assert.equal(row.n,1000);assert.equal(Number(row.total),499500);
      }
      samples.push({writeMs,readMs:performance.now()-started});
    }
    console.log(JSON.stringify({port:process.env.MYSQL_PORT,transactions:100,rows:1000,reads:100,samples},null,2));
  } finally { await db.end(); }
})().catch(e=>{console.error(e);process.exitCode=1});
