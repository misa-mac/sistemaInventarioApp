import { useState, useEffect, useMemo } from 'react';
import api from '../services/api';
import { Plus, Search, Filter, Monitor, RefreshCw, Printer, Image as ImageIcon, Hash } from 'lucide-react';
import HardwareFormModal from '../components/HardwareFormModal';
import QRPrintModal from '../components/QRPrintModal';
import AssetDetailsModal from '../components/AssetDetailsModal';

const InventoryPage = () => {
  const [hardware, setHardware] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('todos');
  
  const [isFormModalOpen, setIsFormModalOpen] = useState(false);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);

  // QR Selection state
  const [selectedIds, setSelectedIds] = useState([]);
  const [isQRModalOpen, setIsQRModalOpen] = useState(false);
  const [assetsToPrint, setAssetsToPrint] = useState([]);

  useEffect(() => {
    fetchInventory();
  }, []);

  const fetchInventory = () => {
    setLoading(true);
    api.get('/inventory')
      .then(res => {
        setHardware(res.data);
      })
      .catch(err => {
        console.error('Error fetching inventory:', err);
        setError('No se pudo cargar el inventario.');
      })
      .finally(() => {
        setLoading(false);
      });
  };

  const filteredHardware = useMemo(() => {
    return hardware.filter(item => {
      const term = searchTerm.toLowerCase();
      const matchesSearch = 
        !term ||
        item.codigo_activo?.toLowerCase().includes(term) ||
        item.nombre?.toLowerCase().includes(term) ||
        item.marca?.toLowerCase().includes(term) ||
        item.modelo?.toLowerCase().includes(term) ||
        item.numero_serie?.toLowerCase().includes(term) ||
        item.tipo?.nombre?.toLowerCase().includes(term) ||
        item.ambiente?.nombre?.toLowerCase().includes(term);

      const matchesStatus = 
        statusFilter === 'todos' || 
        item.estado?.toLowerCase() === statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    });
  }, [hardware, searchTerm, statusFilter]);

  const getStatusClasses = (estado) => {
    switch (estado?.toLowerCase()) {
      case 'activo': 
        return 'bg-[#22c55e]/10 text-[#22c55e] border-[#22c55e]/20';
      case 'en_reparacion': 
      case 'dañado':
        return 'bg-amber-100 text-amber-700 border-amber-200';
      case 'baja': 
      case 'inactivo':
        return 'bg-error-container text-on-error-container border-error/20';
      default: 
        return 'bg-surface-container-highest text-on-surface-variant border-outline-variant';
    }
  };

  const handleAdd = () => {
    setSelectedItem(null);
    setIsFormModalOpen(true);
  };

  const handleEdit = (item) => {
    setSelectedItem(item);
    setIsFormModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('¿Está seguro de que desea eliminar este equipo?')) {
      try {
        await api.delete(`/inventory/${id}`);
        setSelectedIds(prev => prev.filter(selectedId => selectedId !== id));
        fetchInventory();
      } catch (err) {
        console.error('Error al eliminar:', err);
        alert('Error al eliminar el equipo.');
      }
    }
  };

  const handleCardClick = (item) => {
    setSelectedItem(item);
    setIsDetailsModalOpen(true);
  };

  // Select logic
  const handleSelectAll = (e) => {
    if (e.target.checked) {
      setSelectedIds(filteredHardware.map(item => item.id));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectOne = (e, id) => {
    e.stopPropagation();
    setSelectedIds(prev => 
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  // QR Logic
  const handlePrintBatch = () => {
    if (selectedIds.length === 0) return;
    const items = hardware.filter(h => selectedIds.includes(h.id));
    setAssetsToPrint(items);
    setIsQRModalOpen(true);
  };

  const handlePrintSingle = (item) => {
    setAssetsToPrint([item]);
    setIsQRModalOpen(true);
  };

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

  return (
    <div className="space-y-6 animate-fade-in no-print">
      
      {/* Page Header */}
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-h2 font-h2 text-on-surface tracking-tight mb-1">Activos Fijos</h1>
          <p className="text-on-surface-variant text-body-sm">Catálogo y gestión del inventario tecnológico institucional.</p>
        </div>
        <div className="flex gap-3">
          <button onClick={fetchInventory} className="flex items-center gap-2 px-4 py-2 bg-surface-container-lowest border border-outline-variant rounded shadow-sm text-sm font-medium text-on-surface hover:bg-surface-container-low transition-colors">
            <RefreshCw size={16} className={loading ? 'animate-spin text-outline' : 'text-outline'} />
            Sincronizar
          </button>
          <button onClick={handleAdd} className="flex items-center gap-2 px-4 py-2 bg-primary text-on-primary rounded shadow-sm text-sm font-medium hover:bg-primary/90 transition-colors">
            <Plus size={16} />
            Añadir Activo
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="bg-surface-container-lowest border border-surface-container-highest rounded-xl shadow-sm overflow-hidden flex flex-col min-h-[60vh]">
        
        {/* Toolbar */}
        <div className="p-4 border-b border-surface-container-highest flex justify-between items-center bg-surface-bright flex-wrap gap-4">
          <div className="flex items-center gap-4 flex-wrap">
            <div className="relative">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-outline" />
              <input 
                type="text" 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Buscar por código, serie, marca..." 
                className="pl-9 pr-4 py-1.5 bg-surface border border-outline-variant rounded text-sm focus:border-primary focus:ring-1 focus:ring-primary w-64 outline-none"
              />
            </div>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-1.5 bg-surface border border-outline-variant rounded text-sm focus:border-primary focus:ring-1 focus:ring-primary outline-none"
            >
              <option value="todos">Todos los estados</option>
              <option value="Activo">Activo</option>
              <option value="Inactivo">Inactivo</option>
              <option value="Dañado">Dañado</option>
            </select>

            <label className="flex items-center gap-2 cursor-pointer text-sm font-medium text-on-surface">
              <input 
                type="checkbox" 
                className="rounded border-outline-variant text-primary focus:ring-primary w-4 h-4 cursor-pointer"
                checked={filteredHardware.length > 0 && selectedIds.length === filteredHardware.length}
                onChange={handleSelectAll}
              />
              Seleccionar Todos
            </label>

            {selectedIds.length > 0 && (
              <button 
                onClick={handlePrintBatch}
                className="flex items-center gap-2 px-3 py-1.5 bg-secondary-container text-on-secondary-container border border-secondary-container hover:bg-secondary/20 rounded text-sm font-medium transition-colors animate-fade-in"
              >
                <Printer size={16} />
                Imprimir {selectedIds.length} QR(s)
              </button>
            )}
          </div>
        </div>

        {/* Grid View */}
        <div className="p-6 flex-1 bg-surface-container/20">
          {loading ? (
            <div className="flex items-center justify-center h-full text-on-surface-variant text-sm py-16">
              Cargando activos...
            </div>
          ) : error ? (
            <div className="flex items-center justify-center h-full text-error text-sm font-medium py-16">
              {error}
            </div>
          ) : filteredHardware.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-on-surface-variant text-sm py-16">
              <Monitor size={48} className="mb-4 opacity-50" />
              <p>No se encontraron activos que coincidan con la búsqueda.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
              {filteredHardware.map((item) => {
                const isSelected = selectedIds.includes(item.id);
                const imgPath = item.imagen_url || item.imagen;
                const imageUrl = imgPath ? (imgPath.startsWith('http') ? imgPath : `${API_URL}${imgPath}`) : null;
                
                return (
                  <div 
                    key={item.id} 
                    onClick={() => handleCardClick(item)}
                    className={`bg-surface-container-lowest rounded-xl border overflow-hidden cursor-pointer transition-all hover:shadow-md hover:-translate-y-1 group relative ${isSelected ? 'border-primary ring-1 ring-primary' : 'border-surface-container-highest'}`}
                  >
                    {/* Checkbox Overlay */}
                    <div className="absolute top-3 left-3 z-10">
                      <input 
                        type="checkbox" 
                        className="rounded border-outline-variant text-primary focus:ring-primary w-5 h-5 cursor-pointer bg-white shadow-sm"
                        checked={isSelected}
                        onChange={(e) => handleSelectOne(e, item.id)}
                        onClick={(e) => e.stopPropagation()}
                      />
                    </div>
                    
                    {/* Image Area */}
                    <div className="h-44 bg-surface-container flex items-center justify-center overflow-hidden relative">
                      {imageUrl ? (
                        <img src={imageUrl} alt={item.codigo_activo} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                      ) : (
                        <div className="text-on-surface-variant/50 flex flex-col items-center">
                          <ImageIcon size={32} className="mb-1 opacity-60" />
                          <span className="text-[11px] font-medium">Sin imagen</span>
                        </div>
                      )}
                      
                      {/* Status Badge overlay */}
                      <div className="absolute bottom-3 right-3">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider shadow-sm backdrop-blur-md ${getStatusClasses(item.estado)}`}>
                          {item.estado}
                        </span>
                      </div>
                    </div>
                    
                    {/* Content Area */}
                    <div className="p-4 border-t border-surface-container-highest flex flex-col gap-1">
                      <div className="flex justify-between items-center">
                        <span className="text-primary font-technical-data font-bold text-xs tracking-wider">
                          {item.codigo_activo}
                        </span>
                        <span className="text-[10px] px-1.5 py-0.5 bg-surface-container text-on-surface-variant rounded">
                          {item.tipo?.nombre || 'General'}
                        </span>
                      </div>

                      <div className="font-semibold text-on-surface text-sm truncate mt-0.5">
                        {item.nombre || `${item.tipo?.nombre || 'Activo'} ${item.codigo_activo}`}
                      </div>

                      {(item.marca || item.modelo) && (
                        <div className="text-xs text-on-surface-variant truncate">
                          {[item.marca, item.modelo].filter(Boolean).join(' • ')}
                        </div>
                      )}

                      {item.numero_serie && (
                        <div className="text-[11px] text-on-surface-variant/80 font-mono truncate flex items-center gap-1">
                          <Hash size={11} /> S/N: {item.numero_serie}
                        </div>
                      )}

                      <div className="text-xs text-outline mt-1 truncate border-t border-surface-container pt-1.5 flex justify-between items-center gap-2">
                        <span className="truncate" title={item.ambiente?.ubicacion ? `${item.ambiente.nombre} (${item.ambiente.ubicacion})` : item.ambiente?.nombre}>
                          {item.ambiente?.nombre ? `${item.ambiente.nombre}${item.ambiente.ubicacion ? ` • ${item.ambiente.ubicacion}` : ''}` : 'Sin ambiente'}
                        </span>
                        {item.valor && <span className="font-mono text-on-surface font-medium shrink-0">Bs. {item.valor}</span>}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
        
        {/* Footer */}
        <div className="px-6 py-3 border-t border-surface-container-highest bg-surface-bright flex justify-between items-center text-xs text-on-surface-variant">
          <div>Mostrando {filteredHardware.length} de {hardware.length} activos en total</div>
        </div>

      </div>
      
      {/* Modals */}
      <HardwareFormModal 
        isOpen={isFormModalOpen}
        onClose={() => setIsFormModalOpen(false)}
        onSuccess={fetchInventory}
        editData={selectedItem}
      />

      <AssetDetailsModal 
        isOpen={isDetailsModalOpen}
        onClose={() => setIsDetailsModalOpen(false)}
        asset={selectedItem}
        onEdit={handleEdit}
        onDelete={handleDelete}
        onPrintQR={handlePrintSingle}
      />

      <QRPrintModal 
        isOpen={isQRModalOpen}
        onClose={() => setIsQRModalOpen(false)}
        assetsToPrint={assetsToPrint}
      />
    </div>
  );
};

export default InventoryPage;
