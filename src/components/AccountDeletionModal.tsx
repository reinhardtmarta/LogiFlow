import React, { useState } from 'react';
import { User } from '../types';
import { store } from '../services/store';
import { 
  Trash2, 
  UserX, 
  AlertTriangle, 
  ShieldAlert, 
  CheckCircle2, 
  Loader2 
} from 'lucide-react';

interface AccountDeletionModalProps {
  user: User;
  onClose: () => void;
  onDeleted: (message: string) => void;
}

export const AccountDeletionModal: React.FC<AccountDeletionModalProps> = ({
  user,
  onClose,
  onDeleted,
}) => {
  const [selectedAction, setSelectedAction] = useState<'account_only' | 'all_data' | null>(null);
  const [confirmStep, setConfirmStep] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleExecuteDeletion = async () => {
    if (!selectedAction) return;
    setIsDeleting(true);
    setErrorMessage(null);

    try {
      if (selectedAction === 'account_only') {
        await store.deleteUserAccount(user.id);
        onDeleted('Sua conta no LogiFlow foi encerrada com sucesso.');
      } else {
        await store.deleteAllUserData(user.id);
        onDeleted('Todos os seus dados e produtos foram excluídos permanentemente (LGPD).');
      }
      onClose();
    } catch (err: any) {
      setErrorMessage(err.message || 'Erro ao processar exclusão. Tente novamente.');
      setIsDeleting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-150">
      <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl border border-gray-100 p-6 relative text-left">
        <button
          onClick={onClose}
          disabled={isDeleting}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-sm font-semibold cursor-pointer p-1 disabled:opacity-30"
        >
          ✕
        </button>

        {/* Header */}
        <div className="flex items-center gap-3 mb-4 pb-3 border-b border-gray-100">
          <div className="w-10 h-10 rounded-xl bg-red-100 text-red-600 flex items-center justify-center shrink-0">
            <UserX className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-extrabold text-gray-900 text-base">
              Gerenciar Conta & Privacidade
            </h3>
            <p className="text-[11px] text-gray-500">
              Opções de encerramento e exclusão de dados (LGPD)
            </p>
          </div>
        </div>

        {!confirmStep ? (
          <div className="space-y-4">
            <p className="text-xs text-gray-600 leading-relaxed">
              Você tem total controle sobre sua presença no LogiFlow. Escolha abaixo a opção desejada:
            </p>

            {/* Option 1: Account Only */}
            <div
              onClick={() => setSelectedAction('account_only')}
              className={`p-4 rounded-2xl border-2 transition cursor-pointer flex items-start gap-3 ${
                selectedAction === 'account_only'
                  ? 'border-amber-500 bg-amber-50/50'
                  : 'border-gray-200 hover:border-gray-300 bg-white'
              }`}
            >
              <div className="w-8 h-8 rounded-lg bg-amber-100 text-amber-700 flex items-center justify-center shrink-0 mt-0.5">
                <UserX className="w-4 h-4" />
              </div>
              <div className="flex-1 text-xs">
                <p className="font-bold text-gray-900">
                  1. Excluir apenas a conta no LogiFlow
                </p>
                <p className="text-gray-500 mt-0.5 leading-relaxed">
                  Desativa seu cadastro nesta aplicação. Sua conta Google continua normal e inalterada. Seus anúncios anteriores são desvinculados.
                </p>
              </div>
            </div>

            {/* Option 2: Full Data Wipe */}
            <div
              onClick={() => setSelectedAction('all_data')}
              className={`p-4 rounded-2xl border-2 transition cursor-pointer flex items-start gap-3 ${
                selectedAction === 'all_data'
                  ? 'border-red-500 bg-red-50/50'
                  : 'border-gray-200 hover:border-gray-300 bg-white'
              }`}
            >
              <div className="w-8 h-8 rounded-lg bg-red-100 text-red-700 flex items-center justify-center shrink-0 mt-0.5">
                <Trash2 className="w-4 h-4" />
              </div>
              <div className="flex-1 text-xs">
                <div className="flex items-center gap-1.5">
                  <p className="font-bold text-gray-900">
                    2. Excluir todos os meus dados
                  </p>
                  <span className="text-[9px] bg-red-100 text-red-800 font-bold px-1.5 py-0.2 rounded">
                    LGPD
                  </span>
                </div>
                <p className="text-gray-500 mt-0.5 leading-relaxed">
                  Exclusão total e irreversível: remove seu perfil, todos os produtos anunciados e histórico de conversas do banco de dados.
                </p>
              </div>
            </div>

            <div className="pt-2 flex justify-end gap-2">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-xs font-semibold text-gray-600 hover:bg-gray-100 rounded-xl transition cursor-pointer"
              >
                Cancelar
              </button>
              <button
                type="button"
                disabled={!selectedAction}
                onClick={() => setConfirmStep(true)}
                className="px-5 py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-xs transition cursor-pointer disabled:opacity-40"
              >
                Continuar
              </button>
            </div>
          </div>
        ) : (
          /* Confirmation Step */
          <div className="space-y-4">
            <div className="p-3.5 bg-red-50 border border-red-200 rounded-2xl text-xs text-red-800 flex items-start gap-2.5">
              <AlertTriangle className="w-5 h-5 text-red-600 shrink-0 mt-0.5" />
              <div>
                <p className="font-bold">Confirmação de Segurança</p>
                <p className="mt-1 leading-relaxed">
                  {selectedAction === 'account_only'
                    ? 'Tem certeza de que deseja excluir sua conta no LogiFlow? Você será desconectado imediatamente.'
                    : 'Atenção: todos os seus produtos cadastrados e dados serão permanentemente apagados do sistema de forma irreversível.'}
                </p>
              </div>
            </div>

            {errorMessage && (
              <div className="p-3 bg-red-100 border border-red-300 text-red-900 rounded-xl text-xs flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-red-600 shrink-0" />
                <span>{errorMessage}</span>
              </div>
            )}

            <p className="text-xs text-gray-500">
              Usuário conectado: <strong>{user.email || user.name}</strong>
            </p>

            <div className="pt-2 flex justify-end gap-2">
              <button
                type="button"
                disabled={isDeleting}
                onClick={() => setConfirmStep(false)}
                className="px-4 py-2 text-xs font-semibold text-gray-600 hover:bg-gray-100 rounded-xl transition cursor-pointer disabled:opacity-50"
              >
                Voltar
              </button>

              <button
                type="button"
                disabled={isDeleting}
                onClick={handleExecuteDeletion}
                className="px-5 py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-xs transition cursor-pointer flex items-center gap-2 disabled:opacity-50 shadow-md"
              >
                {isDeleting ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Processando exclusão...</span>
                  </>
                ) : (
                  <>
                    <Trash2 className="w-4 h-4" />
                    <span>Confirmar e Excluir Definitivamente</span>
                  </>
                )}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
