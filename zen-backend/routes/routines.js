const express = require('express');

module.exports = (pool) => {
  const router = express.Router();

  // Obtener completados de rutinas del usuario
  router.get('/:userId/completions', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      const [rows] = await connection.execute(
        'SELECT routine_id, completion_date FROM routine_completions WHERE user_id = ? AND is_completed = 1',
        [userId]
      );

      connection.release();
      res.status(200).json(rows);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Obtener rutinas del usuario
  router.get('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      const [routines] = await connection.execute(
        'SELECT * FROM routines WHERE user_id = ?',
        [userId]
      );

      connection.release();
      res.status(200).json(routines);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Crear rutina
  router.post('/', async (req, res) => {
    try {
      const { user_id, title, description, frequency, days_of_week, color, created_by, repeat_every_days, schedule_time, is_active, duration_minutes, steps } = req.body;
      if (!user_id || !title) {
        return res.status(400).json({ error: 'user_id y title son requeridos' });
      }

      const { v4: uuidv4 } = require('uuid');
      const routineId = uuidv4();

      const connection = await pool.getConnection();

      const params = [
        routineId,
        user_id,
        title,
        description === undefined ? null : description,
        frequency === undefined ? null : frequency,
        days_of_week ? JSON.stringify(days_of_week) : null,
        color === undefined ? null : color,
        created_by || user_id,
        repeat_every_days !== undefined ? repeat_every_days : 1,
        schedule_time === undefined ? null : schedule_time,
        is_active !== undefined ? is_active : true,
        duration_minutes === undefined ? null : duration_minutes,
        Array.isArray(steps) ? JSON.stringify(steps) : null,
      ];

      console.log('📝 Creando rutina con parámetros:', params);

      await connection.execute(
        `INSERT INTO routines (id, user_id, title, description, frequency, days_of_week, color, created_by, repeat_every_days, schedule_time, is_active, duration_minutes, steps)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        params
      );

      connection.release();
      res.status(201).json({ message: 'Rutina creada', routineId: routineId });
    } catch (error) {
      console.error('❌ Error creando rutina:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Marcar/desmarcar rutina como completada en un día concreto
  router.post('/:routineId/completions', async (req, res) => {
    try {
      const { routineId } = req.params;
      const { user_id, completion_date, completed } = req.body;

      if (!user_id || !completion_date) {
        return res.status(400).json({ error: 'user_id y completion_date son requeridos' });
      }

      const connection = await pool.getConnection();

      if (completed === false || completed === 0) {
        await connection.execute(
          'DELETE FROM routine_completions WHERE routine_id = ? AND user_id = ? AND completion_date = ?',
          [routineId, user_id, completion_date]
        );
      } else {
        await connection.execute(
          `INSERT INTO routine_completions (id, routine_id, user_id, completion_date, is_completed)
           VALUES (UUID(), ?, ?, ?, 1)
           ON DUPLICATE KEY UPDATE is_completed = VALUES(is_completed)`,
          [routineId, user_id, completion_date]
        );
      }

      connection.release();
      res.status(200).json({ message: 'Estado diario de rutina actualizado' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Actualizar rutina
  router.put('/:routineId', async (req, res) => {
    try {
      const { routineId } = req.params;
      const updates = req.body;
      const connection = await pool.getConnection();

      const fields = Object.keys(updates).map(key => `${key} = ?`).join(', ');
      const values = Object.values(updates);
      values.push(routineId);

      await connection.execute(
        `UPDATE routines SET ${fields}, updated_at = NOW() WHERE id = ?`,
        values
      );

      connection.release();
      res.status(200).json({ message: 'Rutina actualizada' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Eliminar rutina
  router.delete('/:routineId', async (req, res) => {
    try {
      const { routineId } = req.params;
      const connection = await pool.getConnection();

      await connection.execute('DELETE FROM routines WHERE id = ?', [routineId]);

      connection.release();
      res.status(200).json({ message: 'Rutina eliminada' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
