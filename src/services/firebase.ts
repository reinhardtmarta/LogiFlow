import { initializeApp, getApps, getApp } from 'firebase/app';
import { 
  getAuth, 
  GoogleAuthProvider, 
  signInWithPopup, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut as fbSignOut,
  onAuthStateChanged
} from 'firebase/auth';
import { 
  getFirestore, 
  collection, 
  doc, 
  setDoc, 
  getDoc, 
  getDocs, 
  onSnapshot, 
  updateDoc, 
  deleteDoc, 
  query, 
  orderBy, 
  where,
  getDocFromServer
} from 'firebase/firestore';
import firebaseConfig from '../firebase-applet-config.json';
import { Product, User, ChatMessage } from '../types';

// Initialize Firebase App
const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);

// Initialize Auth & Firestore with firestoreDatabaseId
export const auth = getAuth(app);
export const db = getFirestore(app, firebaseConfig.firestoreDatabaseId);
export const googleProvider = new GoogleAuthProvider();

// Error handler conforming to Firebase Integration Skill
export enum OperationType {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
  LIST = 'list',
  GET = 'get',
  WRITE = 'write',
}

export interface FirestoreErrorInfo {
  error: string;
  operationType: OperationType;
  path: string | null;
  authInfo: {
    userId?: string | null;
    email?: string | null;
    emailVerified?: boolean | null;
  };
}

export function handleFirestoreError(error: unknown, operationType: OperationType, path: string | null) {
  const errInfo: FirestoreErrorInfo = {
    error: error instanceof Error ? error.message : String(error),
    authInfo: {
      userId: auth.currentUser?.uid,
      email: auth.currentUser?.email,
      emailVerified: auth.currentUser?.emailVerified,
    },
    operationType,
    path,
  };
  console.warn('Firestore Operation Notice:', JSON.stringify(errInfo));
  return errInfo;
}

// Connection test from skill
export async function testFirestoreConnection() {
  try {
    await getDocFromServer(doc(db, 'test', 'connection'));
  } catch (error) {
    if (error instanceof Error && error.message.includes('the client is offline')) {
      console.warn('Firestore offline notice. Retrying connection...');
    }
  }
}
testFirestoreConnection();

// Initial Seed Products
const SEED_PRODUCTS = [
  {
    seller_id: 'user_seller_1',
    name: 'Maçãs Gala Orgânicas (Caixa 3kg)',
    quantity: 14,
    price: 15.50,
    expiry_date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Ripe',
    is_producer: true,
    address: 'Sítio Boa Vista, Zona Rural, SP',
    image_paths: ['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'],
    category: 'Fruits & Vegetables',
    is_rescue: true,
    is_featured: true,
    hidden: false,
    waste_prevented_kg: 7.0,
    created_at: new Date().toISOString(),
  },
  {
    seller_id: 'user_seller_1',
    name: 'Pães Artesanais de Fermentação Natural',
    quantity: 8,
    price: 8.90,
    expiry_date: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Bakery',
    is_producer: true,
    address: 'Padaria Artesanal Central, SP',
    image_paths: ['https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80'],
    category: 'Bakery',
    is_rescue: true,
    is_featured: false,
    hidden: false,
    waste_prevented_kg: 4.0,
    created_at: new Date().toISOString(),
  },
  {
    seller_id: 'user_seller_1',
    name: 'Leite Fresco Tipo A Pasteurizado 1L',
    quantity: 25,
    price: 4.20,
    expiry_date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Fresh',
    is_producer: true,
    address: 'Laticínios da Serra, SP',
    image_paths: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80'],
    category: 'Dairy',
    is_rescue: true,
    is_featured: false,
    hidden: false,
    waste_prevented_kg: 12.5,
    created_at: new Date().toISOString(),
  },
  {
    seller_id: 'user_seller_1',
    name: 'Tomates Italianos Maduros (2kg)',
    quantity: 30,
    price: 9.00,
    expiry_date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Ripe',
    is_producer: true,
    address: 'Sítio Boa Vista, Zona Rural, SP',
    image_paths: ['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'],
    category: 'Fruits & Vegetables',
    is_rescue: false,
    is_featured: false,
    hidden: false,
    waste_prevented_kg: 15.0,
    created_at: new Date().toISOString(),
  },
  {
    seller_id: 'user_seller_1',
    name: 'Iogurte Natural Integral Artesanal (500g)',
    quantity: 12,
    price: 6.50,
    expiry_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Fresh',
    is_producer: true,
    address: 'Laticínios da Serra, SP',
    image_paths: ['https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=600&q=80'],
    category: 'Dairy',
    is_rescue: false,
    is_featured: false,
    hidden: false,
    waste_prevented_kg: 6.0,
    created_at: new Date().toISOString(),
  },
  {
    seller_id: 'user_seller_1',
    name: 'Suco de Laranja Integral Prensado a Frio 1L',
    quantity: 18,
    price: 11.00,
    expiry_date: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000).toISOString(),
    condition: 'Fresh',
    is_producer: true,
    address: 'Pomar Verde, Campinas - SP',
    image_paths: ['https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=600&q=80'],
    category: 'Beverages',
    is_rescue: false,
    is_featured: false,
    hidden: false,
    waste_prevented_kg: 9.0,
    created_at: new Date().toISOString(),
  },
];

export async function seedInitialProductsIfEmpty() {
  try {
    const productsSnap = await getDocs(collection(db, 'products'));
    if (productsSnap.empty) {
      for (let i = 0; i < SEED_PRODUCTS.length; i++) {
        const item = SEED_PRODUCTS[i];
        await setDoc(doc(db, 'products', `prod_${i + 1}`), item);
      }
    }
  } catch (e) {
    handleFirestoreError(e, OperationType.WRITE, 'products');
  }
}

// Seed on startup
seedInitialProductsIfEmpty();

// Helper to format Firestore Product doc to TypeScript Product
export function docToProduct(id: string, data: any): Product {
  return {
    id,
    userId: data.seller_id || data.userId || '',
    name: data.name || '',
    quantity: Number(data.quantity || 0),
    price: Number(data.price || 0),
    expiryDate: data.expiry_date || data.expiryDate || new Date().toISOString(),
    condition: data.condition || 'Fresh',
    isProducer: Boolean(data.is_producer ?? data.isProducer),
    address: data.address || '',
    latitude: data.latitude !== undefined ? Number(data.latitude) : undefined,
    longitude: data.longitude !== undefined ? Number(data.longitude) : undefined,
    imagePath: data.image_path || data.imagePath,
    imagePaths: Array.isArray(data.image_paths) ? data.image_paths : (data.image_path ? [data.image_path] : []),
    category: data.category || 'Other',
    isRescue: Boolean(data.is_rescue ?? data.isRescue),
    isFeatured: Boolean(data.is_featured ?? data.isFeatured),
    hidden: Boolean(data.hidden),
    wastePreventedKg: Number(data.waste_prevented_kg || data.wastePreventedKg || 0),
    createdAt: data.created_at || data.createdAt || new Date().toISOString(),
  };
}
