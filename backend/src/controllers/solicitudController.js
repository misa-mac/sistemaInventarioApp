const SolicitudCambio = require('../models/SolicitudCambio');
const Activo = require('../models/Activo');
const Ambiente = require('../models/Ambiente');
const TipoActivo = require('../models/TipoActivo');
const Usuario = require('../models/Usuario');
const Movimiento = require('../models/Movimiento');
const Notificacion = require('../models/Notificacion');
const AuditLog = require('../models/AuditLog');
const { sequelize } = require('../../database');
const Joi = require('joi');

const isUuid = (str) => typeof str === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);

const CAMPOS_PERMITIDOS_EDICION = [
  'nombre',
  'marca',
  'modelo',
  'numero_serie',
  'origen',
  'especificacion_origen',
  'descripcion',
  'responsable',
  'fecha_ingreso',
  'valor',
  'imagen_url',
  'estado',
  'observaciones',
];

const CAMPOS_PERMITIDOS_ALTA = [
  'nombre',
  'marca',
  'modelo',
  'numero_serie',
  'tipo_activo_id',
  'ambiente_id',
  'ambiente_registro_id',
  'origen',
  'especificacion_origen',
  'descripcion',
  'responsable',
  'fecha_ingreso',
  'valor',
  'imagen_url',
  'estado',
  'observaciones',
];

/**
 * POST /api/solicitudes
 * Permite a técnicos y administradores proponer un cambio (alta, edición, baja).
 * Soporta idempotencia mediante UUID opcional provisto por el cliente.
 */
exports.create = async (req, res) => {
  try {
    const { id, tipo, activo_id, datos, motivo } = req.body;

    // 1. Idempotencia: Si se envía un ID y ya existe, retornar la existente sin duplicar
    if (id && isUuid(id)) {
      const existente = await SolicitudCambio.findByPk(id, {
        include: [
          { model: Usuario, as: 'solicitante', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
          { model: Activo, as: 'activo' },
          { model: Activo, as: 'activo_resultante' },
        ]
      });
      if (existente) {
        return res.status(200).json(existente);
      }
    }

    // 2. Validación de tipo
    if (!['alta', 'edicion', 'baja'].includes(tipo)) {
      return res.status(400).json({ message: 'El tipo de solicitud debe ser "alta", "edicion" o "baja".' });
    }

    const payloadDatos = (typeof datos === 'object' && datos !== null) ? { ...datos } : {};
    let sanitizedDatos = {};

    // 3. Validaciones específicas por tipo
    if (tipo === 'alta') {
      // Filtrar estrictamente campos permitidos para alta
      for (const key of Object.keys(payloadDatos)) {
        if (CAMPOS_PERMITIDOS_ALTA.includes(key)) {
          sanitizedDatos[key] = payloadDatos[key];
        }
      }

      // Prohibir terminantemente código o correlativo calculado por el cliente
      delete sanitizedDatos.codigo_activo;
      delete sanitizedDatos.numero_correlativo;

      if (!sanitizedDatos.tipo_activo_id || !isUuid(sanitizedDatos.tipo_activo_id)) {
        return res.status(400).json({ message: 'tipo_activo_id es requerido y debe ser un UUID válido.' });
      }
      if (!sanitizedDatos.ambiente_id || !isUuid(sanitizedDatos.ambiente_id)) {
        return res.status(400).json({ message: 'ambiente_id es requerido y debe ser un UUID válido.' });
      }

      const tipoExiste = await TipoActivo.findByPk(sanitizedDatos.tipo_activo_id);
      if (!tipoExiste) {
        return res.status(400).json({ message: 'El tipo_activo_id especificado no existe.' });
      }

      const ambienteExiste = await Ambiente.findByPk(sanitizedDatos.ambiente_id);
      if (!ambienteExiste) {
        return res.status(400).json({ message: 'El ambiente_id especificado no existe.' });
      }

      if (sanitizedDatos.ambiente_registro_id) {
        const ambRegExiste = await Ambiente.findByPk(sanitizedDatos.ambiente_registro_id);
        if (!ambRegExiste) {
          return res.status(400).json({ message: 'El ambiente_registro_id especificado no existe.' });
        }
      } else {
        sanitizedDatos.ambiente_registro_id = sanitizedDatos.ambiente_id;
      }
    } else if (tipo === 'edicion') {
      if (!activo_id || !isUuid(activo_id)) {
        return res.status(400).json({ message: 'activo_id es requerido para solicitudes de edición.' });
      }

      const activoExiste = await Activo.findByPk(activo_id);
      if (!activoExiste) {
        return res.status(404).json({ message: 'El activo a editar no fue encontrado.' });
      }

      // Filtrar solo los campos permitidos. Inmutables: código, tipo, ambientes
      for (const key of Object.keys(payloadDatos)) {
        if (CAMPOS_PERMITIDOS_EDICION.includes(key)) {
          sanitizedDatos[key] = payloadDatos[key];
        }
      }

      if (Object.keys(sanitizedDatos).length === 0) {
        return res.status(400).json({ message: 'Debe especificar al menos un campo permitido para editar.' });
      }
    } else if (tipo === 'baja') {
      if (!activo_id || !isUuid(activo_id)) {
        return res.status(400).json({ message: 'activo_id es requerido para solicitudes de baja.' });
      }

      const activoExiste = await Activo.findByPk(activo_id);
      if (!activoExiste) {
        return res.status(404).json({ message: 'El activo a dar de baja no fue encontrado.' });
      }

      if (!motivo || typeof motivo !== 'string' || motivo.trim() === '') {
        return res.status(400).json({ message: 'El motivo es obligatorio para solicitar la baja de un activo.' });
      }
    }

    // 4. Crear la solicitud en la base de datos
    const nuevaSolicitud = await SolicitudCambio.create({
      id: (id && isUuid(id)) ? id : undefined,
      tipo,
      estado: 'pendiente',
      solicitante_id: req.user.id,
      activo_id: (tipo === 'alta') ? null : activo_id,
      datos: sanitizedDatos,
      motivo: motivo ? motivo.trim() : null,
    });

    // 5. Registrar en audit_logs
    try {
      await AuditLog.create({
        usuario_id: req.user.id,
        accion: 'SOLICITUD_CREADA',
        recurso: '/api/solicitudes',
        recurso_id: nuevaSolicitud.id,
        resultado: 'exitoso',
        detalles: `Solicitud de ${tipo} creada por ${req.user.email}`,
        ip_address: req.ip || req.connection?.remoteAddress || '127.0.0.1',
        user_agent: req.get('User-Agent') || 'Desconocido',
        fecha_hora: new Date()
      });

      // Notificar a administradores
      await Notificacion.create({
        usuario_id: null,
        titulo: 'Nueva solicitud de inventario',
        mensaje: `${req.user.nombre_completo || req.user.email} solicitó una ${tipo}.`,
        tipo: 'info'
      });
    } catch (logErr) {
      console.warn('Advertencia audit_logs/notificacion:', logErr.message);
    }

    const resultado = await SolicitudCambio.findByPk(nuevaSolicitud.id, {
      include: [
        { model: Usuario, as: 'solicitante', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        {
          model: Activo,
          as: 'activo',
          include: [
            { model: TipoActivo, as: 'tipo' },
            { model: Ambiente, as: 'ambiente' },
          ]
        },
      ]
    });

    res.status(201).json(resultado);
  } catch (error) {
    console.error('Error al crear solicitud:', error);
    res.status(500).json({ message: 'Error interno del servidor: ' + error.message });
  }
};

/**
 * GET /api/solicitudes
 * Admin ve todas (con filtros de estado, tipo y paginación).
 * Otros roles ven solo las suyas.
 */
exports.getAll = async (req, res) => {
  try {
    const { estado, tipo, page = 1, limit = 20 } = req.query;
    const offset = (Math.max(1, parseInt(page)) - 1) * Math.max(1, parseInt(limit));
    const where = {};

    // Seguridad RBAC: técnico solo ve las suyas
    if (req.user.rol !== 'admin') {
      where.solicitante_id = req.user.id;
    }

    if (estado && ['pendiente', 'aprobada', 'rechazada'].includes(estado)) {
      where.estado = estado;
    }

    if (tipo && ['alta', 'edicion', 'baja'].includes(tipo)) {
      where.tipo = tipo;
    }

    const { count, rows } = await SolicitudCambio.findAndCountAll({
      where,
      include: [
        { model: Usuario, as: 'solicitante', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        { model: Usuario, as: 'revisor', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        {
          model: Activo,
          as: 'activo',
          include: [
            { model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] },
            { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo'] },
            { model: Ambiente, as: 'ambiente_registro', attributes: ['id', 'nombre', 'codigo'] },
          ]
        },
        {
          model: Activo,
          as: 'activo_resultante',
          include: [
            { model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] },
            { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo'] },
            { model: Ambiente, as: 'ambiente_registro', attributes: ['id', 'nombre', 'codigo'] },
          ]
        },
      ],
      order: [['created_at', 'DESC']],
      limit: Math.max(1, parseInt(limit)),
      offset,
    });

    res.json({
      total: count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(count / Math.max(1, parseInt(limit))),
      data: rows,
    });
  } catch (error) {
    console.error('Error al listar solicitudes:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

/**
 * GET /api/solicitudes/pendientes-count
 * Retorna el número de solicitudes pendientes para badges en web y móvil.
 */
exports.getPendientesCount = async (req, res) => {
  try {
    const where = { estado: 'pendiente' };
    if (req.user.rol !== 'admin') {
      where.solicitante_id = req.user.id;
    }
    const count = await SolicitudCambio.count({ where });
    res.json({ count });
  } catch (error) {
    console.error('Error al contar solicitudes pendientes:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

/**
 * GET /api/solicitudes/:id
 */
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    const solicitud = await SolicitudCambio.findByPk(id, {
      include: [
        { model: Usuario, as: 'solicitante', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        { model: Usuario, as: 'revisor', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        {
          model: Activo,
          as: 'activo',
          include: [
            { model: TipoActivo, as: 'tipo' },
            { model: Ambiente, as: 'ambiente' },
            { model: Ambiente, as: 'ambiente_registro' },
          ]
        },
        {
          model: Activo,
          as: 'activo_resultante',
          include: [
            { model: TipoActivo, as: 'tipo' },
            { model: Ambiente, as: 'ambiente' },
            { model: Ambiente, as: 'ambiente_registro' },
          ]
        },
      ]
    });

    if (!solicitud) {
      return res.status(404).json({ message: 'Solicitud no encontrada' });
    }

    if (req.user.rol !== 'admin' && solicitud.solicitante_id !== req.user.id) {
      return res.status(403).json({ message: 'Acceso denegado a esta solicitud' });
    }

    res.json(solicitud);
  } catch (error) {
    console.error('Error al obtener solicitud:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

/**
 * POST /api/solicitudes/:id/aprobar
 * Solo rol admin. Aplica los cambios en UNA transacción:
 * - alta: inserta el activo (código asignado por trigger fn_activos_asignar_codigo) y guarda activo_resultante_id.
 * - edicion: actualiza solo campos permitidos.
 * - baja: baja lógica (estado Inactivo) + movimiento 'baja'.
 * - audit_logs + notificación para el solicitante.
 */
exports.aprobar = async (req, res) => {
  const { id } = req.params;
  const t = await sequelize.transaction();

  try {
    const solicitud = await SolicitudCambio.findByPk(id, { transaction: t });
    if (!solicitud) {
      await t.rollback();
      return res.status(404).json({ message: 'Solicitud no encontrada' });
    }

    if (solicitud.estado !== 'pendiente') {
      await t.rollback();
      return res.status(400).json({ message: `La solicitud ya fue procesada anteriormente (estado: ${solicitud.estado}).` });
    }

    let activoResultanteId = null;

    if (solicitud.tipo === 'alta') {
      const datosAlta = { ...solicitud.datos };
      // Dejar que el trigger de base de datos genere codigo_activo y numero_correlativo
      delete datosAlta.codigo_activo;
      delete datosAlta.numero_correlativo;

      if (!datosAlta.ambiente_registro_id) {
        datosAlta.ambiente_registro_id = datosAlta.ambiente_id;
      }

      const nuevoActivo = await Activo.create(datosAlta, { transaction: t });
      
      // Recargar activo para capturar codigo_activo generado por el trigger
      await nuevoActivo.reload({ transaction: t });
      activoResultanteId = nuevoActivo.id;
      solicitud.activo_resultante_id = nuevoActivo.id;
    } else if (solicitud.tipo === 'edicion') {
      const activo = await Activo.findByPk(solicitud.activo_id, { transaction: t });
      if (!activo) {
        await t.rollback();
        return res.status(404).json({ message: 'El activo asociado ya no existe' });
      }

      const updates = {};
      for (const campo of CAMPOS_PERMITIDOS_EDICION) {
        if (solicitud.datos[campo] !== undefined) {
          updates[campo] = solicitud.datos[campo];
        }
      }

      await activo.update(updates, { transaction: t });
    } else if (solicitud.tipo === 'baja') {
      const activo = await Activo.findByPk(solicitud.activo_id, { transaction: t });
      if (!activo) {
        await t.rollback();
        return res.status(404).json({ message: 'El activo asociado ya no existe' });
      }

      const estadoAnterior = activo.estado;
      await activo.update({ estado: 'Inactivo' }, { transaction: t });

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
        observaciones: solicitud.motivo || 'Baja aprobada por solicitud'
      }, { transaction: t });
    }

    // Actualizar estado de la solicitud
    solicitud.estado = 'aprobada';
    solicitud.revisor_id = req.user.id;
    solicitud.revisado_at = new Date();
    await solicitud.save({ transaction: t });

    // Registrar en audit_logs
    await AuditLog.create({
      usuario_id: req.user.id,
      accion: 'APROBAR_SOLICITUD',
      recurso: '/api/solicitudes',
      recurso_id: solicitud.id,
      resultado: 'exitoso',
      detalles: `Solicitud de ${solicitud.tipo} (${solicitud.id}) aprobada por ${req.user.email}`,
      ip_address: req.ip || req.connection?.remoteAddress || '127.0.0.1',
      user_agent: req.get('User-Agent') || 'Desconocido',
      fecha_hora: new Date()
    }, { transaction: t });

    // Crear notificación para el solicitante
    await Notificacion.create({
      usuario_id: solicitud.solicitante_id,
      titulo: 'Solicitud aprobada',
      mensaje: `Tu solicitud de ${solicitud.tipo} ha sido aprobada por la administración.`,
      tipo: 'success'
    }, { transaction: t });

    await t.commit();

    const actualizada = await SolicitudCambio.findByPk(solicitud.id, {
      include: [
        { model: Usuario, as: 'solicitante', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        { model: Usuario, as: 'revisor', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        {
          model: Activo,
          as: 'activo',
          include: [
            { model: TipoActivo, as: 'tipo' },
            { model: Ambiente, as: 'ambiente' },
          ]
        },
        {
          model: Activo,
          as: 'activo_resultante',
          include: [
            { model: TipoActivo, as: 'tipo' },
            { model: Ambiente, as: 'ambiente' },
          ]
        },
      ]
    });

    res.json({
      message: 'Solicitud aprobada exitosamente y cambios aplicados.',
      solicitud: actualizada,
    });
  } catch (error) {
    await t.rollback();
    console.error('Error al aprobar solicitud:', error);
    res.status(500).json({ message: 'Error interno al aprobar solicitud: ' + error.message });
  }
};

/**
 * POST /api/solicitudes/:id/rechazar
 * Solo rol admin. Exige comentario obligatorio.
 */
exports.rechazar = async (req, res) => {
  const { id } = req.params;
  const comentario = (req.body?.comentario || req.body?.comentario_revision || '').trim();

  if (!comentario) {
    return res.status(400).json({ message: 'El comentario de rechazo es obligatorio.' });
  }

  const t = await sequelize.transaction();

  try {
    const solicitud = await SolicitudCambio.findByPk(id, { transaction: t });
    if (!solicitud) {
      await t.rollback();
      return res.status(404).json({ message: 'Solicitud no encontrada' });
    }

    if (solicitud.estado !== 'pendiente') {
      await t.rollback();
      return res.status(400).json({ message: `La solicitud ya fue procesada anteriormente (estado: ${solicitud.estado}).` });
    }

    solicitud.estado = 'rechazada';
    solicitud.comentario_revision = comentario;
    solicitud.revisor_id = req.user.id;
    solicitud.revisado_at = new Date();
    await solicitud.save({ transaction: t });

    // Registrar en audit_logs
    await AuditLog.create({
      usuario_id: req.user.id,
      accion: 'RECHAZAR_SOLICITUD',
      recurso: '/api/solicitudes',
      recurso_id: solicitud.id,
      resultado: 'exitoso',
      detalles: `Solicitud de ${solicitud.tipo} (${solicitud.id}) rechazada. Motivo: ${comentario}`,
      ip_address: req.ip || req.connection?.remoteAddress || '127.0.0.1',
      user_agent: req.get('User-Agent') || 'Desconocido',
      fecha_hora: new Date()
    }, { transaction: t });

    // Crear notificación para el solicitante
    await Notificacion.create({
      usuario_id: solicitud.solicitante_id,
      titulo: 'Solicitud rechazada',
      mensaje: `Tu solicitud de ${solicitud.tipo} fue rechazada: ${comentario}`,
      tipo: 'error'
    }, { transaction: t });

    await t.commit();

    const actualizada = await SolicitudCambio.findByPk(solicitud.id, {
      include: [
        { model: Usuario, as: 'solicitante', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        { model: Usuario, as: 'revisor', attributes: ['id', 'nombre_completo', 'email', 'rol'] },
        { model: Activo, as: 'activo' },
      ]
    });

    res.json({
      message: 'Solicitud rechazada.',
      solicitud: actualizada,
    });
  } catch (error) {
    await t.rollback();
    console.error('Error al rechazar solicitud:', error);
    res.status(500).json({ message: 'Error interno al rechazar solicitud: ' + error.message });
  }
};
