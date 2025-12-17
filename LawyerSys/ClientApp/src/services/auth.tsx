import React, { createContext, useState, useContext, useEffect } from 'react'
import api from './api'

interface User {
  email: string;
  token: string;
}

interface AuthContextValue {
  token: string | null;
  user: User | null;
  login: (user: string, pass: string) => Promise<boolean>;
  register: (user: string, email: string, pass: string) => Promise<boolean>;
  logout: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

function parseJwt(token: string): any {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // avoid reading localStorage during SSR — initialize on client
  const [token, setToken] = useState<string | null>(null)
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('lawyersys-token')
      if (saved) setToken(saved)
    }
  }, [])
  const [user, setUser] = useState<User | null>(null)

  useEffect(() => {
    if (token) {
      const decoded = parseJwt(token);
      if (decoded) {
        setUser({
          email: decoded.email || decoded.sub || 'User',
          token,
        });
      }
    } else {
      setUser(null);
    }
  }, [token]);

  async function login(userName: string, pass: string) {
    console.log('Login attempt:', { userName, passwordLength: pass.length })
    try {
      const r = await api.post('/Account/login', { userName, password: pass })
      console.log('Login response:', r.data)
      const t = r.data?.token
      if (t) {
        localStorage.setItem('lawyersys-token', t)
        setToken(t)
        return true
      }
      console.warn('No token in response')
      return false
    } catch (e: any) {
      console.error('Login error:', e.response?.data || e.message)
      return false
    }
  }

  async function register(userName: string, email: string, pass: string) {
    try {
      await api.post('/Account/register', { userName, email, password: pass })
      return true
    } catch (e) {
      return false
    }
  }

  function logout() {
    localStorage.removeItem('lawyersys-token')
    setToken(null)
    setUser(null)
  }

  const isAuthenticated = !!token;

  return (
    <AuthContext.Provider value={{ token, user, login, register, logout, isAuthenticated }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
