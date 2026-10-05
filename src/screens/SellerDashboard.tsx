import React, { useState, useEffect } from 'react';
import { User, Product, SellerSubscription } from '../types';
import { store } from '../services/store';
import { 
  Package, 
  AlertTriangle, 
  AlertCircle, 
  Plus, 
  SlidersHorizontal, 
  Crown, 
  ArrowUpRight, 
  Star,
  Trash2,
  Calendar
} from 'lucide-react';

interface SellerDashboardProps {
  user: User;
  onOpenAddProduct: () => void;
  onOpenStockScreen: () => void;
  onOpenUpgrade: (suggestedTier: 'basic' | 'pro') => void;
  onOpenFeaturedSelect: () => void;
}

export const SellerDashboard: React.FC<SellerDashboardProps> = ({
  user,
  onOpenAddProduct,
  onOpenStockScreen,
  onOpenUpgrade,
  onOpenFeaturedSelect,
}) => {
  const [products, setProducts] = useState<Product[]>([]);
  const [sub, setSub] = useState<SellerSubscription>(store.getSubscription(user.id));

  useEffect(() => {
    const update = () => {
      setProducts(store.getSellerProducts(user.id, true));
      setSub(store.getSubscription(user.id));
    };
    update();
    return store.subscribe(update);
  }, [user.id]);

  const getDaysLeft = (expiryDate: string): number => {
    const expiry = new Date(expiryDate);
    const now = new Date();
    const d1 = new Date(expiry.getFullYear(), expiry.getMonth(), expiry.getDate()).getTime();
    const d2 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return Math.ceil((d1 - d2) / (1000 * 60 * 60 * 24));
  };

  const isExpired = (p: Product) => getDaysLeft(p.expiryDate) < 0;
  const isExpiringSoon = (p: Product) => {
    const d = getDaysLeft(p.expiryDate);
    return d >= 0 && d <= 5;
  };

  const expiredCount = products.filter(isExpired).length;
  const expiringSoonCount = products.filter(isExpiringSoon).length;
  const hiddenCount = products.filter((p) => p.hidden).length;

  const getExpiryText = (p: Product) => {
    const days = getDaysLeft(p.expiryDate);
    if (days < 0) {
      const overdue = Math.abs(days);
      return overdue === 1 ? 'Expired 1 day ago' : `Expired ${overdue} days ago`;
    }
    if (days === 0) return 'Expires today';
    if (days === 1) return 'Expires tomorrow';
    return `Expires in ${days} days`;
  };

  return (
    <div className="pb-28 pt-3 max-w-xl mx-auto px-4 relative">
      {/* Welcome Card matching Flutter */}
      <div className="bg-white rounded-2xl p-4 mb-4 border border-gray-200 shadow-sm">
        <h2 className="text-base font-bold text-gray-900">
          Welcome back, {user.name}!
        </h2>
        <p className="text-xs text-gray-500 mt-0.5">
          Manage your inventory and reduce food waste.
        </p>
      </div>

      {/* Plan Banner */}
      <div
        className={`rounded-2xl p-4 mb-4 border flex items-center justify-between gap-3 shadow-sm ${
          sub.status === 'active'
            ? 'bg-emerald-50 border-emerald-200 text-emerald-950'
            : 'bg-amber-50 border-amber-200 text-amber-950'
        }`}
      >
        <div className="flex items-start gap-3 flex-1 min-w-0">
          <div
            className={`p-2.5 rounded-xl shrink-0 ${
              sub.status === 'active' ? 'bg-emerald-600 text-white' : 'bg-amber-500 text-white'
            }`}
          >
            {sub.status === 'active' ? <Crown className="w-5 h-5" /> : <ArrowUpRight className="w-5 h-5" />}
          </div>
          <div className="min-w-0">
            <h4 className="font-bold text-sm leading-tight">
              {sub.status === 'active'
                ? `Plano ${sub.tier === 'pro' ? 'Pro' : 'Basic'} ativo`
                : `Você está no plano Grátis (${sub.productLimit < 0 ? 'ilimitado' : `limite ${sub.productLimit}`})`}
            </h4>
            <p className="text-xs mt-0.5 opacity-90 leading-snug">
              {sub.status === 'active'
                ? 'Você pode destacar 1 produto no feed público.'
                : hiddenCount > 0
                ? `Você tem ${hiddenCount} produto(s) oculto(s) por exceder o limite. Reduza o estoque ou faça upgrade.`
                : 'Faça upgrade para liberar até 1000 produtos ou produtos ilimitados e fotos.'}
            </p>
          </div>
        </div>

        {sub.status === 'active' ? (
          <button
            onClick={onOpenFeaturedSelect}
            className="shrink-0 px-3 py-1.5 bg-emerald-700 hover:bg-emerald-800 text-white text-xs font-semibold rounded-lg transition shadow-sm cursor-pointer flex items-center gap-1"
          >
            <Star className="w-3.5 h-3.5" />
            Destacar
          </button>
        ) : (
          <button
            onClick={() => onOpenUpgrade(products.length >= 1000 ? 'pro' : 'basic')}
            className="shrink-0 px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold rounded-lg transition shadow-sm cursor-pointer"
          >
            Upgrade
          </button>
        )}
      </div>

      {/* Inventory Overview matching Flutter _buildSummaryCard */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-bold text-gray-900 text-sm">Inventory Overview</h3>
          <button
            onClick={onOpenStockScreen}
            className="text-xs font-semibold text-emerald-700 hover:text-emerald-800 flex items-center gap-1 cursor-pointer bg-emerald-50 px-2.5 py-1 rounded-lg"
          >
            <SlidersHorizontal className="w-3.5 h-3.5" />
            Gerenciar Estoque
          </button>
        </div>

        <div className="grid grid-cols-3 gap-2.5">
          {/* Total products */}
          <div className="bg-white rounded-xl p-3 border border-gray-200 text-center shadow-sm">
            <Package className="w-5 h-5 mx-auto text-emerald-600 mb-1" />
            <span className="block text-xl font-black text-gray-900 leading-tight">
              {products.length}
            </span>
            <span className="text-[11px] text-gray-500 font-medium">Products</span>
          </div>

          {/* Expiring soon */}
          <div className="bg-white rounded-xl p-3 border border-gray-200 text-center shadow-sm">
            <AlertTriangle
              className={`w-5 h-5 mx-auto mb-1 ${
                expiringSoonCount > 0 ? 'text-amber-500' : 'text-emerald-600'
              }`}
            />
            <span
              className={`block text-xl font-black leading-tight ${
                expiringSoonCount > 0 ? 'text-amber-600' : 'text-gray-900'
              }`}
            >
              {expiringSoonCount}
            </span>
            <span className="text-[11px] text-gray-500 font-medium">Expiring</span>
          </div>

          {/* Expired */}
          <div className="bg-white rounded-xl p-3 border border-gray-200 text-center shadow-sm">
            <AlertCircle
              className={`w-5 h-5 mx-auto mb-1 ${
                expiredCount > 0 ? 'text-red-500' : 'text-emerald-600'
              }`}
            />
            <span
              className={`block text-xl font-black leading-tight ${
                expiredCount > 0 ? 'text-red-600' : 'text-gray-900'
              }`}
            >
              {expiredCount}
            </span>
            <span className="text-[11px] text-gray-500 font-medium">Expired</span>
          </div>
        </div>
      </div>

      {/* My Products Section */}
      <div>
        <div className="flex items-center justify-between mb-2.5 px-0.5">
          <h3 className="font-bold text-gray-900 text-sm">My Products</h3>
          <span className="text-xs text-gray-500 font-medium">{products.length} items</span>
        </div>

        {products.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm">
            <Package className="w-10 h-10 mx-auto text-gray-300 mb-2" />
            <p className="text-gray-600 text-sm font-medium">No products yet.</p>
            <p className="text-xs text-gray-400 mt-0.5 mb-4">Tap + to add your first product.</p>
            <button
              onClick={onOpenAddProduct}
              className="px-4 py-2 bg-emerald-600 text-white rounded-lg text-xs font-semibold hover:bg-emerald-700 transition"
            >
              Add Product
            </button>
          </div>
        ) : (
          <div className="space-y-2.5">
            {products.map((product) => {
              const expired = isExpired(product);
              const expiring = isExpiringSoon(product);

              return (
                <div
                  key={product.id}
                  className={`bg-white rounded-xl p-3 border shadow-sm flex items-center justify-between gap-3 ${
                    product.hidden ? 'opacity-60 bg-gray-50 border-dashed border-gray-300' : 'border-gray-200'
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0 flex-1">
                    <div
                      className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                        expired
                          ? 'bg-red-100 text-red-600'
                          : expiring
                          ? 'bg-amber-100 text-amber-600'
                          : 'bg-emerald-100 text-emerald-700'
                      }`}
                    >
                      {expired ? (
                        <AlertCircle className="w-5 h-5" />
                      ) : expiring ? (
                        <AlertTriangle className="w-5 h-5" />
                      ) : (
                        <Package className="w-5 h-5" />
                      )}
                    </div>

                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1.5">
                        <h4 className="font-bold text-gray-900 text-sm truncate">
                          {product.name}
                        </h4>
                        {product.isFeatured && (
                          <span className="text-[10px] bg-amber-100 text-amber-800 font-semibold px-1.5 py-0.2 rounded flex items-center gap-0.5">
                            <Star className="w-2.5 h-2.5 fill-amber-500 text-amber-500" />
                            Destaque
                          </span>
                        )}
                        {product.hidden && (
                          <span className="text-[10px] bg-gray-200 text-gray-700 font-semibold px-1.5 py-0.2 rounded">
                            Oculto
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-gray-500 mt-0.5">
                        {product.quantity} units • {getExpiryText(product)}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => store.deleteProduct(product.id)}
                      title="Excluir produto"
                      className="p-1.5 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50 transition cursor-pointer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                    {(expiring || expired) && (
                      <AlertTriangle className="w-4 h-4 text-red-500 shrink-0" />
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Floating Action Button "+ Add Product" matching Flutter FloatingActionButton.extended */}
      <button
        onClick={onOpenAddProduct}
        className="fixed bottom-20 right-5 z-20 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm px-5 py-3 rounded-full shadow-lg flex items-center gap-2 cursor-pointer transition transform active:scale-95 border-2 border-white/30"
      >
        <Plus className="w-5 h-5" />
        <span>Add Product</span>
      </button>
    </div>
  );
};
