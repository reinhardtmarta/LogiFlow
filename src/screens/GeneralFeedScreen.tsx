import React, { useState, useEffect, useMemo } from 'react';
import { Product, User } from '../types';
import { store } from '../services/store';
import { DistanceBot } from '../services/distanceBot';
import { DistanceBotModal } from '../components/DistanceBotModal';
import { useLanguage } from '../context/LanguageContext';
import { 
  Sparkles, 
  X, 
  Star, 
  AlertTriangle, 
  Leaf, 
  MapPin, 
  Package, 
  MessageSquareText, 
  Navigation,
  Bot,
  Filter,
  Clock,
  DollarSign,
  Compass,
  Bike,
  Footprints,
  SlidersHorizontal,
  ChevronDown
} from 'lucide-react';

interface GeneralFeedScreenProps {
  user: User;
  onOpenChat: (receiverId: string, receiverName: string) => void;
  aiInsightMessage: string | null;
  onDismissAiInsight: () => void;
}

type ExpiryFilter = 'all' | 'today' | '3days';
type PriceFilter = 'all' | 'free' | 'under15' | 'low_first' | 'high_first';
type DistanceFilter = 'all' | '2km' | '5km' | '10km';

export const GeneralFeedScreen: React.FC<GeneralFeedScreenProps> = ({
  user,
  onOpenChat,
  aiInsightMessage,
  onDismissAiInsight,
}) => {
  const { t } = useLanguage();
  const [products, setProducts] = useState<Product[]>([]);
  const [buyerRegion, setBuyerRegion] = useState<string>(
    user.address?.trim() || 'São Paulo, Centro'
  );
  const [isEditingRegion, setIsEditingRegion] = useState(false);
  const [tempRegion, setTempRegion] = useState(buyerRegion);

  // Filters State
  const [expiryFilter, setExpiryFilter] = useState<ExpiryFilter>('all');
  const [priceFilter, setPriceFilter] = useState<PriceFilter>('all');
  const [distanceFilter, setDistanceFilter] = useState<DistanceFilter>('all');
  const [showFiltersPanel, setShowFiltersPanel] = useState(false);

  // Distance Bot Modal State
  const [selectedProductForBot, setSelectedProductForBot] = useState<Product | null>(null);

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

  // Bot-Assisted Distance Calculation for each product
  const productsWithBotDistance = useMemo(() => {
    return products.map((p, idx) => {
      const botCalc = DistanceBot.calculate(buyerRegion, p.address || 'São Paulo, SP', idx);
      const days = getDaysLeft(p.expiryDate);
      return {
        ...p,
        botDistance: botCalc,
        daysLeft: days,
      };
    });
  }, [products, buyerRegion]);

  // Filter & Sort Pipeline
  const filteredProducts = useMemo(() => {
    let list = [...productsWithBotDistance];

    // 1. Expiry Filter
    if (expiryFilter === 'today') {
      list = list.filter((p) => p.daysLeft <= 1);
    } else if (expiryFilter === '3days') {
      list = list.filter((p) => p.daysLeft <= 3);
    }

    // 2. Price Filter
    if (priceFilter === 'free') {
      list = list.filter((p) => p.price === 0);
    } else if (priceFilter === 'under15') {
      list = list.filter((p) => p.price <= 15);
    }

    // 3. Local / Distance Filter (Bot-calculated)
    if (distanceFilter === '2km') {
      list = list.filter((p) => p.botDistance.distanceMeters <= 2000);
    } else if (distanceFilter === '5km') {
      list = list.filter((p) => p.botDistance.distanceMeters <= 5000);
    } else if (distanceFilter === '10km') {
      list = list.filter((p) => p.botDistance.distanceMeters <= 10000);
    }

    // Sorting
    list.sort((a, b) => {
      // Featured / Premium products pinned first
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;

      // Price Sort
      if (priceFilter === 'low_first') {
        return a.price - b.price;
      }
      if (priceFilter === 'high_first') {
        return b.price - a.price;
      }

      // Default sort by distance then expiry
      if (distanceFilter !== 'all') {
        return a.botDistance.distanceMeters - b.botDistance.distanceMeters;
      }

      return a.daysLeft - b.daysLeft;
    });

    return list;
  }, [productsWithBotDistance, expiryFilter, priceFilter, distanceFilter]);

  const activeFiltersCount =
    (expiryFilter !== 'all' ? 1 : 0) +
    (priceFilter !== 'all' ? 1 : 0) +
    (distanceFilter !== 'all' ? 1 : 0);

  const clearAllFilters = () => {
    setExpiryFilter('all');
    setPriceFilter('all');
    setDistanceFilter('all');
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
              {t('gemma_tip_title')}
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

      {/* Distance Bot: Reference Region Bar (No GPS needed!) */}
      <div className="bg-white rounded-2xl p-3 border border-gray-200 shadow-xs mb-3 flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0 flex-1">
          <div className="w-8 h-8 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
            <Bot className="w-4 h-4" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5">
              <span className="text-[10px] font-bold text-gray-400 uppercase">
                {t('distance_bot_title')}
              </span>
              <span className="text-[9px] bg-emerald-50 text-emerald-700 font-bold px-1.5 rounded">
                {t('no_gps_badge')}
              </span>
            </div>
            {!isEditingRegion ? (
              <p className="text-xs font-bold text-gray-800 truncate flex items-center gap-1">
                <span>{t('calc_from_label')}</span>
                <span className="text-emerald-700 underline underline-offset-2">{buyerRegion}</span>
              </p>
            ) : (
              <div className="flex items-center gap-1.5 mt-1">
                <input
                  type="text"
                  value={tempRegion}
                  onChange={(e) => setTempRegion(e.target.value)}
                  placeholder={t('region_placeholder')}
                  className="px-2 py-1 bg-gray-50 border border-gray-300 rounded-lg text-xs w-full focus:outline-none focus:ring-1 focus:ring-emerald-500"
                />
                <button
                  onClick={() => {
                    if (tempRegion.trim()) setBuyerRegion(tempRegion.trim());
                    setIsEditingRegion(false);
                  }}
                  className="px-2.5 py-1 bg-emerald-600 text-white text-[11px] font-bold rounded-lg cursor-pointer"
                >
                  {t('ok_btn')}
                </button>
              </div>
            )}
          </div>
        </div>

        {!isEditingRegion && (
          <button
            onClick={() => {
              setTempRegion(buyerRegion);
              setIsEditingRegion(true);
            }}
            className="text-[11px] font-bold text-emerald-700 hover:text-emerald-800 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 px-2.5 py-1.5 rounded-xl transition cursor-pointer shrink-0"
          >
            {t('change_region_btn')}
          </button>
        )}
      </div>

      {/* Filter Control Header */}
      <div className="bg-white rounded-2xl p-3 border border-gray-200 shadow-xs mb-4 space-y-2.5">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <SlidersHorizontal className="w-4 h-4 text-emerald-600" />
            <h3 className="font-bold text-xs text-gray-800 uppercase tracking-wider">
              {t('quickFilters')}
            </h3>
            {activeFiltersCount > 0 && (
              <span className="w-5 h-5 rounded-full bg-emerald-600 text-white text-[10px] font-bold flex items-center justify-center">
                {activeFiltersCount}
              </span>
            )}
          </div>

          <div className="flex items-center gap-2">
            {activeFiltersCount > 0 && (
              <button
                onClick={clearAllFilters}
                className="text-[11px] font-semibold text-gray-400 hover:text-red-600 cursor-pointer"
              >
                {t('clearFilters')}
              </button>
            )}
            <span className="text-xs font-bold text-gray-700 bg-gray-100 px-2 py-0.5 rounded-full">
              {filteredProducts.length} {t('itemsCount')}
            </span>
          </div>
        </div>

        {/* Filter Pills Grid: Vencimento, Valor, Local Próximo */}
        <div className="grid grid-cols-3 gap-2">
          {/* 1. Próximo do Vencimento */}
          <div>
            <label className="block text-[10px] font-bold text-gray-400 mb-1 flex items-center gap-1">
              <Clock className="w-3 h-3 text-red-500" />
              <span>{t('expiry')}</span>
            </label>
            <select
              value={expiryFilter}
              onChange={(e) => setExpiryFilter(e.target.value as ExpiryFilter)}
              className="w-full px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-medium text-gray-700 focus:outline-none focus:ring-1 focus:ring-emerald-500 cursor-pointer"
            >
              <option value="all">{t('expiryAll')}</option>
              <option value="today">{t('expiryToday')}</option>
              <option value="3days">{t('expiry3Days')}</option>
            </select>
          </div>

          {/* 2. Valor */}
          <div>
            <label className="block text-[10px] font-bold text-gray-400 mb-1 flex items-center gap-1">
              <DollarSign className="w-3 h-3 text-emerald-600" />
              <span>{t('price')}</span>
            </label>
            <select
              value={priceFilter}
              onChange={(e) => setPriceFilter(e.target.value as PriceFilter)}
              className="w-full px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-medium text-gray-700 focus:outline-none focus:ring-1 focus:ring-emerald-500 cursor-pointer"
            >
              <option value="all">{t('priceAll')}</option>
              <option value="free">{t('priceFree')}</option>
              <option value="under15">{t('priceUnder15')}</option>
              <option value="low_first">{t('priceLowFirst')}</option>
              <option value="high_first">{t('priceHighFirst')}</option>
            </select>
          </div>

          {/* 3. Local Próximo (Calculado pelo Bot) */}
          <div>
            <label className="block text-[10px] font-bold text-gray-400 mb-1 flex items-center gap-1">
              <Compass className="w-3 h-3 text-blue-600" />
              <span>{t('nearby')}</span>
            </label>
            <select
              value={distanceFilter}
              onChange={(e) => setDistanceFilter(e.target.value as DistanceFilter)}
              className="w-full px-2 py-1.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-medium text-gray-700 focus:outline-none focus:ring-1 focus:ring-emerald-500 cursor-pointer"
            >
              <option value="all">{t('distanceAll')}</option>
              <option value="2km">{t('distance2km')}</option>
              <option value="5km">{t('distance5km')}</option>
              <option value="10km">{t('distance10km')}</option>
            </select>
          </div>
        </div>
      </div>

      {/* Product List */}
      {filteredProducts.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-gray-100 p-8 shadow-sm">
          <div className="w-16 h-16 mx-auto mb-3 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
            <Package className="w-8 h-8" />
          </div>
          <h3 className="font-bold text-gray-800 text-base">{t('noItemsFound')}</h3>
          <p className="text-xs text-gray-500 mt-1 max-w-xs mx-auto">
            Tente expandir o raio de distância ou selecionar outros critérios de valor e vencimento.
          </p>
          <button
            onClick={clearAllFilters}
            className="mt-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs transition cursor-pointer"
          >
            {t('viewAllItems')}
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredProducts.map((p) => {
            const isUrgent = p.daysLeft <= 3;
            const isPremium = p.isFeatured;
            const image = p.imagePaths?.[0] || p.imagePath;

            return (
              <div
                key={p.id}
                className={`bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-all border ${
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
                      {t('badge_featured')}
                    </span>
                  )}
                  {isUrgent && (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-red-50 text-red-700 border border-red-200">
                      <AlertTriangle className="w-3 h-3" />
                      {t('badge_urgent')} ({p.daysLeft === 0 ? 'Hoje' : `${p.daysLeft}d`})
                    </span>
                  )}
                  {!isPremium && !isUrgent && (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                      <Leaf className="w-3 h-3" />
                      {t('badge_fresh')}
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
                      <h3 className="font-bold text-gray-900 text-base leading-tight truncate">
                        {p.name}
                      </h3>

                      {/* Location & Distance Calculated by the Bot */}
                      <div className="flex flex-wrap items-center gap-1.5 text-xs text-gray-500 mt-1">
                        <MapPin className="w-3.5 h-3.5 shrink-0 text-gray-400" />
                        <span className="truncate">{p.address}</span>

                        {/* Bot Distance Badge */}
                        <button
                          type="button"
                          onClick={() => setSelectedProductForBot(p)}
                          className="inline-flex items-center gap-1 text-[10px] font-bold text-emerald-800 bg-emerald-50 hover:bg-emerald-100 border border-emerald-300 px-2 py-0.5 rounded-full transition cursor-pointer"
                          title="Clique para ver detalhes calculados pelo Bot de Rota"
                        >
                          <Bot className="w-3 h-3 text-emerald-700" />
                          <span>{p.botDistance.distanceFormatted}</span>
                          <span className="text-gray-400 font-normal">
                            (~{p.botDistance.walkingMinutes} min)
                          </span>
                        </button>
                      </div>

                      <div className="flex items-center gap-3 text-xs text-gray-600 mt-1 font-medium">
                        <span className="flex items-center gap-1">
                          <Package className="w-3.5 h-3.5 text-gray-400" />
                          {p.quantity} {t('units_available')}
                        </span>
                        <span className="text-gray-400">•</span>
                        <span className="text-emerald-600 font-semibold">{p.condition}</span>
                      </div>
                    </div>
                  </div>

                  <div className="text-right shrink-0">
                    <span className="text-lg font-black text-emerald-700">
                      {p.price === 0 ? 'Grátis' : `R$ ${p.price.toFixed(2).replace('.', ',')}`}
                    </span>
                    <span className="block text-[10px] text-gray-400">
                      {t('expires_on_prefix')} {new Date(p.expiryDate).toLocaleDateString([], { day: '2-digit', month: '2-digit' })}
                    </span>
                  </div>
                </div>

                {/* Action Buttons: Distance Bot & Combinar Resgate */}
                <div className="mt-3 pt-3 border-t border-gray-100 flex items-center justify-between gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedProductForBot(p)}
                    className="py-1.5 px-3 bg-gray-50 hover:bg-gray-100 border border-gray-200 text-gray-700 text-xs font-semibold rounded-xl transition flex items-center gap-1.5 cursor-pointer"
                  >
                    <Bot className="w-3.5 h-3.5 text-emerald-600" />
                    <span>{t('calculateRoute')}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => onOpenChat(p.userId, 'Produtor')}
                    className="py-2 px-4 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl transition shadow-xs flex items-center gap-1.5 cursor-pointer ml-auto"
                  >
                    <MessageSquareText className="w-4 h-4" />
                    <span>{t('combineRescue')}</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Distance Bot Interactive Modal */}
      {selectedProductForBot && (
        <DistanceBotModal
          product={selectedProductForBot}
          initialBuyerAddress={buyerRegion}
          onClose={() => setSelectedProductForBot(null)}
          onUpdateBuyerAddress={(newAddr) => setBuyerRegion(newAddr)}
        />
      )}
    </div>
  );
};
