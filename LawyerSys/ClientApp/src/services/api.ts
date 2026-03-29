import axios from 'axios'
import i18n from '../i18n'

const resolvedApiBase =
  typeof process !== 'undefined'
    ? (
      process.env.NEXT_PUBLIC_API_BASE_URL ||
      process.env.NEXT_PUBLIC_BACKEND_URL ||
      process.env.VITE_API_BASE_URL
    )
    : undefined

if (!resolvedApiBase) {
  throw new Error(
    'Missing API base URL env var. Set NEXT_PUBLIC_API_BASE_URL (or NEXT_PUBLIC_BACKEND_URL / VITE_API_BASE_URL).'
  )
}

const API_BASE = resolvedApiBase

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

export const REALTIME_BASE = API_BASE.replace(/\/api\/?$/, '')

export default instance
