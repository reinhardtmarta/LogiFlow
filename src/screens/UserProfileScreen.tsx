import React, { useState, useEffect } from 'react';
import { User } from '../types';
import { store } from '../services/store';
import { AccountDeletionModal } from '../components/AccountDeletionModal';
import { TermsModal } from '../components/TermsModal';
import { i18n, AppLanguage } from '../services/i18n';
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
  Layers, 
  QrCode,
  Sparkles,
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
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [isSeller, setIsSeller] = useState(false);
  const [pixKey, setPixKey] = useState('');
  const [bio, setBio] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showTermsModal, setShowTermsModal] = useState(false);
  const [currentLang, setCurrentLang] = useState<AppLanguage>(i18n.getLanguage());

  useEffect(() => {
    return i18n.subscribe((lang) => {
      setCurrentLang(lang);
    });
  }, []);

  useEffect(() => {
    if (user) {
      setName(user.name || '');
      setPhone(user.phone || '');
      setAddress(user.address || '');
      setIsSeller(Boolean(user.isSeller));
      // Load optional fields if present in user
      const anyUser = user as any;
      setPixKey(anyUser.pixKey || '');
      setBio(anyUser.bio || '');
    }
  }, [user]);

  if (!user || user.id === 'guest') {
    return (
      <div className="pb-28 pt-8 max-w-md mx-auto px-4 text-center">
        <div className="w-16 h-16 rounded-3xl bg-emerald-100 text-emerald-700 flex items-center justify-center mx-auto mb-4 shadow-sm">
          <UserIcon className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-extrabold text-gray-900 mb-1">
          Acesse seu Perfil
        </h2>
        <p className="text-xs text-gray-500 mb-6 max-w-xs mx-auto">
          Conecte-se com sua conta Google para gerenciar seus dados, endereço de retirada e anúncios de alimentos.
        </p>

        <button
          onClick={onOpenAuth}
          className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-2xl text-sm shadow-md transition cursor-pointer flex items-center justify-center gap-2"
        >
          <UserIcon className="w-4 h-4" />
          <span>Fazer Login com Google</span>
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
      setSaveError('Erro ao salvar perfil: ' + (err.message || 'Tente novamente.'));
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
            Meu Perfil & Dados
          </h2>
          <p className="text-xs text-gray-500">
            Gerencie suas informações cadastrais e de contato
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
            {isSeller ? 'Produtor / Vendedor' : 'Consumidor'}
          </span>
        </div>

        {/* Capacity / Package Status */}
        <div className="pt-2.5 border-t border-gray-100 flex items-center justify-between text-xs">
          <div>
            <span className="text-gray-500">Capacidade de Estoque:</span>{' '}
            <strong className="text-emerald-800">{sub.productLimit} itens</strong>
          </div>
          <button
            type="button"
            onClick={onOpenUpgrade}
            className="text-[11px] font-bold text-emerald-700 hover:text-emerald-800 underline cursor-pointer"
          >
            +1.000 itens (R$ 20)
          </button>
        </div>
      </div>

      {/* Form: Add or Alter User Data */}
      <form onSubmit={handleSaveProfile} className="bg-white rounded-2xl p-5 border border-gray-200 shadow-sm space-y-4 mb-4">
        <h3 className="font-bold text-gray-900 text-sm flex items-center gap-2">
          <span>Editar Informações Cadastrais</span>
        </h3>

        {saveSuccess && (
          <div className="p-3 bg-emerald-50 border border-emerald-300 text-emerald-800 rounded-xl text-xs flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            <span>Dados atualizados com sucesso no sistema!</span>
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
            Nome de Exibição / Nome do Estabelecimento *
          </label>
          <div className="relative">
            <UserIcon className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ex.: Fazenda Sol Verde ou Maria Silva"
              className="w-full pl-10 pr-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
            />
          </div>
        </div>

        {/* Phone / WhatsApp */}
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1">
            Telefone / WhatsApp para Retirada
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
            Facilita o contato entre produtor e resgatador no momento da entrega/retirada.
          </p>
        </div>

        {/* Address / Location */}
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1">
            Endereço de Retirada / Cidade / Bairro
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
            Usado para calcular a distância em metros/km para os consumidores próximos.
          </p>
        </div>

        {/* Role Toggle: Seller vs Consumer */}
        <div className="p-3.5 bg-emerald-50/60 border border-emerald-200 rounded-xl">
          <label className="flex items-center justify-between cursor-pointer">
            <div>
              <span className="block text-xs font-bold text-emerald-950">
                Ativar Perfil de Produtor / Estabelecimento
              </span>
              <span className="block text-[11px] text-emerald-800/80">
                Permite cadastrar e anunciar alimentos excedentes no feed
              </span>
            </div>
            <input
              type="checkbox"
              checked={isSeller}
              onChange={(e) => setIsSeller(e.target.checked)}
              className="w-5 h-5 accent-emerald-600 rounded cursor-pointer"
            />
          </label>
        </div>

        {/* Language Selection - Auto detected from Google */}
        <div className="p-3.5 bg-gray-50 border border-gray-200 rounded-xl space-y-2">
          <div className="flex items-center justify-between">
            <label className="text-xs font-bold text-gray-800 flex items-center gap-1.5">
              <Languages className="w-4 h-4 text-emerald-600" />
              <span>{i18n.t('languageSetting')}</span>
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
                onClick={() => i18n.setLanguage(langItem.code as AppLanguage)}
                className={`py-2 px-2 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition cursor-pointer ${
                  currentLang === langItem.code
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
            {i18n.t('autoDetectedFromGoogle')}
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
              <span>Salvando no banco de dados...</span>
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              <span>Salvar Alterações</span>
            </>
          )}
        </button>
      </form>

      {/* Account Management & Privacy Options */}
      <div className="bg-white rounded-2xl p-4 border border-gray-200 shadow-xs space-y-2 mb-4">
        <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">
          Privacidade & Termos
        </h4>

        <button
          type="button"
          onClick={() => setShowTermsModal(true)}
          className="w-full p-2.5 rounded-xl hover:bg-gray-50 text-gray-700 text-xs font-semibold flex items-center justify-between transition cursor-pointer border border-gray-100"
        >
          <span className="flex items-center gap-2">
            <FileText className="w-4 h-4 text-emerald-600" />
            <span>Termos de Uso e Política de Privacidade (LGPD)</span>
          </span>
          <span className="text-[10px] text-gray-400">Consultar</span>
        </button>

        <button
          type="button"
          onClick={() => setShowDeleteModal(true)}
          className="w-full p-2.5 rounded-xl hover:bg-red-50 text-red-700 text-xs font-semibold flex items-center justify-between transition cursor-pointer border border-red-100"
        >
          <span className="flex items-center gap-2">
            <Trash2 className="w-4 h-4 text-red-600" />
            <span>Excluir Conta ou Dados (LGPD)</span>
          </span>
          <span className="text-[10px] bg-red-100 text-red-800 px-1.5 py-0.5 rounded font-bold">
            Gerenciar
          </span>
        </button>

        <button
          type="button"
          onClick={() => store.signOut()}
          className="w-full p-2.5 rounded-xl hover:bg-gray-100 text-gray-700 text-xs font-semibold flex items-center gap-2 transition cursor-pointer"
        >
          <LogOut className="w-4 h-4 text-gray-500" />
          <span>Sair da Conta</span>
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
