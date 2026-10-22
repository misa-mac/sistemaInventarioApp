import React, { useState, useEffect } from 'react';
import { X, QrCode, Upload, Image as ImageIcon } from 'lucide-react';
import imageCompression from 'browser-image-compression';
import api from '../services/api';

const HardwareFormModal = ({ isOpen, onClose, onSuccess, editData }) => {
  const [formData, setFormData] = useState({
    nombre: '',
    marca: '',
    modelo: '',
    numero_serie: '',
    tipo_activo_id: '',
    ambiente_id: '',
    ambiente_registro_id: '',
    origen: '',
    especificacion_origen: '',
    descripcion: '',
    responsable: '',
    fecha_ingreso: new Date().toISOString().split('T')[0],
    valor: '',
    estado: 'Activo',
    observaciones: '',
  });
  
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  
  const [ambientes, setAmbientes] = useState([]);
  const [tiposActivos, setTiposActivos] = useState([]);
  const [nextSequence, setNextSequence] = useState(1);
  const [previewCodigo, setPreviewCodigo] = useState('');
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isOpen) {
      fetchCatalogos();
      setImageFile(null);
      setImagePreview(null);
      if (editData) {
        setFormData({
          nombre: editData.nombre || '',
          marca: editData.marca || '',
          modelo: editData.modelo || '',
          numero_serie: editData.numero_serie || '',
          tipo_activo_id: editData.tipo_activo_id || '',
          ambiente_id: editData.ambiente_id || '',
          ambiente_registro_id: editData.ambiente_registro_id || editData.ambiente_id || '',
          origen: editData.origen || '',
          especificacion_origen: editData.especificacion_origen || '',
          descripcion: editData.descripcion || '',
          responsable: editData.responsable || '',
          fecha_ingreso: editData.fecha_ingreso ? new Date(editData.fecha_ingreso).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
          valor: editData.valor || '',
          estado: editData.estado || 'Activo',
          observaciones: editData.observaciones || '',
        });
        setPreviewCodigo(editData.codigo_activo);
        const img = editData.imagen_url || editData.imagen;
        if (img) {
          const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';
          setImagePreview(img.startsWith('http') ? img : `${API_URL}${img}`);
        }
      } else {
        setFormData({
          nombre: '',
          marca: '',
          modelo: '',
          numero_serie: '',
          tipo_activo_id: '',
          ambiente_id: '',
          ambiente_registro_id: '',
          origen: '',
          especificacion_origen: '',
          descripcion: '',
          responsable: '',
          fecha_ingreso: new Date().toISOString().split('T')[0],
          valor: '',
          estado: 'Activo',
          observaciones: '',
        });
        setPreviewCodigo('');
      }
    }
  }, [isOpen, editData]);

  const fetchCatalogos = async () => {
    try {
      const [resAmbientes, resTipos] = await Promise.all([
        api.get('/ambientes'),
        api.get('/tipos-activos'),
      ]);
      setAmbientes(resAmbientes.data);
      setTiposActivos(resTipos.data);
    } catch (err) {
      console.error('Error fetching catalogos:', err);
    }
  };

  // El código oficial se asigna exclusivamente en la base de datos por el trigger fn_activos_asignar_codigo
  useEffect(() => {
    if (editData) {
      setPreviewCodigo(editData.codigo_activo);
    } else {
      setPreviewCodigo('Asignado por base de datos (1YYAACC-GG)');
    }
  }, [editData]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleImageChange = async (e) => {
    const file = e.target.files[0];
    if (file) {
      setImagePreview(URL.createObjectURL(file));
      try {
        const options = {
          maxSizeMB: 0.5,
          maxWidthOrHeight: 1200,
          useWebWorker: true
        };
        const compressedFile = await imageCompression(file, options);
        setImageFile(compressedFile);
      } catch (error) {
        console.error("Error al comprimir la imagen:", error);
        setError("Error al procesar la imagen. Intente con otra.");
      }
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    if (formData.origen === 'Otros' && !formData.especificacion_origen.trim()) {
      setError('Debe especificar el origen cuando selecciona "Otros"');
      setLoading(false);
      return;
    }

    const submitData = new FormData();
    Object.keys(formData).forEach(key => {
      if (formData[key] !== null && formData[key] !== '') {
        submitData.append(key, formData[key]);
      }
    });

    if (imageFile) {
      submitData.append('imagen', imageFile);
    }

    try {
      if (editData) {
        await api.put(`/inventory/${editData.id}`, submitData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });
      } else {
        await api.post('/inventory', submitData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });
      }
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.error || err.response?.data?.message || 'Error al guardar el activo.');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in p-4 overflow-y-auto">
      <div className="bg-surface-container-lowest rounded-xl shadow-lg w-full max-w-4xl max-h-[92vh] flex flex-col my-auto">
        
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b border-surface-container-highest">
          <div>
            <h2 className="text-xl font-bold text-on-surface">
              {editData ? 'Editar Activo Fijo' : 'Registrar Nuevo Activo'}
            </h2>
            <p className="text-xs text-on-surface-variant mt-0.5">
              Esquema unificado con código de barras/QR (1YYAACC-GG) y trazabilidad completa
            </p>
          </div>
          <button 
            onClick={onClose}
            className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 overflow-y-auto">
          {error && (
            <div className="bg-error-container text-on-error-container p-3 rounded mb-4 text-sm font-medium">
              {error}
            </div>
          )}
          
          <form id="hardware-form" onSubmit={handleSubmit} className="space-y-6">
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              
              {/* Foto y QR Column */}
              <div className="md:col-span-1 space-y-4 flex flex-col items-center">
                <div className="w-full aspect-square border-2 border-dashed border-outline-variant rounded-xl overflow-hidden bg-surface-container flex items-center justify-center relative group">
                  {imagePreview ? (
                    <img src={imagePreview} alt="Preview" className="w-full h-full object-cover" />
                  ) : (
                    <div className="text-center text-on-surface-variant p-4 flex flex-col items-center">
                      <ImageIcon size={36} className="mb-2 opacity-50" />
                      <span className="text-sm font-medium">Sin fotografía</span>
                    </div>
                  )}
                  
                  <label className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center text-white cursor-pointer">
                    <Upload size={24} className="mb-2" />
                    <span className="text-sm font-medium">Subir Fotografía</span>
                    <input 
                      type="file" 
                      accept="image/*" 
                      className="hidden" 
                      onChange={handleImageChange}
                    />
                  </label>
                </div>
                
                <p className="text-xs text-center text-on-surface-variant">La imagen se optimiza y almacena en el servidor.</p>

                {/* Código QR Resultante */}
                <div className="w-full p-4 bg-primary-container/30 border border-primary/20 rounded-xl text-center mt-auto">
                  <div className="mx-auto w-10 h-10 bg-primary text-on-primary rounded-lg shadow-sm flex items-center justify-center mb-2">
                    <QrCode size={20} />
                  </div>
                  <p className="text-[10px] font-bold uppercase text-primary tracking-wider mb-1">Código QR Unificado</p>
                  <p className="text-base font-technical-data font-bold text-on-surface tracking-wider">
                    {previewCodigo || 'Esperando tipo y ambiente...'}
                  </p>
                  <p className="text-[10px] text-on-surface-variant mt-1">Formato: 1 + Año(YY) + Tipo(AA) + Ambiente(CC) - Correlativo(GG)</p>
                </div>
              </div>

              {/* Data Column */}
              <div className="md:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4">
                
                {/* Nombre descriptivo del activo */}
                <div className="sm:col-span-2">
                  <label className="block text-sm font-medium text-on-surface mb-1">Nombre / Denominación del Activo</label>
                  <input 
                    type="text" 
                    name="nombre"
                    value={formData.nombre}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                    placeholder="Ej: Computadora de Escritorio HP Pavilion"
                  />
                  <p className="text-xs text-on-surface-variant mt-1">Si se deja vacío, se generará automáticamente a partir del Tipo y Código.</p>
                </div>

                {/* Marca y Modelo */}
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Marca</label>
                  <input 
                    type="text" 
                    name="marca"
                    value={formData.marca}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                    placeholder="Ej: Dell, HP, Epson, Cisco"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Modelo</label>
                  <input 
                    type="text" 
                    name="modelo"
                    value={formData.modelo}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                    placeholder="Ej: Latitude 5420, L3150"
                  />
                </div>

                {/* Número de Serie */}
                <div className="sm:col-span-2">
                  <label className="block text-sm font-medium text-on-surface mb-1">Número de Serie (S/N)</label>
                  <input 
                    type="text" 
                    name="numero_serie"
                    value={formData.numero_serie}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none font-mono"
                    placeholder="Ej: CN-0GH342-71618-52B-0466"
                  />
                </div>

                {/* Tipo de Activo */}
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Tipo de Activo *</label>
                  <select 
                    name="tipo_activo_id"
                    value={formData.tipo_activo_id}
                    onChange={handleChange}
                    required
                    disabled={!!editData}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none disabled:bg-surface-container"
                  >
                    <option value="">Seleccione...</option>
                    {tiposActivos.map(t => (
                      <option key={t.id} value={t.id}>{t.nombre} ({t.codigo})</option>
                    ))}
                  </select>
                </div>

                {/* Ambiente Actual */}
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Ambiente de Ubicación *</label>
                  <select 
                    name="ambiente_id"
                    value={formData.ambiente_id}
                    onChange={handleChange}
                    required
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                  >
                    <option value="">Seleccione...</option>
                    {ambientes.map((amb) => (
                      <option key={amb.id} value={amb.id}>
                        {amb.nombre} {amb.ubicacion ? `— ${amb.ubicacion}` : ''} (CC: {amb.codigo.toString().padStart(2, '0')})
                      </option>
                    ))}
                  </select>
                </div>

                {/* Origen del Activo */}
                <div className={formData.origen === 'Otros' ? 'sm:col-span-1' : 'sm:col-span-2'}>
                  <label className="block text-sm font-medium text-on-surface mb-1">Origen del Activo</label>
                  <select 
                    name="origen"
                    value={formData.origen}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                  >
                    <option value="">Seleccione...</option>
                    <option value="Donación de estudiantes">Donación de estudiantes</option>
                    <option value="Recursos propios">Recursos propios (institución)</option>
                    <option value="Dotación gubernamental">Dotación gubernamental</option>
                    <option value="Otros">Otros (Especificar)</option>
                  </select>
                </div>

                {formData.origen === 'Otros' && (
                  <div>
                    <label className="block text-sm font-medium text-on-surface mb-1">Especificar Origen *</label>
                    <input 
                      type="text" 
                      name="especificacion_origen"
                      value={formData.especificacion_origen}
                      onChange={handleChange}
                      required
                      className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                      placeholder="Especifique origen..."
                    />
                  </div>
                )}

                {/* Responsable y Fecha */}
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Responsable</label>
                  <input 
                    type="text" 
                    name="responsable"
                    value={formData.responsable}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                    placeholder="Ej. Ing. Juan Pérez"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Fecha de Ingreso *</label>
                  <input 
                    type="date" 
                    name="fecha_ingreso"
                    value={formData.fecha_ingreso}
                    onChange={handleChange}
                    required
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                  />
                </div>

                {/* Valor y Estado */}
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Valor Estimado (Bs.)</label>
                  <input 
                    type="number" 
                    step="0.01" 
                    min="0"
                    name="valor"
                    value={formData.valor}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                    placeholder="0.00"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Estado</label>
                  <select 
                    name="estado"
                    value={formData.estado}
                    onChange={handleChange}
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                  >
                    <option value="Activo">Activo</option>
                    <option value="Inactivo">Inactivo</option>
                    <option value="Dañado">Dañado</option>
                  </select>
                </div>

                {/* Descripción y Observaciones */}
                <div className="sm:col-span-2">
                  <label className="block text-sm font-medium text-on-surface mb-1">Descripción / Especificaciones</label>
                  <textarea 
                    name="descripcion"
                    value={formData.descripcion}
                    onChange={handleChange}
                    rows="2"
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                    placeholder="Procesador, RAM, disco, puertos, detalles físicos..."
                  ></textarea>
                </div>

                <div className="sm:col-span-2">
                  <label className="block text-sm font-medium text-on-surface mb-1">Observaciones</label>
                  <textarea 
                    name="observaciones"
                    value={formData.observaciones}
                    onChange={handleChange}
                    rows="2"
                    className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                    placeholder="Notas para auditorías, condiciones especiales de resguardo..."
                  ></textarea>
                </div>

              </div>
            </div>
          </form>
        </div>

        {/* Footer */}
        <div className="p-6 border-t border-surface-container-highest flex justify-end gap-3 bg-surface-bright rounded-b-xl">
          <button 
            type="button" 
            onClick={onClose}
            className="px-4 py-2 border border-outline rounded text-sm font-medium text-on-surface hover:bg-surface-container transition-colors"
          >
            Cancelar
          </button>
          <button 
            form="hardware-form"
            type="submit" 
            disabled={loading}
            className="px-4 py-2 bg-primary text-on-primary rounded shadow-sm text-sm font-medium hover:bg-primary/90 transition-colors flex justify-center items-center"
          >
            {loading ? 'Guardando...' : (editData ? 'Actualizar Activo' : 'Guardar Activo')}
          </button>
        </div>

      </div>
    </div>
  );
};

export default HardwareFormModal;
