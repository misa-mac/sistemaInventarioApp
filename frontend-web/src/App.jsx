import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import InventoryPage from './pages/InventoryPage';
import ReportsPage from './pages/ReportsPage';
import AmbientesPage from './pages/AmbientesPage';
import UsuariosPage from './pages/UsuariosPage';
import DashboardPage from './pages/DashboardPage';
import ConfiguracionPage from './pages/ConfiguracionPage';
import HistorialPage from './pages/HistorialPage';
import api from './services/api';
import { LayoutDashboard, Monitor, LogOut, Settings, Bell, Search, Menu, FileText, Building, Shield, Users, AlertTriangle, Info, Clock } from 'lucide-react';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? children : <Navigate to="/login" />;
};

const Sidebar = () => {
  const location = useLocation();
  const { logout } = useAuth();

  const menuItems = [
    { path: '/', icon: <LayoutDashboard size={20} />, label: 'Panel de Control' },
    { path: '/inventario', icon: <Monitor size={20} />, label: 'Activos Fijos' },
    { path: '/ambientes', icon: <Building size={20} />, label: 'Ambientes' },
    { path: '/historial', icon: <Clock size={20} />, label: 'Movimientos' },
    { path: '/reportes', icon: <FileText size={20} />, label: 'Reportes' },
    { path: '/usuarios', icon: <Users size={20} />, label: 'Roles y Permisos' },
    { path: '/configuracion', icon: <Settings size={20} />, label: 'Configuración' },
  ];

  return (
    <aside className="w-64 bg-surface-container-lowest border-r border-surface-container-highest flex flex-col h-screen sticky top-0 hidden md:flex">
      
      {/* Brand */}
      <div className="h-16 px-6 flex items-center border-b border-surface-container-highest">
        <div className="flex items-center gap-3">
          <img 
            src="/logo.png" 
            alt="Logo ITBM" 
            className="w-8 h-8 object-contain"
            onError={(e) => {
              e.target.style.display = 'none';
              e.target.nextSibling.style.display = 'flex';
            }}
          />
          <div className="w-8 h-8 rounded bg-primary-container text-on-primary-container flex items-center justify-center font-bold text-sm hidden" style={{display: 'none'}}>
            IT
          </div>
          <span className="font-semibold text-on-surface tracking-tight leading-tight">
            Instituto<br/>
            <span className="text-xs text-primary font-bold">Bolivia Mar</span>
          </span>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto p-4 space-y-1">
        <div className="px-3 pb-2 text-label-caps text-on-surface-variant uppercase tracking-wider mb-2 mt-2">
          Administración
        </div>
        
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.label}
              to={item.path}
              className={`flex items-center gap-3 px-3 py-2 rounded-md transition-colors text-sm font-medium ${
                isActive 
                  ? 'bg-secondary-container/10 text-secondary' 
                  : 'text-on-surface-variant hover:bg-surface-container-low hover:text-on-surface'
              }`}
            >
              <span className={`${isActive ? 'text-secondary' : 'text-outline'}`}>
                {item.icon}
              </span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-surface-container-highest">
        <button 
          onClick={logout} 
          className="flex items-center gap-3 px-3 py-2 rounded-md w-full text-on-surface-variant hover:bg-error-container hover:text-on-error-container transition-colors text-sm font-medium"
        >
          <LogOut size={20} className="text-outline" />
          Cerrar Sesión
        </button>
      </div>
    </aside>
  );
};

const Header = () => {
  const { user } = useAuth();
  const [showNotifs, setShowNotifs] = useState(false);
  const [notifs, setNotifs] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchNotifs = async () => {
    if (!user) return;
    try {
      const res = await api.get('/notificaciones');
      setNotifs(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchNotifs();
    // Poll notifications every minute
    const interval = setInterval(fetchNotifs, 60000);
    return () => clearInterval(interval);
  }, [user]);

  const handleMarkAsRead = async () => {
    if (notifs.length === 0) return;
    setLoading(true);
    try {
      await api.post('/notificaciones/marcar-leidas');
      setNotifs([]);
      setShowNotifs(false);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString) => {
    const d = new Date(dateString);
    return isNaN(d.getTime()) ? 'Reciente' : d.toLocaleDateString('es-ES', { month: 'short', day: 'numeric', hour: '2-digit', minute:'2-digit' });
  };

  return (
    <header className="h-16 bg-surface-container-lowest border-b border-surface-container-highest flex items-center justify-between px-4 sm:px-6 sticky top-0 z-40">
      <div className="flex items-center gap-4">
        <button className="md:hidden text-on-surface-variant p-2 -ml-2 rounded hover:bg-surface-container-low">
          <Menu size={20} />
        </button>
      </div>
      
      <div className="flex items-center gap-4">
        {/* Notificaciones */}
        <div className="relative">
          <button 
            onClick={() => { setShowNotifs(!showNotifs); if (!showNotifs) fetchNotifs(); }}
            className="text-on-surface-variant relative p-2 rounded-full hover:bg-surface-container-low transition-colors"
          >
            <Bell size={20} />
            {notifs.length > 0 && (
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-error rounded-full animate-pulse flex items-center justify-center"></span>
            )}
          </button>

          {showNotifs && (
            <div className="absolute right-0 mt-2 w-80 bg-surface-container-lowest border border-surface-container-highest rounded-xl shadow-lg overflow-hidden animate-fade-in z-50">
              <div className="p-4 border-b border-surface-container-highest bg-surface-bright flex justify-between items-center">
                <h3 className="font-medium text-on-surface">Notificaciones</h3>
                {notifs.length > 0 && (
                  <button onClick={handleMarkAsRead} disabled={loading} className="text-xs text-primary hover:underline font-medium">
                    Marcar leídas
                  </button>
                )}
              </div>
              <div className="max-h-80 overflow-y-auto">
                {notifs.length === 0 ? (
                  <div className="p-6 text-center text-on-surface-variant text-sm flex flex-col items-center gap-2">
                    <Bell size={24} className="text-outline-variant" />
                    No tienes alertas pendientes.
                  </div>
                ) : (
                  notifs.map(n => (
                    <div key={n.id} className="p-4 border-b border-surface-container-highest last:border-0 hover:bg-surface-container/50 transition-colors cursor-default">
                      <div className="flex gap-3">
                        <div className={`mt-0.5 w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${n.tipo === 'warning' ? 'bg-amber-100 text-amber-600' : n.tipo === 'error' ? 'bg-error-container text-on-error-container' : 'bg-primary-container text-primary'}`}>
                          {n.tipo === 'warning' ? <AlertTriangle size={14} /> : n.tipo === 'error' ? <Shield size={14} /> : <Info size={14} />}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-on-surface mb-0.5">{n.titulo}</p>
                          <p className="text-xs text-on-surface-variant leading-relaxed">{n.mensaje}</p>
                          <p className="text-[10px] text-on-surface-variant/70 mt-2 font-medium uppercase tracking-wider">{formatDate(n.created_at)}</p>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>

        <div className="h-6 w-px bg-surface-container-highest"></div>
        <div className="flex items-center gap-3">
          <div className="text-right hidden sm:block">
            <div className="text-sm font-medium text-on-surface">{user?.nombre || 'Usuario'}</div>
            <div className="text-xs text-on-surface-variant capitalize">{user?.rol || 'Administrador'}</div>
          </div>
          <div className="w-8 h-8 rounded-full bg-primary-fixed text-on-primary-fixed flex items-center justify-center font-bold text-sm">
            {(user?.nombre || 'A').charAt(0).toUpperCase()}
          </div>
        </div>
      </div>
    </header>
  );
};

const DashboardLayout = ({ children }) => {
  return (
    <div className="flex h-screen bg-surface overflow-hidden">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <div className="max-w-5xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
};

function AppContent() {
  const { isAuthenticated } = useAuth();

  return (
    <Router>
      <Routes>
        <Route path="/login" element={isAuthenticated ? <Navigate to="/" /> : <LoginPage />} />
        <Route 
          path="/inventario" 
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <InventoryPage />
              </DashboardLayout>
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/ambientes" 
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <AmbientesPage />
              </DashboardLayout>
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/reportes" 
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <ReportsPage />
              </DashboardLayout>
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/usuarios" 
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <UsuariosPage />
              </DashboardLayout>
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/configuracion" 
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <ConfiguracionPage />
              </DashboardLayout>
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/historial" 
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <HistorialPage />
              </DashboardLayout>
            </ProtectedRoute>
          } 
        />
        <Route 
          path="/" 
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <DashboardPage />
              </DashboardLayout>
            </ProtectedRoute>
          } 
        />
      </Routes>
    </Router>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
