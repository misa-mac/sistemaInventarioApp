process.env.NODE_ENV = 'test';
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../index');
const { sequelize } = require('../database');
const Usuario = require('../src/models/Usuario');
const Ambiente = require('../src/models/Ambiente');
const Auditoria = require('../src/models/Auditoria');
const Notificacion = require('../src/models/Notificacion');

const JWT_SECRET = process.env.JWT_SECRET || 'secret_itbm_inventario_v2';

describe('Notificaciones Asíncronas y Sincronización Móvil', () => {
  let adminToken;
  let adminUser;
  let ambienteTest;
  let auditoriaTest;

  beforeAll(async () => {
    adminUser = await Usuario.findOne({ where: { rol: 'admin' } });
    if (!adminUser) {
      adminUser = await Usuario.create({
        nombre_completo: 'Admin Test Notif',
        email: 'admin_test_notif@itbm.edu.bo',
        password_hash: 'hash',
        rol: 'admin',
        activo: true
      });
    }

    adminToken = jwt.sign(
      { id: adminUser.id, rol: 'admin', email: adminUser.email },
      JWT_SECRET,
      { expiresIn: '2h' }
    );

    ambienteTest = await Ambiente.findOne();
    if (!ambienteTest) {
      ambienteTest = await Ambiente.create({
        codigo: 99,
        nombre: 'Laboratorio de Pruebas',
        ubicacion: 'Bloque Z',
        activo: true
      });
    }

    auditoriaTest = await Auditoria.create({
      ambiente_id: ambienteTest.id,
      auditor_id: adminUser.id,
      total_esperados: 5,
      estado: 'en_progreso'
    });
  });

  afterAll(async () => {
    if (auditoriaTest) {
      await auditoriaTest.destroy().catch(() => {});
    }
  });

  test('1. POST /api/auditorias/sync genera una notificación de tipo success al sincronizar escaneos', async () => {
    const res = await request(app)
      .post('/api/auditorias/sync')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        auditoria_id: auditoriaTest.id,
        detalles: [
          {
            codigo_qr_escaneado: 'TEST-QR-NOTIF-01',
            estado: 'presente',
            fecha_escaneo: new Date()
          },
          {
            codigo_qr_escaneado: 'TEST-QR-NOTIF-02',
            estado: 'presente',
            fecha_escaneo: new Date()
          }
        ]
      });

    expect(res.status).toBe(200);
    expect(res.body.sincronizados).toBe(2);

    // Verificar en la BD que se haya insertado la notificación
    const notif = await Notificacion.findOne({
      where: {
        titulo: 'Auditoría Sincronizada',
        tipo: 'success',
        leida: false
      },
      order: [['created_at', 'DESC']]
    });

    expect(notif).not.toBeNull();
    expect(notif.mensaje).toContain('Se han sincronizado 2 equipos del');
    expect(notif.tipo).toBe('success');
    expect(notif.leida).toBe(false);
  });

  test('2. GET /api/notificaciones devuelve la notificación pendiente al admin', async () => {
    const res = await request(app)
      .get('/api/notificaciones')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);

    const encontrada = res.body.find(n => n.titulo === 'Auditoría Sincronizada');
    expect(encontrada).toBeDefined();
    expect(encontrada.tipo).toBe('success');
  });

  test('3. POST /api/notificaciones/marcar-leidas marca como leídas las notificaciones globales', async () => {
    const res = await request(app)
      .post('/api/notificaciones/marcar-leidas')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);

    // Comprobar que en GET /api/notificaciones ya no aparece
    const resGet = await request(app)
      .get('/api/notificaciones')
      .set('Authorization', `Bearer ${adminToken}`);

    const encontrada = resGet.body.find(n => n.titulo === 'Auditoría Sincronizada');
    expect(encontrada).toBeUndefined();
  });
});

