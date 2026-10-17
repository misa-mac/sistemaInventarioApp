const http = require('http');
const { fork } = require('child_process');
const path = require('path');

async function runRbacTests() {
  console.log('🛡️ =================================================================');
  console.log('🛡️ INICIANDO SUITE DE PRUEBAS DE SEGURIDAD Y PERMISOS RBAC POR ROL');
  console.log('🛡️ =================================================================\n');

  // Arrancar servidor Express en segundo plano
  const serverProcess = fork(path.join(__dirname, '../index.js'), { silent: true });
  let serverOutput = '';
  serverProcess.stdout.on('data', d => serverOutput += d);
  serverProcess.stderr.on('data', d => serverOutput += d);

  // Esperar a que el servidor esté listo
  await new Promise(r => setTimeout(r, 2500));

  const BASE_URL = 'http://localhost:3000/api';

  async function apiCall(method, endpoint, token, body = null) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const opts = { method, headers };
    if (body) opts.body = JSON.stringify(body);

    const res = await fetch(`${BASE_URL}${endpoint}`, opts);
    let data;
    try {
      data = await res.json();
    } catch (_) {
      data = null;
    }
    return { status: res.status, data };
  }

  try {
    // ---------------------------------------------------------------------
    // 1. INICIAR SESIÓN CON CADA ROL
    // ---------------------------------------------------------------------
    console.log('1️⃣ AUTENTICACIÓN DE CADA USUARIO:');
    
    const adminLogin = await apiCall('POST', '/auth/login', null, { email: 'misa@gmail.com', password: '123456789' });
    if (adminLogin.status !== 200 || !adminLogin.data.token) throw new Error('Error login admin: ' + JSON.stringify(adminLogin));
    const adminToken = adminLogin.data.token;
    console.log(`   ✅ Admin: ${adminLogin.data.user.email} -> Rol: '${adminLogin.data.user.rol}'`);

    const tecnicoLogin = await apiCall('POST', '/auth/login', null, { email: 'tecnico@itbm.edu.bo', password: '123456789' });
    if (tecnicoLogin.status !== 200 || !tecnicoLogin.data.token) throw new Error('Error login tecnico: ' + JSON.stringify(tecnicoLogin));
    const tecnicoToken = tecnicoLogin.data.token;
    console.log(`   ✅ Técnico: ${tecnicoLogin.data.user.email} -> Rol: '${tecnicoLogin.data.user.rol}'`);

    const auditorLogin = await apiCall('POST', '/auth/login', null, { email: 'auditor@itbm.edu.bo', password: '123456789' });
    if (auditorLogin.status !== 200 || !auditorLogin.data.token) throw new Error('Error login auditor: ' + JSON.stringify(auditorLogin));
    const auditorToken = auditorLogin.data.token;
    console.log(`   ✅ Auditor: ${auditorLogin.data.user.email} -> Rol: '${auditorLogin.data.user.rol}'`);

    let passedTests = 0;
    let totalTests = 0;

    function assertResponse(roleName, actionName, actualStatus, expectedStatus) {
      totalTests++;
      if (actualStatus === expectedStatus) {
        console.log(`   ✓ [${roleName}] ${actionName}: HTTP ${actualStatus} (OK)`);
        passedTests++;
      } else {
        console.error(`   ❌ [${roleName}] ${actionName}: Se esperaba HTTP ${expectedStatus} pero se obtuvo ${actualStatus}`);
      }
    }

    // ---------------------------------------------------------------------
    // 2. PRUEBAS DEL ADMINISTRADOR (ACCESO TOTAL A TODO)
    // ---------------------------------------------------------------------
    console.log('\n2️⃣ PRUEBAS DE ACCESO TOTAL DEL ROL ADMIN:');
    
    const adminEndpoints = [
      { m: 'GET', ep: '/activos', name: 'Listar Activos', exp: 200 },
      { m: 'GET', ep: '/ambientes', name: 'Listar Ambientes', exp: 200 },
      { m: 'GET', ep: '/tipos-activos', name: 'Listar Tipos Activos', exp: 200 },
      { m: 'GET', ep: '/movimientos', name: 'Listar Movimientos', exp: 200 },
      { m: 'GET', ep: '/reports/summary', name: 'Ver Reportes', exp: 200 },
      { m: 'GET', ep: '/usuarios', name: 'Gestionar Usuarios', exp: 200 },
      { m: 'GET', ep: '/auditorias', name: 'Listar Auditorías', exp: 200 },
      { m: 'GET', ep: '/notificaciones', name: 'Ver Notificaciones', exp: 200 },
      { m: 'GET', ep: '/audit-logs', name: 'Ver Audit Logs (OWASP)', exp: 200 },
    ];

    for (const test of adminEndpoints) {
      const res = await apiCall(test.m, test.ep, adminToken);
      assertResponse('ADMIN', test.name, res.status, test.exp);
    }

    // ---------------------------------------------------------------------
    // 3. PRUEBAS DEL TÉCNICO (PERMITIDOS Y DENEGADOS)
    // ---------------------------------------------------------------------
    console.log('\n3️⃣ PRUEBAS DEL ROL TÉCNICO:');
    
    // Permitidos:
    const tecPermitidos = [
      { m: 'GET', ep: '/activos', name: 'Ver Activos', exp: 200 },
      { m: 'GET', ep: '/ambientes', name: 'Ver Ambientes', exp: 200 },
      { m: 'GET', ep: '/movimientos', name: 'Ver Historial', exp: 200 },
      { m: 'GET', ep: '/notificaciones', name: 'Ver Notificaciones', exp: 200 }
    ];
    for (const test of tecPermitidos) {
      const res = await apiCall(test.m, test.ep, tecnicoToken);
      assertResponse('TÉCNICO', test.name, res.status, test.exp);
    }

    // Denegados (403):
    const tecDenegados = [
      { m: 'GET', ep: '/usuarios', name: 'Gestionar Usuarios (Prohibido)', exp: 403 },
      { m: 'GET', ep: '/reports/summary', name: 'Ver Reportes (Prohibido)', exp: 403 },
      { m: 'GET', ep: '/auditorias', name: 'Listar Auditorías (Prohibido)', exp: 403 },
      { m: 'POST', ep: '/auditorias', name: 'Iniciar Auditoría (Prohibido)', exp: 403 },
      { m: 'GET', ep: '/audit-logs', name: 'Listar Audit Logs (Prohibido)', exp: 403 }
    ];
    for (const test of tecDenegados) {
      const res = await apiCall(test.m, test.ep, tecnicoToken);
      assertResponse('TÉCNICO', test.name, res.status, test.exp);
    }

    // ---------------------------------------------------------------------
    // 4. PRUEBAS DEL AUDITOR (PERMITIDOS Y DENEGADOS)
    // ---------------------------------------------------------------------
    console.log('\n4️⃣ PRUEBAS DEL ROL AUDITOR:');
    
    // Permitidos:
    const audPermitidos = [
      { m: 'GET', ep: '/activos', name: 'Ver Activos', exp: 200 },
      { m: 'GET', ep: '/ambientes', name: 'Ver Ambientes', exp: 200 },
      { m: 'GET', ep: '/movimientos', name: 'Ver Historial', exp: 200 },
      { m: 'GET', ep: '/reports/summary', name: 'Ver Reportes', exp: 200 },
      { m: 'GET', ep: '/auditorias', name: 'Listar Auditorías', exp: 200 }
    ];
    for (const test of audPermitidos) {
      const res = await apiCall(test.m, test.ep, auditorToken);
      assertResponse('AUDITOR', test.name, res.status, test.exp);
    }

    // Denegados (403):
    const audDenegados = [
      { m: 'GET', ep: '/usuarios', name: 'Gestionar Usuarios (Prohibido)', exp: 403 },
      { m: 'POST', ep: '/activos', name: 'Crear Activo / Editar Inventario (Prohibido)', exp: 403 },
      { m: 'POST', ep: '/movimientos', name: 'Registrar Movimiento (Prohibido)', exp: 403 },
      { m: 'POST', ep: '/ambientes', name: 'Crear Ambientes (Prohibido)', exp: 403 },
      { m: 'GET', ep: '/audit-logs', name: 'Listar Audit Logs (Prohibido)', exp: 403 }
    ];
    for (const test of audDenegados) {
      const res = await apiCall(test.m, test.ep, auditorToken);
      assertResponse('AUDITOR', test.name, res.status, test.exp);
    }

    console.log('\n=================================================================');
    console.log(`🎉 RESULTADOS: ${passedTests} de ${totalTests} pruebas pasaron exitosamente.`);
    if (passedTests === totalTests) {
      console.log('✅ RBAC 100% OPERATIVO:');
      console.log('   - Admin tiene acceso completo e irrestricto.');
      console.log('   - Técnico y Auditor reciben 403 Forbidden estricto en rutas protegidas.');
    } else {
      console.error('⚠️ Algunas pruebas fallaron.');
    }
    console.log('=================================================================\n');

  } catch (err) {
    console.error('Error durante la ejecución del test:', err);
  } finally {
    try {
      if (serverProcess && serverProcess.pid) {
        const { execSync } = require('child_process');
        execSync(`taskkill /F /T /PID ${serverProcess.pid} >nul 2>&1`);
      }
    } catch (_) {}
    process.exit(0);
  }
}

runRbacTests();
