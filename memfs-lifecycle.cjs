const mysql = require('mysql2/promise');
const assert = require('node:assert/strict');
(async () => {
  const db=await mysql.createConnection({host:'127.0.0.1',port:Number(process.env.MYSQL_PORT),user:'root'});
  try {
    if(process.argv.includes('--expect-empty')) {
      const [rows]=await db.query("SELECT SCHEMA_NAME FROM information_schema.schemata WHERE SCHEMA_NAME IN ('wasm_port_smoke','memfs_benchmark')");
      assert.deepEqual(rows,[]);
      console.log('PASS: test databases disappeared after MEMFS process restart');
    }
    await db.query('SHUTDOWN');
  } finally {await db.end();}
})().catch(e=>{console.error(e);process.exitCode=1});
