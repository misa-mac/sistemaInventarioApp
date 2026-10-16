import React from 'react';
import { X, QrCode, Edit2, Trash2, Tag, Layers, MapPin, Hash } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';

const AssetDetailsModal = ({ isOpen, onClose, asset, onEdit, onDelete, onPrintQR }) => {
  if (!isOpen || !asset) return null;

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';
  const imgPath = asset.imagen_url || asset.imagen;
  const imageUrl = imgPath ? (imgPath.startsWith('http') ? imgPath : `${API_URL}${imgPath}`) : null;

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4 animate-fade-in">
      <div className="bg-surface-container-lowest rounded-xl shadow-lg w-full max-w-4xl max-h-[90vh] flex flex-col">
        
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b border-surface-container-highest">
          <div>
            <h2 className="text-xl font-bold text-on-surface">Detalles del Activo</h2>
            <p className="text-xs text-on-surface-variant font-mono">{asset.codigo_activo}</p>
          </div>
          <button onClick={onClose} className="text-on-surface-variant hover:bg-surface-container p-2 rounded-full transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 overflow-y-auto flex-1 bg-surface-container/30">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            
            {/* Foto y QR Col */}
            <div className="md:col-span-1 flex flex-col items-center">
              <div className="w-full aspect-square bg-surface-container-high rounded-xl overflow-hidden flex items-center justify-center border border-outline-variant/30 mb-6 shadow-sm">
                {imageUrl ? (
                  <img src={imageUrl} alt={asset.codigo_activo} className="w-full h-full object-cover" />
                ) : (
                  <div className="text-on-surface-variant/50 text-center flex flex-col items-center gap-2">
                    <QrCode size={48} />
                    <span className="text-sm font-medium">Sin fotografía</span>
                  </div>
                )}
              </div>
              
              <div className="bg-white p-4 rounded-xl shadow-sm border border-outline-variant/20 inline-block text-center">
                <QRCodeSVG value={asset.codigo_activo} size={150} level="M" />
                <p className="text-center font-mono font-bold mt-2 text-black text-sm tracking-wider">{asset.codigo_activo}</p>
              </div>
            </div>

            {/* Info Col */}
            <div className="md:col-span-2 space-y-6">
              
              <div>
                <h3 className="text-2xl font-bold text-on-surface tracking-tight mb-1">
                  {asset.nombre || `${asset.tipo?.nombre || 'Activo'} ${asset.codigo_activo}`}
                </h3>
                <div className="flex flex-wrap items-center gap-2 mt-2">
                  <span className="px-3 py-1 bg-secondary-container text-on-secondary-container rounded-full text-xs font-semibold">
                    {asset.tipo?.nombre}
                  </span>
                  <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${
                    asset.estado === 'Activo' ? 'bg-[#22c55e]/10 text-[#22c55e] border-[#22c55e]/20' : 
                    asset.estado === 'Dañado' ? 'bg-amber-100 text-amber-700 border-amber-200' : 
                    'bg-error-container text-on-error-container border-error/20'
                  }`}>
                    {asset.estado}
                  </span>
                  {asset.marca && (
                    <span className="px-2.5 py-0.5 bg-surface-container-highest text-on-surface-variant rounded-md text-xs font-medium">
                      Marca: {asset.marca}
                    </span>
                  )}
                  {asset.modelo && (
                    <span className="px-2.5 py-0.5 bg-surface-container-highest text-on-surface-variant rounded-md text-xs font-medium">
                      Modelo: {asset.modelo}
                    </span>
                  )}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-y-4 gap-x-6 text-sm">
                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1 flex items-center gap-1">
                    <MapPin size={14} className="text-primary" /> Ubicación Actual
                  </p>
                  <p className="text-on-surface font-semibold text-base">{asset.ambiente?.nombre || 'N/A'}</p>
                </div>

                {asset.ambiente_registro && (
                  <div>
                    <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1 flex items-center gap-1">
                      <Layers size={14} /> Ambiente de Registro
                    </p>
                    <p className="text-on-surface font-medium">{asset.ambiente_registro.nombre}</p>
                  </div>
                )}

                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1 flex items-center gap-1">
                    <Hash size={14} /> Número de Serie
                  </p>
                  <p className="text-on-surface font-mono font-medium">{asset.numero_serie || 'Sin número de serie'}</p>
                </div>

                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1">Responsable</p>
                  <p className="text-on-surface font-medium">{asset.responsable || 'No asignado'}</p>
                </div>

                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1">Origen</p>
                  <p className="text-on-surface">{asset.origen || 'No especificado'}</p>
                  {asset.especificacion_origen && <p className="text-on-surface-variant italic text-xs mt-0.5">{asset.especificacion_origen}</p>}
                </div>

                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1">Fecha de Ingreso</p>
                  <p className="text-on-surface">{asset.fecha_ingreso ? new Date(asset.fecha_ingreso).toLocaleDateString() : 'N/A'}</p>
                </div>

                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1">Valor Estimado</p>
                  <p className="text-on-surface font-mono font-semibold">{asset.valor ? `Bs. ${asset.valor}` : 'N/A'}</p>
                </div>
              </div>

              {asset.descripcion && (
                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1">Descripción / Características</p>
                  <div className="bg-surface-container-lowest p-3.5 rounded-lg border border-outline-variant text-on-surface text-sm">
                    {asset.descripcion}
                  </div>
                </div>
              )}

              {asset.observaciones && (
                <div>
                  <p className="text-on-surface-variant font-medium text-xs uppercase tracking-wider mb-1">Observaciones</p>
                  <div className="bg-surface-container-lowest p-3.5 rounded-lg border border-outline-variant text-on-surface text-sm">
                    {asset.observaciones}
                  </div>
                </div>
              )}

            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-surface-container-highest flex justify-between items-center bg-surface-bright rounded-b-xl">
          <div className="flex gap-2">
            {onEdit && (
              <button 
                onClick={() => { onClose(); onEdit(asset); }} 
                className="flex items-center gap-1.5 px-3 py-1.5 border border-outline rounded text-sm font-medium text-on-surface hover:bg-surface-container transition-colors"
              >
                <Edit2 size={16} /> Editar
              </button>
            )}
            {onDelete && (
              <button 
                onClick={() => { onClose(); onDelete(asset.id); }} 
                className="flex items-center gap-1.5 px-3 py-1.5 border border-error/30 text-error hover:bg-error-container/20 rounded text-sm font-medium transition-colors"
              >
                <Trash2 size={16} /> Eliminar
              </button>
            )}
          </div>
          
          <div className="flex gap-2">
            {onPrintQR && (
              <button 
                onClick={() => { onClose(); onPrintQR(asset); }} 
                className="flex items-center gap-1.5 px-4 py-1.5 bg-primary text-on-primary rounded text-sm font-medium hover:bg-primary/90 transition-colors shadow-sm"
              >
                <QrCode size={16} /> Imprimir QR
              </button>
            )}
            <button 
              onClick={onClose} 
              className="px-4 py-1.5 bg-surface-container text-on-surface rounded text-sm font-medium hover:bg-surface-container-high transition-colors"
            >
              Cerrar
            </button>
          </div>
        </div>

      </div>
    </div>
  );
};

export default AssetDetailsModal;
