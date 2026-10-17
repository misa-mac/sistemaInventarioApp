const express = require('express');
const auditoriaController = require('../controllers/auditoriaController');
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');

const router = express.Router();

// Consultas e historial de auditorías
router.get('/', auth, authorize('auditorias:listar'), auditoriaController.getAll);
router.get('/ultima', auth, authorize('auditorias:ver'), auditoriaController.getUltima);
router.get('/movimientos-recientes', auth, authorize('auditorias:ver'), auditoriaController.getMovimientosRecientes);
router.get('/:id', auth, authorize('auditorias:ver'), auditoriaController.getById);
router.get('/:id/detalles', auth, authorize('auditorias:ver'), auditoriaController.getDetalles);
router.get('/:id/detalle', auth, authorize('auditorias:ver'), auditoriaController.getDetalles);

// Iniciar auditoría
router.post('/', auth, authorize('auditorias:iniciar'), auditoriaController.create);

// Sincronización offline (App Móvil)
router.post('/sync', auth, authorize('auditorias:sync'), auditoriaController.sync);

// Registrar escaneo de activo
router.post('/:id/detalle', auth, authorize('auditorias:detalle'), auditoriaController.addDetalle);
router.post('/:id/detalles', auth, authorize('auditorias:detalle'), auditoriaController.addDetalle);

// Finalizar auditoría
router.patch('/:id/finalizar', auth, authorize('auditorias:finalizar'), auditoriaController.finalizar);
router.patch('/:id', auth, authorize('auditorias:finalizar'), auditoriaController.finalizar);

// Gestión de detalles
router.post('/detalles/bulk-delete', auth, authorize('auditorias:detalle'), auditoriaController.deleteDetallesBulk);
router.delete('/detalles/:detalleId', auth, authorize('auditorias:detalle'), auditoriaController.deleteDetalle);

module.exports = router;
