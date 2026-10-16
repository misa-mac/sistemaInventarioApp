import { useState, useEffect } from 'react';
import api from '../services/api';
import { Plus, Edit2, Trash2, Shield, X, ShieldAlert } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const UsuarioFormModal = ({ isOpen, onClose, onSuccess, editData }) => {
  const [formData, setFormData] = useState({
    nombre_completo: '',
    email: '',
    password: '',
    rol: 'tecnico',
    activo: true
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isOpen) {
      if (editData) {
        setFormData({
          nombre_completo: editData.nombre_completo,
          email: editData.email,
          password: '', // Empty unless changing
          rol: editData.rol,
          activo: editData.activo
        });
      } else {
        setFormData({ nombre_completo: '', email: '', password: '', rol: 'tecnico', activo: true });
      }
      setError(null);
    }
  }, [isOpen, editData]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    // Si estamos creando, el password es obligatorio
    if (!editData && !formData.password) {
      setError('La contraseña es obligatoria para nuevos usuarios.');
      setLoading(false);
      return;
    }

    try {
      if (editData) {
        await api.put(`/usuarios/${editData.id}`, formData);
      } else {
        await api.post('/usuarios', formData);
      }
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Error al guardar el usuario.');
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
            <Shield size={20} className="text-primary" />
            {editData ? 'Editar Usuario' : 'Nuevo Usuario'}
          </h2>
          <button onClick={onClose} className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full">
            <X size={20} />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && <div className="bg-error-container text-on-error-container p-3 rounded text-sm">{error}</div>}
          
          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Nombre Completo *</label>
            <input 
              type="text" 
              value={formData.nombre_completo}
              onChange={(e) => setFormData({...formData, nombre_completo: e.target.value})}
              required
              className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">Correo Electrónico *</label>
            <input 
              type="email" 
              value={formData.email}
              onChange={(e) => setFormData({...formData, email: e.target.value})}
              required
              className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface mb-1">
              Contraseña {editData && <span className="text-xs text-on-surface-variant font-normal">(Dejar en blanco para no cambiar)</span>}
            </label>
            <input 
              type="password" 
              value={formData.password}
              onChange={(e) => setFormData({...formData, password: e.target.value})}
              required={!editData}
              className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Rol *</label>
              <select 
                value={formData.rol}
                onChange={(e) => setFormData({...formData, rol: e.target.value})}
                className="w-full px-3 py-2 bg-surface border border-outline-variant rounded focus:border-primary focus:ring-1 focus:ring-primary outline-none"
              >
                <option value="tecnico">Técnico</option>
                <option value="auditor">Auditor</option>
                <option value="admin">Administrador</option>
              </select>
            </div>
            
            <div className="flex items-center pt-6">
              <label className="flex items-center gap-2 cursor-pointer text-sm font-medium text-on-surface">
                <input 
                  type="checkbox" 
                  checked={formData.activo}
                  onChange={(e) => setFormData({...formData, activo: e.target.checked})}
                  className="rounded border-outline-variant text-primary focus:ring-primary w-4 h-4 cursor-pointer"
                />
                Cuenta Activa
              </label>
            </div>
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

const UsuariosPage = () => {
  const { user } = useAuth();
  const [usuarios, setUsuarios] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editItem, setEditItem] = useState(null);

  useEffect(() => {
    if (user?.rol === 'admin') {
      fetchUsuarios();
    } else {
      setLoading(false);
    }
  }, [user]);

  const fetchUsuarios = async () => {
    setLoading(true);
    try {
      const res = await api.get('/usuarios');
      setUsuarios(res.data);
      setError(null);
    } catch (err) {
      setError(err.response?.data?.message || 'Error al obtener usuarios');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('¿Está seguro de que desea eliminar permanentemente a este usuario?')) {
      try {
        await api.delete(`/usuarios/${id}`);
        fetchUsuarios();
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

  if (user?.rol !== 'admin') {
    return (
      <div className="h-full flex flex-col items-center justify-center p-8 text-center animate-fade-in">
        <ShieldAlert size={64} className="text-error mb-4 opacity-80" />
        <h2 className="text-2xl font-bold text-on-surface mb-2">Acceso Restringido</h2>
        <p className="text-on-surface-variant max-w-md">
          Esta sección es exclusiva para administradores. Tu rol actual ({user?.rol}) no tiene permisos para gestionar cuentas de usuario ni políticas de acceso.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-h2 font-h2 text-on-surface tracking-tight mb-1">Roles y Permisos</h1>
          <p className="text-on-surface-variant text-body-sm">Control de acceso y administración de cuentas de usuario.</p>
        </div>
        <button onClick={handleAdd} className="flex items-center gap-2 px-4 py-2 bg-primary text-on-primary rounded shadow-sm text-sm font-medium hover:bg-primary/90">
          <Plus size={16} />
          Nuevo Usuario
        </button>
      </div>

      <div className="bg-surface-container-lowest border border-surface-container-highest rounded-xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-on-surface-variant">Cargando...</div>
        ) : error ? (
          <div className="p-8 text-center text-error font-medium">{error}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-bright border-b border-surface-container-highest text-sm text-on-surface-variant">
                  <th className="p-4 font-medium">Nombre Completo</th>
                  <th className="p-4 font-medium">Correo Electrónico</th>
                  <th className="p-4 font-medium">Rol</th>
                  <th className="p-4 font-medium">Estado</th>
                  <th className="p-4 font-medium w-24 text-center">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container-highest">
                {usuarios.map(u => (
                  <tr key={u.id} className="hover:bg-surface-container-low transition-colors">
                    <td className="p-4 font-medium text-on-surface">
                      {u.nombre_completo}
                      {user.id === u.id && <span className="ml-2 text-[10px] uppercase bg-secondary-container text-on-secondary-container px-2 py-0.5 rounded-full font-bold tracking-wider">Tú</span>}
                    </td>
                    <td className="p-4 text-on-surface-variant">{u.email}</td>
                    <td className="p-4">
                      <span className={`px-2 py-1 rounded text-xs font-medium border ${
                        u.rol === 'admin' ? 'bg-primary-container text-on-primary-container border-primary/20' :
                        u.rol === 'auditor' ? 'bg-amber-100 text-amber-700 border-amber-200' :
                        'bg-surface-container-high text-on-surface-variant border-outline-variant'
                      }`}>
                        {u.rol.toUpperCase()}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className={`flex items-center gap-1.5 text-xs font-medium ${u.activo ? 'text-[#22c55e]' : 'text-error'}`}>
                        <span className={`w-2 h-2 rounded-full ${u.activo ? 'bg-[#22c55e]' : 'bg-error'}`}></span>
                        {u.activo ? 'Activo' : 'Inactivo'}
                      </span>
                    </td>
                    <td className="p-4 text-center space-x-2">
                      <button onClick={() => handleEdit(u)} className="p-1.5 text-on-surface-variant hover:text-secondary hover:bg-secondary/10 rounded transition-colors">
                        <Edit2 size={16} />
                      </button>
                      <button 
                        onClick={() => handleDelete(u.id)} 
                        disabled={user.id === u.id}
                        className={`p-1.5 rounded transition-colors ${user.id === u.id ? 'opacity-30 cursor-not-allowed text-on-surface-variant' : 'text-on-surface-variant hover:text-error hover:bg-error/10'}`}
                        title={user.id === u.id ? "No puedes eliminar tu propia cuenta" : "Eliminar"}
                      >
                        <Trash2 size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
                {usuarios.length === 0 && (
                  <tr>
                    <td colSpan="5" className="p-8 text-center text-on-surface-variant">No hay usuarios registrados.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <UsuarioFormModal 
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={fetchUsuarios}
        editData={editItem}
      />
    </div>
  );
};

export default UsuariosPage;
