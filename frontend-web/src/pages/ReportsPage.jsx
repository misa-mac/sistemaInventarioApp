import { useState, useEffect } from 'react';
import api from '../services/api';
import { FileText, Download, PieChart as PieChartIcon, BarChart2, FileSpreadsheet } from 'lucide-react';
import { PieChart, Pie, Cell, Tooltip as RechartsTooltip, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';
import * as XLSX from 'xlsx';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#FF6B6B', '#4ECDC4', '#45B7D1'];

const ReportsPage = () => {
  const [summary, setSummary] = useState(null);
  const [rawAssets, setRawAssets] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [summaryRes, assetsRes] = await Promise.all([
        api.get('/reports/summary'),
        api.get('/inventory')
      ]);
      setSummary(summaryRes.data);
      setRawAssets(assetsRes.data);
    } catch (err) {
      console.error('Error fetching reports data:', err);
    } finally {
      setLoading(false);
    }
  };

  const exportToExcel = () => {
    if (rawAssets.length === 0) return alert('No hay datos para exportar.');
    
    // Preparar datos para Excel
    const dataForExcel = rawAssets.map(item => ({
      'Código de Activo': item.codigo_activo,
      'Tipo de Equipo': item.tipo?.nombre || 'N/A',
      'Ubicación (Ambiente)': item.ambiente?.nombre || 'N/A',
      'Estado': item.estado,
      'Origen': item.origen,
      'Responsable': item.responsable || 'Sin asignar',
      'Valor Estimado (Bs)': item.valor || '0.00',
      'Fecha Ingreso': new Date(item.fecha_ingreso).toLocaleDateString()
    }));

    const worksheet = XLSX.utils.json_to_sheet(dataForExcel);
    
    // Auto-ajustar ancho de columnas
    const wscols = Object.keys(dataForExcel[0]).map(() => ({ wch: 20 }));
    worksheet['!cols'] = wscols;

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Activos ITBM");
    
    XLSX.writeFile(workbook, `Reporte_Inventario_ITBM_${new Date().toISOString().slice(0,10)}.xlsx`);
  };

  const exportToPDF = () => {
    if (rawAssets.length === 0) return alert('No hay datos para exportar.');
    
    const doc = new jsPDF('landscape');
    
    // Título
    doc.setFontSize(18);
    doc.text('Instituto Tecnológico "Bolivia Mar"', 14, 22);
    doc.setFontSize(12);
    doc.text('Reporte General de Activos Fijos - Sistemas Informáticos', 14, 30);
    doc.setFontSize(10);
    doc.text(`Fecha de generación: ${new Date().toLocaleDateString()}`, 14, 38);
    
    // Resumen arriba
    doc.text(`Total Activos: ${summary?.totalActivos || 0}`, 14, 46);
    doc.text(`Valor Total Estimado: Bs. ${summary?.totalValor || 0}`, 80, 46);

    // Tabla de datos
    const tableColumn = ["Código", "Tipo", "Ambiente", "Estado", "Responsable", "Ingreso"];
    const tableRows = [];

    rawAssets.forEach(item => {
      const rowData = [
        item.codigo_activo,
        item.tipo?.nombre || 'N/A',
        item.ambiente?.nombre || 'N/A',
        item.estado,
        item.responsable || '-',
        new Date(item.fecha_ingreso).toLocaleDateString()
      ];
      tableRows.push(rowData);
    });

    autoTable(doc, {
      head: [tableColumn],
      body: tableRows,
      startY: 55,
      theme: 'grid',
      styles: { fontSize: 8 },
      headStyles: { fillColor: [41, 128, 185] }
    });

    doc.save(`Reporte_Inventario_ITBM_${new Date().toISOString().slice(0,10)}.pdf`);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full text-on-surface-variant">
        Generando métricas...
      </div>
    );
  }

  // Preparar datos para Recharts
  const dataEstado = summary?.porEstado.map(e => ({ name: e.estado, value: parseInt(e.cantidad) })) || [];
  const dataAmbiente = summary?.porAmbiente.map(a => ({ name: a.ambiente, cantidad: parseInt(a.cantidad) })) || [];
  const dataTipo = summary?.porTipo.map(t => ({ name: t.tipo, cantidad: parseInt(t.cantidad) })) || [];

  return (
    <div className="space-y-6 animate-fade-in">
      
      {/* Page Header */}
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-h2 font-h2 text-on-surface tracking-tight mb-1">Reportes y Estadísticas</h1>
          <p className="text-on-surface-variant text-body-sm">Visión global del inventario y exportación de datos.</p>
        </div>
        <div className="flex gap-3">
          <button onClick={exportToExcel} className="flex items-center gap-2 px-4 py-2 bg-[#217346] text-white rounded shadow-sm text-sm font-medium hover:bg-[#1e6b41] transition-colors">
            <FileSpreadsheet size={16} />
            Exportar Excel
          </button>
          <button onClick={exportToPDF} className="flex items-center gap-2 px-4 py-2 bg-[#e74c3c] text-white rounded shadow-sm text-sm font-medium hover:bg-[#c0392b] transition-colors">
            <FileText size={16} />
            Exportar PDF
          </button>
        </div>
      </div>

      {/* Tarjetas de Resumen Rápido */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        
        <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm flex flex-col">
          <div className="text-on-surface-variant text-sm font-medium uppercase tracking-wider mb-2">Total Activos Fijos</div>
          <div className="text-4xl font-bold text-primary mb-1">{summary?.totalActivos || 0}</div>
          <div className="text-xs text-on-surface-variant">Registrados en base de datos</div>
        </div>
        
        <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm flex flex-col">
          <div className="text-on-surface-variant text-sm font-medium uppercase tracking-wider mb-2">Valor Estimado Total</div>
          <div className="text-4xl font-bold text-secondary mb-1">Bs. {summary?.totalValor || 0}</div>
          <div className="text-xs text-on-surface-variant">Suma de valor declarado</div>
        </div>

        <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm flex flex-col">
          <div className="text-on-surface-variant text-sm font-medium uppercase tracking-wider mb-2">Equipos Operativos</div>
          <div className="text-4xl font-bold text-[#22c55e] mb-1">
            {dataEstado.find(e => e.name === 'Activo')?.value || 0}
          </div>
          <div className="text-xs text-on-surface-variant">Estado actual: Activo</div>
        </div>

        <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm flex flex-col">
          <div className="text-on-surface-variant text-sm font-medium uppercase tracking-wider mb-2">Equipos Dañados</div>
          <div className="text-4xl font-bold text-amber-500 mb-1">
            {dataEstado.find(e => e.name === 'Dañado')?.value || 0}
          </div>
          <div className="text-xs text-on-surface-variant">Requieren reparación inmediata</div>
        </div>

      </div>

      {/* Gráficos */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Gráfico 1: Estado */}
        <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm">
          <h3 className="text-lg font-medium text-on-surface mb-6 flex items-center gap-2">
            <PieChartIcon size={20} className="text-primary" />
            Distribución por Estado
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={dataEstado}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  fill="#8884d8"
                  paddingAngle={5}
                  dataKey="value"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {dataEstado.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <RechartsTooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Gráfico 2: Por Ambiente */}
        <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm">
          <h3 className="text-lg font-medium text-on-surface mb-6 flex items-center gap-2">
            <BarChart2 size={20} className="text-secondary" />
            Activos por Ambiente
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={dataAmbiente} margin={{ top: 5, right: 30, left: 0, bottom: 25 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.3} />
                <XAxis dataKey="name" angle={-45} textAnchor="end" height={60} tick={{ fontSize: 11 }} />
                <YAxis />
                <RechartsTooltip />
                <Bar dataKey="cantidad" fill="#0088FE" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Gráfico 3: Por Tipo (Ocupa todo el ancho abajo) */}
        <div className="lg:col-span-2 bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm">
          <h3 className="text-lg font-medium text-on-surface mb-6 flex items-center gap-2">
            <BarChart2 size={20} className="text-primary" />
            Clasificación por Tipo de Equipo
          </h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={dataTipo} margin={{ top: 5, right: 30, left: 0, bottom: 25 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.3} />
                <XAxis dataKey="name" angle={-15} textAnchor="end" height={40} tick={{ fontSize: 11 }} />
                <YAxis />
                <RechartsTooltip />
                <Bar dataKey="cantidad" fill="#00C49F" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

      </div>
    </div>
  );
};

export default ReportsPage;
