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
  const [token, setToken] = useState<string | null>(localStorage.getItem('lawyersys-token'))
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
    try {
      const r = await api.post('/Account/login', { userName, password: pass })
      const t = r.data?.token
      if (t) {
        localStorage.setItem('lawyersys-token', t)
        setToken(t)
        return true
      }
      return false
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
    <AuthContext.Provider value={{ token, user, login, logout, isAuthenticated }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
