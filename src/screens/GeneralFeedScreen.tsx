import React, { useState, useEffect } from 'react';
import { Product, User } from '../types';
import { store } from '../services/store';
import { Sparkles, X, Star, AlertTriangle, Leaf, MapPin, Package, MessageSquareText } from 'lucide-react';

interface GeneralFeedScreenProps {
  user: User;
  onOpenChat: (receiverId: string, receiverName: string) => void;
  aiInsightMessage: string | null;
  onDismissAiInsight: () => void;
}

export const GeneralFeedScreen: React.FC<GeneralFeedScreenProps> = ({
  user,
  onOpenChat,
  aiInsightMessage,
  onDismissAiInsight,
}) => {
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    const update = () => {
      setProducts(store.getProducts());
    };
    update();
    return store.subscribe(update);
  }, []);

  const getDaysLeft = (expiryDate: string): number => {
    const expiry = new Date(expiryDate);
    const now = new Date();
    // Compare dates only
    const d1 = new Date(expiry.getFullYear(), expiry.getMonth(), expiry.getDate()).getTime();
    const d2 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return Math.ceil((d1 - d2) / (1000 * 60 * 60 * 24));
  };

  return (
    <div className="pb-24 pt-3 max-w-xl mx-auto px-4">
      {/* Gemma AI Smart Insight Banner */}
      {aiInsightMessage && (
        <div className="mb-4 bg-gradient-to-r from-emerald-600 to-emerald-700 text-white p-4 rounded-2xl shadow-md border border-emerald-500/30 flex items-start gap-3 relative animate-in fade-in slide-in-from-top-2 duration-200">
          <div className="p-2 bg-white/20 rounded-xl shrink-0 mt-0.5">
            <Sparkles className="w-5 h-5 text-amber-300" />
          </div>
          <div className="flex-1 pr-6">
            <p className="text-[11px] font-black uppercase tracking-wider text-emerald-200">
              Dica da Gemma
            </p>
            <p className="text-sm font-medium mt-0.5 leading-snug text-white">
              {aiInsightMessage}
            </p>
          </div>
          <button
            onClick={onDismissAiInsight}
            className="absolute top-3 right-3 p-1 rounded-full hover:bg-white/20 text-white/80 hover:text-white transition cursor-pointer"
            title="Fechar dica"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Feed List Header */}
      <div className="flex items-center justify-between mb-3 px-1">
        <div>
          <h2 className="text-lg font-bold text-gray-800">Feed de Alimentos</h2>
          <p className="text-xs text-gray-500">Resgate alimentos frescos antes que vençam</p>
        </div>
        <span className="text-xs font-semibold bg-emerald-100 text-emerald-800 px-2.5 py-1 rounded-full">
          {products.length} itens ativos
        </span>
      </div>

      {products.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-100 p-8 shadow-sm">
          <div className="w-16 h-16 mx-auto mb-3 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
            <Package className="w-8 h-8" />
          </div>
          <h3 className="font-bold text-gray-800 text-base">Nenhum item disponível no momento</h3>
          <p className="text-xs text-gray-500 mt-1 max-w-xs mx-auto">
            Novos produtos frescos e resgatados serão cadastrados pelos produtores da sua região.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {products.map((p) => {
            const days = getDaysLeft(p.expiryDate);
            const isUrgent = days <= 3;
            const isPremium = p.isFeatured;
            const image = p.imagePaths?.[0] || p.imagePath;

            return (
              <div
                key={p.id}
                onClick={() => onOpenChat(p.userId, 'Produtor')}
                className={`group bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-all cursor-pointer border ${
                  isPremium
                    ? 'border-amber-400 ring-2 ring-amber-400/20'
                    : isUrgent
                    ? 'border-red-300'
                    : 'border-gray-200'
                }`}
              >
                {/* Badges Row */}
                <div className="flex flex-wrap items-center gap-1.5 mb-2.5">
                  {isPremium && (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-300">
                      <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
                      PREMIUM
                    </span>
                  )}
                  {isUrgent && (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-red-50 text-red-700 border border-red-200">
                      <AlertTriangle className="w-3 h-3" />
                      RESGATE URGENTE
                    </span>
                  )}
                  {!isPremium && !isUrgent && (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                      <Leaf className="w-3 h-3" />
                      SAUDÁVEL
                    </span>
                  )}
                  <span className="text-[10px] font-medium text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full ml-auto">
                    {p.category}
                  </span>
                </div>

                {/* Product Main Info */}
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-start gap-3 flex-1 min-w-0">
                    {image ? (
                      <img
                        src={image}
                        alt={p.name}
                        className="w-16 h-16 rounded-xl object-cover shrink-0 border border-gray-100 bg-gray-50"
                        onError={(e) => {
                          (e.currentTarget as HTMLImageElement).style.display = 'none';
                        }}
                      />
                    ) : (
                      <div className="w-16 h-16 rounded-xl bg-emerald-50 flex items-center justify-center shrink-0 border border-emerald-100 text-emerald-600">
                        <Leaf className="w-8 h-8" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <h3 className="font-bold text-gray-900 text-base leading-tight group-hover:text-emerald-700 transition truncate">
                        {p.name}
                      </h3>
                      <div className="flex items-center gap-1 text-xs text-gray-500 mt-1 truncate">
                        <MapPin className="w-3.5 h-3.5 shrink-0 text-gray-400" />
                        <span className="truncate">{p.address}</span>
                      </div>
                      <div className="flex items-center gap-3 text-xs text-gray-600 mt-1 font-medium">
                        <span className="flex items-center gap-1">
                          <Package className="w-3.5 h-3.5 text-gray-400" />
                          {p.quantity} un disponíveis
                        </span>
                        <span className="text-gray-400">•</span>
                        <span className="text-emerald-600 font-semibold">{p.condition}</span>
                      </div>
                    </div>
                  </div>

                  <div className="text-right shrink-0">
                    <span className="text-lg font-black text-emerald-700">
                      R$ {p.price.toFixed(2)}
                    </span>
                    {p.isRescue && (
                      <span className="block text-[10px] text-emerald-600 font-medium">
                        Resgate Verde
                      </span>
                    )}
                  </div>
                </div>

                {/* Divider & Expiry Footer */}
                <div className="mt-3 pt-2.5 border-t border-gray-100 flex items-center justify-between">
                  <div className="text-xs">
                    <span className="text-gray-500">Vencimento: </span>
                    <span
                      className={`font-semibold ${
                        days < 0
                          ? 'text-red-700 font-bold'
                          : days === 0
                          ? 'text-red-600 font-bold'
                          : isUrgent
                          ? 'text-red-600 font-bold'
                          : 'text-gray-700'
                      }`}
                    >
                      {days < 0
                        ? `Venceu há ${Math.abs(days)} dia(s)`
                        : days === 0
                        ? 'Vence hoje!'
                        : days === 1
                        ? 'Vence amanhã'
                        : `Vence em ${days} dias`}
                    </span>
                  </div>

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      onOpenChat(p.userId, 'Produtor');
                    }}
                    className="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 hover:text-emerald-800 bg-emerald-50 hover:bg-emerald-100/80 px-2.5 py-1 rounded-lg transition"
                  >
                    <MessageSquareText className="w-3.5 h-3.5" />
                    Falar com Vendedor
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
