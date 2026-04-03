import React, { createContext, useState, useContext, useEffect } from 'react'
import api, { clearApiGetCache } from './api'

interface User {
  id: string;
  email: string;
  fullName: string;
  userName: string;
  token: string;
  roles: string[];
  tenantId: number | null;
  tenantName: string;
  countryId: number | null;
  countryName: string;
}

interface AuthContextValue {
  token: string | null;
  user: User | null;
  isAuthInitialized: boolean;
  login: (user: string, pass: string) => Promise<{ success: boolean; message?: string }>;
  register: (
    user: string,
    email: string,
    pass: string,
    fullName: string,
    countryId: number,
    lawyerOfficeName: string,
    lawyerOfficePhoneNumber: string,
    subscriptionPackageId: number
  ) => Promise<{ success: boolean; message?: string }>;
  setAuthToken: (token: string) => void;
  logout: () => void;
  isAuthenticated: boolean;
  hasRole: (role: string) => boolean;
  hasAnyRole: (...roles: string[]) => boolean;
  syncUserProfile: (profile: Partial<Pick<User, 'countryId' | 'countryName' | 'tenantId' | 'tenantName'>>) => void;
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
    let cancelled = false;

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
          id: decoded["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"] || decoded.nameid || decoded.sub || "",
          email: decoded.email || decoded.sub || 'User',
          fullName: decoded.fullName || '',
          userName: decoded.unique_name || decoded.preferred_username || decoded.sub || '',
          roles,
          tenantId: Number(decoded.tenant_id || decoded.firm_id || 0) || null,
          tenantName: decoded.tenant_name || '',
          countryId: Number(decoded.country_id || 0) || null,
          countryName: decoded.country_name || '',
          token,
        };
        console.log('Setting user info:', userInfo);
        setUser(userInfo);

        if (typeof window !== 'undefined' && userInfo.tenantId) {
          const savedTenantId = localStorage.getItem('lawyersys-active-tenant-id')
          if (!savedTenantId) {
            localStorage.setItem('lawyersys-active-tenant-id', String(userInfo.tenantId))
            clearApiGetCache()
          }
        }

        void api.get('/Account/me')
          .then((response) => {
            if (cancelled) return;

            setUser((current) => {
              if (!current) return current;

              return {
                ...current,
                tenantId: Number(response.data?.tenantId || 0) || current.tenantId,
                tenantName: response.data?.tenantName || current.tenantName,
                countryId: Number(response.data?.countryId || 0) || current.countryId,
                countryName: response.data?.countryName || current.countryName,
              };
            });
          })
          .catch(() => {
            // Keep JWT-derived identity if profile hydration fails.
          });
      }
    } else {
      setUser(null);
    }

    return () => {
      cancelled = true;
    };
  }, [token]);

  async function login(userName: string, pass: string) {
    console.log('Login attempt:', { userName, passwordLength: pass.length })
    try {
      const r = await api.post('/Account/login', { userName, password: pass })
      console.log('Login response:', r.data)
      const t = r.data?.token
      if (t) {
        localStorage.setItem('lawyersys-token', t)
        localStorage.removeItem('lawyersys-active-tenant-id')
        clearApiGetCache()
        setAuthState((prev) => ({ ...prev, token: t, isAuthInitialized: true }))
        return { success: true }
      }
      console.warn('No token in response')
      return { success: false }
    } catch (e: any) {
      console.error('Login error:', e.response?.data || e.message)
      return {
        success: false,
        message: e?.response?.data?.message,
      }
    }
  }

  async function register(
    userName: string,
    email: string,
    pass: string,
    fullName: string,
    countryId: number,
    lawyerOfficeName: string,
    lawyerOfficePhoneNumber: string,
    subscriptionPackageId: number
  ) {
    try {
      const response = await api.post('/Account/register', {
        userName,
        email,
        password: pass,
        fullName,
        countryId,
        lawyerOfficeName,
        lawyerOfficePhoneNumber,
        subscriptionPackageId,
      })
      return {
        success: true,
        message: response.data?.message,
      }
    } catch (e: any) {
      return {
        success: false,
        message: e?.response?.data?.message,
      }
    }
  }

  function setAuthToken(nextToken: string) {
    localStorage.setItem('lawyersys-token', nextToken)
    clearApiGetCache()
    setAuthState((prev) => ({ ...prev, token: nextToken, isAuthInitialized: true }))
  }

  function logout() {
    localStorage.removeItem('lawyersys-token')
    localStorage.removeItem('lawyersys-active-tenant-id')
    clearApiGetCache()
    setAuthState((prev) => ({ ...prev, token: null, isAuthInitialized: true }))
    setUser(null)
  }

  function hasRole(role: string): boolean {
    return user?.roles?.includes(role) ?? false;
  }

  function hasAnyRole(...roles: string[]): boolean {
    return roles.some(role => user?.roles?.includes(role)) ?? false;
  }

  function syncUserProfile(profile: Partial<Pick<User, 'countryId' | 'countryName' | 'tenantId' | 'tenantName'>>) {
    setUser((current) => {
      if (!current) return current;
      return {
        ...current,
        countryId: profile.countryId ?? current.countryId,
        countryName: profile.countryName ?? current.countryName,
        tenantId: profile.tenantId ?? current.tenantId,
        tenantName: profile.tenantName ?? current.tenantName,
      };
    });
  }

  const isAuthenticated = !!token;

  return (
    <AuthContext.Provider value={{ token, user, isAuthInitialized, login, register, setAuthToken, logout, isAuthenticated, hasRole, hasAnyRole, syncUserProfile }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
