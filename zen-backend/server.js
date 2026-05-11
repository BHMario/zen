require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mysql = require('mysql2/promise');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Configuración de MySQL
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'zen_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: true, // Retornar fechas como strings para evitar desfases horarios
  timezone: '+00:00'
});

// Verificar conexión a BD y ejecutar migraciones
pool.getConnection().then(async conn => {
  console.log('✅ Conectado a MySQL');

  const migrations = [
    // routines
    'ALTER TABLE routines ADD COLUMN repeat_every_days INT DEFAULT 1',
    'ALTER TABLE routines ADD COLUMN schedule_time VARCHAR(5) DEFAULT NULL',
    'ALTER TABLE routines ADD COLUMN is_active BOOLEAN DEFAULT TRUE',
    'ALTER TABLE routines ADD COLUMN duration_minutes INT DEFAULT NULL',
    'ALTER TABLE routines ADD COLUMN steps TEXT',
    // goals
    'ALTER TABLE goals ADD COLUMN target_value FLOAT DEFAULT 1',
    'ALTER TABLE goals ADD COLUMN current_value FLOAT DEFAULT 0',
    'ALTER TABLE goals ADD COLUMN unit VARCHAR(50) DEFAULT NULL',
    'ALTER TABLE goals ADD COLUMN start_date DATE',
    'ALTER TABLE goals ADD COLUMN is_completed BOOLEAN DEFAULT FALSE',
    // tasks attachments
    'ALTER TABLE tasks ADD COLUMN attachment_url TEXT',
    "ALTER TABLE tasks ADD COLUMN attachment_type VARCHAR(20) DEFAULT NULL",
    'ALTER TABLE tasks ADD COLUMN completed_at DATETIME DEFAULT NULL',
    'ALTER TABLE tasks ADD COLUMN completion_attachment_url TEXT',
    "ALTER TABLE tasks ADD COLUMN completion_attachment_type VARCHAR(20) DEFAULT NULL",
    // task_type
    "ALTER TABLE tasks ADD COLUMN task_type VARCHAR(50) DEFAULT 'other'",
    // projects attachments
    'ALTER TABLE projects ADD COLUMN attachment_url TEXT',
    "ALTER TABLE projects ADD COLUMN attachment_type VARCHAR(20) DEFAULT NULL",
    'ALTER TABLE projects ADD COLUMN completed_at DATETIME DEFAULT NULL',
    'ALTER TABLE projects ADD COLUMN completion_attachment_url TEXT',
    "ALTER TABLE projects ADD COLUMN completion_attachment_type VARCHAR(20) DEFAULT NULL",
    // goals completion
    'ALTER TABLE goals ADD COLUMN completed_at DATETIME DEFAULT NULL',
    'ALTER TABLE goals ADD COLUMN completion_attachment_url TEXT',
    "ALTER TABLE goals ADD COLUMN completion_attachment_type VARCHAR(20) DEFAULT NULL",
    // user privacy/settings columns
    'ALTER TABLE users ADD COLUMN share_analytics BOOLEAN DEFAULT TRUE',
    'ALTER TABLE users ADD COLUMN show_active_status BOOLEAN DEFAULT TRUE',
    'ALTER TABLE users ADD COLUMN app_lock_enabled BOOLEAN DEFAULT FALSE',
    'ALTER TABLE users ADD COLUMN marketing_emails BOOLEAN DEFAULT TRUE',
    'ALTER TABLE users ADD COLUMN profile_private BOOLEAN DEFAULT FALSE',
  ];

  for (const sql of migrations) {
    try {
      await conn.execute(sql);
    } catch (e) {
      // Ignora error de columna duplicada en bases ya migradas
      if (e.code !== 'ER_DUP_FIELDNAME') {
        console.error('⚠️ Error en migración:', e.message);
      }
    }
  }

  try {
    await conn.execute(`
      CREATE TABLE IF NOT EXISTS routine_completions (
        id VARCHAR(36) PRIMARY KEY,
        routine_id VARCHAR(36) NOT NULL,
        user_id VARCHAR(36) NOT NULL,
        completion_date DATE NOT NULL,
        is_completed BOOLEAN DEFAULT TRUE,
        attachment_url TEXT,
        attachment_type VARCHAR(20),
        completed_at DATETIME,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_routine_completion (routine_id, user_id, completion_date),
        FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_date (user_id, completion_date)
      )
    `);
  } catch (e) {
    console.error('⚠️ Error creando routine_completions:', e.message);
  }

  const routineCompletionMigrations = [
    'ALTER TABLE routine_completions ADD COLUMN attachment_url TEXT',
    "ALTER TABLE routine_completions ADD COLUMN attachment_type VARCHAR(20) DEFAULT NULL",
    'ALTER TABLE routine_completions ADD COLUMN completed_at DATETIME DEFAULT NULL',
  ];

  for (const sql of routineCompletionMigrations) {
    try {
      await conn.execute(sql);
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') {
        console.error('⚠️ Error en migración routine_completions:', e.message);
      }
    }
  }

  conn.release();
  console.log('✅ Migraciones completadas');
}).catch(err => {
  console.error('❌ Error conectando a MySQL:', err.message);
});

// Rutas
app.use('/api/auth', require('./routes/auth')(pool));
app.use('/api/tasks', require('./routes/tasks')(pool));
app.use('/api/projects', require('./routes/projects')(pool));
app.use('/api/uploads', require('./routes/uploads')());
app.use('/api/reminders', require('./routes/reminders')(pool));
app.use('/api/routines', require('./routes/routines')(pool));
app.use('/api/goals', require('./routes/goals')(pool));
app.use('/api/users', require('./routes/users')(pool));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message);
  res.status(err.status || 500).json({
    error: err.message || 'Error del servidor'
  });
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
});

module.exports = { pool };
