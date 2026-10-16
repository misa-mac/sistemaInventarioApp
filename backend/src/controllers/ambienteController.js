const Ambiente = require('../models/Ambiente');

exports.getAll = async (req, res) => {
  try {
    const ambientes = await Ambiente.findAll({
      order: [['codigo', 'ASC']]
    });
    res.json(ambientes);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getById = async (req, res) => {
  try {
    const ambiente = await Ambiente.findByPk(req.params.id);
    if (!ambiente) return res.status(404).json({ message: 'Ambiente no encontrado' });
    res.json(ambiente);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.create = async (req, res) => {
  try {
    const { codigo, nombre, descripcion, ubicacion, latitude, longitude, radio_geofence, tiene_internet } = req.body;
    
    const numCodigo = parseInt(codigo);
    if (isNaN(numCodigo) || numCodigo < 0 || numCodigo > 99) {
      return res.status(400).json({ message: 'El código (CC) debe ser un número entero entre 0 y 99.' });
    }

    if (!nombre || nombre.trim() === '') {
      return res.status(400).json({ message: 'El nombre del ambiente es requerido.' });
    }

    const lat = (latitude !== undefined && latitude !== '' && latitude !== null) ? parseFloat(latitude) : null;
    const lng = (longitude !== undefined && longitude !== '' && longitude !== null) ? parseFloat(longitude) : null;
    if ((lat === null) !== (lng === null)) {
      return res.status(400).json({ message: 'Debe proporcionar ambas coordenadas (latitud y longitud) o ninguna.' });
    }

    const nuevo = await Ambiente.create({ 
      codigo: numCodigo, 
      nombre: nombre.trim(), 
      descripcion,
      ubicacion,
      latitude: lat,
      longitude: lng,
      radio_geofence: radio_geofence || 50,
      tiene_internet: tiene_internet !== undefined ? tiene_internet : true,
      activo: true
    });
    res.status(201).json(nuevo);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al crear ambiente: ' + error.message });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { codigo, nombre, descripcion, ubicacion, latitude, longitude, radio_geofence, tiene_internet, activo } = req.body;
    const ambiente = await Ambiente.findByPk(id);
    if (!ambiente) return res.status(404).json({ message: 'No encontrado' });

    const updateData = {};
    if (codigo !== undefined) {
      const numCodigo = parseInt(codigo);
      if (isNaN(numCodigo) || numCodigo < 0 || numCodigo > 99) {
        return res.status(400).json({ message: 'El código (CC) debe ser un número entero entre 0 y 99.' });
      }
      updateData.codigo = numCodigo;
    }
    if (nombre !== undefined) updateData.nombre = nombre.trim();
    if (descripcion !== undefined) updateData.descripcion = descripcion;
    if (ubicacion !== undefined) updateData.ubicacion = ubicacion;

    let finalLat = ambiente.latitude;
    let finalLng = ambiente.longitude;

    if (latitude !== undefined) {
      finalLat = (latitude !== '' && latitude !== null) ? parseFloat(latitude) : null;
      updateData.latitude = finalLat;
    }
    if (longitude !== undefined) {
      finalLng = (longitude !== '' && longitude !== null) ? parseFloat(longitude) : null;
      updateData.longitude = finalLng;
    }

    if ((finalLat === null) !== (finalLng === null)) {
      return res.status(400).json({ message: 'Debe proporcionar ambas coordenadas (latitud y longitud) o ninguna.' });
    }

    if (radio_geofence !== undefined) updateData.radio_geofence = radio_geofence;
    if (tiene_internet !== undefined) updateData.tiene_internet = tiene_internet;
    if (activo !== undefined) updateData.activo = activo;

    await ambiente.update(updateData);
    res.json(ambiente);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar ambiente: ' + error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const ambiente = await Ambiente.findByPk(id);
    if (!ambiente) return res.status(404).json({ message: 'No encontrado' });
    
    await ambiente.destroy();
    res.json({ message: 'Ambiente eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar ambiente. Puede que tenga activos asociados.' });
  }
};
