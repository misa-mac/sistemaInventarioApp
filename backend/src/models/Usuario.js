const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');

const Usuario = sequelize.define('Usuario', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  password_hash: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  nombre_completo: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  rol: {
    type: DataTypes.ENUM('admin', 'tecnico', 'auditor'),
    defaultValue: 'tecnico',
    allowNull: false,
  },
  activo: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: 'usuarios',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Usuario;
