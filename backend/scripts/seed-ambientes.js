const { sequelize, connectDB } = require('../database');
const Ambiente = require('../src/models/Ambiente');

const ambientes = [
  { nombre: 'Laboratorio 1', descripcion: 'Laboratorio de Informática Principal', tiene_internet: true },
  { nombre: 'Laboratorio 2', descripcion: 'Laboratorio de Redes y Sistemas', tiene_internet: true },
  { nombre: 'Laboratorio 3', descripcion: 'Laboratorio de Desarrollo de Software', tiene_internet: true },
  { nombre: 'Taller 1', descripcion: 'Taller de Ensamblaje y Mantenimiento', tiene_internet: false },
  { nombre: 'Taller 2', descripcion: 'Taller de Electrónica', tiene_internet: false },
  { nombre: 'Oficina Central', descripcion: 'Oficina Administrativa IT', tiene_internet: true },
  { nombre: 'Depósito Central', descripcion: 'Depósito de Hardware y Equipos en Desuso', tiene_internet: false }
];

async function seedAmbientes() {
  try {
    await connectDB();
    await sequelize.sync({ alter: true });
    
    for (const amb of ambientes) {
      const [ambiente, created] = await Ambiente.findOrCreate({
        where: { nombre: amb.nombre },
        defaults: amb
      });
      
      if (created) {
        console.log(`✅ Ambiente creado: ${amb.nombre}`);
      } else {
        console.log(`ℹ️ Ambiente ya existía: ${amb.nombre}`);
      }
    }
  } catch (error) {
    console.error('❌ Error insertando ambientes:', error);
  } finally {
    await sequelize.close();
    console.log('🏁 Proceso finalizado. Conexión cerrada.');
  }
}

seedAmbientes();
