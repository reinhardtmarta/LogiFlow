import React, { useState, useEffect } from 'react';
import { Product } from '../types';
import { store } from '../services/store';
import { Search, X, MessageSquare, PackageSearch, Tag } from 'lucide-react';

interface SearchScreenProps {
  onOpenChat: (receiverId: string, receiverName: string) => void;
}

export const SearchScreen: React.FC<SearchScreenProps> = ({ onOpenChat }) => {
  const [query, setQuery] = useState('');
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    const update = () => {
      setProducts(store.getProducts());
    };
    update();
    return store.subscribe(update);
  }, []);

  const cleanQuery = query.trim().toLowerCase();

  const filtered = cleanQuery
    ? products.filter(
        (p) =>
          p.name.toLowerCase().includes(cleanQuery) ||
          p.category.toLowerCase().includes(cleanQuery) ||
          p.address.toLowerCase().includes(cleanQuery)
      )
    : [];

  const suggestedCategories = [
    'Fruits & Vegetables',
    'Dairy',
    'Bakery',
    'Beverages',
    'Grains & Pasta',
  ];

  return (
    <div className="pb-24 pt-3 max-w-xl mx-auto px-4">
      <div className="mb-4">
        <h2 className="text-xl font-bold text-gray-900">Search Food</h2>
        <p className="text-xs text-gray-500">Busque por produtos, categorias ou regiões</p>
      </div>

      {/* Search Input Bar */}
      <div className="relative mb-3">
        <Search className="w-5 h-5 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search for bread, milk, fruits..."
          className="w-full pl-10 pr-10 py-2.5 bg-white border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 shadow-sm"
        />
        {query && (
          <button
            onClick={() => setQuery('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 p-1"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Suggested Search Pills */}
      {!cleanQuery && (
        <div className="mb-6">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Categorias em alta
          </p>
          <div className="flex flex-wrap gap-2">
            {suggestedCategories.map((cat) => (
              <button
                key={cat}
                onClick={() => setQuery(cat)}
                className="px-3 py-1.5 rounded-full text-xs font-medium bg-white hover:bg-emerald-50 text-gray-700 hover:text-emerald-700 border border-gray-200 transition cursor-pointer flex items-center gap-1.5"
              >
                <Tag className="w-3 h-3 text-emerald-600" />
                {cat}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Results Section */}
      {!cleanQuery ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-100 p-8 shadow-sm">
          <PackageSearch className="w-12 h-12 mx-auto text-gray-300 mb-2" />
          <p className="text-gray-500 text-sm font-medium">Type something to search</p>
          <p className="text-xs text-gray-400 mt-1">Ex: maçã, leite fresco, pão integral</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-100 p-8 shadow-sm">
          <PackageSearch className="w-12 h-12 mx-auto text-gray-300 mb-2" />
          <p className="text-gray-500 text-sm font-medium">No products found</p>
          <p className="text-xs text-gray-400 mt-1">
            Nenhum produto correspondente a "{query}" foi encontrado.
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100 overflow-hidden shadow-sm">
          {filtered.map((product) => (
            <div
              key={product.id}
              onClick={() => onOpenChat(product.userId, 'Seller')}
              className="p-3.5 hover:bg-emerald-50/50 transition cursor-pointer flex items-center justify-between gap-3 group"
            >
              <div className="flex items-center gap-3 min-w-0 flex-1">
                <div className="w-10 h-10 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center shrink-0">
                  <PackageSearch className="w-5 h-5" />
                </div>
                <div className="min-w-0 flex-1">
                  <h4 className="font-bold text-gray-900 text-sm truncate group-hover:text-emerald-700 transition">
                    {product.name}
                  </h4>
                  <p className="text-xs text-gray-500 mt-0.5 truncate">
                    {product.category} • {product.address}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3 shrink-0">
                <span className="font-bold text-sm text-emerald-700">
                  R$ {product.price.toFixed(2)}
                </span>
                <span className="p-1.5 rounded-lg bg-gray-50 group-hover:bg-emerald-100 text-gray-400 group-hover:text-emerald-700 transition">
                  <MessageSquare className="w-4 h-4" />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
