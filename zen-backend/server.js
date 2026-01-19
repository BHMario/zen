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
  queueLimit: 0
});

// Verificar conexión a BD
pool.getConnection().then(conn => {
  console.log('✅ Conectado a MySQL');
  conn.release();
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
