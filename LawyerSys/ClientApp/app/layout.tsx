import './globals.css'
import Providers from '../src/providers/Providers'

export const metadata = {
  title: 'Qadaya - قضايا',
  description: 'Lawyer Management System - نظام إدارة المحاماة',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const locale = 'ar'

  return (
    <html lang={locale} dir={locale.startsWith('ar') ? 'rtl' : 'ltr'}>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <Providers locale={locale}>
          {children}
        </Providers>
      </body>
    </html>
  )
}
