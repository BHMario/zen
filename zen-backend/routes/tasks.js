const express = require('express');

module.exports = (pool) => {
  const router = express.Router();

  // Obtener todas las tareas del usuario
  router.get('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      const [tasks] = await connection.execute(
        `SELECT * FROM tasks WHERE user_id = ? ORDER BY due_date ASC`,
        [userId]
      );

      connection.release();
      res.status(200).json(tasks);
    } catch (error) {
      console.error('❌ Error obteniendo tareas:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Crear tarea
  router.post('/', async (req, res) => {
    try {
      const {
        user_id,
        title,
        description,
        due_date,
        status,
        priority,
        project_id,
        color,
        labels,
        created_by
      } = req.body;

      if (!user_id || !title) {
        return res.status(400).json({ error: 'user_id y title son requeridos' });
      }

      const { v4: uuidv4 } = require('uuid');
      const taskId = uuidv4();

      const connection = await pool.getConnection();

      // Convert all undefined values to null
      const params = [
        taskId,
        user_id,
        title,
        description === undefined ? null : description,
        due_date === undefined ? null : due_date,
        status || 'pending',
        priority || 'medium',
        project_id === undefined ? null : project_id,
        color === undefined ? null : color,
        labels ? JSON.stringify(labels) : null,
        created_by || user_id // Usar user_id como default si created_by no se proporciona
      ];

      console.log('📝 Creando tarea con parámetros:', params);

      await connection.execute(
        `INSERT INTO tasks (id, user_id, title, description, due_date, status, priority, project_id, color, labels, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        params
      );

      connection.release();
      res.status(201).json({ message: 'Tarea creada', taskId: taskId });
    } catch (error) {
      console.error('❌ Error creando tarea:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Actualizar tarea
  router.put('/:taskId', async (req, res) => {
    try {
      const { taskId } = req.params;
      const updates = req.body;

      const connection = await pool.getConnection();

      const fields = Object.keys(updates)
        .map(key => `${key} = ?`)
        .join(', ');

      const values = Object.values(updates);
      values.push(taskId);

      await connection.execute(
        `UPDATE tasks SET ${fields}, updated_at = NOW() WHERE id = ?`,
        values
      );

      connection.release();
      res.status(200).json({ message: 'Tarea actualizada' });
    } catch (error) {
      console.error('❌ Error actualizando tarea:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Eliminar tarea
  router.delete('/:taskId', async (req, res) => {
    try {
      const { taskId } = req.params;
      const connection = await pool.getConnection();

      await connection.execute('DELETE FROM tasks WHERE id = ?', [taskId]);

      connection.release();
      res.status(200).json({ message: 'Tarea eliminada' });
    } catch (error) {
      console.error('❌ Error eliminando tarea:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
