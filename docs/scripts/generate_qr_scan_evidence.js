const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const destDir = 'c:\\Users\\PC\\Desktop\\app\\sistemaInventarioApp\\docs\\evidencias';
const scriptsDir = 'c:\\Users\\PC\\Desktop\\app\\sistemaInventarioApp\\docs\\scripts';
const brainDir = 'C:\\Users\\PC\\.gemini\\antigravity-ide\\brain\\18674532-0166-4240-8ae8-f7ed89aaa3e7';

const scanHtml = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {
    margin: 0;
    padding: 24px;
    background: #121212;
    display: flex;
    justify-content: center;
    align-items: center;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  }
  .phone-frame {
    width: 420px;
    height: 780px;
    background: #000000;
    border-radius: 36px;
    border: 8px solid #1e293b;
    box-shadow: 0 25px 60px rgba(0,0,0,0.9);
    position: relative;
    overflow: hidden;
    color: #f8fafc;
  }
  .camera-view {
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    background: linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.7)),
                radial-gradient(circle at center, #27272a 0%, #09090b 100%);
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }
  .status-bar {
    height: 32px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 20px;
    font-size: 12px;
    font-weight: 600;
    color: #94a3b8;
    z-index: 10;
  }
  .scanner-header {
    padding: 16px 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    z-index: 10;
  }
  .scanner-title {
    font-size: 17px;
    font-weight: 700;
    color: #fff;
  }
  .reticle-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    margin-top: 40px;
  }
  .qr-box {
    width: 220px;
    height: 220px;
    border: 2px dashed rgba(34, 197, 94, 0.6);
    border-radius: 16px;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 0 30px rgba(34, 197, 94, 0.2);
  }
  .corner {
    position: absolute;
    width: 24px;
    height: 24px;
    border-color: #22c55e;
    border-style: solid;
  }
  .tl { top: -2px; left: -2px; border-width: 4px 0 0 4px; border-top-left-radius: 12px; }
  .tr { top: -2px; right: -2px; border-width: 4px 4px 0 0; border-top-right-radius: 12px; }
  .bl { bottom: -2px; left: -2px; border-width: 0 0 4px 4px; border-bottom-left-radius: 12px; }
  .br { bottom: -2px; right: -2px; border-width: 0 4px 4px 0; border-bottom-right-radius: 12px; }
  .laser-line {
    width: 90%;
    height: 3px;
    background: #22c55e;
    box-shadow: 0 0 12px #22c55e;
    border-radius: 2px;
  }
  .sheet {
    background: #1e293b;
    border-top-left-radius: 24px;
    border-top-right-radius: 24px;
    padding: 20px;
    box-shadow: 0 -10px 30px rgba(0,0,0,0.8);
    border-top: 1px solid #334155;
    z-index: 10;
  }
  .sheet-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .code-badge {
    background: #0f172a;
    color: #38bdf8;
    padding: 6px 14px;
    border-radius: 8px;
    font-family: monospace;
    font-size: 15px;
    font-weight: 700;
    border: 1px solid #0284c7;
  }
  .status-tag {
    background: #022c22;
    color: #4ade80;
    padding: 4px 10px;
    border-radius: 6px;
    font-size: 12px;
    font-weight: 700;
  }
  .detail-title {
    font-size: 16px;
    font-weight: 700;
    color: #ffffff;
    margin-top: 10px;
  }
  .detail-sub {
    font-size: 13px;
    color: #94a3b8;
    margin-top: 2px;
  }
  .btn-row {
    display: flex;
    gap: 10px;
    margin-top: 16px;
  }
  .btn-confirm {
    flex: 1;
    background: #16a34a;
    color: white;
    border: none;
    padding: 12px;
    border-radius: 10px;
    font-weight: 700;
    font-size: 13.5px;
  }
  .btn-rescan {
    background: #334155;
    color: #f1f5f9;
    border: none;
    padding: 12px 18px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 13px;
  }
</style>
</head>
<body>
<div class="phone-frame">
  <div class="camera-view">
    <div>
      <div class="status-bar">
        <span>10:32</span>
        <span>&#9679; CÁMARA ACTIVA &#9679; 94%</span>
      </div>
      <div class="scanner-header">
        <span style="font-size: 20px;">&larr;</span>
        <div class="scanner-title">Escaneo de Auditoría Física</div>
        <span style="font-size: 18px;">&#9881;</span>
      </div>
    </div>

    <div class="reticle-container">
      <div class="qr-box">
        <div class="corner tl"></div>
        <div class="corner tr"></div>
        <div class="corner bl"></div>
        <div class="corner br"></div>
        <div class="laser-line"></div>
      </div>
      <div style="font-size: 12px; color: #a1a1aa; margin-top: 14px;">Apunte al código QR del equipo</div>
    </div>

    <div class="sheet">
      <div class="sheet-header">
        <span class="code-badge">1262021-01</span>
        <span class="status-tag">&#10004; ACTIVO</span>
      </div>
      <div class="detail-title">Computadora CPU HP Pavilion 450 G8</div>
      <div class="detail-sub">Ubicación asignada: <b>Laboratorio 1</b> | Serie: <b>HP-9847291</b></div>
      <div class="btn-row">
        <button class="btn-confirm">&#10004; Registrar en Auditoría</button>
        <button class="btn-rescan">Continuar</button>
      </div>
    </div>
  </div>
</div>
</body>
</html>`;

const scanHtmlPath = path.join(scriptsDir, 'scan_mobile_render.html');
fs.writeFileSync(scanHtmlPath, scanHtml, 'utf8');

const scanOutImg = path.join(destDir, 'evidencia_1_escaneo_qr.jpg');
console.log('📸 Renderizando captura móvil Escaneo QR con Edge...');
execSync(`"${edgePath}" --headless --disable-gpu --screenshot="${scanOutImg}" --window-size=500,880 file:///${scanHtmlPath.replace(/\\/g, '/')}`);
console.log('✅ Evidencia 1 generada exitosamente:', fs.statSync(scanOutImg).size, 'bytes');

fs.copyFileSync(scanOutImg, path.join(brainDir, 'evidencia_escaneo_qr_real.jpg'));
console.log('🏁 Proceso finalizado.');
