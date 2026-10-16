import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import { Lock, Mail, Server } from 'lucide-react';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const response = await api.post('/auth/login', { email, password });
      login(response.data.token, response.data.user);
      navigate('/inventario');
    } catch (err) {
      setError(err.response?.data?.error || 'Credenciales incorrectas');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-surface flex flex-col justify-center items-center p-4">
      
      <div className="bg-surface-container-lowest p-8 rounded-xl border border-surface-container-highest shadow-sm w-full max-w-md">
        
        <div className="mb-8 flex flex-col items-center sm:items-start text-center sm:text-left">
          <img 
            src="/logo.png" 
            alt="Logo Institución" 
            className="h-16 w-auto object-contain mb-4"
            onError={(e) => {
              e.target.style.display = 'none';
              e.target.nextSibling.style.display = 'flex';
            }}
          />
          <div className="h-14 w-14 bg-primary-container text-inverse-primary flex items-center justify-center rounded-lg mb-4 hidden" style={{display: 'none'}}>
            <Server size={28} />
          </div>
          <h2 className="font-h2 text-h2 text-on-surface mb-2 tracking-tight">Instituto ITBM</h2>
          <p className="text-on-surface-variant text-body-sm">Autenticación de Inventario</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-6">
          
          <div className="space-y-2">
            <label className="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-wider block">
              Correo Institucional
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Mail size={18} className="text-outline" />
              </div>
              <input
                type="email"
                className="w-full pl-10 pr-4 py-2 bg-surface-container-lowest border border-outline-variant rounded focus:border-secondary focus:ring-2 focus:ring-secondary/20 focus:outline-none transition-all text-on-surface text-body-main"
                placeholder="usuario@itbm.edu"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
          </div>
          
          <div className="space-y-2">
            <label className="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-wider block">
              Contraseña
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Lock size={18} className="text-outline" />
              </div>
              <input
                type="password"
                className="w-full pl-10 pr-4 py-2 bg-surface-container-lowest border border-outline-variant rounded focus:border-secondary focus:ring-2 focus:ring-secondary/20 focus:outline-none transition-all text-on-surface text-body-main"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </div>

          {error && (
            <div className="bg-error-container text-on-error-container p-3 rounded text-sm text-center font-medium">
              {error}
            </div>
          )}

          <button 
            type="submit" 
            className="w-full bg-secondary text-on-secondary py-2.5 rounded font-medium hover:bg-secondary/90 transition-colors focus:ring-2 focus:ring-offset-2 focus:ring-secondary"
            disabled={loading}
          >
            {loading ? 'Verificando...' : 'Acceder al Sistema'}
          </button>
          
        </form>
      </div>
      
      <div className="mt-8 text-center text-outline text-xs">
        <p>Sistema de Inventario ITBM v2.0</p>
        <p className="mt-1">© 2026 Lab Precision Systems. All rights reserved.</p>
      </div>
      
    </div>
  );
};

export default LoginPage;
