// Archivo para inicializar la BD con todas las tablas
require('dotenv').config();
const mysql = require('mysql2/promise');

const initializeDatabase = async () => {
  let connection;
  try {
    // Conectar sin seleccionar BD
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || ''
    });

    console.log('✅ Conectado a MySQL');

    // Crear BD si no existe (sin prepared statement)
    await connection.query(`CREATE DATABASE IF NOT EXISTS zen_db;`);
    console.log('✅ Base de datos zen_db lista');

    // Seleccionar BD
    await connection.query(`USE zen_db;`);

    // Tabla de usuarios
    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        lopd_accepted BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Tabla users creada');

    // Tabla de proyectos (fechas como DATE, no DATETIME - para evitar problemas de zona horaria)
    // Debe crearse ANTES de tasks porque tasks la referencia
    await connection.query(`
      CREATE TABLE IF NOT EXISTS projects (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        color VARCHAR(7) DEFAULT '#3B82F6',
        start_date DATE,
        end_date DATE,
        status VARCHAR(50) DEFAULT 'active',
        created_by VARCHAR(36) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_start_date (start_date),
        INDEX idx_end_date (end_date)
      );
    `);
    console.log('✅ Tabla projects creada');

    // Tabla de tareas (due_date como DATE para consistencia)
    await connection.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        due_date DATE,
        status VARCHAR(50) DEFAULT 'pending',
        priority VARCHAR(50) DEFAULT 'medium',
        project_id VARCHAR(36),
        color VARCHAR(7) DEFAULT '#6366F1',
        labels TEXT,
        estimated_hours INT,
        actual_hours INT,
        created_by VARCHAR(36) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_due_date (due_date),
        INDEX idx_project_id (project_id)
      );
    `);
    console.log('✅ Tabla tasks creada');

    // Tabla de recordatorios
    await connection.query(`
      CREATE TABLE IF NOT EXISTS reminders (
        id VARCHAR(36) PRIMARY KEY,
        item_id VARCHAR(36) NOT NULL,
        type VARCHAR(50) NOT NULL,
        date_time DATETIME NOT NULL,
        frequency VARCHAR(50) DEFAULT 'once',
        message TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_by VARCHAR(36) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_item_id (item_id),
        INDEX idx_date_time (date_time)
      );
    `);
    console.log('✅ Tabla reminders creada');

    // Tabla de rutinas
    await connection.query(`
      CREATE TABLE IF NOT EXISTS routines (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        frequency VARCHAR(50) NOT NULL,
        days_of_week VARCHAR(255),
        color VARCHAR(7) DEFAULT '#10B981',
        is_active BOOLEAN DEFAULT TRUE,
        schedule_time VARCHAR(5),
        duration_minutes INT,
        created_by VARCHAR(36) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id)
      );
    `);
    console.log('✅ Tabla routines creada');

    // Tabla de objetivos
    await connection.query(`
      CREATE TABLE IF NOT EXISTS goals (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        start_date DATE,
        target_date DATE,
        target_value DECIMAL(10,2) DEFAULT 1.0,
        current_value DECIMAL(10,2) DEFAULT 0.0,
        unit VARCHAR(50) DEFAULT 'unidades',
        timeframe VARCHAR(50) DEFAULT 'mediumTerm',
        is_completed BOOLEAN DEFAULT FALSE,
        color VARCHAR(7) DEFAULT '#F59E0B',
        created_by VARCHAR(36) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_start_date (start_date),
        INDEX idx_target_date (target_date)
      );
    `);
    console.log('✅ Tabla goals creada');

    console.log('✅ Todas las tablas inicializadas correctamente');
    await connection.end();
  } catch (error) {
    console.error('❌ Error inicializando BD:', error.message);
    await connection.end();
    throw error;
  }
};

// Ejecutar inicialización
initializeDatabase()
  .then(() => {
    console.log('✅ Inicialización completada');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Error:', err.message);
    process.exit(1);
  });

module.exports = { initializeDatabase };
