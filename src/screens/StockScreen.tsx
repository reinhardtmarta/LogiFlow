import React, { useState, useEffect } from 'react';
import { User, Product } from '../types';
import { store } from '../services/store';
import { ArrowLeft, MinusCircle, PlusCircle, AlertTriangle, Package } from 'lucide-react';

interface StockScreenProps {
  user: User;
  onBack: () => void;
}

export const StockScreen: React.FC<StockScreenProps> = ({ user, onBack }) => {
  const [selectedStatus, setSelectedStatus] = useState('All');
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    const update = () => {
      setProducts(store.getSellerProducts(user.id, true));
    };
    update();
    return store.subscribe(update);
  }, [user.id]);

  const filters = ['All', 'New', 'Cleaned', 'Packaged', 'Expiring'];

  const getDaysLeft = (expiryDate: string): number => {
    const expiry = new Date(expiryDate);
    const now = new Date();
    const d1 = new Date(expiry.getFullYear(), expiry.getMonth(), expiry.getDate()).getTime();
    const d2 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return Math.ceil((d1 - d2) / (1000 * 60 * 60 * 24));
  };

  const handleUpdateQty = (p: Product, change: number) => {
    const newQty = Math.max(0, Math.min(999, p.quantity + change));
    store.updateProductStock(p.id, newQty);
  };

  const filteredProducts = products.filter((p) => {
    if (selectedStatus === 'All') return true;
    if (selectedStatus === 'Expiring') {
      return getDaysLeft(p.expiryDate) <= 3;
    }
    return p.condition.toLowerCase().includes(selectedStatus.toLowerCase());
  });

  return (
    <div className="pb-24 pt-3 max-w-xl mx-auto px-4">
      {/* Top Header */}
      <div className="flex items-center gap-3 mb-4">
        <button
          onClick={onBack}
          className="p-2 rounded-xl bg-white border border-gray-200 text-gray-700 hover:bg-gray-100 transition cursor-pointer"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div>
          <h2 className="text-xl font-bold text-gray-900">My Stock Management</h2>
          <p className="text-xs text-gray-500">Ajuste o estoque em tempo real para sincronização</p>
        </div>
      </div>

      {/* Filter Chips matching Flutter _buildStatusFilter */}
      <div className="flex gap-2 overflow-x-auto pb-3 mb-3">
        {filters.map((status) => {
          const isActive = selectedStatus === status;
          return (
            <button
              key={status}
              onClick={() => setSelectedStatus(status)}
              className={`px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition cursor-pointer border ${
                isActive
                  ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs'
                  : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
              }`}
            >
              {status}
            </button>
          );
        })}
      </div>

      {/* Products List */}
      {filteredProducts.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-100 p-8 shadow-sm">
          <Package className="w-12 h-12 mx-auto text-gray-300 mb-2" />
          <p className="text-gray-500 text-sm font-medium">No products in stock.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredProducts.map((item) => {
            const daysLeft = getDaysLeft(item.expiryDate);
            const isExpiring = daysLeft <= 3;

            return (
              <div
                key={item.id}
                className="bg-white rounded-xl p-3.5 border border-gray-200 shadow-sm flex items-center justify-between gap-3"
              >
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                      isExpiring ? 'bg-red-100 text-red-600' : 'bg-emerald-100 text-emerald-700'
                    }`}
                  >
                    <Package className="w-5 h-5" />
                  </div>

                  <div className="min-w-0 flex-1">
                    <h4 className="font-bold text-gray-900 text-sm truncate">
                      {item.name}
                    </h4>
                    <p className="text-xs text-gray-500 mt-0.5">
                      Status: <span className="font-semibold">{item.condition}</span>
                    </p>
                    <p
                      className={`text-xs mt-0.5 font-medium ${
                        isExpiring ? 'text-red-600 font-bold' : 'text-gray-500'
                      }`}
                    >
                      {isExpiring
                        ? `⚠️ ${daysLeft <= 0 ? 'Vence hoje / vencido' : `${daysLeft} days until expiry!`}`
                        : `Expires in ${daysLeft} days`}
                    </p>
                  </div>
                </div>

                {/* Trailing Quantity Controls matching Flutter */}
                <div className="flex items-center gap-2 shrink-0 bg-gray-50 px-2 py-1 rounded-xl border border-gray-200">
                  <button
                    onClick={() => handleUpdateQty(item, -1)}
                    disabled={item.quantity <= 0}
                    className="text-gray-500 hover:text-red-600 disabled:opacity-30 p-1 cursor-pointer transition"
                    title="Diminuir"
                  >
                    <MinusCircle className="w-5 h-5" />
                  </button>
                  <span className="w-8 text-center font-bold text-sm text-gray-900">
                    {item.quantity}
                  </span>
                  <button
                    onClick={() => handleUpdateQty(item, 1)}
                    className="text-gray-500 hover:text-emerald-600 p-1 cursor-pointer transition"
                    title="Aumentar"
                  >
                    <PlusCircle className="w-5 h-5" />
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
