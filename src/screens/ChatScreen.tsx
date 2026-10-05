import React, { useState, useEffect, useRef } from 'react';
import { User, ChatMessage } from '../types';
import { store } from '../services/store';
import { useLanguage } from '../context/LanguageContext';
import { 
  ArrowLeft, 
  Send, 
  MessageSquare, 
  ShieldAlert, 
  AlertTriangle,
  Info
} from 'lucide-react';

interface ChatScreenProps {
  currentUser: User;
  receiverId: string;
  receiverName: string;
  onBack: () => void;
}

export const ChatScreen: React.FC<ChatScreenProps> = ({
  currentUser,
  receiverId,
  receiverName,
  onBack,
}) => {
  const { t } = useLanguage();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputText, setInputText] = useState('');
  const [isSending, setIsSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Subscribe to real-time Cloud Firestore messages stream
  useEffect(() => {
    const unsubscribe = store.subscribeToChat(currentUser.id, receiverId, (newMsgs) => {
      setMessages(newMsgs);
    });

    return () => {
      unsubscribe();
    };
  }, [currentUser.id, receiverId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || isSending) return;

    const text = inputText.trim();
    setInputText('');
    setIsSending(true);

    try {
      await store.sendMessage(currentUser.id, receiverId, text);
    } catch (err) {
      console.warn('Send message error:', err);
    } finally {
      setIsSending(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-50 flex flex-col z-40 max-w-xl mx-auto shadow-2xl">
      {/* Real-time Header */}
      <div className="bg-emerald-700 text-white p-3.5 flex items-center gap-3 shrink-0 shadow-sm">
        <button
          onClick={onBack}
          className="p-1.5 rounded-lg hover:bg-emerald-800 transition cursor-pointer"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div className="flex items-center gap-2.5 flex-1 min-w-0">
          <div className="w-8 h-8 rounded-full bg-emerald-500 flex items-center justify-center font-bold text-xs">
            {receiverName.charAt(0)}
          </div>
          <div className="min-w-0 flex-1">
            <h3 className="font-bold text-sm truncate flex items-center gap-1.5">
              <span>{receiverName}</span>
            </h3>
            <p className="text-[11px] text-emerald-200 flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-300 animate-pulse" />
              <span>Conexão Realtime Firestore</span>
            </p>
          </div>
        </div>
      </div>

      {/* Termo de Responsabilidade e Segurança do Chat */}
      <div className="bg-amber-50 border-b border-amber-200/90 px-3.5 py-2.5 text-xs text-amber-950 flex items-start gap-2.5 shadow-xs">
        <ShieldAlert className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
        <div className="flex-1 leading-snug">
          <p className="font-bold text-amber-900 text-[11px] uppercase tracking-wide flex items-center gap-1">
            <span>{t('chatDisclaimerHeader')}</span>
          </p>
          <p className="text-[11px] text-amber-800/95 mt-0.5">
            {t('chatDisclaimerText')}
          </p>
          <div className="mt-1.5 text-[11px] text-amber-900/90 bg-amber-100/70 p-2 rounded-lg border border-amber-200/60 space-y-1">
            <p>
              🔒 {t('chatWarningData')}
            </p>
            <p>
              🤝 {t('chatWarningPayment')}
            </p>
          </div>
        </div>
      </div>

      {/* Messages List from Cloud Firestore */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {messages.length === 0 ? (
          <div className="text-center py-16 text-gray-400 text-xs">
            <MessageSquare className="w-10 h-10 mx-auto text-gray-300 mb-2" />
            <p className="font-medium text-gray-500">Nenhuma mensagem trocada ainda.</p>
            <p className="mt-1 max-w-xs mx-auto">
              Converse diretamente com o produtor para combinar horários, valores e a melhor forma de retirada do alimento.
            </p>
          </div>
        ) : (
          messages.map((msg) => {
            const isMe = msg.senderId === currentUser.id;
            const time = new Date(msg.createdAt).toLocaleTimeString([], {
              hour: '2-digit',
              minute: '2-digit',
            });

            return (
              <div
                key={msg.id}
                className={`flex flex-col ${isMe ? 'items-end' : 'items-start'}`}
              >
                <div
                  className={`max-w-[80%] rounded-2xl px-4 py-2.5 shadow-xs text-xs break-words whitespace-pre-wrap ${
                    isMe
                      ? 'bg-emerald-600 text-white rounded-br-xs'
                      : 'bg-white text-gray-800 border border-gray-200 rounded-bl-xs'
                  }`}
                >
                  {msg.message}
                </div>
                <span className="text-[10px] text-gray-400 mt-0.5 px-1">{time}</span>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Bar */}
      <form onSubmit={handleSendMessage} className="p-3 bg-white border-t border-gray-200 flex items-center gap-2">
        <input
          type="text"
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder={t('sendMessagePlaceholder')}
          className="flex-1 bg-gray-100 border border-gray-200 rounded-xl px-3.5 py-2.5 text-xs text-gray-900 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
        />
        <button
          type="submit"
          disabled={!inputText.trim() || isSending}
          className="p-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl transition cursor-pointer disabled:opacity-50"
        >
          <Send className="w-4 h-4" />
        </button>
      </form>
    </div>
  );
};
