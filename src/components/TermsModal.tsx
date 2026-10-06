import React, { useState } from 'react';
import { FileText, Users, Globe, ShieldCheck } from 'lucide-react';
import { useLanguage } from '../context/LanguageContext';
import { AppLanguage } from '../services/i18n';

interface TermsModalProps {
  onClose: () => void;
}

export const TermsModal: React.FC<TermsModalProps> = ({ onClose }) => {
  const { language, setLanguage, t } = useLanguage();
  const [activeModalLang, setActiveModalLang] = useState<AppLanguage>(language);

  const handleSwitchLanguage = (lang: AppLanguage) => {
    setActiveModalLang(lang);
    setLanguage(lang);
  };

  return (
    <div className="fixed inset-0 bg-gray-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-150">
      <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl border border-gray-100 p-6 relative max-h-[88vh] flex flex-col text-left">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-sm font-semibold cursor-pointer p-1"
        >
          ✕
        </button>

        {/* Header */}
        <div className="flex items-center gap-3 mb-3 pb-3 border-b border-gray-100">
          <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
            <FileText className="w-5 h-5" />
          </div>
          <div className="min-w-0 flex-1 pr-6">
            <h3 className="font-extrabold text-gray-900 text-base leading-tight">
              {t('terms_title')}
            </h3>
            <p className="text-[11px] text-gray-500 mt-0.5 truncate">
              {t('terms_subtitle')}
            </p>
          </div>
        </div>

        {/* Language Tabs Switcher inside Terms Modal */}
        <div className="flex items-center justify-between bg-gray-50 p-1.5 rounded-xl mb-3 border border-gray-200">
          <div className="flex items-center gap-1 text-[11px] font-bold text-gray-500 pl-1.5">
            <Globe className="w-3.5 h-3.5 text-emerald-600" />
            <span>Idioma / Language:</span>
          </div>
          <div className="flex items-center gap-1">
            {[
              { code: 'pt', label: 'Português', flag: '🇧🇷' },
              { code: 'en', label: 'English', flag: '🇺🇸' },
              { code: 'es', label: 'Español', flag: '🇪🇸' },
            ].map((item) => (
              <button
                key={item.code}
                type="button"
                onClick={() => handleSwitchLanguage(item.code as AppLanguage)}
                className={`px-2.5 py-1 rounded-lg text-xs font-bold transition cursor-pointer flex items-center gap-1 ${
                  activeModalLang === item.code
                    ? 'bg-white text-emerald-800 shadow-2xs border border-emerald-300'
                    : 'text-gray-500 hover:text-gray-800'
                }`}
              >
                <span>{item.flag}</span>
                <span>{item.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Scrollable Legal Body */}
        <div className="flex-1 overflow-y-auto space-y-4 text-xs text-gray-600 leading-relaxed pr-2">
          {/* Highlight Notice Card */}
          <div className="p-3 bg-amber-50 border border-amber-200 rounded-2xl text-amber-900 flex items-start gap-2.5">
            <Users className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div className="text-[11px] leading-relaxed">
              <strong className="block text-amber-950 font-bold mb-0.5">
                {t('terms_notice_highlight_title')}
              </strong>
              {t('terms_notice_highlight_desc')}
            </div>
          </div>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              {t('terms_sec1_title')}
            </h4>
            <p>
              {t('terms_sec1_p1')}
            </p>
            <p className="mt-1">
              {t('terms_sec1_p2')}
            </p>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              {t('terms_sec2_title')}
            </h4>
            <p>
              {t('terms_sec2_p1')}
            </p>
            <ul className="list-disc list-inside mt-1.5 space-y-1 text-gray-600">
              <li>{t('terms_sec2_item1')}</li>
              <li>{t('terms_sec2_item2')}</li>
              <li>{t('terms_sec2_item3')}</li>
            </ul>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              {t('terms_sec3_title')}
            </h4>
            <p>
              {t('terms_sec3_p1')}
            </p>
          </section>

          <section>
            <h4 className="font-bold text-gray-900 text-xs mb-1">
              {t('terms_sec4_title')}
            </h4>
            <p>
              {t('terms_sec4_p1')}
            </p>
          </section>
        </div>

        {/* Footer */}
        <div className="pt-4 mt-3 border-t border-gray-100 flex items-center justify-between">
          <span className="text-[11px] text-gray-400">
            {t('terms_updated_date')}
          </span>
          <button
            onClick={onClose}
            className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs transition cursor-pointer shadow-xs"
          >
            {t('terms_agree_btn')}
          </button>
        </div>
      </div>
    </div>
  );
};
