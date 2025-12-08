import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

const LOCALES = ['en', 'ar']

export function middleware(req: NextRequest) {
  const url = req.nextUrl.clone()
  const pathname = url.pathname

  // allow next internals and assets
  if (pathname.startsWith('/_next') || pathname.startsWith('/api') || pathname.includes('.')) {
    return
  }

  const firstSegment = pathname.split('/')[1]
  if (LOCALES.includes(firstSegment)) {
    // already localized
    return
  }

  // try accept-language header
  const accept = req.headers.get('accept-language') || ''
  const preferred = accept.split(',').map(p => p.split(';')[0].trim())[0] || ''
  const lang = preferred.startsWith('ar') ? 'ar' : 'en'

  url.pathname = `/${lang}${pathname === '/' ? '' : pathname}`
  return NextResponse.redirect(url)
}

export const config = {
  matcher: ['/', '/((?!_next|api|static).*)'],
}
