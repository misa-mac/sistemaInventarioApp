const Usuario = require('../models/Usuario');
const bcrypt = require('bcrypt');

exports.getAll = async (req, res) => {
  try {
    const usuarios = await Usuario.findAll({
      attributes: { exclude: ['password_hash'] }
    });
    res.json(usuarios);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error interno obteniendo usuarios' });
  }
};

exports.create = async (req, res) => {
  try {
    const { nombre_completo, email, password, rol, activo } = req.body;
    
    if (!email) {
      return res.status(400).json({ message: 'El correo electrónico es requerido.' });
    }

    const cleanEmail = email.toLowerCase().trim();

    // Verificar si el email ya existe
    const existente = await Usuario.findOne({ where: { email: cleanEmail } });
    if (existente) {
      return res.status(400).json({ message: 'El correo electrónico ya está registrado.' });
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const nuevoUsuario = await Usuario.create({
      nombre_completo,
      email: cleanEmail,
      password_hash,
      rol: rol || 'tecnico',
      activo: activo !== undefined ? activo : true
    });

    const { password_hash: _, ...userWithoutPass } = nuevoUsuario.toJSON();
    res.status(201).json(userWithoutPass);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al crear usuario: ' + error.message });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre_completo, email, password, rol, activo } = req.body;
    
    const usuario = await Usuario.findByPk(id);
    if (!usuario) return res.status(404).json({ message: 'Usuario no encontrado' });

    const updateData = { nombre_completo, rol, activo };

    if (email) {
      const cleanEmail = email.toLowerCase().trim();
      if (cleanEmail !== usuario.email) {
        const existente = await Usuario.findOne({ where: { email: cleanEmail } });
        if (existente) return res.status(400).json({ message: 'El correo electrónico ya está en uso por otro usuario.' });
        updateData.email = cleanEmail;
      }
    }

    if (password && password.trim() !== '') {
      const salt = await bcrypt.genSalt(10);
      updateData.password_hash = await bcrypt.hash(password, salt);
    }

    await usuario.update(updateData);
    
    const { password_hash: _, ...userWithoutPass } = usuario.toJSON();
    res.json(userWithoutPass);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar usuario: ' + error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (req.user && req.user.id === id) {
      return res.status(400).json({ message: 'No puedes eliminar tu propio usuario.' });
    }

    const usuario = await Usuario.findByPk(id);
    if (!usuario) return res.status(404).json({ message: 'Usuario no encontrado' });
    
    await usuario.destroy();
    res.json({ message: 'Usuario eliminado correctamente' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar usuario' });
  }
};
