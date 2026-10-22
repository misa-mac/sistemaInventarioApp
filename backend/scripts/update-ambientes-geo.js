const { sequelize, connectDB } = require('../database');
const Ambiente = require('../src/models/Ambiente');

const ambientesData = [
  {
    codigo: 20,
    nombre: 'Laboratorio 1',
    ubicacion: 'Bloque A - Planta Alta',
    descripcion: 'Lab de computadoras',
    latitude: -16.57773800,
    longitude: -68.19655600,
    radio_geofence: 18.00,
    tiene_internet: true
  },
  {
    codigo: 21,
    nombre: 'Laboratorio 2',
    ubicacion: 'Bloque A - Planta Alta',
    descripcion: 'Lab de computadoras',
    latitude: -16.57766000,
    longitude: -68.19660200,
    radio_geofence: 17.00,
    tiene_internet: true
  },
  {
    codigo: 22,
    nombre: 'Laboratorio 3',
    ubicacion: 'Bloque B - Planta Baja',
    descripcion: 'Lab de computadoras',
    latitude: -16.57789200,
    longitude: -68.19676800,
    radio_geofence: 22.00,
    tiene_internet: true
  },
  {
    codigo: 23,
    nombre: 'Taller 1',
    ubicacion: 'Bloque C - Técnico',
    descripcion: 'Espacio de trabajo técnico',
    latitude: -16.57784000,
    longitude: -68.19659000,
    radio_geofence: 18.00,
    tiene_internet: false
  },
  {
    codigo: 24,
    nombre: 'Taller 2',
    ubicacion: 'Bloque C - Técnico',
    descripcion: 'Espacio de trabajo técnico',
    latitude: -16.57785000,
    longitude: -68.19658000,
    radio_geofence: 18.00,
    tiene_internet: false
  },
  {
    codigo: 25,
    nombre: 'Oficina Central',
    ubicacion: 'Edificio Administrativo',
    descripcion: 'Oficina Administrativa IT',
    latitude: -16.57778500,
    longitude: -68.19652000,
    radio_geofence: 15.00,
    tiene_internet: true
  },
  {
    codigo: 26,
    nombre: 'Depósito Central',
    ubicacion: 'Bloque D - Almacén',
    descripcion: 'Depósito de Hardware',
    latitude: -16.57780000,
    longitude: -68.19660000,
    radio_geofence: 50.00,
    tiene_internet: false
  }
];

async function updateAmbientesGeo() {
  try {
    await connectDB();
    for (const amb of ambientesData) {
      const record = await Ambiente.findOne({ where: { codigo: amb.codigo } });
      if (record) {
        await record.update({
          nombre: amb.nombre,
          ubicacion: amb.ubicacion,
          descripcion: amb.descripcion,
          latitude: amb.latitude,
          longitude: amb.longitude,
          radio_geofence: amb.radio_geofence,
          tiene_internet: amb.tiene_internet
        });
        console.log(`✅ Actualizado Ambiente [${amb.codigo}] ${amb.nombre} -> Ubicación: ${amb.ubicacion}, Coords: (${amb.latitude}, ${amb.longitude}), Radio: ${amb.radio_geofence}m`);
      } else {
        await Ambiente.create(amb);
        console.log(`✅ Creado Ambiente [${amb.codigo}] ${amb.nombre}`);
      }
    }
    console.log('🎉 Todos los ambientes fueron actualizados con éxito con coordenadas y ubicación oficial.');
  } catch (err) {
    console.error('❌ Error actualizando ambientes:', err);
  } finally {
    await sequelize.close();
  }
}

updateAmbientesGeo();
