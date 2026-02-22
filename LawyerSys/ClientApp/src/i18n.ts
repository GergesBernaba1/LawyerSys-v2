import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

import en from './locales/en/translation.json'
import ar from './locales/ar/translation.json'

const resources = {
  en: { translation: en },
  ar: { translation: ar }
}

const initOptions: any = {
  resources,
  lng: 'ar',
  fallbackLng: 'ar',
  debug: false,
  interpolation: { escapeValue: false },
  detection: {
    order: ['localStorage', 'navigator', 'htmlTag', 'path', 'subdomain'],
    caches: ['localStorage']
  }
}

// Initialize differently for server vs client. LanguageDetector uses browser-only APIs.
if (!i18n.isInitialized) {
  if (typeof window !== 'undefined') {
    i18n.use(initReactI18next).use(LanguageDetector).init(initOptions)
  } else {
    // server-only: do not use LanguageDetector (avoids localStorage access during SSR)
    const serverOptions = { ...initOptions }
    delete serverOptions.detection
    i18n.use(initReactI18next).init(serverOptions)
  }
}

export default i18n
