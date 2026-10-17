const express = require('express');
const usuarioController = require('../controllers/usuarioController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

router.get('/', auth, authorize('usuarios:gestionar'), usuarioController.getAll);
router.post('/', auth, authorize('usuarios:gestionar'), usuarioController.create);
router.put('/:id', auth, authorize('usuarios:gestionar'), usuarioController.update);
router.delete('/:id', auth, authorize('usuarios:gestionar'), usuarioController.delete);

module.exports = router;
