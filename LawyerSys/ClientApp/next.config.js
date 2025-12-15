/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: ['localhost', process.env.NEXT_PUBLIC_BACKEND_HOST || 'localhost'],
  },
  i18n: {
    locales: ['ar', 'en'],
    defaultLocale: 'ar',
    localeDetection: false,
  },
}

module.exports = nextConfig