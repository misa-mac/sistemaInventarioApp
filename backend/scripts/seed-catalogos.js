const { sequelize, connectDB } = require('../database');
const Ambiente = require('../src/models/Ambiente');
const TipoActivo = require('../src/models/TipoActivo');

const ambientes = [
  { nombre: 'Laboratorio 1', descripcion: 'Lab de computadoras', codigo: 20 },
  { nombre: 'Laboratorio 2', descripcion: 'Lab de computadoras', codigo: 21 },
  { nombre: 'Laboratorio 3', descripcion: 'Lab de computadoras', codigo: 22 },
  { nombre: 'Taller 1', descripcion: 'Espacio de trabajo técnico', codigo: 23 },
  { nombre: 'Taller 2', descripcion: 'Espacio de trabajo técnico', codigo: 24 },
  { nombre: 'Oficina Central', descripcion: 'Oficina Administrativa IT', codigo: 25 },
  { nombre: 'Depósito Central', descripcion: 'Depósito de Hardware', codigo: 26 }
];

const tipos_activos = [
  { codigo: 50, nombre: 'Teclado', descripcion: 'Periférico de entrada' },
  { codigo: 60, nombre: 'Mouse', descripcion: 'Periférico de entrada' },
  { codigo: 80, nombre: 'Pantalla/Monitor', descripcion: 'Monitor display' },
  { codigo: 10, nombre: 'CPU/Computadora', descripcion: 'Unidad central de procesamiento' },
  { codigo: 20, nombre: 'RAK', descripcion: 'Estructura servidores' },
  { codigo: 30, nombre: 'Estabilizador', descripcion: 'Dispositivo regulación energía' },
  { codigo: 40, nombre: 'Router', descripcion: 'Dispositivo red' },
  { codigo: 45, nombre: 'Switch', descripcion: 'Dispositivo red conmutación' },
  { codigo: 90, nombre: 'Mesa', descripcion: 'Mobiliario escritorio' },
  { codigo: 95, nombre: 'Silla', descripcion: 'Mobiliario asiento' }
];

async function seedCatalogos() {
  try {
    await connectDB();
    
    for (const amb of ambientes) {
      const [ambiente, created] = await Ambiente.findOrCreate({
        where: { nombre: amb.nombre },
        defaults: amb
      });
      if (!created) {
        ambiente.codigo = amb.codigo;
        await ambiente.save();
      }
      console.log(`${created ? '✅ Creado' : 'ℹ️ Actualizado'} Ambiente: ${amb.nombre} (Cod: ${amb.codigo})`);
    }

    for (const tipo of tipos_activos) {
      const [tipo_activo, created] = await TipoActivo.findOrCreate({
        where: { codigo: tipo.codigo },
        defaults: tipo
      });
      if (!created) {
        tipo_activo.nombre = tipo.nombre;
        await tipo_activo.save();
      }
      console.log(`${created ? '✅ Creado' : 'ℹ️ Actualizado'} Tipo Activo: ${tipo.nombre} (Cod: ${tipo.codigo})`);
    }

  } catch (error) {
    console.error('❌ Error insertando catálogos:', error);
  } finally {
    await sequelize.close();
    console.log('🏁 Proceso finalizado. Conexión cerrada.');
  }
}

seedCatalogos();
