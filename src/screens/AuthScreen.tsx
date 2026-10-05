import React, { useState } from 'react';
import { store } from '../services/store';
import { auth, googleProvider, db } from '../services/firebase';
import { signInWithPopup } from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { User } from '../types';
import { TermsModal } from '../components/TermsModal';
import { 
  Leaf, 
  Loader2, 
  AlertCircle,
  FileText
} from 'lucide-react';

interface AuthScreenProps {
  onSuccess: (user: User) => void;
  onClose?: () => void;
}

export const AuthScreen: React.FC<AuthScreenProps> = ({ onSuccess, onClose }) => {
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showTerms, setShowTerms] = useState(false);

  // Exclusive Official Google Sign-In
  const handleGoogleLogin = async () => {
    setIsLoading(true);
    setErrorMsg(null);

    try {
      const result = await signInWithPopup(auth, googleProvider);
      const fbUser = result.user;
      const profileRef = doc(db, 'profiles', fbUser.uid);
      const snap = await getDoc(profileRef);

      let profileData = snap.exists() ? snap.data() : null;

      // Only save basic info the user chose to share
      if (!profileData) {
        profileData = {
          uid: fbUser.uid,
          name: fbUser.displayName || 'Usuário Google',
          email: fbUser.email || '',
          phone: '',
          address: '',
          is_seller: false,
          product_limit: 50,
          subscription_status: 'none',
          plan: 'free',
          created_at: new Date().toISOString(),
        };
        await setDoc(profileRef, profileData);
      }

      const user: User = {
        id: fbUser.uid,
        name: profileData.name || fbUser.displayName || 'Usuário Google',
        email: fbUser.email || '',
        phone: profileData.phone || '',
        address: profileData.address || '',
        isSeller: Boolean(profileData.is_seller),
        settings: { language: 'pt', interests: [] },
      };

      store.setCurrentUser(user);
      onSuccess(user);
    } catch (err: any) {
      if (err.code === 'auth/popup-closed-by-user') {
        setErrorMsg('Janela de login com Google fechada antes de concluir.');
      } else if (err.code === 'auth/popup-blocked') {
        setErrorMsg('Pop-up bloqueado pelo navegador. Permita pop-ups para fazer login com Google.');
      } else {
        setErrorMsg(err.message || 'Não foi possível conectar com o Google no momento.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <div className="fixed inset-0 bg-gray-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-150">
        <div className="bg-white w-full max-w-sm rounded-3xl shadow-2xl border border-gray-100 p-6 sm:p-8 my-auto relative text-center">
          {onClose && (
            <button
              onClick={onClose}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-sm font-semibold cursor-pointer p-1"
            >
              ✕
            </button>
          )}

          {/* Branding & Logo */}
          <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center mx-auto mb-3 shadow-xs">
            <Leaf className="w-8 h-8" />
          </div>

          <h1 className="text-2xl font-black text-gray-900 tracking-tight">
            LogiFlow
          </h1>
          <p className="text-xs text-gray-500 mt-1">
            Entre com sua conta Google
          </p>

          {errorMsg && (
            <div className="mt-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-xl text-xs flex items-center gap-2 text-left">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* Google Login Action */}
          <div className="mt-6">
            <button
              type="button"
              onClick={handleGoogleLogin}
              disabled={isLoading}
              className="w-full py-3.5 px-4 bg-white hover:bg-gray-50 text-gray-800 font-bold rounded-2xl text-sm border-2 border-gray-200 shadow-md hover:shadow-lg transition cursor-pointer flex items-center justify-center gap-3 disabled:opacity-60"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin text-emerald-600" />
                  <span>Conectando com o Google...</span>
                </>
              ) : (
                <>
                  <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
                    <path
                      fill="#4285F4"
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    />
                    <path
                      fill="#34A853"
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                    />
                    <path
                      fill="#EA4335"
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                    />
                  </svg>
                  <span>Continuar com o Google</span>
                </>
              )}
            </button>
          </div>

          {/* Informative Terms of Use Button */}
          <div className="mt-6 pt-4 border-t border-gray-100">
            <button
              type="button"
              onClick={() => setShowTerms(true)}
              className="inline-flex items-center gap-1.5 text-xs text-emerald-700 hover:text-emerald-800 font-semibold cursor-pointer underline underline-offset-2"
            >
              <FileText className="w-3.5 h-3.5" />
              <span>Termos de Uso e Política de Privacidade</span>
            </button>
            <p className="text-[10px] text-gray-400 mt-2 leading-relaxed">
              O aplicativo utiliza apenas as informações básicas públicas autorizadas por você em sua conta Google.
            </p>
          </div>
        </div>
      </div>

      {showTerms && (
        <TermsModal onClose={() => setShowTerms(false)} />
      )}
    </>
  );
};
