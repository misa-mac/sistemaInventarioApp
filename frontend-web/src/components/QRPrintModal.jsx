import React, { useState } from 'react';
import { X, Printer, LayoutGrid, Tag, Layers } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';

const QRPrintModal = ({ isOpen, onClose, assetsToPrint = [], stationToPrint = null, alertMessage = null }) => {
  const [printMode, setPrintMode] = useState(stationToPrint ? 'both' : 'individual');

  if (!isOpen) return null;

  // Si se pasa una estación, obtenemos sus componentes y la estación
  const station = stationToPrint;
  const stationComponents = station?.activos || station?.componentes || [];
  const assets = station ? stationComponents : (assetsToPrint || []);

  const handlePrint = () => {
    const printContent = document.getElementById('print-section').innerHTML;
    const printWindow = window.open('', '', 'width=900,height=700');
    printWindow.document.write(`
      <html>
        <head>
          <title>Imprimir Etiquetas QR - ITBM</title>
          <style>
            @page { margin: 1cm; size: auto; }
            body { font-family: system-ui, -apple-system, sans-serif; text-align: center; color: black; margin: 0; padding: 0; }
            .grid { 
              display: grid;
              grid-template-columns: repeat(4, 1fr);
              gap: 16px;
              justify-items: center;
              margin: 0 auto;
            }
            /* Etiqueta Individual (Pequeña para Componentes) */
            .qr-container { 
              border: 1.5px solid #1a1a1a; 
              border-radius: 4px;
              padding: 6px; 
              width: 4.6cm; 
              height: 4.8cm; 
              box-sizing: border-box; 
              display: flex; 
              flex-direction: column; 
              align-items: center; 
              justify-content: space-between; 
              page-break-inside: avoid;
              background: white;
            }
            /* Etiqueta General de Estación (Mesa de Trabajo - Grande) */
            .station-qr-card {
              border: 2.5px solid #000;
              border-radius: 8px;
              padding: 14px;
              width: 9.5cm;
              margin: 0 auto 20px auto;
              box-sizing: border-box;
              display: flex;
              flex-direction: column;
              align-items: center;
              page-break-inside: avoid;
              background: #fff;
            }
            .header-text { 
              font-size: 9px; 
              font-weight: 800; 
              text-transform: uppercase; 
              margin-bottom: 3px; 
              letter-spacing: 0.5px;
            }
            .footer-text { 
              font-size: 11px; 
              font-family: 'Courier New', monospace; 
              font-weight: bold; 
              letter-spacing: 1.5px; 
              margin-top: 4px; 
            }
            .meta-text {
              font-size: 8px;
              color: #444;
              text-transform: uppercase;
              white-space: nowrap;
              overflow: hidden;
              text-overflow: ellipsis;
              max-width: 4cm;
            }
            .station-title {
              font-size: 13px;
              font-weight: 900;
              letter-spacing: 1px;
              text-transform: uppercase;
              border-bottom: 2px solid #000;
              padding-bottom: 4px;
              width: 100%;
              margin-bottom: 8px;
            }
            .station-code {
              font-size: 18px;
              font-weight: 900;
              font-family: monospace;
              letter-spacing: 2px;
              margin: 6px 0;
            }
            .station-details {
              font-size: 9.5px;
              margin-top: 6px;
              width: 100%;
              text-align: left;
              border-top: 1px dashed #666;
              padding-top: 6px;
            }
            .station-details div {
              margin: 2px 0;
            }
            .doc-header { 
              text-align: center; 
              margin-bottom: 0.6cm; 
              border-bottom: 2px solid black; 
              padding-bottom: 0.4cm; 
            }
            .doc-header h1 { font-size: 18px; text-transform: uppercase; margin: 0; }
            .doc-header h2 { font-size: 13px; margin: 4px 0 0; font-weight: normal; }
            .doc-header p { font-size: 11px; margin: 4px 0 0; }
            .divider-section {
              margin: 20px 0;
              border-top: 2px dashed #999;
              padding-top: 15px;
              font-size: 11px;
              font-weight: bold;
              text-transform: uppercase;
            }
          </style>
        </head>
        <body>
          ${printContent}
        </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    setTimeout(() => {
      printWindow.print();
      printWindow.close();
    }, 250);
  };

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-[70] p-4 animate-fade-in">
      <div className="bg-surface-container-lowest rounded-xl shadow-2xl w-full max-w-4xl max-h-[92vh] flex flex-col">
        {/* Header */}
        <div className="flex justify-between items-center p-5 border-b border-surface-container-highest">
          <div>
            <h2 className="text-xl font-bold text-on-surface flex items-center gap-2">
              <Printer className="text-primary" size={22} />
              Impresión de Etiquetas QR
            </h2>
            <p className="text-xs text-on-surface-variant mt-1">
              Estándar ISO/IEC 18004 • Formato Híbrido ITBM
            </p>
          </div>
          <button 
            onClick={onClose}
            className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        {/* Alerta de reimpresión obligatoria por traslado / cambio */}
        {alertMessage && (
          <div className="mx-6 mt-4 p-3.5 rounded-lg bg-amber-50 border border-amber-300 text-amber-900 text-xs font-semibold flex items-center gap-2.5 shadow-sm animate-fade-in">
            <span className="text-lg leading-none">⚠️</span>
            <span>{alertMessage}</span>
          </div>
        )}

        {/* Mode Selector (si hay estación) */}
        {station && (
          <div className="px-6 py-3 bg-surface-container-low border-b border-surface-container-highest flex items-center gap-3">
            <span className="text-xs font-semibold text-on-surface-variant">Modo de Impresión:</span>
            <div className="inline-flex rounded-lg border border-outline-variant bg-surface-container p-1 gap-1">
              <button
                type="button"
                onClick={() => setPrintMode('general')}
                className={`px-3 py-1 text-xs font-medium rounded-md transition-all flex items-center gap-1.5 ${
                  printMode === 'general' ? 'bg-primary text-on-primary shadow-sm' : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <LayoutGrid size={14} />
                Solo QR General (Mesa)
              </button>
              <button
                type="button"
                onClick={() => setPrintMode('individual')}
                className={`px-3 py-1 text-xs font-medium rounded-md transition-all flex items-center gap-1.5 ${
                  printMode === 'individual' ? 'bg-primary text-on-primary shadow-sm' : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <Tag size={14} />
                Solo QR Componentes ({stationComponents.length})
              </button>
              <button
                type="button"
                onClick={() => setPrintMode('both')}
                className={`px-3 py-1 text-xs font-medium rounded-md transition-all flex items-center gap-1.5 ${
                  printMode === 'both' ? 'bg-primary text-on-primary shadow-sm' : 'text-on-surface-variant hover:text-on-surface'
                }`}
              >
                <Layers size={14} />
                Kit Completo (Mesa + 4 Componentes)
              </button>
            </div>
          </div>
        )}

        {/* Preview Scrollable Area */}
        <div className="p-6 overflow-y-auto bg-surface-container border-b border-surface-container-highest flex-1">
          <div className="bg-white text-black p-8 rounded shadow-sm mx-auto max-w-3xl">
            <div id="print-section">
              <div className="doc-header">
                <h1>Instituto Tecnológico "Bolivia Mar"</h1>
                <h2>Carrera de Sistemas Informáticos - Control de Inventario</h2>
                <p>
                  {station ? `Etiquetas para Estación de Trabajo [${station.codigo_estacion}]` : 'Etiquetas Individuales de Activos Fijos'}
                </p>
              </div>

              {/* QR General de la Estación (si aplica) */}
              {station && (printMode === 'general' || printMode === 'both') && (
                <div className="mb-6 flex justify-center">
                  <div className="station-qr-card border-2 border-black p-4 rounded-lg flex flex-col items-center max-w-sm w-full bg-white text-black">
                    <div className="station-title font-black text-xs uppercase tracking-wider text-center border-b-2 border-black w-full pb-1 mb-2">
                      ITBM • ESTACIÓN DE TRABAJO (MESA)
                    </div>
                    <div className="station-code text-xl font-mono font-black tracking-widest my-1">
                      {station.codigo_estacion}
                    </div>
                    <div className="p-2 border border-black rounded my-2 bg-white">
                      <QRCodeSVG 
                        value={station.codigo_estacion} 
                        size={150}
                        level="M"
                        includeMargin={false}
                      />
                    </div>
                    <div className="station-details text-[10px] w-full mt-2 pt-2 border-t border-dashed border-gray-400 text-left">
                      <div><strong>Ambiente:</strong> {station.ambiente?.nombre || 'General'}</div>
                      <div><strong>Descripción:</strong> {station.descripcion || 'Estación de laboratorio'}</div>
                      <div><strong>Componentes vinculados:</strong> {stationComponents.length} activos</div>
                    </div>
                  </div>
                </div>
              )}

              {/* Título de separación en modo kit */}
              {station && printMode === 'both' && stationComponents.length > 0 && (
                <div className="divider-section text-center my-6 py-2 border-t-2 border-dashed border-gray-400 font-bold text-xs">
                  COMPONENTES ASIGNADOS A LA ESTACIÓN ({station.codigo_estacion})
                </div>
              )}

              {/* QRs Individuales de los Componentes */}
              {(!station || printMode === 'individual' || printMode === 'both') && (
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-4" style={{ display: 'grid' }}>
                  {assets.map((activo) => (
                    <div key={activo.id} className="qr-container border border-black p-2 rounded flex flex-col items-center justify-between text-center bg-white text-black">
                      <div className="header-text text-[9px] font-bold uppercase tracking-wider leading-tight">
                        ITBM - Inventario
                      </div>
                      
                      <div className="meta-text text-[8px] text-gray-700 truncate w-full px-1">
                        {activo.nombre || 'Componente'}
                      </div>
                      
                      <div className="my-1 p-1 bg-white">
                        <QRCodeSVG 
                          value={activo.codigo_activo} 
                          size={95}
                          level="M"
                          includeMargin={false}
                        />
                      </div>
                      
                      <div className="footer-text text-[10px] font-mono font-bold tracking-wider leading-none mt-1">
                        {activo.codigo_activo}
                      </div>

                      <div className="meta-text text-[7px] text-gray-600 truncate w-full mt-0.5">
                        {activo.marca ? `${activo.marca} ${activo.modelo || ''}`.trim() : 'Hardware'}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 flex justify-between items-center bg-surface-bright rounded-b-xl border-t border-surface-container-highest">
          <div className="text-xs text-on-surface-variant">
            {station 
              ? (printMode === 'both' 
                  ? `Se imprimirá 1 QR General + ${stationComponents.length} QR(s) individuales`
                  : printMode === 'general' ? 'Se imprimirá 1 QR General de Mesa' : `Se imprimirán ${stationComponents.length} QR(s) individuales`)
              : `Total a imprimir: ${assets.length} etiqueta(s)`}
          </div>
          <div className="flex gap-3">
            <button 
              onClick={onClose}
              className="px-4 py-2 border border-outline rounded text-sm font-medium text-on-surface hover:bg-surface-container transition-colors"
            >
              Cerrar
            </button>
            <button 
              onClick={handlePrint}
              className="px-4 py-2 bg-primary text-on-primary rounded shadow-sm text-sm font-medium hover:bg-primary/90 transition-colors flex items-center gap-2"
            >
              <Printer size={16} />
              Imprimir Etiquetas
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default QRPrintModal;
