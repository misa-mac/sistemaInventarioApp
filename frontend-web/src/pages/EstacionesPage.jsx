import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import QRPrintModal from '../components/QRPrintModal';
import { QRCodeSVG } from 'qrcode.react';
import { 
  LayoutGrid, Plus, Search, Filter, Printer, Eye, Edit2, Trash2, 
  Cpu, Monitor, Keyboard, Mouse, CheckCircle2, AlertCircle, X, 
  Building, RefreshCw, Link2, Unlink
} from 'lucide-react';

const EstacionesPage = () => {
  const { user } = useAuth();
  const isAdmin = user?.rol === 'admin';
  const canAssign = user?.rol === 'admin' || user?.rol === 'tecnico';

  const [estaciones, setEstaciones] = useState([]);
  const [ambientes, setAmbientes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedAmbiente, setSelectedAmbiente] = useState('');

  // Modales
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingStation, setEditingStation] = useState(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [selectedStation, setSelectedStation] = useState(null);
  const [isAssignOpen, setIsAssignOpen] = useState(false);
  const [isPrintOpen, setIsPrintOpen] = useState(false);
  const [stationToPrint, setStationToPrint] = useState(null);

  // Estados para formulario
  const [formData, setFormData] = useState({
    codigo_estacion: '',
    ambiente_id: '',
    descripcion: ''
  });
  const [formError, setFormError] = useState('');
  const [formLoading, setFormLoading] = useState(false);

  // Estados para asignación de activos
  const [allAssets, setAllAssets] = useState([]);
  const [selectedAssetIds, setSelectedAssetIds] = useState([]);
  const [assetSearch, setAssetSearch] = useState('');

  const fetchEstaciones = async () => {
    try {
      setLoading(true);
      const params = {};
      if (selectedAmbiente) params.ambiente_id = selectedAmbiente;
      if (search) params.q = search;
      const res = await api.get('/estaciones', { params });
      setEstaciones(res.data);
    } catch (err) {
      console.error('Error al cargar estaciones:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchAmbientes = async () => {
    try {
      const res = await api.get('/ambientes');
      setAmbientes(res.data);
    } catch (err) {
      console.error('Error al cargar ambientes:', err);
    }
  };

  const fetchAssetsForAssignment = async () => {
    try {
      const res = await api.get('/inventory');
      setAllAssets(res.data || []);
    } catch (err) {
      console.error('Error al cargar activos:', err);
    }
  };

  useEffect(() => {
    fetchAmbientes();
  }, []);

  useEffect(() => {
    fetchEstaciones();
  }, [selectedAmbiente, search]);

  const handleOpenCreate = () => {
    setEditingStation(null);
    setFormData({
      codigo_estacion: '',
      ambiente_id: ambientes[0]?.id || '',
      descripcion: ''
    });
    setFormError('');
    setIsFormOpen(true);
  };

  const handleOpenEdit = (station) => {
    setEditingStation(station);
    setFormData({
      codigo_estacion: station.codigo_estacion,
      ambiente_id: station.ambiente_id,
      descripcion: station.descripcion || ''
    });
    setFormError('');
    setIsFormOpen(true);
  };

  const handleSaveStation = async (e) => {
    e.preventDefault();
    if (!formData.codigo_estacion.trim()) {
      setFormError('El código de estación es requerido (ej. EST-LAB1-05)');
      return;
    }
    if (!formData.ambiente_id) {
      setFormError('Debe seleccionar un ambiente');
      return;
    }

    try {
      setFormLoading(true);
      setFormError('');
      if (editingStation) {
        await api.put(`/estaciones/${editingStation.id}`, formData);
      } else {
        await api.post('/estaciones', formData);
      }
      setIsFormOpen(false);
      fetchEstaciones();
    } catch (err) {
      setFormError(err.response?.data?.message || 'Error al guardar estación');
    } finally {
      setFormLoading(false);
    }
  };

  const handleDeleteStation = async (station) => {
    if (!window.confirm(`¿Está seguro de eliminar la estación ${station.codigo_estacion}? Los componentes asignados se desvincularán.`)) {
      return;
    }
    try {
      await api.delete(`/estaciones/${station.id}`);
      fetchEstaciones();
    } catch (err) {
      alert(err.response?.data?.message || 'Error al eliminar estación');
    }
  };

  const handleOpenAssign = async (station) => {
    setSelectedStation(station);
    setSelectedAssetIds((station.activos || []).map(a => a.id));
    await fetchAssetsForAssignment();
    setIsAssignOpen(true);
  };

  const handleToggleAsset = (assetId) => {
    if (selectedAssetIds.includes(assetId)) {
      setSelectedAssetIds(selectedAssetIds.filter(id => id !== assetId));
    } else {
      if (selectedAssetIds.length >= 4) {
        alert('Una estación de trabajo estándar consta de hasta 4 componentes (CPU, Monitor, Teclado, Mouse).');
      }
      setSelectedAssetIds([...selectedAssetIds, assetId]);
    }
  };

  const handleSaveAssignment = async () => {
    if (!selectedStation) return;
    try {
      await api.post(`/estaciones/${selectedStation.id}/asignar-activos`, {
        activo_ids: selectedAssetIds
      });
      setIsAssignOpen(false);
      fetchEstaciones();
    } catch (err) {
      alert(err.response?.data?.message || 'Error al asignar componentes');
    }
  };

  const handleOpenDetail = (station) => {
    setSelectedStation(station);
    setIsDetailOpen(true);
  };

  const handleOpenPrint = (station) => {
    setStationToPrint(station);
    setIsPrintOpen(true);
  };

  // Ayudante de icono por categoría
  const getComponentIcon = (name = '', typeName = '') => {
    const text = `${name} ${typeName}`.toLowerCase();
    if (text.includes('cpu') || text.includes('gabinete') || text.includes('torre') || text.includes('computadora')) {
      return <Cpu size={16} className="text-blue-500" />;
    }
    if (text.includes('monitor') || text.includes('pantalla')) {
      return <Monitor size={16} className="text-emerald-500" />;
    }
    if (text.includes('teclado') || text.includes('keyboard')) {
      return <Keyboard size={16} className="text-amber-500" />;
    }
    if (text.includes('mouse') || text.includes('raton')) {
      return <Mouse size={16} className="text-purple-500" />;
    }
    return <Cpu size={16} className="text-slate-500" />;
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-surface-container-highest pb-6">
        <div>
          <h1 className="text-2xl font-bold text-on-surface flex items-center gap-2.5">
            <LayoutGrid className="text-primary" size={28} />
            Estaciones de Trabajo (Mesas)
          </h1>
          <p className="text-sm text-on-surface-variant mt-1">
            Sistema Híbrido de QR: Administre mesas completas con su código QR general y sus 4 componentes asociados.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={fetchEstaciones}
            className="p-2.5 border border-outline-variant hover:bg-surface-container rounded-lg text-on-surface-variant transition-colors"
            title="Actualizar lista"
          >
            <RefreshCw size={18} />
          </button>

          {isAdmin && (
            <button
              onClick={handleOpenCreate}
              className="px-4 py-2.5 bg-primary text-on-primary rounded-lg shadow-sm font-semibold text-sm hover:bg-primary/90 transition-all flex items-center gap-2"
            >
              <Plus size={18} />
              Nueva Estación
            </button>
          )}
        </div>
      </div>

      {/* Filtros */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 bg-surface-container-low p-4 rounded-xl border border-surface-container-highest">
        {/* Búsqueda */}
        <div className="relative col-span-2">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-outline" size={18} />
          <input
            type="text"
            placeholder="Buscar por código (ej. EST-LAB1-05) o descripción..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary"
          />
        </div>

        {/* Filtro de Ambiente */}
        <div className="flex items-center gap-2">
          <Filter size={18} className="text-outline" />
          <select
            value={selectedAmbiente}
            onChange={(e) => setSelectedAmbiente(e.target.value)}
            className="w-full px-3 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary"
          >
            <option value="">Todos los Ambientes / Laboratorios</option>
            {ambientes.map((amb) => (
              <option key={amb.id} value={amb.id}>
                {amb.nombre} ({amb.ubicacion || 'Sin ubicación'})
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Grid de Estaciones */}
      {loading ? (
        <div className="p-12 text-center text-on-surface-variant">
          <RefreshCw className="animate-spin mx-auto mb-2 text-primary" size={24} />
          Cargando estaciones de trabajo...
        </div>
      ) : estaciones.length === 0 ? (
        <div className="p-12 text-center bg-surface-container-lowest border border-dashed border-outline-variant rounded-2xl">
          <LayoutGrid className="mx-auto text-outline mb-3" size={48} />
          <h3 className="text-lg font-bold text-on-surface">No se encontraron estaciones</h3>
          <p className="text-sm text-on-surface-variant mt-1 max-w-md mx-auto">
            {search || selectedAmbiente 
              ? 'No hay estaciones que coincidan con los filtros aplicados.' 
              : 'Comience creando la primera estación de trabajo para vincular CPU, monitor, teclado y mouse.'}
          </p>
          {isAdmin && !search && !selectedAmbiente && (
            <button
              onClick={handleOpenCreate}
              className="mt-4 px-4 py-2 bg-primary text-on-primary rounded-lg text-sm font-semibold hover:bg-primary/90"
            >
              Crear Estación
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {estaciones.map((est) => {
            const count = (est.activos || []).length;
            const isFull = count >= 4;
            return (
              <div 
                key={est.id}
                className="bg-surface-container-lowest border border-surface-container-highest hover:border-primary/50 transition-all rounded-2xl shadow-sm overflow-hidden flex flex-col"
              >
                {/* Cabecera de la Tarjeta */}
                <div className="p-5 border-b border-surface-container-highest flex justify-between items-start bg-surface-container-low/50">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-bold text-base text-primary bg-primary/10 px-2.5 py-0.5 rounded-md border border-primary/20">
                        {est.codigo_estacion}
                      </span>
                      <span className={`text-[11px] font-bold px-2 py-0.5 rounded-full ${
                        isFull ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                      }`}>
                        {count}/4 Componentes
                      </span>
                    </div>
                    <div className="text-xs text-on-surface-variant flex items-center gap-1.5 mt-1 font-medium">
                      <Building size={14} className="text-outline" />
                      {est.ambiente?.nombre || 'Ambiente no asignado'}
                    </div>
                  </div>

                  {/* QR Miniatura */}
                  <div 
                    onClick={() => handleOpenPrint(est)}
                    className="p-1.5 bg-white border border-outline-variant rounded-lg cursor-pointer hover:shadow-md transition-shadow"
                    title="Clic para imprimir etiqueta QR"
                  >
                    <QRCodeSVG value={est.codigo_estacion} size={46} level="M" />
                  </div>
                </div>

                {/* Contenido / Descripción */}
                <div className="p-5 flex-1 space-y-4">
                  {est.descripcion && (
                    <p className="text-xs text-on-surface-variant line-clamp-2">
                      {est.descripcion}
                    </p>
                  )}

                  {/* Lista de Componentes Vinculados */}
                  <div className="space-y-2">
                    <div className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant flex justify-between">
                      <span>Componentes Vinculados</span>
                      {canAssign && (
                        <button
                          onClick={() => handleOpenAssign(est)}
                          className="text-primary hover:underline text-[11px] font-semibold flex items-center gap-1"
                        >
                          <Link2 size={12} />
                          Gestionar
                        </button>
                      )}
                    </div>

                    <div className="grid grid-cols-1 gap-1.5">
                      {(est.activos || []).slice(0, 4).map((activo) => (
                        <div 
                          key={activo.id}
                          className="flex items-center justify-between p-2 rounded-lg bg-surface-container-low border border-surface-container-highest text-xs"
                        >
                          <div className="flex items-center gap-2 min-w-0">
                            {getComponentIcon(activo.nombre, activo.tipo?.nombre)}
                            <div className="truncate">
                              <span className="font-semibold text-on-surface truncate block">
                                {activo.nombre}
                              </span>
                              <span className="text-[10px] text-on-surface-variant font-mono">
                                {activo.codigo_activo} • {activo.marca || 'S/M'}
                              </span>
                            </div>
                          </div>
                          <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
                            activo.estado === 'Activo' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'
                          }`}>
                            {activo.estado}
                          </span>
                        </div>
                      ))}

                      {count === 0 && (
                        <div className="p-3 text-center rounded-lg border border-dashed border-outline-variant text-on-surface-variant text-xs">
                          Sin componentes asignados
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Acciones */}
                <div className="p-3 bg-surface-container-low/70 border-t border-surface-container-highest flex items-center justify-between gap-1">
                  <button
                    onClick={() => handleOpenDetail(est)}
                    className="p-2 hover:bg-surface-container rounded-lg text-on-surface-variant hover:text-primary transition-colors flex items-center gap-1.5 text-xs font-medium"
                    title="Ver detalles completos de la estación"
                  >
                    <Eye size={16} />
                    Detalle
                  </button>

                  <button
                    onClick={() => handleOpenPrint(est)}
                    className="p-2 hover:bg-surface-container rounded-lg text-on-surface-variant hover:text-emerald-600 transition-colors flex items-center gap-1.5 text-xs font-medium"
                    title="Imprimir etiquetas QR (General e Individuales)"
                  >
                    <Printer size={16} />
                    Etiquetas
                  </button>

                  {isAdmin && (
                    <button
                      onClick={() => handleOpenEdit(est)}
                      className="p-2 hover:bg-surface-container rounded-lg text-on-surface-variant hover:text-amber-600 transition-colors"
                      title="Editar información de la estación"
                    >
                      <Edit2 size={16} />
                    </button>
                  )}

                  {isAdmin && (
                    <button
                      onClick={() => handleDeleteStation(est)}
                      className="p-2 hover:bg-error-container hover:text-on-error-container rounded-lg text-on-surface-variant transition-colors"
                      title="Eliminar estación"
                    >
                      <Trash2 size={16} />
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal Crear / Editar Estación */}
      {isFormOpen && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 animate-fade-in">
          <div className="bg-surface-container-lowest rounded-2xl shadow-2xl w-full max-w-lg border border-surface-container-highest overflow-hidden">
            <div className="flex justify-between items-center p-5 border-b border-surface-container-highest">
              <h2 className="text-lg font-bold text-on-surface flex items-center gap-2">
                <LayoutGrid className="text-primary" size={20} />
                {editingStation ? 'Editar Estación de Trabajo' : 'Nueva Estación de Trabajo'}
              </h2>
              <button 
                onClick={() => setIsFormOpen(false)}
                className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSaveStation} className="p-6 space-y-4">
              {formError && (
                <div className="p-3 rounded-lg bg-error-container text-on-error-container text-xs flex items-center gap-2">
                  <AlertCircle size={16} />
                  {formError}
                </div>
              )}

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1">
                  Código de Estación * (Formato General)
                </label>
                <input
                  type="text"
                  placeholder="ej. EST-LAB1-05"
                  value={formData.codigo_estacion}
                  onChange={(e) => setFormData({ ...formData, codigo_estacion: e.target.value.toUpperCase() })}
                  className="w-full px-3 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface font-mono font-bold focus:outline-none focus:border-primary"
                  required
                />
                <span className="text-[11px] text-on-surface-variant mt-1 block">
                  Identificador único que se codifica en el QR General de la mesa.
                </span>
              </div>

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1">
                  Ambiente / Laboratorio *
                </label>
                <select
                  value={formData.ambiente_id}
                  onChange={(e) => setFormData({ ...formData, ambiente_id: e.target.value })}
                  className="w-full px-3 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary"
                  required
                >
                  <option value="">Seleccione un ambiente...</option>
                  {ambientes.map((amb) => (
                    <option key={amb.id} value={amb.id}>
                      {amb.nombre} - {amb.ubicacion || 'Sin ubicación'}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-on-surface-variant uppercase mb-1">
                  Descripción / Observaciones
                </label>
                <textarea
                  rows="3"
                  placeholder="ej. Mesa 5 fila central para estudiantes de Redes..."
                  value={formData.descripcion}
                  onChange={(e) => setFormData({ ...formData, descripcion: e.target.value })}
                  className="w-full px-3 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg text-sm text-on-surface focus:outline-none focus:border-primary"
                />
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-surface-container-highest">
                <button
                  type="button"
                  onClick={() => setIsFormOpen(false)}
                  className="px-4 py-2 border border-outline-variant rounded-lg text-sm font-semibold text-on-surface-variant hover:bg-surface-container"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={formLoading}
                  className="px-5 py-2 bg-primary text-on-primary rounded-lg text-sm font-semibold hover:bg-primary/90 disabled:opacity-50"
                >
                  {formLoading ? 'Guardando...' : editingStation ? 'Actualizar Estación' : 'Crear Estación'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Ficha Técnica y Detalles de Estación */}
      {isDetailOpen && selectedStation && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 animate-fade-in">
          <div className="bg-surface-container-lowest rounded-2xl shadow-2xl w-full max-w-2xl border border-surface-container-highest overflow-hidden max-h-[90vh] flex flex-col">
            {/* Header */}
            <div className="p-5 border-b border-surface-container-highest flex justify-between items-center bg-surface-container-low">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-primary/10 rounded-xl text-primary border border-primary/20">
                  <LayoutGrid size={22} />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-on-surface font-mono">
                    {selectedStation.codigo_estacion}
                  </h2>
                  <p className="text-xs text-on-surface-variant">
                    {selectedStation.ambiente?.nombre} • {selectedStation.ambiente?.ubicacion || 'Sin ubicación'}
                  </p>
                </div>
              </div>
              <button 
                onClick={() => setIsDetailOpen(false)}
                className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full"
              >
                <X size={20} />
              </button>
            </div>

            {/* Body */}
            <div className="p-6 overflow-y-auto space-y-6 flex-1">
              {/* Tarjeta Banner con QR General */}
              <div className="bg-surface-container-low p-5 rounded-xl border border-surface-container-highest flex flex-col sm:flex-row items-center gap-6">
                <div className="p-3 bg-white border border-outline-variant rounded-xl shadow-xs shrink-0">
                  <QRCodeSVG value={selectedStation.codigo_estacion} size={110} level="M" />
                </div>
                <div className="space-y-2 text-center sm:text-left flex-1">
                  <div className="inline-block px-2.5 py-0.5 rounded-full text-xs font-bold bg-primary/10 text-primary border border-primary/20">
                    QR General de Estación
                  </div>
                  <h3 className="font-mono text-xl font-bold text-on-surface">
                    {selectedStation.codigo_estacion}
                  </h3>
                  <p className="text-xs text-on-surface-variant">
                    {selectedStation.descripcion || 'Mesa de laboratorio estándar asignada para prácticas técnicas.'}
                  </p>
                  <div className="text-[11px] text-on-surface-variant font-semibold">
                    Total Componentes Vinculados: {(selectedStation.activos || []).length} / 4
                  </div>
                </div>
              </div>

              {/* Lista Detallada de los 4 Componentes */}
              <div className="space-y-3">
                <h4 className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">
                  Componentes Asignados a la Mesa
                </h4>

                <div className="space-y-2">
                  {(selectedStation.activos || []).map((activo) => (
                    <div 
                      key={activo.id}
                      className="p-3 bg-surface-container-low border border-surface-container-highest rounded-xl flex items-center justify-between gap-4"
                    >
                      <div className="flex items-center gap-3">
                        <div className="p-2 bg-surface-container rounded-lg">
                          {getComponentIcon(activo.nombre, activo.tipo?.nombre)}
                        </div>
                        <div>
                          <div className="text-sm font-semibold text-on-surface">
                            {activo.nombre}
                          </div>
                          <div className="text-xs text-on-surface-variant font-mono">
                            Código: <span className="font-bold text-on-surface">{activo.codigo_activo}</span> • Marca: {activo.marca || 'N/A'} {activo.modelo ? `(${activo.modelo})` : ''}
                          </div>
                          {activo.numero_serie && (
                            <div className="text-[11px] text-on-surface-variant">
                              N° Serie: {activo.numero_serie}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="text-right">
                        <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${
                          activo.estado === 'Activo' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'
                        }`}>
                          {activo.estado}
                        </span>
                      </div>
                    </div>
                  ))}

                  {(selectedStation.activos || []).length === 0 && (
                    <div className="p-6 text-center border border-dashed border-outline-variant rounded-xl text-on-surface-variant text-xs">
                      Esta estación aún no tiene componentes vinculados.
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="p-4 bg-surface-container-low border-t border-surface-container-highest flex justify-between items-center">
              <button
                onClick={() => {
                  setIsDetailOpen(false);
                  handleOpenPrint(selectedStation);
                }}
                className="px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm font-semibold hover:bg-emerald-700 flex items-center gap-2"
              >
                <Printer size={16} />
                Imprimir Etiquetas QR
              </button>

              <button
                onClick={() => setIsDetailOpen(false)}
                className="px-4 py-2 border border-outline-variant rounded-lg text-sm font-semibold text-on-surface-variant hover:bg-surface-container"
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Asignar Componentes */}
      {isAssignOpen && selectedStation && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 animate-fade-in">
          <div className="bg-surface-container-lowest rounded-2xl shadow-2xl w-full max-w-2xl border border-surface-container-highest overflow-hidden max-h-[90vh] flex flex-col">
            <div className="p-5 border-b border-surface-container-highest flex justify-between items-center bg-surface-container-low">
              <div>
                <h2 className="text-lg font-bold text-on-surface flex items-center gap-2">
                  <Link2 className="text-primary" size={20} />
                  Asignar Componentes a {selectedStation.codigo_estacion}
                </h2>
                <p className="text-xs text-on-surface-variant">
                  Seleccione los componentes de inventario (CPU, Monitor, Teclado, Mouse) vinculados a esta mesa.
                </p>
              </div>
              <button 
                onClick={() => setIsAssignOpen(false)}
                className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full"
              >
                <X size={20} />
              </button>
            </div>

            {/* Search within available assets */}
            <div className="p-4 border-b border-surface-container-highest bg-surface-container-low/50">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-outline" size={16} />
                <input
                  type="text"
                  placeholder="Filtrar por código, nombre o tipo de activo..."
                  value={assetSearch}
                  onChange={(e) => setAssetSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 bg-surface-container-lowest border border-outline-variant rounded-lg text-xs text-on-surface focus:outline-none focus:border-primary"
                />
              </div>
            </div>

            {/* List */}
            <div className="p-4 overflow-y-auto space-y-2 flex-1">
              <div className="flex justify-between items-center text-xs font-bold text-on-surface-variant px-1 mb-2">
                <span>Activos Disponibles</span>
                <span>Seleccionados: {selectedAssetIds.length} / 4</span>
              </div>

              {allAssets
                .filter(asset => {
                  const matchSearch = !assetSearch || 
                    (asset.codigo_activo && asset.codigo_activo.toLowerCase().includes(assetSearch.toLowerCase())) ||
                    (asset.nombre && asset.nombre.toLowerCase().includes(assetSearch.toLowerCase())) ||
                    (asset.marca && asset.marca.toLowerCase().includes(assetSearch.toLowerCase()));
                  // Mostrar activos no asignados o asignados a esta misma estación
                  const matchStation = !asset.estacion_id || asset.estacion_id === selectedStation.id;
                  return matchSearch && matchStation;
                })
                .map((asset) => {
                  const isSelected = selectedAssetIds.includes(asset.id);
                  return (
                    <div
                      key={asset.id}
                      onClick={() => handleToggleAsset(asset.id)}
                      className={`p-3 rounded-xl border transition-all cursor-pointer flex items-center justify-between ${
                        isSelected 
                          ? 'bg-primary/10 border-primary text-on-surface' 
                          : 'bg-surface-container-low border-surface-container-highest text-on-surface hover:border-outline'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-5 h-5 rounded flex items-center justify-center border ${
                          isSelected ? 'bg-primary border-primary text-white' : 'border-outline-variant bg-surface-container-lowest'
                        }`}>
                          {isSelected && <CheckCircle2 size={14} />}
                        </div>
                        <div>
                          <div className="text-xs font-bold flex items-center gap-2">
                            {asset.nombre}
                            <span className="font-mono text-[11px] text-primary bg-primary/10 px-1.5 py-0.2 rounded">
                              {asset.codigo_activo}
                            </span>
                          </div>
                          <div className="text-[11px] text-on-surface-variant">
                            {asset.marca} {asset.modelo ? `• ${asset.modelo}` : ''} • Ambiente: {asset.ambiente?.nombre || 'General'}
                          </div>
                        </div>
                      </div>

                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                        asset.estado === 'Activo' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'
                      }`}>
                        {asset.estado}
                      </span>
                    </div>
                  );
                })}
            </div>

            {/* Footer */}
            <div className="p-4 bg-surface-container-low border-t border-surface-container-highest flex justify-between items-center">
              <span className="text-xs text-on-surface-variant">
                {selectedAssetIds.length} componente(s) asignados a {selectedStation.codigo_estacion}
              </span>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setIsAssignOpen(false)}
                  className="px-4 py-2 border border-outline-variant rounded-lg text-sm font-semibold text-on-surface-variant hover:bg-surface-container"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  onClick={handleSaveAssignment}
                  className="px-5 py-2 bg-primary text-on-primary rounded-lg text-sm font-semibold hover:bg-primary/90"
                >
                  Guardar Asignación
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal Impresión de QR Híbrido */}
      {isPrintOpen && stationToPrint && (
        <QRPrintModal
          isOpen={isPrintOpen}
          onClose={() => {
            setIsPrintOpen(false);
            setStationToPrint(null);
          }}
          stationToPrint={stationToPrint}
        />
      )}
    </div>
  );
};

export default EstacionesPage;

