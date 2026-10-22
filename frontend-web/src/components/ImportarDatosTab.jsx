import { useState, useEffect, useRef } from 'react';
import * as XLSX from 'xlsx';
import api from '../services/api';
import { 
  FileSpreadsheet, UploadCloud, Download, CheckCircle2, 
  AlertCircle, RefreshCw, FileCheck, HelpCircle, ArrowRight,
  Database, Building, Layers, Trash2, Check, X
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const ImportarDatosTab = () => {
  const navigate = useNavigate();
  const fileInputRef = useRef(null);

  const [ambientes, setAmbientes] = useState([]);
  const [tipos, setTipos] = useState([]);
  const [loadingCatalogs, setLoadingCatalogs] = useState(true);

  const [selectedFile, setSelectedFile] = useState(null);
  const [parsedRows, setParsedRows] = useState([]);
  const [validationSummary, setValidationSummary] = useState({ total: 0, valid: 0, invalid: 0 });
  const [filterMode, setFilterMode] = useState('all'); // 'all', 'valid', 'invalid'
  
  const [isImporting, setIsImporting] = useState(false);
  const [importResult, setImportResult] = useState(null);
  const [isDragOver, setIsDragOver] = useState(false);

  // Cargar catálogos actuales para validación client-side y plantilla
  useEffect(() => {
    fetchCatalogs();
  }, []);

  const fetchCatalogs = async () => {
    setLoadingCatalogs(true);
    try {
      const [resAmbientes, resTipos] = await Promise.all([
        api.get('/ambientes'),
        api.get('/tipos-activos')
      ]);
      setAmbientes(resAmbientes.data || []);
      setTipos(resTipos.data || []);
    } catch (err) {
      console.error('Error al cargar catálogos:', err);
    } finally {
      setLoadingCatalogs(false);
    }
  };

  // 1. Descargar Plantilla Excel Oficial
  const handleDownloadTemplate = () => {
    const wb = XLSX.utils.book_new();

    // Hoja 1: Plantilla con datos de ejemplo
    const headers = [
      'Nombre del Activo',
      'Categoría o Código AA',
      'Ambiente o Código CC',
      'Marca',
      'Modelo',
      'Número de Serie',
      'Estado',
      'Origen',
      'Valor (Bs)',
      'Fecha de Ingreso',
      'Descripción / Observaciones'
    ];

    const sampleRows = [
      [
        'Computadora de Escritorio Core i7',
        'CPU/Computadora',
        'Laboratorio 1',
        'Dell',
        'OptiPlex 7050',
        'DELL-SN-784920',
        'Activo',
        'Compra institucional',
        4500,
        '2026-01-15',
        'Equipo en puesto docente'
      ],
      [
        'Monitor LED 24 Pulgadas',
        'Pantalla/Monitor',
        'Laboratorio 1',
        'Samsung',
        'F24T350',
        'SAM-MN-449102',
        'Activo',
        'Compra institucional',
        980,
        '2026-01-15',
        'Monitor HDMI para laboratorio'
      ],
      [
        'Switch Administrable 24 Puertos Gigabit',
        'Switch',
        'Taller 1',
        'Cisco',
        'Catalyst 2960',
        'CSCO-SW-90211',
        'Activo',
        'Transferencia de otra sede',
        2800,
        '2026-02-01',
        'Instalado en rack de comunicaciones'
      ],
      [
        'Teclado USB Multimedia',
        'Teclado',
        'Laboratorio 2',
        'Logitech',
        'K120',
        'LOGI-KB-11029',
        'Activo',
        'Donación de estudiantes',
        75,
        '2026-02-10',
        'Periférico para mesa 3'
      ]
    ];

    const wsData = [headers, ...sampleRows];
    const wsPlantilla = XLSX.utils.aoa_to_sheet(wsData);

    // Configurar ancho de columnas
    wsPlantilla['!cols'] = [
      { wch: 35 }, // Nombre
      { wch: 22 }, // Categoría
      { wch: 22 }, // Ambiente
      { wch: 15 }, // Marca
      { wch: 18 }, // Modelo
      { wch: 20 }, // Serie
      { wch: 12 }, // Estado
      { wch: 25 }, // Origen
      { wch: 14 }, // Valor
      { wch: 16 }, // Fecha
      { wch: 35 }  // Descripción
    ];

    XLSX.utils.book_append_sheet(wb, wsPlantilla, 'Plantilla Activos');

    // Hoja 2: Catálogo de Ambientes (Referencia)
    const ambientesData = [
      ['Código (CC)', 'Nombre del Ambiente', 'Área / Bloque Físico'],
      ...ambientes.map(a => [a.codigo, a.nombre, a.ubicacion || '-'])
    ];
    const wsAmbientes = XLSX.utils.aoa_to_sheet(ambientesData);
    wsAmbientes['!cols'] = [{ wch: 14 }, { wch: 28 }, { wch: 30 }];
    XLSX.utils.book_append_sheet(wb, wsAmbientes, 'Ambientes Disponibles');

    // Hoja 3: Catálogo de Categorías (Referencia)
    const tiposData = [
      ['Código (AA)', 'Nombre de Categoría', 'Descripción'],
      ...tipos.map(t => [t.codigo, t.nombre, t.descripcion || '-'])
    ];
    const wsTipos = XLSX.utils.aoa_to_sheet(tiposData);
    wsTipos['!cols'] = [{ wch: 14 }, { wch: 28 }, { wch: 35 }];
    XLSX.utils.book_append_sheet(wb, wsTipos, 'Categorias Disponibles');

    // Descargar archivo
    XLSX.writeFile(wb, 'Plantilla_Importacion_Inventario_ITBM.xlsx');
  };

  // 2. Procesar Archivo Excel Subido
  const handleFileUpload = (file) => {
    if (!file) return;
    setSelectedFile(file);
    setImportResult(null);

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target.result);
        const workbook = XLSX.read(data, { type: 'array' });
        const firstSheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[firstSheetName];
        
        // Convertir a matriz o json
        const rawJson = XLSX.utils.sheet_to_json(worksheet, { defval: '' });
        validateAndParseRows(rawJson);
      } catch (err) {
        alert('Error al leer el archivo Excel: ' + err.message);
      }
    };
    reader.readAsArrayBuffer(file);
  };

  // Mapear y validar cada fila
  const validateAndParseRows = (rows) => {
    let validCount = 0;
    let invalidCount = 0;

    const parsed = rows.map((row, index) => {
      // Normalizar claves del objeto a minúsculas sin acentos
      const normalizedRow = {};
      Object.keys(row).forEach(key => {
        const cleanKey = key.toLowerCase()
          .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
          .trim();
        normalizedRow[cleanKey] = row[key];
      });

      // Extracción inteligente de campos según posibles encabezados
      const nombre = normalizedRow['nombre del activo'] || normalizedRow['nombre'] || normalizedRow['activo'] || '';
      
      const tipoRaw = normalizedRow['categoria o codigo aa'] || normalizedRow['categoria'] || normalizedRow['tipo'] || normalizedRow['codigo aa'] || '';
      const ambienteRaw = normalizedRow['ambiente o codigo cc'] || normalizedRow['ambiente'] || normalizedRow['laboratorio'] || normalizedRow['codigo cc'] || '';
      
      const marca = normalizedRow['marca'] || '';
      const modelo = normalizedRow['modelo'] || '';
      const serie = normalizedRow['numero de serie'] || normalizedRow['serie'] || normalizedRow['serial'] || normalizedRow['nro serie'] || '';
      
      const estadoRaw = normalizedRow['estado'] || normalizedRow['estado fisico'] || 'Activo';
      const origen = normalizedRow['origen'] || normalizedRow['procedencia'] || 'Compra institucional';
      const valor = normalizedRow['valor (bs)'] || normalizedRow['valor bs'] || normalizedRow['valor'] || normalizedRow['precio'] || '';
      const fecha = normalizedRow['fecha de ingreso'] || normalizedRow['fecha ingreso'] || normalizedRow['fecha'] || '';
      const descripcion = normalizedRow['descripcion / observaciones'] || normalizedRow['descripcion'] || normalizedRow['observaciones'] || '';

      const errors = [];

      // Validar Nombre
      if (!nombre || nombre.toString().trim() === '') {
        errors.push('El nombre del activo es obligatorio.');
      }

      // Validar Categoría / Tipo
      let matchedTipo = null;
      if (tipoRaw !== '') {
        const asNum = parseInt(tipoRaw, 10);
        if (!isNaN(asNum)) {
          matchedTipo = tipos.find(t => t.codigo === asNum);
        }
        if (!matchedTipo) {
          const tClean = tipoRaw.toString().toLowerCase().trim();
          matchedTipo = tipos.find(t => t.nombre.toLowerCase().trim() === tClean || t.nombre.toLowerCase().includes(tClean));
        }
      }
      if (!matchedTipo && tipos.length > 0) {
        matchedTipo = tipos[0]; // Fallback por defecto o advertencia
      }

      // Validar Ambiente
      let matchedAmbiente = null;
      if (ambienteRaw !== '') {
        const asNum = parseInt(ambienteRaw, 10);
        if (!isNaN(asNum)) {
          matchedAmbiente = ambientes.find(a => a.codigo === asNum);
        }
        if (!matchedAmbiente) {
          const aClean = ambienteRaw.toString().toLowerCase().trim();
          matchedAmbiente = ambientes.find(a => a.nombre.toLowerCase().trim() === aClean || a.nombre.toLowerCase().includes(aClean));
        }
      }

      if (!matchedAmbiente) {
        errors.push(`Ambiente '${ambienteRaw}' no reconocido en el sistema.`);
      }

      const isValid = errors.length === 0;
      if (isValid) validCount++;
      else invalidCount++;

      return {
        rowNumber: index + 2, // Fila en Excel (contando cabecera)
        nombre: nombre.toString().trim(),
        tipoRaw,
        matchedTipo,
        ambienteRaw,
        matchedAmbiente,
        marca: marca.toString().trim(),
        modelo: modelo.toString().trim(),
        numero_serie: serie.toString().trim(),
        estado: estadoRaw.toString().trim() || 'Activo',
        origen: origen.toString().trim() || 'Compra institucional',
        valor: valor !== '' ? parseFloat(valor) : null,
        fecha_ingreso: fecha ? fecha.toString().trim() : null,
        descripcion: descripcion.toString().trim(),
        isValid,
        errors
      };
    });

    setParsedRows(parsed);
    setValidationSummary({
      total: parsed.length,
      valid: validCount,
      invalid: invalidCount
    });
  };

  // 3. Ejecutar Importación Masiva en el Backend
  const handleExecuteImport = async () => {
    const validItems = parsedRows.filter(r => r.isValid);
    if (validItems.length === 0) {
      alert('No hay filas válidas para importar. Por favor corrija los errores en su archivo Excel.');
      return;
    }

    setIsImporting(true);
    setImportResult(null);

    try {
      const payload = {
        items: validItems.map(item => ({
          nombre: item.nombre,
          tipo_activo_id: item.matchedTipo?.id,
          ambiente_id: item.matchedAmbiente?.id,
          marca: item.marca || null,
          modelo: item.modelo || null,
          numero_serie: item.numero_serie || null,
          estado: item.estado,
          origen: item.origen,
          valor: item.valor,
          fecha_ingreso: item.fecha_ingreso,
          descripcion: item.descripcion || null
        }))
      };

      const res = await api.post('/inventory/bulk-import', payload);
      setImportResult({
        success: true,
        count: res.data.count,
        message: res.data.message || `Se importaron ${res.data.count} activos correctamente.`
      });
      // Limpiar archivo seleccionado para evitar duplicados accidentales
      setParsedRows([]);
      setSelectedFile(null);
    } catch (err) {
      setImportResult({
        success: false,
        message: err.response?.data?.message || 'Error durante la importación masiva: ' + err.message
      });
    } finally {
      setIsImporting(false);
    }
  };

  const handleClear = () => {
    setSelectedFile(null);
    setParsedRows([]);
    setValidationSummary({ total: 0, valid: 0, invalid: 0 });
    setImportResult(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const filteredRows = parsedRows.filter(r => {
    if (filterMode === 'valid') return r.isValid;
    if (filterMode === 'invalid') return !r.isValid;
    return true;
  });

  return (
    <div className="p-6 space-y-6 animate-fade-in">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 pb-4 border-b border-surface-container-highest">
        <div>
          <h3 className="text-xl font-bold text-on-surface flex items-center gap-2">
            <FileSpreadsheet className="text-primary" size={24} />
            Importación Masiva de Activos (Excel)
          </h3>
          <p className="text-sm text-on-surface-variant mt-0.5">
            Cargue múltiples equipos y activos en un solo paso mediante una hoja de cálculo formateada.
          </p>
        </div>
        
        <button
          onClick={handleDownloadTemplate}
          className="flex items-center gap-2 px-4 py-2.5 bg-primary text-on-primary rounded-xl font-medium text-sm hover:bg-primary/90 transition-all shadow-sm"
        >
          <Download size={16} />
          Descargar Plantilla Oficial (.xlsx)
        </button>
      </div>

      {/* Result Alert */}
      {importResult && (
        <div className={`p-4 rounded-xl border flex items-start gap-3 animate-fade-in ${importResult.success ? 'bg-[#22c55e]/10 border-[#22c55e]/30 text-[#15803d]' : 'bg-error-container border-error/30 text-on-error-container'}`}>
          {importResult.success ? <CheckCircle2 size={22} className="shrink-0 mt-0.5" /> : <AlertCircle size={22} className="shrink-0 mt-0.5" />}
          <div className="flex-1">
            <h4 className="font-bold text-sm">{importResult.success ? '¡Importación Completada con Éxito!' : 'Error en la Importación'}</h4>
            <p className="text-xs mt-0.5">{importResult.message}</p>
            {importResult.success && (
              <div className="mt-3 flex gap-2">
                <button
                  onClick={() => navigate('/inventario')}
                  className="px-3.5 py-1.5 bg-[#16a34a] text-white rounded-lg text-xs font-semibold hover:bg-[#15803d] transition-colors flex items-center gap-1.5 shadow-sm"
                >
                  Ver Activos en Inventario <ArrowRight size={14} />
                </button>
                <button
                  onClick={handleClear}
                  className="px-3.5 py-1.5 bg-white border border-outline-variant text-on-surface rounded-lg text-xs font-medium hover:bg-surface-container transition-colors"
                >
                  Cargar otro archivo
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Guía de Estructura de Columnas */}
      <div className="bg-surface-container-low rounded-2xl p-5 border border-surface-container-highest space-y-4">
        <div className="flex items-center justify-between">
          <h4 className="text-sm font-bold text-on-surface flex items-center gap-2">
            <HelpCircle size={18} className="text-primary" />
            Estructura y Orden Obligatorio de las Columnas en el Excel
          </h4>
          <span className="text-xs bg-surface-container px-2.5 py-0.5 rounded-full font-medium text-on-surface-variant">
            11 Columnas Estándar
          </span>
        </div>

        <p className="text-xs text-on-surface-variant leading-relaxed">
          Su archivo de Excel debe contener los siguientes encabezados en la primera fila. Puede usar los nombres exactos o códigos numéricos identificadores:
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 text-xs">
          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>1. Nombre del Activo</span>
              <span className="text-primary font-semibold text-[10px] bg-primary/10 px-1.5 py-0.5 rounded">Obligatorio</span>
            </div>
            <p className="text-on-surface-variant mt-1">Nombre o descripción del activo. Ej: <em>Computadora Core i7</em></p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>2. Categoría o Código AA</span>
              <span className="text-primary font-semibold text-[10px] bg-primary/10 px-1.5 py-0.5 rounded">Obligatorio</span>
            </div>
            <p className="text-on-surface-variant mt-1">Nombre o código (10: CPU, 80: Monitor, 50: Teclado, etc.).</p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>3. Ambiente o Código CC</span>
              <span className="text-primary font-semibold text-[10px] bg-primary/10 px-1.5 py-0.5 rounded">Obligatorio</span>
            </div>
            <p className="text-on-surface-variant mt-1">Nombre o código (20: Lab 1, 21: Lab 2, 23: Taller 1, etc.).</p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>4. Marca</span>
              <span className="text-outline font-medium text-[10px]">Opcional</span>
            </div>
            <p className="text-on-surface-variant mt-1">Fabricante del equipo. Ej: <em>Dell, HP, Cisco, Lenovo</em></p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>5. Modelo</span>
              <span className="text-outline font-medium text-[10px]">Opcional</span>
            </div>
            <p className="text-on-surface-variant mt-1">Modelo específico del equipo. Ej: <em>OptiPlex 7050</em></p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>6. Número de Serie</span>
              <span className="text-outline font-medium text-[10px]">Opcional</span>
            </div>
            <p className="text-on-surface-variant mt-1">Número de serie o serial institucional único.</p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>7. Estado Físico</span>
              <span className="text-primary font-semibold text-[10px] bg-primary/10 px-1.5 py-0.5 rounded">Obligatorio</span>
            </div>
            <p className="text-on-surface-variant mt-1">Valores válidos: <strong>Activo</strong>, <strong>Regular</strong>, <strong>Inactivo</strong> o <strong>Dañado</strong>.</p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>8. Origen</span>
              <span className="text-outline font-medium text-[10px]">Opcional</span>
            </div>
            <p className="text-on-surface-variant mt-1">Compra institucional, Donación estudiantes, Donación docentes, etc.</p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>9. Valor (Bs)</span>
              <span className="text-outline font-medium text-[10px]">Opcional</span>
            </div>
            <p className="text-on-surface-variant mt-1">Valor monetario numérico en Bolivianos. Ej: <em>3500.00</em></p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>10. Fecha de Ingreso</span>
              <span className="text-outline font-medium text-[10px]">Opcional</span>
            </div>
            <p className="text-on-surface-variant mt-1">Formato fecha: <strong>YYYY-MM-DD</strong>. Ej: <em>2026-02-15</em></p>
          </div>

          <div className="p-3 bg-surface rounded-xl border border-outline-variant/60 md:col-span-2">
            <div className="font-bold text-on-surface flex items-center justify-between">
              <span>11. Descripción / Observaciones</span>
              <span className="text-outline font-medium text-[10px]">Opcional</span>
            </div>
            <p className="text-on-surface-variant mt-1">Detalles de uso, ubicación específica dentro del aula o especificaciones técnicas.</p>
          </div>
        </div>
      </div>

      {/* Zona de Carga de Archivo */}
      {!selectedFile ? (
        <div 
          onDragOver={(e) => { e.preventDefault(); setIsDragOver(true); }}
          onDragLeave={() => setIsDragOver(false)}
          onDrop={(e) => {
            e.preventDefault();
            setIsDragOver(false);
            if (e.dataTransfer.files && e.dataTransfer.files[0]) {
              handleFileUpload(e.dataTransfer.files[0]);
            }
          }}
          onClick={() => fileInputRef.current?.click()}
          className={`border-2 border-dashed rounded-2xl p-10 text-center cursor-pointer transition-all flex flex-col items-center justify-center gap-3 ${
            isDragOver 
              ? 'border-primary bg-primary/5 scale-[1.01]' 
              : 'border-outline-variant hover:border-primary hover:bg-surface-container-low'
          }`}
        >
          <input 
            type="file" 
            ref={fileInputRef}
            onChange={(e) => {
              if (e.target.files && e.target.files[0]) {
                handleFileUpload(e.target.files[0]);
              }
            }}
            accept=".xlsx, .xls, .csv" 
            className="hidden" 
          />
          <div className="w-16 h-16 rounded-2xl bg-primary/10 text-primary flex items-center justify-center">
            <UploadCloud size={32} />
          </div>
          <div>
            <h4 className="font-bold text-on-surface text-base">Haga clic o arrastre su archivo Excel aquí</h4>
            <p className="text-xs text-on-surface-variant mt-1">Formatos compatibles: .xlsx, .xls o .csv (Hoja de cálculo)</p>
          </div>
          <span className="mt-2 text-xs font-semibold px-4 py-2 bg-surface border border-outline-variant rounded-xl shadow-sm hover:bg-surface-container transition-colors">
            Seleccionar archivo desde el equipo
          </span>
        </div>
      ) : (
        <div className="p-4 bg-surface-container-low rounded-2xl border border-surface-container-highest flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-[#22c55e]/10 text-[#22c55e] flex items-center justify-center">
              <FileCheck size={24} />
            </div>
            <div>
              <div className="font-bold text-sm text-on-surface">{selectedFile.name}</div>
              <div className="text-xs text-on-surface-variant">
                {(selectedFile.size / 1024).toFixed(1)} KB • {parsedRows.length} fila(s) detectada(s)
              </div>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => fileInputRef.current?.click()}
              className="px-3.5 py-1.5 border border-outline rounded-xl text-xs font-medium text-on-surface hover:bg-surface-container transition-colors"
            >
              Cambiar archivo
            </button>
            <button
              onClick={handleClear}
              className="p-1.5 text-error hover:bg-error/10 rounded-xl transition-colors"
              title="Quitar archivo"
            >
              <Trash2 size={18} />
            </button>
          </div>
          <input 
            type="file" 
            ref={fileInputRef}
            onChange={(e) => {
              if (e.target.files && e.target.files[0]) {
                handleFileUpload(e.target.files[0]);
              }
            }}
            accept=".xlsx, .xls, .csv" 
            className="hidden" 
          />
        </div>
      )}

      {/* Previsualización y Validación */}
      {parsedRows.length > 0 && (
        <div className="space-y-4">
          
          {/* Summary KPIs */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="p-4 bg-surface rounded-xl border border-outline-variant flex items-center justify-between">
              <div>
                <div className="text-xs text-on-surface-variant font-medium">Total de Registros</div>
                <div className="text-xl font-bold text-on-surface">{validationSummary.total}</div>
              </div>
              <FileSpreadsheet size={24} className="text-outline" />
            </div>

            <div className="p-4 bg-[#22c55e]/10 rounded-xl border border-[#22c55e]/30 flex items-center justify-between">
              <div>
                <div className="text-xs text-[#15803d] font-semibold">Listos para Importar</div>
                <div className="text-xl font-bold text-[#15803d]">{validationSummary.valid}</div>
              </div>
              <CheckCircle2 size={24} className="text-[#22c55e]" />
            </div>

            <div className={`p-4 rounded-xl border flex items-center justify-between ${validationSummary.invalid > 0 ? 'bg-error-container/40 border-error/30' : 'bg-surface border-outline-variant'}`}>
              <div>
                <div className={`text-xs font-semibold ${validationSummary.invalid > 0 ? 'text-error' : 'text-on-surface-variant'}`}>
                  Con Errores / Incompletos
                </div>
                <div className={`text-xl font-bold ${validationSummary.invalid > 0 ? 'text-error' : 'text-on-surface'}`}>
                  {validationSummary.invalid}
                </div>
              </div>
              <AlertCircle size={24} className={validationSummary.invalid > 0 ? 'text-error' : 'text-outline'} />
            </div>
          </div>

          {/* Action Toolbar */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 pt-2">
            <div className="flex items-center gap-2">
              <span className="text-xs font-medium text-on-surface-variant">Filtrar vista:</span>
              <button
                onClick={() => setFilterMode('all')}
                className={`px-3 py-1 text-xs rounded-lg font-medium transition-colors ${filterMode === 'all' ? 'bg-primary text-on-primary' : 'bg-surface border border-outline-variant text-on-surface'}`}
              >
                Todos ({parsedRows.length})
              </button>
              <button
                onClick={() => setFilterMode('valid')}
                className={`px-3 py-1 text-xs rounded-lg font-medium transition-colors ${filterMode === 'valid' ? 'bg-[#22c55e] text-white' : 'bg-surface border border-outline-variant text-on-surface'}`}
              >
                Válidos ({validationSummary.valid})
              </button>
              {validationSummary.invalid > 0 && (
                <button
                  onClick={() => setFilterMode('invalid')}
                  className={`px-3 py-1 text-xs rounded-lg font-medium transition-colors ${filterMode === 'invalid' ? 'bg-error text-on-error' : 'bg-surface border border-outline-variant text-on-surface'}`}
                >
                  Con Errores ({validationSummary.invalid})
                </button>
              )}
            </div>

            <button
              onClick={handleExecuteImport}
              disabled={isImporting || validationSummary.valid === 0}
              className="flex items-center gap-2 px-5 py-2.5 bg-primary text-on-primary rounded-xl font-bold text-sm hover:bg-primary/90 transition-all shadow-md disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isImporting ? (
                <>
                  <RefreshCw size={16} className="animate-spin" />
                  Importando {validationSummary.valid} activos...
                </>
              ) : (
                <>
                  <Check size={16} />
                  Confirmar e Importar {validationSummary.valid} Activo(s)
                </>
              )}
            </button>
          </div>

          {/* Preview Table */}
          <div className="bg-surface-container-lowest border border-surface-container-highest rounded-2xl shadow-sm overflow-hidden">
            <div className="overflow-x-auto max-h-[420px]">
              <table className="w-full text-left border-collapse text-xs">
                <thead className="sticky top-0 bg-surface-bright border-b border-surface-container-highest z-10 font-semibold uppercase text-on-surface-variant">
                  <tr>
                    <th className="p-3.5 pl-4 w-14">Fila</th>
                    <th className="p-3.5 w-24">Estado</th>
                    <th className="p-3.5">Nombre</th>
                    <th className="p-3.5">Categoría Asignada</th>
                    <th className="p-3.5">Ambiente Asignado</th>
                    <th className="p-3.5">Marca / Modelo</th>
                    <th className="p-3.5">Serie</th>
                    <th className="p-3.5">Condición</th>
                    <th className="p-3.5">Valor (Bs)</th>
                    <th className="p-3.5 pr-4">Observaciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-container-highest">
                  {filteredRows.map((row, idx) => (
                    <tr 
                      key={idx} 
                      className={`hover:bg-surface-container-low transition-colors ${!row.isValid ? 'bg-error-container/10' : ''}`}
                    >
                      <td className="p-3.5 pl-4 font-mono font-medium text-outline">#{row.rowNumber}</td>
                      <td className="p-3.5">
                        {row.isValid ? (
                          <span className="inline-flex items-center gap-1 text-[#15803d] font-semibold bg-[#22c55e]/15 px-2 py-0.5 rounded-full text-[11px]">
                            <CheckCircle2 size={12} /> Listo
                          </span>
                        ) : (
                          <span 
                            title={row.errors.join(' ')}
                            className="inline-flex items-center gap-1 text-error font-semibold bg-error/10 px-2 py-0.5 rounded-full text-[11px] cursor-help"
                          >
                            <AlertCircle size={12} /> Error
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 font-semibold text-on-surface max-w-[200px] truncate" title={row.nombre}>
                        {row.nombre || <span className="text-error italic">Sin nombre</span>}
                      </td>
                      <td className="p-3.5">
                        {row.matchedTipo ? (
                          <span className="font-medium text-on-surface bg-surface-container px-2 py-0.5 rounded">
                            {row.matchedTipo.nombre} (AA: {row.matchedTipo.codigo})
                          </span>
                        ) : (
                          <span className="text-error font-medium">{row.tipoRaw || 'No indicado'}</span>
                        )}
                      </td>
                      <td className="p-3.5">
                        {row.matchedAmbiente ? (
                          <span className="font-medium text-on-surface bg-surface-container px-2 py-0.5 rounded">
                            {row.matchedAmbiente.nombre} (CC: {row.matchedAmbiente.codigo})
                          </span>
                        ) : (
                          <span className="text-error font-medium">{row.ambienteRaw || 'No indicado'}</span>
                        )}
                      </td>
                      <td className="p-3.5 text-on-surface-variant truncate">
                        {[row.marca, row.modelo].filter(Boolean).join(' • ') || '-'}
                      </td>
                      <td className="p-3.5 font-mono text-outline text-[11px] truncate">
                        {row.numero_serie || '-'}
                      </td>
                      <td className="p-3.5">
                        <span className="px-2 py-0.5 bg-surface-container text-on-surface rounded font-medium text-[11px]">
                          {row.estado}
                        </span>
                      </td>
                      <td className="p-3.5 font-mono font-medium text-on-surface">
                        {row.valor ? `Bs. ${row.valor.toFixed(2)}` : '-'}
                      </td>
                      <td className="p-3.5 pr-4 text-on-surface-variant max-w-[220px] truncate" title={row.descripcion || row.errors.join(', ')}>
                        {row.errors.length > 0 ? (
                          <span className="text-error font-medium">{row.errors.join(', ')}</span>
                        ) : (
                          row.descripcion || '-'
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

        </div>
      )}

    </div>
  );
};

export default ImportarDatosTab;
