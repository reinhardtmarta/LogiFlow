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
    label: 'Plano Grátis',
    amountCents: 0,
    priceLabel: 'R$ 0,00',
    productLimit: 50,
    limitLabel: 'Até 50 produtos (grátis)',
    maxPhotos: 1,
  },
  basic: {
    id: 'basic',
    label: 'Pacote +1.000 itens (30 dias)',
    amountCents: 2000,
    priceLabel: 'R$ 20,00',
    productLimit: 1000,
    limitLabel: '+1.000 itens por 30 dias (não recorrente)',
    maxPhotos: 5,
  },
  pro: {
    id: 'pro',
    label: 'Pacote Extra (+1.000 itens)',
    amountCents: 2000,
    priceLabel: 'R$ 20,00',
    productLimit: 1000,
    limitLabel: 'Adicione mais 1.000 itens por R$ 20',
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
  packagesCount?: number;
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
  latitude?: number;
  longitude?: number;
  distanceMeters?: number;
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
