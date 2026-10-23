const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const Joi = require('joi');
const Usuario = require('../models/Usuario');

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

const login = async (req, res) => {
  const { error, value } = loginSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }

  const { email, password } = value;

  try {
    let cleanEmail = email.toLowerCase().trim();
    let user = await Usuario.findOne({ where: { email: cleanEmail } });
    if (!user && cleanEmail.endsWith('@itbm.edu')) {
      user = await Usuario.findOne({ where: { email: `${cleanEmail}.bo` } });
    }

    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Credenciales inválidas.' });
    }

    if (!user.activo) {
      return res.status(403).json({ error: 'Usuario inactivo.' });
    }

    const token = jwt.sign(
      { id: user.id, rol: user.rol.toLowerCase() },
      process.env.JWT_SECRET || 'secret_itbm_inventario_v2',
      { expiresIn: '8h' }
    );

    res.json({ token, user: { id: user.id, email: user.email, rol: user.rol, nombre: user.nombre_completo } });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error interno del servidor.' });
  }
};

module.exports = { login };
