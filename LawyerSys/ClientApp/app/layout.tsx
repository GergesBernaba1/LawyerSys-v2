import './globals.css'
import Providers from '../src/providers/Providers'

export const metadata = {
  title: 'LawyerSys Client',
  description: 'Next.js front-end for LawyerSys',
}

export default function RootLayout({ children, params }: { children: React.ReactNode; params?: { locale?: string } }) {
  const locale = params?.locale || 'ar'

  return (
    <html lang={locale}>
      <body>
        <Providers locale={locale}>
          {children}
        </Providers>
      </body>
    </html>
  )
}
