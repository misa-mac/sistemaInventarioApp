const express = require('express');
const ambienteController = require('../controllers/ambienteController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

router.get('/', auth, authorize('ambientes:listar'), ambienteController.getAll);
router.get('/:id', auth, authorize('ambientes:ver'), ambienteController.getById);
router.post('/', auth, authorize('ambientes:crear'), ambienteController.create);
router.put('/:id', auth, authorize('ambientes:editar'), ambienteController.update);
router.delete('/:id', auth, authorize('ambientes:eliminar'), ambienteController.delete);

module.exports = router;
