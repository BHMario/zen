const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

module.exports = (pool) => {
  const router = express.Router();

  // Registrar usuario
  router.post('/register', async (req, res) => {
    try {
      const { name, email, password, phone, lopd_accepted } = req.body;

      if (!name || !email || !password || !phone) {
        return res.status(400).json({ error: 'Faltan datos requeridos' });
      }

      if (!lopd_accepted) {
        return res.status(400).json({ error: 'Debe aceptar la LOPD' });
      }

      const connection = await pool.getConnection();

      // Verificar si email existe
      const [rows] = await connection.execute(
        'SELECT id FROM users WHERE email = ?',
        [email]
      );

      if (rows.length > 0) {
        connection.release();
        return res.status(400).json({ error: 'Email ya registrado' });
      }

      // Hash contraseña
      const hashedPassword = await bcrypt.hash(password, 10);
      const userId = uuidv4();

      // Insertar usuario
      await connection.execute(
        'INSERT INTO users (id, name, email, password, phone, lopd_accepted) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, name, email, hashedPassword, phone, lopd_accepted ? 1 : 0]
      );

      connection.release();

      // Generar JWT token
      const token = jwt.sign(
        { userId: userId, email: email, name: name },
        process.env.JWT_SECRET || 'zen-secret-key-change-in-production',
        { expiresIn: '7d' }
      );

      res.status(201).json({
        message: 'Usuario registrado exitosamente',
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        token: token
      });
    } catch (error) {
      console.error('❌ Error en registro:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Login usuario
  router.post('/login', async (req, res) => {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Email y contraseña requeridos' });
      }

      const connection = await pool.getConnection();

      // Buscar usuario
      const [rows] = await connection.execute(
        'SELECT id, name, email, password, phone FROM users WHERE email = ?',
        [email]
      );

      connection.release();

      if (rows.length === 0) {
        return res.status(401).json({ error: 'Email o contraseña incorrectos' });
      }

      const user = rows[0];

      // Verificar contraseña
      const passwordMatch = await bcrypt.compare(password, user.password);

      if (!passwordMatch) {
        return res.status(401).json({ error: 'Email o contraseña incorrectos' });
      }

      // Generar JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email, name: user.name },
        process.env.JWT_SECRET || 'zen-secret-key-change-in-production',
        { expiresIn: '7d' }
      );

      res.json({
        message: 'Login exitoso',
        userId: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        token: token
      });
    } catch (error) {
      console.error('❌ Error en login:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
