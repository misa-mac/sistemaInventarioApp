const express = require('express');
const cors = require('cors');
const path = require('path');
const dotenv = require('dotenv');
const { sequelize, connectDB } = require('./database');

// Importar Modelos para registrarlos antes del sync
require('./src/models/Usuario');
require('./src/models/Ambiente');
require('./src/models/TipoActivo');
require('./src/models/Activo');
require('./src/models/Movimiento');
require('./src/models/Notificacion');
require('./src/models/Auditoria');
require('./src/models/DetalleAuditoria');
require('./src/models/AuditLog');

// Importar Rutas
const authRoutes = require('./src/routes/authRoutes');
const inventoryRoutes = require('./src/routes/inventoryRoutes');
const ambienteRoutes = require('./src/routes/ambienteRoutes');
const tipoActivoRoutes = require('./src/routes/tipoActivoRoutes');
const reportRoutes = require('./src/routes/reportRoutes');
const usuarioRoutes = require('./src/routes/usuarioRoutes');
const movimientoRoutes = require('./src/routes/movimientoRoutes');
const notificacionRoutes = require('./src/routes/notificacionRoutes');
const auditoriaRoutes = require('./src/routes/auditoriaRoutes');
const auditLogRoutes = require('./src/routes/auditLogRoutes');

dotenv.config();

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Servir archivos estáticos
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/activos', inventoryRoutes); // Alias para la app móvil
app.use('/api/ambientes', ambienteRoutes);
app.use('/api/tipos-activos', tipoActivoRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/usuarios', usuarioRoutes);
app.use('/api/movimientos', movimientoRoutes);
app.use('/api/notificaciones', notificacionRoutes);
app.use('/api/auditorias', auditoriaRoutes);
app.use('/api/audit-logs', auditLogRoutes);

// Configuración Servidor
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('API v2 Sistema de Inventario Funcionando 🚀');
});

const startServer = async () => {
  await connectDB();
  
  try {
    // Sincronización segura sin alterar triggers o ENUMs nativos
    await sequelize.sync();
    console.log('✅ Modelos de BD listos.');
  } catch (err) {
    console.warn('⚠️ Nota sobre sincronización Sequelize:', err.message);
  }

  app.listen(PORT, () => {
    console.log(`✅ Servidor corriendo en puerto ${PORT}`);
  });
};

startServer();
