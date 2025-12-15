"use client"
import React, { useEffect, useMemo, useState } from 'react'
import { CacheProvider } from '@emotion/react'
import createCache from '@emotion/cache'
import rtlPlugin from 'stylis-plugin-rtl'
import dynamic from 'next/dynamic'
import i18n from '../src/i18n'

// create caches inside the client component so no browser APIs run at module-eval time

export default function Page() {
  // detect locale prefix (e.g. /ar/... or /en/...) — default to 'ar'
  const detectLocaleFromPath = () => {
    if (typeof window === 'undefined') return 'ar'
    const m = window.location.pathname.match(/^\/(en|ar)(?:\/|$)/)
    return m ? m[1] : 'ar'
  }

  const [lng, setLng] = useState(() => detectLocaleFromPath() || i18n.language || 'ar')
  const [basename, setBasename] = useState(() => {
    if (typeof window === 'undefined') return ''
    const m = window.location.pathname.match(/^\/(en|ar)(?:\/|$)/)
    return m ? `/${m[1]}` : ''
  })

  useEffect(() => {
    const onChange = (l: string) => setLng(l)
    i18n.on('languageChanged', onChange)
    return () => { i18n.off('languageChanged', onChange) }
  }, [])

  useEffect(() => {
    if (typeof document !== 'undefined') document.documentElement.setAttribute('dir', lng.startsWith('ar') ? 'rtl' : 'ltr')
  }, [lng])

  // keep react-router basename in sync when the pathname prefix changes
  useEffect(() => {
    if (typeof window === 'undefined') return
    const m = window.location.pathname.match(/^\/(en|ar)(?:\/|$)/)
    setBasename(m ? `/${m[1]}` : '')
  }, [])

  const activeCache = useMemo(() => createCache({ key: lng.startsWith('ar') ? 'muirtl' : 'css', stylisPlugins: lng.startsWith('ar') ? [rtlPlugin] : [], prepend: true }), [lng])

  // ensure the SPA bundle (react-router, document usage) is only loaded client-side
  const AppClient = dynamic(() => import('../src/client/App.client'), { ssr: false })

  return (
    <CacheProvider value={activeCache}>
      <AppClient basename={basename} />
    </CacheProvider>
  )
}
