const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

module.exports = () => {
  const router = express.Router();

  const uploadsDir = path.join(__dirname, '..', 'uploads');
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }

  const storage = multer.diskStorage({
    destination: (_, __, cb) => cb(null, uploadsDir),
    filename: (_, file, cb) => {
      const extension = path.extname(file.originalname || '').toLowerCase();
      cb(null, `${uuidv4()}${extension}`);
    },
  });

  const allowedMime = new Set([
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/webm',
    'video/quicktime',
    'video/x-matroska',
    'video/3gpp',
  ]);

  const allowedExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif', '.mp4', '.webm', '.mov', '.mkv', '.3gp']);

  const upload = multer({
    storage,
    limits: { fileSize: 25 * 1024 * 1024 },
    fileFilter: (_, file, cb) => {
      const extension = path.extname(file.originalname || '').toLowerCase();
      if (allowedMime.has(file.mimetype) || allowedExtensions.has(extension)) {
        cb(null, true);
      } else {
        cb(new Error('Solo se permiten archivos de imagen o video'));
      }
    },
  });

  router.post('/', (req, res) => {
    upload.single('attachment')(req, res, (error) => {
      if (error) {
        const status = error.message === 'File too large' ? 413 : 400;
        return res.status(status).json({ error: error.message });
      }

      try {
        if (!req.file) {
          return res.status(400).json({ error: 'No se recibió ningún archivo' });
        }

        const relativeUrl = `/uploads/${req.file.filename}`;
        const mimetype = req.file.mimetype || '';
        const kind = mimetype.startsWith('image/') || ['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(path.extname(req.file.originalname || '').toLowerCase())
          ? 'image'
          : 'video';

        return res.status(201).json({
          url: relativeUrl,
          kind,
          mimeType: req.file.mimetype,
          fileName: req.file.originalname,
          size: req.file.size,
        });
      } catch (handlerError) {
        return res.status(500).json({ error: handlerError.message });
      }
    });
  });

  return router;
};
