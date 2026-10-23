const { spawn } = require('child_process');
const path = require('path');

console.log('Iniciando Backend...');
const backend = spawn('cmd.exe', ['/c', 'npm run dev'], {
  cwd: path.join(__dirname, 'backend'),
  detached: true,
  stdio: 'ignore'
});
backend.unref();

console.log('Iniciando Frontend...');
const frontend = spawn('cmd.exe', ['/c', 'npm run dev'], {
  cwd: path.join(__dirname, 'frontend-web'),
  detached: true,
  stdio: 'ignore'
});
frontend.unref();

// Configurar puente ADB para dispositivo móvil por USB si existe
const fs = require('fs');
const adbPath = path.join(process.env.LOCALAPPDATA || '', 'Android', 'Sdk', 'platform-tools', 'adb.exe');
if (fs.existsSync(adbPath)) {
  try {
    const { execSync } = require('child_process');
    execSync(`"${adbPath}" reverse tcp:3000 tcp:3000`, { stdio: 'ignore' });
    console.log('✅ Puente ADB configurado (reverse tcp:3000 tcp:3000)');
  } catch (_) {}
}

console.log('Ambos servicios han sido desacoplados y levantados en segundo plano.');
