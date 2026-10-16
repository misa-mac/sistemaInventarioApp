const express = require('express');
const auditoriaController = require('../controllers/auditoriaController');
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

router.get('/', auditoriaController.getAll);
router.get('/ultima', auditoriaController.getUltima);
router.get('/movimientos-recientes', auditoriaController.getMovimientosRecientes);
router.post('/detalles/bulk-delete', auditoriaController.deleteDetallesBulk);
router.delete('/detalles/:detalleId', auditoriaController.deleteDetalle);
router.get('/:id', auditoriaController.getById);
router.post('/', auditoriaController.create);
router.patch('/:id', auditoriaController.finalizar);
router.post('/:id/detalles', auditoriaController.addDetalle);
router.get('/:id/detalles', auditoriaController.getDetalles);

module.exports = router;
