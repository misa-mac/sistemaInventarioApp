const { Sequelize } = require('sequelize');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '.env') });

const sequelize = new Sequelize(process.env.DATABASE_URL || 'postgresql://postgres:123@localhost:5432/inventario_db', {
  dialect: 'postgres',
  logging: false, // console.log to see SQL queries
  pool: { max: 5, min: 0, acquire: 30000, idle: 10000 }
});

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Base de datos conectada vía Sequelize');
  } catch (error) {
    console.error('❌ Error conectando a la base de datos:', error.message);
  }
};

module.exports = { sequelize, connectDB };
