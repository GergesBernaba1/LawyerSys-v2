'use client'
import React, { Suspense, useEffect, useState } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  IconButton,
  InputAdornment,
  Stack,
  TextField,
  Typography,
  useTheme,
} from '@mui/material'
import {
  Key as KeyIcon,
  Person as PersonIcon,
  VpnKey as TokenIcon,
  Lock as LockIcon,
  Visibility,
  VisibilityOff,
  CheckCircle as CheckCircleIcon,
  ShieldOutlined,
  TaskAltOutlined,
} from '@mui/icons-material'
import api from '../../src/services/api'
import { useTranslation } from 'react-i18next'
import AuthSplitLayout from '../../src/components/auth/AuthSplitLayout'

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
  const { t, i18n } = useTranslation()
  const theme = useTheme()
  const isRTL = theme.direction === 'rtl' || (i18n.resolvedLanguage || i18n.language || '').startsWith('ar')
  const fieldSx = isRTL ? { '& .MuiInputBase-input': { textAlign: 'right' } } : {}

  useEffect(()=>{
    if (initialToken) setToken(initialToken)
    if (initialUser) setUserName(initialUser)
  }, [initialToken, initialUser])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (password !== confirm) {
      setError(t('register.passwordMismatch') || 'Passwords do not match')
      return
    }
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
    <AuthSplitLayout
      badge={isRTL ? 'تحديث كلمة المرور' : 'PASSWORD UPDATE'}
      title={isRTL ? 'تعيين كلمة مرور جديدة مع نفس الضوابط الحالية' : 'Set a new password through the existing secure reset flow'}
      subtitle={
        isRTL
          ? 'تحافظ الشاشة على نفس المدخلات المطلوبة وتعرض النجاح أو الخطأ بشكل أوضح، دون تغيير في عقد الاسترداد.'
          : 'This screen keeps the same required inputs and reset contract while making success and error states easier to understand.'
      }
      formTitle={t('login.resetPassword') || 'Reset Password'}
      formSubtitle={isRTL ? 'أدخل اسم المستخدم والرمز وكلمة المرور الجديدة' : 'Enter your username, reset token, and new password'}
      heroIcon={<KeyIcon />}
      formIcon={success ? <CheckCircleIcon /> : <LockIcon />}
      footerLinkHref="/login"
      footerLinkLabel={t('login.signIn') || 'Sign In'}
      features={[
        {
          icon: <ShieldOutlined fontSize="small" />,
          text: isRTL ? 'يعرض الأخطاء القابلة للتصحيح بوضوح ويُبقي التدفق كما هو' : 'Shows recoverable errors clearly while preserving the same flow',
        },
        {
          icon: <TaskAltOutlined fontSize="small" />,
          text: isRTL ? 'يوجه المستخدم بوضوح إلى الخطوة التالية بعد النجاح' : 'Makes the post-success next step obvious',
        },
      ]}
    >
      {success ? (
        <Stack spacing={2}>
          <Alert severity="success" sx={{ borderRadius: 3 }}>
            {t('login.passwordResetSuccess') || 'Password updated successfully'}
          </Alert>
          <Typography variant="body2" color="text.secondary" sx={{ lineHeight: 1.8 }}>
            {isRTL
              ? 'تم تحديث كلمة المرور بنجاح. يمكنك الآن العودة إلى شاشة تسجيل الدخول.'
              : 'Your password has been updated successfully. You can now return to the sign-in screen.'}
          </Typography>
          <Button fullWidth variant="contained" sx={{ py: 1.35, borderRadius: 3, fontWeight: 800 }} onClick={()=>router.push('/login')}>
            {t('login.signIn') || 'Sign In Now'}
          </Button>
        </Stack>
      ) : (
        <Box component="form" onSubmit={handleSubmit}>
          <Stack spacing={2}>
            {error ? (
              <Alert severity="error" sx={{ borderRadius: 3 }}>
                {error}
              </Alert>
            ) : null}
            <TextField fullWidth label={t('login.username')} value={userName} onChange={(e)=>setUserName(e.target.value)} required sx={fieldSx}
              InputProps={{ startAdornment: <InputAdornment position="start"><PersonIcon sx={{ color: 'primary.main' }} /></InputAdornment> }} />
            <TextField fullWidth label={t('login.resetToken')} value={token} onChange={(e)=>setToken(e.target.value)} required sx={fieldSx}
              InputProps={{ startAdornment: <InputAdornment position="start"><TokenIcon sx={{ color: 'primary.main' }} /></InputAdornment> }} />
            <TextField
              fullWidth
              type={showPassword ? 'text' : 'password'}
              label={t('register.password')}
              value={password}
              onChange={(e)=>setPassword(e.target.value)}
              required
              sx={fieldSx}
              InputProps={{
                startAdornment: <InputAdornment position="start"><LockIcon sx={{ color: 'primary.main' }} /></InputAdornment>,
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={() => setShowPassword(!showPassword)} edge="end" size="small">
                      {showPassword ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
            <TextField
              fullWidth
              type={showPassword ? 'text' : 'password'}
              label={t('register.confirmPassword')}
              value={confirm}
              onChange={(e)=>setConfirm(e.target.value)}
              required
              sx={fieldSx}
              InputProps={{ startAdornment: <InputAdornment position="start"><LockIcon sx={{ color: 'primary.main' }} /></InputAdornment> }}
            />
            <Button type="submit" fullWidth variant="contained" size="large" disabled={loading} sx={{ py: 1.35, borderRadius: 3, fontWeight: 800 }}>
              {loading ? <CircularProgress size={24} color="inherit" /> : (t('login.resetPassword') || 'Update Password')}
            </Button>
          </Stack>
        </Box>
      )}
    </AuthSplitLayout>
  )
}

export default function ResetPasswordPage() {
  return (
    <Suspense fallback={
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', background: 'linear-gradient(135deg, #081320 0%, #14345a 100%)' }}>
        <CircularProgress sx={{ color: 'white' }} />
      </Box>
    }>
      <ResetPasswordForm />
    </Suspense>
  )
}
