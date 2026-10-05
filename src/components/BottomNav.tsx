import React from 'react';
import { Home, Search, LayoutDashboard, Store, Bot, User as UserIcon } from 'lucide-react';
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
    { label: t('logibot'), icon: Bot },
    { label: t('profile'), icon: UserIcon },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-30 shadow-lg">
      <div className="max-w-md mx-auto grid grid-cols-5 h-16">
        {tabs.map((tab, idx) => {
          const Icon = tab.icon;
          const isActive = currentTab === idx;
          return (
            <button
              key={tab.label + idx}
              onClick={() => onTabChange(idx)}
              className={`flex flex-col items-center justify-center gap-1 transition-colors cursor-pointer relative ${
                isActive ? 'text-emerald-700' : 'text-gray-400 hover:text-gray-600'
              }`}
            >
              <div
                className={`flex items-center justify-center w-10 h-7 rounded-full transition-all ${
                  isActive ? 'bg-emerald-100 text-emerald-800' : 'bg-transparent'
                }`}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'stroke-[2.3]' : 'stroke-2'}`} />
              </div>
              <span className={`text-[10px] font-medium tracking-tight truncate max-w-[64px] ${isActive ? 'font-bold' : ''}`}>
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
