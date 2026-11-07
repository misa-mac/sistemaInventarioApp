const express = require('express');
const estacionController = require('../controllers/estacionController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

// Rutas con autorización RBAC estricta (Deny-By-Default)
router.get('/', auth, authorize('estaciones:listar'), estacionController.getAll);
router.get('/:codigo', auth, authorize('estaciones:ver'), estacionController.getByCodigo);
router.post('/', auth, authorize('estaciones:crear'), estacionController.create);
router.put('/:id', auth, authorize('estaciones:editar'), estacionController.update);
router.delete('/:id', auth, authorize('estaciones:eliminar'), estacionController.delete);
router.post('/:id/asignar-activos', auth, authorize('estaciones:asignar'), estacionController.asignarActivos);

module.exports = router;

