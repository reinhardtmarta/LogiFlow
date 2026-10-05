import React, { useState } from 'react';
import { User, Tier, TIER_CONFIGS } from '../types';
import { store } from '../services/store';
import { googlePay } from '../services/googlePay';
import { MERCADO_PAGO_CONFIG } from '../config/payment';
import { MercadoPagoSecurityBot } from '../components/MercadoPagoSecurityBot';
import { 
  ArrowLeft, 
  CheckCircle2, 
  ShieldCheck, 
  Crown, 
  Star, 
  CreditCard, 
  Loader2,
  Lock,
  ExternalLink,
  QrCode,
  Calendar,
  Layers,
  Sparkles,
  Bot
} from 'lucide-react';

interface UpgradeScreenProps {
  user: User;
  suggestedTier: Tier;
  onBack: () => void;
  onSuccess: () => void;
}

export const UpgradeScreen: React.FC<UpgradeScreenProps> = ({
  user,
  suggestedTier,
  onBack,
  onSuccess,
}) => {
  const [selectedTier, setSelectedTier] = useState<Tier>(suggestedTier || 'basic');
  const [isProcessing, setIsProcessing] = useState(false);
  const [googlePaySheetOpen, setGooglePaySheetOpen] = useState(false);
  const [paymentSuccess, setPaymentSuccess] = useState(false);
  const [gpayTransactionId, setGpayTransactionId] = useState<string | null>(null);
  const [showBot, setShowBot] = useState(false);

  const sub = store.getSubscription(user.id);
  const sellerProducts = store.getSellerProducts(user.id, true);
  const currentCount = sellerProducts.length;
  const config = TIER_CONFIGS[selectedTier];

  const handleOpenGooglePay = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      setGooglePaySheetOpen(true);
    }, 400);
  };

  const handleConfirmGooglePay = async () => {
    setIsProcessing(true);
    try {
      const amountStr = (config.amountCents / 100).toFixed(2);
      const res = await googlePay.processPayment({
        amount: amountStr,
        currencyCode: 'BRL',
        merchantName: 'LogiFlow Alimentos',
        planName: config.label,
      });

      setGpayTransactionId(res.transactionId);
      setPaymentSuccess(true);
      await store.completePayment(user.id, selectedTier);

      setTimeout(() => {
        onSuccess();
      }, 1500);
    } catch (err: any) {
      alert(err.message || 'Erro ao processar Google Pay');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleManualConfirmMercadoPago = async () => {
    setIsProcessing(true);
    await store.completePayment(user.id, 'basic');
    setIsProcessing(false);
    onSuccess();
  };

  const daysLeft = sub.currentPeriodEnd
    ? Math.max(0, Math.ceil((new Date(sub.currentPeriodEnd).getTime() - Date.now()) / (1000 * 60 * 60 * 24)))
    : 0;

  return (
    <div className="pb-24 pt-3 max-w-xl mx-auto px-4">
      {/* Header */}
      <div className="flex items-center gap-3 mb-4">
        <button
          onClick={onBack}
          className="p-2 rounded-xl bg-white border border-gray-200 text-gray-700 hover:bg-gray-100 transition cursor-pointer"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <h2 className="text-xl font-bold text-gray-900">Capacidade de Estoque</h2>
          <p className="text-xs text-gray-500">Recargas de 30 dias • Pagamento único (Não recorrente)</p>
        </div>
      </div>

      {/* Status Card */}
      <div className="bg-emerald-50 rounded-2xl p-4 border border-emerald-200 mb-4 shadow-sm">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-base font-bold text-emerald-950 flex items-center gap-1.5">
            <Layers className="w-4 h-4 text-emerald-700" />
            <span>Sua Capacidade Atual</span>
          </h3>
          <span className="text-[10px] bg-emerald-200 text-emerald-900 font-bold px-2 py-0.5 rounded-full">
            {sub.status === 'active' ? 'Pacote Ativo' : 'Cota Grátis'}
          </span>
        </div>

        <div className="space-y-1.5 text-xs text-emerald-900">
          <p className="flex justify-between">
            <span className="font-semibold text-gray-700">Produtos cadastrados:</span>
            <span className="font-bold text-gray-900">{currentCount} / {sub.productLimit} itens</span>
          </p>
          <p className="flex justify-between">
            <span className="font-semibold text-gray-700">Limite contratado:</span>
            <span className="font-bold text-emerald-800">{sub.productLimit} itens ({sub.packagesCount || 0} pacote(s))</span>
          </p>
          {sub.currentPeriodEnd && sub.status === 'active' && (
            <p className="flex justify-between items-center text-emerald-800">
              <span className="font-semibold flex items-center gap-1">
                <Calendar className="w-3.5 h-3.5" /> Validade do pacote:
              </span>
              <span className="font-bold">
                {daysLeft} dias restantes ({new Date(sub.currentPeriodEnd).toLocaleDateString()})
              </span>
            </p>
          )}
        </div>

        {/* Clear Explanation of Non-Recurrent & Cumulative Rule */}
        <div className="mt-3 pt-2.5 border-t border-emerald-200 text-[11px] text-emerald-900 leading-relaxed bg-emerald-100/60 p-2.5 rounded-xl">
          <p className="font-bold flex items-center gap-1 text-emerald-950 mb-0.5">
            <Sparkles className="w-3.5 h-3.5 text-emerald-700" />
            Como funciona a recarga de capacidade:
          </p>
          <ul className="list-disc list-inside space-y-0.5 text-emerald-800">
            <li><strong>Pagamento NÃO recorrente</strong>: não há renovação automática no seu cartão.</li>
            <li><strong>Duração de 1 mês</strong>: cada recarga é válida por 30 dias de uso.</li>
            <li><strong>Acumulativo</strong>: cada R$ 20,00 adiciona <strong>+1.000 itens</strong>. Se precisar de 2.000, 3.000 ou mais itens, basta pagar novamente a qualquer momento!</li>
          </ul>
        </div>
      </div>

      {/* Package Options */}
      <div className="space-y-3 mb-6">
        {/* Free Plan */}
        <div
          onClick={() => setSelectedTier('free')}
          className={`p-4 rounded-2xl border-2 transition-all cursor-pointer flex items-center justify-between gap-3 ${
            selectedTier === 'free'
              ? 'border-emerald-600 bg-white shadow-md ring-2 ring-emerald-500/20'
              : 'border-gray-200 bg-white hover:border-gray-300'
          }`}
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gray-100 text-gray-700 flex items-center justify-center shrink-0 font-black text-sm">
              50
            </div>
            <div>
              <h4 className="font-bold text-gray-900 text-sm">Cota Grátis Inicial</h4>
              <p className="text-xs text-gray-500 mt-0.5">
                Até 50 itens cadastrados permanentemente (sem custo)
              </p>
            </div>
          </div>
          <div className="text-right shrink-0">
            <span className="text-base font-black text-emerald-700 block">R$ 0,00</span>
            <span className="text-[10px] text-gray-400">Permanente</span>
          </div>
        </div>

        {/* Basic Recharge Package: +1000 items / R$ 20 */}
        <div
          onClick={() => setSelectedTier('basic')}
          className={`p-4 rounded-2xl border-2 transition-all cursor-pointer flex items-center justify-between gap-3 ${
            selectedTier === 'basic' || selectedTier === 'pro'
              ? 'border-emerald-600 bg-white shadow-md ring-2 ring-emerald-500/20'
              : 'border-gray-200 bg-white hover:border-gray-300'
          }`}
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center shrink-0 font-bold">
              <Star className="w-5 h-5 fill-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h4 className="font-bold text-gray-900 text-sm">+1.000 Itens de Estoque</h4>
                <span className="text-[10px] bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full">
                  Acumulativo
                </span>
              </div>
              <p className="text-xs text-gray-500 mt-0.5">
                Válido por 30 dias (1 mês) • Não recorrente • Até 5 fotos por item
              </p>
            </div>
          </div>
          <div className="text-right shrink-0">
            <span className="text-base font-black text-emerald-700 block">R$ 20,00</span>
            <span className="text-[10px] text-gray-400">por 30 dias</span>
          </div>
        </div>
      </div>

      {/* Payment Gateways: Mercado Pago & Google Pay */}
      <div className="bg-white rounded-2xl p-5 border border-gray-200 shadow-sm mb-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-emerald-600" />
            <span className="font-bold text-sm text-gray-900">
              Formas de Pagamento (Não Recorrente)
            </span>
          </div>
          <span className="text-[11px] text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded-full">
            R$ 20,00 / +1.000 itens
          </span>
        </div>

        <p className="text-xs text-gray-500 mb-4 leading-relaxed">
          Pague com <strong>Mercado Pago</strong> (Pix instantâneo, cartão ou boleto) ou <strong>Google Pay</strong>. Cada pagamento de R$ 20,00 soma imediatamente +1.000 itens à sua conta por 30 dias.
        </p>

        <div className="space-y-3">
          {/* Bot de Segurança Oficial Mercado Pago / Mercado Livre */}
          <button
            type="button"
            onClick={() => setShowBot(true)}
            className="w-full py-3.5 bg-gradient-to-r from-[#009EE3] to-[#007ebb] hover:from-[#008cc9] hover:to-[#006ea8] text-white font-bold rounded-2xl text-sm shadow-md transition flex items-center justify-center gap-2.5 cursor-pointer text-center border border-white/20"
          >
            <Bot className="w-5 h-5 text-white" />
            <span>Pagar & Autorizar com Bot Mercado Pago (R$ 20,00)</span>
          </button>

          {/* Direct Link Alternative */}
          <a
            href={MERCADO_PAGO_CONFIG.basicPlanUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full py-2.5 bg-gray-50 hover:bg-gray-100 text-gray-700 font-semibold rounded-xl text-xs border border-gray-200 transition flex items-center justify-center gap-2 cursor-pointer no-underline text-center"
          >
            <QrCode className="w-3.5 h-3.5 text-gray-500" />
            <span>Abrir Link Direto do Mercado Pago</span>
            <ExternalLink className="w-3 h-3 text-gray-400" />
          </a>

          <div className="flex items-center gap-2 my-2">
            <div className="flex-1 h-px bg-gray-200" />
            <span className="text-[10px] text-gray-400 uppercase font-semibold">ou pagar com</span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>

          {/* Google Pay Button */}
          <button
            type="button"
            onClick={handleOpenGooglePay}
            disabled={isProcessing}
            className="w-full py-3 bg-black hover:bg-neutral-800 text-white font-medium rounded-xl text-sm shadow-md transition flex items-center justify-center gap-2.5 cursor-pointer disabled:opacity-50"
          >
            {isProcessing ? (
              <Loader2 className="w-5 h-5 animate-spin text-white" />
            ) : (
              <>
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path
                    fill="#4285F4"
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                  />
                  <path
                    fill="#EA4335"
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                  />
                </svg>
                <span className="font-semibold">Pay</span>
                <span className="text-gray-400">|</span>
                <span>Pagar R$ 20,00 via Google Pay</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Google Pay Sheet Modal */}
      {googlePaySheetOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 z-50 animate-in fade-in duration-150">
          <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl shadow-2xl p-6 border border-gray-100 animate-in slide-in-from-bottom duration-200">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100 mb-4">
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path
                    fill="#4285F4"
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                  />
                  <path
                    fill="#EA4335"
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                  />
                </svg>
                <span className="font-bold text-gray-900 text-sm">Google Pay</span>
              </div>
              <button
                onClick={() => setGooglePaySheetOpen(false)}
                className="text-gray-400 hover:text-gray-600 text-xs font-bold cursor-pointer"
              >
                Cancelar
              </button>
            </div>

            {!paymentSuccess ? (
              <div className="space-y-4">
                <div className="bg-gray-50 p-3.5 rounded-2xl border border-gray-200">
                  <div className="flex justify-between items-center text-xs text-gray-500 mb-1">
                    <span>Recarga de Capacidade LogiFlow</span>
                    <span>30 dias de uso</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="font-bold text-gray-900 text-sm">+1.000 Itens de Estoque</span>
                    <span className="font-extrabold text-base text-gray-900">R$ 20,00</span>
                  </div>
                </div>

                <div className="border border-gray-200 rounded-2xl p-3.5 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-7 bg-blue-600 text-white rounded flex items-center justify-center font-black text-[10px]">
                      VISA
                    </div>
                    <div>
                      <p className="text-xs font-bold text-gray-900">Cartão Santander •••• 4821</p>
                      <p className="text-[10px] text-gray-400">{user.email}</p>
                    </div>
                  </div>
                  <span className="text-[11px] text-blue-600 font-semibold cursor-pointer">
                    Trocar
                  </span>
                </div>

                <div className="text-[11px] text-gray-400 flex items-center gap-1.5 px-1">
                  <Lock className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Pagamento único sem recorrência automática.</span>
                </div>

                <button
                  type="button"
                  onClick={handleConfirmGooglePay}
                  disabled={isProcessing}
                  className="w-full py-3.5 bg-black hover:bg-neutral-800 text-white font-bold rounded-xl text-sm shadow-md transition flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
                >
                  {isProcessing ? (
                    <Loader2 className="w-5 h-5 animate-spin" />
                  ) : (
                    <span>Confirmar Pagamento de R$ 20,00</span>
                  )}
                </button>
              </div>
            ) : (
              <div className="py-6 text-center space-y-3">
                <div className="w-14 h-14 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto shadow-sm animate-in zoom-in-75">
                  <CheckCircle2 className="w-8 h-8" />
                </div>
                <h4 className="font-bold text-gray-900 text-base">
                  +1.000 Itens Adicionados com Sucesso!
                </h4>
                <p className="text-xs text-gray-500 max-w-xs mx-auto">
                  Sua nova capacidade de estoque foi atualizada para 30 dias.
                </p>
                <div className="p-2.5 bg-gray-50 rounded-xl text-[11px] text-gray-500 font-mono">
                  ID: {gpayTransactionId}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Mercado Pago Security Bot Modal */}
      {showBot && (
        <MercadoPagoSecurityBot
          user={user}
          onSuccess={() => {
            setShowBot(false);
            onSuccess();
          }}
          onClose={() => setShowBot(false)}
        />
      )}
    </div>
  );
};
