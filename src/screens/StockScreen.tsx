import React, { useState, useEffect, useMemo } from 'react';
import { User, Product } from '../types';
import { store } from '../services/store';
import { useLanguage } from '../context/LanguageContext';
import { 
  ArrowLeft, 
  MinusCircle, 
  PlusCircle, 
  AlertTriangle, 
  Package, 
  Search, 
  Filter, 
  ArrowUpDown, 
  Eye, 
  EyeOff, 
  Trash2, 
  Star, 
  Clock, 
  CheckCircle2, 
  Layers, 
  Tag, 
  Flame, 
  BookmarkCheck,
  X
} from 'lucide-react';

interface StockScreenProps {
  user: User;
  onBack: () => void;
  onOpenUpgrade?: () => void;
}

type StatusFilter = 'all' | 'urgent' | 'available' | 'reserved' | 'out_of_stock' | 'featured' | 'hidden';
type SortOption = 'expiry_asc' | 'qty_asc' | 'qty_desc' | 'price_asc' | 'price_desc' | 'newest';

export const StockScreen: React.FC<StockScreenProps> = ({ user, onBack, onOpenUpgrade }) => {
  const { t } = useLanguage();
  const [products, setProducts] = useState<Product[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [sortOption, setSortOption] = useState<SortOption>('expiry_asc');
  const [editingQtyId, setEditingQtyId] = useState<string | null>(null);
  const [manualQtyValue, setManualQtyValue] = useState<string>('');
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const sub = store.getSubscription(user.id);

  useEffect(() => {
    const update = () => {
      setProducts(store.getSellerProducts(user.id, true));
    };
    update();
    return store.subscribe(update);
  }, [user.id]);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 2500);
  };

  const getDaysLeft = (expiryDate: string): number => {
    const expiry = new Date(expiryDate);
    const now = new Date();
    const d1 = new Date(expiry.getFullYear(), expiry.getMonth(), expiry.getDate()).getTime();
    const d2 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return Math.ceil((d1 - d2) / (1000 * 60 * 60 * 24));
  };

  // Stock summary metrics
  const totalCount = products.length;
  const urgentCount = products.filter((p) => getDaysLeft(p.expiryDate) <= 3 && p.quantity > 0 && !p.isReserved).length;
  const availableCount = products.filter((p) => p.quantity > 0 && !p.isReserved).length;
  const reservedCount = products.filter((p) => Boolean(p.isReserved)).length;
  const outOfStockCount = products.filter((p) => p.quantity === 0).length;
  const hiddenCount = products.filter((p) => p.hidden).length;

  // Extract unique categories
  const categories = useMemo(() => {
    const set = new Set<string>();
    products.forEach((p) => {
      if (p.category) set.add(p.category);
    });
    return Array.from(set);
  }, [products]);

  // Quantity updates
  const handleUpdateQty = (p: Product, change: number) => {
    const newQty = Math.max(0, Math.min(100000, p.quantity + change));
    store.updateProductStock(p.id, newQty);
    showToast(`"${p.name}": ${newQty} ${t('units_available')}`);
  };

  const handleSaveManualQty = (p: Product) => {
    const val = parseInt(manualQtyValue, 10);
    if (!isNaN(val) && val >= 0) {
      store.updateProductStock(p.id, Math.min(100000, val));
      showToast(`"${p.name}": ${val} ${t('units_available')}`);
    }
    setEditingQtyId(null);
  };

  const handleToggleVisibility = async (p: Product) => {
    await store.toggleProductVisibility(p.id);
    showToast(p.hidden ? `"${p.name}" ${t('stock_filter_available')}` : `"${p.name}" ${t('stock_filter_hidden')}`);
  };

  const handleToggleReserved = async (p: Product) => {
    await store.toggleProductReserved(p.id);
    showToast(p.isReserved ? `"${p.name}" - ${t('stock_unmark_reserved')}` : `"${p.name}" - ${t('stock_reserved_badge')}`);
  };

  const handleDeleteProduct = async (productId: string) => {
    await store.deleteProduct(productId);
    setDeleteConfirmId(null);
    showToast('Item excluído com sucesso.');
  };

  // Filtered & Sorted Product List
  const filteredProducts = useMemo(() => {
    return products
      .filter((p) => {
        // Search query
        if (searchQuery.trim()) {
          const q = searchQuery.toLowerCase();
          const matchesName = p.name.toLowerCase().includes(q);
          const matchesCat = p.category.toLowerCase().includes(q);
          const matchesAddress = (p.address || '').toLowerCase().includes(q);
          if (!matchesName && !matchesCat && !matchesAddress) return false;
        }

        // Status filter
        if (statusFilter === 'urgent') {
          return getDaysLeft(p.expiryDate) <= 3 && p.quantity > 0 && !p.isReserved;
        }
        if (statusFilter === 'available') {
          return p.quantity > 0 && !p.isReserved;
        }
        if (statusFilter === 'reserved') {
          return Boolean(p.isReserved);
        }
        if (statusFilter === 'out_of_stock') {
          return p.quantity === 0;
        }
        if (statusFilter === 'featured') {
          return p.isFeatured;
        }
        if (statusFilter === 'hidden') {
          return p.hidden;
        }

        return true;
      })
      .filter((p) => {
        // Category filter
        if (categoryFilter !== 'all') {
          return p.category === categoryFilter;
        }
        return true;
      })
      .sort((a, b) => {
        if (sortOption === 'expiry_asc') {
          return new Date(a.expiryDate).getTime() - new Date(b.expiryDate).getTime();
        }
        if (sortOption === 'qty_asc') {
          return a.quantity - b.quantity;
        }
        if (sortOption === 'qty_desc') {
          return b.quantity - a.quantity;
        }
        if (sortOption === 'price_asc') {
          return a.price - b.price;
        }
        if (sortOption === 'price_desc') {
          return b.price - a.price;
        }
        if (sortOption === 'newest') {
          return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        }
        return 0;
      });
  }, [products, searchQuery, statusFilter, categoryFilter, sortOption]);

  return (
    <div className="pb-28 pt-3 max-w-2xl mx-auto px-4">
      {/* Toast feedback */}
      {toastMessage && (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-emerald-900 text-white text-xs font-semibold px-4 py-2.5 rounded-full shadow-lg border border-emerald-700 animate-in fade-in duration-200">
          {toastMessage}
        </div>
      )}

      {/* Top Navigation Bar */}
      <div className="flex items-center justify-between gap-3 mb-4">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 rounded-xl bg-white border border-gray-200 text-gray-700 hover:bg-gray-100 transition cursor-pointer"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-gray-900">{t('stock_title')}</h2>
            <p className="text-xs text-gray-500">{t('stock_subtitle')}</p>
          </div>
        </div>

        {onOpenUpgrade && (
          <button
            onClick={onOpenUpgrade}
            className="px-3 py-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 rounded-xl text-xs font-bold transition flex items-center gap-1.5 cursor-pointer shrink-0"
          >
            <Layers className="w-3.5 h-3.5 text-emerald-600" />
            <span>{t('stock_capacity_badge')}</span>
          </button>
        )}
      </div>

      {/* Summary KPI Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-2 mb-4">
        {/* Total */}
        <div 
          onClick={() => setStatusFilter('all')}
          className={`p-3 rounded-2xl border transition cursor-pointer ${
            statusFilter === 'all' 
              ? 'bg-emerald-50 border-emerald-300 ring-2 ring-emerald-500/20' 
              : 'bg-white border-gray-200 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center justify-between text-[11px] text-gray-500 mb-1">
            <span>{t('stock_total_kpi')}</span>
            <Package className="w-3.5 h-3.5 text-gray-400" />
          </div>
          <p className="text-base font-black text-gray-900">
            {totalCount} <span className="text-[10px] font-normal text-gray-400">/ {sub.productLimit}</span>
          </p>
        </div>

        {/* Expiring Soon */}
        <div 
          onClick={() => setStatusFilter('urgent')}
          className={`p-3 rounded-2xl border transition cursor-pointer ${
            statusFilter === 'urgent' 
              ? 'bg-red-50 border-red-300 ring-2 ring-red-500/20' 
              : 'bg-white border-gray-200 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center justify-between text-[11px] text-red-600 font-bold mb-1">
            <span>{t('stock_urgent_kpi')}</span>
            <Flame className="w-3.5 h-3.5 text-red-500" />
          </div>
          <p className="text-base font-black text-red-600">{urgentCount}</p>
        </div>

        {/* Available */}
        <div 
          onClick={() => setStatusFilter('available')}
          className={`p-3 rounded-2xl border transition cursor-pointer ${
            statusFilter === 'available' 
              ? 'bg-emerald-50 border-emerald-300 ring-2 ring-emerald-500/20' 
              : 'bg-white border-gray-200 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center justify-between text-[11px] text-emerald-700 font-medium mb-1">
            <span>{t('stock_available_kpi')}</span>
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
          </div>
          <p className="text-base font-black text-emerald-700">{availableCount}</p>
        </div>

        {/* Reserved */}
        <div 
          onClick={() => setStatusFilter('reserved')}
          className={`p-3 rounded-2xl border transition cursor-pointer ${
            statusFilter === 'reserved' 
              ? 'bg-blue-50 border-blue-300 ring-2 ring-blue-500/20' 
              : 'bg-white border-gray-200 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center justify-between text-[11px] text-blue-700 font-medium mb-1">
            <span>{t('stock_reserved_kpi')}</span>
            <BookmarkCheck className="w-3.5 h-3.5 text-blue-600" />
          </div>
          <p className="text-base font-black text-blue-700">{reservedCount}</p>
        </div>

        {/* Out of Stock */}
        <div 
          onClick={() => setStatusFilter('out_of_stock')}
          className={`p-3 rounded-2xl border transition cursor-pointer col-span-2 sm:col-span-1 ${
            statusFilter === 'out_of_stock' 
              ? 'bg-gray-100 border-gray-400 ring-2 ring-gray-400/20' 
              : 'bg-white border-gray-200 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center justify-between text-[11px] text-gray-500 mb-1">
            <span>{t('stock_out_of_stock_kpi')}</span>
            <AlertTriangle className="w-3.5 h-3.5 text-amber-500" />
          </div>
          <p className="text-base font-black text-gray-600">{outOfStockCount}</p>
        </div>
      </div>

      {/* Real-time Search Bar */}
      <div className="relative mb-3">
        <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder={t('stock_search_placeholder')}
          className="w-full pl-10 pr-9 py-2.5 bg-white border border-gray-200 rounded-2xl text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500 shadow-xs"
        />
        {searchQuery && (
          <button
            onClick={() => setSearchQuery('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 p-1"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        )}
      </div>

      {/* Filter & Sort Bar */}
      <div className="space-y-2 mb-4 bg-white p-3 rounded-2xl border border-gray-200 shadow-xs">
        {/* Status Chips */}
        <div className="flex gap-1.5 overflow-x-auto pb-1 text-xs">
          <button
            onClick={() => setStatusFilter('all')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition cursor-pointer border ${
              statusFilter === 'all'
                ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs'
                : 'bg-gray-50 text-gray-700 border-gray-200 hover:bg-gray-100'
            }`}
          >
            {t('stock_filter_all')} ({totalCount})
          </button>

          <button
            onClick={() => setStatusFilter('urgent')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition cursor-pointer border flex items-center gap-1 ${
              statusFilter === 'urgent'
                ? 'bg-red-600 text-white border-red-600 shadow-xs'
                : 'bg-white text-red-700 border-red-200 hover:bg-red-50'
            }`}
          >
            <Flame className="w-3 h-3" />
            <span>{t('stock_filter_urgent')} ({urgentCount})</span>
          </button>

          <button
            onClick={() => setStatusFilter('available')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition cursor-pointer border flex items-center gap-1 ${
              statusFilter === 'available'
                ? 'bg-emerald-600 text-white border-emerald-600 shadow-xs'
                : 'bg-white text-emerald-800 border-emerald-200 hover:bg-emerald-50'
            }`}
          >
            <CheckCircle2 className="w-3 h-3" />
            <span>{t('stock_filter_available')} ({availableCount})</span>
          </button>

          <button
            onClick={() => setStatusFilter('reserved')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition cursor-pointer border flex items-center gap-1 ${
              statusFilter === 'reserved'
                ? 'bg-blue-600 text-white border-blue-600 shadow-xs'
                : 'bg-white text-blue-800 border-blue-200 hover:bg-blue-50'
            }`}
          >
            <BookmarkCheck className="w-3 h-3" />
            <span>{t('stock_filter_reserved')} ({reservedCount})</span>
          </button>

          <button
            onClick={() => setStatusFilter('out_of_stock')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition cursor-pointer border ${
              statusFilter === 'out_of_stock'
                ? 'bg-gray-800 text-white border-gray-800 shadow-xs'
                : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
            }`}
          >
            {t('stock_filter_out_of_stock')} ({outOfStockCount})
          </button>

          <button
            onClick={() => setStatusFilter('featured')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition cursor-pointer border flex items-center gap-1 ${
              statusFilter === 'featured'
                ? 'bg-amber-500 text-white border-amber-500 shadow-xs'
                : 'bg-white text-amber-800 border-amber-200 hover:bg-amber-50'
            }`}
          >
            <Star className="w-3 h-3 fill-current" />
            <span>{t('stock_filter_featured')}</span>
          </button>

          <button
            onClick={() => setStatusFilter('hidden')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition cursor-pointer border flex items-center gap-1 ${
              statusFilter === 'hidden'
                ? 'bg-purple-600 text-white border-purple-600 shadow-xs'
                : 'bg-white text-purple-700 border-purple-200 hover:bg-purple-50'
            }`}
          >
            <EyeOff className="w-3 h-3" />
            <span>{t('stock_filter_hidden')} ({hiddenCount})</span>
          </button>
        </div>

        {/* Category & Sorting Controls */}
        <div className="flex items-center justify-between gap-2 pt-2 border-t border-gray-100 flex-wrap sm:flex-nowrap">
          {/* Category Dropdown */}
          <div className="flex items-center gap-1.5 min-w-0 flex-1">
            <Tag className="w-3.5 h-3.5 text-gray-400 shrink-0" />
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="bg-gray-50 border border-gray-200 text-gray-700 text-xs rounded-xl px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-emerald-500 truncate w-full sm:w-auto"
            >
              <option value="all">{t('stock_category_all')}</option>
              {categories.map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
            </select>
          </div>

          {/* Sorting Dropdown */}
          <div className="flex items-center gap-1.5 shrink-0 w-full sm:w-auto justify-end">
            <ArrowUpDown className="w-3.5 h-3.5 text-gray-400" />
            <select
              value={sortOption}
              onChange={(e) => setSortOption(e.target.value as SortOption)}
              className="bg-gray-50 border border-gray-200 text-gray-700 text-xs rounded-xl px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-emerald-500 font-medium"
            >
              <option value="expiry_asc">{t('stock_sort_expiry_asc')}</option>
              <option value="qty_asc">{t('stock_sort_qty_asc')}</option>
              <option value="qty_desc">{t('stock_sort_qty_desc')}</option>
              <option value="price_asc">{t('stock_sort_price_asc')}</option>
              <option value="price_desc">{t('stock_sort_price_desc')}</option>
              <option value="newest">{t('stock_sort_newest')}</option>
            </select>
          </div>
        </div>
      </div>

      {/* Product List */}
      {filteredProducts.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-3xl border border-gray-100 p-8 shadow-sm">
          <Package className="w-12 h-12 mx-auto text-gray-300 mb-2" />
          <h3 className="font-bold text-gray-800 text-sm">{t('stock_empty_title')}</h3>
          <p className="text-xs text-gray-400 mt-1 max-w-xs mx-auto">
            {t('stock_empty_desc')}
          </p>
          {(statusFilter !== 'all' || categoryFilter !== 'all' || searchQuery) && (
            <button
              onClick={() => {
                setStatusFilter('all');
                setCategoryFilter('all');
                setSearchQuery('');
              }}
              className="mt-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition cursor-pointer"
            >
              {t('clear_filters_btn')}
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {filteredProducts.map((item) => {
            const daysLeft = getDaysLeft(item.expiryDate);
            const isUrgent = daysLeft <= 3 && item.quantity > 0 && !item.isReserved;
            const isExpired = daysLeft <= 0;
            const isEditingThis = editingQtyId === item.id;
            const image = item.imagePaths?.[0] || item.imagePath;

            return (
              <div
                key={item.id}
                className={`bg-white rounded-2xl p-4 border transition-all shadow-xs ${
                  item.hidden
                    ? 'border-dashed border-gray-300 opacity-70 bg-gray-50/50'
                    : item.isReserved
                    ? 'border-blue-200 bg-blue-50/20'
                    : isUrgent
                    ? 'border-red-200 bg-gradient-to-r from-red-50/30 to-white'
                    : 'border-gray-200 hover:border-emerald-300'
                }`}
              >
                <div className="flex items-start justify-between gap-3 mb-3">
                  {/* Image & Main Info */}
                  <div className="flex items-start gap-3 min-w-0 flex-1">
                    {image ? (
                      <img
                        src={image}
                        alt={item.name}
                        className="w-14 h-14 rounded-2xl object-cover shrink-0 border border-gray-200 shadow-2xs"
                      />
                    ) : (
                      <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 font-bold text-lg shadow-2xs">
                        🌱
                      </div>
                    )}

                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <h4 className="font-bold text-gray-900 text-sm truncate">
                          {item.name}
                        </h4>
                        {item.isFeatured && (
                          <span className="text-[10px] font-bold bg-amber-100 text-amber-900 px-2 py-0.2 rounded-full flex items-center gap-0.5">
                            <Star className="w-2.5 h-2.5 fill-current" /> {t('badge_featured')}
                          </span>
                        )}
                        {item.isReserved && (
                          <span className="text-[10px] font-bold bg-blue-100 text-blue-900 px-2 py-0.2 rounded-full flex items-center gap-0.5">
                            <BookmarkCheck className="w-2.5 h-2.5" /> {t('stock_reserved_badge')}
                          </span>
                        )}
                        {item.hidden && (
                          <span className="text-[10px] font-bold bg-purple-100 text-purple-800 px-2 py-0.2 rounded-full">
                            {t('stock_filter_hidden')}
                          </span>
                        )}
                        {item.quantity === 0 && (
                          <span className="text-[10px] font-bold bg-red-100 text-red-700 px-2 py-0.2 rounded-full">
                            {t('stock_filter_out_of_stock')}
                          </span>
                        )}
                      </div>

                      <p className="text-xs text-gray-500 mt-0.5">
                        <span className="font-semibold text-gray-700">{item.category}</span> • R$ {item.price.toFixed(2)} / un
                      </p>

                      {/* Expiry countdown badge */}
                      <div className="mt-1 flex items-center gap-2 flex-wrap">
                        <span
                          className={`text-[11px] font-bold px-2 py-0.5 rounded-lg inline-flex items-center gap-1 ${
                            isExpired
                              ? 'bg-red-100 text-red-800'
                              : isUrgent
                              ? 'bg-amber-100 text-amber-900 animate-pulse'
                              : 'bg-emerald-50 text-emerald-800'
                          }`}
                        >
                          <Clock className="w-3 h-3" />
                          {isExpired
                            ? 'Vencimento atingido'
                            : daysLeft === 1
                            ? 'Vence amanhã (Urgente!)'
                            : `${t('expires_on_prefix')} ${daysLeft}d (${new Date(item.expiryDate).toLocaleDateString()})`}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Top Right Quick Actions */}
                  <div className="flex items-center gap-1 shrink-0">
                    {/* Toggle Reservation */}
                    <button
                      onClick={() => handleToggleReserved(item)}
                      className={`p-1.5 rounded-xl border transition cursor-pointer ${
                        item.isReserved
                          ? 'bg-blue-600 text-white border-blue-600 hover:bg-blue-700'
                          : 'bg-gray-50 text-gray-500 border-gray-200 hover:bg-blue-50 hover:text-blue-600'
                      }`}
                      title={item.isReserved ? t('stock_unmark_reserved') : t('stock_mark_reserved')}
                    >
                      <BookmarkCheck className="w-4 h-4" />
                    </button>

                    {/* Toggle Visibility */}
                    <button
                      onClick={() => handleToggleVisibility(item)}
                      className={`p-1.5 rounded-xl border transition cursor-pointer ${
                        item.hidden
                          ? 'bg-purple-50 text-purple-700 border-purple-200 hover:bg-purple-100'
                          : 'bg-gray-50 text-gray-500 border-gray-200 hover:bg-gray-100'
                      }`}
                      title={item.hidden ? 'Tornar Visível' : 'Ocultar do Feed'}
                    >
                      {item.hidden ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>

                    {/* Delete button */}
                    <button
                      onClick={() => setDeleteConfirmId(item.id)}
                      className="p-1.5 rounded-xl bg-gray-50 text-gray-400 hover:text-red-600 hover:bg-red-50 border border-gray-200 transition cursor-pointer"
                      title="Excluir Produto"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Stock Controls & Increment Steppers */}
                <div className="pt-3 border-t border-gray-100 flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5">
                    <span className="text-xs text-gray-500 font-medium">Estoque:</span>
                    {isEditingThis ? (
                      <div className="flex items-center gap-1">
                        <input
                          type="number"
                          value={manualQtyValue}
                          onChange={(e) => setManualQtyValue(e.target.value)}
                          min="0"
                          max="100000"
                          className="w-16 px-2 py-1 bg-white border border-emerald-500 rounded-lg text-xs font-bold text-gray-900 focus:outline-none"
                          autoFocus
                        />
                        <button
                          onClick={() => handleSaveManualQty(item)}
                          className="px-2 py-1 bg-emerald-600 text-white rounded-lg text-xs font-bold hover:bg-emerald-700 cursor-pointer"
                        >
                          {t('stock_save_btn')}
                        </button>
                        <button
                          onClick={() => setEditingQtyId(null)}
                          className="px-2 py-1 bg-gray-100 text-gray-600 rounded-lg text-xs font-semibold hover:bg-gray-200 cursor-pointer"
                        >
                          {t('stock_cancel_btn')}
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => {
                          setEditingQtyId(item.id);
                          setManualQtyValue(item.quantity.toString());
                        }}
                        className="px-2.5 py-0.5 bg-gray-100 hover:bg-gray-200 text-gray-900 font-extrabold text-sm rounded-lg border border-gray-200 transition cursor-pointer"
                        title="Clique para digitar quantidade exata"
                      >
                        {item.quantity} un ✏️
                      </button>
                    )}
                  </div>

                  {/* Stepper Buttons: -1, +1, +5, +10 */}
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => handleUpdateQty(item, -1)}
                      disabled={item.quantity <= 0}
                      className="p-1.5 rounded-lg bg-gray-50 hover:bg-red-50 text-gray-600 hover:text-red-600 border border-gray-200 transition cursor-pointer disabled:opacity-30"
                      title="Diminuir 1"
                    >
                      <MinusCircle className="w-4 h-4" />
                    </button>

                    <button
                      onClick={() => handleUpdateQty(item, 1)}
                      className="p-1.5 rounded-lg bg-gray-50 hover:bg-emerald-50 text-gray-600 hover:text-emerald-700 border border-gray-200 transition cursor-pointer"
                      title="Adicionar 1"
                    >
                      <PlusCircle className="w-4 h-4" />
                    </button>

                    <button
                      onClick={() => handleUpdateQty(item, 5)}
                      className="px-2 py-1 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 text-xs font-bold transition cursor-pointer"
                      title="Adicionar 5 unidades"
                    >
                      +5
                    </button>

                    <button
                      onClick={() => handleUpdateQty(item, 10)}
                      className="px-2 py-1 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 text-xs font-bold transition cursor-pointer"
                      title="Adicionar 10 unidades"
                    >
                      +10
                    </button>
                  </div>
                </div>

                {/* Inline Delete Confirmation */}
                {deleteConfirmId === item.id && (
                  <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-xl text-xs text-red-900 flex items-center justify-between gap-2 animate-in fade-in">
                    <span>Tem certeza que deseja excluir este item?</span>
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleDeleteProduct(item.id)}
                        className="px-3 py-1 bg-red-600 text-white rounded-lg font-bold hover:bg-red-700 cursor-pointer"
                      >
                        Excluir
                      </button>
                      <button
                        onClick={() => setDeleteConfirmId(null)}
                        className="px-3 py-1 bg-white border border-gray-300 text-gray-700 rounded-lg font-semibold hover:bg-gray-100 cursor-pointer"
                      >
                        {t('stock_cancel_btn')}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
