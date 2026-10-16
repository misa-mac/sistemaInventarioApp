const TipoActivo = require('../models/TipoActivo');

exports.getAll = async (req, res) => {
  try {
    const tipos = await TipoActivo.findAll({ order: [['codigo', 'ASC']] });
    res.json(tipos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getById = async (req, res) => {
  try {
    const tipo = await TipoActivo.findByPk(req.params.id);
    if (!tipo) return res.status(404).json({ message: 'Tipo no encontrado' });
    res.json(tipo);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.create = async (req, res) => {
  try {
    const { codigo, nombre, descripcion } = req.body;

    const numCodigo = parseInt(codigo);
    if (isNaN(numCodigo) || numCodigo < 0 || numCodigo > 99) {
      return res.status(400).json({ message: 'El código (AA) debe ser un número entero entre 0 y 99.' });
    }

    if (!nombre || nombre.trim() === '') {
      return res.status(400).json({ message: 'El nombre es requerido.' });
    }

    const nuevo = await TipoActivo.create({ 
      codigo: numCodigo, 
      nombre: nombre.trim(), 
      descripcion,
      activo: true
    });
    res.status(201).json(nuevo);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al crear tipo de activo: ' + error.message });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { codigo, nombre, descripcion, activo } = req.body;
    const tipo = await TipoActivo.findByPk(id);
    if (!tipo) return res.status(404).json({ message: 'No encontrado' });

    const updateData = {};
    if (codigo !== undefined) {
      const numCodigo = parseInt(codigo);
      if (isNaN(numCodigo) || numCodigo < 0 || numCodigo > 99) {
        return res.status(400).json({ message: 'El código (AA) debe ser un número entero entre 0 y 99.' });
      }
      updateData.codigo = numCodigo;
    }
    if (nombre !== undefined) updateData.nombre = nombre.trim();
    if (descripcion !== undefined) updateData.descripcion = descripcion;
    if (activo !== undefined) updateData.activo = activo;

    await tipo.update(updateData);
    res.json(tipo);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar tipo de activo: ' + error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const tipo = await TipoActivo.findByPk(id);
    if (!tipo) return res.status(404).json({ message: 'No encontrado' });
    
    await tipo.destroy();
    res.json({ message: 'Tipo eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar. Puede que tenga activos asociados.' });
  }
};
