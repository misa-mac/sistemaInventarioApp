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

console.log('Ambos servicios han sido desacoplados y levantados en segundo plano.');
