import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { i18n, AppLanguage } from '../services/i18n';

interface LanguageContextType {
  language: AppLanguage;
  setLanguage: (lang: AppLanguage) => void;
  t: (key: any) => string;
}

const LanguageContext = createContext<LanguageContextType>({
  language: 'pt',
  setLanguage: () => {},
  t: (key: string) => key,
});

export const LanguageProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<AppLanguage>(i18n.getLanguage());

  useEffect(() => {
    return i18n.subscribe((newLang) => {
      setLanguageState(newLang);
    });
  }, []);

  const setLanguage = (lang: AppLanguage) => {
    i18n.setLanguage(lang);
    setLanguageState(lang);
  };

  const t = (key: any) => {
    return i18n.t(key);
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => useContext(LanguageContext);
