'use client'
import React, { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
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
  Link
} from '@mui/material'
import { 
  LockReset as LockResetIcon,
  Person as PersonIcon,
  ArrowBack as ArrowBackIcon
} from '@mui/icons-material'
import api from '../../src/services/api'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../../src/services/auth'

export default function ForgotPasswordPage(){
  const [userName, setUserName] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState<any>(null)
  const router = useRouter()
  const { t } = useTranslation()
  const { isAuthenticated } = useAuth()
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  // Redirect authenticated users away from forgot-password page
  useEffect(() => {
    if (isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSuccess(null)
    setLoading(true)
    try{
      const r = await api.post('/Account/request-password-reset', { userName })
      setSuccess(r.data)
    }catch(e:any){
      setError(e?.response?.data?.message || t('login.errorOccurred') || 'Error')
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
          maxWidth: 450, 
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
          <LockResetIcon sx={{ fontSize: 40, color: 'white' }} />
        </Box>

        <CardContent sx={{ p: { xs: 4, sm: 6 }, pt: 8 }}>
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <Typography variant="h4" fontWeight={800} gutterBottom sx={{ letterSpacing: '-0.02em', color: 'text.primary' }}>
              {t('login.forgotPassword') || 'Forgot Password'}
            </Typography>
            <Typography variant="body1" color="text.secondary" sx={{ fontWeight: 500 }}>
              {t('login.forgotPasswordSubtitle') || 'Enter your username to reset your password.'}
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

          {success && (
            <Alert 
              severity="success" 
              variant="filled"
              sx={{ mb: 3, borderRadius: 3, boxShadow: '0 4px 12px rgba(16, 185, 129, 0.2)' }}
            >
              <Typography variant="body2" fontWeight={600}>
                {t('login.passwordResetRequested') || 'Password reset token issued.'}
              </Typography>
              <Box sx={{ mt: 1.5, p: 1.5, bgcolor: 'rgba(255,255,255,0.2)', borderRadius: 2, wordBreak: 'break-all', fontFamily: 'monospace', fontSize: '0.75rem' }}>
                <strong>Token:</strong> {success.token}
              </Box>
              <Button 
                fullWidth
                size="small" 
                variant="contained" 
                color="inherit"
                onClick={()=>router.push(`/reset-password?userName=${encodeURIComponent(userName)}&token=${encodeURIComponent(success.token)}`)}
                sx={{ mt: 2, color: 'success.main', fontWeight: 700, bgcolor: 'white', '&:hover': { bgcolor: 'rgba(255,255,255,0.9)' } }}
              >
                {t('login.resetPassword') || 'Reset Password Now'}
              </Button>
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit}>
            <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
              {t('login.username')}
            </Typography>
            <TextField
              fullWidth
              placeholder={t('login.usernamePlaceholder') || "Enter your username"}
              value={userName}
              onChange={(e)=>setUserName(e.target.value)}
              required
              autoFocus
              sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <PersonIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                  </InputAdornment>
                ),
              }}
            />

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
              {loading ? <CircularProgress size={24} color="inherit" /> : (t('login.requestReset') || 'Send Reset Link')}
            </Button>

            <Box sx={{ mt: 3, textAlign: 'center' }}>
              <Button 
                onClick={()=>router.push('/login')} 
                variant="text"
                startIcon={isRTL ? null : <ArrowBackIcon />}
                endIcon={isRTL ? <ArrowBackIcon sx={{ transform: 'rotate(180deg)' }} /> : null}
                sx={{ fontWeight: 700, color: 'text.secondary', '&:hover': { color: 'primary.main', bgcolor: 'transparent' } }}
              >
                {t('login.backToSignIn') || t('login.signIn') || 'Back to Sign In'}
              </Button>
            </Box>
          </Box>
        </CardContent>
      </Card>
    </Box>
  )
}
