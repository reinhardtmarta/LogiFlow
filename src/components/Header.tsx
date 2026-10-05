import React, { useState } from 'react';
import { User } from '../types';
import { store } from '../services/store';
import { Sparkles, UserCheck, LogOut, ArrowRightLeft, ShieldCheck, ShoppingBag } from 'lucide-react';

interface HeaderProps {
  user: User | null;
  onRefreshAi: () => void;
  onOpenAuth: () => void;
}

export const Header: React.FC<HeaderProps> = ({ user, onRefreshAi, onOpenAuth }) => {
  const [showUserMenu, setShowUserMenu] = useState(false);
  const allUsers = store.getAllUsers();

  return (
    <header className="bg-emerald-700 text-white shadow-md sticky top-0 z-30">
      <div className="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
            <span className="text-xl font-black text-emerald-200">🌱</span>
          </div>
          <div>
            <h1 className="font-bold text-lg leading-tight tracking-tight flex items-center gap-1.5">
              LogiFlow
              <span className="text-[10px] font-semibold bg-emerald-800/80 px-1.5 py-0.5 rounded text-emerald-200 uppercase tracking-wider">
                Food Rescue
              </span>
            </h1>
            <p className="text-xs text-emerald-100/80 hidden sm:block">
              Marketplace sustentável contra o desperdício
            </p>
          </div>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            onClick={onRefreshAi}
            title="Gerar Dica da IA"
            className="p-2 rounded-lg bg-emerald-800/50 hover:bg-emerald-800 transition text-emerald-100 flex items-center gap-1.5 text-xs font-medium cursor-pointer"
          >
            <Sparkles className="w-4 h-4 text-amber-300 animate-pulse" />
            <span className="hidden sm:inline">Dica Gemma</span>
          </button>

          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg bg-emerald-800/60 hover:bg-emerald-800 transition text-white text-xs font-medium cursor-pointer border border-emerald-600/50"
            >
              <div className="w-6 h-6 rounded-full bg-emerald-500/80 flex items-center justify-center text-xs font-bold">
                {user ? user.name.charAt(0) : '?'}
              </div>
              <span className="max-w-[100px] truncate hidden md:inline">
                {user ? user.name : 'Entrar'}
              </span>
              <span className="text-[10px] bg-white/20 px-1.5 py-0.5 rounded">
                {user?.isSeller ? 'Vendedor' : 'Consumidor'}
              </span>
            </button>

            {showUserMenu && (
              <div className="absolute right-0 mt-2 w-72 bg-white text-gray-800 rounded-xl shadow-xl border border-gray-100 py-2 z-50 animate-in fade-in zoom-in-95 duration-100">
                {user ? (
                  <>
                    <div className="px-4 py-2 border-b border-gray-100">
                      <p className="text-xs text-gray-400 font-medium">Conectado como</p>
                      <p className="font-semibold text-sm text-gray-900 truncate">{user.name}</p>
                      <p className="text-xs text-gray-500 truncate">{user.email}</p>
                      <span className="inline-block mt-1 px-2 py-0.5 bg-emerald-50 text-emerald-700 text-[11px] font-medium rounded-full">
                        {user.isSeller ? '🏪 Perfil Produtor / Vendedor' : '🛒 Perfil Consumidor'}
                      </span>
                    </div>

                    <div className="px-3 py-2 border-b border-gray-100">
                      <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider mb-1.5 px-1 flex items-center gap-1">
                        <ArrowRightLeft className="w-3 h-3" /> Alternar Conta de Teste
                      </p>
                      {allUsers.map((u) => (
                        <button
                          key={u.id}
                          onClick={() => {
                            store.switchUser(u.id);
                            setShowUserMenu(false);
                          }}
                          className={`w-full text-left px-2 py-1.5 rounded-lg text-xs flex items-center justify-between hover:bg-gray-50 transition cursor-pointer ${
                            u.id === user.id ? 'bg-emerald-50 text-emerald-800 font-semibold' : 'text-gray-700'
                          }`}
                        >
                          <span className="truncate flex items-center gap-1.5">
                            {u.isSeller ? <ShoppingBag className="w-3.5 h-3.5 text-emerald-600" /> : <UserCheck className="w-3.5 h-3.5 text-blue-600" />}
                            {u.name}
                          </span>
                          <span className="text-[10px] text-gray-400 shrink-0">
                            {u.isSeller ? 'Produtor' : 'Consumidor'}
                          </span>
                        </button>
                      ))}
                    </div>

                    <button
                      onClick={() => {
                        store.signOut();
                        setShowUserMenu(false);
                        onOpenAuth();
                      }}
                      className="w-full text-left px-4 py-2 text-xs text-red-600 hover:bg-red-50 flex items-center gap-2 cursor-pointer font-medium"
                    >
                      <LogOut className="w-3.5 h-3.5" /> Sair da conta
                    </button>
                  </>
                ) : (
                  <div className="p-3">
                    <button
                      onClick={() => {
                        setShowUserMenu(false);
                        onOpenAuth();
                      }}
                      className="w-full py-2 bg-emerald-600 text-white font-medium text-xs rounded-lg hover:bg-emerald-700 transition"
                    >
                      Fazer Login / Cadastrar
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
