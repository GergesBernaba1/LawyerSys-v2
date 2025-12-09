import React from 'react'
import type { AppProps } from 'next/app'
import Providers from '../providers/Providers'

export default function MyApp({ Component, pageProps }: AppProps) {
  // pageProps may include locale if provided by app router or custom code — fallback to 'en'
  const locale = (pageProps && (pageProps as any).locale) || 'en'
  return (
    <Providers locale={locale}>
      <Component {...pageProps} />
    </Providers>
  )
}
