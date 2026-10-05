import React, { useState } from 'react';
import { Product, User } from '../types';
import { store } from '../services/store';
import { 
  ShoppingBag, 
  CheckCircle2, 
  MapPin, 
  Clock, 
  Package, 
  MessageSquareText, 
  Loader2, 
  AlertCircle,
  QrCode,
  ShieldCheck,
  Leaf
} from 'lucide-react';

interface ReserveFoodModalProps {
  product: Product;
  user: User;
  onClose: () => void;
  onOpenChat: (sellerId: string, sellerName: string) => void;
  onSuccess: () => void;
}

export const ReserveFoodModal: React.FC<ReserveFoodModalProps> = ({
  product,
  user,
  onClose,
  onOpenChat,
  onSuccess,
}) => {
  const [quantity, setQuantity] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [reservationCode, setReservationCode] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const maxAvailable = Math.max(1, product.quantity || 1);
  const totalPrice = product.price * quantity;

  const handleConfirmReservation = async () => {
    if (quantity <= 0 || quantity > maxAvailable) {
      setErrorMsg(`Quantidade inválida. Máximo disponível: ${maxAvailable}`);
      return;
    }

    setIsSubmitting(true);
    setErrorMsg(null);

    try {
      // 1. Generate unique pickup code
      const code = 'RESG-' + Math.floor(1000 + Math.random() * 9000);

      // 2. Decrement product stock in Firestore
      const newQty = Math.max(0, product.quantity - quantity);
      await store.updateProductStock(product.id, newQty);

      // 3. Send automated order notification message to seller in Firestore Chat
      const orderMessage = `🛒 [Resgate Confirmado]\nOlá! Reservei ${quantity} un de "${product.name}".\nValor Total: ${totalPrice === 0 ? 'Grátis (Doação)' : `R$ ${totalPrice.toFixed(2).replace('.', ',')}`}\nCódigo de Retirada: ${code}\nPodemos combinar o horário de retirada?`;
      await store.sendMessage(user.id, product.userId, orderMessage);

      setReservationCode(code);
      onSuccess();
    } catch (err: any) {
      setErrorMsg('Falha ao concluir reserva: ' + (err.message || 'Tente novamente'));
    } finally {
      setIsSubmitting(false);
    }
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

        {!reservationCode ? (
          <div>
            {/* Header */}
            <div className="flex items-center gap-3 mb-4 pb-3 border-b border-gray-100">
              <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center shrink-0">
                <ShoppingBag className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-extrabold text-gray-900 text-base">
                  Reservar Alimento para Resgate
                </h3>
                <p className="text-[11px] text-gray-500">
                  Evite o desperdício e garanta sua retirada
                </p>
              </div>
            </div>

            {errorMsg && (
              <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-xl text-xs flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{errorMsg}</span>
              </div>
            )}

            {/* Product Summary */}
            <div className="bg-gray-50 p-3.5 rounded-2xl border border-gray-200 mb-4 space-y-2">
              <div className="flex justify-between items-start">
                <h4 className="font-bold text-gray-900 text-sm leading-tight">
                  {product.name}
                </h4>
                <span className="text-base font-black text-emerald-700">
                  {product.price === 0 ? 'Grátis' : `R$ ${product.price.toFixed(2).replace('.', ',')}`}
                </span>
              </div>

              <div className="text-xs text-gray-600 space-y-1">
                <p className="flex items-center gap-1.5 text-gray-500">
                  <MapPin className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                  <span className="truncate">{product.address || 'São Paulo, SP'}</span>
                </p>
                <p className="flex items-center gap-1.5 text-gray-500">
                  <Clock className="w-3.5 h-3.5 text-amber-500 shrink-0" />
                  <span>Vence em: {new Date(product.expiryDate).toLocaleDateString()}</span>
                </p>
              </div>
            </div>

            {/* Quantity Selector */}
            <div className="mb-4">
              <div className="flex justify-between items-center mb-1.5">
                <label className="text-xs font-bold text-gray-700">
                  Quantidade a Resgatar:
                </label>
                <span className="text-[11px] text-gray-400">
                  Máximo: {maxAvailable} un
                </span>
              </div>

              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setQuantity(Math.max(1, quantity - 1))}
                  className="w-10 h-10 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold text-base flex items-center justify-center transition cursor-pointer"
                >
                  -
                </button>
                <span className="flex-1 text-center font-bold text-base text-gray-900">
                  {quantity} un
                </span>
                <button
                  type="button"
                  onClick={() => setQuantity(Math.min(maxAvailable, quantity + 1))}
                  className="w-10 h-10 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold text-base flex items-center justify-center transition cursor-pointer"
                >
                  +
                </button>
              </div>
            </div>

            {/* Order Total */}
            <div className="p-3 bg-emerald-50/70 border border-emerald-200 rounded-2xl mb-4 flex items-center justify-between text-xs">
              <span className="font-semibold text-emerald-900">Total a pagar na retirada:</span>
              <span className="text-base font-black text-emerald-800">
                {totalPrice === 0 ? 'R$ 0,00 (Doação Gratuita)' : `R$ ${totalPrice.toFixed(2).replace('.', ',')}`}
              </span>
            </div>

            {/* Confirm Button */}
            <button
              type="button"
              disabled={isSubmitting || maxAvailable <= 0}
              onClick={handleConfirmReservation}
              className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-2xl text-sm shadow-md transition flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>Confirmando reserva...</span>
                </>
              ) : (
                <>
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Confirmar Reserva de Resgate</span>
                </>
              )}
            </button>
          </div>
        ) : (
          /* Success Receipt Card */
          <div className="space-y-4 text-center py-2 animate-in zoom-in-95">
            <div className="w-14 h-14 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-8 h-8" />
            </div>

            <div>
              <h4 className="font-black text-emerald-950 text-lg">
                Reserva Realizada com Sucesso!
              </h4>
              <p className="text-xs text-gray-500 mt-0.5">
                O produtor foi notificado via chat e o estoque foi atualizado.
              </p>
            </div>

            {/* Pickup Code Display */}
            <div className="p-4 bg-emerald-50 rounded-2xl border-2 border-dashed border-emerald-300">
              <span className="text-[10px] text-emerald-700 font-bold uppercase tracking-wider block mb-1">
                Apresente este código na retirada:
              </span>
              <span className="text-2xl font-black text-emerald-900 tracking-wider font-mono">
                {reservationCode}
              </span>
            </div>

            <div className="text-xs text-gray-600 space-y-1 text-left bg-gray-50 p-3.5 rounded-xl border border-gray-200">
              <p><strong>Item:</strong> {quantity}x {product.name}</p>
              <p><strong>Retirada:</strong> {product.address || 'São Paulo, SP'}</p>
              <p><strong>Valor:</strong> {totalPrice === 0 ? 'Grátis' : `R$ ${totalPrice.toFixed(2).replace('.', ',')}`}</p>
            </div>

            <div className="flex gap-2">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-xl text-xs transition cursor-pointer"
              >
                Fechar
              </button>

              <button
                type="button"
                onClick={() => {
                  onClose();
                  onOpenChat(product.userId, 'Produtor');
                }}
                className="flex-1 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs transition cursor-pointer flex items-center justify-center gap-1.5 shadow-xs"
              >
                <MessageSquareText className="w-3.5 h-3.5" />
                <span>Abrir Chat com Produtor</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
