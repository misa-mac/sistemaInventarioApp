const Activo = require('../models/Activo');
const Ambiente = require('../models/Ambiente');
const TipoActivo = require('../models/TipoActivo');
const Movimiento = require('../models/Movimiento');
const { sequelize } = require('../../database');
const { Op } = require('sequelize');
const Joi = require('joi');

const isUuid = (str) => typeof str === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);

const normalizeEstado = (estado) => {
  if (!estado) return 'Activo';
  const est = estado.toString().toLowerCase().trim();
  if (est === 'activo') return 'Activo';
  if (est === 'inactivo' || est === 'baja') return 'Inactivo';
  if (est === 'dañado' || est === 'danado' || est === 'mantenimiento') return 'Dañado';
  return 'Activo';
};

const createSchema = Joi.object({
  nombre: Joi.string().max(150).allow('', null).optional(),
  marca: Joi.string().max(100).allow('', null).optional(),
  modelo: Joi.string().max(100).allow('', null).optional(),
  numero_serie: Joi.string().max(100).allow('', null).optional(),
  tipo_activo_id: Joi.string().uuid().optional(),
  tipo: Joi.string().allow('', null).optional(),
  ambiente_id: Joi.string().uuid().required(),
  ambiente_registro_id: Joi.string().uuid().allow('', null).optional(),
  origen: Joi.string().max(150).allow('', null).optional(),
  especificacion_origen: Joi.string().max(255).allow('', null).optional(),
  descripcion: Joi.string().allow('', null).optional(),
  responsable: Joi.string().max(150).allow('', null).optional(),
  fecha_ingreso: Joi.date().allow(null, '').optional(),
  valor: Joi.number().min(0).allow(null, '').optional(),
  estado: Joi.string().valid('Activo', 'Inactivo', 'Dañado').optional(),
  observaciones: Joi.string().allow('', null).optional(),
  imagen_url: Joi.string().allow('', null).optional(),
  imagen: Joi.string().allow('', null).optional(),
  uuid: Joi.string().allow('', null).optional(),
  codigo_activo: Joi.string().allow('', null).optional(),
  qr_codigo: Joi.string().allow('', null).optional(),
  id: Joi.string().allow('', null).optional(),
});

const updateSchema = Joi.object({
  nombre: Joi.string().max(150).allow('', null).optional(),
  marca: Joi.string().max(100).allow('', null).optional(),
  modelo: Joi.string().max(100).allow('', null).optional(),
  numero_serie: Joi.string().max(100).allow('', null).optional(),
  ambiente_id: Joi.string().uuid().optional(),
  origen: Joi.string().max(150).allow('', null).optional(),
  especificacion_origen: Joi.string().max(255).allow('', null).optional(),
  descripcion: Joi.string().allow('', null).optional(),
  responsable: Joi.string().max(150).allow('', null).optional(),
  fecha_ingreso: Joi.date().allow(null, '').optional(),
  valor: Joi.number().min(0).allow(null, '').optional(),
  estado: Joi.string().valid('Activo', 'Inactivo', 'Dañado').optional(),
  observaciones: Joi.string().allow('', null).optional(),
  imagen_url: Joi.string().allow('', null).optional(),
  imagen: Joi.string().allow('', null).optional(),
  uuid: Joi.string().allow('', null).optional(),
  codigo_activo: Joi.string().allow('', null).optional(),
  qr_codigo: Joi.string().allow('', null).optional(),
  id: Joi.string().allow('', null).optional(),
  tipo_activo_id: Joi.string().allow('', null).optional(),
  tipo: Joi.string().allow('', null).optional(),
  ambiente_registro_id: Joi.string().allow('', null).optional(),
});

exports.getAll = async (req, res) => {
  try {
    const { ambiente_id, estado, limit, q } = req.query;
    const where = {};

    if (ambiente_id && isUuid(ambiente_id)) where.ambiente_id = ambiente_id;
    if (estado) {
      where.estado = normalizeEstado(estado);
    }

    if (q && q.trim()) {
      const qStr = `%${q.trim()}%`;
      where[Op.or] = [
        { nombre: { [Op.like]: qStr } },
        { codigo_activo: { [Op.like]: qStr } },
        { qr_codigo: { [Op.like]: qStr } },
        { numero_serie: { [Op.like]: qStr } },
        { modelo: { [Op.like]: qStr } },
        { marca: { [Op.like]: qStr } },
        ...(isUuid(q.trim()) ? [{ id: q.trim() }] : [])
      ];
    }

    const activos = await Activo.findAll({
      where,
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
        { model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }
      ],
      order: [['created_at', 'DESC']],
      limit: limit ? parseInt(limit) : undefined
    });

    const resultado = activos.map(a => {
      const plain = a.toJSON();
      plain.imagen = plain.imagen_url || plain.imagen || null;
      return plain;
    });

    res.json(resultado);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getBySearch = async (req, res) => {
  try {
    const { q } = req.params;
    const searchConditions = [
      { codigo_activo: q },
      { numero_serie: q }
    ];

    if (isUuid(q)) {
      searchConditions.push({ id: q });
    }

    const activo = await Activo.findOne({
      where: {
        [Op.or]: searchConditions
      },
      include: [
        { model: Ambiente, as: 'ambiente' },
        { model: TipoActivo, as: 'tipo' }
      ]
    });

    if (!activo) return res.status(404).json({ message: 'Activo no encontrado' });

    const plain = activo.toJSON();
    plain.imagen = plain.imagen_url || plain.imagen || null;
    res.json(plain);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getUltimo = async (req, res) => {
  try {
    const activo = await Activo.findOne({
      include: [
        { model: Ambiente, as: 'ambiente' },
        { model: TipoActivo, as: 'tipo' }
      ],
      order: [['updated_at', 'DESC']]
    });

    if (!activo) return res.json(null);
    const plain = activo.toJSON();
    plain.imagen = plain.imagen_url || plain.imagen || null;
    res.json(plain);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    let activo = null;

    if (isUuid(id)) {
      activo = await Activo.findByPk(id, {
        include: [
          { model: Ambiente, as: 'ambiente' },
          { model: TipoActivo, as: 'tipo' }
        ]
      });
    } else {
      activo = await Activo.findOne({
        where: {
          [Op.or]: [
            { codigo_activo: id },
            { numero_serie: id }
          ]
        },
        include: [
          { model: Ambiente, as: 'ambiente' },
          { model: TipoActivo, as: 'tipo' }
        ]
      });
    }

    if (!activo) return res.status(404).json({ message: 'Activo no encontrado' });

    const plain = activo.toJSON();
    plain.imagen = plain.imagen_url || plain.imagen || null;
    res.json(plain);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getNextSequence = async (req, res) => {
  try {
    const { tipo_activo_id, ambiente_id } = req.query;
    let whereClause = {
      estado: { [Op.ne]: 'Inactivo' }
    };

    if (tipo_activo_id) whereClause.tipo_activo_id = tipo_activo_id;
    if (ambiente_id) whereClause.ambiente_id = ambiente_id;

    const maxCorrelativo = await Activo.max('numero_correlativo', { where: whereClause }) || 0;
    res.json({ next: maxCorrelativo + 1 });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error obteniendo secuencia' });
  }
};

exports.create = async (req, res) => {
  // Pre-normalizar body para móviles o formularios web
  if (req.body.valor === '' || req.body.valor === undefined) req.body.valor = null;
  if (req.body.fecha_ingreso === '') req.body.fecha_ingreso = null;
  if (req.body.estado) req.body.estado = normalizeEstado(req.body.estado);

  if (!req.body.tipo_activo_id && (req.body.tipo || req.body.tipo_nombre)) {
    const tipoBusqueda = req.body.tipo || req.body.tipo_nombre;
    if (isUuid(tipoBusqueda)) {
      req.body.tipo_activo_id = tipoBusqueda;
    } else {
      const tMatch = await TipoActivo.findOne({
        where: sequelize.where(
          sequelize.fn('LOWER', sequelize.col('nombre')),
          tipoBusqueda.toString().toLowerCase().trim()
        )
      });
      if (tMatch) req.body.tipo_activo_id = tMatch.id;
    }
  }

  if (!req.body.tipo_activo_id) {
    const primerTipo = await TipoActivo.findOne({ order: [['codigo', 'ASC']] });
    if (primerTipo) req.body.tipo_activo_id = primerTipo.id;
  }

  const { error, value } = createSchema.validate(req.body);
  if (error) return res.status(400).json({ error: error.details[0].message });
  
  const t = await sequelize.transaction();
  
  try {
    const tipo = await TipoActivo.findByPk(value.tipo_activo_id);
    const ambienteActual = await Ambiente.findByPk(value.ambiente_id);
    
    if (!tipo || !ambienteActual) {
      await t.rollback();
      return res.status(400).json({ message: 'Tipo de activo o ambiente inválido' });
    }

    delete value.ambiente_registro_id;
    
    // Dejar que la base de datos (trigger fn_activos_asignar_codigo) sea la ÚNICA fuente de verdad para el código y correlativo
    delete value.codigo_activo;
    delete value.numero_correlativo;

    if (req.file) {
      value.imagen_url = `/uploads/activos/${req.file.filename}`;
    } else if (value.imagen && !value.imagen_url) {
      value.imagen_url = value.imagen;
    }
    
    const activo = await Activo.create(value, { transaction: t });
    await t.commit();
    
    // Recargar para obtener el codigo_activo y numero_correlativo asignados por el trigger
    await activo.reload({
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
        { model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }
      ]
    });

    const plain = activo.toJSON();
    plain.imagen = plain.imagen_url;
    res.status(201).json(plain);
  } catch (error) {
    await t.rollback();
    console.error(error);
    res.status(500).json({ message: 'Error al registrar activo: ' + error.message });
  }
};

exports.update = async (req, res) => {
  const { id } = req.params;
  if (req.body.valor === '' || req.body.valor === undefined) req.body.valor = null;
  if (req.body.fecha_ingreso === '') req.body.fecha_ingreso = null;
  if (req.body.estado) req.body.estado = normalizeEstado(req.body.estado);

  const { error, value } = updateSchema.validate(req.body);
  if (error) return res.status(400).json({ error: error.details[0].message });
  
  try {
    const activo = isUuid(id)
      ? await Activo.findByPk(id)
      : await Activo.findOne({ where: { codigo_activo: id } });

    if (!activo) return res.status(404).json({ message: 'Activo no encontrado' });
    
    // Campos inmutables (identidad física permanente del activo)
    delete value.codigo_activo;
    delete value.numero_correlativo;
    delete value.tipo_activo_id;
    delete value.ambiente_registro_id;

    let huboCambioAmbiente = false;
    let ambienteAnteriorId = activo.ambiente_id;
    let codigoAnterior = activo.codigo_activo;
    let nuevoAmbiente = null;

    if (value.ambiente_id && value.ambiente_id !== activo.ambiente_id) {
      nuevoAmbiente = await Ambiente.findByPk(value.ambiente_id);
      if (!nuevoAmbiente) {
        return res.status(400).json({ message: 'El ambiente seleccionado no existe.' });
      }
      huboCambioAmbiente = true;
    }

    if (req.file) {
      value.imagen_url = `/uploads/activos/${req.file.filename}`;
    } else if (value.imagen && !value.imagen_url) {
      value.imagen_url = value.imagen;
    }
    
    await activo.update(value);

    // Recargar para obtener el codigo_activo y numero_correlativo calculados por el trigger de BD
    await activo.reload({
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
        { model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }
      ]
    });

    // Si hubo traslado de ambiente, registrar el movimiento oficial con el cambio de código
    if (huboCambioAmbiente) {
      await Movimiento.create({
        tipo_evento: 'traslado',
        activo_id: activo.id,
        usuario_id: req.user.id,
        ambiente_origen_id: ambienteAnteriorId,
        ambiente_destino_id: value.ambiente_id,
        estado_anterior: activo.estado,
        estado_nuevo: value.estado || activo.estado,
        tipo_mantenimiento: null,
        piezas_reemplazadas: null,
        costo_mantenimiento: null,
        observaciones: `Traslado a ${nuevoAmbiente.nombre}. Código QR actualizado de ${codigoAnterior} a ${activo.codigo_activo}`
      });
    }

    const plain = activo.toJSON();
    plain.imagen = plain.imagen_url;
    plain.hubo_cambio_ambiente = huboCambioAmbiente;
    res.json(plain);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar activo: ' + error.message });
  }
};

exports.delete = async (req, res) => {
  const { id } = req.params;
  const esPermanente = req.query.permanente === 'true' || req.body?.permanente === true;

  try {
    const activo = isUuid(id)
      ? await Activo.findByPk(id)
      : await Activo.findOne({ where: { codigo_activo: id } });

    if (!activo) return res.status(404).json({ message: 'Activo no encontrado' });

    // Si ya está inactivo (previamente dado de baja) o se solicita eliminación definitiva:
    if (activo.estado === 'Inactivo' || esPermanente) {
      const t = await sequelize.transaction();
      try {
        const DetalleAuditoria = require('../models/DetalleAuditoria');
        const SolicitudCambio = require('../models/SolicitudCambio');
        const AuditLog = require('../models/AuditLog');
        const fs = require('fs');
        const path = require('path');

        // 1. Limpiar referencias en detalle_auditoria
        await DetalleAuditoria.destroy({ where: { activo_id: activo.id }, transaction: t });

        // 2. Limpiar referencias en movimientos
        await Movimiento.destroy({ where: { activo_id: activo.id }, transaction: t });

        // 3. Limpiar referencias en solicitudes_cambio (tanto como activo afectado como resultante)
        await SolicitudCambio.destroy({
          where: {
            [Op.or]: [
              { activo_id: activo.id },
              { activo_resultante_id: activo.id }
            ]
          },
          transaction: t
        });

        // 4. Limpiar imagen física del servidor si existe
        if (activo.imagen_url && activo.imagen_url.startsWith('/uploads/')) {
          const fullImgPath = path.join(__dirname, '../../', activo.imagen_url);
          if (fs.existsSync(fullImgPath)) {
            try { fs.unlinkSync(fullImgPath); } catch (_) {}
          }
        }

        // 5. Registrar en audit_logs antes de eliminar
        try {
          await AuditLog.create({
            usuario_id: req.user?.id || null,
            accion: 'ACTIVO_ELIMINADO_DEFINITIVO',
            recurso: '/api/inventory',
            recurso_id: activo.id,
            resultado: 'exitoso',
            detalles: `Activo ${activo.codigo_activo} (${activo.nombre}) eliminado definitivamente por ${req.user?.email || 'admin'}`,
            ip_address: req.ip || req.connection?.remoteAddress || '127.0.0.1',
            user_agent: req.get('User-Agent') || 'Desconocido',
            fecha_hora: new Date()
          }, { transaction: t });
        } catch (logErr) {
          console.warn('Advertencia audit_logs:', logErr.message);
        }

        // 6. Eliminar definitivamente el activo
        await activo.destroy({ transaction: t });

        await t.commit();
        return res.json({ 
          message: 'Activo eliminado definitivamente de la base de datos', 
          id: activo.id, 
          eliminado_permanente: true 
        });
      } catch (transErr) {
        await t.rollback();
        throw transErr;
      }
    }

    // Si aún estaba Activo y no se pidió permanente: Baja lógica
    const estadoAnterior = activo.estado;
    await activo.update({ estado: 'Inactivo' });

    // Registrar evento de baja en historial de movimientos
    await Movimiento.create({
      tipo_evento: 'baja',
      activo_id: activo.id,
      usuario_id: req.user.id,
      ambiente_origen_id: null,
      ambiente_destino_id: null,
      estado_anterior: estadoAnterior,
      estado_nuevo: 'Inactivo',
      tipo_mantenimiento: null,
      piezas_reemplazadas: null,
      costo_mantenimiento: null,
      observaciones: req.body?.observaciones || 'Baja lógica de activo'
    });

    res.json({ message: 'Activo dado de baja correctamente (baja lógica)', activo, eliminado_permanente: false });
  } catch (error) {
    console.error('Error al procesar eliminación:', error);
    res.status(500).json({ message: 'Error al dar de baja o eliminar el activo: ' + error.message });
  }
};

exports.bulkImport = async (req, res) => {
  try {
    const { items } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Se requiere una lista de activos no vacía (items).' });
    }

    const allTipos = await TipoActivo.findAll();
    const allAmbientes = await Ambiente.findAll();

    const t = await sequelize.transaction();
    const created = [];
    const errors = [];

    for (let i = 0; i < items.length; i++) {
      const raw = items[i];
      const rowNum = i + 1;

      // 1. Resolver Tipo de Activo
      let tipo = null;
      if (raw.tipo_activo_id && isUuid(raw.tipo_activo_id)) {
        tipo = allTipos.find(tp => tp.id === raw.tipo_activo_id);
      }
      if (!tipo && raw.tipo_codigo !== undefined && raw.tipo_codigo !== null && raw.tipo_codigo !== '') {
        const codNum = parseInt(raw.tipo_codigo, 10);
        tipo = allTipos.find(tp => tp.codigo === codNum);
      }
      if (!tipo && (raw.tipo || raw.tipo_nombre || raw.categoria)) {
        const queryName = (raw.tipo || raw.tipo_nombre || raw.categoria).toString().toLowerCase().trim();
        tipo = allTipos.find(tp => tp.nombre.toLowerCase().trim() === queryName || tp.nombre.toLowerCase().includes(queryName));
      }
      if (!tipo) {
        tipo = allTipos[0];
      }

      // 2. Resolver Ambiente
      let amb = null;
      if (raw.ambiente_id && isUuid(raw.ambiente_id)) {
        amb = allAmbientes.find(a => a.id === raw.ambiente_id);
      }
      if (!amb && raw.ambiente_codigo !== undefined && raw.ambiente_codigo !== null && raw.ambiente_codigo !== '') {
        const codNum = parseInt(raw.ambiente_codigo, 10);
        amb = allAmbientes.find(a => a.codigo === codNum);
      }
      if (!amb && (raw.ambiente || raw.ambiente_nombre || raw.laboratorio)) {
        const queryName = (raw.ambiente || raw.ambiente_nombre || raw.laboratorio).toString().toLowerCase().trim();
        amb = allAmbientes.find(a => a.nombre.toLowerCase().trim() === queryName || a.nombre.toLowerCase().includes(queryName));
      }
      if (!amb) {
        errors.push(`Fila #${rowNum}: No se encontró el ambiente '${raw.ambiente || raw.ambiente_codigo || 'desconocido'}'.`);
        continue;
      }

      // 3. Normalizar datos
      const estadoNorm = normalizeEstado(raw.estado);
      const valorNum = (raw.valor !== undefined && raw.valor !== null && raw.valor !== '') ? parseFloat(raw.valor) : null;
      let fechaIngreso = null;
      if (raw.fecha_ingreso) {
        const parsedDate = new Date(raw.fecha_ingreso);
        if (!isNaN(parsedDate.getTime())) {
          fechaIngreso = parsedDate.toISOString().split('T')[0];
        }
      }

      const itemPayload = {
        nombre: (raw.nombre && raw.nombre.toString().trim()) || `${tipo ? tipo.nombre : 'Activo'} ${raw.marca || ''}`.trim(),
        tipo_activo_id: tipo ? tipo.id : null,
        ambiente_id: amb.id,
        marca: raw.marca ? raw.marca.toString().trim() : null,
        modelo: raw.modelo ? raw.modelo.toString().trim() : null,
        numero_serie: raw.numero_serie ? raw.numero_serie.toString().trim() : null,
        estado: estadoNorm,
        origen: raw.origen ? raw.origen.toString().trim() : 'Compra institucional',
        especificacion_origen: raw.especificacion_origen ? raw.especificacion_origen.toString().trim() : null,
        valor: isNaN(valorNum) ? null : valorNum,
        fecha_ingreso: fechaIngreso,
        descripcion: raw.descripcion ? raw.descripcion.toString().trim() : null,
        observaciones: raw.observaciones ? raw.observaciones.toString().trim() : null,
        responsable: raw.responsable ? raw.responsable.toString().trim() : null
      };

      const nuevoActivo = await Activo.create(itemPayload, { transaction: t });
      created.push(nuevoActivo);
    }

    if (errors.length > 0 && created.length === 0) {
      await t.rollback();
      return res.status(400).json({ message: 'No se pudo importar ningún activo.', errors });
    }

    await t.commit();
    res.status(201).json({
      success: true,
      count: created.length,
      errors: errors.length > 0 ? errors : undefined,
      message: `Se han importado exitosamente ${created.length} activo(s).`
    });
  } catch (err) {
    console.error('Error en bulkImport:', err);
    res.status(500).json({ message: 'Error durante la importación masiva: ' + err.message });
  }
};

