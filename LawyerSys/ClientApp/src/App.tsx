import React, { useEffect, useState } from 'react'
import { ThemeProvider, CssBaseline } from '@mui/material'
import getTheme from './theme'
import i18n from './i18n'
import Dashboard from './client/Dashboard.client'
import { AuthProvider } from './services/auth'

export default function App() {
  const [lng, setLng] = useState(i18n.language || 'ar')
  
  useEffect(() => {
    const onChange = (l:string) => {
      setLng(l)
      const dir = l.startsWith('ar') ? 'rtl' : 'ltr'
      document.documentElement.dir = dir
      document.body.dir = dir
    }
    i18n.on('languageChanged', onChange)
    // Set initial direction
    const initialDir = lng.startsWith('ar') ? 'rtl' : 'ltr'
    document.documentElement.dir = initialDir
    document.body.dir = initialDir
    return () => { i18n.off('languageChanged', onChange) }
  }, [lng])

  const theme = getTheme(lng.startsWith('ar') ? 'rtl' : 'ltr')

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <Dashboard />
      </AuthProvider>
    </ThemeProvider>
  )
}
