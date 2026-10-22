import { useState, useEffect } from 'react';
import api from '../services/api';
import { 
  Plus, Edit2, Trash2, Building, X, Wifi, WifiOff, MapPin, 
  ExternalLink, Navigation, Compass, Layers, ShieldCheck, 
  Sparkles, Globe2, Radio
} from 'lucide-react';

const PRESETS_ITBM = [
  { nombre: 'Laboratorio 1', codigo: 20, ubicacion: 'Bloque A - Planta Alta', latitude: -16.577738, longitude: -68.196556, radio_geofence: 18, descripcion: 'Lab de computadoras' },
  { nombre: 'Laboratorio 2', codigo: 21, ubicacion: 'Bloque A - Planta Alta', latitude: -16.577660, longitude: -68.196602, radio_geofence: 17, descripcion: 'Lab de computadoras' },
  { nombre: 'Laboratorio 3', codigo: 22, ubicacion: 'Bloque B - Planta Baja', latitude: -16.577892, longitude: -68.196768, radio_geofence: 22, descripcion: 'Lab de computadoras' },
  { nombre: 'Taller 1', codigo: 23, ubicacion: 'Bloque C - Técnico', latitude: -16.577840, longitude: -68.196590, radio_geofence: 18, descripcion: 'Espacio de trabajo técnico' },
  { nombre: 'Taller 2', codigo: 24, ubicacion: 'Bloque C - Técnico', latitude: -16.577850, longitude: -68.196580, radio_geofence: 18, descripcion: 'Espacio de trabajo técnico' },
  { nombre: 'Oficina Central', codigo: 25, ubicacion: 'Edificio Administrativo', latitude: -16.577785, longitude: -68.196520, radio_geofence: 15, descripcion: 'Oficina Administrativa IT' },
  { nombre: 'Depósito Central', codigo: 26, ubicacion: 'Bloque D - Almacén', latitude: -16.577800, longitude: -68.196600, radio_geofence: 50, descripcion: 'Depósito de Hardware' }
];

const AmbienteFormModal = ({ isOpen, onClose, onSuccess, editData }) => {
  const [formData, setFormData] = useState({
    codigo: '',
    nombre: '',
    ubicacion: '',
    latitude: '',
    longitude: '',
    radio_geofence: 18,
    descripcion: '',
    tiene_internet: true
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isOpen) {
      if (editData) {
        setFormData({
          codigo: editData.codigo,
          nombre: editData.nombre,
          ubicacion: editData.ubicacion || '',
          latitude: editData.latitude !== null && editData.latitude !== undefined ? editData.latitude : '',
          longitude: editData.longitude !== null && editData.longitude !== undefined ? editData.longitude : '',
          radio_geofence: editData.radio_geofence || 18,
          descripcion: editData.descripcion || '',
          tiene_internet: editData.tiene_internet !== undefined ? editData.tiene_internet : true
        });
      } else {
        setFormData({ 
          codigo: '', 
          nombre: '', 
          ubicacion: '', 
          latitude: '', 
          longitude: '', 
          radio_geofence: 18, 
          descripcion: '', 
          tiene_internet: true 
        });
      }
      setError(null);
    }
  }, [isOpen, editData]);

  const handleApplyPreset = (preset) => {
    setFormData(prev => ({
      ...prev,
      nombre: preset.nombre,
      codigo: preset.codigo,
      ubicacion: preset.ubicacion,
      latitude: preset.latitude,
      longitude: preset.longitude,
      radio_geofence: preset.radio_geofence,
      descripcion: preset.descripcion
    }));
  };

  const calculateArea = (radius) => {
    const r = parseFloat(radius);
    if (isNaN(r) || r <= 0) return 0;
    return Math.round(Math.PI * r * r);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      const payload = {
        ...formData,
        codigo: parseInt(formData.codigo, 10),
        radio_geofence: parseFloat(formData.radio_geofence) || 18,
        latitude: formData.latitude !== '' ? parseFloat(formData.latitude) : null,
        longitude: formData.longitude !== '' ? parseFloat(formData.longitude) : null
      };

      if (editData) {
        await api.put(`/ambientes/${editData.id}`, payload);
      } else {
        await api.post('/ambientes', payload);
      }
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Error al guardar el ambiente.');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in p-4 overflow-y-auto">
      <div className="bg-surface-container-lowest rounded-2xl shadow-2xl w-full max-w-xl flex flex-col my-8 border border-surface-container-highest">
        
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b border-surface-container-highest bg-surface-bright rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
              <Building size={22} />
            </div>
            <div>
              <h2 className="text-xl font-bold text-on-surface">
                {editData ? 'Editar Ambiente & Área' : 'Nuevo Ambiente de Trabajo'}
              </h2>
              <p className="text-xs text-on-surface-variant">Configure código CC, ubicación geográfica y área de geocerca.</p>
            </div>
          </div>
          <button onClick={onClose} className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full transition-colors">
            <X size={20} />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {error && (
            <div className="bg-error-container text-on-error-container p-3.5 rounded-xl text-sm font-medium border border-error/20">
              {error}
            </div>
          )}

          {/* Quick Presets selector for ITBM mobile app */}
          <div className="p-3.5 bg-surface-container-low rounded-xl border border-surface-container-highest">
            <div className="flex items-center gap-1.5 text-xs font-semibold text-primary mb-2">
              <Sparkles size={14} /> Cargar Datos Oficiales de Geocerca ITBM (App Móvil):
            </div>
            <div className="flex flex-wrap gap-1.5">
              {PRESETS_ITBM.map((preset, idx) => (
                <button
                  type="button"
                  key={idx}
                  onClick={() => handleApplyPreset(preset)}
                  className="px-2.5 py-1 text-xs font-medium rounded-lg bg-surface border border-outline-variant/60 hover:border-primary hover:bg-primary/5 hover:text-primary transition-all text-on-surface"
                >
                  {preset.nombre}
                </button>
              ))}
            </div>
          </div>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Código Identificador (CC) *</label>
              <input 
                type="number" 
                value={formData.codigo}
                onChange={(e) => setFormData({...formData, codigo: e.target.value})}
                required
                min="0"
                max="99"
                placeholder="Ej: 20"
                className="w-full px-3.5 py-2.5 bg-surface border border-outline-variant rounded-xl focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-sm font-mono font-semibold"
              />
              <p className="text-[11px] text-on-surface-variant mt-1">Dígitos de 0 a 99 correspondientes al bloque CC del código QR.</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Nombre del Ambiente *</label>
              <input 
                type="text" 
                value={formData.nombre}
                onChange={(e) => setFormData({...formData, nombre: e.target.value})}
                required
                placeholder="Ej: Laboratorio 1"
                className="w-full px-3.5 py-2.5 bg-surface border border-outline-variant rounded-xl focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-sm font-medium"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">
              Área / Ubicación Física en el Campus
            </label>
            <div className="relative">
              <MapPin size={17} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-outline" />
              <input 
                type="text" 
                value={formData.ubicacion}
                onChange={(e) => setFormData({...formData, ubicacion: e.target.value})}
                placeholder="Ej: Bloque A - Planta Alta, Bloque C - Técnico"
                className="w-full pl-10 pr-3.5 py-2.5 bg-surface border border-outline-variant rounded-xl focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-sm"
              />
            </div>
          </div>

          {/* Geographical Coordinates Section */}
          <div className="p-4 bg-surface-container/40 rounded-xl border border-surface-container-highest space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-primary flex items-center gap-1.5">
                <Compass size={14} /> Coordenadas GPS & Geocerca Móvil
              </span>
              {formData.latitude && formData.longitude && (
                <a
                  href={`https://www.google.com/maps?q=${formData.latitude},${formData.longitude}`}
                  target="_blank"
                  rel="noreferrer"
                  className="text-xs text-primary hover:underline flex items-center gap-1 font-medium"
                >
                  <ExternalLink size={12} /> Ver en Maps
                </a>
              )}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-on-surface-variant mb-1">Latitud GPS</label>
                <input 
                  type="number" 
                  step="any"
                  value={formData.latitude}
                  onChange={(e) => setFormData({...formData, latitude: e.target.value})}
                  placeholder="-16.577738"
                  className="w-full px-3 py-2 bg-surface border border-outline-variant rounded-lg focus:border-primary focus:ring-1 focus:ring-primary outline-none text-xs font-mono"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-on-surface-variant mb-1">Longitud GPS</label>
                <input 
                  type="number" 
                  step="any"
                  value={formData.longitude}
                  onChange={(e) => setFormData({...formData, longitude: e.target.value})}
                  placeholder="-68.196556"
                  className="w-full px-3 py-2 bg-surface border border-outline-variant rounded-lg focus:border-primary focus:ring-1 focus:ring-primary outline-none text-xs font-mono"
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between items-center mb-1">
                <label className="text-xs font-medium text-on-surface-variant">Radio de Cobertura Geográfica</label>
                <span className="text-xs font-bold text-primary font-mono">
                  {formData.radio_geofence || 0} m (~{calculateArea(formData.radio_geofence).toLocaleString()} m² de área)
                </span>
              </div>
              <input 
                type="number" 
                value={formData.radio_geofence}
                onChange={(e) => setFormData({...formData, radio_geofence: e.target.value})}
                min="5"
                max="500"
                className="w-full px-3 py-2 bg-surface border border-outline-variant rounded-lg focus:border-primary focus:ring-1 focus:ring-primary outline-none text-xs font-mono"
              />
              <p className="text-[11px] text-on-surface-variant mt-1">
                Define el radio de tolerancia espacial utilizado por el celular para validar auditorías en sitio.
              </p>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Descripción</label>
            <textarea 
              value={formData.descripcion}
              onChange={(e) => setFormData({...formData, descripcion: e.target.value})}
              rows="2"
              placeholder="Usos del aula, laboratorios de cómputo, responsables asignados..."
              className="w-full px-3.5 py-2.5 bg-surface border border-outline-variant rounded-xl focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-sm"
            ></textarea>
          </div>

          <div className="flex items-center gap-3 p-3 bg-surface-container rounded-xl">
            <input 
              type="checkbox" 
              id="tiene_internet"
              checked={formData.tiene_internet}
              onChange={(e) => setFormData({...formData, tiene_internet: e.target.checked})}
              className="w-4 h-4 text-primary rounded border-outline-variant focus:ring-primary cursor-pointer"
            />
            <label htmlFor="tiene_internet" className="text-sm font-medium text-on-surface cursor-pointer select-none">
              Dispone de conexión WiFi / Red institucional (facilita sincronización inmediata en la app móvil)
            </label>
          </div>

          <div className="pt-4 flex justify-end gap-3 border-t border-surface-container-highest">
            <button 
              type="button" 
              onClick={onClose} 
              className="px-4 py-2.5 border border-outline rounded-xl text-sm font-medium text-on-surface hover:bg-surface-container transition-colors"
            >
              Cancelar
            </button>
            <button 
              type="submit" 
              disabled={loading} 
              className="px-5 py-2.5 bg-primary text-on-primary rounded-xl text-sm font-medium hover:bg-primary/90 shadow-sm transition-all"
            >
              {loading ? 'Guardando...' : (editData ? 'Actualizar Ambiente' : 'Guardar Ambiente')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const AmbientesPage = () => {
  const [ambientes, setAmbientes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editItem, setEditItem] = useState(null);

  useEffect(() => {
    fetchAmbientes();
  }, []);

  const fetchAmbientes = async () => {
    setLoading(true);
    try {
      const res = await api.get('/ambientes');
      setAmbientes(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('¿Está seguro de que desea eliminar este ambiente? Si contiene activos asociados, la base de datos lo bloqueará por integridad.')) {
      try {
        await api.delete(`/ambientes/${id}`);
        fetchAmbientes();
      } catch (err) {
        alert(err.response?.data?.message || 'Error al eliminar');
      }
    }
  };

  const handleAdd = () => {
    setEditItem(null);
    setIsModalOpen(true);
  };

  const handleEdit = (item) => {
    setEditItem(item);
    setIsModalOpen(true);
  };

  // Metrics
  const totalAmbientes = ambientes.length;
  const conGps = ambientes.filter(a => a.latitude && a.longitude).length;
  const conInternet = ambientes.filter(a => a.tiene_internet).length;
  const totalAreaM2 = ambientes.reduce((sum, a) => {
    const r = parseFloat(a.radio_geofence);
    return isNaN(r) ? sum : sum + Math.round(Math.PI * r * r);
  }, 0);

  return (
    <div className="space-y-6 animate-fade-in pb-10">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
        <div>
          <h1 className="text-h2 font-h2 text-on-surface tracking-tight mb-1 flex items-center gap-2.5">
            <Building className="text-primary" size={28} />
            Gestión de Ambientes & Áreas
          </h1>
          <p className="text-on-surface-variant text-body-sm">
            Control de laboratorios, talleres, geocercas GPS oficiales y cobertura espacial del ITBM.
          </p>
        </div>
        <button 
          onClick={handleAdd} 
          className="flex items-center gap-2 px-4 py-2.5 bg-primary text-on-primary rounded-xl shadow-sm text-sm font-medium hover:bg-primary/90 transition-all hover:shadow"
        >
          <Plus size={16} />
          Añadir Ambiente
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        
        <div className="p-5 bg-surface-container-lowest border border-surface-container-highest rounded-2xl shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-primary/10 text-primary flex items-center justify-center shrink-0">
            <Building size={24} />
          </div>
          <div>
            <div className="text-2xl font-bold text-on-surface">{totalAmbientes}</div>
            <div className="text-xs text-on-surface-variant font-medium">Ambientes Totales</div>
          </div>
        </div>

        <div className="p-5 bg-surface-container-lowest border border-surface-container-highest rounded-2xl shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-[#22c55e]/10 text-[#22c55e] flex items-center justify-center shrink-0">
            <Navigation size={24} />
          </div>
          <div>
            <div className="text-2xl font-bold text-on-surface">{conGps} / {totalAmbientes}</div>
            <div className="text-xs text-on-surface-variant font-medium">Georreferenciados (App Móvil)</div>
          </div>
        </div>

        <div className="p-5 bg-surface-container-lowest border border-surface-container-highest rounded-2xl shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-secondary/10 text-secondary flex items-center justify-center shrink-0">
            <Radio size={24} />
          </div>
          <div>
            <div className="text-2xl font-bold text-on-surface font-mono">~{totalAreaM2.toLocaleString()} m²</div>
            <div className="text-xs text-on-surface-variant font-medium">Área Total Cobertura Geocercas</div>
          </div>
        </div>

        <div className="p-5 bg-surface-container-lowest border border-surface-container-highest rounded-2xl shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-tertiary-container/30 text-tertiary flex items-center justify-center shrink-0">
            <Wifi size={24} />
          </div>
          <div>
            <div className="text-2xl font-bold text-on-surface">{conInternet} Online</div>
            <div className="text-xs text-on-surface-variant font-medium">Red WiFi Institucional</div>
          </div>
        </div>

      </div>

      {/* Main Table Container */}
      <div className="bg-surface-container-lowest border border-surface-container-highest rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-on-surface-variant flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
            <p className="text-sm font-medium">Cargando ambientes y geocercas...</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-bright border-b border-surface-container-highest text-xs uppercase tracking-wider text-on-surface-variant font-semibold">
                  <th className="p-4 pl-6">Código (CC)</th>
                  <th className="p-4">Ambiente</th>
                  <th className="p-4">Área / Ubicación Física</th>
                  <th className="p-4">Geolocalización GPS</th>
                  <th className="p-4">Radio & Área de Geocerca</th>
                  <th className="p-4">Conectividad</th>
                  <th className="p-4">Descripción</th>
                  <th className="p-4 pr-6 text-center w-24">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-highest">
                {ambientes.map(amb => {
                  const radius = parseFloat(amb.radio_geofence) || 0;
                  const areaM2 = radius > 0 ? Math.round(Math.PI * radius * radius) : 0;
                  const hasGps = amb.latitude !== null && amb.longitude !== null && amb.latitude !== undefined && amb.longitude !== undefined;

                  return (
                    <tr key={amb.id} className="hover:bg-surface-container-low/70 transition-colors">
                      
                      {/* Código CC */}
                      <td className="p-4 pl-6">
                        <span className="inline-flex items-center px-2.5 py-1 rounded-md bg-surface-container font-mono font-bold text-primary text-xs border border-outline-variant/60">
                          CC: {amb.codigo.toString().padStart(2, '0')}
                        </span>
                      </td>

                      {/* Nombre */}
                      <td className="p-4">
                        <div className="font-semibold text-on-surface text-sm flex items-center gap-1.5">
                          {amb.nombre}
                        </div>
                      </td>

                      {/* Área / Ubicación Física */}
                      <td className="p-4 text-on-surface text-sm">
                        {amb.ubicacion ? (
                          <div className="flex items-center gap-1.5 font-medium text-on-surface bg-surface-container-low px-2.5 py-1 rounded-lg border border-surface-container-highest w-fit">
                            <MapPin size={14} className="text-primary shrink-0" />
                            <span>{amb.ubicacion}</span>
                          </div>
                        ) : (
                          <span className="text-on-surface-variant text-xs italic">No especificada</span>
                        )}
                      </td>

                      {/* Geolocalización GPS */}
                      <td className="p-4">
                        {hasGps ? (
                          <div className="space-y-1">
                            <div className="font-mono text-xs text-on-surface font-medium flex items-center gap-1">
                              <Compass size={13} className="text-outline" />
                              <span>{parseFloat(amb.latitude).toFixed(6)}, {parseFloat(amb.longitude).toFixed(6)}</span>
                            </div>
                            <a 
                              href={`https://www.google.com/maps?q=${amb.latitude},${amb.longitude}`} 
                              target="_blank" 
                              rel="noreferrer"
                              className="inline-flex items-center gap-1 text-[11px] font-semibold text-primary hover:text-primary/80 transition-colors hover:underline"
                            >
                              <ExternalLink size={11} /> Abrir en Google Maps
                            </a>
                          </div>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] bg-surface-container text-on-surface-variant">
                            Sin GPS asignado
                          </span>
                        )}
                      </td>

                      {/* Radio & Área de Geocerca */}
                      <td className="p-4">
                        <div className="flex flex-col gap-0.5">
                          <span className="font-mono font-semibold text-xs text-on-surface flex items-center gap-1">
                            <Radio size={13} className="text-secondary" />
                            Radio: {radius} m
                          </span>
                          <span className="text-[11px] text-on-surface-variant font-medium">
                            Área: ~{areaM2.toLocaleString()} m²
                          </span>
                        </div>
                      </td>

                      {/* Conectividad */}
                      <td className="p-4 text-xs">
                        {amb.tiene_internet ? (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#22c55e]/10 text-[#22c55e] font-semibold text-xs">
                            <Wifi size={13} /> Online
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-surface-container text-on-surface-variant font-medium text-xs">
                            <WifiOff size={13} /> Offline
                          </span>
                        )}
                      </td>

                      {/* Descripción */}
                      <td className="p-4 text-on-surface-variant text-xs max-w-xs truncate">
                        {amb.descripcion || '-'}
                      </td>

                      {/* Acciones */}
                      <td className="p-4 pr-6 text-center space-x-1.5">
                        <button 
                          onClick={() => handleEdit(amb)} 
                          className="p-2 text-on-surface-variant hover:text-secondary hover:bg-secondary/10 rounded-lg transition-colors" 
                          title="Editar Ambiente y Geocerca"
                        >
                          <Edit2 size={16} />
                        </button>
                        <button 
                          onClick={() => handleDelete(amb.id)} 
                          className="p-2 text-on-surface-variant hover:text-error hover:bg-error/10 rounded-lg transition-colors" 
                          title="Eliminar"
                        >
                          <Trash2 size={16} />
                        </button>
                      </td>

                    </tr>
                  );
                })}

                {ambientes.length === 0 && (
                  <tr>
                    <td colSpan="8" className="p-12 text-center text-on-surface-variant">
                      <Building size={40} className="mx-auto mb-3 opacity-40" />
                      <p className="font-medium">No hay ambientes registrados.</p>
                      <button onClick={handleAdd} className="mt-3 text-xs text-primary font-semibold hover:underline">
                        Crear el primer ambiente ahora
                      </button>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <AmbienteFormModal 
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={fetchAmbientes}
        editData={editItem}
      />
    </div>
  );
};

export default AmbientesPage;
