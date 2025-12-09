import axios from 'axios'

// support both Vite and Next public env var names
const API_BASE = (typeof process !== 'undefined' && (process.env.NEXT_PUBLIC_API_BASE_URL || process.env.VITE_API_BASE_URL))
  || 'http://localhost:5000/api'

const instance = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' }
})

instance.interceptors.request.use(config => {
  // guard for server-side rendering — localStorage only available in browser
  const token = (typeof window !== 'undefined') ? localStorage.getItem('lawyersys-token') : null
  if (token && config.headers) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default instance
