import React from 'react';
import { Home, Search, LayoutDashboard, Store, Compass, User as UserIcon } from 'lucide-react';
import { useLanguage } from '../context/LanguageContext';

interface BottomNavProps {
  currentTab: number;
  onTabChange: (index: number) => void;
  isSeller: boolean;
}

export const BottomNav: React.FC<BottomNavProps> = ({ currentTab, onTabChange, isSeller }) => {
  const { t } = useLanguage();

  const tabs = [
    { label: t('feed'), icon: Home },
    { label: t('search'), icon: Search },
    { label: isSeller ? t('dashboard') : t('marketplace'), icon: isSeller ? LayoutDashboard : Store },
    { label: t('explore'), icon: Compass },
    { label: t('profile'), icon: UserIcon },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-emerald-800 border-t border-emerald-600/80 z-30 shadow-2xl">
      <div className="max-w-md mx-auto grid grid-cols-5 h-16 px-1">
        {tabs.map((tab, idx) => {
          const Icon = tab.icon;
          const isActive = currentTab === idx;
          return (
            <button
              key={tab.label + idx}
              onClick={() => onTabChange(idx)}
              className={`flex flex-col items-center justify-center gap-1 transition-all cursor-pointer relative py-1 ${
                isActive ? 'text-white' : 'text-emerald-100 hover:text-white'
              }`}
            >
              <div
                className={`flex items-center justify-center w-10 h-7 rounded-full transition-all ${
                  isActive ? 'bg-white text-emerald-800 shadow-md ring-2 ring-white/40' : 'bg-transparent text-emerald-100'
                }`}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'stroke-[2.5]' : 'stroke-2'}`} />
              </div>
              <span className={`text-[10px] tracking-tight truncate max-w-[64px] ${isActive ? 'font-black text-white drop-shadow-xs' : 'font-bold text-emerald-100'}`}>
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
