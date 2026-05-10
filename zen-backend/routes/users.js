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
        'SELECT id, name, email, phone, share_analytics, show_active_status, app_lock_enabled, created_at, updated_at FROM users WHERE id = ?',
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

  // Actualizar configuración del usuario
  router.put('/:userId/settings', async (req, res) => {
    try {
      const { userId } = req.params;
      const { share_analytics, show_active_status, app_lock_enabled, marketing_emails, profile_private } = req.body;

      const connection = await pool.getConnection();

      await connection.execute(
        'UPDATE users SET share_analytics = ?, show_active_status = ?, app_lock_enabled = ?, marketing_emails = ?, profile_private = ?, updated_at = NOW() WHERE id = ?',
        [
          share_analytics !== undefined ? (share_analytics ? 1 : 0) : 1,
          show_active_status !== undefined ? (show_active_status ? 1 : 0) : 1,
          app_lock_enabled !== undefined ? (app_lock_enabled ? 1 : 0) : 0,
          marketing_emails !== undefined ? (marketing_emails ? 1 : 0) : 1,
          profile_private !== undefined ? (profile_private ? 1 : 0) : 0,
          userId
        ]
      );

      connection.release();

      res.json({ message: 'Configuración actualizada exitosamente' });
    } catch (error) {
      console.error('❌ Error actualizando configuración:', error);
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

  // Exportar todos los datos del usuario como JSON
  router.get('/:userId/export', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      // Obtener datos básicos
      const [userRows] = await connection.execute(
        'SELECT id, name, email, phone, share_analytics, show_active_status, app_lock_enabled, created_at FROM users WHERE id = ?',
        [userId]
      );

      if (userRows.length === 0) {
        connection.release();
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const userData = userRows[0];

      // Obtener tareas, proyectos, objetivos y rutinas
      const [tasks] = await connection.execute('SELECT * FROM tasks WHERE userId = ?', [userId]);
      const [projects] = await connection.execute('SELECT * FROM projects WHERE userId = ?', [userId]);
      const [goals] = await connection.execute('SELECT * FROM goals WHERE userId = ?', [userId]);
      const [routines] = await connection.execute('SELECT * FROM routines WHERE userId = ?', [userId]);

      connection.release();

      const exportPackage = {
        exported_at: new Date().toISOString(),
        user: userData,
        data: {
          tasks,
          projects,
          goals,
          routines
        }
      };

      res.setHeader('Content-disposition', `attachment; filename=zen_data_${userId.substring(0,8)}.json`);
      res.setHeader('Content-type', 'application/json');
      res.send(JSON.stringify(exportPackage, null, 2));

    } catch (error) {
      console.error('❌ Error exportando datos:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Eliminar usuario y todos sus datos
  router.delete('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      // Iniciar transacción para asegurar que todo se borre o nada se borre
      await connection.beginTransaction();

      try {
        // Al usar ON DELETE CASCADE en las tablas relacionadas (tasks, projects, etc.),
        // borrar al usuario debería borrar todo lo demás automáticamente.
        // Pero lo hacemos explícito o confiamos en el cascade.
        const [result] = await connection.execute(
          'DELETE FROM users WHERE id = ?',
          [userId]
        );

        if (result.affectedRows === 0) {
          await connection.rollback();
          connection.release();
          return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        await connection.commit();
        connection.release();

        res.json({ message: 'Cuenta y datos eliminados permanentemente' });
      } catch (error) {
        await connection.rollback();
        connection.release();
        throw error;
      }
    } catch (error) {
      console.error('❌ Error eliminando usuario:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
