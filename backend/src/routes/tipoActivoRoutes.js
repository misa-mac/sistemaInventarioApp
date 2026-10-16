const express = require('express');
const tipoActivoController = require('../controllers/tipoActivoController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

router.get('/', auth, authorize('tipos:listar'), tipoActivoController.getAll);
router.get('/:id', auth, authorize('tipos:ver'), tipoActivoController.getById);
router.post('/', auth, authorize('tipos:crear'), tipoActivoController.create);
router.put('/:id', auth, authorize('tipos:editar'), tipoActivoController.update);
router.delete('/:id', auth, authorize('tipos:eliminar'), tipoActivoController.delete);

module.exports = router;
