import './globals.css'
import Providers from '../src/providers/Providers'

export const metadata = {
  title: 'LawyerSys Client',
  description: 'Next.js front-end for LawyerSys',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const locale = 'ar'

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
