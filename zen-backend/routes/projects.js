const express = require('express');

module.exports = (pool) => {
  const router = express.Router();

  // Obtener proyectos del usuario
  router.get('/:userId', async (req, res) => {
    try {
      const { userId } = req.params;
      const connection = await pool.getConnection();

      const [projects] = await connection.execute(
        'SELECT * FROM projects WHERE user_id = ? ORDER BY start_date DESC',
        [userId]
      );

      connection.release();
      res.status(200).json(projects);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Crear proyecto
  router.post('/', async (req, res) => {
    try {
      const { user_id, name, description, color, start_date, end_date, status, created_by } = req.body;
      if (!user_id || !name) {
        return res.status(400).json({ error: 'user_id y name son requeridos' });
      }

      const { v4: uuidv4 } = require('uuid');
      const projectId = uuidv4();

      const connection = await pool.getConnection();

      // Convert undefined values to null
      const params = [
        projectId,
        user_id,
        name,
        description === undefined ? null : description,
        color === undefined ? null : color,
        start_date === undefined ? null : start_date,
        end_date === undefined ? null : end_date,
        status || 'active',
        created_by === undefined ? null : created_by
      ];

      console.log('📝 Creando proyecto con parámetros:', params);

      await connection.execute(
        `INSERT INTO projects (id, user_id, name, description, color, start_date, end_date, status, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        params
      );

      connection.release();
      res.status(201).json({ message: 'Proyecto creado', projectId: projectId });
    } catch (error) {
      console.error('❌ Error creando proyecto:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Actualizar proyecto
  router.put('/:projectId', async (req, res) => {
    try {
      const { projectId } = req.params;
      const updates = req.body;
      const connection = await pool.getConnection();

      const fields = Object.keys(updates).map(key => `${key} = ?`).join(', ');
      const values = Object.values(updates);
      values.push(projectId);

      await connection.execute(
        `UPDATE projects SET ${fields}, updated_at = NOW() WHERE id = ?`,
        values
      );

      connection.release();
      res.status(200).json({ message: 'Proyecto actualizado' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Eliminar proyecto
  router.delete('/:projectId', async (req, res) => {
    try {
      const { projectId } = req.params;
      const connection = await pool.getConnection();

      await connection.execute('DELETE FROM projects WHERE id = ?', [projectId]);

      connection.release();
      res.status(200).json({ message: 'Proyecto eliminado' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
