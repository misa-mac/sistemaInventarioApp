import React, { useState, useEffect } from 'react';
import { 
  CheckCircle2, 
  XCircle, 
  Clock, 
  AlertTriangle, 
  QrCode, 
  Printer, 
  Eye, 
  Filter, 
  Search, 
  ArrowRight, 
  User, 
  Calendar, 
  Layers, 
  ShieldAlert, 
  Check, 
  X,
  FileQuestion,
  HelpCircle
} from 'lucide-react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import QRPrintModal from '../components/QRPrintModal';

const SolicitudesPage = () => {
  const { user } = useAuth();
  const [solicitudes, setSolicitudes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Filtros
  const [filtroEstado, setFiltroEstado] = useState('pendiente');
  const [filtroTipo, setFiltroTipo] = useState('todos');
  const [busqueda, setBusqueda] = useState('');

  // Modal de Detalle
  const [selectedSolicitud, setSelectedSolicitud] = useState(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);

  // Acciones: Aprobar y Rechazar
  const [isAprobarModalOpen, setIsAprobarModalOpen] = useState(false);
  const [isRechazarModalOpen, setIsRechazarModalOpen] = useState(false);
  const [comentarioRechazo, setComentarioRechazo] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState(null);

  // Modal de éxito post-aprobación de alta (para ofrecer imprimir QR)
  const [altaAprobadaInfo, setAltaAprobadaInfo] = useState(null);
  const [showQRModal, setShowQRModal] = useState(false);
  const [qrAssets, setQrAssets] = useState([]);

  useEffect(() => {
    fetchSolicitudes();
  }, [filtroEstado, filtroTipo]);

  const fetchSolicitudes = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = {};
      if (filtroEstado !== 'todas') params.estado = filtroEstado;
      if (filtroTipo !== 'todos') params.tipo = filtroTipo;

      const res = await api.get('/solicitudes', { params });
      setSolicitudes(res.data.data || []);
    } catch (err) {
      console.error('Error al cargar solicitudes:', err);
      setError('No se pudieron cargar las solicitudes de cambio.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDetail = (sol) => {
    setSelectedSolicitud(sol);
    setIsDetailOpen(true);
    setActionError(null);
  };

  const handleConfirmAprobar = async () => {
    if (!selectedSolicitud) return;
    setActionLoading(true);
    setActionError(null);

    try {
      const res = await api.post(`/solicitudes/${selectedSolicitud.id}/aprobar`);
      const { solicitud, activo } = res.data;

      setIsAprobarModalOpen(false);
      setIsDetailOpen(false);
      fetchSolicitudes();

      // Si fue un alta, ofrecemos generar e imprimir el QR de inmediato
      if (solicitud.tipo === 'alta' && (activo || solicitud.activo_resultante)) {
        const activoFinal = activo || solicitud.activo_resultante;
        setAltaAprobadaInfo({
          codigo: activoFinal.codigo_activo,
          activo: activoFinal
        });
      }
    } catch (err) {
      console.error('Error al aprobar solicitud:', err);
      setActionError(err.response?.data?.message || 'Error al aprobar la solicitud.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleConfirmRechazar = async () => {
    if (!selectedSolicitud) return;
    if (!comentarioRechazo.trim()) {
      setActionError('El motivo o comentario de rechazo es estrictamente obligatorio.');
      return;
    }

    setActionLoading(true);
    setActionError(null);

    try {
      await api.post(`/solicitudes/${selectedSolicitud.id}/rechazar`, {
        comentario: comentarioRechazo.trim()
      });

      setIsRechazarModalOpen(false);
      setComentarioRechazo('');
      setIsDetailOpen(false);
      fetchSolicitudes();
    } catch (err) {
      console.error('Error al rechazar solicitud:', err);
      setActionError(err.response?.data?.message || 'Error al rechazar la solicitud.');
    } finally {
      setActionLoading(false);
    }
  };

  const solicitudesFiltradas = solicitudes.filter(s => {
    if (!busqueda.trim()) return true;
    const term = busqueda.toLowerCase();
    const nombre = s.datos?.nombre || s.activo?.nombre || '';
    const solicitante = s.solicitante?.nombre_completo || s.solicitante?.email || '';
    const codigo = s.activo?.codigo_activo || s.activo_resultante?.codigo_activo || '';
    return nombre.toLowerCase().includes(term) ||
           solicitante.toLowerCase().includes(term) ||
           codigo.toLowerCase().includes(term);
  });

  const getTipoBadge = (tipo) => {
    switch (tipo) {
      case 'alta':
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800 border border-emerald-300">Alta</span>;
      case 'edicion':
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 border border-amber-300">Edición</span>;
      case 'baja':
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-100 text-rose-800 border border-rose-300">Baja</span>;
      default:
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-surface-container text-on-surface">{tipo}</span>;
    }
  };

  const getEstadoBadge = (estado) => {
    switch (estado) {
      case 'pendiente':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-50 text-amber-700 border border-amber-200">
            <Clock size={12} className="animate-spin" /> Pendiente
          </span>
        );
      case 'aprobada':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 size={12} /> Aprobada
          </span>
        );
      case 'rechazada':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-rose-50 text-rose-700 border border-rose-200">
            <XCircle size={12} /> Rechazada
          </span>
        );
      default:
        return <span>{estado}</span>;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-surface-container-lowest p-6 rounded-xl border border-surface-container-highest shadow-sm">
        <div>
          <h1 className="text-2xl font-bold text-on-surface tracking-tight flex items-center gap-2">
            <Layers className="text-primary" size={24} /> Solicitudes de Cambio
          </h1>
          <p className="text-sm text-on-surface-variant mt-1">
            Gobernanza central: los técnicos proponen cambios desde el móvil y la web los confirma como única autoridad.
          </p>
        </div>
      </div>

      {/* Filtros y Búsqueda */}
      <div className="bg-surface-container-lowest p-4 rounded-xl border border-surface-container-highest shadow-sm flex flex-col md:flex-row gap-4 justify-between items-center">
        <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
          {/* Filtro Estado */}
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold text-on-surface-variant uppercase tracking-wider">Estado:</span>
            <select
              value={filtroEstado}
              onChange={(e) => setFiltroEstado(e.target.value)}
              className="px-3 py-1.5 text-sm bg-surface rounded-lg border border-surface-container-highest text-on-surface focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="pendiente">Pendientes</option>
              <option value="aprobada">Aprobadas</option>
              <option value="rechazada">Rechazadas</option>
              <option value="todas">Todas</option>
            </select>
          </div>

          {/* Filtro Tipo */}
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold text-on-surface-variant uppercase tracking-wider">Tipo:</span>
            <select
              value={filtroTipo}
              onChange={(e) => setFiltroTipo(e.target.value)}
              className="px-3 py-1.5 text-sm bg-surface rounded-lg border border-surface-container-highest text-on-surface focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="todos">Todos</option>
              <option value="alta">Altas</option>
              <option value="edicion">Ediciones</option>
              <option value="baja">Bajas</option>
            </select>
          </div>
        </div>

        {/* Buscador */}
        <div className="relative w-full md:w-72">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-outline" />
          <input
            type="text"
            placeholder="Buscar por activo o técnico..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 text-sm bg-surface rounded-lg border border-surface-container-highest text-on-surface placeholder:text-outline focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>
      </div>

      {/* Lista / Tabla de Solicitudes */}
      <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-on-surface-variant">
            <Clock size={32} className="mx-auto mb-3 animate-spin text-primary" />
            <p className="text-sm">Cargando solicitudes...</p>
          </div>
        ) : error ? (
          <div className="p-8 text-center text-error">
            <AlertTriangle size={32} className="mx-auto mb-2" />
            <p className="text-sm font-medium">{error}</p>
          </div>
        ) : solicitudesFiltradas.length === 0 ? (
          <div className="p-12 text-center text-on-surface-variant">
            <CheckCircle2 size={36} className="mx-auto mb-2 text-outline" />
            <p className="text-sm font-medium">No se encontraron solicitudes con los filtros aplicados.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-surface-container-low text-on-surface-variant border-b border-surface-container-highest uppercase text-[11px] font-semibold tracking-wider">
                <tr>
                  <th className="px-6 py-3">Tipo</th>
                  <th className="px-6 py-3">Activo / Detalle</th>
                  <th className="px-6 py-3">Solicitante</th>
                  <th className="px-6 py-3">Fecha</th>
                  <th className="px-6 py-3">Estado</th>
                  <th className="px-6 py-3 text-right">Acción</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-highest">
                {solicitudesFiltradas.map((sol) => {
                  const nombreActivo = sol.tipo === 'alta' 
                    ? sol.datos?.nombre 
                    : (sol.activo?.nombre || sol.datos?.nombre || 'Activo s/n');
                  const codigoActivo = sol.activo?.codigo_activo || sol.activo_resultante?.codigo_activo || null;

                  return (
                    <tr key={sol.id} className="hover:bg-surface-container-low/50 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap">
                        {getTipoBadge(sol.tipo)}
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-medium text-on-surface">{nombreActivo}</div>
                        {codigoActivo && (
                          <div className="text-xs font-mono text-primary font-semibold mt-0.5">
                            {codigoActivo}
                          </div>
                        )}
                        {sol.tipo === 'baja' && sol.motivo && (
                          <div className="text-xs text-rose-600 mt-1 italic line-clamp-1">
                            Motivo: {sol.motivo}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-on-surface font-medium">{sol.solicitante?.nombre_completo || 'Técnico'}</div>
                        <div className="text-xs text-on-surface-variant">{sol.solicitante?.email}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-xs text-on-surface-variant">
                        {new Date(sol.created_at).toLocaleDateString('es-ES', {
                          day: '2-digit',
                          month: 'short',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {getEstadoBadge(sol.estado)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right">
                        <button
                          onClick={() => handleOpenDetail(sol)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg bg-surface-container border border-surface-container-highest text-primary hover:bg-primary-container transition-colors"
                        >
                          <Eye size={14} /> Revisar
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* MODAL DE DETALLE Y RESOLUCIÓN */}
      {isDetailOpen && selectedSolicitud && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center z-50 p-4 overflow-y-auto">
          <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest shadow-xl w-full max-w-3xl max-h-[90vh] flex flex-col my-auto">
            {/* Header Modal */}
            <div className="p-5 border-b border-surface-container-highest flex justify-between items-center bg-surface-container-low/50">
              <div className="flex items-center gap-3">
                {getTipoBadge(selectedSolicitud.tipo)}
                <h2 className="text-lg font-bold text-on-surface">
                  Detalle de Solicitud ({selectedSolicitud.tipo.toUpperCase()})
                </h2>
              </div>
              <button
                onClick={() => setIsDetailOpen(false)}
                className="text-on-surface-variant hover:text-on-surface p-1 rounded-lg hover:bg-surface-container"
              >
                <X size={20} />
              </button>
            </div>

            {/* Body */}
            <div className="p-6 overflow-y-auto space-y-6">
              {/* Metadatos de la solicitud */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 p-4 rounded-xl bg-surface-container-low border border-surface-container-highest text-xs">
                <div>
                  <span className="text-on-surface-variant block font-medium">Solicitante:</span>
                  <span className="font-semibold text-on-surface">{selectedSolicitud.solicitante?.nombre_completo}</span>
                  <span className="text-on-surface-variant block">{selectedSolicitud.solicitante?.email}</span>
                </div>
                <div>
                  <span className="text-on-surface-variant block font-medium">Fecha de Envío:</span>
                  <span className="font-semibold text-on-surface">
                    {new Date(selectedSolicitud.created_at).toLocaleString('es-ES')}
                  </span>
                </div>
                <div>
                  <span className="text-on-surface-variant block font-medium">Estado:</span>
                  <div className="mt-1">{getEstadoBadge(selectedSolicitud.estado)}</div>
                </div>
              </div>

              {/* CONTENIDO SEGÚN TIPO */}
              {/* 1. ALTA */}
              {selectedSolicitud.tipo === 'alta' && (
                <div className="space-y-4">
                  <div className="p-4 rounded-xl bg-primary-container/20 border border-primary/30 flex items-start gap-3 text-xs text-primary font-medium">
                    <ShieldAlert size={18} className="shrink-0 mt-0.5" />
                    <div>
                      <p className="font-semibold">Regla de autoridad del inventario:</p>
                      <p className="mt-0.5">El código oficial de inventario XYZAACC-GG y su respectivo código QR serán generados exclusivamente por la base de datos al confirmar la aprobación.</p>
                    </div>
                  </div>

                  <div className="border border-surface-container-highest rounded-xl p-4 bg-surface-container-lowest">
                    <h3 className="text-sm font-bold text-on-surface mb-3">Datos Propuestos para el Nuevo Activo</h3>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-3 text-xs">
                      <div>
                        <span className="text-on-surface-variant block">Nombre:</span>
                        <span className="font-semibold text-on-surface text-sm">{selectedSolicitud.datos?.nombre || '-'}</span>
                      </div>
                      <div>
                        <span className="text-on-surface-variant block">Marca y Modelo:</span>
                        <span className="font-semibold text-on-surface">{selectedSolicitud.datos?.marca || '-'} / {selectedSolicitud.datos?.modelo || '-'}</span>
                      </div>
                      <div>
                        <span className="text-on-surface-variant block">Número de Serie:</span>
                        <span className="font-mono text-on-surface">{selectedSolicitud.datos?.numero_serie || 'S/N'}</span>
                      </div>
                      <div>
                        <span className="text-on-surface-variant block">Origen:</span>
                        <span className="text-on-surface">{selectedSolicitud.datos?.origen || 'No especificado'}</span>
                      </div>
                      <div>
                        <span className="text-on-surface-variant block">Responsable:</span>
                        <span className="text-on-surface">{selectedSolicitud.datos?.responsable || 'No asignado'}</span>
                      </div>
                      <div>
                        <span className="text-on-surface-variant block">Valor (Bs.):</span>
                        <span className="text-on-surface font-semibold">{selectedSolicitud.datos?.valor || '0.00'}</span>
                      </div>
                      <div className="sm:col-span-2">
                        <span className="text-on-surface-variant block">Descripción:</span>
                        <span className="text-on-surface">{selectedSolicitud.datos?.descripcion || 'Sin descripción'}</span>
                      </div>
                    </div>
                  </div>

                  {selectedSolicitud.estado === 'aprobada' && selectedSolicitud.activo_resultante && (
                    <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 flex items-center justify-between">
                      <div>
                        <span className="text-xs text-emerald-700 block font-medium">Activo Creado y Confirmado:</span>
                        <span className="text-lg font-mono font-bold text-emerald-900">
                          {selectedSolicitud.activo_resultante.codigo_activo}
                        </span>
                      </div>
                      <button
                        onClick={() => {
                          setQrAssets([selectedSolicitud.activo_resultante]);
                          setShowQRModal(true);
                        }}
                        className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg text-xs font-semibold hover:bg-emerald-700 transition-colors shadow-sm"
                      >
                        <Printer size={16} /> Imprimir QR
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* 2. EDICIÓN: TABLA ANTES Y DESPUÉS CAMPO A CAMPO */}
              {selectedSolicitud.tipo === 'edicion' && (
                <div className="space-y-4">
                  <div className="p-3 rounded-lg bg-surface-container-low border border-surface-container-highest text-xs text-on-surface-variant">
                    <p className="font-semibold text-on-surface">Comparación de Cambios Propuestos</p>
                    <p className="text-[11px] mt-0.5">El código de activo, tipo y ambiente de registro son inmutables por integridad histórica. Los traslados de ambiente se realizan exclusivamente en el módulo de Movimientos.</p>
                  </div>

                  <div className="border border-surface-container-highest rounded-xl overflow-hidden">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-surface-container-low text-on-surface-variant uppercase text-[10px] font-semibold border-b border-surface-container-highest">
                        <tr>
                          <th className="px-4 py-2.5">Campo</th>
                          <th className="px-4 py-2.5">Valor Actual (en Base de Datos)</th>
                          <th className="px-4 py-2.5">Valor Propuesto</th>
                          <th className="px-4 py-2.5 text-center">Estado</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-surface-container-highest">
                        {[
                          { key: 'nombre', label: 'Nombre' },
                          { key: 'marca', label: 'Marca' },
                          { key: 'modelo', label: 'Modelo' },
                          { key: 'numero_serie', label: 'Número de Serie' },
                          { key: 'origen', label: 'Origen' },
                          { key: 'especificacion_origen', label: 'Especif. Origen' },
                          { key: 'descripcion', label: 'Descripción' },
                          { key: 'responsable', label: 'Responsable' },
                          { key: 'valor', label: 'Valor' },
                          { key: 'estado', label: 'Estado del Activo' },
                          { key: 'observaciones', label: 'Observaciones' }
                        ].map(({ key, label }) => {
                          const actual = selectedSolicitud.activo ? String(selectedSolicitud.activo[key] ?? '') : '';
                          const propuesto = selectedSolicitud.datos && selectedSolicitud.datos[key] !== undefined 
                            ? String(selectedSolicitud.datos[key] ?? '') 
                            : actual;
                          const haCambiado = actual !== propuesto;

                          return (
                            <tr key={key} className={haCambiado ? 'bg-amber-50/60 font-medium' : 'hover:bg-surface-container-low/30'}>
                              <td className="px-4 py-2 font-semibold text-on-surface">{label}</td>
                              <td className="px-4 py-2 text-on-surface-variant line-clamp-2">{actual || <span className="italic text-outline">vacío</span>}</td>
                              <td className="px-4 py-2 text-on-surface font-medium">{propuesto || <span className="italic text-outline">vacío</span>}</td>
                              <td className="px-4 py-2 text-center">
                                {haCambiado ? (
                                  <span className="inline-flex px-2 py-0.5 rounded text-[10px] font-bold bg-amber-200 text-amber-900">
                                    Modificado
                                  </span>
                                ) : (
                                  <span className="text-[10px] text-outline">Sin cambio</span>
                                )}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* 3. BAJA */}
              {selectedSolicitud.tipo === 'baja' && (
                <div className="space-y-4">
                  <div className="p-4 rounded-xl bg-rose-50 border border-rose-200">
                    <span className="text-xs font-bold uppercase tracking-wider text-rose-800 block mb-1">
                      Motivo Obligatorio de Baja:
                    </span>
                    <p className="text-sm font-medium text-rose-950 bg-white/80 p-3 rounded-lg border border-rose-200">
                      "{selectedSolicitud.motivo || 'No especificado'}"
                    </p>
                  </div>

                  {selectedSolicitud.activo && (
                    <div className="border border-surface-container-highest rounded-xl p-4 bg-surface-container-lowest">
                      <h4 className="text-xs font-bold text-on-surface uppercase tracking-wider mb-2">Activo a Dar de Baja:</h4>
                      <div className="grid grid-cols-2 gap-3 text-xs">
                        <div>
                          <span className="text-on-surface-variant block">Código:</span>
                          <span className="font-mono font-bold text-primary">{selectedSolicitud.activo.codigo_activo}</span>
                        </div>
                        <div>
                          <span className="text-on-surface-variant block">Nombre:</span>
                          <span className="font-semibold text-on-surface">{selectedSolicitud.activo.nombre}</span>
                        </div>
                        <div>
                          <span className="text-on-surface-variant block">Marca / Modelo:</span>
                          <span>{selectedSolicitud.activo.marca || '-'} / {selectedSolicitud.activo.modelo || '-'}</span>
                        </div>
                        <div>
                          <span className="text-on-surface-variant block">Estado actual:</span>
                          <span className="font-semibold">{selectedSolicitud.activo.estado}</span>
                        </div>
                      </div>
                      <p className="text-[11px] text-on-surface-variant mt-3 border-t border-surface-container-highest pt-2">
                        🛡️ <strong>Baja Lógica:</strong> Al confirmar, el activo pasará al estado "Inactivo" y se registrará un evento de baja en el historial. No hay borrado físico para preservar la trazabilidad.
                      </p>
                    </div>
                  )}
                </div>
              )}

              {/* Información de Rechazo o Aprobación si ya fue resuelta */}
              {selectedSolicitud.estado === 'rechazada' && (
                <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-xs">
                  <span className="font-bold text-rose-800 block mb-1">Comentario de Rechazo (Administración):</span>
                  <p className="text-rose-900 bg-white p-3 rounded-lg border border-rose-200 italic font-medium">
                    "{selectedSolicitud.comentario_revision}"
                  </p>
                  <p className="mt-2 text-rose-700/80 text-[11px]">
                    Revisado por {selectedSolicitud.revisor?.nombre_completo || 'Administrador'} el {new Date(selectedSolicitud.revisado_at).toLocaleString('es-ES')}
                  </p>
                </div>
              )}

              {actionError && (
                <div className="p-3 rounded-lg bg-error-container text-on-error-container text-xs font-medium flex items-center gap-2">
                  <AlertTriangle size={16} />
                  <span>{actionError}</span>
                </div>
              )}
            </div>

            {/* Footer Modal con Botones */}
            <div className="p-4 border-t border-surface-container-highest flex justify-between items-center bg-surface-container-low/50">
              <button
                onClick={() => setIsDetailOpen(false)}
                className="px-4 py-2 text-xs font-semibold text-on-surface-variant hover:bg-surface-container rounded-lg transition-colors"
              >
                Cerrar
              </button>

              {selectedSolicitud.estado === 'pendiente' && (
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => {
                      setActionError(null);
                      setComentarioRechazo('');
                      setIsRechazarModalOpen(true);
                    }}
                    className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold rounded-lg bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100 transition-colors"
                  >
                    <XCircle size={15} /> Rechazar...
                  </button>
                  <button
                    onClick={() => {
                      setActionError(null);
                      setIsAprobarModalOpen(true);
                    }}
                    className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 transition-colors shadow-sm"
                  >
                    <CheckCircle2 size={15} /> Aprobar Solicitud
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* MODAL DE CONFIRMACIÓN: APROBAR */}
      {isAprobarModalOpen && selectedSolicitud && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-60 p-4">
          <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest shadow-xl w-full max-w-md p-6 animate-fade-in">
            <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto mb-4">
              <CheckCircle2 size={26} />
            </div>
            <h3 className="text-base font-bold text-center text-on-surface mb-2">
              ¿Confirmar Aprobación de {selectedSolicitud.tipo.toUpperCase()}?
            </h3>
            <p className="text-xs text-center text-on-surface-variant mb-6">
              Esta acción aplicará el cambio en el inventario oficial en una sola transacción atómica y notificará al solicitante.
            </p>

            {actionError && (
              <div className="p-3 mb-4 rounded-lg bg-error-container text-on-error-container text-xs font-medium">
                {actionError}
              </div>
            )}

            <div className="flex justify-end gap-3">
              <button
                disabled={actionLoading}
                onClick={() => setIsAprobarModalOpen(false)}
                className="px-4 py-2 text-xs font-semibold text-on-surface-variant hover:bg-surface-container rounded-lg"
              >
                Cancelar
              </button>
              <button
                disabled={actionLoading}
                onClick={handleConfirmAprobar}
                className="px-4 py-2 text-xs font-semibold bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors inline-flex items-center gap-2"
              >
                {actionLoading ? <Clock size={14} className="animate-spin" /> : <Check size={14} />}
                Confirmar y Aplicar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL DE RECHAZO: EXIGE COMENTARIO OBLIGATORIO */}
      {isRechazarModalOpen && selectedSolicitud && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-60 p-4">
          <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest shadow-xl w-full max-w-md p-6 animate-fade-in">
            <div className="w-12 h-12 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center mx-auto mb-4">
              <XCircle size={26} />
            </div>
            <h3 className="text-base font-bold text-center text-on-surface mb-1">
              Rechazar Solicitud de Cambio
            </h3>
            <p className="text-xs text-center text-on-surface-variant mb-4">
              El solicitante recibirá esta justificación en su aplicación móvil.
            </p>

            <div className="mb-4">
              <label className="block text-xs font-semibold text-on-surface mb-1">
                Motivo / Justificación de Rechazo <span className="text-rose-500">*</span>
              </label>
              <textarea
                rows={3}
                required
                value={comentarioRechazo}
                onChange={(e) => setComentarioRechazo(e.target.value)}
                placeholder="Explica claramente por qué no se acepta esta solicitud (obligatorio)..."
                className="w-full p-2.5 text-xs bg-surface rounded-lg border border-surface-container-highest text-on-surface placeholder:text-outline focus:outline-none focus:ring-2 focus:ring-rose-500"
              />
            </div>

            {actionError && (
              <div className="p-3 mb-4 rounded-lg bg-error-container text-on-error-container text-xs font-medium">
                {actionError}
              </div>
            )}

            <div className="flex justify-end gap-3">
              <button
                disabled={actionLoading}
                onClick={() => setIsRechazarModalOpen(false)}
                className="px-4 py-2 text-xs font-semibold text-on-surface-variant hover:bg-surface-container rounded-lg"
              >
                Cancelar
              </button>
              <button
                disabled={actionLoading || !comentarioRechazo.trim()}
                onClick={handleConfirmRechazar}
                className="px-4 py-2 text-xs font-semibold bg-rose-600 text-white rounded-lg hover:bg-rose-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center gap-2"
              >
                {actionLoading ? <Clock size={14} className="animate-spin" /> : <X size={14} />}
                Rechazar Solicitud
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL ÉXITO ALTA APROBADA: MUESTRA CÓDIGO Y OFRECE IMPRIMIR QR */}
      {altaAprobadaInfo && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-60 p-4">
          <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest shadow-xl w-full max-w-md p-6 text-center animate-fade-in">
            <div className="w-14 h-14 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto mb-4">
              <QrCode size={30} />
            </div>
            <h3 className="text-lg font-bold text-on-surface mb-1">
              ¡Activo Creado Exitosamente!
            </h3>
            <p className="text-xs text-on-surface-variant mb-4">
              La base de datos asignó el código oficial del inventario:
            </p>

            <div className="p-4 bg-emerald-50 rounded-xl border border-emerald-200 mb-6">
              <span className="text-xs uppercase font-semibold text-emerald-700 block mb-1">Código Asignado:</span>
              <span className="font-mono text-2xl font-black text-emerald-900 tracking-wider">
                {altaAprobadaInfo.codigo}
              </span>
            </div>

            <div className="flex flex-col sm:flex-row gap-3 justify-center">
              <button
                onClick={() => setAltaAprobadaInfo(null)}
                className="px-4 py-2 text-xs font-semibold text-on-surface-variant hover:bg-surface-container rounded-lg"
              >
                Cerrar
              </button>
              <button
                onClick={() => {
                  setQrAssets([altaAprobadaInfo.activo]);
                  setShowQRModal(true);
                  setAltaAprobadaInfo(null);
                }}
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 text-xs font-bold bg-primary text-on-primary rounded-lg hover:bg-primary/90 transition-colors shadow-sm"
              >
                <Printer size={16} /> Generar e Imprimir QR
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL DE IMPRESIÓN QR REUTILIZADO */}
      <QRPrintModal
        isOpen={showQRModal}
        onClose={() => setShowQRModal(false)}
        assetsToPrint={qrAssets}
      />
    </div>
  );
};

export default SolicitudesPage;
