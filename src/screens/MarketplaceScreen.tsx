import React, { useState, useEffect } from 'react';
import { Product, User } from '../types';
import { store } from '../services/store';
import { formatDistance } from '../utils/distance';
import { Search, AlertTriangle, Star, ShoppingBag, MessageSquare, Navigation } from 'lucide-react';

interface MarketplaceScreenProps {
  user: User;
  onOpenChat: (receiverId: string, receiverName: string) => void;
}

export const MarketplaceScreen: React.FC<MarketplaceScreenProps> = ({ user, onOpenChat }) => {
  const [searchQuery, setSearchQuery] = useState('');
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
    const d1 = new Date(expiry.getFullYear(), expiry.getMonth(), expiry.getDate()).getTime();
    const d2 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return Math.ceil((d1 - d2) / (1000 * 60 * 60 * 24));
  };

  const filteredProducts = products.filter((p) =>
    p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    p.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="pb-24 pt-3 max-w-xl mx-auto px-4">
      {/* Header bar matching Flutter */}
      <div className="mb-4">
        <h2 className="text-xl font-bold text-gray-900">Marketplace - Rescue Food</h2>
        <p className="text-xs text-gray-500">Compre direto de produtores com até 70% de desconto</p>
      </div>

      {/* Search Bar */}
      <div className="relative mb-4">
        <Search className="w-5 h-5 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search products..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 shadow-sm"
        />
      </div>

      {filteredProducts.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-100 p-8 shadow-sm">
          <ShoppingBag className="w-12 h-12 mx-auto text-gray-300 mb-2" />
          <p className="text-gray-500 text-sm font-medium">No products available yet</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredProducts.map((p) => {
            const daysLeft = getDaysLeft(p.expiryDate);
            const isRescue = daysLeft <= 3;
            const imageUrl = p.imagePaths?.[0] || p.imagePath;

            return (
              <div
                key={p.id}
                onClick={() => onOpenChat(p.userId, 'Seller')}
                className="bg-white rounded-xl p-3 border border-gray-200 shadow-sm hover:shadow-md transition-all flex items-center justify-between gap-3 cursor-pointer group"
              >
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  {imageUrl ? (
                    <img
                      src={imageUrl}
                      alt={p.name}
                      className="w-12 h-12 rounded-lg object-cover shrink-0 border border-gray-100 bg-gray-50"
                      onError={(e) => {
                        (e.currentTarget as HTMLImageElement).style.display = 'none';
                      }}
                    />
                  ) : (
                    <div className="w-12 h-12 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600 shrink-0">
                      <ShoppingBag className="w-6 h-6" />
                    </div>
                  )}

                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <h4 className="font-bold text-gray-900 text-sm truncate group-hover:text-emerald-700 transition">
                        {p.name}
                      </h4>
                      {p.isFeatured && (
                        <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-amber-100 text-amber-800">
                          <Star className="w-2.5 h-2.5 fill-amber-500 text-amber-500" />
                          Destaque
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-1.5 flex-wrap text-xs text-gray-500 mt-0.5">
                      <span>Expires in {daysLeft} days • R$ {p.price.toFixed(2)}</span>
                      {p.distanceMeters !== undefined && (
                        <span className="inline-flex items-center gap-0.5 text-[10px] font-bold text-emerald-800 bg-emerald-50 border border-emerald-200 px-1 py-0.2 rounded">
                          <Navigation className="w-2.5 h-2.5 text-emerald-600" />
                          {formatDistance(p.distanceMeters)}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex flex-col items-end shrink-0 justify-center">
                  <span className="font-bold text-sm text-emerald-700">
                    R$ {p.price.toFixed(2)}
                  </span>
                  <div className="flex items-center gap-1.5 mt-0.5">
                    {isRescue && (
                      <span title="Resgate urgente">
                        <AlertTriangle className="w-4 h-4 text-red-500" />
                      </span>
                    )}
                    <span className="p-1 rounded bg-gray-50 hover:bg-emerald-50 text-gray-400 group-hover:text-emerald-600">
                      <MessageSquare className="w-4 h-4" />
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
