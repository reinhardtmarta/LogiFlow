import { 
  Product, 
  User, 
  SellerSubscription, 
  Tier, 
  TIER_CONFIGS, 
  ChatMessage, 
  StripeCheckoutSession 
} from '../types';

// Seed users
const INITIAL_USERS: User[] = [
  {
    id: 'user_seller_1',
    name: 'Fazenda Sol Verde Orgânicos',
    email: 'contato@solverde.com',
    phone: '(11) 98765-4321',
    address: 'Sítio Boa Vista, Zona Rural, São Paulo - SP',
    isSeller: true,
    settings: {
      language: 'pt',
      interests: ['Frutas & Vegetais', 'Orgânicos', 'Sustentabilidade'],
    },
  },
  {
    id: 'user_consumer_1',
    name: 'Maria Oliveira Silva',
    email: 'maria.silva@email.com',
    phone: '(11) 91234-5678',
    address: 'Av. Paulista, 1500, Apto 42, São Paulo - SP',
    isSeller: false,
    settings: {
      language: 'pt',
      interests: ['Padaria', 'Laticínios', 'Resgate de Alimentos'],
    },
  },
];

// Helper to get relative future dates
const futureDate = (days: number): string => {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
};

const pastDate = (days: number): string => {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d.toISOString();
};

const INITIAL_PRODUCTS: Product[] = [
  {
    id: 'prod_1',
    userId: 'user_seller_1',
    name: 'Maçãs Gala Orgânicas (Caixa 3kg)',
    quantity: 14,
    price: 15.50,
    expiryDate: futureDate(2), // 2 days -> URGENT RESCUE
    condition: 'Ripe',
    isProducer: true,
    address: 'Sítio Boa Vista, Zona Rural, SP',
    imagePaths: [
      'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80',
    ],
    category: 'Fruits & Vegetables',
    isRescue: true,
    isFeatured: true,
    hidden: false,
    wastePreventedKg: 7.0,
    createdAt: pastDate(2),
  },
  {
    id: 'prod_2',
    userId: 'user_seller_1',
    name: 'Pães Artesanais de Fermentação Natural',
    quantity: 8,
    price: 8.90,
    expiryDate: futureDate(1), // 1 day -> URGENT RESCUE
    condition: 'Bakery',
    isProducer: true,
    address: 'Padaria Artesanal Central, SP',
    imagePaths: [
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
    ],
    category: 'Bakery',
    isRescue: true,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 4.0,
    createdAt: pastDate(1),
  },
  {
    id: 'prod_3',
    userId: 'user_seller_1',
    name: 'Leite Fresco Tipo A Pasteurizado 1L',
    quantity: 25,
    price: 4.20,
    expiryDate: futureDate(3), // 3 days -> URGENT RESCUE
    condition: 'Fresh',
    isProducer: true,
    address: 'Laticínios da Serra, SP',
    imagePaths: [
      'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80',
    ],
    category: 'Dairy',
    isRescue: true,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 12.5,
    createdAt: pastDate(3),
  },
  {
    id: 'prod_4',
    userId: 'user_seller_1',
    name: 'Tomates Italianos Maduros (2kg)',
    quantity: 30,
    price: 9.00,
    expiryDate: futureDate(5),
    condition: 'Ripe',
    isProducer: true,
    address: 'Sítio Boa Vista, Zona Rural, SP',
    imagePaths: [
      'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80',
    ],
    category: 'Fruits & Vegetables',
    isRescue: false,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 15.0,
    createdAt: pastDate(4),
  },
  {
    id: 'prod_5',
    userId: 'user_seller_1',
    name: 'Iogurte Natural Integral Artesanal (500g)',
    quantity: 12,
    price: 6.50,
    expiryDate: futureDate(7),
    condition: 'Fresh',
    isProducer: true,
    address: 'Laticínios da Serra, SP',
    imagePaths: [
      'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=600&q=80',
    ],
    category: 'Dairy',
    isRescue: false,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 6.0,
    createdAt: pastDate(5),
  },
  {
    id: 'prod_6',
    userId: 'user_seller_1',
    name: 'Suco de Laranja Integral Prensado a Frio 1L',
    quantity: 18,
    price: 11.00,
    expiryDate: futureDate(4),
    condition: 'Fresh',
    isProducer: true,
    address: 'Pomar Verde, Campinas - SP',
    imagePaths: [
      'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80',
    ],
    category: 'Beverages',
    isRescue: false,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 9.0,
    createdAt: pastDate(2),
  },
  {
    id: 'prod_7',
    userId: 'user_seller_1',
    name: 'Espinafre e Rúcula Hidropônicos (Maço)',
    quantity: 20,
    price: 3.50,
    expiryDate: futureDate(2), // 2 days -> URGENT
    condition: 'Fresh',
    isProducer: true,
    address: 'Horta Hidropônica Verde Viva, SP',
    imagePaths: [
      'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=600&q=80',
    ],
    category: 'Fruits & Vegetables',
    isRescue: true,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 10.0,
    createdAt: pastDate(1),
  },
];

const INITIAL_MESSAGES: ChatMessage[] = [
  {
    id: 'msg_1',
    senderId: 'user_consumer_1',
    receiverId: 'user_seller_1',
    message: 'Olá! As maçãs ainda estão disponíveis para retirada hoje?',
    createdAt: pastDate(1),
  },
  {
    id: 'msg_2',
    senderId: 'user_seller_1',
    receiverId: 'user_consumer_1',
    message: 'Olá Maria! Sim, ainda temos 14 caixas. Se vier até as 18h, reservo para você!',
    createdAt: pastDate(1),
  },
];

class StoreService {
  private users: User[] = [];
  private currentUser: User | null = null;
  private products: Product[] = [];
  private messages: ChatMessage[] = [];
  private subscriptions: Record<string, SellerSubscription> = {};
  private listeners: Set<() => void> = new Set();

  constructor() {
    this.loadFromStorage();
  }

  private loadFromStorage() {
    try {
      const storedUsers = localStorage.getItem('logiflow_users');
      this.users = storedUsers ? JSON.parse(storedUsers) : INITIAL_USERS;

      const storedCurrent = localStorage.getItem('logiflow_current_user');
      if (storedCurrent) {
        this.currentUser = JSON.parse(storedCurrent);
      } else {
        // Default to seller initially for demonstration, or consumer
        this.currentUser = this.users[0] || null;
      }

      const storedProducts = localStorage.getItem('logiflow_products');
      this.products = storedProducts ? JSON.parse(storedProducts) : INITIAL_PRODUCTS;

      const storedMessages = localStorage.getItem('logiflow_messages');
      this.messages = storedMessages ? JSON.parse(storedMessages) : INITIAL_MESSAGES;

      const storedSubs = localStorage.getItem('logiflow_subscriptions');
      if (storedSubs) {
        this.subscriptions = JSON.parse(storedSubs);
      } else {
        // Default subscription for user_seller_1
        this.subscriptions['user_seller_1'] = {
          tier: 'free',
          productLimit: 50,
          status: 'none',
          featuredProductId: 'prod_1',
        };
      }
    } catch {
      this.users = INITIAL_USERS;
      this.currentUser = INITIAL_USERS[0];
      this.products = INITIAL_PRODUCTS;
      this.messages = INITIAL_MESSAGES;
    }
  }

  private saveToStorage() {
    try {
      localStorage.setItem('logiflow_users', JSON.stringify(this.users));
      localStorage.setItem('logiflow_current_user', JSON.stringify(this.currentUser));
      localStorage.setItem('logiflow_products', JSON.stringify(this.products));
      localStorage.setItem('logiflow_messages', JSON.stringify(this.messages));
      localStorage.setItem('logiflow_subscriptions', JSON.stringify(this.subscriptions));
    } catch (e) {
      console.warn('Storage save error:', e);
    }
    this.notify();
  }

  public subscribe(listener: () => void) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private notify() {
    this.listeners.forEach((listener) => listener());
  }

  // ================= User / Auth =================
  public getCurrentUser(): User | null {
    return this.currentUser;
  }

  public setCurrentUser(user: User | null) {
    this.currentUser = user;
    this.saveToStorage();
  }

  public getAllUsers(): User[] {
    return this.users;
  }

  public switchUser(userId: string) {
    const user = this.users.find((u) => u.id === userId);
    if (user) {
      this.setCurrentUser(user);
    }
  }

  public signIn(email: string): User {
    const trimmed = email.trim().toLowerCase();
    let user = this.users.find((u) => u.email.toLowerCase() === trimmed);
    if (!user) {
      // Create user on the fly if not found, to keep demo frictionless
      user = {
        id: 'user_' + Date.now(),
        name: email.split('@')[0],
        email: email.trim(),
        phone: '(11) 99999-9999',
        address: 'São Paulo, SP',
        isSeller: false,
        settings: { language: 'pt', interests: [] },
      };
      this.users.push(user);
    }
    this.setCurrentUser(user);
    return user;
  }

  public signUp(data: {
    name: string;
    email: string;
    password?: string;
    phone: string;
    address: string;
    isSeller: boolean;
  }): User {
    const existing = this.users.find((u) => u.email.toLowerCase() === data.email.trim().toLowerCase());
    if (existing) {
      throw new Error('E-mail já cadastrado.');
    }

    const newUser: User = {
      id: 'user_' + Date.now(),
      name: data.name.trim(),
      email: data.email.trim(),
      phone: data.phone.trim(),
      address: data.address.trim(),
      isSeller: data.isSeller,
      settings: {
        language: 'pt',
        interests: [],
      },
    };

    this.users.push(newUser);

    if (newUser.isSeller) {
      this.subscriptions[newUser.id] = {
        tier: 'free',
        productLimit: 50,
        status: 'none',
      };
    }

    this.setCurrentUser(newUser);
    this.saveToStorage();
    return newUser;
  }

  public signOut() {
    this.currentUser = null;
    this.saveToStorage();
  }

  // ================= Subscriptions =================
  public getSubscription(userId: string): SellerSubscription {
    if (!this.subscriptions[userId]) {
      this.subscriptions[userId] = {
        tier: 'free',
        productLimit: 50,
        status: 'none',
      };
    }
    return this.subscriptions[userId];
  }

  public applySoftLock(userId: string, newLimit: number) {
    if (newLimit < 0) {
      // Unlimited - unhide all
      this.products = this.products.map((p) => (p.userId === userId ? { ...p, hidden: false } : p));
      this.saveToStorage();
      return 0;
    }

    const userProducts = this.products
      .filter((p) => p.userId === userId)
      .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());

    const toHide = userProducts.slice(newLimit);
    const hiddenIds = new Set(toHide.map((p) => p.id));

    this.products = this.products.map((p) => {
      if (p.userId === userId) {
        return { ...p, hidden: hiddenIds.has(p.id) };
      }
      return p;
    });

    this.saveToStorage();
    return toHide.length;
  }

  public createStripeCheckoutSession(tier: Tier, userId: string): StripeCheckoutSession {
    const config = TIER_CONFIGS[tier];
    const externalReference = `${userId}:${tier}:${new Date().toISOString().slice(0, 7)}`;
    return {
      sessionId: 'cs_test_' + Math.random().toString(36).substring(2),
      checkoutUrl: `https://checkout.stripe.com/pay/cs_test_mock_${tier}`,
      amountCents: config.amountCents,
      externalReference,
    };
  }

  public completePayment(userId: string, tier: Tier) {
    const config = TIER_CONFIGS[tier];
    const now = new Date();
    const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString();

    this.subscriptions[userId] = {
      tier,
      productLimit: config.productLimit,
      status: 'active',
      currentPeriodEnd: periodEnd,
    };

    this.applySoftLock(userId, config.productLimit);
    this.saveToStorage();
  }

  public selectFeaturedProduct(userId: string, productId: string) {
    const sub = this.getSubscription(userId);
    if (sub.status !== 'active') {
      throw new Error('Apenas assinantes ativos podem destacar produtos.');
    }

    this.products = this.products.map((p) => {
      if (p.userId === userId) {
        return { ...p, isFeatured: p.id === productId };
      }
      return p;
    });

    this.subscriptions[userId] = {
      ...sub,
      featuredProductId: productId,
    };

    this.saveToStorage();
  }

  // ================= Products =================
  public getProducts(includeHidden = false): Product[] {
    return this.products
      .filter((p) => includeHidden || !p.hidden)
      .sort((a, b) => {
        // Featured first
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        // Then by expiry date ascending
        return new Date(a.expiryDate).getTime() - new Date(b.expiryDate).getTime();
      });
  }

  public getSellerProducts(userId: string, includeHidden = true): Product[] {
    return this.products
      .filter((p) => p.userId === userId && (includeHidden || !p.hidden))
      .sort((a, b) => new Date(a.expiryDate).getTime() - new Date(b.expiryDate).getTime());
  }

  public addProduct(product: Omit<Product, 'id' | 'createdAt' | 'wastePreventedKg' | 'hidden'>): Product {
    const sub = this.getSubscription(product.userId);
    const userProducts = this.products.filter((p) => p.userId === product.userId);

    if (sub.productLimit >= 0 && userProducts.length >= sub.productLimit) {
      throw new Error(`ProductLimitReached: Seu plano atual permite ${sub.productLimit} produtos.`);
    }

    const newProduct: Product = {
      ...product,
      id: 'prod_' + Date.now(),
      createdAt: new Date().toISOString(),
      wastePreventedKg: (product.quantity || 1) * 0.5,
      hidden: false,
    };

    this.products.unshift(newProduct);
    this.saveToStorage();
    return newProduct;
  }

  public updateProductStock(productId: string, newQuantity: number) {
    if (newQuantity < 0) throw new Error('Quantidade não pode ser negativa.');
    this.products = this.products.map((p) =>
      p.id === productId ? { ...p, quantity: newQuantity } : p
    );
    this.saveToStorage();
  }

  public deleteProduct(productId: string) {
    this.products = this.products.filter((p) => p.id !== productId);
    this.saveToStorage();
  }

  // ================= Chat =================
  public getChatMessages(userA: string, userB: string): ChatMessage[] {
    return this.messages.filter(
      (m) =>
        (m.senderId === userA && m.receiverId === userB) ||
        (m.senderId === userB && m.receiverId === userA)
    ).sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
  }

  public sendMessage(senderId: string, receiverId: string, message: string): ChatMessage {
    const trimmed = message.trim();
    if (!trimmed) throw new Error('Mensagem vazia.');

    const newMsg: ChatMessage = {
      id: 'msg_' + Date.now(),
      senderId,
      receiverId,
      message: trimmed,
      createdAt: new Date().toISOString(),
    };

    this.messages.push(newMsg);
    this.saveToStorage();
    return newMsg;
  }

  // ================= AI Insights =================
  public generateSmartInsight(products: Product[]): string {
    const expiringSoon = products.filter((p) => {
      const days = Math.ceil((new Date(p.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
      return days <= 3 && p.quantity > 0;
    });

    if (expiringSoon.length > 0) {
      const sample = expiringSoon[0];
      const days = Math.max(0, Math.ceil((new Date(sample.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24)));
      return `Alerta de Resgate: ${sample.name} vence em ${days === 0 ? 'hoje' : days + ' dia(s)'}! Excelente oportunidade para consumo consciente e desconto especial.`;
    }

    const featured = products.find((p) => p.isFeatured);
    if (featured) {
      return `Destaque do Produtor: Confira ${featured.name} fresco da ${featured.address.split(',')[0]}!`;
    }

    return 'Dica sustentável: Adquirir produtos próximos do vencimento reduz a pegada de carbono e combate o desperdício alimentar.';
  }
}

export const store = new StoreService();
