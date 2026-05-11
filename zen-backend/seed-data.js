const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'zen_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

async function seedData() {
  const connection = await pool.getConnection();
  try {
    console.log('🌱 Iniciando seed de datos de prueba...');

    // Crear usuario de prueba
    const userId = uuidv4();
    await connection.query(
      `INSERT IGNORE INTO users (id, username, email, password_hash, created_at) VALUES (?, ?, ?, ?, NOW())`,
      [userId, 'testuser', 'test@example.com', 'hashed_password']
    );
    console.log('✅ Usuario de prueba creado');

    // Generar tareas con variación de estados y tipos
    const taskStates = ['pending', 'inProgress', 'completed', 'cancelled'];
    const taskTypes = ['work', 'personal', 'sport', 'other'];
    const priorities = ['low', 'medium', 'high', 'urgent'];

    for (let i = 1; i <= 15; i++) {
      const taskId = uuidv4();
      const state = taskStates[i % taskStates.length];
      const type = taskTypes[i % taskTypes.length];
      const priority = priorities[i % priorities.length];
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + (i % 30));

      const completedAt = state === 'completed' ? new Date() : null;

      await connection.query(
        `INSERT INTO tasks (
          id, user_id, title, description, due_date, status, priority, 
          task_type, created_by, created_at, updated_at, completed_at, color
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), ?, ?)`,
        [
          taskId,
          userId,
          `Tarea ${i} (${type})`,
          `Descripción de la tarea ${i} - tipo: ${type}`,
          dueDate,
          state,
          priority,
          type,
          userId,
          completedAt,
          '#6366f1',
        ]
      );
    }
    console.log('✅ 15 tareas variadas creadas');

    // Generar rutinas con rachas
    const routineFrequencies = ['daily', 'weekly'];

    for (let i = 1; i <= 8; i++) {
      const routineId = uuidv4();
      const frequency = routineFrequencies[i % routineFrequencies.length];
      const streak = Math.floor(Math.random() * 30);
      const maxStreak = streak + Math.floor(Math.random() * 20);
      const lastCompleted = streak > 0 ? new Date() : null;

      await connection.query(
        `INSERT INTO routines (
          id, user_id, title, description, frequency, repeat_every_days,
          is_active, created_by, created_at, updated_at,
          current_streak, max_streak, last_completed_date, color
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), ?, ?, ?, ?)`,
        [
          routineId,
          userId,
          `Rutina ${i}`,
          `Descripción de rutina ${i} - frecuencia: ${frequency}`,
          frequency,
          frequency === 'daily' ? 1 : 7,
          i % 3 !== 0, // 2 de cada 3 activas
          userId,
          streak,
          maxStreak,
          lastCompleted,
          i % 2 === 0 ? '#10b981' : '#f59e0b',
        ]
      );
    }
    console.log('✅ 8 rutinas con rachas creadas');

    // Generar objetivos con progreso variado
    for (let i = 1; i <= 6; i++) {
      const goalId = uuidv4();
      const progress = Math.floor(Math.random() * 100);
      const isCompleted = progress >= 100;
      const completedAt = isCompleted ? new Date() : null;

      await connection.query(
        `INSERT INTO goals (
          id, user_id, title, description, category, timeframe,
          start_date, target_date, target_value, current_value, unit,
          is_completed, created_by, created_at, updated_at, completed_at
        ) VALUES (?, ?, ?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 60 DAY), 100, ?, '%', ?, ?, NOW(), NOW(), ?)`,
        [
          goalId,
          userId,
          `Objetivo ${i}`,
          `Descripción del objetivo ${i}`,
          ['health', 'career', 'personal', 'finance'][i % 4],
          ['shortTerm', 'mediumTerm', 'longTerm'][i % 3],
          progress,
          isCompleted,
          userId,
          completedAt,
        ]
      );
    }
    console.log('✅ 6 objetivos variados creados');

    // Generar proyectos
    const projectStates = ['planning', 'active', 'onHold', 'completed'];

    for (let i = 1; i <= 4; i++) {
      const projectId = uuidv4();
      const state = projectStates[i % projectStates.length];
      const completedAt = state === 'completed' ? new Date() : null;

      await connection.query(
        `INSERT INTO projects (
          id, user_id, name, description, status, created_by,
          created_at, updated_at, completed_at, color
        ) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW(), ?, ?)`,
        [
          projectId,
          userId,
          `Proyecto ${i}`,
          `Descripción del proyecto ${i}`,
          state,
          userId,
          completedAt,
          i % 2 === 0 ? '#8b5cf6' : '#ec4899',
        ]
      );
    }
    console.log('✅ 4 proyectos variados creados');

    console.log('✨ Seed de datos completado exitosamente!');
    console.log(`📊 Datos generados para userId: ${userId}`);
    console.log(
      'Use estas credenciales para probar: username: testuser, email: test@example.com'
    );
  } catch (error) {
    console.error('❌ Error en seed:', error);
    throw error;
  } finally {
    await connection.release();
    await pool.end();
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  seedData().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = seedData;
