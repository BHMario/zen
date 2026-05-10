require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mysql = require('mysql2/promise');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

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

  conn.release();
  console.log('✅ Migraciones completadas');
}).catch(err => {
  console.error('❌ Error conectando a MySQL:', err.message);
});

// Rutas
app.use('/api/auth', require('./routes/auth')(pool));
app.use('/api/tasks', require('./routes/tasks')(pool));
app.use('/api/projects', require('./routes/projects')(pool));
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
