import React, { useState } from 'react';
import { Product } from '../types';
import { DistanceBot, DistanceCalculationResult } from '../services/distanceBot';
import { useLanguage } from '../context/LanguageContext';
import { 
  MapPin, 
  Navigation, 
  Footprints, 
  Bike, 
  Car,
  Leaf, 
  ShieldCheck, 
  RefreshCw,
  Compass
} from 'lucide-react';

interface DistanceBotModalProps {
  product: Product;
  initialBuyerAddress: string;
  onClose: () => void;
  onUpdateBuyerAddress?: (newAddress: string) => void;
}

export const DistanceBotModal: React.FC<DistanceBotModalProps> = ({
  product,
  initialBuyerAddress,
  onClose,
  onUpdateBuyerAddress,
}) => {
  const { t } = useLanguage();
  const [buyerAddress, setBuyerAddress] = useState(
    initialBuyerAddress || 'Minha Região / Centro'
  );
  const [result, setResult] = useState<DistanceCalculationResult>(() =>
    DistanceBot.calculate(buyerAddress, product.address || 'São Paulo, SP')
  );
  const [isRecalculating, setIsRecalculating] = useState(false);

  const handleRecalculate = (e: React.FormEvent) => {
    e.preventDefault();
    setIsRecalculating(true);
    setTimeout(() => {
      const res = DistanceBot.calculate(buyerAddress, product.address || 'São Paulo, SP');
      setResult(res);
      setIsRecalculating(false);
      if (onUpdateBuyerAddress) {
        onUpdateBuyerAddress(buyerAddress);
      }
    }, 400);
  };

  return (
    <div className="fixed inset-0 bg-gray-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-150">
      <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl border border-gray-100 p-6 relative text-left">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-sm font-semibold cursor-pointer p-1"
        >
          ✕
        </button>

        {/* Modal Header */}
        <div className="flex items-center gap-3 mb-4 pb-3 border-b border-gray-100">
          <div className="w-11 h-11 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 border border-emerald-200">
            <Compass className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-gray-900 text-base">
                {t('bot_modal_title')}
              </h3>
              <span className="text-[10px] bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
                <ShieldCheck className="w-3 h-3 text-emerald-600" />
                {t('bot_modal_no_gps')}
              </span>
            </div>
            <p className="text-xs text-gray-500">
              {t('bot_modal_subtitle')}
            </p>
          </div>
        </div>

        {/* Product Reference */}
        <div className="p-3 bg-gray-50 rounded-2xl border border-gray-200 mb-4 flex items-center justify-between text-xs">
          <div>
            <span className="text-gray-400 text-[10px] uppercase font-bold block">{t('bot_food_label')}</span>
            <span className="font-bold text-gray-900">{product.name}</span>
          </div>
          <div className="text-right">
            <span className="text-gray-400 text-[10px] uppercase font-bold block">{t('bot_pickup_label')}</span>
            <span className="font-semibold text-gray-700">{product.address || 'São Paulo, SP'}</span>
          </div>
        </div>

        {/* Buyer Location Input Form */}
        <form onSubmit={handleRecalculate} className="mb-4 space-y-2">
          <label className="block text-xs font-bold text-gray-700">
            {t('bot_buyer_region_label')}
          </label>
          <div className="flex gap-2">
            <div className="relative flex-1">
              <MapPin className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                value={buyerAddress}
                onChange={(e) => setBuyerAddress(e.target.value)}
                placeholder="Ex.: Pinheiros, Vila Mariana, Centro..."
                className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-300 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
              />
            </div>
            <button
              type="submit"
              disabled={isRecalculating}
              className="px-3.5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs transition cursor-pointer flex items-center gap-1 shadow-xs disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRecalculating ? 'animate-spin' : ''}`} />
              <span>{t('bot_recalc_btn')}</span>
            </button>
          </div>
        </form>

        {/* Distance Calculation Results Card */}
        <div className="bg-emerald-50/80 rounded-2xl p-4 border border-emerald-200 mb-4 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs text-emerald-900 font-semibold flex items-center gap-1.5">
              <Navigation className="w-4 h-4 text-emerald-600" />
              {t('bot_estimated_distance')}
            </span>
            <span className="text-lg font-black text-emerald-900">
              {result.distanceFormatted}
            </span>
          </div>

          {/* Transportation Times */}
          <div className="grid grid-cols-2 gap-2 pt-2 border-t border-emerald-200/60">
            <div className="bg-white p-2.5 rounded-xl border border-emerald-100 flex items-center gap-2.5">
              <Footprints className="w-4 h-4 text-emerald-600 shrink-0" />
              <div>
                <span className="text-[10px] text-gray-400 block font-medium">{t('bot_walking_time')}</span>
                <span className="text-xs font-bold text-gray-900">~{result.walkingMinutes} min</span>
              </div>
            </div>

            <div className="bg-white p-2.5 rounded-xl border border-emerald-100 flex items-center gap-2.5">
              <Bike className="w-4 h-4 text-blue-600 shrink-0" />
              <div>
                <span className="text-[10px] text-gray-400 block font-medium">{t('bot_biking_time')}</span>
                <span className="text-xs font-bold text-gray-900">~{result.bikingMinutes} min</span>
              </div>
            </div>

            <div className="bg-white p-2.5 rounded-xl border border-emerald-100 flex items-center gap-2.5 col-span-2">
              <Car className="w-4 h-4 text-emerald-700 shrink-0" />
              <div>
                <span className="text-[10px] text-gray-400 block font-medium">{t('bot_driving_time')}</span>
                <span className="text-xs font-bold text-gray-900">~{result.drivingMinutes} min ({result.distanceKm} km)</span>
              </div>
            </div>
          </div>

          {/* Eco Recommendation */}
          <div className="pt-2 border-t border-emerald-200/60 flex items-start gap-2 text-xs text-emerald-900">
            <Leaf className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
            <div>
              <p className="font-semibold text-emerald-950">{result.recommendation}</p>
              <p className="text-[11px] text-emerald-800/90 mt-0.5">
                {result.co2SavedGrams}g {t('bot_eco_saved_co2')}
              </p>
            </div>
          </div>
        </div>

        <button
          onClick={onClose}
          className="w-full py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-xl text-xs transition cursor-pointer"
        >
          {t('close_btn')}
        </button>
      </div>
    </div>
  );
};
