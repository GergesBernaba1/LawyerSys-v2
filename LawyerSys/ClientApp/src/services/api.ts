import axios from 'axios'

// support both Vite and Next public env var names
const API_BASE = (typeof process !== 'undefined' && (process.env.NEXT_PUBLIC_API_BASE_URL || process.env.VITE_API_BASE_URL))
  || 'http://localhost:5000/api'

const instance = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' }
})

instance.interceptors.request.use(config => {
  const token = localStorage.getItem('lawyersys-token')
  if (token && config.headers) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default instance
