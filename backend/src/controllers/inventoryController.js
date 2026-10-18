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
    const { ambiente_id, estado, limit } = req.query;
    const where = {};

    if (ambiente_id && isUuid(ambiente_id)) where.ambiente_id = ambiente_id;
    if (estado) {
      where.estado = normalizeEstado(estado);
    }

    const activos = await Activo.findAll({
      where,
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
        { model: Ambiente, as: 'ambiente_registro', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
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
        { model: Ambiente, as: 'ambiente_registro' },
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
          { model: Ambiente, as: 'ambiente_registro' },
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
          { model: Ambiente, as: 'ambiente_registro' },
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
    let whereClause = {};

    if (tipo_activo_id && ambiente_id) {
      whereClause = {
        tipo_activo_id,
        ambiente_registro_id: ambiente_id
      };
    }

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
    const ambienteRegistroId = value.ambiente_registro_id || value.ambiente_id;
    const ambienteRegistro = await Ambiente.findByPk(ambienteRegistroId);
    
    if (!tipo || !ambienteActual || !ambienteRegistro) {
      await t.rollback();
      return res.status(400).json({ message: 'Tipo de activo o ambiente inválido' });
    }

    value.ambiente_registro_id = ambienteRegistroId;
    
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
        { model: Ambiente, as: 'ambiente_registro', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
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
    
    // Campos inmutables en edición (cambiar de ambiente es traslado, no edición)
    delete value.codigo_activo;
    delete value.numero_correlativo;
    delete value.tipo_activo_id;
    delete value.ambiente_registro_id;
    delete value.ambiente_id;

    if (req.file) {
      value.imagen_url = `/uploads/activos/${req.file.filename}`;
    } else if (value.imagen && !value.imagen_url) {
      value.imagen_url = value.imagen;
    }
    
    await activo.update(value);

    const plain = activo.toJSON();
    plain.imagen = plain.imagen_url;
    res.json(plain);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar activo: ' + error.message });
  }
};

exports.delete = async (req, res) => {
  const { id } = req.params;
  try {
    const activo = isUuid(id)
      ? await Activo.findByPk(id)
      : await Activo.findOne({ where: { codigo_activo: id } });

    if (!activo) return res.status(404).json({ message: 'Activo no encontrado' });
    
    // Regla: Solo baja lógica, sin borrado físico para ningún rol
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

    res.json({ message: 'Activo dado de baja correctamente (baja lógica)', activo });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al dar de baja el activo: ' + error.message });
  }
};
