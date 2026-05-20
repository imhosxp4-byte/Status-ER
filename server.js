/**
 * ER Status — Backend API Server
 * รองรับ MySQL และ PostgreSQL
 * เริ่มด้วย: node server.js  (หรือ start.bat)
 */

const express = require('express');
const fs      = require('fs');
const path    = require('path');
const cors    = require('cors');

const app           = express();
const PORT          = 4000;
const CONFIG_FILE   = path.join(__dirname, 'config.json');
const DEFAULTS_FILE = path.join(__dirname, 'user-defaults.json');

app.use(cors());
app.use(express.json());
app.use(express.static(__dirname)); /* serve HTML files */

/* ══════════════════════════════════════════════
   HELPERS
══════════════════════════════════════════════ */

function loadConfig() {
  try   { return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')); }
  catch { return null; }
}

/**
 * Run a query using a one-shot connection.
 * Works for both MySQL and PostgreSQL.
 */
async function runQuery(cfg, sql, params = []) {
  if (cfg.dbType === 'mysql') {
    const mysql = require('mysql2/promise');
    const conn  = await mysql.createConnection({
      host: cfg.host, port: parseInt(cfg.port),
      database: cfg.database,
      user: cfg.username, password: cfg.password,
      connectTimeout: 8000,
    });
    const [rows] = await conn.query(sql, params);
    await conn.end();
    return rows;

  } else {
    const { Client } = require('pg');
    const client = new Client({
      host: cfg.host, port: parseInt(cfg.port),
      database: cfg.database,
      user: cfg.username, password: cfg.password,
      connectionTimeoutMillis: 8000,
    });
    await client.connect();
    const result = await client.query(sql, params);
    await client.end();
    return result.rows;
  }
}

/* ══════════════════════════════════════════════
   ROUTES
══════════════════════════════════════════════ */

/* ── GET  /api/defaults — load saved display defaults ── */
app.get('/api/defaults', (req, res) => {
  try {
    if (fs.existsSync(DEFAULTS_FILE)) {
      res.json({ ok: true, defaults: JSON.parse(fs.readFileSync(DEFAULTS_FILE, 'utf8')) });
    } else {
      res.json({ ok: true, defaults: null });
    }
  } catch { res.json({ ok: true, defaults: null }); }
});

/* ── POST /api/defaults — save display defaults to file ── */
app.post('/api/defaults', (req, res) => {
  try {
    fs.writeFileSync(DEFAULTS_FILE, JSON.stringify(req.body, null, 2));
    console.log('[Defaults] Saved display defaults');
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

/* ── GET  /api/status — server health check ── */
app.get('/api/status', (req, res) => {
  const cfg = loadConfig();
  res.json({
    ok: true,
    configured: !!cfg,
    dbType: cfg?.dbType || null,
    host:   cfg?.host   || null,
  });
});

/* ── POST /api/config — save DB config to file ── */
app.post('/api/config', (req, res) => {
  try {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(req.body, null, 2));
    console.log(`[Config] Saved — ${req.body.dbType} @ ${req.body.host}:${req.body.port}`);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

/* ── POST /api/test — test DB connection ── */
app.post('/api/test', async (req, res) => {
  try {
    const cfg = req.body;
    await runQuery(cfg, 'SELECT 1');
    console.log(`[Test] OK — ${cfg.dbType} @ ${cfg.host}:${cfg.port}`);
    res.json({ ok: true, message: 'เชื่อมต่อสำเร็จ' });
  } catch (err) {
    console.error(`[Test] FAIL — ${err.message}`);
    res.status(400).json({ ok: false, message: err.message });
  }
});

/* ── GET /api/er-data — ER patient list (today) ── */
app.get('/api/er-data', async (req, res) => {
  const cfg = loadConfig();
  if (!cfg) {
    return res.status(503).json({ ok: false, error: 'ยังไม่ได้ตั้งค่าฐานข้อมูล กรุณาตั้งค่าก่อน' });
  }

  const isMySQL = cfg.dbType === 'mysql';

  /* ── SQL — ตรงกับ query ที่ใช้งานได้จริงใน HOSxP ── */
  const sql = isMySQL ? `
    SELECT
      TIME(e.enter_er_time)                              AS enter_time,
      CONCAT(p.pname, p.fname, ' ', p.lname)             AS pt_name,
      el.er_leave_status_name                             AS status_name,
      o.hn                                                AS hn,
      IFNULL(e.er_emergency_type, 5)                      AS triage_level,
      o.vn                                                AS vn,
      COALESCE(el.leave, '')                              AS leave_flag
    FROM ovst o
    LEFT JOIN er_regist e          ON e.vn  = o.vn
    LEFT JOIN patient p            ON p.hn  = o.hn
    LEFT JOIN er_emergency_type ep ON ep.er_emergency_type = e.er_emergency_type
    LEFT JOIN er_leave_status el   ON el.er_leave_status_id = e.er_leave_status_id
    LEFT JOIN ovstist os           ON os.ovstist = o.ovstist
    WHERE e.vstdate = CURDATE()
    ORDER BY e.er_emergency_type ASC, e.enter_er_time ASC
  ` : `
    SELECT
      e.enter_er_time::time                              AS enter_time,
      CONCAT(p.pname, p.fname, ' ', p.lname)             AS pt_name,
      el.er_leave_status_name                             AS status_name,
      o.hn                                                AS hn,
      COALESCE(
        NULLIF(TRIM(CAST(e.er_emergency_type AS text)), '')::int,
        5
      )                                                   AS triage_level,
      o.vn                                                AS vn,
      COALESCE(el.leave::text, '')                        AS leave_flag
    FROM ovst o
    LEFT JOIN er_regist e          ON e.vn  = o.vn
    LEFT JOIN patient p            ON p.hn  = o.hn
    LEFT JOIN er_emergency_type ep ON ep.er_emergency_type = e.er_emergency_type
    LEFT JOIN er_leave_status el   ON el.er_leave_status_id = e.er_leave_status_id
    LEFT JOIN ovstist os           ON os.ovstist = o.ovstist
    WHERE e.vstdate = CURRENT_DATE
    ORDER BY e.er_emergency_type ASC, e.enter_er_time ASC
  `;

  try {
    const [rows, nameRows] = await Promise.all([
      runQuery(cfg, sql),
      runQuery(cfg, 'SELECT hospitalname FROM opdconfig LIMIT 1').catch(() => []),
    ]);
    const hospitalName = (nameRows[0]?.hospitalname || '').trim();
    console.log(`[ER Data] ${rows.length} rows | รพ.: ${hospitalName || '-'}`);
    res.json({ ok: true, data: rows, count: rows.length, hospitalName, ts: Date.now() });
  } catch (err) {
    console.error(`[ER Data] ERROR — ${err.message}`);
    res.status(500).json({ ok: false, error: err.message });
  }
});

/* ── GET /api/er-leave-summary — สรุปสถานะออกจาก ER วันนี้ ── */
app.get('/api/er-leave-summary', async (req, res) => {
  const cfg = loadConfig();
  if (!cfg) return res.status(503).json({ ok: false, error: 'ยังไม่ได้ตั้งค่าฐานข้อมูล' });

  const isMySQL = cfg.dbType === 'mysql';
  const sql = isMySQL ? `
    SELECT
      COALESCE(el.er_leave_status_name, 'ไม่ระบุ')  AS status_name,
      COALESCE(el.leave, '')                          AS leave_flag,
      COUNT(*)                                        AS cnt
    FROM ovst o
    LEFT JOIN er_regist e       ON e.vn  = o.vn
    LEFT JOIN er_leave_status el ON el.er_leave_status_id = e.er_leave_status_id
    WHERE e.vstdate = CURDATE()
    GROUP BY el.er_leave_status_name, el.leave
    ORDER BY (el.leave = 'Y') ASC, cnt DESC
  ` : `
    SELECT
      COALESCE(el.er_leave_status_name, 'ไม่ระบุ')  AS status_name,
      COALESCE(el.leave::text, '')                    AS leave_flag,
      COUNT(*)                                        AS cnt
    FROM ovst o
    LEFT JOIN er_regist e        ON e.vn  = o.vn
    LEFT JOIN er_leave_status el ON el.er_leave_status_id = e.er_leave_status_id
    WHERE e.vstdate = CURRENT_DATE
    GROUP BY el.er_leave_status_name, el.leave
    ORDER BY (el.leave = 'Y') ASC NULLS FIRST, cnt DESC
  `;

  try {
    const rows = await runQuery(cfg, sql);
    console.log(`[Leave Summary] ${rows.length} status groups`);
    res.json({ ok: true, data: rows });
  } catch (err) {
    console.error(`[Leave Summary] ERROR — ${err.message}`);
    res.status(500).json({ ok: false, error: err.message });
  }
});

/* ══════════════════════════════════════════════
   START
══════════════════════════════════════════════ */
app.listen(PORT, () => {
  console.log('');
  console.log(' ╔══════════════════════════════════╗');
  console.log(' ║   🏥  ER Status Server  v1.0     ║');
  console.log(` ║   http://localhost:${PORT}          ║`);
  console.log(' ╚══════════════════════════════════╝');
  console.log('');
  const cfg = loadConfig();
  if (cfg) {
    console.log(` ✅ DB Config: ${cfg.dbType?.toUpperCase()} @ ${cfg.host}:${cfg.port}`);
  } else {
    console.log(' ⚠  ยังไม่มี config.json — กรุณาตั้งค่าการเชื่อมต่อก่อน');
  }
  console.log('');
});
