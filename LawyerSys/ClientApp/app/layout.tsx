import './globals.css'
import dynamic from 'next/dynamic'

const Providers = dynamic(() => import('../src/providers/Providers'), { ssr: false })
const ServiceWorkerRegister = dynamic(() => import('../src/components/ServiceWorkerRegister'), { ssr: false })

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://qadaya.naqreo.com'
const title = 'قضايا Qadaya | منصة إدارة العمليات القانونية'
const description =
  'مساحة عمل ثنائية اللغة لإدارة القضايا، تنسيق العملاء، وإدارة مكاتب المحاماة. Bilingual legal operations workspace for case management, client coordination, and firm administration.'

export const metadata = {
  metadataBase: new URL(siteUrl),
  title,
  description,
  openGraph: {
    title,
    description,
    url: siteUrl,
    siteName: 'Qadaya',
    images: [
      {
        url: '/icons/icon-512.png',
        width: 512,
        height: 512,
        alt: 'Qadaya',
      },
    ],
    locale: 'ar_EG',
    type: 'website',
  },
  twitter: {
    card: 'summary',
    title,
    description,
    images: ['/icons/icon-512.png'],
  },
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
