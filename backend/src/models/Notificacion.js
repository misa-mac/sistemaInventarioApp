const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Usuario = require('./Usuario');

const Notificacion = sequelize.define('Notificacion', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  usuario_id: {
    type: DataTypes.UUID,
    allowNull: true, // Si es nulo, es global para todos
    references: { model: Usuario, key: 'id' }
  },
  titulo: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  mensaje: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  tipo: {
    type: DataTypes.STRING,
    defaultValue: 'info',
  },
  leida: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  }
}, {
  tableName: 'notificaciones',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

Notificacion.belongsTo(Usuario, { foreignKey: 'usuario_id' });

module.exports = Notificacion;
