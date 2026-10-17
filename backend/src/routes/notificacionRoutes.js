const express = require('express');
const notificacionController = require('../controllers/notificacionController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

router.get('/', auth, authorize('notificaciones:ver'), notificacionController.getMisNotificaciones);
router.post('/marcar-leidas', auth, authorize('notificaciones:marcar'), notificacionController.marcarLeidas);

module.exports = router;
