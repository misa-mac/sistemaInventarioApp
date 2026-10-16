const express = require('express');
const inventoryController = require('../controllers/inventoryController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');
const upload = require('../middleware/upload');

const router = express.Router();

// Rutas de Activos / Inventario con autorización RBAC estricta
router.get('/', auth, authorize('activos:listar'), inventoryController.getAll);
router.get('/next-sequence', auth, authorize('activos:crear'), inventoryController.getNextSequence);
router.get('/ultimo', auth, authorize('activos:ver'), inventoryController.getUltimo);
router.get('/search/:q', auth, authorize('activos:ver'), inventoryController.getBySearch);
router.get('/:id', auth, authorize('activos:ver'), inventoryController.getById);

router.post('/', auth, authorize('activos:crear'), upload.single('imagen'), inventoryController.create);
router.put('/:id', auth, authorize('activos:editar'), upload.single('imagen'), inventoryController.update);
router.delete('/:id', auth, authorize('activos:eliminar'), inventoryController.delete);

module.exports = router;
