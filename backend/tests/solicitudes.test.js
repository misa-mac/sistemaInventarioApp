process.env.NODE_ENV = 'test';
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../index');
const { sequelize } = require('../database');
const Usuario = require('../src/models/Usuario');
const Ambiente = require('../src/models/Ambiente');
const TipoActivo = require('../src/models/TipoActivo');
const Activo = require('../src/models/Activo');
const Movimiento = require('../src/models/Movimiento');
const SolicitudCambio = require('../src/models/SolicitudCambio');

const JWT_SECRET = process.env.JWT_SECRET || 'secret_itbm_inventario_v2';

describe('Gobernanza de Inventario - Suite de Pruebas de Solicitudes y Seguridad RBAC', () => {
  let adminToken;
  let tecnicoToken;
  let adminUser;
  let tecnicoUser;
  let ambienteTest;
  let tipoTest;

  beforeAll(async () => {
    // Buscar o crear usuarios para pruebas
    adminUser = await Usuario.findOne({ where: { email: 'misa@gmail.com' } });
    if (!adminUser) {
      adminUser = await Usuario.create({
        nombre_completo: 'Admin Test',
        email: 'misa@gmail.com',
        password_hash: 'hash',
        rol: 'admin',
        activo: true
      });
    }

    tecnicoUser = await Usuario.findOne({ where: { email: 'tecnico@itbm.edu.bo' } });
    if (!tecnicoUser) {
      tecnicoUser = await Usuario.create({
        nombre_completo: 'Tecnico Test',
        email: 'tecnico@itbm.edu.bo',
        password_hash: 'hash',
        rol: 'tecnico',
        activo: true
      });
    }

    adminToken = jwt.sign({ id: adminUser.id, rol: 'admin', email: adminUser.email }, JWT_SECRET, { expiresIn: '2h' });
    tecnicoToken = jwt.sign({ id: tecnicoUser.id, rol: 'tecnico', email: tecnicoUser.email }, JWT_SECRET, { expiresIn: '2h' });

    ambienteTest = await Ambiente.findOne();
    tipoTest = await TipoActivo.findOne();
  });

  afterAll(async () => {
    await sequelize.close();
  });

  // 1. Técnico crea solicitudes pero no puede aprobar ni escribir activos directamente
  test('1. El técnico crea solicitudes de alta pero no puede aprobarlas ni escribir activos directamente', async () => {
    // A) Técnico crea solicitud de alta -> 201
    const resCrear = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        tipo: 'alta',
        datos: {
          nombre: 'Monitor LG Test',
          marca: 'LG',
          modelo: 'UltraGear',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id,
          valor: 250,
          estado: 'Activo'
        }
      });

    expect(resCrear.status).toBe(201);
    expect(resCrear.body.tipo).toBe('alta');
    expect(resCrear.body.estado).toBe('pendiente');
    expect(resCrear.body.solicitante_id).toBe(tecnicoUser.id);
    const solicitudId = resCrear.body.id;

    // B) Técnico intenta aprobar -> 403
    const resAprobarTecnico = await request(app)
      .post(`/api/solicitudes/${solicitudId}/aprobar`)
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send();

    expect(resAprobarTecnico.status).toBe(403);

    // C) Técnico intenta escribir activo directamente (POST /api/activos) -> 403
    const resEscribirDirecto = await request(app)
      .post('/api/activos')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        nombre: 'Intento Directo',
        ambiente_id: ambienteTest.id,
        tipo_activo_id: tipoTest.id
      });

    expect(resEscribirDirecto.status).toBe(403);
  });

  // 2. Admin aprueba una alta (el activo nace con código XYZAACC-GG generado por el trigger)
  test('2. El admin aprueba una alta: el activo nace con código que cumple el formato XYZAACC-GG', async () => {
    const resCrear = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        tipo: 'alta',
        datos: {
          nombre: 'CPU HP Gobernanza',
          marca: 'HP',
          modelo: 'ProDesk 400',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id,
          valor: 600,
          estado: 'Activo'
        }
      });

    expect(resCrear.status).toBe(201);
    const solId = resCrear.body.id;

    // Admin aprueba
    const resAprobar = await request(app)
      .post(`/api/solicitudes/${solId}/aprobar`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send();

    expect(resAprobar.status).toBe(200);
    expect(resAprobar.body.solicitud.estado).toBe('aprobada');
    expect(resAprobar.body.solicitud.activo_resultante_id).toBeDefined();

    // Verificar en la BD el activo creado
    const activoCreado = await Activo.findByPk(resAprobar.body.solicitud.activo_resultante_id);
    expect(activoCreado).not.toBeNull();
    // Validar formato estricto XYZAACC-GG: '1' + 2 dígitos año + 2 dígitos tipo + 2 dígitos ambiente + '-' + 2 dígitos correlativo
    expect(activoCreado.codigo_activo).toMatch(/^1[0-9]{6}-[0-9]{2}$/);
    expect(activoCreado.numero_correlativo).toBeGreaterThan(0);
  });

  // 3. Admin aprueba una edición (solo campos permitidos)
  test('3. El admin aprueba una edición: solo actualiza campos permitidos, inmutables quedan intactos', async () => {
    // Crear un activo base
    const resCrearSol = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        tipo: 'alta',
        datos: {
          nombre: 'Teclado Original',
          marca: 'Genius',
          modelo: 'K215',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id,
          valor: 15,
          estado: 'Activo'
        }
      });
    const resApr = await request(app)
      .post(`/api/solicitudes/${resCrearSol.body.id}/aprobar`)
      .set('Authorization', `Bearer ${adminToken}`);
    
    const activoId = resApr.body.solicitud.activo_resultante_id;
    const activoAntes = await Activo.findByPk(activoId);

    // Técnico solicita edición
    const resSolEdit = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        tipo: 'edicion',
        activo_id: activoId,
        datos: {
          marca: 'Genius RGB Modificado',
          valor: 35,
          observaciones: 'Teclado retroiluminado',
          // Intento malicioso de alterar código o ambiente de registro
          codigo_activo: '9999999-99',
          tipo_activo_id: '00000000-0000-0000-0000-000000000000'
        }
      });
    expect(resSolEdit.status).toBe(201);

    // Admin aprueba edición
    const resAprobarEdit = await request(app)
      .post(`/api/solicitudes/${resSolEdit.body.id}/aprobar`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resAprobarEdit.status).toBe(200);

    // Comprobar activo en BD
    const activoDespues = await Activo.findByPk(activoId);
    expect(activoDespues.marca).toBe('Genius RGB Modificado');
    expect(Number(activoDespues.valor)).toBe(35);
    expect(activoDespues.observaciones).toBe('Teclado retroiluminado');
    // Código y tipo no cambiaron
    expect(activoDespues.codigo_activo).toBe(activoAntes.codigo_activo);
    expect(activoDespues.tipo_activo_id).toBe(activoAntes.tipo_activo_id);
  });

  // 4. Admin aprueba una baja (estado Inactivo, movimiento 'baja', fila intacta)
  test('4. El admin aprueba una baja: estado Inactivo, movimiento registrado, fila intacta sin borrado físico', async () => {
    // Crear activo
    const solAlta = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        tipo: 'alta',
        datos: {
          nombre: 'Mouse para dar de baja',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id,
          estado: 'Activo'
        }
      });
    const aprAlta = await request(app).post(`/api/solicitudes/${solAlta.body.id}/aprobar`).set('Authorization', `Bearer ${adminToken}`);
    const activoId = aprAlta.body.solicitud.activo_resultante_id;

    // Solicitar baja
    const resBaja = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        tipo: 'baja',
        activo_id: activoId,
        motivo: 'Placa madre quemada e irrecuperable'
      });
    expect(resBaja.status).toBe(201);

    // Aprobar baja
    const resAprBaja = await request(app)
      .post(`/api/solicitudes/${resBaja.body.id}/aprobar`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(resAprBaja.status).toBe(200);

    // Verificar en BD
    const activoEnBD = await Activo.findByPk(activoId);
    expect(activoEnBD).not.toBeNull(); // Fila intacta (sin borrado físico)
    expect(activoEnBD.estado).toBe('Inactivo');

    // Verificar movimiento tipo baja
    const movBaja = await Movimiento.findOne({
      where: { activo_id: activoId, tipo_evento: 'baja' }
    });
    expect(movBaja).not.toBeNull();
    expect(movBaja.observaciones).toBe('Placa madre quemada e irrecuperable');
  });

  // 5. Rechazar sin comentario falla
  test('5. Rechazar solicitud sin comentario obligatorio falla con 400', async () => {
    const sol = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        tipo: 'alta',
        datos: {
          nombre: 'Item para rechazar',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id
        }
      });

    // Rechazo sin comentario -> 400
    const resRechazarSinComentario = await request(app)
      .post(`/api/solicitudes/${sol.body.id}/rechazar`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ comentario: '' });

    expect(resRechazarSinComentario.status).toBe(400);

    // Rechazo con comentario -> 200
    const resRechazarConComentario = await request(app)
      .post(`/api/solicitudes/${sol.body.id}/rechazar`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ comentario: 'No se cuenta con factura de compra' });

    expect(resRechazarConComentario.status).toBe(200);
    expect(resRechazarConComentario.body.solicitud.estado).toBe('rechazada');
    expect(resRechazarConComentario.body.solicitud.comentario_revision).toBe('No se cuenta con factura de compra');
  });

  // 6. Una solicitud resuelta no se puede volver a modificar
  test('6. Una solicitud ya resuelta (aprobada o rechazada) no se puede volver a procesar', async () => {
    const sol = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        tipo: 'alta',
        datos: {
          nombre: 'Item único',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id
        }
      });

    await request(app).post(`/api/solicitudes/${sol.body.id}/rechazar`).set('Authorization', `Bearer ${adminToken}`).send({ comentario: 'Rechazado' });

    // Intentar aprobar solicitud rechazada -> 400
    const resReaprobar = await request(app)
      .post(`/api/solicitudes/${sol.body.id}/aprobar`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send();

    expect(resReaprobar.status).toBe(400);
  });

  // 7. Reenviar el mismo id no duplica (Idempotencia)
  test('7. Idempotencia: reenviar la solicitud con el mismo id UUID responde la existente sin duplicar', async () => {
    const customId = crypto.randomUUID();

    // Primer envío
    const res1 = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        id: customId,
        tipo: 'alta',
        datos: {
          nombre: 'Equipo Offline Sync Test',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id
        }
      });
    expect(res1.status).toBe(201);
    expect(res1.body.id).toBe(customId);

    // Segundo envío (simulando reintento por fallo de red en móvil)
    const res2 = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${tecnicoToken}`)
      .send({
        id: customId,
        tipo: 'alta',
        datos: {
          nombre: 'Equipo Offline Sync Test',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id
        }
      });
    expect(res2.status).toBe(200);
    expect(res2.body.id).toBe(customId);

    // Comprobar que en BD solo existe 1 registro con ese ID
    const conteo = await SolicitudCambio.count({ where: { id: customId } });
    expect(conteo).toBe(1);
  });

  // 8. Con X-Client: mobile, aprobar o escribir activos da 403
  test('8. Cabecera X-Client: mobile responde 403 ("Esta acción se confirma en la web")', async () => {
    const sol = await request(app)
      .post('/api/solicitudes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        tipo: 'alta',
        datos: {
          nombre: 'Item test mobile header',
          tipo_activo_id: tipoTest.id,
          ambiente_id: ambienteTest.id
        }
      });

    // A) Aprobar con X-Client: mobile -> 403
    const resAprobarMovil = await request(app)
      .post(`/api/solicitudes/${sol.body.id}/aprobar`)
      .set('Authorization', `Bearer ${adminToken}`)
      .set('X-Client', 'mobile')
      .send();

    expect(resAprobarMovil.status).toBe(403);
    expect(resAprobarMovil.body.message).toBe('Esta acción se confirma en la web');

    // B) Rechazar con X-Client: mobile -> 403
    const resRechazarMovil = await request(app)
      .post(`/api/solicitudes/${sol.body.id}/rechazar`)
      .set('Authorization', `Bearer ${adminToken}`)
      .set('X-Client', 'mobile')
      .send({ comentario: 'Rechazo' });

    expect(resRechazarMovil.status).toBe(403);
    expect(resRechazarMovil.body.message).toBe('Esta acción se confirma en la web');

    // C) Escritura directa de activos con X-Client: mobile -> 403
    const resCrearActivoMovil = await request(app)
      .post('/api/activos')
      .set('Authorization', `Bearer ${adminToken}`)
      .set('X-Client', 'mobile')
      .send({
        nombre: 'Activo desde movil',
        ambiente_id: ambienteTest.id,
        tipo_activo_id: tipoTest.id
      });

    expect(resCrearActivoMovil.status).toBe(403);
    expect(resCrearActivoMovil.body.message).toBe('Esta acción se confirma en la web');
  });
});
