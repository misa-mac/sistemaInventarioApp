const EstacionTrabajo = require('../models/EstacionTrabajo');
const Ambiente = require('../models/Ambiente');
const Activo = require('../models/Activo');
const TipoActivo = require('../models/TipoActivo');
const { Op } = require('sequelize');

const isUuid = (str) => typeof str === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);

exports.getAll = async (req, res) => {
  try {
    const { ambiente_id, q } = req.query;
    const where = {};

    if (ambiente_id) {
      where.ambiente_id = ambiente_id;
    }

    if (q) {
      where[Op.or] = [
        { codigo_estacion: { [Op.iLike]: `%${q}%` } },
        { descripcion: { [Op.iLike]: `%${q}%` } }
      ];
    }

    const estaciones = await EstacionTrabajo.findAll({
      where,
      include: [
        {
          model: Ambiente,
          as: 'ambiente',
          attributes: ['id', 'nombre', 'codigo', 'ubicacion']
        },
        {
          model: Activo,
          as: 'activos',
          attributes: ['id', 'codigo_activo', 'nombre', 'marca', 'modelo', 'numero_serie', 'estado', 'tipo_activo_id', 'imagen_url'],
          include: [{ model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }]
        }
      ],
      order: [['codigo_estacion', 'ASC']]
    });

    res.json(estaciones);
  } catch (error) {
    console.error('Error al obtener estaciones:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getByCodigo = async (req, res) => {
  try {
    const { codigo } = req.params;
    let estacion = null;

    if (isUuid(codigo)) {
      estacion = await EstacionTrabajo.findByPk(codigo, {
        include: [
          {
            model: Ambiente,
            as: 'ambiente',
            attributes: ['id', 'nombre', 'codigo', 'ubicacion']
          },
          {
            model: Activo,
            as: 'activos',
            attributes: ['id', 'codigo_activo', 'nombre', 'marca', 'modelo', 'numero_serie', 'estado', 'tipo_activo_id', 'imagen_url'],
            include: [{ model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }]
          }
        ]
      });
    } else {
      estacion = await EstacionTrabajo.findOne({
        where: {
          codigo_estacion: { [Op.iLike]: codigo.trim() }
        },
        include: [
          {
            model: Ambiente,
            as: 'ambiente',
            attributes: ['id', 'nombre', 'codigo', 'ubicacion']
          },
          {
            model: Activo,
            as: 'activos',
            attributes: ['id', 'codigo_activo', 'nombre', 'marca', 'modelo', 'numero_serie', 'estado', 'tipo_activo_id', 'imagen_url'],
            include: [{ model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }]
          }
        ]
      });
    }

    if (!estacion) {
      return res.status(404).json({ message: 'Estación de trabajo no encontrada' });
    }

    const data = estacion.toJSON();
    data.componentes = data.activos || [];
    res.json(data);
  } catch (error) {
    console.error('Error al obtener estación:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.create = async (req, res) => {
  try {
    const { codigo_estacion, ambiente_id, descripcion, activo_ids } = req.body;

    if (!codigo_estacion || !codigo_estacion.trim()) {
      return res.status(400).json({ message: 'El código de estación es requerido (ej. EST-LAB1-05)' });
    }

    if (!ambiente_id) {
      return res.status(400).json({ message: 'El ambiente es requerido' });
    }

    const existe = await EstacionTrabajo.findOne({
      where: { codigo_estacion: codigo_estacion.trim() }
    });
    if (existe) {
      return res.status(400).json({ message: `La estación con código ${codigo_estacion} ya existe` });
    }

    const ambiente = await Ambiente.findByPk(ambiente_id);
    if (!ambiente) {
      return res.status(404).json({ message: 'Ambiente no encontrado' });
    }

    const nueva = await EstacionTrabajo.create({
      codigo_estacion: codigo_estacion.trim().toUpperCase(),
      ambiente_id,
      descripcion: descripcion ? descripcion.trim() : null
    });

    if (Array.isArray(activo_ids) && activo_ids.length > 0) {
      await Activo.update(
        { estacion_id: nueva.id, ambiente_id: nueva.ambiente_id },
        { where: { id: { [Op.in]: activo_ids } } }
      );
    }

    const resultado = await EstacionTrabajo.findByPk(nueva.id, {
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
        {
          model: Activo,
          as: 'activos',
          attributes: ['id', 'codigo_activo', 'nombre', 'marca', 'modelo', 'numero_serie', 'estado', 'tipo_activo_id', 'imagen_url'],
          include: [{ model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }]
        }
      ]
    });

    res.status(201).json(resultado);
  } catch (error) {
    console.error('Error al crear estación:', error);
    res.status(500).json({ message: 'Error al crear estación: ' + error.message });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { codigo_estacion, ambiente_id, descripcion, activo_ids } = req.body;

    const estacion = await EstacionTrabajo.findByPk(id);
    if (!estacion) {
      return res.status(404).json({ message: 'Estación de trabajo no encontrada' });
    }

    if (codigo_estacion && codigo_estacion.trim() !== estacion.codigo_estacion) {
      const repetido = await EstacionTrabajo.findOne({
        where: {
          codigo_estacion: codigo_estacion.trim().toUpperCase(),
          id: { [Op.ne]: id }
        }
      });
      if (repetido) {
        return res.status(400).json({ message: `El código ${codigo_estacion} ya está en uso` });
      }
      estacion.codigo_estacion = codigo_estacion.trim().toUpperCase();
    }

    if (ambiente_id) {
      const ambiente = await Ambiente.findByPk(ambiente_id);
      if (!ambiente) return res.status(404).json({ message: 'Ambiente no encontrado' });
      estacion.ambiente_id = ambiente_id;
    }

    if (descripcion !== undefined) {
      estacion.descripcion = descripcion ? descripcion.trim() : null;
    }

    await estacion.save();

    if (Array.isArray(activo_ids)) {
      // Desvincular los que no estén en la nueva lista
      await Activo.update(
        { estacion_id: null },
        { where: { estacion_id: estacion.id, id: { [Op.notIn]: activo_ids } } }
      );
      // Vincular los de la lista
      if (activo_ids.length > 0) {
        await Activo.update(
          { estacion_id: estacion.id, ambiente_id: estacion.ambiente_id },
          { where: { id: { [Op.in]: activo_ids } } }
        );
      }
    }

    const resultado = await EstacionTrabajo.findByPk(estacion.id, {
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
        {
          model: Activo,
          as: 'activos',
          attributes: ['id', 'codigo_activo', 'nombre', 'marca', 'modelo', 'numero_serie', 'estado', 'tipo_activo_id', 'imagen_url'],
          include: [{ model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }]
        }
      ]
    });

    res.json(resultado);
  } catch (error) {
    console.error('Error al actualizar estación:', error);
    res.status(500).json({ message: 'Error al actualizar estación: ' + error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const estacion = await EstacionTrabajo.findByPk(id);
    if (!estacion) {
      return res.status(404).json({ message: 'Estación de trabajo no encontrada' });
    }

    // Desvincular activos antes de eliminar
    await Activo.update(
      { estacion_id: null },
      { where: { estacion_id: id } }
    );

    await estacion.destroy();
    res.json({ message: 'Estación de trabajo eliminada exitosamente' });
  } catch (error) {
    console.error('Error al eliminar estación:', error);
    res.status(500).json({ message: 'Error al eliminar estación: ' + error.message });
  }
};

exports.asignarActivos = async (req, res) => {
  try {
    const { id } = req.params;
    const { activo_ids } = req.body;

    const estacion = await EstacionTrabajo.findByPk(id);
    if (!estacion) {
      return res.status(404).json({ message: 'Estación de trabajo no encontrada' });
    }

    if (!Array.isArray(activo_ids)) {
      return res.status(400).json({ message: 'activo_ids debe ser un arreglo de IDs' });
    }

    // Desvincular activos previos
    await Activo.update(
      { estacion_id: null },
      { where: { estacion_id: id } }
    );

    if (activo_ids.length > 0) {
      await Activo.update(
        { estacion_id: id, ambiente_id: estacion.ambiente_id },
        { where: { id: { [Op.in]: activo_ids } } }
      );
    }

    const resultado = await EstacionTrabajo.findByPk(id, {
      include: [
        { model: Ambiente, as: 'ambiente', attributes: ['id', 'nombre', 'codigo', 'ubicacion'] },
        {
          model: Activo,
          as: 'activos',
          attributes: ['id', 'codigo_activo', 'nombre', 'marca', 'modelo', 'numero_serie', 'estado', 'tipo_activo_id', 'imagen_url'],
          include: [{ model: TipoActivo, as: 'tipo', attributes: ['id', 'nombre', 'codigo'] }]
        }
      ]
    });

    res.json(resultado);
  } catch (error) {
    console.error('Error al asignar activos a la estación:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

