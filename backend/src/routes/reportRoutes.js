const express = require('express');
const reportController = require('../controllers/reportController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

router.get('/', auth, authorize('reportes:ver'), reportController.getSummary);
router.get('/summary', auth, authorize('reportes:ver'), reportController.getSummary);

module.exports = router;
