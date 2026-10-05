import React, { useState } from 'react';
import { store } from '../services/store';
import { User } from '../types';
import { Leaf, Lock, Mail, User as UserIcon, Phone, MapPin, Store, AlertCircle } from 'lucide-react';

interface AuthScreenProps {
  onSuccess: (user: User) => void;
  onClose?: () => void;
}

export const AuthScreen: React.FC<AuthScreenProps> = ({ onSuccess, onClose }) => {
  const [isRegister, setIsRegister] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [isSeller, setIsSeller] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    if (!email.trim() || !password.trim()) {
      setErrorMsg('Por favor, preencha todos os campos.');
      return;
    }

    setIsLoading(true);
    setTimeout(() => {
      try {
        const user = store.signIn(email);
        onSuccess(user);
      } catch (err: unknown) {
        setErrorMsg(err instanceof Error ? err.message : 'Erro ao fazer login.');
      } finally {
        setIsLoading(false);
      }
    }, 400);
  };

  const handleRegister = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    if (!name.trim() || !email.trim() || !password.trim()) {
      setErrorMsg('Por favor, preencha todos os campos obrigatórios (*).');
      return;
    }
    if (password.length < 6) {
      setErrorMsg('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setIsLoading(true);
    setTimeout(() => {
      try {
        const user = store.signUp({
          name,
          email,
          password,
          phone,
          address,
          isSeller,
        });
        onSuccess(user);
      } catch (err: unknown) {
        setErrorMsg(err instanceof Error ? err.message : 'Erro no cadastro.');
      } finally {
        setIsLoading(false);
      }
    }, 400);
  };

  const handleQuickLogin = (role: 'seller' | 'consumer') => {
    const all = store.getAllUsers();
    const target = all.find((u) => (role === 'seller' ? u.isSeller : !u.isSeller));
    if (target) {
      store.setCurrentUser(target);
      onSuccess(target);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-50 flex items-center justify-center p-4 z-50 overflow-y-auto">
      <div className="bg-white w-full max-w-md rounded-3xl shadow-xl border border-gray-100 p-6 sm:p-8 my-auto animate-in fade-in zoom-in-95 duration-150 relative">
        {onClose && (
          <button
            onClick={onClose}
            className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-sm font-semibold cursor-pointer"
          >
            Fechar ✕
          </button>
        )}

        {/* Logo and Branding matching Flutter login_screen */}
        <div className="text-center mb-6">
          <div className="w-16 h-16 rounded-2xl bg-emerald-100/70 text-emerald-600 flex items-center justify-center mx-auto mb-2 shadow-xs">
            <Leaf className="w-9 h-9" />
          </div>
          <h1 className="text-3xl font-extrabold text-emerald-700 tracking-tight">
            LogiFlow
          </h1>
          <p className="text-xs font-medium text-gray-500 mt-0.5">
            AI-Driven Food Rescue & Inventory
          </p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-xl text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {!isRegister ? (
          /* LOGIN FORM */
          <form onSubmit={handleLogin} className="space-y-3.5">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Email
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="seu@email.com"
                  className="w-full pl-10 pr-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full mt-2 py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-sm shadow-md transition cursor-pointer disabled:opacity-50"
            >
              {isLoading ? 'Conectando...' : 'Login'}
            </button>

            <div className="pt-2 text-center">
              <button
                type="button"
                onClick={() => {
                  setErrorMsg(null);
                  setIsRegister(true);
                }}
                className="text-xs text-emerald-700 hover:text-emerald-800 font-semibold cursor-pointer"
              >
                Don't have an account? Create one
              </button>
            </div>

            {/* Quick Demo Acccess */}
            <div className="pt-4 border-t border-gray-100 mt-4 text-center">
              <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider mb-2">
                Acesso Rápido para Avaliação
              </p>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => handleQuickLogin('seller')}
                  className="p-2 rounded-xl border border-emerald-200 bg-emerald-50/70 hover:bg-emerald-100 text-emerald-900 text-xs font-semibold transition cursor-pointer flex items-center justify-center gap-1.5"
                >
                  <Store className="w-3.5 h-3.5" />
                  <span>Produtor</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleQuickLogin('consumer')}
                  className="p-2 rounded-xl border border-blue-200 bg-blue-50/70 hover:bg-blue-100 text-blue-900 text-xs font-semibold transition cursor-pointer flex items-center justify-center gap-1.5"
                >
                  <UserIcon className="w-3.5 h-3.5" />
                  <span>Consumidor</span>
                </button>
              </div>
            </div>
          </form>
        ) : (
          /* REGISTER FORM */
          <form onSubmit={handleRegister} className="space-y-3">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Full Name *
              </label>
              <div className="relative">
                <UserIcon className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Nome completo ou da Fazenda"
                  className="w-full pl-10 pr-3.5 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Email Address *
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="seu@email.com"
                  className="w-full pl-10 pr-3.5 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Create Password *
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Pelo menos 6 caracteres"
                  className="w-full pl-10 pr-3.5 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Phone Number
              </label>
              <div className="relative">
                <Phone className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="(11) 98765-4321"
                  className="w-full pl-10 pr-3.5 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Address / Location
              </label>
              <div className="relative">
                <MapPin className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Cidade, Bairro ou Região"
                  className="w-full pl-10 pr-3.5 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
                />
              </div>
            </div>

            <div className="p-3 bg-emerald-50/70 border border-emerald-200 rounded-xl">
              <label className="flex items-center justify-between cursor-pointer">
                <div>
                  <span className="block text-xs font-bold text-emerald-950">
                    I am a Seller / Producer
                  </span>
                  <span className="block text-[11px] text-emerald-800/80">
                    I want to sell or donate products
                  </span>
                </div>
                <input
                  type="checkbox"
                  checked={isSeller}
                  onChange={(e) => setIsSeller(e.target.checked)}
                  className="w-5 h-5 accent-emerald-600 rounded"
                />
              </label>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full mt-2 py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-sm shadow-md transition cursor-pointer disabled:opacity-50"
            >
              {isLoading ? 'Criando conta...' : 'Create Account'}
            </button>

            <div className="pt-2 text-center">
              <button
                type="button"
                onClick={() => {
                  setErrorMsg(null);
                  setIsRegister(false);
                }}
                className="text-xs text-emerald-700 hover:text-emerald-800 font-semibold cursor-pointer"
              >
                Already have an account? Login
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
