export type Tier = 'free' | 'basic' | 'pro';

export interface TierConfig {
  id: Tier;
  label: string;
  amountCents: number;
  priceLabel: string;
  productLimit: number; // -1 for unlimited
  limitLabel: string;
  maxPhotos: number;
}

export const TIER_CONFIGS: Record<Tier, TierConfig> = {
  free: {
    id: 'free',
    label: 'Grátis',
    amountCents: 0,
    priceLabel: 'R$ 0,00',
    productLimit: 50,
    limitLabel: 'Até 50 produtos',
    maxPhotos: 1,
  },
  basic: {
    id: 'basic',
    label: 'Basic (até 1000 produtos)',
    amountCents: 1000,
    priceLabel: 'R$ 10,00',
    productLimit: 1000,
    limitLabel: 'Até 1000 produtos',
    maxPhotos: 5,
  },
  pro: {
    id: 'pro',
    label: 'Pro (acima de 1000 produtos)',
    amountCents: 10000,
    priceLabel: 'R$ 100,00',
    productLimit: -1,
    limitLabel: 'Produtos ilimitados',
    maxPhotos: 5,
  },
};

export type SubscriptionStatus = 'none' | 'active' | 'expired';

export interface SellerSubscription {
  tier: Tier;
  productLimit: number;
  status: SubscriptionStatus;
  currentPeriodEnd?: string;
  featuredProductId?: string;
}

export interface UserSettings {
  language: 'pt' | 'en';
  interests: string[];
}

export interface User {
  id: string;
  name: string;
  email: string;
  password?: string;
  phone: string;
  address: string;
  isSeller: boolean;
  settings: UserSettings;
}

export interface Product {
  id: string;
  userId: string;
  name: string;
  quantity: number;
  price: number;
  expiryDate: string; // ISO String
  condition: string;
  isProducer: boolean;
  address: string;
  imagePath?: string;
  imagePaths: string[];
  category: string;
  isRescue: boolean;
  isFeatured: boolean;
  hidden: boolean;
  wastePreventedKg: number;
  createdAt: string;
}

export interface ChatMessage {
  id: string;
  senderId: string;
  receiverId: string;
  message: string;
  createdAt: string;
}

export interface StripeCheckoutSession {
  sessionId: string;
  checkoutUrl: string;
  amountCents: number;
  externalReference: string;
}

export type SearchIntent = 'search' | 'outOfContext' | 'itemNotFound';

export interface IntentResult {
  intent: SearchIntent;
  query: string;
  message: string;
}
