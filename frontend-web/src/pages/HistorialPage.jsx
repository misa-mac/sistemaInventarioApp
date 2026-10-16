import { useState, useEffect } from 'react';
import api from '../services/api';
import { Clock, Plus, ArrowRightLeft, Wrench, ShieldAlert, X, Trash2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const EventoFormModal = ({ isOpen, onClose, onSuccess }) => {
  const [activos, setActivos] = useState([]);
  const [ambientes, setAmbientes] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  
  const [formData, setFormData] = useState({
    activo_id: '',
    tipo_evento: 'traslado',
    ambiente_destino_id: '',
    estado_nuevo: '',
    costo_mantenimiento: '',
    observaciones: ''
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isOpen) {
      fetchData();
      setFormData({
        activo_id: '',
        tipo_evento: 'traslado',
        ambiente_destino_id: '',
        estado_nuevo: '',
        costo_mantenimiento: '',
        observaciones: ''
      });
      setSearchTerm('');
      setIsDropdownOpen(false);
      setError(null);
    }
  }, [isOpen]);

  const fetchData = async () => {
    try {
      const [actRes, ambRes] = await Promise.all([
        api.get('/inventory'),
        api.get('/ambientes')
      ]);
      setActivos(actRes.data.filter(a => a.estado !== 'De Baja')); 
      setAmbientes(ambRes.data);
    } catch (err) {
      console.error(err);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.activo_id) {
      setError('Por favor, selecciona un equipo.');
      return;
    }
    setLoading(true);
    setError(null);
    
    try {
      await api.post('/movimientos', formData);
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Error al registrar el evento.');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  const filteredActivos = activos.filter(a => {
    const searchLower = searchTerm.toLowerCase();
    return (a.codigo_activo?.toLowerCase().includes(searchLower)) || 
           (a.descripcion?.toLowerCase().includes(searchLower)) ||
           (a.tipo?.nombre?.toLowerCase().includes(searchLower));
  });

  const selectedActivo = activos.find(a => a.id === formData.activo_id);

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in p-4">
      <div className="bg-surface-container-lowest rounded-xl shadow-lg w-full max-w-lg flex flex-col max-h-[90vh]">
        <div className="flex justify-between items-center p-6 border-b border-surface-container-highest shrink-0">
          <h2 className="text-xl font-medium text-on-surface flex items-center gap-2">
            <Clock size={20} className="text-primary" />
            Registrar Evento
          </h2>
          <button onClick={onClose} className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full">
            <X size={20} />
          </button>
        </div>
        
        <div className="p-6 overflow-y-auto flex-1">
          <form id="eventoForm" onSubmit={handleSubmit} className="space-y-4">
            {error && <div className="bg-error-container text-on-error-container p-3 rounded text-sm">{error}</div>}
            
            <div className="relative">
              <label className="block text-sm font-medium text-on-surface mb-1">Seleccionar Equipo *</label>
              
              <div className="relative">
                <input 
                  type="text"
                  placeholder="Buscar por código QR, marca o modelo..."
                  value={searchTerm}
                  onChange={(e) => {
                    setSearchTerm(e.target.value);
                    setIsDropdownOpen(true);
                  }}
                  onFocus={() => setIsDropdownOpen(true)}
                  className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                />
                
                {isDropdownOpen && (
                  <div className="absolute z-10 w-full mt-1 bg-surface-container-lowest border border-surface-container-highest rounded-md shadow-lg max-h-60 overflow-y-auto">
                    {filteredActivos.length > 0 ? (
                      filteredActivos.map(a => (
                        <div 
                          key={a.id} 
                          className="px-4 py-2 hover:bg-surface-container cursor-pointer text-sm border-b border-surface-container-highest last:border-0"
                          onClick={() => {
                            setFormData({...formData, activo_id: a.id});
                            setSearchTerm(`${a.codigo_activo} - ${a.tipo?.nombre} (${a.descripcion || 'Sin descripción'})`);
                            setIsDropdownOpen(false);
                          }}
                        >
                          <div className="font-medium text-primary">{a.codigo_activo}</div>
                          <div className="text-on-surface-variant text-xs">{a.tipo?.nombre} - {a.descripcion}</div>
                        </div>
                      ))
                    ) : (
                      <div className="px-4 py-3 text-sm text-on-surface-variant text-center">No se encontraron equipos.</div>
                    )}
                  </div>
                )}
              </div>
            </div>

            {selectedActivo && (
              <div className="p-3 bg-surface-container-low rounded border border-outline-variant/50 text-sm flex justify-between items-center">
                <div>
                  <p className="text-on-surface-variant text-xs">Ubicación Actual:</p>
                  <p className="font-medium text-on-surface">{selectedActivo.ambiente?.nombre || 'Desconocida'}</p>
                </div>
                <div className="text-right">
                  <p className="text-on-surface-variant text-xs">Estado Actual:</p>
                  <p className="font-medium text-on-surface">{selectedActivo.estado}</p>
                </div>
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Tipo de Evento *</label>
              <div className="grid grid-cols-3 gap-2">
                {['traslado', 'mantenimiento', 'baja'].map(tipo => (
                  <label key={tipo} className={`cursor-pointer border rounded p-2 text-center text-sm font-medium transition-colors ${formData.tipo_evento === tipo ? 'bg-primary-container text-on-primary-container border-primary' : 'bg-surface border-outline-variant text-on-surface-variant hover:bg-surface-container'}`}>
                    <input type="radio" name="tipo_evento" value={tipo} className="hidden" checked={formData.tipo_evento === tipo} onChange={(e) => setFormData({...formData, tipo_evento: e.target.value})} />
                    <span className="capitalize">{tipo}</span>
                  </label>
                ))}
              </div>
            </div>

            {formData.tipo_evento === 'traslado' && (
              <div className="animate-fade-in">
                <label className="block text-sm font-medium text-on-surface mb-1">Laboratorio / Ambiente Destino *</label>
                <select 
                  value={formData.ambiente_destino_id}
                  onChange={(e) => setFormData({...formData, ambiente_destino_id: e.target.value})}
                  required
                  className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                >
                  <option value="">-- Seleccionar Nuevo Ambiente --</option>
                  {ambientes.filter(amb => amb.id !== selectedActivo?.ambiente_id).map(amb => (
                    <option key={amb.id} value={amb.id}>{amb.nombre}</option>
                  ))}
                </select>
              </div>
            )}

            {formData.tipo_evento === 'mantenimiento' && (
              <div className="grid grid-cols-2 gap-4 animate-fade-in">
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Actualizar Estado</label>
                  <select 
                    value={formData.estado_nuevo}
                    onChange={(e) => setFormData({...formData, estado_nuevo: e.target.value})}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                  >
                    <option value="">Mantener Estado Actual</option>
                    <option value="Activo">Reparado (Activo)</option>
                    <option value="Dañado">En Reparación (Dañado)</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Costo (Bs.)</label>
                  <input 
                    type="number"
                    step="0.01"
                    min="0"
                    placeholder="Ej: 150.00" 
                    value={formData.costo_mantenimiento}
                    onChange={(e) => setFormData({...formData, costo_mantenimiento: e.target.value})}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                  />
                </div>
              </div>
            )}

            {formData.tipo_evento === 'baja' && (
              <div className="p-3 bg-error-container text-on-error-container rounded text-sm animate-fade-in font-medium">
                Al registrar la Baja, el equipo cambiará su estado permanentemente a "De Baja" y ya no estará disponible para traslados.
                <input type="hidden" name="estado_nuevo" value="De Baja" />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Observaciones o Justificación *</label>
              <textarea 
                value={formData.observaciones}
                onChange={(e) => setFormData({...formData, observaciones: e.target.value})}
                required
                rows="3"
                placeholder="Detalle técnico del evento..."
                className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
              ></textarea>
            </div>
          </form>
        </div>
        
        <div className="p-6 border-t border-surface-container-highest shrink-0 flex justify-end gap-3 bg-surface-bright rounded-b-xl">
          <button type="button" onClick={onClose} className="px-4 py-2 border border-outline rounded text-sm font-medium">Cancelar</button>
          <button type="submit" form="eventoForm" disabled={loading} className="px-4 py-2 bg-primary text-on-primary rounded text-sm font-medium hover:bg-primary/90">
            {loading ? 'Procesando...' : 'Registrar Evento'}
          </button>
        </div>

      </div>
    </div>
  );
};

const HistorialPage = () => {
  const { user } = useAuth();
  const [eventos, setEventos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    fetchEventos();
  }, []);

  const fetchEventos = async () => {
    setLoading(true);
    try {
      const res = await api.get('/movimientos');
      setEventos(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const getEventIcon = (tipo) => {
    switch(tipo) {
      case 'traslado': return <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center"><ArrowRightLeft size={16} /></div>;
      case 'mantenimiento': return <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center"><Wrench size={16} /></div>;
      case 'baja': return <div className="w-8 h-8 rounded-full bg-red-100 text-red-600 flex items-center justify-center"><ShieldAlert size={16} /></div>;
      default: return <div className="w-8 h-8 rounded-full bg-gray-100 text-gray-600 flex items-center justify-center"><Clock size={16} /></div>;
    }
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString('es-ES', { 
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute:'2-digit'
    });
  };

  const handleDelete = async (id) => {
    if (window.confirm('¿Estás seguro de eliminar este registro del historial? (Nota: Esto NO revertirá el estado actual del equipo en el inventario)')) {
      try {
        await api.delete(`/movimientos/${id}`);
        fetchEventos();
      } catch (err) {
        console.error('Error al eliminar:', err);
      }
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-h2 font-h2 text-on-surface tracking-tight mb-1">Historial de Eventos</h1>
          <p className="text-on-surface-variant text-body-sm">Registro de traslados, mantenimientos y bajas de equipos.</p>
        </div>
        <button onClick={() => setIsModalOpen(true)} className="flex items-center gap-2 px-4 py-2 bg-primary text-on-primary rounded shadow-sm text-sm font-medium hover:bg-primary/90">
          <Plus size={16} />
          Registrar Evento
        </button>
      </div>

      <div className="bg-surface-container-lowest border border-surface-container-highest rounded-xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-on-surface-variant">Cargando historial...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-bright border-b border-surface-container-highest text-sm text-on-surface-variant">
                  <th className="p-4 font-medium w-16">Tipo</th>
                  <th className="p-4 font-medium">Equipo (QR)</th>
                  <th className="p-4 font-medium">Detalle del Evento</th>
                  <th className="p-4 font-medium">Técnico/Responsable</th>
                  <th className="p-4 font-medium">Fecha</th>
                  <th className="p-4 font-medium w-16"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-highest">
                {eventos.map(ev => (
                  <tr key={ev.id} className="hover:bg-surface-container-low transition-colors align-top">
                    <td className="p-4">
                      {getEventIcon(ev.tipo_evento)}
                    </td>
                    <td className="p-4">
                      <p className="font-mono font-medium text-primary">{ev.Activo?.codigo_activo}</p>
                      <p className="text-xs text-on-surface-variant mt-1">Estado: {ev.estado_nuevo || ev.estado_anterior || ev.Activo?.estado}</p>
                    </td>
                    <td className="p-4">
                      {ev.tipo_evento === 'traslado' && (
                        <div className="text-sm">
                          <span className="text-on-surface-variant">De:</span> <span className="font-medium text-on-surface">{ev.origen?.nombre}</span> <br/>
                          <span className="text-on-surface-variant">A:</span> <span className="font-medium text-on-surface">{ev.destino?.nombre}</span>
                        </div>
                      )}
                      {ev.tipo_evento === 'mantenimiento' && (
                        <div className="text-sm">
                          <span className="font-medium text-on-surface">Mantenimiento</span>
                          {ev.costo_mantenimiento && <span className="ml-2 bg-green-100 text-green-700 px-1.5 py-0.5 rounded text-xs font-bold">Bs. {ev.costo_mantenimiento}</span>}
                        </div>
                      )}
                      {ev.tipo_evento === 'baja' && (
                        <div className="text-sm font-medium text-error">Baja Definitiva del Equipo</div>
                      )}
                      
                      <p className="text-xs text-on-surface-variant mt-2 italic border-l-2 border-outline-variant pl-2">
                        "{ev.observaciones}"
                      </p>
                    </td>
                    <td className="p-4 text-sm font-medium text-on-surface">
                      {ev.Usuario?.nombre_completo}
                    </td>
                    <td className="p-4 text-sm text-on-surface-variant whitespace-nowrap">
                      {formatDate(ev.created_at)}
                    </td>
                    <td className="p-4 text-right">
                      <button 
                        onClick={() => handleDelete(ev.id)}
                        className="text-on-surface-variant hover:text-error hover:bg-error-container p-1.5 rounded transition-colors"
                        title="Eliminar del historial"
                      >
                        <Trash2 size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
                {eventos.length === 0 && (
                  <tr>
                    <td colSpan="5" className="p-8 text-center text-on-surface-variant">No hay eventos registrados en el historial.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <EventoFormModal 
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={fetchEventos}
      />
    </div>
  );
};

export default HistorialPage;
