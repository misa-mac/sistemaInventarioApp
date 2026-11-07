const request = require('supertest');
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { sequelize } = require('../database');

// Importar modelos
require('../src/models/Usuario');
const Ambiente = require('../src/models/Ambiente');
const TipoActivo = require('../src/models/TipoActivo');
const Activo = require('../src/models/Activo');
const EstacionTrabajo = require('../src/models/EstacionTrabajo');
const Auditoria = require('../src/models/Auditoria');
const DetalleAuditoria = require('../src/models/DetalleAuditoria');
const Usuario = require('../src/models/Usuario');

const authRoutes = require('../src/routes/authRoutes');
const estacionRoutes = require('../src/routes/estacionRoutes');
const auditoriaRoutes = require('../src/routes/auditoriaRoutes');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/estaciones', estacionRoutes);
app.use('/api/auditorias', auditoriaRoutes);

async function runTest() {
  try {
    await sequelize.authenticate();
    console.log('✅ DB Conectada');

    // Obtener un usuario admin
    const admin = await Usuario.findOne({ where: { rol: 'admin' } });
    if (!admin) throw new Error('No se encontró usuario admin');
    const adminToken = jwt.sign({ id: admin.id, rol: admin.rol }, process.env.JWT_SECRET || 'secret_itbm_inventario_v2', { expiresIn: '1h' });

    // Obtener un ambiente
    const ambiente = await Ambiente.findOne();
    if (!ambiente) throw new Error('No se encontró ambiente');

    // Obtener o crear tipos de activo para componentes
    const tipos = await TipoActivo.findAll({ limit: 4 });
    console.log(`✅ Tipos encontrados: ${tipos.length}`);

    // Limpiar o buscar estación de prueba
    const testCode = 'EST-TEST-01';
    await Activo.update({ estacion_id: null }, { where: {} });
    await EstacionTrabajo.destroy({ where: { codigo_estacion: testCode } });

    // Crear 4 activos de prueba vinculados al ambiente
    const activos = [];
    for (let i = 0; i < 4; i++) {
      const tipo = tipos[i % tipos.length];
      const act = await Activo.create({
        nombre: `Componente Test ${i + 1}`,
        marca: 'HP',
        modelo: `Model-${i + 1}`,
        numero_serie: `SN-TEST-00${i + 1}`,
        tipo_activo_id: tipo.id,
        ambiente_id: ambiente.id,
        ambiente_registro_id: ambiente.id,
        estado: 'Activo'
      });
      activos.push(act);
    }
    console.log(`✅ 4 activos de prueba creados`);

    // 1. Crear estación mediante endpoint POST /api/estaciones
    const resCreate = await request(app)
      .post('/api/estaciones')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        codigo_estacion: testCode,
        ambiente_id: ambiente.id,
        descripcion: 'Mesa de Laboratorio 1 - Test',
        activo_ids: activos.map(a => a.id)
      });

    console.log('POST /api/estaciones status:', resCreate.status);
    if (resCreate.status !== 201) {
      console.error(resCreate.body);
      throw new Error('Fallo al crear estación');
    }
    console.log(`✅ Estación creada con ID: ${resCreate.body.id}, activos asignados: ${resCreate.body.activos.length}`);

    // 2. Probar GET /api/estaciones/:codigo
    const resGet = await request(app)
      .get(`/api/estaciones/${testCode}`)
      .set('Authorization', `Bearer ${adminToken}`);

    console.log('GET /api/estaciones/:codigo status:', resGet.status);
    if (resGet.status !== 200 || resGet.body.componentes.length !== 4) {
      console.error(resGet.body);
      throw new Error('GET /api/estaciones/:codigo no devolvió los 4 componentes esperados');
    }
    console.log(`✅ GET /api/estaciones/${testCode} devolvió la estación con ${resGet.body.componentes.length} componentes:`);
    resGet.body.componentes.forEach(c => console.log(`   - [${c.codigo_activo}] ${c.nombre} (${c.marca} ${c.modelo}) - Estado: ${c.estado}`));

    // 3. Probar escaneo de estación en auditoría
    const auditoria = await Auditoria.create({
      ambiente_id: ambiente.id,
      auditor_id: admin.id,
      total_esperados: 4,
      estado: 'en_progreso',
      fecha_inicio: new Date()
    });

    const resAudit = await request(app)
      .post(`/api/auditorias/${auditoria.id}/detalle`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        codigo_qr_escaneado: testCode,
        estado: 'presente',
        observacion: 'Auditado vía QR General'
      });

    console.log('POST /api/auditorias/:id/detalle con QR General status:', resAudit.status);
    if (resAudit.status !== 201 || !resAudit.body.is_station || resAudit.body.componentes_auditados !== 4) {
      console.error(resAudit.body);
      throw new Error('Fallo en registro automático de los 4 componentes de la estación');
    }
    console.log(`✅ Auditoría registró los 4 componentes de la estación exitosamente!`);

    // Limpieza
    await DetalleAuditoria.destroy({ where: { auditoria_id: auditoria.id } });
    await auditoria.destroy();
    await Activo.destroy({ where: { id: activos.map(a => a.id) } });
    await EstacionTrabajo.destroy({ where: { codigo_estacion: testCode } });

    console.log('🎉 TODAS LAS PRUEBAS DE ESTACIONES DE TRABAJO Y QR GENERAL PASARON CON ÉXITO!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error en prueba:', err);
    process.exit(1);
  }
}

runTest();
