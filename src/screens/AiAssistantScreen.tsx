import React, { useState } from 'react';
import { User, Product } from '../types';
import { gemmaService } from '../services/gemmaService';
import { Sparkles, Send, Bot, User as UserIcon, Loader2, ArrowRight } from 'lucide-react';

interface AiAssistantScreenProps {
  user: User;
  onOpenChat: (receiverId: string, receiverName: string) => void;
}

interface MessageItem {
  id: string;
  role: 'user' | 'gemma';
  text: string;
  matchedProducts?: Product[];
}

export const AiAssistantScreen: React.FC<AiAssistantScreenProps> = ({ user, onOpenChat }) => {
  const [messages, setMessages] = useState<MessageItem[]>([]);
  const [prompt, setPrompt] = useState('');
  const [isThinking, setIsThinking] = useState(false);

  const samplePrompts = [
    'Quais alimentos estão com prazo urgente de resgate?',
    'Do we have organic milk or dairy in stock?',
    'Dicas de receitas para aproveitar maçãs maduras',
    'Como conservar pães artesanais por mais tempo?',
  ];

  const handleSendPrompt = async (textToSend?: string) => {
    const q = (textToSend || prompt).trim();
    if (!q || isThinking) return;

    const userMsg: MessageItem = {
      id: 'usr_' + Date.now(),
      role: 'user',
      text: q,
    };

    setMessages((prev) => [...prev, userMsg]);
    setPrompt('');
    setIsThinking(true);

    try {
      // Simulate natural AI thinking delay
      await new Promise((r) => setTimeout(r, 600));
      const res = await gemmaService.processQuery(q);

      const gemmaMsg: MessageItem = {
        id: 'gem_' + Date.now(),
        role: 'gemma',
        text: res.text,
        matchedProducts: res.matchedProducts,
      };

      setMessages((prev) => [...prev, gemmaMsg]);
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          id: 'gem_' + Date.now(),
          role: 'gemma',
          text: 'Erro de processamento na comunicação com a IA.',
        },
      ]);
    } finally {
      setIsThinking(false);
    }
  };

  return (
    <div className="pb-24 pt-3 max-w-xl mx-auto px-4 flex flex-col h-[calc(100vh-60px)]">
      {/* Header */}
      <div className="mb-3 shrink-0">
        <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-emerald-600" />
          Gemma 4 AI Assistant
        </h2>
        <p className="text-xs text-gray-500">
          Inteligência dedicada para gestão de estoque e resgate de alimentos
        </p>
      </div>

      {/* Messages Thread */}
      <div className="flex-1 overflow-y-auto space-y-3.5 pr-1">
        {messages.length === 0 ? (
          <div className="py-8 text-center">
            <div className="w-14 h-14 rounded-2xl bg-emerald-100/60 text-emerald-700 flex items-center justify-center mx-auto mb-3">
              <Bot className="w-7 h-7" />
            </div>
            <h3 className="font-bold text-gray-800 text-sm">
              Pergunte qualquer coisa sobre estoque 🌱
            </h3>
            <p className="text-xs text-gray-400 mt-1 max-w-xs mx-auto">
              Descubra quais itens estão prestes a vencer, dicas de conservação ou busque ofertas.
            </p>

            {/* Suggested Prompts */}
            <div className="mt-6 space-y-2 max-w-sm mx-auto text-left">
              <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider px-1">
                Sugestões rápidas
              </p>
              {samplePrompts.map((sp) => (
                <button
                  key={sp}
                  onClick={() => handleSendPrompt(sp)}
                  className="w-full text-left p-2.5 bg-white hover:bg-emerald-50 border border-gray-200 hover:border-emerald-300 rounded-xl text-xs text-gray-700 transition cursor-pointer flex items-center justify-between group shadow-2xs"
                >
                  <span className="truncate">{sp}</span>
                  <ArrowRight className="w-3.5 h-3.5 text-gray-400 group-hover:text-emerald-600 shrink-0 ml-2" />
                </button>
              ))}
            </div>
          </div>
        ) : (
          messages.map((msg) => {
            const isUser = msg.role === 'user';
            return (
              <div
                key={msg.id}
                className={`flex gap-2.5 ${isUser ? 'justify-end' : 'justify-start'}`}
              >
                {!isUser && (
                  <div className="w-7 h-7 rounded-lg bg-emerald-600 text-white flex items-center justify-center shrink-0 mt-0.5">
                    <Bot className="w-4 h-4" />
                  </div>
                )}

                <div
                  className={`max-w-[85%] rounded-2xl p-3.5 text-sm leading-relaxed shadow-2xs ${
                    isUser
                      ? 'bg-emerald-600 text-white rounded-tr-xs'
                      : 'bg-white text-gray-800 border border-gray-200 rounded-tl-xs'
                  }`}
                >
                  <p className="whitespace-pre-line">{msg.text}</p>

                  {/* Matched product buttons inside AI response */}
                  {msg.matchedProducts && msg.matchedProducts.length > 0 && (
                    <div className="mt-3 pt-2 border-t border-gray-100 space-y-1.5">
                      <p className="text-[11px] font-bold text-gray-500 uppercase">
                        Ação rápida:
                      </p>
                      {msg.matchedProducts.map((p) => (
                        <button
                          key={p.id}
                          onClick={() => onOpenChat(p.userId, 'Produtor')}
                          className="w-full text-left p-2 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-900 text-xs font-medium transition cursor-pointer flex items-center justify-between"
                        >
                          <span className="truncate">Conversar sobre: {p.name}</span>
                          <span className="font-bold text-emerald-700 shrink-0 ml-1">
                            R$ {p.price.toFixed(2)}
                          </span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {isUser && (
                  <div className="w-7 h-7 rounded-lg bg-gray-200 text-gray-700 flex items-center justify-center shrink-0 mt-0.5">
                    <UserIcon className="w-4 h-4" />
                  </div>
                )}
              </div>
            );
          })
        )}

        {isThinking && (
          <div className="flex items-center gap-2 text-xs text-gray-500 py-1 px-1">
            <Loader2 className="w-4 h-4 text-emerald-600 animate-spin" />
            <span>Gemma 4 is checking data...</span>
          </div>
        )}
      </div>

      {/* Input section matching Flutter */}
      <div className="pt-2 shrink-0">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            handleSendPrompt();
          }}
          className="flex items-center gap-2 bg-white p-2 rounded-2xl border border-gray-300 shadow-sm focus-within:ring-2 focus-within:ring-emerald-500"
        >
          <input
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Do we have organic milk?"
            className="flex-1 px-3 py-1.5 text-sm bg-transparent border-none focus:outline-none text-gray-800"
          />
          <button
            type="submit"
            disabled={!prompt.trim() || isThinking}
            className="p-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl transition cursor-pointer disabled:opacity-30 shrink-0"
          >
            <Send className="w-4 h-4" />
          </button>
        </form>

        <p className="text-[11px] text-center text-gray-400 mt-2 font-medium">
          Powered by Gemma 4
        </p>
      </div>
    </div>
  );
};
