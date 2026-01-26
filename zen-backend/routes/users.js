const express = require('express');

module.exports = (pool) => {
  const router = express.Router();

  // Obtener usuario por ID
  router.get('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      const [rows] = await connection.execute(
        'SELECT id, name, email, phone, created_at, updated_at FROM users WHERE id = ?',
        [userId]
      );

      connection.release();

      if (rows.length === 0) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      res.json(rows[0]);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
