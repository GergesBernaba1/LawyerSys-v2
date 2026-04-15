import './globals.css'
import dynamic from 'next/dynamic'

const Providers = dynamic(() => import('../src/providers/Providers'), { ssr: false })
const ServiceWorkerRegister = dynamic(() => import('../src/components/ServiceWorkerRegister'), { ssr: false })

export const metadata = {
  title: 'قضايا Qadaya | منصة إدارة العمليات القانونية',
  description:
    'مساحة عمل ثنائية اللغة لإدارة القضايا، تنسيق العملاء، وإدارة مكاتب المحاماة. Bilingual legal operations workspace for case management, client coordination, and firm administration.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const locale = 'ar'

  return (
    <html lang={locale} dir={locale.startsWith('ar') ? 'rtl' : 'ltr'} suppressHydrationWarning>
      <head>
        <link rel="manifest" href="/manifest.webmanifest" />
        <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
        <link rel="shortcut icon" href="/favicon.svg" type="image/svg+xml" />
        <link rel="apple-touch-icon" href="/icons/icon-192.png" />
        <meta name="theme-color" content="#14345a" />
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="default" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700;800&family=Poppins:wght@300;400;500;600;700&family=Cairo:wght@400;500;600;700;800&family=Tajawal:wght@400;500;700&display=swap"
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
