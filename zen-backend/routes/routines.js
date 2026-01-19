const express = require('express');

module.exports = (pool) => {
  const router = express.Router();

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
      const { user_id, title, description, frequency, days_of_week, color, created_by } = req.body;
      if (!user_id || !title) {
        return res.status(400).json({ error: 'user_id y title son requeridos' });
      }

      const { v4: uuidv4 } = require('uuid');
      const routineId = uuidv4();

      const connection = await pool.getConnection();

      // Convert undefined values to null
      const params = [
        routineId,
        user_id,
        title,
        description === undefined ? null : description,
        frequency === undefined ? null : frequency,
        days_of_week ? JSON.stringify(days_of_week) : null,
        color === undefined ? null : color,
        created_by === undefined ? null : created_by
      ];

      console.log('📝 Creando rutina con parámetros:', params);

      await connection.execute(
        `INSERT INTO routines (id, user_id, title, description, frequency, days_of_week, color, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        params
      );

      connection.release();
      res.status(201).json({ message: 'Rutina creada', routineId: routineId });
    } catch (error) {
      console.error('❌ Error creando rutina:', error);
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
