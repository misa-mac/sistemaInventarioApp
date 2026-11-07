const { sequelize } = require('../database');
const Activo = require('../src/models/Activo');
const Ambiente = require('../src/models/Ambiente');
const TipoActivo = require('../src/models/TipoActivo');

async function runTests() {
  console.log('🧪 Iniciando batería de pruebas de parámetros reales y ciclo de vida de correlativos...\n');

  try {
    // 0. Preparar ambientes y tipo de prueba limpios
    let tipoTest = await TipoActivo.findOne({ where: { codigo: 10 } }); // 10 CPU
    if (!tipoTest) {
      throw new Error('Tipo CPU (codigo 10) no encontrado en base de datos');
    }

    let amb1 = await Ambiente.findOne({ where: { codigo: 20 } }); // Lab 1
    let amb2 = await Ambiente.findOne({ where: { codigo: 21 } }); // Lab 2
    let amb3 = await Ambiente.findOne({ where: { codigo: 22 } }); // Lab 3

    if (!amb1 || !amb2 || !amb3) {
      throw new Error('Ambientes 20, 21 o 22 no encontrados en base de datos');
    }

    // Usaremos un tipo de activo exclusivo temporal para pruebas aisladas de ciclo de vida
    const tipoPruebaCodigo = 99; // 99 Tipo Prueba
    let tipoPrueba = await TipoActivo.findOne({ where: { codigo: tipoPruebaCodigo } });
    if (!tipoPrueba) {
      tipoPrueba = await TipoActivo.create({
        nombre: 'Tipo Prueba Ciclo Vida',
        codigo: tipoPruebaCodigo,
        activo: true
      });
    }

    // Limpiar activos de pruebas anteriores con este tipo
    await Activo.destroy({ where: { tipo_activo_id: tipoPrueba.id } });

    console.log('--- TEST 1: REGISTRO (INSERT) ---');
    // Registrar activo 1 en amb1
    const activo1 = await Activo.create({
      tipo_activo_id: tipoPrueba.id,
      ambiente_id: amb1.id,
      nombre: 'Prueba 1',
      marca: 'TestBrand',
      fecha_ingreso: '2026-05-10',
      estado: 'Activo'
    });
    await activo1.reload();

    console.log(`Activo 1 Creado: Codigo = ${activo1.codigo_activo}, Correlativo = ${activo1.numero_correlativo}`);
    
    // Validar regex exacto: ^1[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{1,4}-[0-9]{2}$
    const regexValidador = /^1[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{1,4}-[0-9]{2}$/;
    if (!regexValidador.test(activo1.codigo_activo)) {
      throw new Error(`TEST 1 FALLÓ: El código ${activo1.codigo_activo} no cumple el regex oficial.`);
    }

    // Validar estructura X=1, CC=50, TT=99, AA=20, NNNN=1, YY=26 -> 15099201-26
    const expectedCod1 = '15099201-26';
    if (activo1.codigo_activo !== expectedCod1) {
      throw new Error(`TEST 1 FALLÓ: Se esperaba '${expectedCod1}', pero se obtuvo '${activo1.codigo_activo}'`);
    }
    if (activo1.numero_correlativo !== 1) {
      throw new Error(`TEST 1 FALLÓ: El correlativo inicial debe ser 1, obtenido: ${activo1.numero_correlativo}`);
    }
    console.log('✅ TEST 1 PASÓ: Registro genera formato 150·TT·AA·NNNN-YY sin ceros a la izquierda en el correlativo.\n');


    console.log('--- TEST 2: TRASLADO SIN COLISIÓN ---');
    // Trasladar activo1 de amb1 (codigo 20) a amb2 (codigo 21).
    // En amb2 no hay ningún activo de este tipo, por lo que correlativo 1 está libre.
    // Regla: Si el correlativo actual no existe en el destino, DEBE CONSERVARLO.
    await activo1.update({ ambiente_id: amb2.id });
    await activo1.reload();

    console.log(`Activo 1 Trasladado a Amb2: Codigo = ${activo1.codigo_activo}, Correlativo = ${activo1.numero_correlativo}`);
    const expectedCod1Trasladado = '15099211-26'; // AA cambia a 21, correlativo sigue siendo 1
    if (activo1.codigo_activo !== expectedCod1Trasladado) {
      throw new Error(`TEST 2 FALLÓ: Se esperaba '${expectedCod1Trasladado}', pero se obtuvo '${activo1.codigo_activo}'`);
    }
    if (activo1.numero_correlativo !== 1) {
      throw new Error(`TEST 2 FALLÓ: En traslado sin colisión se debe conservar el correlativo 1, pero se obtuvo: ${activo1.numero_correlativo}`);
    }
    console.log('✅ TEST 2 PASÓ: Traslado sin colisión conserva correlativo y actualiza AA en código activo.\n');


    console.log('--- TEST 3: TRASLADO CON COLISIÓN DE CORRELATIVO ---');
    // Creamos activo2 directamente en amb3 -> obtendrá correlativo 1 en amb3 (15099221-26)
    const activo2 = await Activo.create({
      tipo_activo_id: tipoPrueba.id,
      ambiente_id: amb3.id,
      nombre: 'Prueba 2 en Amb3',
      fecha_ingreso: '2026-06-15',
      estado: 'Activo'
    });
    await activo2.reload();
    console.log(`Activo 2 Creado en Amb3: Codigo = ${activo2.codigo_activo}, Correlativo = ${activo2.numero_correlativo}`);
    if (activo2.numero_correlativo !== 1) {
      throw new Error(`TEST 3 FALLÓ: Activo 2 debía nacer con correlativo 1 en amb3.`);
    }

    // Ahora trasladamos activo1 (que tiene correlativo 1) hacia amb3 (donde activo2 ya tiene correlativo 1)
    // Regla: Como correlativo 1 YA EXISTE en amb3 (colisión), debe tomar el siguiente al máximo del destino (1 + 1 = 2).
    await activo1.update({ ambiente_id: amb3.id });
    await activo1.reload();

    console.log(`Activo 1 Trasladado a Amb3 (con colisión): Codigo = ${activo1.codigo_activo}, Correlativo = ${activo1.numero_correlativo}`);
    const expectedCod1ConColision = '15099222-26'; // AA=22, NNNN=2
    if (activo1.codigo_activo !== expectedCod1ConColision) {
      throw new Error(`TEST 3 FALLÓ: Se esperaba '${expectedCod1ConColision}', pero se obtuvo '${activo1.codigo_activo}'`);
    }
    if (activo1.numero_correlativo !== 2) {
      throw new Error(`TEST 3 FALLÓ: En traslado con colisión debía asignarse 2 (MAX+1), obtenido: ${activo1.numero_correlativo}`);
    }
    console.log('✅ TEST 3 PASÓ: Traslado con colisión detecta conflicto y asigna MAX(destino) + 1.\n');


    console.log('--- TEST 4: BAJA LÓGICA ---');
    // Damos de baja activo2 en amb3 (que tenía correlativo 1)
    await activo2.update({ estado: 'Inactivo' });
    await activo2.reload();

    console.log(`Activo 2 dado de baja: Estado = ${activo2.estado}, Codigo = ${activo2.codigo_activo}, Correlativo = ${activo2.numero_correlativo}`);
    if (activo2.estado !== 'Inactivo') {
      throw new Error(`TEST 4 FALLÓ: El estado debía ser Inactivo.`);
    }
    console.log('✅ TEST 4 PASÓ: Baja lógica completada, fila preservada y correlativo marcado disponible.\n');


    console.log('--- TEST 5: REUTILIZACIÓN DEL CORRELATIVO LIBERADO TRAS BAJA ---');
    // En amb1 (Lab 1), creamos un activo A3 -> correlativo 1
    const activo3 = await Activo.create({
      tipo_activo_id: tipoPrueba.id,
      ambiente_id: amb1.id,
      nombre: 'Prueba 3 en Amb1',
      fecha_ingreso: '2026-07-20',
      estado: 'Activo'
    });
    await activo3.reload();
    console.log(`Activo 3 creado en Amb1: Codigo = ${activo3.codigo_activo}, Correlativo = ${activo3.numero_correlativo}`);
    if (activo3.numero_correlativo !== 1) {
      throw new Error(`TEST 5 FALLÓ: Activo 3 debía tener correlativo 1 en amb1.`);
    }

    // Le damos baja al activo 3
    await activo3.update({ estado: 'Inactivo' });
    console.log(`Activo 3 en Amb1 dado de baja (libera correlativo 1).`);

    // Insertamos nuevo activo 4 en amb1 para el mismo tipo:
    // Debe reutilizar el correlativo 1 liberado por activo 3
    const activo4 = await Activo.create({
      tipo_activo_id: tipoPrueba.id,
      ambiente_id: amb1.id,
      nombre: 'Prueba 4 en Amb1 (Reutilizador)',
      fecha_ingreso: '2026-07-20',
      estado: 'Activo'
    });
    await activo4.reload();

    console.log(`Activo 4 Creado en Amb1: Codigo = ${activo4.codigo_activo}, Correlativo = ${activo4.numero_correlativo}`);
    if (activo4.numero_correlativo !== 1) {
      throw new Error(`TEST 5 FALLÓ: Se esperaba reutilizar correlativo 1, pero se obtuvo: ${activo4.numero_correlativo}`);
    }
    const expectedCod4 = '15099201-26';
    if (activo4.codigo_activo !== expectedCod4) {
      throw new Error(`TEST 5 FALLÓ: Se esperaba '${expectedCod4}', pero se obtuvo '${activo4.codigo_activo}'`);
    }
    console.log('✅ TEST 5 PASÓ: El correlativo liberado por la baja se reutiliza exitosamente por un nuevo activo.\n');


    console.log('--- TEST 6: BLOQUEO DE INMUTABILIDAD DESDE EL CLIENTE ---');
    let mutacionFallida = false;
    try {
      // Intentar cambiar manualmente codigo_activo sin traslado
      await sequelize.query(`
        UPDATE activos 
        SET codigo_activo = '15099209-26' 
        WHERE id = '${activo4.id}'
      `);
    } catch (e) {
      mutacionFallida = true;
      console.log(`Intento de mutación de código bloqueado con error: ${e.message}`);
    }
    if (!mutacionFallida) {
      throw new Error('TEST 6 FALLÓ: La base de datos debía bloquear la alteración manual del código.');
    }
    console.log('✅ TEST 6 PASÓ: El trigger protege la inmutabilidad física impidiendo manipulaciones del cliente.\n');

    // Limpieza final
    await Activo.destroy({ where: { tipo_activo_id: tipoPrueba.id } });
    await TipoActivo.destroy({ where: { id: tipoPrueba.id } });

    console.log('🏆 ¡TODAS LAS 6 PRUEBAS DE CICLO DE VIDA PASARON SATISFACTORIAMENTE!');
    process.exit(0);
  } catch (err) {
    console.error('❌ ERROR DURANTE LAS PRUEBAS:', err);
    process.exit(1);
  }
}

runTests();

