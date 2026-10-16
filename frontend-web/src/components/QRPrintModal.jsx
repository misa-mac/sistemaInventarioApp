import React from 'react';
import { X, Printer } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';

const QRPrintModal = ({ isOpen, onClose, assetsToPrint }) => {
  if (!isOpen) return null;

  const handlePrint = () => {
    const printContent = document.getElementById('print-section').innerHTML;
    const printWindow = window.open('', '', 'width=800,height=600');
    printWindow.document.write(`
      <html>
        <head>
          <title>Imprimir QRs - ITBM</title>
          <style>
            @page { margin: 1cm; }
            body { font-family: system-ui, -apple-system, sans-serif; text-align: center; }
            .grid { 
              display: grid;
              grid-template-columns: repeat(4, 1fr);
              gap: 20px;
              justify-items: center;
              margin: 0 auto;
            }
            .qr-container { 
              border: 1px solid black; 
              padding: 5px; 
              width: 4.5cm; 
              height: 4.5cm; 
              box-sizing: border-box; 
              display: flex; 
              flex-direction: column; 
              align-items: center; 
              justify-content: center; 
              page-break-inside: avoid;
              background: white;
            }
            .header-text { 
              font-size: 9px; 
              font-weight: bold; 
              text-transform: uppercase; 
              margin-bottom: 5px; 
              line-height: 1; 
            }
            .footer-text { 
              font-size: 10px; 
              font-family: monospace; 
              font-weight: bold; 
              letter-spacing: 1px; 
              margin-top: 5px; 
            }
            .svg-container { 
              width: 3cm; 
              height: 3cm; 
              display: flex; 
              align-items: center; 
              justify-content: center; 
            }
            svg { 
              width: 100% !important; 
              height: 100% !important; 
            }
            .doc-header { 
              text-align: center; 
              margin-bottom: 1cm; 
              border-bottom: 2px solid black; 
              padding-bottom: 1cm; 
            }
            .doc-header h1 { font-size: 20px; text-transform: uppercase; margin: 0; }
            .doc-header h2 { font-size: 16px; margin: 5px 0 0; font-weight: normal; }
            .doc-header p { font-size: 12px; margin: 10px 0 0; }
            @media print {
              .doc-header { display: block; }
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
    // Use a small timeout to ensure SVGs are rendered before calling print
    setTimeout(() => {
      printWindow.print();
      printWindow.close();
    }, 250);
  };

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4 animate-fade-in">
      
      {/* Modal Container */}
      <div className="bg-surface-container-lowest rounded-xl shadow-lg w-full max-w-4xl max-h-[90vh] flex flex-col">
        
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b border-surface-container-highest">
          <div>
            <h2 className="text-xl font-medium text-on-surface">Impresión de Códigos QR</h2>
            <p className="text-sm text-on-surface-variant mt-1">Seleccionados: {assetsToPrint.length} activo(s)</p>
          </div>
          <button 
            onClick={onClose}
            className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        {/* Preview Scrollable Area */}
        <div className="p-6 overflow-y-auto bg-surface-container border-b border-surface-container-highest flex-1">
          
          {/* We use standard CSS classes here that will be translated to our print style */}
          <div className="bg-white text-black p-8 rounded shadow-sm mx-auto max-w-3xl">
            <div id="print-section">
              <div className="doc-header hidden">
                <h1>Instituto Tecnológico "Bolivia Mar"</h1>
                <h2>Carrera de Sistemas Informáticos</h2>
                <p>Etiquetas de Control de Inventario</p>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-4 gap-6" style={{ display: 'grid' }}>
                {assetsToPrint.map((activo) => (
                  <div key={activo.id} className="qr-container border border-black flex flex-col items-center justify-center">
                    
                    <div className="header-text text-[9px] font-bold uppercase mb-1 leading-tight text-center">
                      ITBM - Inventario
                    </div>
                    
                    {/* El QR exacto de 3x3 cm */}
                    <div className="svg-container" style={{ width: '3cm', height: '3cm' }}>
                      <QRCodeSVG 
                        value={activo.codigo_activo} 
                        style={{ width: '100%', height: '100%' }}
                        level={"M"}
                        includeMargin={false}
                      />
                    </div>
                    
                    <div className="footer-text text-[10px] font-mono font-bold tracking-widest leading-none mt-1">
                      {activo.codigo_activo}
                    </div>
                    
                  </div>
                ))}
              </div>
            </div>
          </div>
          
        </div>

        {/* Footer */}
        <div className="p-6 flex justify-end gap-3 bg-surface-bright rounded-b-xl">
          <button 
            onClick={onClose}
            className="px-4 py-2 border border-outline rounded text-sm font-medium text-on-surface hover:bg-surface-container transition-colors"
          >
            Cerrar
          </button>
          <button 
            onClick={handlePrint}
            className="px-4 py-2 bg-primary text-on-primary rounded shadow-sm text-sm font-medium hover:bg-primary/90 transition-colors flex justify-center items-center gap-2"
          >
            <Printer size={18} />
            Imprimir Documento
          </button>
        </div>

      </div>
    </div>
  );
};

export default QRPrintModal;
