import React, { useState, useEffect, useRef } from 'react';
import { User, ChatMessage } from '../types';
import { store } from '../services/store';
import { ArrowLeft, Send, MessageSquare } from 'lucide-react';

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
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputText, setInputText] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const update = () => {
      setMessages(store.getChatMessages(currentUser.id, receiverId));
    };
    update();
    return store.subscribe(update);
  }, [currentUser.id, receiverId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) return;

    store.sendMessage(currentUser.id, receiverId, inputText.trim());
    setInputText('');

    // If talking to a seller or simulation, generate an automated friendly response if first message
    if (messages.length === 0) {
      setTimeout(() => {
        store.sendMessage(
          receiverId,
          currentUser.id,
          'Olá! Recebemos sua mensagem sobre os alimentos. Podemos combinar a retirada hoje mesmo até às 18h no nosso endereço!'
        );
      }, 1000);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-50 flex flex-col z-40 max-w-xl mx-auto shadow-2xl">
      {/* Header */}
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
          <div className="min-w-0">
            <h3 className="font-bold text-sm truncate">Chat with {receiverName}</h3>
            <p className="text-[11px] text-emerald-200">Online • LogiFlow Direct</p>
          </div>
        </div>
      </div>

      {/* Messages List matching Flutter */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {messages.length === 0 ? (
          <div className="text-center py-20 text-gray-400 text-xs">
            <MessageSquare className="w-10 h-10 mx-auto text-gray-300 mb-2" />
            <p className="font-medium text-gray-500">No messages yet.</p>
            <p>Start the conversation to arrange food rescue pickup!</p>
          </div>
        ) : (
          messages.map((msg) => {
            const isMe = msg.senderId === currentUser.id;
            return (
              <div
                key={msg.id}
                className={`flex flex-col ${isMe ? 'items-end' : 'items-start'}`}
              >
                <div
                  className={`max-w-[78%] px-4 py-2.5 rounded-2xl text-sm leading-relaxed shadow-xs ${
                    isMe
                      ? 'bg-emerald-600 text-white rounded-br-xs'
                      : 'bg-white text-gray-900 border border-gray-200 rounded-bl-xs'
                  }`}
                >
                  <p>{msg.message}</p>
                </div>
                <span className="text-[10px] text-gray-400 mt-1 px-1">
                  {new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Send Message Bar */}
      <form
        onSubmit={handleSendMessage}
        className="bg-white border-t border-gray-200 p-3 flex items-center gap-2 shrink-0 shadow-lg"
      >
        <input
          type="text"
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder="Type a message..."
          className="flex-1 px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white"
        />
        <button
          type="submit"
          disabled={!inputText.trim()}
          className="p-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-full transition shadow-xs cursor-pointer disabled:opacity-40"
        >
          <Send className="w-5 h-5" />
        </button>
      </form>
    </div>
  );
};
