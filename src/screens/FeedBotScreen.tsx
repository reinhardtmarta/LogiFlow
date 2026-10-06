import React, { useState, useEffect } from 'react';
import { User, Product } from '../types';
import { store } from '../services/store';
import { formatDistance } from '../utils/distance';
import { useLanguage } from '../context/LanguageContext';
import { 
  Tag, 
  AlertTriangle, 
  Apple, 
  Croissant, 
  Milk, 
  Star, 
  BarChart3, 
  MessageSquare, 
  Clock,
  Navigation,
  Compass,
  Sparkles
} from 'lucide-react';

interface FeedBotScreenProps {
  user: User;
  onOpenChat: (receiverId: string, receiverName: string) => void;
  onNavigateToCategory?: (category: string) => void;
}

interface MessageItem {
  id: string;
  sender: 'system' | 'user';
  text: string;
  products?: Product[];
  stats?: {
    totalItems: number;
    expiringUrgent: number;
    wastePreventedTotal: number;
    cheapestPrice: number;
  };
}

export const FeedBotScreen: React.FC<FeedBotScreenProps> = ({ user, onOpenChat }) => {
  const { t } = useLanguage();
  const [products, setProducts] = useState<Product[]>(store.getProducts());
  const [messages, setMessages] = useState<MessageItem[]>([]);

  useEffect(() => {
    const update = () => {
      setProducts(store.getProducts());
    };
    return store.subscribe(update);
  }, []);

  // Initialize with welcome message and options
  useEffect(() => {
    setMessages([
      {
        id: 'msg_welcome',
        sender: 'system',
        text: `Olá, ${user.name}! Bem-vindo ao Explorador do Feed LogiFlow 🌱\n\nToque em uma das opções abaixo para filtrar e explorar o inventário em tempo real:`,
      },
    ]);
  }, [user.name]);

  const handleStaticOption = (action: string) => {
    const current = store.getProducts();

    if (action === 'best_prices') {
      const sorted = [...current].sort((a, b) => a.price - b.price);
      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '🏷️ Mostrar os melhores preços do feed',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: `Encontrei ${sorted.length} produtos ordenados do menor para o maior preço:`,
          products: sorted.slice(0, 5),
        },
      ]);
    } else if (action === 'urgent_rescue') {
      const urgent = current.filter((p) => {
        const days = Math.ceil((new Date(p.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
        return days <= 3;
      });

      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '⚡ Ver alimentos em resgate urgente (≤ 3 dias)',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: urgent.length > 0
            ? `Atenção: temos ${urgent.length} produto(s) com validade crítica. Resgatá-los evita o descarte!`
            : 'Boas notícias: no momento nenhum item está com vencimento urgente inferior a 3 dias!',
          products: urgent,
        },
      ]);
    } else if (action === 'cat_produce') {
      const filtered = current.filter((p) => p.category === 'Frutas & Vegetais' || p.category === 'Fruits & Vegetables');
      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '🍎 Filtrar Frutas & Vegetais',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: `Encontrei ${filtered.length} item(ns) na categoria Frutas & Vegetais:`,
          products: filtered,
        },
      ]);
    } else if (action === 'cat_bakery') {
      const filtered = current.filter((p) => p.category === 'Padaria' || p.category === 'Bakery' || p.category === 'Grains & Pasta');
      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '🥖 Filtrar Padaria & Grãos',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: `Encontrei ${filtered.length} item(ns) de Padaria e Grãos:`,
          products: filtered,
        },
      ]);
    } else if (action === 'cat_dairy') {
      const filtered = current.filter((p) => p.category === 'Laticínios' || p.category === 'Dairy' || p.category === 'Beverages');
      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '🥛 Filtrar Laticínios & Bebidas',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: `Encontrei ${filtered.length} item(ns) de Laticínios e Bebidas:`,
          products: filtered,
        },
      ]);
    } else if (action === 'featured') {
      const featured = current.filter((p) => p.isFeatured);
      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '⭐ Ver produtos em destaque',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: featured.length > 0
            ? `Aqui estão os produtos destacados pelos produtores:`
            : 'No momento nenhum produtor ativou destaque para itens.',
          products: featured,
        },
      ]);
    } else if (action === 'nearest') {
      const sortedByDistance = [...current].sort(
        (a, b) => (a.distanceMeters || 99999) - (b.distanceMeters || 99999)
      );
      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '📍 Alimentos mais próximos de mim (km/m)',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: `Encontrei ${sortedByDistance.length} produto(s) ordenados por proximidade geográfica em relação a você:`,
          products: sortedByDistance.slice(0, 5),
        },
      ]);
    } else if (action === 'stats') {
      const urgentCount = current.filter((p) => {
        const days = Math.ceil((new Date(p.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
        return days <= 3;
      }).length;
      const totalKg = current.reduce((sum, p) => sum + (p.wastePreventedKg || 0), 0);
      const minPrice = current.length > 0 ? Math.min(...current.map((p) => p.price)) : 0;

      setMessages((prev) => [
        ...prev,
        {
          id: 'user_' + Date.now(),
          sender: 'user',
          text: '📊 Ver resumo e estatísticas do feed',
        },
        {
          id: 'sys_' + Date.now(),
          sender: 'system',
          text: `Resumo do feed sincronizado em tempo real:\n\n• ${current.length} produtos disponíveis\n• ${urgentCount} itens em resgate urgente\n• ${totalKg.toFixed(1)} kg de alimento resgatado do descarte\n• Menor preço a partir de R$ ${minPrice.toFixed(2)}`,
          stats: {
            totalItems: current.length,
            expiringUrgent: urgentCount,
            wastePreventedTotal: totalKg,
            cheapestPrice: minPrice,
          },
        },
      ]);
    }
  };

  const staticOptions = [
    { id: 'nearest', label: '📍 Mais Próximos', icon: Navigation, desc: 'Distância em m e km' },
    { id: 'best_prices', label: '🏷️ Melhores Preços', icon: Tag, desc: 'Do menor ao maior valor' },
    { id: 'urgent_rescue', label: '⚡ Resgate Urgente', icon: AlertTriangle, desc: 'Vence em até 3 dias' },
    { id: 'cat_produce', label: '🍎 Frutas & Vegetais', icon: Apple, desc: 'Itens frescos da horta' },
    { id: 'cat_bakery', label: '🥖 Padaria & Grãos', icon: Croissant, desc: 'Pães e farinhas' },
    { id: 'cat_dairy', label: '🥛 Laticínios & Bebidas', icon: Milk, desc: 'Leites, iogurtes e sucos' },
    { id: 'featured', label: '⭐ Destaques', icon: Star, desc: 'Itens recomendados' },
    { id: 'stats', label: '📊 Estatísticas', icon: BarChart3, desc: 'Total e kg poupados' },
  ];

  return (
    <div className="pb-24 pt-3 max-w-xl mx-auto px-4 flex flex-col h-[calc(100vh-65px)]">
      {/* Header */}
      <div className="bg-white p-3.5 rounded-2xl border border-gray-200 shadow-xs mb-3 flex items-center justify-between shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center shadow-xs">
            <Compass className="w-6 h-6" />
          </div>
          <div>
            <h2 className="font-bold text-gray-900 text-sm flex items-center gap-1.5">
              Explorar Alimentos
            </h2>
            <p className="text-[11px] text-gray-500">
              Navegue pelo feed de alimentos usando filtros rápidos
            </p>
          </div>
        </div>

        <div className="flex items-center gap-1 text-[11px] font-semibold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-lg">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          <span>Firestore Live</span>
        </div>
      </div>

      {/* Message History */}
      <div className="flex-1 overflow-y-auto space-y-3.5 pr-1 mb-3">
        {messages.map((msg) => {
          const isUser = msg.sender === 'user';
          return (
            <div
              key={msg.id}
              className={`flex gap-2.5 ${isUser ? 'justify-end' : 'justify-start'}`}
            >
              {!isUser && (
                <div className="w-7 h-7 rounded-lg bg-emerald-600 text-white flex items-center justify-center shrink-0 mt-0.5">
                  <Sparkles className="w-4 h-4 text-emerald-100" />
                </div>
              )}

              <div
                className={`max-w-[88%] rounded-2xl p-3.5 text-xs sm:text-sm leading-relaxed shadow-2xs ${
                  isUser
                    ? 'bg-emerald-600 text-white rounded-tr-xs'
                    : 'bg-white text-gray-800 border border-gray-200 rounded-tl-xs'
                }`}
              >
                <p className="whitespace-pre-line font-medium">{msg.text}</p>

                {/* Render Product Cards */}
                {msg.products && msg.products.length > 0 && (
                  <div className="mt-3 pt-2.5 border-t border-gray-100 space-y-2">
                    {msg.products.map((p) => {
                      const days = Math.ceil(
                        (new Date(p.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
                      );
                      const isUrgent = days <= 3;
                      const image = p.imagePaths?.[0] || p.imagePath;

                      return (
                        <div
                          key={p.id}
                          className="bg-gray-50 hover:bg-emerald-50/70 p-2.5 rounded-xl border border-gray-200 flex items-center justify-between gap-2.5 transition"
                        >
                          <div className="flex items-center gap-2.5 min-w-0 flex-1">
                            {image ? (
                              <img
                                src={image}
                                alt={p.name}
                                className="w-11 h-11 rounded-lg object-cover shrink-0 border border-gray-200"
                              />
                            ) : (
                              <div className="w-11 h-11 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0 font-bold text-xs">
                                🌱
                              </div>
                            )}

                            <div className="min-w-0 flex-1">
                              <h4 className="font-bold text-gray-900 text-xs truncate">
                                {p.name}
                              </h4>
                              <p className="text-[11px] text-gray-500 mt-0.5 truncate">
                                {p.category} • {p.quantity} un
                              </p>
                              <div className="flex items-center gap-2 mt-0.5 flex-wrap">
                                <p
                                  className={`text-[10px] font-semibold flex items-center gap-1 ${
                                    isUrgent ? 'text-red-600' : 'text-gray-500'
                                  }`}
                                >
                                  <Clock className="w-3 h-3" />
                                  {days <= 0 ? 'Vence hoje' : `Vence em ${days}d`}
                                </p>
                                {p.distanceMeters !== undefined && (
                                  <span className="inline-flex items-center gap-0.5 text-[10px] font-bold text-emerald-800 bg-emerald-100/80 px-1.5 py-0.2 rounded">
                                    <Navigation className="w-2.5 h-2.5 text-emerald-700" />
                                    {formatDistance(p.distanceMeters)}
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>

                          <div className="text-right shrink-0">
                            <span className="font-extrabold text-sm text-emerald-700 block">
                              R$ {p.price.toFixed(2)}
                            </span>
                            <button
                              onClick={() => onOpenChat(p.userId, 'Vendedor')}
                              className="mt-1 px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white text-[11px] font-bold rounded-lg transition shadow-2xs flex items-center gap-1 cursor-pointer"
                            >
                              <MessageSquare className="w-3 h-3" />
                              <span>Resgatar</span>
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Static Interactive Action Buttons */}
      <div className="bg-white p-3 rounded-2xl border border-gray-200 shadow-sm shrink-0">
        <p className="text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-2 px-1">
          Toque em uma opção:
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-1.5 max-h-36 overflow-y-auto pr-1">
          {staticOptions.map((opt) => {
            const Icon = opt.icon;
            return (
              <button
                key={opt.id}
                onClick={() => handleStaticOption(opt.id)}
                className="p-2 text-left rounded-xl border border-gray-200 bg-gray-50 hover:bg-emerald-50 hover:border-emerald-300 transition text-xs font-semibold text-gray-800 flex items-center gap-2 cursor-pointer group shadow-2xs"
              >
                <div className="p-1 rounded-lg bg-white border border-gray-200 group-hover:border-emerald-300 text-emerald-700 shrink-0">
                  <Icon className="w-3.5 h-3.5" />
                </div>
                <div className="min-w-0">
                  <span className="block truncate leading-tight">{opt.label}</span>
                  <span className="block text-[9px] text-gray-400 truncate">{opt.desc}</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};
