'use client'
import React, { useState, useEffect, Suspense } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'
import { 
  Box, 
  Card, 
  CardContent, 
  TextField, 
  Button, 
  Typography, 
  Alert, 
  Container, 
  InputAdornment,
  CircularProgress,
  useTheme,
  Grid,
  IconButton
} from '@mui/material'
import { 
  Key as KeyIcon,
  Person as PersonIcon,
  VpnKey as TokenIcon,
  Lock as LockIcon,
  Visibility,
  VisibilityOff,
  CheckCircle as CheckCircleIcon
} from '@mui/icons-material'
import api from '../../src/services/api'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../../src/services/auth'

function ResetPasswordForm() {
  const search = useSearchParams()
  const safeSearch = (search && typeof (search as any).get === 'function') ? search : null
  const initialToken = safeSearch ? (safeSearch.get('token') || '') : ''
  const initialUser = safeSearch ? (safeSearch.get('userName') || '') : ''
  const [userName, setUserName] = useState(initialUser)
  const [token, setToken] = useState(initialToken)
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)

  const router = useRouter()
  const { t } = useTranslation()
  const theme = useTheme()
  const isRTL = theme.direction === 'rtl'

  useEffect(()=>{
    if (initialToken) setToken(initialToken)
    if (initialUser) setUserName(initialUser)
  }, [initialToken, initialUser])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (password !== confirm) { setError(t('register.passwordMismatch') || 'Passwords do not match'); return }
    setLoading(true)
    
    try{
      await api.post('/Account/reset-password', { userName, token, newPassword: password })
      setSuccess(true)
    }catch(e:any){
      const errorMsg = e?.response?.data?.message 
        || (e?.response?.data?.errors ? JSON.stringify(e.response.data.errors) : '')
        || e?.message 
        || t('login.errorOccurred') 
        || 'Error'
      setError(errorMsg)
    }finally{ setLoading(false) }
  }

  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
        p: 2,
        position: 'relative',
        overflow: 'hidden',
        '&::before': {
          content: '""',
          position: 'absolute',
          width: '140%',
          height: '140%',
          top: '-20%',
          left: '-20%',
          background: 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 70%)',
          animation: 'pulse 15s infinite alternate',
        },
        '@keyframes pulse': {
          '0%': { transform: 'scale(1) translate(0, 0)' },
          '100%': { transform: 'scale(1.1) translate(2%, 2%)' },
        }
      }}
    >
      <Card 
        elevation={0}
        sx={{ 
          maxWidth: 500, 
          width: '100%', 
          borderRadius: 6,
          bgcolor: 'rgba(255, 255, 255, 0.9)',
          backdropFilter: 'blur(20px)',
          border: '1px solid rgba(255, 255, 255, 0.3)',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
          overflow: 'visible',
          position: 'relative',
          zIndex: 1,
        }}
      >
        <Box
          sx={{
            position: 'absolute',
            top: -40,
            left: '50%',
            transform: 'translateX(-50%)',
            width: 80,
            height: 80,
            borderRadius: 4,
            bgcolor: 'primary.main',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 10px 25px -5px rgba(99, 102, 241, 0.5)',
            background: 'linear-gradient(135deg, #6366f1 0%, #818cf8 100%)',
            zIndex: 2,
          }}
        >
          {success ? <CheckCircleIcon sx={{ fontSize: 40, color: 'white' }} /> : <KeyIcon sx={{ fontSize: 40, color: 'white' }} />}
        </Box>

        <CardContent sx={{ p: { xs: 4, sm: 6 }, pt: 8 }}>
          {success ? (
            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="h4" fontWeight={800} gutterBottom sx={{ letterSpacing: '-0.02em', color: 'text.primary' }}>
                {t('login.passwordResetSuccess') || 'Success!'}
              </Typography>
              <Typography variant="body1" color="text.secondary" sx={{ mb: 4, fontWeight: 500 }}>
                {t('login.passwordResetSuccessSubtitle') || 'Your password has been updated successfully.'}
              </Typography>
              <Button 
                fullWidth 
                variant="contained" 
                size="large"
                onClick={()=>router.push('/login')}
                sx={{ 
                  py: 2,
                  borderRadius: 3,
                  fontWeight: 700,
                  background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
                }}
              >
                {t('login.signIn') || 'Sign In Now'}
              </Button>
            </Box>
          ) : (
            <>
              <Box sx={{ textAlign: 'center', mb: 4 }}>
                <Typography variant="h4" fontWeight={800} gutterBottom sx={{ letterSpacing: '-0.02em', color: 'text.primary' }}>
                  {t('login.resetPassword') || 'Reset Password'}
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ fontWeight: 500 }}>
                  {t('login.resetPasswordSubtitle') || 'Create a new secure password for your account.'}
                </Typography>
              </Box>

              {error && (
                <Alert 
                  severity="error" 
                  variant="filled"
                  sx={{ mb: 3, borderRadius: 3, boxShadow: '0 4px 12px rgba(239, 68, 68, 0.2)' }}
                >
                  {error}
                </Alert>
              )}

              <Box component="form" onSubmit={handleSubmit}>
                <Grid container spacing={2.5}>
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                      {t('login.username')}
                    </Typography>
                    <TextField 
                      fullWidth 
                      placeholder={t('login.usernamePlaceholder') || "Username"}
                      value={userName} 
                      onChange={(e)=>setUserName(e.target.value)} 
                      required
                      sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start">
                            <PersonIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                          </InputAdornment>
                        ),
                      }}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                      {t('login.resetToken')}
                    </Typography>
                    <TextField 
                      fullWidth 
                      placeholder={t('login.tokenPlaceholder') || "Enter reset token"}
                      value={token} 
                      onChange={(e)=>setToken(e.target.value)} 
                      required
                      sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start">
                            <TokenIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                          </InputAdornment>
                        ),
                      }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                      {t('register.password')}
                    </Typography>
                    <TextField 
                      fullWidth 
                      type={showPassword ? 'text' : 'password'}
                      placeholder="••••••••"
                      value={password} 
                      onChange={(e)=>setPassword(e.target.value)} 
                      required
                      sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start">
                            <LockIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                          </InputAdornment>
                        ),
                      }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                      {t('register.confirmPassword')}
                    </Typography>
                    <TextField 
                      fullWidth 
                      type={showPassword ? 'text' : 'password'}
                      placeholder="••••••••"
                      value={confirm} 
                      onChange={(e)=>setConfirm(e.target.value)} 
                      required
                      sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
                      InputProps={{
                        startAdornment: (
                          <InputAdornment position="start">
                            <LockIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                          </InputAdornment>
                        ),
                        endAdornment: (
                          <InputAdornment position="end">
                            <IconButton onClick={() => setShowPassword(!showPassword)} edge="end" size="small">
                              {showPassword ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                            </IconButton>
                          </InputAdornment>
                        ),
                      }}
                    />
                  </Grid>
                </Grid>

                <Button 
                  type="submit" 
                  fullWidth 
                  variant="contained" 
                  size="large"
                  disabled={loading}
                  sx={{ 
                    mt: 4, 
                    py: 2,
                    borderRadius: 3,
                    fontSize: '1rem',
                    fontWeight: 700,
                    textTransform: 'none',
                    background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
                    boxShadow: '0 10px 20px -5px rgba(99, 102, 241, 0.4)',
                    '&:hover': {
                      boxShadow: '0 15px 25px -5px rgba(99, 102, 241, 0.5)',
                      transform: 'translateY(-1px)',
                    },
                    transition: 'all 0.2s ease-in-out',
                  }}
                >
                  {loading ? <CircularProgress size={24} color="inherit" /> : (t('login.resetPassword') || 'Update Password')}
                </Button>
              </Box>
            </>
          )}
        </CardContent>
      </Card>
    </Box>
  )
}

export default function ResetPasswordPage() {
  return (
    <Suspense fallback={
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)' }}>
        <CircularProgress sx={{ color: 'white' }} />
      </Box>
    }>
      <ResetPasswordForm />
    </Suspense>
  )
}


