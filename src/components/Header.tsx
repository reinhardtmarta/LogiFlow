import React, { useState } from 'react';
import { User } from '../types';
import { store } from '../services/store';
import { AccountDeletionModal } from './AccountDeletionModal';
import { useLanguage } from '../context/LanguageContext';
import { 
  Sparkles, 
  LogOut, 
  User as UserIcon, 
  Store, 
  ShoppingBag, 
  UserX,
  Trash2
} from 'lucide-react';

interface HeaderProps {
  user: User | null;
  onRefreshAi: () => void;
  onOpenAuth: () => void;
}

export const Header: React.FC<HeaderProps> = ({ user, onRefreshAi, onOpenAuth }) => {
  const { t } = useLanguage();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  const toggleSellerMode = async () => {
    if (!user) return;
    await store.updateUserProfile({ isSeller: !user.isSeller });
    setShowUserMenu(false);
  };

  return (
    <>
      <header className="bg-emerald-700 text-white shadow-md sticky top-0 z-30">
        <div className="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-white/15 flex items-center justify-center border border-white/20">
              <span className="text-xl font-black text-emerald-200">🌱</span>
            </div>
            <div>
              <h1 className="font-bold text-lg leading-tight tracking-tight flex items-center gap-1.5">
                {t('app_name')}
                <span className="text-[10px] font-semibold bg-emerald-800/80 px-1.5 py-0.5 rounded text-emerald-200 uppercase tracking-wider">
                  {t('app_tagline')}
                </span>
              </h1>
              <p className="text-xs text-emerald-100/80 hidden sm:block">
                {t('header_subtitle')}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              onClick={onRefreshAi}
              title={t('quick_tip_btn')}
              className="p-2 rounded-lg bg-emerald-800/50 hover:bg-emerald-800 transition text-emerald-100 flex items-center gap-1.5 text-xs font-medium cursor-pointer"
            >
              <Sparkles className="w-4 h-4 text-amber-300" />
              <span className="hidden sm:inline">{t('quick_tip_btn')}</span>
            </button>

            <div className="relative">
              {user ? (
                <button
                  onClick={() => setShowUserMenu(!showUserMenu)}
                  className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg bg-emerald-800/60 hover:bg-emerald-800 transition text-white text-xs font-medium cursor-pointer border border-emerald-600/50"
                >
                  <div className="w-6 h-6 rounded-full bg-emerald-500/80 flex items-center justify-center text-xs font-bold">
                    {user.name ? user.name.charAt(0).toUpperCase() : 'U'}
                  </div>
                  <span className="max-w-[110px] truncate hidden md:inline">
                    {user.name}
                  </span>
                  <span className="text-[10px] bg-white/20 px-1.5 py-0.5 rounded">
                    {user.isSeller ? t('producer_label') : t('consumer_label')}
                  </span>
                </button>
              ) : (
                <button
                  onClick={onOpenAuth}
                  className="px-3.5 py-1.5 rounded-xl bg-white text-emerald-800 hover:bg-emerald-50 font-bold text-xs shadow-xs transition cursor-pointer flex items-center gap-1.5"
                >
                  <UserIcon className="w-3.5 h-3.5" />
                  <span>{t('login_btn')}</span>
                </button>
              )}

              {showUserMenu && user && (
                <div className="absolute right-0 mt-2 w-72 bg-white text-gray-800 rounded-2xl shadow-2xl border border-gray-100 py-2 z-50 animate-in fade-in zoom-in-95 duration-100">
                  <div className="px-4 py-2 border-b border-gray-100">
                    <p className="text-xs text-gray-400 font-medium">{t('account_auth')}</p>
                    <p className="font-semibold text-sm text-gray-900 truncate">{user.name}</p>
                    <p className="text-xs text-gray-500 truncate">{user.email}</p>
                    <span className="inline-block mt-1 px-2 py-0.5 bg-emerald-50 text-emerald-700 text-[11px] font-semibold rounded-full border border-emerald-200">
                      {user.isSeller ? t('producer_mode') : t('consumer_mode')}
                    </span>
                  </div>

                  <div className="px-3 py-2 border-b border-gray-100">
                    <button
                      onClick={toggleSellerMode}
                      className="w-full text-left px-3 py-2 rounded-xl text-xs font-semibold hover:bg-emerald-50 text-emerald-900 transition cursor-pointer flex items-center justify-between"
                    >
                      <span className="flex items-center gap-2">
                        {user.isSeller ? <ShoppingBag className="w-4 h-4 text-blue-600" /> : <Store className="w-4 h-4 text-emerald-600" />}
                        <span>{user.isSeller ? t('switch_to_consumer') : t('switch_to_producer')}</span>
                      </span>
                      <span className="text-[10px] bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded">
                        {t('switch_role_badge')}
                      </span>
                    </button>
                  </div>

                  <div className="px-3 py-1.5 border-b border-gray-100">
                    <button
                      onClick={() => {
                        setShowUserMenu(false);
                        setShowDeleteModal(true);
                      }}
                      className="w-full text-left px-3 py-2 rounded-xl text-xs font-semibold text-gray-700 hover:text-red-700 hover:bg-red-50 transition cursor-pointer flex items-center gap-2"
                    >
                      <UserX className="w-4 h-4 text-gray-400 group-hover:text-red-600" />
                      <span>{t('manage_privacy_lgpd')}</span>
                    </button>
                  </div>

                  <button
                    onClick={() => {
                      store.signOut();
                      setShowUserMenu(false);
                    }}
                    className="w-full text-left px-4 py-2 text-xs text-red-600 hover:bg-red-50 flex items-center gap-2 cursor-pointer font-medium"
                  >
                    <LogOut className="w-3.5 h-3.5" /> {t('logout_btn')}
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Account / Data Deletion Modal */}
      {showDeleteModal && user && (
        <AccountDeletionModal
          user={user}
          onClose={() => setShowDeleteModal(false)}
          onDeleted={(msg) => {
            alert(msg);
          }}
        />
      )}
    </>
  );
};
