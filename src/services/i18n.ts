/**
 * Internationalization (i18n) Service
 * Uses Android-native R.string resource architecture
 */
import { StringResources, AppLocale, R } from '../res/strings';

export type AppLanguage = AppLocale;

class I18nService {
  private currentLanguage: AppLanguage;
  private listeners: Array<(lang: AppLanguage) => void> = [];

  constructor() {
    this.currentLanguage = this.detectInitialLanguage();
  }

  /**
   * Detect language from Android device system / Google account browser locale
   */
  private detectInitialLanguage(): AppLanguage {
    if (typeof window === 'undefined') return 'pt';

    const saved = localStorage.getItem('logiflow_language') as AppLanguage | null;
    if (saved && ['pt', 'en', 'es'].includes(saved)) {
      return saved;
    }

    // Android Webview & Chrome expose navigator.languages[0] and navigator.language
    const languages = (navigator.languages && navigator.languages.length > 0)
      ? navigator.languages
      : [navigator.language || (navigator as any).userLanguage || 'pt'];

    for (const lang of languages) {
      const lower = (lang || '').toLowerCase();
      if (lower.startsWith('en')) return 'en';
      if (lower.startsWith('es')) return 'es';
      if (lower.startsWith('pt')) return 'pt';
    }

    return 'pt';
  }

  public getLanguage(): AppLanguage {
    return this.currentLanguage;
  }

  public setLanguage(lang: AppLanguage) {
    this.currentLanguage = lang;
    try {
      localStorage.setItem('logiflow_language', lang);
    } catch (_) {}
    this.notify();
  }

  /**
   * Returns localized string using Android-like R.string key
   */
  public t(key: keyof typeof StringResources['pt']): string {
    return R.string(key, this.currentLanguage);
  }

  public subscribe(listener: (lang: AppLanguage) => void): () => void {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  private notify() {
    this.listeners.forEach((l) => l(this.currentLanguage));
  }
}

export const i18n = new I18nService();
