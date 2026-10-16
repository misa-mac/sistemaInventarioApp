const express = require('express');
const usuarioController = require('../controllers/usuarioController');
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

const isAdmin = (req, res, next) => {
  if (req.user && req.user.rol === 'admin') {
    next();
  } else {
    return res.status(403).json({ message: 'Acceso denegado. Se requiere rol de Administrador.' });
  }
};

// All routes here require to be authenticated
router.use(verifyToken);

// You must be admin to manage users
router.use(isAdmin);

router.get('/', usuarioController.getAll);
router.post('/', usuarioController.create);
router.put('/:id', usuarioController.update);
router.delete('/:id', usuarioController.delete);

module.exports = router;
