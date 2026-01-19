const express = require('express');

module.exports = (pool) => {
  const router = express.Router();

  // Obtener objetivos del usuario
  router.get('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      const [goals] = await connection.execute(
        'SELECT * FROM goals WHERE user_id = ? ORDER BY target_date ASC',
        [userId]
      );

      connection.release();
      res.status(200).json(goals);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Crear objetivo
  router.post('/', async (req, res) => {
    try {
      const { user_id, title, description, category, target_date, progress, status, color, created_by } = req.body;
      if (!user_id || !title) {
        return res.status(400).json({ error: 'user_id y title son requeridos' });
      }

      const { v4: uuidv4 } = require('uuid');
      const goalId = uuidv4();

      const connection = await pool.getConnection();

      // Convert undefined values to null
      const params = [
        goalId,
        user_id,
        title,
        description === undefined ? null : description,
        category === undefined ? null : category,
        target_date === undefined ? null : target_date,
        progress || 0,
        status || 'pending',
        color === undefined ? null : color,
        created_by === undefined ? null : created_by
      ];

      console.log('📝 Creando objetivo con parámetros:', params);

      await connection.execute(
        `INSERT INTO goals (id, user_id, title, description, category, target_date, progress, status, color, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        params
      );

      connection.release();
      res.status(201).json({ message: 'Objetivo creado', goalId: goalId });
    } catch (error) {
      console.error('❌ Error creando objetivo:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Actualizar objetivo
  router.put('/:goalId', async (req, res) => {
    try {
      const { goalId } = req.params;
      const updates = req.body;
      const connection = await pool.getConnection();

      const fields = Object.keys(updates).map(key => `${key} = ?`).join(', ');
      const values = Object.values(updates);
      values.push(goalId);

      await connection.execute(
        `UPDATE goals SET ${fields}, updated_at = NOW() WHERE id = ?`,
        values
      );

      connection.release();
      res.status(200).json({ message: 'Objetivo actualizado' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Eliminar objetivo
  router.delete('/:goalId', async (req, res) => {
    try {
      const { goalId } = req.params;
      const connection = await pool.getConnection();

      await connection.execute('DELETE FROM goals WHERE id = ?', [goalId]);

      connection.release();
      res.status(200).json({ message: 'Objetivo eliminado' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
