import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'

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
  interpolation: { escapeValue: false }
}

// Use a deterministic initial language for both SSR and first client render.
if (!i18n.isInitialized) {
  i18n.use(initReactI18next).init(initOptions)
}

export default i18n
