import React, { useState, useEffect } from 'react';
import { User } from '../types';
import { store } from '../services/store';
import { AccountDeletionModal } from '../components/AccountDeletionModal';
import { TermsModal } from '../components/TermsModal';
import { useLanguage } from '../context/LanguageContext';
import { AppLanguage } from '../services/i18n';
import { 
  User as UserIcon, 
  MapPin, 
  Phone, 
  Store, 
  ShoppingBag, 
  Save, 
  ShieldCheck, 
  LogOut, 
  FileText, 
  Trash2, 
  Loader2, 
  CheckCircle2, 
  Languages,
  AlertCircle
} from 'lucide-react';

interface UserProfileScreenProps {
  user: User | null;
  onOpenAuth: () => void;
  onOpenUpgrade: () => void;
}

export const UserProfileScreen: React.FC<UserProfileScreenProps> = ({
  user,
  onOpenAuth,
  onOpenUpgrade,
}) => {
  const { t, language, setLanguage } = useLanguage();
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [isSeller, setIsSeller] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showTermsModal, setShowTermsModal] = useState(false);

  useEffect(() => {
    if (user) {
      setName(user.name || '');
      setPhone(user.phone || '');
      setAddress(user.address || '');
      setIsSeller(Boolean(user.isSeller));
    }
  }, [user]);

  if (!user || user.id === 'guest') {
    return (
      <div className="pb-28 pt-8 max-w-md mx-auto px-4 text-center">
        <div className="w-16 h-16 rounded-3xl bg-emerald-100 text-emerald-700 flex items-center justify-center mx-auto mb-4 shadow-sm">
          <UserIcon className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-extrabold text-gray-900 mb-1">
          {t('profile_access_title')}
        </h2>
        <p className="text-xs text-gray-500 mb-6 max-w-xs mx-auto">
          {t('profile_access_subtitle')}
        </p>

        <button
          onClick={onOpenAuth}
          className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-2xl text-sm shadow-md transition cursor-pointer flex items-center justify-center gap-2"
        >
          <UserIcon className="w-4 h-4" />
          <span>{t('profile_login_google_btn')}</span>
        </button>
      </div>
    );
  }

  const sub = store.getSubscription(user.id);

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    setIsSaving(true);
    setSaveSuccess(false);

    try {
      await store.updateUserProfile({
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        isSeller,
      });

      setSaveSuccess(true);
      setSaveError(null);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err: any) {
      setSaveError('Error: ' + (err.message || 'Please try again.'));
      setTimeout(() => setSaveError(null), 4000);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="pb-28 pt-3 max-w-xl mx-auto px-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-xl font-extrabold text-gray-900 tracking-tight">
            {t('profile_title')}
          </h2>
          <p className="text-xs text-gray-500">
            {t('profile_subtitle')}
          </p>
        </div>
        <div className="w-10 h-10 rounded-full bg-emerald-600 text-white flex items-center justify-center font-bold text-sm shadow-xs">
          {name.charAt(0).toUpperCase() || 'U'}
        </div>
      </div>

      {/* Account Info Pill */}
      <div className="bg-white rounded-2xl p-4 border border-gray-200 shadow-xs mb-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold text-xs">
              <ShieldCheck className="w-4 h-4 text-emerald-600" />
            </div>
            <div>
              <p className="text-xs font-bold text-gray-900">{name || 'Usuário'}</p>
              <p className="text-[11px] text-gray-500">{user.email}</p>
            </div>
          </div>
          <span className="text-[10px] bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full">
            {isSeller ? t('profile_user_role_producer') : t('profile_user_role_consumer')}
          </span>
        </div>

        {/* Capacity / Package Status */}
        <div className="pt-2.5 border-t border-gray-100 flex items-center justify-between text-xs">
          <div>
            <span className="text-gray-500">{t('stock_capacity_label')}</span>{' '}
            <strong className="text-emerald-800">{sub.productLimit} {t('itemsCount')}</strong>
          </div>
          <button
            type="button"
            onClick={onOpenUpgrade}
            className="text-[11px] font-bold text-emerald-700 hover:text-emerald-800 underline cursor-pointer"
          >
            {t('recharge_capacity_btn')}
          </button>
        </div>
      </div>

      {/* Form: Add or Alter User Data */}
      <form onSubmit={handleSaveProfile} className="bg-white rounded-2xl p-5 border border-gray-200 shadow-sm space-y-4 mb-4">
        <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2">
          <span>{t('edit_info_title')}</span>
        </h3>

        {saveSuccess && (
          <div className="p-3 bg-emerald-50 border border-emerald-300 text-emerald-800 rounded-xl text-xs flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            <span>{t('data_saved_success')}</span>
          </div>
        )}

        {saveError && (
          <div className="p-3 bg-red-50 border border-red-300 text-red-800 rounded-xl text-xs flex items-center gap-2 animate-in fade-in">
            <AlertCircle className="w-4 h-4 text-red-600 shrink-0" />
            <span>{saveError}</span>
          </div>
        )}

        {/* Name Input */}
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1">
            {t('display_name_label')}
          </label>
          <div className="relative">
            <UserIcon className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={t('display_name_placeholder')}
              className="w-full pl-10 pr-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
            />
          </div>
        </div>

        {/* Phone / WhatsApp */}
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1">
            {t('phone_label')}
          </label>
          <div className="relative">
            <Phone className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="(11) 98765-4321"
              className="w-full pl-10 pr-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
            />
          </div>
          <p className="text-[10px] text-gray-400 mt-1">
            {t('phone_hint')}
          </p>
        </div>

        {/* Address / Location */}
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1">
            {t('address_label')}
          </label>
          <div className="relative">
            <MapPin className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Ex.: Rua Augusta, 500, Consolação, São Paulo - SP"
              className="w-full pl-10 pr-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
            />
          </div>
          <p className="text-[10px] text-gray-400 mt-1">
            {t('address_hint')}
          </p>
        </div>

        {/* Direct Mode Switcher Widget */}
        <div className="p-4 bg-emerald-50/70 border border-emerald-200 rounded-2xl space-y-2">
          <label className="block text-xs font-bold text-emerald-950 mb-1">
            {t('profile_mode_selection_label')}
          </label>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            <button
              type="button"
              onClick={async () => {
                setIsSeller(false);
                await store.updateUserProfile({ isSeller: false });
                setToastMessage(t('profile_consumer_activated_toast'));
                setTimeout(() => setToastMessage(null), 3000);
              }}
              className={`p-3 rounded-xl border text-left transition cursor-pointer flex items-start gap-2.5 ${
                !isSeller
                  ? 'bg-white border-emerald-600 shadow-sm ring-2 ring-emerald-500/20'
                  : 'bg-white/60 border-gray-200 hover:bg-white'
              }`}
            >
              <div className={`p-2 rounded-lg shrink-0 ${!isSeller ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-500'}`}>
                <ShoppingBag className="w-5 h-5" />
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="font-bold text-xs text-gray-900">{t('profile_mode_consumer_title')}</span>
                  {!isSeller && <span className="text-[9px] bg-blue-100 text-blue-800 font-bold px-1.5 py-0.2 rounded-full">{t('profile_mode_active_badge')}</span>}
                </div>
                <p className="text-[11px] text-gray-500 mt-0.5 leading-snug">
                  {t('profile_mode_consumer_desc')}
                </p>
              </div>
            </button>

            <button
              type="button"
              onClick={async () => {
                setIsSeller(true);
                await store.updateUserProfile({ isSeller: true });
                setToastMessage(t('profile_producer_activated_toast'));
                setTimeout(() => setToastMessage(null), 3000);
              }}
              className={`p-3 rounded-xl border text-left transition cursor-pointer flex items-start gap-2.5 ${
                isSeller
                  ? 'bg-white border-emerald-600 shadow-sm ring-2 ring-emerald-500/20'
                  : 'bg-white/60 border-gray-200 hover:bg-white'
              }`}
            >
              <div className={`p-2 rounded-lg shrink-0 ${isSeller ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-500'}`}>
                <Store className="w-5 h-5" />
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="font-bold text-xs text-gray-900">{t('profile_mode_producer_title')}</span>
                  {isSeller && <span className="text-[9px] bg-emerald-100 text-emerald-800 font-bold px-1.5 py-0.2 rounded-full">{t('profile_mode_active_badge')}</span>}
                </div>
                <p className="text-[11px] text-gray-500 mt-0.5 leading-snug">
                  {t('profile_mode_producer_desc')}
                </p>
              </div>
            </button>
          </div>
        </div>

        {/* Language Selection - Auto detected from Google */}
        <div className="p-3.5 bg-gray-50 border border-gray-200 rounded-xl space-y-2">
          <div className="flex items-center justify-between">
            <label className="text-xs font-bold text-gray-800 flex items-center gap-1.5">
              <Languages className="w-4 h-4 text-emerald-600" />
              <span>{t('languageSetting')}</span>
            </label>
            <span className="text-[10px] text-gray-400">
              Google Locale
            </span>
          </div>

          <div className="grid grid-cols-3 gap-2">
            {[
              { code: 'pt', label: 'Português', flag: '🇧🇷' },
              { code: 'en', label: 'English', flag: '🇺🇸' },
              { code: 'es', label: 'Español', flag: '🇪🇸' },
            ].map((langItem) => (
              <button
                key={langItem.code}
                type="button"
                onClick={() => setLanguage(langItem.code as AppLanguage)}
                className={`py-2 px-2 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition cursor-pointer ${
                  language === langItem.code
                    ? 'border-emerald-600 bg-white text-emerald-800 shadow-xs ring-2 ring-emerald-500/20'
                    : 'border-gray-200 hover:border-gray-300 text-gray-600 bg-white'
                }`}
              >
                <span>{langItem.flag}</span>
                <span>{langItem.label}</span>
              </button>
            ))}
          </div>
          <p className="text-[10px] text-gray-400 mt-1 leading-relaxed">
            {t('autoDetectedFromGoogle')}
          </p>
        </div>

        {/* Save Button */}
        <button
          type="submit"
          disabled={isSaving || !name.trim()}
          className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs shadow-md transition cursor-pointer flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {isSaving ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              <span>{t('saving_btn')}</span>
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              <span>{t('save_changes_btn')}</span>
            </>
          )}
        </button>
      </form>

      {/* Account Management & Privacy Options */}
      <div className="bg-white rounded-2xl p-4 border border-gray-200 shadow-xs space-y-2 mb-4">
        <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">
          {t('privacy_terms_header')}
        </h4>

        <button
          type="button"
          onClick={() => setShowTermsModal(true)}
          className="w-full p-2.5 rounded-xl hover:bg-gray-50 text-gray-700 text-xs font-semibold flex items-center justify-between transition cursor-pointer border border-gray-100"
        >
          <span className="flex items-center gap-2">
            <FileText className="w-4 h-4 text-emerald-600" />
            <span>{t('terms_modal_button_label')}</span>
          </span>
          <span className="text-[10px] text-gray-400">{t('terms_consult_btn')}</span>
        </button>

        <button
          type="button"
          onClick={() => setShowDeleteModal(true)}
          className="w-full p-2.5 rounded-xl hover:bg-red-50 text-red-700 text-xs font-semibold flex items-center justify-between transition cursor-pointer border border-red-100"
        >
          <span className="flex items-center gap-2">
            <Trash2 className="w-4 h-4 text-red-600" />
            <span>{t('delete_account_button_label')}</span>
          </span>
          <span className="text-[10px] bg-red-100 text-red-800 px-1.5 py-0.5 rounded font-bold">
            {t('manage_btn')}
          </span>
        </button>

        <button
          type="button"
          onClick={() => store.signOut()}
          className="w-full p-2.5 rounded-xl hover:bg-gray-100 text-gray-700 text-xs font-semibold flex items-center gap-2 transition cursor-pointer"
        >
          <LogOut className="w-4 h-4 text-gray-500" />
          <span>{t('sign_out_button_label')}</span>
        </button>
      </div>

      {/* Modals */}
      {showTermsModal && (
        <TermsModal onClose={() => setShowTermsModal(false)} />
      )}

      {showDeleteModal && (
        <AccountDeletionModal
          user={user}
          onClose={() => setShowDeleteModal(false)}
          onDeleted={(msg) => {
            setToastMessage(msg);
            setTimeout(() => setToastMessage(null), 5000);
          }}
        />
      )}

      {toastMessage && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 bg-gray-900 text-white px-5 py-3 rounded-2xl shadow-2xl text-xs font-semibold flex items-center gap-2 border border-gray-700 animate-in fade-in slide-in-from-bottom-3 duration-200">
          <span>✓</span>
          <span>{toastMessage}</span>
        </div>
      )}
    </div>
  );
};
