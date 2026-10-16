import { useState, useEffect } from 'react';
import api from '../services/api';
import { Plus, Edit2, Trash2, Settings, Server, Layers, X, Database } from 'lucide-react';

const TipoActivoFormModal = ({ isOpen, onClose, onSuccess, editData }) => {
  const [formData, setFormData] = useState({
    codigo: '',
    nombre: '',
    descripcion: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isOpen) {
      if (editData) {
        setFormData({
          codigo: editData.codigo,
          nombre: editData.nombre,
          descripcion: editData.descripcion || ''
        });
      } else {
        setFormData({ codigo: '', nombre: '', descripcion: '' });
      }
      setError(null);
    }
  }, [isOpen, editData]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      if (editData) {
        await api.put(`/tipos-activos/${editData.id}`, formData);
      } else {
        await api.post('/tipos-activos', formData);
      }
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Error al guardar el tipo de activo.');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 animate-fade-in p-4">
      <div className="bg-surface-container-lowest rounded-xl shadow-lg w-full max-w-md flex flex-col">
        <div className="flex justify-between items-center p-6 border-b border-surface-container-highest">
          <h2 className="text-xl font-medium text-on-surface flex items-center gap-2">
            <Layers size={20} className="text-primary" />
            {editData ? 'Editar Tipo de Activo' : 'Nuevo Tipo de Activo'}
          </h2>
          <button onClick={onClose} className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full">
            <X size={20} />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && <div className="bg-error-container text-on-error-container p-3 rounded text-sm">{error}</div>}
          
          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Código (AA) *</label>
            <input 
              type="number" 
              value={formData.codigo}
              onChange={(e) => setFormData({...formData, codigo: e.target.value})}
              required
              min="10"
              max="100"
              placeholder="Ej: 50"
              className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
            />
            <p className="text-xs text-on-surface-variant mt-1">Debe ser un número entre 10 y 100.</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Nombre de la Categoría *</label>
            <input 
              type="text" 
              value={formData.nombre}
              onChange={(e) => setFormData({...formData, nombre: e.target.value})}
              required
              placeholder="Ej: Monitor, Teclado, Impresora 3D"
              className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Descripción</label>
            <textarea 
              value={formData.descripcion}
              onChange={(e) => setFormData({...formData, descripcion: e.target.value})}
              rows="3"
              className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
            ></textarea>
          </div>

          <div className="pt-4 flex justify-end gap-3">
            <button type="button" onClick={onClose} className="px-4 py-2 border border-outline rounded text-sm font-medium">Cancelar</button>
            <button type="submit" disabled={loading} className="px-4 py-2 bg-primary text-on-primary rounded text-sm font-medium hover:bg-primary/90">
              {loading ? 'Guardando...' : 'Guardar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const ConfiguracionPage = () => {
  const [activeTab, setActiveTab] = useState('catalogos');
  const [tipos, setTipos] = useState([]);
  const [loading, setLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editItem, setEditItem] = useState(null);

  useEffect(() => {
    if (activeTab === 'catalogos') {
      fetchTipos();
    }
  }, [activeTab]);

  const fetchTipos = async () => {
    setLoading(true);
    try {
      const res = await api.get('/tipos-activos');
      setTipos(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('¿Está seguro de que desea eliminar esta categoría? Si hay hardware asociado, no se podrá eliminar.')) {
      try {
        await api.delete(`/tipos-activos/${id}`);
        fetchTipos();
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

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-h2 font-h2 text-on-surface tracking-tight mb-1">Configuración</h1>
          <p className="text-on-surface-variant text-body-sm">Ajustes del sistema y catálogos globales.</p>
        </div>
      </div>

      <div className="flex gap-6 flex-col md:flex-row">
        
        {/* Sidebar Nav */}
        <div className="w-full md:w-64 flex flex-col gap-2">
          <button 
            onClick={() => setActiveTab('catalogos')}
            className={`flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition-colors text-left ${activeTab === 'catalogos' ? 'bg-primary-container text-on-primary-container' : 'text-on-surface-variant hover:bg-surface-container-low'}`}
          >
            <Database size={18} />
            Catálogo de Hardware
          </button>
          <button 
            onClick={() => setActiveTab('sistema')}
            className={`flex items-center gap-3 p-3 rounded-lg text-sm font-medium transition-colors text-left ${activeTab === 'sistema' ? 'bg-primary-container text-on-primary-container' : 'text-on-surface-variant hover:bg-surface-container-low'}`}
          >
            <Server size={18} />
            Parámetros del Sistema
          </button>
        </div>

        {/* Content Area */}
        <div className="flex-1 bg-surface-container-lowest border border-surface-container-highest rounded-xl shadow-sm min-h-[500px]">
          
          {activeTab === 'catalogos' && (
            <div className="flex flex-col h-full animate-fade-in">
              <div className="p-6 border-b border-surface-container-highest flex justify-between items-center bg-surface-bright rounded-t-xl">
                <div>
                  <h3 className="text-lg font-medium text-on-surface">Categorías de Hardware (Tipos de Activos)</h3>
                  <p className="text-sm text-on-surface-variant mt-1">Administra la estructura central de códigos AA.</p>
                </div>
                <button onClick={handleAdd} className="flex items-center gap-2 px-3 py-2 bg-primary text-on-primary rounded shadow-sm text-sm font-medium hover:bg-primary/90">
                  <Plus size={16} />
                  Nueva Categoría
                </button>
              </div>

              {loading ? (
                <div className="p-8 text-center text-on-surface-variant">Cargando catálogo...</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-surface-container-low border-b border-surface-container-highest text-xs uppercase text-on-surface-variant tracking-wider">
                        <th className="p-4 font-medium">Código (AA)</th>
                        <th className="p-4 font-medium">Categoría</th>
                        <th className="p-4 font-medium">Descripción</th>
                        <th className="p-4 font-medium text-center w-24">Acciones</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-surface-container-highest">
                      {tipos.map(t => (
                        <tr key={t.id} className="hover:bg-surface-container-low transition-colors">
                          <td className="p-4 font-mono font-bold text-primary">{t.codigo.toString().padStart(2, '0')}</td>
                          <td className="p-4 font-medium text-on-surface">{t.nombre}</td>
                          <td className="p-4 text-on-surface-variant text-sm">{t.descripcion || '-'}</td>
                          <td className="p-4 text-center space-x-2">
                            <button onClick={() => handleEdit(t)} className="p-1.5 text-on-surface-variant hover:text-secondary hover:bg-secondary/10 rounded transition-colors">
                              <Edit2 size={16} />
                            </button>
                            <button onClick={() => handleDelete(t.id)} className="p-1.5 text-on-surface-variant hover:text-error hover:bg-error/10 rounded transition-colors">
                              <Trash2 size={16} />
                            </button>
                          </td>
                        </tr>
                      ))}
                      {tipos.length === 0 && (
                        <tr>
                          <td colSpan="4" className="p-8 text-center text-on-surface-variant">No hay categorías registradas.</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {activeTab === 'sistema' && (
            <div className="p-6 animate-fade-in">
              <h3 className="text-lg font-medium text-on-surface mb-6">Parámetros Globales</h3>
              <div className="space-y-6 max-w-2xl">
                
                <div className="p-4 bg-surface-container rounded-xl border border-outline-variant">
                  <h4 className="font-medium text-on-surface mb-2">Constantes de Codificación</h4>
                  <p className="text-sm text-on-surface-variant mb-4">Según los requerimientos institucionales, estos valores están fijados y no pueden ser alterados por el usuario para mantener la integridad del código único XYZAACC-GG.</p>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs text-on-surface-variant mb-1">X (Libro de Cuentas)</label>
                      <input type="text" disabled value="1 - Activo Fijo" className="w-full px-3 py-2 bg-surface-container-low text-on-surface-variant border border-outline-variant/50 rounded cursor-not-allowed text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs text-on-surface-variant mb-1">YZ (Carrera)</label>
                      <input type="text" disabled value="50 - Sistemas Informáticos" className="w-full px-3 py-2 bg-surface-container-low text-on-surface-variant border border-outline-variant/50 rounded cursor-not-allowed text-sm" />
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-surface-container rounded-xl border border-outline-variant">
                  <h4 className="font-medium text-on-surface mb-2">Información de la Institución</h4>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm text-on-surface font-medium mb-1">Nombre</label>
                      <input type="text" defaultValue='Instituto Tecnológico "Bolivia Mar"' className="w-full px-3 py-2 bg-surface border border-outline-variant rounded text-sm" />
                    </div>
                    <button className="px-4 py-2 bg-secondary text-on-secondary rounded text-sm font-medium hover:bg-secondary/90 transition-colors">
                      Guardar Cambios
                    </button>
                  </div>
                </div>

              </div>
            </div>
          )}

        </div>
      </div>

      <TipoActivoFormModal 
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={fetchTipos}
        editData={editItem}
      />
    </div>
  );
};

export default ConfiguracionPage;
