import axios from 'axios'

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:5000/api'

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
