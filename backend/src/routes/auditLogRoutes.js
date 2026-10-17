const express = require('express');
const auditLogController = require('../controllers/auditLogController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

router.post('/', auth, authorize('audit_logs:crear'), auditLogController.create);
router.get('/', auth, authorize('audit_logs:listar'), auditLogController.getAll);

module.exports = router;
