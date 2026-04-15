import axios from 'axios'
import i18n from '../i18n'

const envApiBase =
  typeof process !== 'undefined'
    ? (
      process.env.NEXT_PUBLIC_API_BASE_URL ||
      process.env.NEXT_PUBLIC_BACKEND_URL ||
      process.env.VITE_API_BASE_URL ||
      (process.env.NEXT_PUBLIC_BACKEND_HOST ? `http://${process.env.NEXT_PUBLIC_BACKEND_HOST}/api` : undefined)
    )
    : undefined

let fallbackApiBase: string

if (typeof window !== 'undefined') {
  const { origin, hostname, protocol, port } = window.location
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    // Respect the protocol of the current page to avoid mixed-content blocks.
    // If served over HTTPS (e.g. https://localhost:7001), use HTTPS for the API too.
    if (protocol === 'https:') {
      // When the .NET backend serves the app on port 7001 over HTTPS, the API is on the same origin
      const apiPort = port === '7001' ? '7001' : '5001'
      fallbackApiBase = `https://localhost:${apiPort}/api`
    } else {
      // Plain HTTP dev server (Next.js on 3002 → backend on 5000)
      fallbackApiBase = 'http://localhost:5000/api'
    }
  } else {
    fallbackApiBase = `${origin}/api`
  }
} else {
  fallbackApiBase = 'http://localhost:5000/api'
}

const API_BASE = envApiBase || fallbackApiBase

if (!envApiBase) {
  console.warn(
    'API base URL env var missing; using fallback:',
    API_BASE,
    'Set NEXT_PUBLIC_API_BASE_URL (or NEXT_PUBLIC_BACKEND_URL / VITE_API_BASE_URL) to silence this warning.'
  )
}

const instance = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' },
})

const inFlightGetRequests = new Map<string, Promise<any>>()
const recentGetResponses = new Map<string, { timestamp: number; response: any }>()
const GET_DEDUPE_WINDOW_MS = 500
const MAX_RECENT_CACHE_SIZE = 100

function getActiveTenantId() {
  if (typeof window === 'undefined') return ''
  return localStorage.getItem('lawyersys-active-tenant-id') || ''
}

function shouldSkipTenantHeader(config?: any) {
  return Boolean(config?.skipTenantHeader)
}

function buildGetRequestKey(url: string, config?: any) {
  const uri = instance.getUri({ ...(config || {}), url })
  const tenantHeader = shouldSkipTenantHeader(config)
    ? ''
    : (
      config?.headers?.['X-Firm-Id'] ||
      config?.headers?.['x-firm-id'] ||
      getActiveTenantId()
    )

  return `${uri}::tenant=${tenantHeader || ''}`
}

function cleanupRecentCache(now: number) {
  if (recentGetResponses.size <= MAX_RECENT_CACHE_SIZE) return

  recentGetResponses.forEach((value, key) => {
    if (now - value.timestamp > GET_DEDUPE_WINDOW_MS) {
      recentGetResponses.delete(key)
    }
  })
}

const rawGet = instance.get.bind(instance)

instance.get = ((url, config) => {
  const key = buildGetRequestKey(url, config)
  const now = Date.now()
  const recent = recentGetResponses.get(key)

  if (recent && now - recent.timestamp <= GET_DEDUPE_WINDOW_MS) {
    return Promise.resolve(recent.response)
  }

  const inFlight = inFlightGetRequests.get(key)
  if (inFlight) {
    return inFlight
  }

  const requestPromise = rawGet(url, config)
    .then((response) => {
      const timestamp = Date.now()
      recentGetResponses.set(key, { timestamp, response })
      cleanupRecentCache(timestamp)
      return response
    })
    .finally(() => {
      inFlightGetRequests.delete(key)
    })

  inFlightGetRequests.set(key, requestPromise)
  return requestPromise
}) as typeof instance.get

export function clearApiGetCache() {
  inFlightGetRequests.clear()
  recentGetResponses.clear()
}

instance.interceptors.request.use((config) => {
  const token = typeof window !== 'undefined' ? localStorage.getItem('lawyersys-token') : null
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`
  }

  if (shouldSkipTenantHeader(config)) {
    if (config.headers) {
      delete config.headers['X-Firm-Id']
      delete config.headers['x-firm-id']
    }
    return config
  }

  const activeTenantId = getActiveTenantId()
  if (activeTenantId && config.headers) {
    config.headers['X-Firm-Id'] = activeTenantId
  }

  if (config.headers) {
    const language = (i18n.resolvedLanguage || i18n.language || 'en').startsWith('ar') ? 'ar-SA' : 'en-US'
    config.headers['Accept-Language'] = language
  }

  return config
})

instance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 || error.response?.status === 403) {
      console.error('Access denied:', error.response?.status, error.response?.data)
    }
    return Promise.reject(error)
  }
)

export const REALTIME_BASE = API_BASE.replace(/\/api\/?$/, '')
export const PARITY_API_ROUTES = {
  capabilities: '/parity/capabilities',
  roadmapItems: '/parity/roadmap-items',
  refresh: '/parity/refresh',
} as const

export default instance
