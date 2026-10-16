const express = require('express');
const notificacionController = require('../controllers/notificacionController');
const jwt = require('jsonwebtoken');

const router = express.Router();

const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(403).send('Token requerido');
  
  jwt.verify(token, process.env.JWT_SECRET || 'secret_itbm_inventario_v2', (err, decoded) => {
    if (err) return res.status(401).send('Token inválido');
    req.user = decoded;
    next();
  });
};

router.use(verifyToken);

router.get('/', notificacionController.getMisNotificaciones);
router.post('/marcar-leidas', notificacionController.marcarLeidas);

module.exports = router;
