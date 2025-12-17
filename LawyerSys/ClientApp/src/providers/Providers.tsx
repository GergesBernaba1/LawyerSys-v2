"use client"
import React, { useEffect, useMemo, useState } from 'react'
import { CacheProvider } from '@emotion/react'
import createCache from '@emotion/cache'
import rtlPlugin from 'stylis-plugin-rtl'
import { ThemeProvider, CssBaseline } from '@mui/material'
import getTheme from '../theme'
import Layout from '../components/Layout'
import { AuthProvider } from '../services/auth'
import i18n from '../i18n'

interface ProvidersProps { locale?: string; children: React.ReactNode }

export default function Providers({ locale: initialLocale = 'ar', children }: ProvidersProps) {
  const [locale, setLocale] = useState(i18n.language || initialLocale)

  useEffect(() => {
    const handleLanguageChange = (lng: string) => setLocale(lng)
    i18n.on('languageChanged', handleLanguageChange)
    if (i18n.language && i18n.language !== locale) setLocale(i18n.language)
    return () => { i18n.off('languageChanged', handleLanguageChange) }
  }, [])

  const isRTL = locale.startsWith('ar')
  
  useEffect(() => {
    try { document.documentElement.setAttribute('dir', isRTL ? 'rtl' : 'ltr') } catch {}
  }, [isRTL])

  // Use a stable cache key so SSR and client render match className prefixes
  const cache = useMemo(() => createCache({ key: 'css', stylisPlugins: isRTL ? [rtlPlugin] : [], prepend: true }), [isRTL])
  const theme = useMemo(() => getTheme(isRTL ? 'rtl' : 'ltr'), [isRTL])

  return (
    <CacheProvider value={cache}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <AuthProvider>
          <Layout>
            {children}
          </Layout>
        </AuthProvider>
      </ThemeProvider>
    </CacheProvider>
  )
}
