"use client"
import React, { useEffect, useMemo } from 'react'
import { CacheProvider } from '@emotion/react'
import createCache from '@emotion/cache'
import rtlPlugin from 'stylis-plugin-rtl'
import { ThemeProvider, CssBaseline } from '@mui/material'
import getTheme from '../theme'
import { AuthProvider } from '../services/auth'
import i18n from '../i18n'

interface ProvidersProps { locale?: string; children: React.ReactNode }

export default function Providers({ locale = 'en', children }: ProvidersProps) {
  const isRTL = locale.startsWith('ar')
  const cache = useMemo(() => createCache({ key: isRTL ? 'muirtl' : 'css', stylisPlugins: isRTL ? [rtlPlugin] : [], prepend: true }), [isRTL])

  useEffect(() => {
    try { document.documentElement.setAttribute('dir', isRTL ? 'rtl' : 'ltr') } catch {}
    if (i18n.language !== locale) i18n.changeLanguage(locale)
  }, [isRTL, locale])

  const theme = useMemo(() => getTheme(isRTL ? 'rtl' : 'ltr'), [isRTL])

  return (
    <CacheProvider value={cache}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <AuthProvider>
          {children}
        </AuthProvider>
      </ThemeProvider>
    </CacheProvider>
  )
}
