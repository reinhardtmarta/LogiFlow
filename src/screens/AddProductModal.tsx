import React, { useState } from 'react';
import { User, Tier, TIER_CONFIGS } from '../types';
import { store } from '../services/store';
import { X, Camera, Calendar, Plus, AlertCircle, Sparkles } from 'lucide-react';

interface AddProductModalProps {
  user: User;
  onClose: () => void;
  onOpenUpgrade: (tierNeeded: Tier) => void;
}

export const AddProductModal: React.FC<AddProductModalProps> = ({
  user,
  onClose,
  onOpenUpgrade,
}) => {
  const sub = store.getSubscription(user.id);
  const sellerProducts = store.getSellerProducts(user.id, true);
  const maxPhotos = TIER_CONFIGS[sub.tier].maxPhotos;
  const productLimit = sub.productLimit;
  const currentCount = sellerProducts.length;

  const [name, setName] = useState('');
  const [quantity, setQuantity] = useState('10');
  const [price, setPrice] = useState('8.50');
  const [category, setCategory] = useState('Fruits & Vegetables');
  const [condition, setCondition] = useState('Fresh');
  const [address, setAddress] = useState(user.address);
  const [isProducer, setIsProducer] = useState(true);
  const [isRescue, setIsRescue] = useState(false);
  const [selectedPhotos, setSelectedPhotos] = useState<string[]>([
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
  ]);
  const [expiryDays, setExpiryDays] = useState('5');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const categories = [
    'Fruits & Vegetables',
    'Dairy',
    'Bakery',
    'Meat & Fish',
    'Grains & Pasta',
    'Beverages',
    'Ready Meals',
    'Other',
  ];

  const conditions = ['Fresh', 'Ripe', 'Bakery', 'Near Expiry', 'Frozen'];

  const samplePhotoPresets = [
    { label: 'Frutas', url: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=600&q=80' },
    { label: 'Padaria', url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80' },
    { label: 'Vegetais', url: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80' },
    { label: 'Laticínios', url: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80' },
  ];

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Security validation: only standard image formats (block SVG/HTML vectors)
    const validMimes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!validMimes.includes(file.type)) {
      setErrorMsg('Formato de imagem inválido. Carregue apenas JPG, PNG ou WebP.');
      e.target.value = '';
      return;
    }

    // Security validation: file size limit 5MB max
    if (file.size > 5 * 1024 * 1024) {
      setErrorMsg('Arquivo muito grande. O limite máximo é de 5MB por imagem.');
      e.target.value = '';
      return;
    }

    if (selectedPhotos.length >= maxPhotos) {
      setErrorMsg(`Seu plano atual permite até ${maxPhotos} foto(s) por produto.`);
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const img = new Image();
      img.onload = () => {
        // Redrawing on Canvas permanently strips all EXIF, GPS location & device metadata
        const canvas = document.createElement('canvas');
        let width = img.width;
        let height = img.height;
        const maxDim = 800;
        if (width > height && width > maxDim) {
          height = Math.round((height * maxDim) / width);
          width = maxDim;
        } else if (height > maxDim) {
          width = Math.round((width * maxDim) / height);
          height = maxDim;
        }
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx?.drawImage(img, 0, 0, width, height);
        // Stripped JPEG representation with optimized compression
        const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.75);
        setSelectedPhotos((prev) => [...prev, compressedDataUrl]);
      };
      img.src = event.target?.result as string;
    };
    reader.readAsDataURL(file);
    // Reset file input
    e.target.value = '';
  };

  const handleAddPhotoPreset = (url: string) => {
    if (selectedPhotos.length >= maxPhotos) {
      setErrorMsg(`Seu plano atual permite até ${maxPhotos} foto(s) por produto.`);
      return;
    }
    setSelectedPhotos([...selectedPhotos, url]);
  };

  const handleRemovePhoto = (idx: number) => {
    setSelectedPhotos(selectedPhotos.filter((_, i) => i !== idx));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    const qty = parseInt(quantity, 10);
    const prc = parseFloat(price.replace(',', '.'));

    if (!name.trim()) {
      setErrorMsg('Por favor, informe o nome do produto.');
      return;
    }
    if (isNaN(qty) || qty <= 0) {
      setErrorMsg('Por favor, informe uma quantidade válida.');
      return;
    }
    if (isNaN(prc) || prc < 0) {
      setErrorMsg('Por favor, informe um preço válido.');
      return;
    }

    if (productLimit >= 0 && currentCount >= productLimit) {
      const tierNeeded = currentCount >= 1000 ? 'pro' : 'basic';
      onOpenUpgrade(tierNeeded);
      return;
    }

    setIsSubmitting(true);

    try {
      const expiry = new Date();
      expiry.setDate(expiry.getDate() + (parseInt(expiryDays, 10) || 5));

      store.addProduct({
        userId: user.id,
        name: name.trim(),
        quantity: qty,
        price: prc,
        expiryDate: expiry.toISOString(),
        condition,
        isProducer,
        address: address.trim() || user.address,
        imagePaths: selectedPhotos,
        category,
        isRescue,
        isFeatured: false,
      });

      onClose();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Erro ao cadastrar produto';
      if (message.includes('ProductLimitReached')) {
        const tierNeeded = currentCount >= 1000 ? 'pro' : 'basic';
        onOpenUpgrade(tierNeeded);
      } else {
        setErrorMsg(message);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 overflow-y-auto animate-in fade-in duration-150">
      <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl border border-gray-200 overflow-hidden my-6">
        {/* Header */}
        <div className="bg-emerald-700 text-white p-4 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-bold">Add New Product</h2>
            <p className="text-xs text-emerald-100">
              Produtos: {currentCount} / {productLimit < 0 ? 'ilimitado' : productLimit}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-full hover:bg-white/20 text-white/90 hover:text-white transition cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content / Form */}
        <form onSubmit={handleSubmit} className="p-5 space-y-4 max-h-[80vh] overflow-y-auto">
          {errorMsg && (
            <div className="p-3 bg-red-50 border border-red-200 text-red-700 rounded-xl text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* Photo Picker section matching Flutter */}
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-xs font-bold text-gray-700">Fotos do Produto</label>
              <span className="text-[11px] text-gray-500 font-medium">
                {selectedPhotos.length} / {maxPhotos} foto(s) permitidas no plano
              </span>
            </div>

            <div className="flex gap-2 overflow-x-auto pb-2">
              {selectedPhotos.map((url, idx) => (
                <div key={idx} className="relative w-20 h-20 rounded-xl overflow-hidden shrink-0 border border-gray-200 group">
                  <img src={url} alt={`Foto ${idx}`} className="w-full h-full object-cover" />
                  <button
                    type="button"
                    onClick={() => handleRemovePhoto(idx)}
                    className="absolute top-1 right-1 p-0.5 bg-black/60 text-white rounded-full hover:bg-red-600 transition cursor-pointer"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}

              {selectedPhotos.length < maxPhotos && (
                <label className="w-20 h-20 rounded-xl border-2 border-dashed border-emerald-400 hover:border-emerald-600 flex flex-col items-center justify-center text-emerald-700 shrink-0 bg-emerald-50/60 cursor-pointer transition">
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handlePhotoUpload}
                    className="hidden"
                  />
                  <Camera className="w-6 h-6 mb-0.5" />
                  <span className="text-[10px] font-bold">Tirar Foto</span>
                </label>
              )}
            </div>

            {/* Presets to quickly pick a realistic food picture */}
            <div className="flex items-center gap-1.5 mt-2 flex-wrap">
              <span className="text-[11px] text-gray-400">Exemplos rápidos:</span>
              {samplePhotoPresets.map((preset) => (
                <button
                  type="button"
                  key={preset.label}
                  onClick={() => handleAddPhotoPreset(preset.url)}
                  disabled={selectedPhotos.length >= maxPhotos}
                  className="px-2 py-0.5 rounded-full text-[11px] bg-emerald-50 text-emerald-800 hover:bg-emerald-100 transition cursor-pointer disabled:opacity-40"
                >
                  + {preset.label}
                </button>
              ))}
            </div>
          </div>

          {/* Product Name */}
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">
              Product Name *
            </label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ex: Maçãs Gala Orgânicas"
              className="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
            />
          </div>

          {/* Quantity & Price */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Quantity *
              </label>
              <input
                type="number"
                required
                min="1"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Price (BRL / USD) *
              </label>
              <input
                type="text"
                required
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
              />
            </div>
          </div>

          {/* Category & Condition */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Category
              </label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
              >
                {categories.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-bold text-gray-700 mb-1">
                Condition
              </label>
              <select
                value={condition}
                onChange={(e) => setCondition(e.target.value)}
                className="w-full px-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
              >
                {conditions.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Expiry Date */}
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">
              Validade aproximada
            </label>
            <div className="flex items-center gap-3">
              <div className="flex-1 flex items-center gap-2 px-3.5 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm">
                <Calendar className="w-4 h-4 text-gray-400" />
                <span className="text-gray-700">Vence em</span>
                <input
                  type="number"
                  min="1"
                  max="365"
                  value={expiryDays}
                  onChange={(e) => setExpiryDays(e.target.value)}
                  className="w-16 px-2 py-0.5 bg-white border border-gray-300 rounded text-center text-sm font-semibold"
                />
                <span className="text-gray-700">dia(s)</span>
              </div>
            </div>
          </div>

          {/* Address */}
          <div>
            <label className="block text-xs font-bold text-gray-700 mb-1">
              Address / Retirada
            </label>
            <textarea
              rows={2}
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              className="w-full px-3.5 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
            />
          </div>

          {/* Switches matching Flutter */}
          <div className="space-y-2 pt-2 border-t border-gray-100">
            <label className="flex items-center justify-between cursor-pointer p-2 rounded-xl hover:bg-gray-50">
              <div>
                <span className="block text-sm font-semibold text-gray-900">
                  I am the producer
                </span>
                <span className="block text-xs text-gray-500">
                  Sou o produtor ou agricultor direto deste item
                </span>
              </div>
              <input
                type="checkbox"
                checked={isProducer}
                onChange={(e) => setIsProducer(e.target.checked)}
                className="w-5 h-5 accent-emerald-600 rounded"
              />
            </label>

            <label className="flex items-center justify-between cursor-pointer p-2 rounded-xl hover:bg-gray-50">
              <div>
                <span className="block text-sm font-semibold text-gray-900">
                  Food rescue
                </span>
                <span className="block text-xs text-gray-500">
                  Marcar este produto como resgate urgente contra o desperdício
                </span>
              </div>
              <input
                type="checkbox"
                checked={isRescue}
                onChange={(e) => setIsRescue(e.target.checked)}
                className="w-5 h-5 accent-emerald-600 rounded"
              />
            </label>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full mt-4 py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-sm shadow-md transition cursor-pointer flex items-center justify-center gap-2"
          >
            {isSubmitting ? 'Publicando...' : 'Publish Product'}
          </button>
        </form>
      </div>
    </div>
  );
};
