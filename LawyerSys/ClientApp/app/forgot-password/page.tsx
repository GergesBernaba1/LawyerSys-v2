'use client'
import React, { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Stack,
  TextField,
  Typography,
  useTheme,
} from '@mui/material'
import {
  LockReset as LockResetIcon,
  Person as PersonIcon,
  ShieldOutlined,
  MarkEmailReadOutlined,
} from '@mui/icons-material'
import api from '../../src/services/api'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../../src/services/auth'
import AuthSplitLayout from '../../src/components/auth/AuthSplitLayout'

export default function ForgotPasswordPage(){
  const [userName, setUserName] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState<any>(null)
  const router = useRouter()
  const { t, i18n } = useTranslation()
  const { isAuthenticated } = useAuth()
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl' || (i18n.resolvedLanguage || i18n.language || '').startsWith('ar');
  const fieldSx = isRTL ? { '& .MuiInputBase-input': { textAlign: 'right' } } : {};

  useEffect(() => {
    if (isAuthenticated) {
      router.push('/dashboard');
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
    <AuthSplitLayout
      badge={isRTL ? 'استرداد الوصول' : 'ACCOUNT RECOVERY'}
      title={isRTL ? 'استعادة الوصول بنفس المسار الآمن الحالي' : 'Recover access through the same secure reset flow'}
      subtitle={
        isRTL
          ? 'اطلب رمز إعادة التعيين من خلال واجهة أوضح تحافظ على نفس السلوك الحالي وتعرض الخطوة التالية بوضوح.'
          : 'Request a reset token through a clearer recovery experience that keeps the current behavior and makes the next step obvious.'
      }
      formTitle={t('login.forgotPassword') || 'Forgot Password'}
      formSubtitle={isRTL ? 'أدخل اسم المستخدم لطلب رمز إعادة التعيين' : 'Enter your username to request a password reset token'}
      heroIcon={<LockResetIcon />}
      formIcon={<PersonIcon />}
      footerLinkHref="/login"
      footerLinkLabel={t('login.backToSignIn') || t('login.signIn') || 'Back to Sign In'}
      features={[
        {
          icon: <ShieldOutlined fontSize="small" />,
          text: isRTL ? 'يعرض حالة الطلب والخطوة التالية بدون تغيير منطق الاسترداد' : 'Shows request state and next step without changing reset logic',
        },
        {
          icon: <MarkEmailReadOutlined fontSize="small" />,
          text: isRTL ? 'يسهّل الانتقال المباشر إلى شاشة تعيين كلمة المرور' : 'Makes the handoff to the reset screen more obvious',
        },
      ]}
    >
      <Box component="form" onSubmit={handleSubmit}>
        <Stack spacing={2}>
          {error ? (
            <Alert severity="error" sx={{ borderRadius: 3 }}>
              {error}
            </Alert>
          ) : null}

          {success ? (
            <Alert severity="success" sx={{ borderRadius: 3 }}>
              <Typography variant="body2" fontWeight={700}>
                {t('login.passwordResetRequested') || 'Password reset token issued.'}
              </Typography>
              <Typography variant="caption" sx={{ display: 'block', mt: 1, wordBreak: 'break-all' }}>
                Token: {success.token}
              </Typography>
              <Button
                fullWidth
                variant="contained"
                sx={{ mt: 2, borderRadius: 3, fontWeight: 800 }}
                onClick={() => router.push(`/reset-password?userName=${encodeURIComponent(userName)}&token=${encodeURIComponent(success.token)}`)}
              >
                {t('login.resetPassword') || 'Reset Password Now'}
              </Button>
            </Alert>
          ) : null}

          <TextField
            fullWidth
            label={t('login.username') || 'Username'}
            placeholder={t('login.usernamePlaceholder') || "Enter your username"}
            value={userName}
            onChange={(e)=>setUserName(e.target.value)}
            required
            autoFocus
            sx={fieldSx}
          />

          <Button
            type="submit"
            fullWidth
            variant="contained"
            size="large"
            disabled={loading}
            sx={{ py: 1.35, borderRadius: 3, fontWeight: 800 }}
          >
            {loading ? <CircularProgress size={24} color="inherit" /> : (t('login.requestReset') || 'Send Reset Link')}
          </Button>
        </Stack>
      </Box>
    </AuthSplitLayout>
  )
}
