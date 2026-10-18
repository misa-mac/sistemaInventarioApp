const express = require('express');
const solicitudController = require('../controllers/solicitudController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');
const blockMobileClient = require('../middleware/checkMobileClient');

const router = express.Router();

// Rutas de Solicitudes de Cambio (Gobernanza)
router.post('/', auth, authorize('solicitudes:crear'), solicitudController.create);
router.get('/pendientes-count', auth, authorize('solicitudes:listar'), solicitudController.getPendientesCount);
router.get('/', auth, authorize('solicitudes:listar'), solicitudController.getAll);
router.get('/:id', auth, authorize('solicitudes:ver'), solicitudController.getById);

// Acciones exclusivas de administración web (el cliente móvil recibe 403)
router.post('/:id/aprobar', auth, authorize('solicitudes:aprobar'), blockMobileClient, solicitudController.aprobar);
router.post('/:id/rechazar', auth, authorize('solicitudes:rechazar'), blockMobileClient, solicitudController.rechazar);

module.exports = router;
