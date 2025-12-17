"use client"
import React, { useEffect, useMemo, useState } from 'react'
import { CacheProvider } from '@emotion/react'
import createCache from '@emotion/cache'
import rtlPlugin from 'stylis-plugin-rtl'
import dynamic from 'next/dynamic'
import i18n from '../../src/i18n'

const AppClient = dynamic(() => import('../../src/client/App.client'), { ssr: false })

export default function CatchAll() {
  const [lng, setLng] = useState(i18n.language || 'ar')
  const basename = ''

  useEffect(() => {
    const onChange = (l: string) => setLng(l)
    i18n.on('languageChanged', onChange)
    return () => { i18n.off('languageChanged', onChange) }
  }, [])

  // For quick local testing: allow forcing a language via `?lang=ar|en` query param
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const url = new URL(window.location.href)
      const q = url.searchParams.get('lang')
      if (q && (q === 'ar' || q === 'en')) {
        i18n.changeLanguage(q)
      }
    }
  }, [])

  useEffect(() => {
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('dir', lng.startsWith('ar') ? 'rtl' : 'ltr')
    }
  }, [lng])

  const activeCache = useMemo(() => {
    // stylis-plugin-rtl ships as CommonJS; normalize default export to a function
    // so it works both in dev (ESM interop) and prod (CJS).
    const plugin: any = (rtlPlugin && (rtlPlugin as any).default) ? (rtlPlugin as any).default : rtlPlugin
    return createCache({
      // keep the key stable so server and client class names match
      key: 'css',
      stylisPlugins: lng.startsWith('ar') ? [plugin] : [],
      prepend: true,
    })
  }, [lng])

  return (
    <CacheProvider value={activeCache}>
      <AppClient basename={basename} />
    </CacheProvider>
  )
}
