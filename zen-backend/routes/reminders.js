const express = require('express');

module.exports = (pool) => {
  const router = express.Router();

  // Obtener recordatorios del usuario
  router.get('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      const [reminders] = await connection.execute(
        'SELECT * FROM reminders WHERE created_by = ? ORDER BY date_time ASC',
        [userId]
      );

      connection.release();
      res.status(200).json(reminders);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Crear recordatorio
  router.post('/', async (req, res) => {
    try {
      const { user_id, item_id, type, date_time, frequency, message, is_active, created_by } = req.body;  

      // Usar user_id si created_by no está definido
      const finalUserId = created_by || user_id;

      if (!finalUserId) {
        return res.status(400).json({ error: 'user_id o created_by es requerido' });
      }

      const { v4: uuidv4 } = require('uuid');
      const reminderId = uuidv4();

      const connection = await pool.getConnection();

      // Convert undefined values to null
      const params = [
        reminderId,
        item_id === undefined ? null : item_id,
        type === undefined ? null : type,
        date_time === undefined ? null : date_time,
        frequency === undefined ? null : frequency,
        message === undefined ? null : message,
        is_active !== false,
        finalUserId
      ];

      console.log('📝 Creando recordatorio con parámetros:', params);

      await connection.execute(
        `INSERT INTO reminders (id, item_id, type, date_time, frequency, message, is_active, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        params
      );

      connection.release();
      res.status(201).json({ message: 'Recordatorio creado', reminderId: reminderId });
    } catch (error) {
      console.error('❌ Error creando recordatorio:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Actualizar recordatorio
  router.put('/:reminderId', async (req, res) => {
    try {
      const { reminderId } = req.params;
      const updates = req.body;
      const connection = await pool.getConnection();

      const fields = Object.keys(updates).map(key => `${key} = ?`).join(', ');
      const values = Object.values(updates);
      values.push(reminderId);

      await connection.execute(
        `UPDATE reminders SET ${fields}, updated_at = NOW() WHERE id = ?`,
        values
      );

      connection.release();
      res.status(200).json({ message: 'Recordatorio actualizado' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Eliminar recordatorio
  router.delete('/:reminderId', async (req, res) => {
    try {
      const { reminderId } = req.params;
      const connection = await pool.getConnection();

      await connection.execute('DELETE FROM reminders WHERE id = ?', [reminderId]);

      connection.release();
      res.status(200).json({ message: 'Recordatorio eliminado' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
