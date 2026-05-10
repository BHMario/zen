const express = require('express');
const bcrypt = require('bcryptjs');

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

  // Cambiar contraseña
  router.put('/change-password', async (req, res) => {
    try {
      const { userId, oldPassword, newPassword } = req.body;

      if (!userId || !oldPassword || !newPassword) {
        return res.status(400).json({ error: 'Faltan datos requeridos' });
      }

      const connection = await pool.getConnection();

      // Buscar usuario
      const [rows] = await connection.execute(
        'SELECT password FROM users WHERE id = ?',
        [userId]
      );

      if (rows.length === 0) {
        connection.release();
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const user = rows[0];

      // Verificar contraseña antigua
      const passwordMatch = await bcrypt.compare(oldPassword, user.password);

      if (!passwordMatch) {
        connection.release();
        return res.status(401).json({ error: 'La contraseña actual es incorrecta' });
      }

      // Hashear nueva contraseña
      const hashedPassword = await bcrypt.hash(newPassword, 10);

      // Actualizar contraseña
      await connection.execute(
        'UPDATE users SET password = ?, updated_at = NOW() WHERE id = ?',
        [hashedPassword, userId]
      );

      connection.release();

      res.json({ message: 'Contraseña actualizada exitosamente' });
    } catch (error) {
      console.error('❌ Error cambiando contraseña:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
