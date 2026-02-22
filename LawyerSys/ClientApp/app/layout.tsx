import './globals.css'
import dynamic from 'next/dynamic'

const Providers = dynamic(() => import('../src/providers/Providers'), { ssr: false })
const ServiceWorkerRegister = dynamic(() => import('../src/components/ServiceWorkerRegister'), { ssr: false })

export const metadata = {
  title: 'Qadaya - قضايا',
  description: 'Lawyer Management System - نظام إدارة المحاماة',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const locale = 'ar'

  return (
    <html lang={locale} dir={locale.startsWith('ar') ? 'rtl' : 'ltr'} suppressHydrationWarning>
      <head>
        <link rel="manifest" href="/manifest.webmanifest" />
        <meta name="theme-color" content="#4f46e5" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body suppressHydrationWarning>
        <Providers locale={locale}>
          <ServiceWorkerRegister />
          {children}
        </Providers>
      </body>
    </html>
  )
}
