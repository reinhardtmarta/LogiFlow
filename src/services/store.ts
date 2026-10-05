import { 
  Product, 
  User, 
  SellerSubscription, 
  Tier, 
  TIER_CONFIGS, 
  ChatMessage 
} from '../types';
import { 
  auth, 
  db, 
  docToProduct, 
  handleFirestoreError, 
  OperationType,
  seedInitialProductsIfEmpty
} from './firebase';
import { 
  collection, 
  doc, 
  setDoc, 
  getDoc,
  updateDoc, 
  deleteDoc, 
  onSnapshot,
  query,
  orderBy
} from 'firebase/firestore';
import { onAuthStateChanged, signOut as fbSignOut } from 'firebase/auth';
import { 
  calculateDistanceMeters, 
  getCurrentUserCoordinates, 
  getProductCoordinates 
} from '../utils/distance';
import { sanitizeText, validateNumber } from '../utils/security';

const INITIAL_SAMPLE_PRODUCTS: Product[] = [
  {
    id: 'prod_sample_1',
    userId: 'user_seller_1',
    name: 'Morangos Frescos Orgânicos (Caixa 500g)',
    quantity: 14,
    price: 7.5,
    expiryDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Ótimo',
    isProducer: true,
    address: 'Horta Comunitária Paulista, SP',
    imagePaths: ['https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=600&q=80'],
    category: 'Frutas & Vegetais',
    isRescue: true,
    isFeatured: true,
    hidden: false,
    wastePreventedKg: 7.0,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'prod_sample_2',
    userId: 'user_seller_1',
    name: 'Pães Artesanais de Fermentação Natural',
    quantity: 8,
    price: 8.9,
    expiryDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Padaria',
    isProducer: true,
    address: 'Padaria Artesanal Central, SP',
    imagePaths: ['https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80'],
    category: 'Padaria',
    isRescue: true,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 4.0,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'prod_sample_3',
    userId: 'user_seller_1',
    name: 'Leite Fresco Tipo A Pasteurizado 1L',
    quantity: 25,
    price: 4.2,
    expiryDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Fresco',
    isProducer: true,
    address: 'Laticínios da Serra, SP',
    imagePaths: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80'],
    category: 'Laticínios',
    isRescue: true,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 12.5,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'prod_sample_4',
    userId: 'user_seller_1',
    name: 'Tomates Italianos Maduros (2kg)',
    quantity: 30,
    price: 9.0,
    expiryDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Maduro',
    isProducer: true,
    address: 'Sítio Boa Vista, Zona Rural, SP',
    imagePaths: ['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'],
    category: 'Frutas & Vegetais',
    isRescue: false,
    isFeatured: false,
    hidden: false,
    wastePreventedKg: 15.0,
    createdAt: new Date().toISOString(),
  },
];

class StoreService {
  private currentUser: User | null = null;
  private products: Product[] = [];
  private messages: Record<string, ChatMessage[]> = {}; // chatId -> messages
  private subscriptions: Record<string, SellerSubscription> = {};
  private listeners: Set<() => void> = new Set();
  public isFirestoreLive: boolean = false;
  private activeChatSubscriptions: Map<string, () => void> = new Map();

  constructor() {
    // 1. Manter usuário persistido logado imediatamente
    this.currentUser = this.loadPersistedUser();
    // 2. Sem movimentações: amostragem estática/cacheada do feed sem acionar Firebase
    this.products = this.loadPersistedProducts();
    // 3. Listener passivo de autenticação da conta Google (mantém logado)
    this.initAuthSync();
  }

  private loadPersistedUser(): User | null {
    try {
      const saved = localStorage.getItem('logiflow_active_user');
      if (saved) return JSON.parse(saved);
    } catch (_) {}
    return null;
  }

  private loadPersistedProducts(): Product[] {
    try {
      const saved = localStorage.getItem('logiflow_feed_products');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      }
    } catch (_) {}
    return [...INITIAL_SAMPLE_PRODUCTS];
  }

  private saveProductsLocally(products: Product[]) {
    try {
      localStorage.setItem('logiflow_feed_products', JSON.stringify(products));
    } catch (_) {}
  }

  // Real-time Authentication Sync with Firebase Auth and Firestore Profiles
  private initAuthSync() {
    onAuthStateChanged(auth, async (fbUser) => {
      if (fbUser) {
        try {
          const profileRef = doc(db, 'profiles', fbUser.uid);
          const snap = await getDoc(profileRef);

          if (snap.exists()) {
            const data = snap.data();
            this.currentUser = {
              id: fbUser.uid,
              name: data.name || fbUser.displayName || fbUser.email?.split('@')[0] || 'Usuário',
              email: fbUser.email || '',
              phone: data.phone || '',
              address: data.address || '',
              isSeller: Boolean(data.is_seller),
              settings: { language: 'pt', interests: [] },
            };
            this.subscriptions[fbUser.uid] = {
              tier: (data.plan as Tier) || 'free',
              productLimit: data.product_limit !== undefined ? Number(data.product_limit) : 50,
              status: data.subscription_status || 'none',
              currentPeriodEnd: data.current_period_end,
              featuredProductId: data.featured_product_id,
            };
          } else {
            this.currentUser = {
              id: fbUser.uid,
              name: fbUser.displayName || fbUser.email?.split('@')[0] || 'Usuário Google',
              email: fbUser.email || '',
              phone: '',
              address: 'São Paulo, SP',
              isSeller: false,
              settings: { language: 'pt', interests: [] },
            };
            this.subscriptions[fbUser.uid] = {
              tier: 'free',
              productLimit: 50,
              status: 'none',
            };
          }
        } catch (e) {
          // Fallback persistente caso sem conexão
          this.currentUser = {
            id: fbUser.uid,
            name: fbUser.displayName || 'Usuário LogiFlow',
            email: fbUser.email || '',
            phone: '',
            address: 'Brasil',
            isSeller: false,
            settings: { language: 'pt', interests: [] },
          };
        }
        // Salva para manter usuário 100% logado
        try {
          localStorage.setItem('logiflow_active_user', JSON.stringify(this.currentUser));
        } catch (_) {}
      } else {
        // Apenas limpa se explicitamente deslogado
        this.currentUser = this.loadPersistedUser();
      }
      this.notify();
    });
  }

  // Real-time synchronization of Marketplace Products from Cloud Firestore
  private initFirestoreProductsSync() {
    try {
      const productsCol = collection(db, 'products');
      onSnapshot(
        productsCol,
        (snapshot) => {
          if (!snapshot.empty) {
            const remoteProducts: Product[] = [];
            snapshot.forEach((docSnap) => {
              remoteProducts.push(docToProduct(docSnap.id, docSnap.data()));
            });
            this.products = remoteProducts;
            this.isFirestoreLive = true;
          } else {
            seedInitialProductsIfEmpty();
          }
          this.notify();
        },
        (error) => {
          handleFirestoreError(error, OperationType.GET, 'products');
          this.isFirestoreLive = false;
          this.notify();
        }
      );
    } catch (err) {
      console.warn('Firestore onSnapshot init error:', err);
    }
  }

  public subscribe(listener: () => void) {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
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
    this.notify();
  }

  public async updateUserProfile(updates: Partial<User>) {
    if (!this.currentUser) return;
    this.currentUser = { ...this.currentUser, ...updates };
    try {
      const profileRef = doc(db, 'profiles', this.currentUser.id);
      await updateDoc(profileRef, {
        name: this.currentUser.name,
        phone: this.currentUser.phone,
        address: this.currentUser.address,
        is_seller: this.currentUser.isSeller,
      });
    } catch (e) {
      console.warn('Profile update Firestore notice:', e);
    }
    this.notify();
  }

  public async signOut() {
    await fbSignOut(auth);
    this.currentUser = null;
    this.notify();
  }

  /**
   * Opção 1: Excluir apenas a conta no LogiFlow (Desvincula o perfil do app)
   */
  public async deleteUserAccount(userId: string) {
    try {
      await deleteDoc(doc(db, 'profiles', userId));
    } catch (e) {
      console.warn('Error deleting profile doc:', e);
    }
    delete this.subscriptions[userId];
    await this.signOut();
  }

  /**
   * Opção 2: Exclusão Total de Dados (Direito ao Esquecimento LGPD)
   * Remove perfil, todos os produtos anunciados e limpa dados armazenados
   */
  public async deleteAllUserData(userId: string) {
    // 1. Exclui permanentemente todos os produtos cadastrados pelo usuário no Firestore
    const userProducts = this.products.filter((p) => p.userId === userId);
    for (const p of userProducts) {
      try {
        await deleteDoc(doc(db, 'products', p.id));
      } catch (e) {
        console.warn('Error deleting product during data wipe:', e);
      }
    }
    this.products = this.products.filter((p) => p.userId !== userId);

    // 2. Exclui o documento de perfil no Firestore
    try {
      await deleteDoc(doc(db, 'profiles', userId));
    } catch (e) {
      console.warn('Error deleting profile doc during data wipe:', e);
    }

    delete this.subscriptions[userId];

    // 3. Limpa qualquer cache local
    try {
      if (typeof localStorage !== 'undefined') localStorage.clear();
      if (typeof sessionStorage !== 'undefined') sessionStorage.clear();
    } catch (_) {}

    // 4. Desconecta da autenticação
    await this.signOut();
  }

  // ================= Subscriptions / Pacotes de Capacidade =================
  public getSubscription(userId: string): SellerSubscription {
    const sub = this.subscriptions[userId];
    if (!sub) {
      return {
        tier: 'free',
        productLimit: 50,
        status: 'none',
        packagesCount: 0,
      };
    }

    // Check 30-day package expiration
    if (sub.status === 'active' && sub.currentPeriodEnd) {
      if (new Date(sub.currentPeriodEnd).getTime() < Date.now()) {
        sub.status = 'expired';
        sub.productLimit = 50; // Retorna para a cota gratuita de 50
        sub.packagesCount = 0;
      }
    }

    return sub;
  }

  public async completePayment(userId: string, tier: Tier = 'basic') {
    const currentSub = this.getSubscription(userId);
    const now = new Date();
    const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString();

    // Sucessivo/Cumulativo: se ativo e já tem 1000+, soma +1000 itens!
    let newLimit = 1000;
    const isCurrentlyActive = currentSub.status === 'active' && currentSub.currentPeriodEnd && new Date(currentSub.currentPeriodEnd).getTime() > now.getTime();

    if (isCurrentlyActive && currentSub.productLimit >= 1000) {
      newLimit = currentSub.productLimit + 1000;
    } else {
      newLimit = 1000;
    }

    const packagesCount = Math.floor(newLimit / 1000);

    this.subscriptions[userId] = {
      tier: 'basic',
      productLimit: newLimit,
      status: 'active',
      currentPeriodEnd: periodEnd,
      packagesCount,
    };

    // Persist real package state directly in Cloud Firestore
    try {
      const profileRef = doc(db, 'profiles', userId);
      await setDoc(profileRef, {
        plan: 'basic',
        product_limit: newLimit,
        subscription_status: 'active',
        current_period_end: periodEnd,
        packages_count: packagesCount,
        is_recurring: false, // Pagamento não é recorrente
        updated_at: new Date().toISOString(),
      }, { merge: true });

      // Immutable Financial Audit Record in Firestore
      const paymentAuditId = 'pay_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6);
      await setDoc(doc(db, 'payments', paymentAuditId), {
        payment_id: paymentAuditId,
        user_id: userId,
        amount_reais: 20.00,
        currency: 'BRL',
        product_limit_granted: newLimit,
        period_end: periodEnd,
        created_at: now.toISOString(),
      });
    } catch (e) {
      handleFirestoreError(e, OperationType.UPDATE, `profiles/${userId}`);
    }

    this.notify();
  }

  public async selectFeaturedProduct(userId: string, productId: string) {
    const sub = this.getSubscription(userId);
    if (sub.status !== 'active') {
      throw new Error('Apenas assinantes ativos podem destacar produtos.');
    }

    this.products = this.products.map((p) => {
      if (p.userId === userId) {
        const isFeat = p.id === productId;
        try {
          updateDoc(doc(db, 'products', p.id), { is_featured: isFeat });
        } catch (_) {}
        return { ...p, isFeatured: isFeat };
      }
      return p;
    });

    this.subscriptions[userId] = {
      ...sub,
      featuredProductId: productId,
    };

    try {
      await updateDoc(doc(db, 'profiles', userId), {
        featured_product_id: productId,
      });
    } catch (_) {}

    this.notify();
  }

  // ================= Products =================
  public getProducts(includeHidden = false): Product[] {
    const userLocation = getCurrentUserCoordinates();

    return this.products
      .filter((p) => includeHidden || !p.hidden)
      .map((p, idx) => {
        const coords = (p.latitude !== undefined && p.longitude !== undefined)
          ? { latitude: p.latitude, longitude: p.longitude }
          : getProductCoordinates(idx, p.address);
        const dist = calculateDistanceMeters(
          userLocation.latitude,
          userLocation.longitude,
          coords.latitude,
          coords.longitude
        );
        return {
          ...p,
          latitude: coords.latitude,
          longitude: coords.longitude,
          distanceMeters: dist,
        };
      })
      .sort((a, b) => {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return new Date(a.expiryDate).getTime() - new Date(b.expiryDate).getTime();
      });
  }

  public getSellerProducts(userId: string, includeHidden = true): Product[] {
    return this.products
      .filter((p) => p.userId === userId && (includeHidden || !p.hidden))
      .sort((a, b) => new Date(a.expiryDate).getTime() - new Date(b.expiryDate).getTime());
  }

  public async addProduct(product: Omit<Product, 'id' | 'createdAt' | 'wastePreventedKg' | 'hidden'>): Promise<Product> {
    const sub = this.getSubscription(product.userId);
    const userProducts = this.products.filter((p) => p.userId === product.userId);

    if (sub.productLimit >= 0 && userProducts.length >= sub.productLimit) {
      throw new Error(`ProductLimitReached: Seu plano atual permite ${sub.productLimit} produtos.`);
    }

    const safeName = sanitizeText(product.name, 120);
    const safeAddress = sanitizeText(product.address, 200);
    const safeCategory = sanitizeText(product.category, 60);
    const safePrice = Math.max(0, Number(product.price) || 0);
    const safeQty = Math.max(0, Math.min(100000, Math.floor(Number(product.quantity) || 1)));

    const prodId = 'prod_' + Date.now();
    const newProduct: Product = {
      ...product,
      name: safeName,
      address: safeAddress,
      category: safeCategory,
      price: safePrice,
      quantity: safeQty,
      id: prodId,
      createdAt: new Date().toISOString(),
      wastePreventedKg: safeQty * 0.5,
      hidden: false,
    };

    // Optimistic update
    this.products.unshift(newProduct);
    this.saveProductsLocally(this.products);
    this.notify();

    // Persist to Cloud Firestore in real time
    try {
      await setDoc(doc(db, 'products', prodId), {
        seller_id: newProduct.userId,
        name: newProduct.name,
        quantity: newProduct.quantity,
        price: newProduct.price,
        expiry_date: newProduct.expiryDate,
        condition: newProduct.condition,
        is_producer: newProduct.isProducer,
        address: newProduct.address,
        latitude: newProduct.latitude,
        longitude: newProduct.longitude,
        image_paths: newProduct.imagePaths,
        category: newProduct.category,
        is_rescue: newProduct.isRescue,
        is_featured: newProduct.isFeatured,
        hidden: newProduct.hidden,
        waste_prevented_kg: newProduct.wastePreventedKg,
        created_at: newProduct.createdAt,
      });
    } catch (e) {
      handleFirestoreError(e, OperationType.CREATE, `products/${prodId}`);
    }

    return newProduct;
  }

  public async updateProductStock(productId: string, newQuantity: number) {
    if (newQuantity < 0) throw new Error('Quantidade não pode ser negativa.');
    this.products = this.products.map((p) =>
      p.id === productId ? { ...p, quantity: newQuantity } : p
    );
    this.notify();

    // Sync to Cloud Firestore
    try {
      await updateDoc(doc(db, 'products', productId), {
        quantity: newQuantity,
      });
    } catch (e) {
      handleFirestoreError(e, OperationType.UPDATE, `products/${productId}`);
    }
  }

  public async deleteProduct(productId: string) {
    this.products = this.products.filter((p) => p.id !== productId);
    this.notify();

    // Delete in Cloud Firestore
    try {
      await deleteDoc(doc(db, 'products', productId));
    } catch (e) {
      handleFirestoreError(e, OperationType.DELETE, `products/${productId}`);
    }
  }

  // ================= Real-Time Firestore Chat =================
  private getChatKey(userA: string, userB: string): string {
    return [userA, userB].sort().join('_');
  }

  public subscribeToChat(userA: string, userB: string, onUpdate: (msgs: ChatMessage[]) => void) {
    const chatKey = this.getChatKey(userA, userB);
    const messagesCol = collection(db, 'chats', chatKey, 'messages');
    const q = query(messagesCol, orderBy('created_at', 'asc'));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const msgs: ChatMessage[] = [];
      snapshot.forEach((d) => {
        const data = d.data();
        msgs.push({
          id: d.id,
          senderId: data.sender_id || data.senderId,
          receiverId: data.receiver_id || data.receiverId,
          message: data.message || '',
          createdAt: data.created_at || data.createdAt || new Date().toISOString(),
        });
      });
      this.messages[chatKey] = msgs;
      onUpdate(msgs);
    }, (err) => {
      handleFirestoreError(err, OperationType.GET, `chats/${chatKey}/messages`);
    });

    return unsubscribe;
  }

  public getChatMessages(userA: string, userB: string): ChatMessage[] {
    const chatKey = this.getChatKey(userA, userB);
    return this.messages[chatKey] || [];
  }

  public async sendMessage(senderId: string, receiverId: string, message: string): Promise<ChatMessage> {
    const trimmed = sanitizeText(message, 1500);
    if (!trimmed) throw new Error('Mensagem vazia ou inválida.');

    const chatKey = this.getChatKey(senderId, receiverId);
    const msgId = 'msg_' + Date.now();

    const newMsg: ChatMessage = {
      id: msgId,
      senderId,
      receiverId,
      message: trimmed,
      createdAt: new Date().toISOString(),
    };

    if (!this.messages[chatKey]) {
      this.messages[chatKey] = [];
    }
    this.messages[chatKey].push(newMsg);
    this.notify();

    // Persist in Cloud Firestore subcollection
    try {
      await setDoc(doc(db, 'chats', chatKey, 'messages', msgId), {
        sender_id: senderId,
        receiver_id: receiverId,
        message: trimmed,
        created_at: newMsg.createdAt,
      });

      // Update chat meta
      await setDoc(doc(db, 'chats', chatKey), {
        participants: [senderId, receiverId],
        last_message: trimmed,
        last_update: newMsg.createdAt,
      }, { merge: true });
    } catch (e) {
      handleFirestoreError(e, OperationType.CREATE, `chats/${chatKey}/messages/${msgId}`);
    }

    return newMsg;
  }

  // ================= Smart Insight =================
  public generateSmartInsight(products: Product[]): string {
    const expiringSoon = products.filter((p) => {
      const days = Math.ceil((new Date(p.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
      return days <= 3 && p.quantity > 0;
    });

    if (expiringSoon.length > 0) {
      const sample = expiringSoon[0];
      const days = Math.max(0, Math.ceil((new Date(sample.expiryDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24)));
      return `Alerta de Resgate em Tempo Real: ${sample.name} vence em ${days === 0 ? 'hoje' : days + ' dia(s)'}! Resgate prioritário no feed.`;
    }

    const featured = products.find((p) => p.isFeatured);
    if (featured) {
      return `Destaque do Produtor: Confira ${featured.name} fresco sincronizado direto do produtor!`;
    }

    return 'Dica sustentável: Adquirir produtos em resgate reduz o desperdício alimentar e apoia os agricultores locais.';
  }
}

export const store = new StoreService();
