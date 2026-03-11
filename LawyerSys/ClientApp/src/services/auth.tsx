import React, { createContext, useState, useContext, useEffect } from 'react'
import api from './api'

interface User {
  email: string;
  fullName: string;
  userName: string;
  token: string;
  roles: string[];
}

interface AuthContextValue {
  token: string | null;
  user: User | null;
  isAuthInitialized: boolean;
  login: (user: string, pass: string) => Promise<boolean>;
  register: (user: string, email: string, pass: string, fullName: string, countryId: number) => Promise<boolean>;
  setAuthToken: (token: string) => void;
  logout: () => void;
  isAuthenticated: boolean;
  hasRole: (role: string) => boolean;
  hasAnyRole: (...roles: string[]) => boolean;
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

function isTokenExpired(token: string): boolean {
  try {
    const decoded = parseJwt(token);
    if (!decoded || !decoded.exp) return true;
    
    // exp is in seconds, Date.now() is in milliseconds
    const currentTime = Math.floor(Date.now() / 1000);
    return decoded.exp < currentTime;
  } catch {
    return true;
  }
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Keep token and init state atomic to avoid transient unauthenticated redirects.
  const [authState, setAuthState] = useState<{ token: string | null; isAuthInitialized: boolean }>({
    token: null,
    isAuthInitialized: false,
  })
  const token = authState.token
  const isAuthInitialized = authState.isAuthInitialized
  useEffect(() => {
    let nextToken: string | null = null
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('lawyersys-token')
      if (saved && !isTokenExpired(saved)) {
        nextToken = saved
      } else if (saved) {
        // Token exists but is expired, remove it
        localStorage.removeItem('lawyersys-token')
      }
    }
    setAuthState({ token: nextToken, isAuthInitialized: true })
  }, [])
  const [user, setUser] = useState<User | null>(null)

  useEffect(() => {
    if (token) {
      const decoded = parseJwt(token);
      console.log('Decoded JWT:', decoded);
      if (decoded) {
        // Extract roles from JWT claims
        // Roles can be in 'role' claim or 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'
        let roles: string[] = [];
        const roleClaim = decoded.role || decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
        if (roleClaim) {
          // Role can be a string or an array
          roles = Array.isArray(roleClaim) ? roleClaim : [roleClaim];
        }

        const userInfo = {
          email: decoded.email || decoded.sub || 'User',
          fullName: decoded.fullName || '',
          userName: decoded.unique_name || decoded.preferred_username || decoded.sub || '',
          roles,
          token,
        };
        console.log('Setting user info:', userInfo);
        setUser(userInfo);
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
        setAuthState((prev) => ({ ...prev, token: t, isAuthInitialized: true }))
        return true
      }
      console.warn('No token in response')
      return false
    } catch (e: any) {
      console.error('Login error:', e.response?.data || e.message)
      return false
    }
  }

  async function register(userName: string, email: string, pass: string, fullName: string, countryId: number) {
    try {
      await api.post('/Account/register', { userName, email, password: pass, fullName, countryId })
      return true
    } catch (e) {
      return false
    }
  }

  function setAuthToken(nextToken: string) {
    localStorage.setItem('lawyersys-token', nextToken)
    setAuthState((prev) => ({ ...prev, token: nextToken, isAuthInitialized: true }))
  }

  function logout() {
    localStorage.removeItem('lawyersys-token')
    setAuthState((prev) => ({ ...prev, token: null, isAuthInitialized: true }))
    setUser(null)
  }

  function hasRole(role: string): boolean {
    return user?.roles?.includes(role) ?? false;
  }

  function hasAnyRole(...roles: string[]): boolean {
    return roles.some(role => user?.roles?.includes(role)) ?? false;
  }

  const isAuthenticated = !!token;

  return (
    <AuthContext.Provider value={{ token, user, isAuthInitialized, login, register, setAuthToken, logout, isAuthenticated, hasRole, hasAnyRole }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
