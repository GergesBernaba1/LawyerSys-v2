import React, { useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
import './index.css'
import i18n from './i18n'
import { CacheProvider } from '@emotion/react'
import createCache from '@emotion/cache'
import rtlPlugin from 'stylis-plugin-rtl'

const cacheLtr = createCache({ key: 'css', prepend: true })
const cacheRtl = createCache({ key: 'muirtl', stylisPlugins: [rtlPlugin], prepend: true })

function Root() {
  const [lng, setLng] = useState(i18n.language || 'en')

  useEffect(() => {
    const onChange = (l: string) => setLng(l)
    i18n.on('languageChanged', onChange)
    return () => { i18n.off('languageChanged', onChange) }
  }, [])

  useEffect(() => {
    document.documentElement.setAttribute('dir', lng.startsWith('ar') ? 'rtl' : 'ltr')
  }, [lng])

  const activeCache = lng.startsWith('ar') ? cacheRtl : cacheLtr

  return (
    <React.StrictMode>
      <CacheProvider value={activeCache}>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </CacheProvider>
    </React.StrictMode>
  )
}

createRoot(document.getElementById('root')!).render(<Root />)
