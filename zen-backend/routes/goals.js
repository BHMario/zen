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
      const { user_id, title, description, category, start_date, target_date, target_value, current_value, unit, timeframe, is_completed, color, created_by } = req.body;
      if (!user_id || !title) {
        return res.status(400).json({ error: 'user_id y title son requeridos' });
      }

      const { v4: uuidv4 } = require('uuid');
      const goalId = uuidv4();

      const connection = await pool.getConnection();

      // Validar formato de fechas (deben ser YYYY-MM-DD)
      const validateDateFormat = (dateStr) => {
        if (!dateStr) return true;
        const dateMatch = dateStr.match(/^\d{4}-\d{2}-\d{2}/);
        return dateMatch !== null;
      };

      if (!validateDateFormat(start_date) || !validateDateFormat(target_date)) {
        connection.release();
        return res.status(400).json({ error: 'Las fechas deben estar en formato YYYY-MM-DD' });
      }

      // Extraer solo la fecha (YYYY-MM-DD) si viene con hora
      const extractDate = (dateStr) => {
        if (!dateStr) return null;
        const match = dateStr.match(/^\d{4}-\d{2}-\d{2}/);
        return match ? match[0] : null;
      };
      const params = [
        goalId,
        user_id,
        title,
        description === undefined ? null : description,
        category === undefined ? null : category,
        extractDate(start_date),
        extractDate(target_date),
        target_value !== undefined ? target_value : 1.0,
        current_value !== undefined ? current_value : 0.0,
        unit || '%',
        timeframe || 'mediumTerm',
        is_completed === true || is_completed === 1,
        color === undefined ? null : color,
        created_by || user_id
      ];

      console.log('📝 Creando objetivo con parámetros:', params);

      await connection.execute(
        `INSERT INTO goals (id, user_id, title, description, category, start_date, target_date, target_value, current_value, unit, timeframe, is_completed, color, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
