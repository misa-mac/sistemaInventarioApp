const Auditoria = require('../models/Auditoria');
const DetalleAuditoria = require('../models/DetalleAuditoria');
const Ambiente = require('../models/Ambiente');
const Usuario = require('../models/Usuario');
const Activo = require('../models/Activo');
const { Op } = require('sequelize');

exports.create = async (req, res) => {
  try {
    const { ambiente_id, total_esperados, observaciones, tecnico_id, auditor_id } = req.body;
    let finalAuditorId = req.user?.id;
    if (req.user?.rol === 'admin' && (auditor_id || tecnico_id)) {
      finalAuditorId = auditor_id || tecnico_id;
    }

    if (!ambiente_id) {
      return res.status(400).json({ message: 'ambiente_id es requerido' });
    }

    const nueva = await Auditoria.create({
      ambiente_id,
      auditor_id: finalAuditorId,
      total_esperados: total_esperados || 0,
      total_encontrados: 0,
      total_faltantes: 0,
      total_no_esperados: 0,
      estado: 'en_progreso',
      observaciones: observaciones || null,
      fecha_inicio: new Date()
    });

    const creada = await Auditoria.findByPk(nueva.id, {
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo'] },
        { model: Usuario, as: 'auditor', attributes: ['id', 'nombre_completo', 'email'] }
      ]
    });

    res.status(201).json(creada);
  } catch (error) {
    console.error('Error al crear auditoría:', error);
    res.status(500).json({ message: 'Error al crear auditoría: ' + error.message });
  }
};

exports.getAll = async (req, res) => {
  try {
    const { ambiente_id, auditor_id, tecnico_id, estado, fecha, limit } = req.query;
    const where = {};

    if (ambiente_id) where.ambiente_id = ambiente_id;
    if (auditor_id || tecnico_id) where.auditor_id = auditor_id || tecnico_id;
    if (estado) where.estado = estado;

    if (fecha) {
      const start = new Date(fecha);
      start.setHours(0, 0, 0, 0);
      const end = new Date(fecha);
      end.setHours(23, 59, 59, 999);
      where.fecha_inicio = { [Op.between]: [start, end] };
    }

    const auditorias = await Auditoria.findAll({
      where,
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo'] },
        { model: Usuario, as: 'auditor', attributes: ['id', 'nombre_completo', 'email'] }
      ],
      order: [['fecha_inicio', 'DESC']],
      limit: limit ? parseInt(limit) : undefined
    });

    res.json(auditorias);
  } catch (error) {
    console.error('Error al listar auditorías:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getUltima = async (req, res) => {
  try {
    const ultima = await Auditoria.findOne({
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo'] },
        { model: Usuario, as: 'auditor', attributes: ['id', 'nombre_completo', 'email'] }
      ],
      order: [['created_at', 'DESC']]
    });

    res.json(ultima || null);
  } catch (error) {
    console.error('Error al obtener última auditoría:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getById = async (req, res) => {
  try {
    const auditoria = await Auditoria.findByPk(req.params.id, {
      include: [
        { model: Ambiente, as: 'ambiente' },
        { model: Usuario, as: 'auditor', attributes: ['id', 'nombre_completo', 'email'] },
        {
          model: DetalleAuditoria,
          as: 'detalles',
          include: [{ model: Activo, as: 'activo' }]
        }
      ]
    });

    if (!auditoria) return res.status(404).json({ message: 'Auditoría no encontrada' });
    res.json(auditoria);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.finalizar = async (req, res) => {
  try {
    const { id } = req.params;
    const { total_encontrados, total_faltantes, total_no_esperados, observaciones, estado } = req.body;

    const auditoria = await Auditoria.findByPk(id);
    if (!auditoria) return res.status(404).json({ message: 'Auditoría no encontrada' });

    await auditoria.update({
      total_encontrados: total_encontrados !== undefined ? total_encontrados : auditoria.total_encontrados,
      total_faltantes: total_faltantes !== undefined ? total_faltantes : auditoria.total_faltantes,
      total_no_esperados: total_no_esperados !== undefined ? total_no_esperados : auditoria.total_no_esperados,
      observaciones: observaciones !== undefined ? observaciones : auditoria.observaciones,
      estado: estado || 'completada',
      fecha_fin: new Date()
    });

    res.json(auditoria);
  } catch (error) {
    console.error('Error al finalizar auditoría:', error);
    res.status(500).json({ message: 'Error al finalizar auditoría: ' + error.message });
  }
};

exports.addDetalle = async (req, res) => {
  try {
    const { id } = req.params; // auditoria_id
    let { activo_id, codigo_qr_escaneado, estado, observacion, fecha_escaneo } = req.body;

    const auditoria = await Auditoria.findByPk(id);
    if (!auditoria) return res.status(404).json({ message: 'Auditoría no encontrada' });

    let normEstado = (estado || 'presente').toString().toLowerCase().trim();
    if (!['presente', 'faltante', 'no_esperado'].includes(normEstado)) {
      normEstado = 'presente';
    }

    // Si falta codigo_qr_escaneado y tenemos activo_id, buscarlo
    if (!codigo_qr_escaneado && activo_id) {
      const act = await Activo.findByPk(activo_id);
      if (act) codigo_qr_escaneado = act.codigo_activo;
    }

    // Si falta activo_id y tenemos codigo_qr_escaneado (y no es no_esperado)
    if (!activo_id && codigo_qr_escaneado && normEstado !== 'no_esperado') {
      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(codigo_qr_escaneado);
      const act = await Activo.findOne({
        where: isUuid
          ? { [Op.or]: [{ id: codigo_qr_escaneado }, { codigo_activo: codigo_qr_escaneado }] }
          : { codigo_activo: codigo_qr_escaneado }
      });
      if (act) {
        activo_id = act.id;
        codigo_qr_escaneado = act.codigo_activo;
      }
    }

    // Salvaguarda para constraints de PostgreSQL:
    // Si normEstado !== 'no_esperado' y no hay activo_id, clasificar como no_esperado
    if (normEstado !== 'no_esperado' && !activo_id) {
      normEstado = 'no_esperado';
    }
    // Si normEstado !== 'faltante' y no hay codigo_qr_escaneado
    if (normEstado !== 'faltante' && !codigo_qr_escaneado) {
      codigo_qr_escaneado = 'SIN_CODIGO';
    }

    const detalle = await DetalleAuditoria.create({
      auditoria_id: id,
      activo_id: activo_id || null,
      codigo_qr_escaneado: codigo_qr_escaneado || null,
      estado: normEstado,
      observacion: observacion || null,
      fecha_escaneo: fecha_escaneo ? new Date(fecha_escaneo) : new Date(),
      sincronizado: true
    });

    res.status(201).json(detalle);
  } catch (error) {
    console.error('Error al registrar detalle de auditoría:', error);
    res.status(500).json({ message: 'Error al registrar detalle: ' + error.message });
  }
};

exports.getDetalles = async (req, res) => {
  try {
    const { id } = req.params;
    const detalles = await DetalleAuditoria.findAll({
      where: { auditoria_id: id },
      include: [{ model: Activo, as: 'activo' }],
      order: [['fecha_escaneo', 'DESC']]
    });

    res.json(detalles);
  } catch (error) {
    console.error('Error al obtener detalles:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.deleteDetalle = async (req, res) => {
  try {
    const { detalleId } = req.params;
    const detalle = await DetalleAuditoria.findByPk(detalleId);
    if (!detalle) return res.status(404).json({ message: 'Detalle no encontrado' });

    await detalle.destroy();
    res.json({ message: 'Detalle eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar detalle' });
  }
};

exports.deleteDetallesBulk = async (req, res) => {
  try {
    const { ids } = req.body;
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ message: 'Array ids requerido' });
    }

    await DetalleAuditoria.destroy({
      where: { id: { [Op.in]: ids } }
    });

    res.json({ message: `${ids.length} detalles eliminados` });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar detalles en lote' });
  }
};

exports.getMovimientosRecientes = async (req, res) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit) : 5;
    const detalles = await DetalleAuditoria.findAll({
      include: [{ model: Activo, as: 'activo' }],
      order: [['fecha_escaneo', 'DESC']],
      limit
    });

    res.json(detalles);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.sync = async (req, res) => {
  try {
    const { auditoria_id, detalles } = req.body;
    const items = Array.isArray(detalles) ? detalles : (Array.isArray(req.body) ? req.body : []);
    const audId = auditoria_id || (items[0] && items[0].auditoria_id) || req.params?.id;

    if (!audId) {
      return res.status(400).json({ message: 'auditoria_id es requerido para sincronizar' });
    }

    const auditoria = await Auditoria.findByPk(audId);
    if (!auditoria) {
      return res.status(404).json({ message: 'Auditoría no encontrada' });
    }

    const creados = [];
    for (const item of items) {
      let normEstado = (item.estado || 'presente').toString().toLowerCase().trim();
      if (!['presente', 'faltante', 'no_esperado'].includes(normEstado)) {
        normEstado = 'presente';
      }

      let activoId = item.activo_id;
      let qr = item.codigo_qr_escaneado;

      if (!qr && activoId) {
        const act = await Activo.findByPk(activoId);
        if (act) qr = act.codigo_activo;
      }
      if (!activoId && qr && normEstado !== 'no_esperado') {
        const isUuidVal = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(qr);
        const act = await Activo.findOne({
          where: isUuidVal ? { [Op.or]: [{ id: qr }, { codigo_activo: qr }] } : { codigo_activo: qr }
        });
        if (act) {
          activoId = act.id;
          qr = act.codigo_activo;
        }
      }

      if (normEstado !== 'no_esperado' && !activoId) normEstado = 'no_esperado';
      if (normEstado !== 'faltante' && !qr) qr = 'SIN_CODIGO';

      const d = await DetalleAuditoria.create({
        auditoria_id: audId,
        activo_id: activoId || null,
        codigo_qr_escaneado: qr || null,
        estado: normEstado,
        observacion: item.observacion || null,
        fecha_escaneo: item.fecha_escaneo ? new Date(item.fecha_escaneo) : new Date(),
        sincronizado: true
      });
      creados.push(d);
    }

    // Actualizar conteos
    const encontrados = await DetalleAuditoria.count({ where: { auditoria_id: audId, estado: 'presente' } });
    const faltantes = await DetalleAuditoria.count({ where: { auditoria_id: audId, estado: 'faltante' } });
    const noEsperados = await DetalleAuditoria.count({ where: { auditoria_id: audId, estado: 'no_esperado' } });

    await auditoria.update({
      total_encontrados: encontrados,
      total_faltantes: faltantes,
      total_no_esperados: noEsperados
    });

    res.json({
      message: 'Sincronización completada exitosamente',
      sincronizados: creados.length,
      auditoria
    });
  } catch (error) {
    console.error('Error al sincronizar auditoría:', error);
    res.status(500).json({ message: 'Error interno en sincronización: ' + error.message });
  }
};
