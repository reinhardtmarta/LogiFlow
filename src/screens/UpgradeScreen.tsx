import React, { useState } from 'react';
import { User, Tier, TIER_CONFIGS } from '../types';
import { store } from '../services/store';
import { ArrowLeft, CheckCircle2, Lock, ExternalLink, ShieldCheck, Crown, Star } from 'lucide-react';

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
  const [checkoutOpened, setCheckoutOpened] = useState(false);
  const [paymentStatus, setPaymentStatus] = useState<string | null>(null);

  const sub = store.getSubscription(user.id);
  const sellerProducts = store.getSellerProducts(user.id, true);
  const currentCount = sellerProducts.length;

  const handleStartStripe = () => {
    setIsProcessing(true);
    setPaymentStatus('pending');

    setTimeout(() => {
      setCheckoutOpened(true);
      setIsProcessing(false);
    }, 700);
  };

  const handleSimulatePaymentApproval = () => {
    setPaymentStatus('paid');
    store.completePayment(user.id, selectedTier);

    setTimeout(() => {
      onSuccess();
    }, 1200);
  };

  const config = TIER_CONFIGS[selectedTier];

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
          <h2 className="text-xl font-bold text-gray-900">Fazer upgrade</h2>
          <p className="text-xs text-gray-500">Expanda suas vendas e destaque produtos no feed</p>
        </div>
      </div>

      {/* Status Card matching Flutter _buildStatusCard */}
      <div className="bg-emerald-50 rounded-2xl p-4 border border-emerald-200 mb-4 shadow-sm">
        <h3 className="text-base font-bold text-emerald-950 mb-2">
          Status da sua conta
        </h3>
        <div className="space-y-1 text-xs text-emerald-900">
          <p>
            <span className="font-semibold">Produtos cadastrados:</span> {currentCount}{' '}
            {sub.productLimit < 0 ? '' : `/ ${sub.productLimit}`}
          </p>
          <p>
            <span className="font-semibold">Plano atual:</span> {TIER_CONFIGS[sub.tier].label}
          </p>
          <p>
            <span className="font-semibold">Status:</span>{' '}
            <span className="capitalize">{sub.status === 'active' ? 'Ativo' : 'Sem assinatura ativa'}</span>
          </p>
        </div>
        <p className="text-xs font-semibold text-emerald-800 mt-3 pt-2 border-t border-emerald-200/60">
          Recomendamos o plano {config.label} por {config.priceLabel}/mês.
        </p>
      </div>

      {/* Plan Cards matching Flutter _buildPlanCard */}
      <div className="space-y-3 mb-6">
        {(['basic', 'pro'] as Tier[]).map((tierKey) => {
          const tConfig = TIER_CONFIGS[tierKey];
          const isSelected = selectedTier === tierKey;
          const isCurrent = sub.tier === tierKey && sub.status === 'active';

          return (
            <div
              key={tierKey}
              onClick={() => setSelectedTier(tierKey)}
              className={`p-4 rounded-2xl border-2 transition-all cursor-pointer flex items-center justify-between gap-3 ${
                isSelected
                  ? 'border-emerald-600 bg-white shadow-md ring-2 ring-emerald-500/20'
                  : 'border-gray-200 bg-white hover:border-gray-300'
              }`}
            >
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                    isSelected ? 'bg-emerald-600 text-white' : 'bg-gray-100 text-gray-500'
                  }`}
                >
                  {tierKey === 'pro' ? <Crown className="w-5 h-5" /> : <Star className="w-5 h-5" />}
                </div>

                <div>
                  <div className="flex items-center gap-2">
                    <h4 className="font-bold text-gray-900 text-sm">{tConfig.label}</h4>
                    {isCurrent && (
                      <span className="text-[10px] bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full">
                        Atual
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 mt-0.5">
                    {tConfig.limitLabel} • Até {tConfig.maxPhotos} fotos por item
                  </p>
                </div>
              </div>

              <div className="text-right shrink-0">
                <span className="text-base font-black text-emerald-700 block">
                  {tConfig.priceLabel}
                </span>
                <span className="text-[10px] text-gray-400">/mês</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Safe Payment Info */}
      <div className="mb-4">
        <h4 className="text-sm font-bold text-gray-900 mb-1 flex items-center gap-1.5">
          <ShieldCheck className="w-4 h-4 text-emerald-600" /> Pagamento seguro
        </h4>
        <p className="text-xs text-gray-500 leading-relaxed">
          A assinatura será processada via Stripe Checkout. O pagamento é recorrente mensal e pode ser cancelado a qualquer momento sem taxas adicionais.
        </p>
      </div>

      {/* Stripe Section matching Flutter _buildStripeSection */}
      {!checkoutOpened ? (
        <button
          onClick={handleStartStripe}
          disabled={isProcessing}
          className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-sm shadow-md transition flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
        >
          {isProcessing ? (
            <span>Abrindo Stripe...</span>
          ) : (
            <>
              <Lock className="w-4 h-4" />
              <span>Assinar com Stripe ({config.priceLabel}/mês)</span>
            </>
          )}
        </button>
      ) : (
        <div className="bg-white rounded-2xl p-5 border border-indigo-100 shadow-md text-center space-y-4">
          <div className="w-12 h-12 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center mx-auto">
            <ExternalLink className="w-6 h-6" />
          </div>

          <div>
            <h4 className="font-bold text-gray-900 text-sm">
              Checkout Stripe inicializado
            </h4>
            <p className="text-xs text-gray-500 mt-1 max-w-xs mx-auto">
              Simulação de sessão segura para o plano{' '}
              <strong className="text-indigo-600">{config.label}</strong>.
            </p>
          </div>

          <div className="flex items-center justify-center gap-2">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">
              <span className="w-2 h-2 rounded-full bg-amber-500 animate-ping" />
              {paymentStatus === 'paid' ? 'Pagamento Confirmado' : 'Aguardando pagamento...'}
            </span>
          </div>

          {paymentStatus !== 'paid' ? (
            <button
              onClick={handleSimulatePaymentApproval}
              className="w-full py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-xs transition cursor-pointer flex items-center justify-center gap-1.5"
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>Simular Confirmação Stripe (Webhook)</span>
            </button>
          ) : (
            <div className="p-3 bg-emerald-50 text-emerald-800 border border-emerald-200 rounded-xl text-xs font-bold flex items-center justify-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>Pagamento confirmado! Plano ativado com sucesso.</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
