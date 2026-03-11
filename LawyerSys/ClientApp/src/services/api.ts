import axios from 'axios'

// support both Vite and Next public env var names
const API_BASE = (typeof process !== 'undefined' && (process.env.NEXT_PUBLIC_API_BASE_URL || process.env.VITE_API_BASE_URL))
  || 'https://localhost:7001/api'

const instance = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' }
})

const inFlightGetRequests = new Map<string, Promise<any>>()
const recentGetResponses = new Map<string, { timestamp: number; response: any }>()
const GET_DEDUPE_WINDOW_MS = 500
const MAX_RECENT_CACHE_SIZE = 100

function getActiveTenantId() {
  if (typeof window === 'undefined') return ''
  return localStorage.getItem('lawyersys-active-tenant-id') || ''
}

function buildGetRequestKey(url: string, config?: any) {
  const uri = instance.getUri({ ...(config || {}), url })
  const tenantHeader =
    config?.headers?.['X-Firm-Id']
    || config?.headers?.['x-firm-id']
    || getActiveTenantId()

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

instance.interceptors.request.use(config => {
  // guard for server-side rendering — localStorage only available in browser
  const token = (typeof window !== 'undefined') ? localStorage.getItem('lawyersys-token') : null
  if (token && config.headers) config.headers.Authorization = `Bearer ${token}`
  const activeTenantId = getActiveTenantId()
  if (activeTenantId && config.headers) config.headers['X-Firm-Id'] = activeTenantId
  return config
})

export default instance
