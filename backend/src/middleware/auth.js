const jwt = require('jsonwebtoken');
const Usuario = require('../models/Usuario');

/**
 * Middleware de Autenticación
 * 
 * Regla 3: El rol sale del usuario autenticado, nunca del body, query ni cabeceras del cliente.
 * Carga al usuario desde la base con el id del token y usa su rol y su estado (activo = true) actuales.
 * Regla 4: Respuesta 401 si no hay sesión válida o token inválido/expirado.
 */
const auth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.startsWith('Bearer ')
      ? authHeader.split(' ')[1]
      : null;

    if (!token) {
      return res.status(401).json({ message: 'Acceso no autenticado. Token requerido.' });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_itbm_inventario_v2');
    } catch (jwtErr) {
      if (jwtErr.name === 'TokenExpiredError') {
        return res.status(401).json({ message: 'Sesión expirada. Por favor inicie sesión nuevamente.' });
      }
      return res.status(401).json({ message: 'Token de autenticación inválido.' });
    }

    if (!decoded || !decoded.id) {
      return res.status(401).json({ message: 'Token no contiene identidad de usuario.' });
    }

    // Cargar usuario desde la base de datos (según Regla 3)
    const user = await Usuario.findByPk(decoded.id);

    if (!user) {
      return res.status(401).json({ message: 'Usuario no encontrado o dado de baja.' });
    }

    if (!user.activo) {
      return res.status(401).json({ message: 'Usuario inactivo. Acceso revocado.' });
    }

    // Normalizar rol a minúsculas conforme al ENUM ('admin', 'tecnico', 'auditor')
    const rolNormalizado = (user.rol || '').toLowerCase().trim();

    req.user = {
      id: user.id,
      email: user.email,
      nombre: user.nombre_completo,
      rol: rolNormalizado
    };

    next();
  } catch (error) {
    console.error('Error en middleware auth:', error);
    return res.status(500).json({ message: 'Error interno en autenticación.' });
  }
};

module.exports = auth;
