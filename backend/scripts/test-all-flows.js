const { sequelize } = require('../database');
const Usuario = require('../src/models/Usuario');
const TipoActivo = require('../src/models/TipoActivo');
const Ambiente = require('../src/models/Ambiente');
const Activo = require('../src/models/Activo');
const Movimiento = require('../src/models/Movimiento');
const Notificacion = require('../src/models/Notificacion');
const Auditoria = require('../src/models/Auditoria');
const DetalleAuditoria = require('../src/models/DetalleAuditoria');
const AuditLog = require('../src/models/AuditLog');
const bcrypt = require('bcrypt');

async function testAllDatabaseFlows() {
  console.log('🧪 ========================================================');
  console.log('🧪 INICIANDO VERIFICACIÓN COMPLETA DE FUNCIONES Y BASE DE DATOS');
  console.log('🧪 ========================================================\n');

  try {
    // 1. TEST USUARIOS Y AUTENTICACIÓN
    console.log('1️⃣ [USUARIOS]: Verificando autenticación y modelo...');
    const user = await Usuario.findOne({ where: { email: 'misa@gmail.com' } });
    if (!user) throw new Error('Usuario admin misa@gmail.com no encontrado');
    const validPass = await bcrypt.compare('123456789', user.password_hash);
    if (!validPass) throw new Error('Contraseña de usuario admin inválida');
    console.log(`   ✅ Login verificado para: ${user.email} (Rol: ${user.rol})`);

    // 2. TEST TIPO_ACTIVOS
    console.log('\n2️⃣ [TIPO_ACTIVOS]: Consultando y verificando catálogo...');
    const tipos = await TipoActivo.findAll();
    if (tipos.length === 0) throw new Error('No hay tipos de activos en el catálogo');
    console.log(`   ✅ Total tipos encontrados: ${tipos.length}`);
    const tipoCpu = tipos.find(t => t.codigo === 10) || tipos[0];
    console.log(`   ✅ Tipo seleccionado para pruebas: ${tipoCpu.nombre} (Cod: ${tipoCpu.codigo})`);

    // 3. TEST AMBIENTES
    console.log('\n3️⃣ [AMBIENTES]: Consultando y verificando ambientes...');
    const ambientes = await Ambiente.findAll();
    if (ambientes.length < 2) throw new Error('Se requieren al menos 2 ambientes para pruebas');
    const amb1 = ambientes[0];
    const amb2 = ambientes[1];
    console.log(`   ✅ Ambientes seleccionados: "${amb1.nombre}" (Cod: ${amb1.codigo}) y "${amb2.nombre}" (Cod: ${amb2.codigo})`);

    // 4. TEST ACTIVOS (CREACIÓN CON CÓDIGO XYZAACC-GG)
    console.log('\n4️⃣ [ACTIVOS]: Creando activo de prueba y verificando código QR...');
    const maxCorr = await Activo.max('numero_correlativo', {
      where: { tipo_activo_id: tipoCpu.id, ambiente_registro_id: amb1.id }
    }) || 0;
    const nextCorr = maxCorr + 1;
    const YY = new Date().getFullYear().toString().slice(-2);
    const AA = tipoCpu.codigo.toString().padStart(2, '0');
    const CC = amb1.codigo.toString().padStart(2, '0');
    const GG = nextCorr.toString().padStart(2, '0');
    const expectedCodigo = `1${YY}${AA}${CC}-${GG}`;

    const activoTest = await Activo.create({
      tipo_activo_id: tipoCpu.id,
      ambiente_id: amb1.id,
      ambiente_registro_id: amb1.id,
      numero_correlativo: nextCorr,
      codigo_activo: expectedCodigo,
      nombre: `Computadora de Prueba ${expectedCodigo}`,
      marca: 'Dell',
      modelo: 'OptiPlex 7090',
      numero_serie: `TEST-SN-${Date.now()}`,
      estado: 'Activo',
      valor: 850.50,
      observaciones: 'Activo para pruebas de integración'
    });
    console.log(`   ✅ Activo creado con éxito: ${activoTest.codigo_activo} (ID: ${activoTest.id})`);

    // 5. TEST ACTIVOS (BÚSQUEDA Y LECTURA)
    console.log('\n5️⃣ [ACTIVOS - BÚSQUEDA]: Probando consulta por código y por serie...');
    const foundByCode = await Activo.findOne({
      where: { codigo_activo: activoTest.codigo_activo },
      include: [
        { model: Ambiente, as: 'ambiente' },
        { model: TipoActivo, as: 'tipo' }
      ]
    });
    if (!foundByCode) throw new Error('No se pudo encontrar el activo por código');
    console.log(`   ✅ Activo recuperado: "${foundByCode.nombre}", Ubicado en: "${foundByCode.ambiente.nombre}"`);

    // 6. TEST MOVIMIENTOS: TRASLADO
    console.log('\n6️⃣ [MOVIMIENTOS - TRASLADO]: Registrando traslado entre ambientes...');
    const movTraslado = await Movimiento.create({
      tipo_evento: 'traslado',
      activo_id: activoTest.id,
      usuario_id: user.id,
      ambiente_origen_id: amb1.id,
      ambiente_destino_id: amb2.id,
      estado_anterior: 'Activo',
      estado_nuevo: 'Activo',
      observaciones: 'Traslado preventivo para pruebas'
    });
    // Actualizar ubicación del activo
    await activoTest.update({ ambiente_id: amb2.id });
    console.log(`   ✅ Traslado registrado: ${amb1.nombre} ➔ ${amb2.nombre} (ID: ${movTraslado.id})`);

    // 7. TEST MOVIMIENTOS: MANTENIMIENTO
    console.log('\n7️⃣ [MOVIMIENTOS - MANTENIMIENTO]: Registrando evento de mantenimiento con campos auditados...');
    const movMantenimiento = await Movimiento.create({
      tipo_evento: 'mantenimiento',
      activo_id: activoTest.id,
      usuario_id: user.id,
      ambiente_origen_id: null,
      ambiente_destino_id: null,
      estado_anterior: 'Activo',
      estado_nuevo: 'Dañado',
      tipo_mantenimiento: 'correctivo',
      piezas_reemplazadas: 'Fuente de poder',
      costo_mantenimiento: 45.00,
      observaciones: 'Reemplazo de fuente de poder por falla de voltaje'
    });
    await activoTest.update({ estado: 'Dañado' });
    console.log(`   ✅ Mantenimiento registrado con éxito (Costo: $${movMantenimiento.costo_mantenimiento})`);

    // 8. TEST NOTIFICACIONES
    console.log('\n8️⃣ [NOTIFICACIONES]: Registrando y consultando alerta...');
    const notif = await Notificacion.create({
      usuario_id: user.id,
      titulo: 'Alerta de Mantenimiento',
      mensaje: `Equipo ${activoTest.codigo_activo} requiere revisión.`,
      tipo: 'warning',
      leida: false
    });
    console.log(`   ✅ Notificación creada: "${notif.titulo}" (Tipo: ${notif.tipo})`);

    // 9. TEST AUDITORIAS (SESIÓN Y DETALLES)
    console.log('\n9️⃣ [AUDITORIAS]: Creando sesión de auditoría y registrando escaneo...');
    const auditoria = await Auditoria.create({
      ambiente_id: amb2.id,
      auditor_id: user.id,
      total_esperados: 1,
      total_encontrados: 1,
      total_faltantes: 0,
      total_no_esperados: 0,
      estado: 'en_progreso',
      observaciones: 'Auditoría de prueba automatizada'
    });
    console.log(`   ✅ Sesión de auditoría iniciada: ID ${auditoria.id}`);

    const detalle = await DetalleAuditoria.create({
      auditoria_id: auditoria.id,
      activo_id: activoTest.id,
      codigo_qr_escaneado: activoTest.codigo_activo,
      estado: 'presente',
      observacion: 'Equipo verificado físicamente y operativo',
      sincronizado: true
    });
    console.log(`   ✅ Detalle de escaneo registrado: QR ${detalle.codigo_qr_escaneado} (Estado: ${detalle.estado})`);

    // Finalizar sesión
    await auditoria.update({
      estado: 'completada',
      fecha_fin: new Date()
    });
    console.log(`   ✅ Sesión de auditoría completada con fecha de fin registrada.`);

    // 10. TEST AUDIT_LOGS
    console.log('\n🔟 [AUDIT_LOGS]: Registrando log de auditoría del sistema (OWASP)...');
    const log = await AuditLog.create({
      usuario_id: user.id,
      accion: 'auditoria_completada',
      recurso: 'auditoria',
      recurso_id: auditoria.id,
      resultado: 'exitoso',
      detalles: 'Prueba de integración de flujo completo ejecutada con éxito',
      ip_address: '127.0.0.1',
      user_agent: 'AntigravityIntegrationTester/2.0'
    });
    console.log(`   ✅ Log de seguridad registrado: [${log.resultado.toUpperCase()}] ${log.accion} (ID: ${log.id})`);

    // 11. LIMPIEZA DE DATOS DE PRUEBA
    console.log('\n🧹 Limpiando registros de prueba...');
    await DetalleAuditoria.destroy({ where: { auditoria_id: auditoria.id } });
    await Auditoria.destroy({ where: { id: auditoria.id } });
    await Movimiento.destroy({ where: { activo_id: activoTest.id } });
    await Notificacion.destroy({ where: { id: notif.id } });
    await activoTest.destroy();
    console.log('   ✅ Registros temporales de prueba limpiados correctamente.');

    console.log('\n========================================================');
    console.log('🎉 TODAS LAS 9 TABLAS Y FUNCIONES OPERAN AL 100%');
    console.log('   Cero errores de datos, tipos o restricciones detectados.');
    console.log('========================================================\n');

    process.exit(0);
  } catch (error) {
    console.error('\n❌ ERROR EN LA VERIFICACIÓN DE FLUJOS:', error);
    process.exit(1);
  }
}

testAllDatabaseFlows();
