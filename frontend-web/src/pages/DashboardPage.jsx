import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import { 
  Monitor, 
  AlertTriangle, 
  CheckCircle2, 
  ArrowRight, 
  Plus, 
  Building,
  Activity,
  FileText
} from 'lucide-react';

const DashboardPage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSummary = async () => {
      try {
        const res = await api.get('/reports/summary');
        setSummary(res.data);
      } catch (err) {
        console.error('Error fetching dashboard summary:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchSummary();
  }, []);

  const activosCount = summary?.porEstado.find(e => e.estado === 'Activo')?.cantidad || 0;
  const danadosCount = summary?.porEstado.find(e => e.estado === 'Dañado')?.cantidad || 0;
  const total = summary?.totalActivos || 0;

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  };

  return (
    <div className="space-y-8 animate-fade-in">
      
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-primary to-primary-fixed p-8 rounded-2xl shadow-md text-white relative overflow-hidden">
        <div className="relative z-10">
          <h1 className="text-3xl font-bold tracking-tight mb-2">
            {getGreeting()}, {user?.nombre_completo?.split(' ')[0] || 'Administrador'}
          </h1>
          <p className="text-primary-container max-w-xl">
            Bienvenido al Sistema de Inventario Tecnológico ITBM. Aquí tienes un resumen del estado actual de los laboratorios y equipos de la institución.
          </p>
        </div>
        
        {/* Decorative background shape */}
        <div className="absolute right-0 top-0 w-64 h-64 bg-white opacity-5 rounded-full -translate-y-1/2 translate-x-1/4 blur-2xl"></div>
        <div className="absolute right-32 bottom-0 w-48 h-48 bg-white opacity-10 rounded-full translate-y-1/3 blur-xl"></div>
      </div>

      {loading ? (
        <div className="flex justify-center p-12 text-on-surface-variant">Cargando métricas...</div>
      ) : (
        <>
          {/* Quick Stats Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            
            {/* Total Assets */}
            <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm flex items-center justify-between group hover:border-primary/50 transition-colors cursor-pointer" onClick={() => navigate('/inventario')}>
              <div>
                <p className="text-sm font-medium text-on-surface-variant uppercase tracking-wider mb-1">Total de Equipos</p>
                <h3 className="text-3xl font-bold text-on-surface">{total}</h3>
              </div>
              <div className="w-14 h-14 rounded-full bg-primary-container text-primary flex items-center justify-center group-hover:scale-110 transition-transform">
                <Monitor size={28} />
              </div>
            </div>

            {/* Operative */}
            <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-on-surface-variant uppercase tracking-wider mb-1">Operativos</p>
                <h3 className="text-3xl font-bold text-[#22c55e]">{activosCount}</h3>
              </div>
              <div className="w-14 h-14 rounded-full bg-[#22c55e]/10 text-[#22c55e] flex items-center justify-center">
                <CheckCircle2 size={28} />
              </div>
            </div>

            {/* Damaged */}
            <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-on-surface-variant uppercase tracking-wider mb-1">Para Reparación</p>
                <h3 className="text-3xl font-bold text-amber-500">{danadosCount}</h3>
              </div>
              <div className="w-14 h-14 rounded-full bg-amber-500/10 text-amber-500 flex items-center justify-center">
                <AlertTriangle size={28} />
              </div>
            </div>
            
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* Quick Actions Panel */}
            <div className="lg:col-span-2 bg-surface-container-lowest rounded-xl border border-surface-container-highest shadow-sm p-6">
              <div className="flex items-center gap-2 mb-6">
                <Activity className="text-primary" size={20} />
                <h3 className="text-lg font-medium text-on-surface">Accesos Rápidos</h3>
              </div>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <button 
                  onClick={() => navigate('/inventario')}
                  className="flex flex-col text-left p-5 rounded-xl border border-outline-variant hover:border-primary hover:bg-surface-container-low transition-colors group"
                >
                  <div className="w-10 h-10 rounded bg-primary-container text-primary flex items-center justify-center mb-3 group-hover:scale-105 transition-transform">
                    <Plus size={20} />
                  </div>
                  <h4 className="font-medium text-on-surface mb-1">Registrar Nuevo Activo</h4>
                  <p className="text-sm text-on-surface-variant">Añade hardware a la base de datos y genera su código QR.</p>
                </button>

                <button 
                  onClick={() => navigate('/ambientes')}
                  className="flex flex-col text-left p-5 rounded-xl border border-outline-variant hover:border-secondary hover:bg-surface-container-low transition-colors group"
                >
                  <div className="w-10 h-10 rounded bg-secondary-container text-secondary flex items-center justify-center mb-3 group-hover:scale-105 transition-transform">
                    <Building size={20} />
                  </div>
                  <h4 className="font-medium text-on-surface mb-1">Gestionar Laboratorios</h4>
                  <p className="text-sm text-on-surface-variant">Administra las áreas donde se encuentran distribuidos los equipos.</p>
                </button>
                
                <button 
                  onClick={() => navigate('/reportes')}
                  className="flex flex-col text-left p-5 rounded-xl border border-outline-variant hover:border-tertiary hover:bg-surface-container-low transition-colors group sm:col-span-2"
                >
                  <div className="w-10 h-10 rounded bg-tertiary-container text-tertiary flex items-center justify-center mb-3 group-hover:scale-105 transition-transform">
                    <FileText size={20} />
                  </div>
                  <h4 className="font-medium text-on-surface mb-1">Generar Reporte Oficial</h4>
                  <p className="text-sm text-on-surface-variant">Exporta el listado completo de activos fijos a PDF para su firma y archivo físico.</p>
                </button>
              </div>
            </div>

            {/* Distribution Summary */}
            <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest shadow-sm p-6 flex flex-col">
              <h3 className="text-lg font-medium text-on-surface mb-6">Distribución de Infraestructura</h3>
              
              <div className="space-y-4 flex-1">
                {summary?.porAmbiente?.length > 0 ? (
                  summary.porAmbiente.slice(0, 5).map((amb, idx) => (
                    <div key={idx} className="flex items-center justify-between p-3 rounded-lg bg-surface-container-low">
                      <div className="flex items-center gap-3">
                        <div className="w-2 h-2 rounded-full bg-primary"></div>
                        <span className="font-medium text-on-surface text-sm">{amb.ambiente}</span>
                      </div>
                      <span className="text-sm font-bold text-primary bg-primary-container px-2 py-0.5 rounded">
                        {amb.cantidad} {amb.cantidad == 1 ? 'equipo' : 'equipos'}
                      </span>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-on-surface-variant text-center mt-8">No hay datos de distribución.</p>
                )}
              </div>
              
              <button onClick={() => navigate('/ambientes')} className="mt-6 w-full py-2.5 text-sm font-medium text-primary bg-primary-container/50 hover:bg-primary-container rounded-lg transition-colors flex items-center justify-center gap-2">
                Ver todos los ambientes <ArrowRight size={16} />
              </button>
            </div>

          </div>
        </>
      )}
    </div>
  );
};

export default DashboardPage;
