import React, { useState, useEffect } from 'react';
import { User, Tier } from './types';
import { store } from './services/store';
import { Header } from './components/Header';
import { BottomNav } from './components/BottomNav';
import { GeneralFeedScreen } from './screens/GeneralFeedScreen';
import { MarketplaceScreen } from './screens/MarketplaceScreen';
import { SearchScreen } from './screens/SearchScreen';
import { SellerDashboard } from './screens/SellerDashboard';
import { AddProductModal } from './screens/AddProductModal';
import { StockScreen } from './screens/StockScreen';
import { UpgradeScreen } from './screens/UpgradeScreen';
import { SelectFeaturedScreen } from './screens/SelectFeaturedScreen';
import { ChatScreen } from './screens/ChatScreen';
import { AiAssistantScreen } from './screens/AiAssistantScreen';
import { AuthScreen } from './screens/AuthScreen';

export const App: React.FC = () => {
  const [currentUser, setCurrentUser] = useState<User | null>(store.getCurrentUser());
  const [currentTab, setCurrentTab] = useState(0);

  // Modals & sub-screens
  const [showAddProduct, setShowAddProduct] = useState(false);
  const [showStockScreen, setShowStockScreen] = useState(false);
  const [showUpgrade, setShowUpgrade] = useState<{ open: boolean; tier: Tier }>({
    open: false,
    tier: 'basic',
  });
  const [showFeaturedSelect, setShowFeaturedSelect] = useState(false);
  const [activeChat, setActiveChat] = useState<{
    open: boolean;
    receiverId: string;
    receiverName: string;
  }>({
    open: false,
    receiverId: '',
    receiverName: '',
  });
  const [showAuthModal, setShowAuthModal] = useState(false);

  // Gemma AI Insight message state
  const [aiInsightMessage, setAiInsightMessage] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  useEffect(() => {
    const update = () => {
      setCurrentUser(store.getCurrentUser());
    };
    return store.subscribe(update);
  }, []);

  // Generate initial insight on mount
  useEffect(() => {
    const products = store.getProducts();
    if (products.length > 0) {
      setAiInsightMessage(store.generateSmartInsight(products));
    }
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage(null);
    }, 3000);
  };

  const handleRefreshAiInsight = () => {
    const products = store.getProducts();
    setAiInsightMessage(store.generateSmartInsight(products));
    showToast('Nova dica gerada pela Gemma!');
  };

  const handleOpenChat = (receiverId: string, receiverName: string) => {
    if (!currentUser) {
      setShowAuthModal(true);
      return;
    }
    setActiveChat({
      open: true,
      receiverId,
      receiverName,
    });
  };

  // If user is logged out, show the auth screen
  if (!currentUser) {
    return (
      <AuthScreen
        onSuccess={(user) => {
          setCurrentUser(user);
          showToast(`Bem-vindo, ${user.name}!`);
        }}
      />
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col antialiased select-none sm:select-auto">
      {/* Top Header */}
      <Header
        user={currentUser}
        onRefreshAi={handleRefreshAiInsight}
        onOpenAuth={() => setShowAuthModal(true)}
      />

      {/* Main Content Router based on currentTab */}
      <main className="flex-1 w-full">
        {currentTab === 0 && (
          <GeneralFeedScreen
            user={currentUser}
            onOpenChat={handleOpenChat}
            aiInsightMessage={aiInsightMessage}
            onDismissAiInsight={() => setAiInsightMessage(null)}
          />
        )}

        {currentTab === 1 && <SearchScreen onOpenChat={handleOpenChat} />}

        {currentTab === 2 &&
          (currentUser.isSeller ? (
            <SellerDashboard
              user={currentUser}
              onOpenAddProduct={() => setShowAddProduct(true)}
              onOpenStockScreen={() => setShowStockScreen(true)}
              onOpenUpgrade={(tier) => setShowUpgrade({ open: true, tier })}
              onOpenFeaturedSelect={() => setShowFeaturedSelect(true)}
            />
          ) : (
            <MarketplaceScreen user={currentUser} onOpenChat={handleOpenChat} />
          ))}

        {currentTab === 3 && (
          <AiAssistantScreen user={currentUser} onOpenChat={handleOpenChat} />
        )}
      </main>

      {/* Bottom Navigation */}
      <BottomNav
        currentTab={currentTab}
        onTabChange={(idx) => {
          setShowStockScreen(false);
          setShowUpgrade({ open: false, tier: 'basic' });
          setShowFeaturedSelect(false);
          setActiveChat({ open: false, receiverId: '', receiverName: '' });
          setCurrentTab(idx);
        }}
        isSeller={currentUser.isSeller}
      />

      {/* Modals & Sub-Screens */}
      {showAddProduct && (
        <AddProductModal
          user={currentUser}
          onClose={() => setShowAddProduct(false)}
          onOpenUpgrade={(tierNeeded) => {
            setShowAddProduct(false);
            setShowUpgrade({ open: true, tier: tierNeeded });
          }}
        />
      )}

      {showStockScreen && (
        <div className="fixed inset-0 bg-slate-50 z-30 overflow-y-auto">
          <StockScreen
            user={currentUser}
            onBack={() => setShowStockScreen(false)}
          />
        </div>
      )}

      {showUpgrade.open && (
        <div className="fixed inset-0 bg-slate-50 z-30 overflow-y-auto">
          <UpgradeScreen
            user={currentUser}
            suggestedTier={showUpgrade.tier}
            onBack={() => setShowUpgrade({ open: false, tier: 'basic' })}
            onSuccess={() => {
              setShowUpgrade({ open: false, tier: 'basic' });
              showToast('Assinatura ativada com sucesso!');
            }}
          />
        </div>
      )}

      {showFeaturedSelect && (
        <div className="fixed inset-0 bg-slate-50 z-30 overflow-y-auto">
          <SelectFeaturedScreen
            user={currentUser}
            onBack={() => setShowFeaturedSelect(false)}
            onSuccess={() => {
              setShowFeaturedSelect(false);
              showToast('Produto em destaque atualizado no feed!');
            }}
          />
        </div>
      )}

      {activeChat.open && (
        <ChatScreen
          currentUser={currentUser}
          receiverId={activeChat.receiverId}
          receiverName={activeChat.receiverName}
          onBack={() =>
            setActiveChat({ open: false, receiverId: '', receiverName: '' })
          }
        />
      )}

      {showAuthModal && (
        <AuthScreen
          onSuccess={(u) => {
            setShowAuthModal(false);
            setCurrentUser(u);
            showToast(`Conectado como ${u.name}`);
          }}
          onClose={() => setShowAuthModal(false)}
        />
      )}

      {/* Floating Notification Toast */}
      {toastMessage && (
        <div className="fixed top-16 left-1/2 -translate-x-1/2 bg-gray-900 text-white px-4 py-2.5 rounded-full text-xs font-semibold shadow-lg z-50 animate-in fade-in slide-in-from-top-3 duration-200">
          {toastMessage}
        </div>
      )}
    </div>
  );
};
