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

  useEffect(() => {
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('dir', lng.startsWith('ar') ? 'rtl' : 'ltr')
    }
  }, [lng])

  const activeCache = useMemo(
    () =>
      createCache({
        key: lng.startsWith('ar') ? 'muirtl' : 'css',
        stylisPlugins: lng.startsWith('ar') ? [rtlPlugin] : [],
        prepend: true,
      }),
    [lng]
  )

  return (
    <CacheProvider value={activeCache}>
      <AppClient basename={basename} />
    </CacheProvider>
  )
}
