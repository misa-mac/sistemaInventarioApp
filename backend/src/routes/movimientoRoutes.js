const express = require('express');
const movimientoController = require('../controllers/movimientoController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

router.get('/', auth, authorize('movimientos:listar'), movimientoController.getAll);
router.get('/activo/:activoId', auth, authorize('movimientos:listar'), movimientoController.getByActivo);
router.post('/', auth, authorize('movimientos:crear'), movimientoController.create);
router.post('/:id/revertir', auth, authorize('movimientos:revertir'), movimientoController.revertir);
router.delete('/:id', auth, authorize('movimientos:revertir'), movimientoController.delete);

module.exports = router;
