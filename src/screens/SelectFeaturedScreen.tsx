import React, { useState, useEffect } from 'react';
import { User, Product } from '../types';
import { store } from '../services/store';
import { ArrowLeft, Star, Check } from 'lucide-react';

interface SelectFeaturedScreenProps {
  user: User;
  onBack: () => void;
  onSuccess: () => void;
}

export const SelectFeaturedScreen: React.FC<SelectFeaturedScreenProps> = ({
  user,
  onBack,
  onSuccess,
}) => {
  const [products, setProducts] = useState<Product[]>([]);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    const update = () => {
      setProducts(store.getSellerProducts(user.id, false));
    };
    update();
    return store.subscribe(update);
  }, [user.id]);

  const handleSelectFeatured = (productId: string) => {
    setIsSaving(true);
    try {
      store.selectFeaturedProduct(user.id, productId);
      setTimeout(() => {
        setIsSaving(false);
        onSuccess();
      }, 500);
    } catch {
      setIsSaving(false);
    }
  };

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
          <h2 className="text-xl font-bold text-gray-900">Escolher produto em destaque</h2>
          <p className="text-xs text-gray-500">Seu produto selecionado ficará no topo do feed público</p>
        </div>
      </div>

      {products.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-100 p-8 shadow-sm">
          <Star className="w-12 h-12 mx-auto text-amber-300 mb-2" />
          <p className="text-gray-500 text-sm font-medium">
            Cadastre produtos antes de destacar.
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {products.map((p) => {
            const isFeatured = p.isFeatured;
            return (
              <div
                key={p.id}
                className={`bg-white rounded-xl p-3.5 border shadow-sm flex items-center justify-between gap-3 ${
                  isFeatured ? 'border-amber-400 bg-amber-50/20 ring-1 ring-amber-300' : 'border-gray-200'
                }`}
              >
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  <div
                    className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                      isFeatured ? 'bg-amber-500 text-white' : 'bg-amber-100 text-amber-600'
                    }`}
                  >
                    <Star className="w-5 h-5 fill-current" />
                  </div>

                  <div className="min-w-0 flex-1">
                    <h4 className="font-bold text-gray-900 text-sm truncate">
                      {p.name}
                    </h4>
                    <p className="text-xs text-gray-500 mt-0.5">
                      R$ {p.price.toFixed(2)} • qtd {p.quantity}
                    </p>
                  </div>
                </div>

                <div className="shrink-0">
                  {isFeatured ? (
                    <span className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold bg-amber-100 text-amber-800">
                      <Check className="w-3.5 h-3.5" />
                      Atual
                    </span>
                  ) : (
                    <button
                      onClick={() => handleSelectFeatured(p.id)}
                      disabled={isSaving}
                      className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg transition shadow-xs cursor-pointer disabled:opacity-50"
                    >
                      {isSaving ? 'Salvando...' : 'Destacar'}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
