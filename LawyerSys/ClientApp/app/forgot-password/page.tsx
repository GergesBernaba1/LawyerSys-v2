'use client'
import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Box, Paper, TextField, Button, Typography, Alert, Container, Avatar } from '@mui/material'
import { LockReset as LockResetIcon } from '@mui/icons-material'
import api from '../../src/services/api'
import { useTranslation } from 'react-i18next'

export default function ForgotPasswordPage(){
  const [userName, setUserName] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState<any>(null)
  const router = useRouter()
  const { t } = useTranslation()

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
    <Container component="main" maxWidth="sm">
      <Box sx={{ marginTop: 8, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <Avatar sx={{ m: 1, bgcolor: 'primary.main' }}>
          <LockResetIcon />
        </Avatar>
        <Typography component="h1" variant="h5">{t('login.forgotPassword') || 'Forgot your password?'}</Typography>
        <Paper elevation={3} sx={{ padding: 4, width: '100%', mt: 2 }}>
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <TextField
              margin="normal"
              required
              fullWidth
              id="userName"
              label={t('login.username') || 'Username'}
              name="userName"
              autoComplete="username"
              autoFocus
              value={userName}
              onChange={(e)=>setUserName(e.target.value)}
            />

            {error && <Alert severity="error" sx={{ mt: 2 }}>{error}</Alert>}
            {success && (
              <Alert severity="success" sx={{ mt: 2 }}>
                {t('login.passwordResetRequested') || 'Password reset token issued.'}
                {/* for dev/testing show token and provide quick link to Reset page */}
                <Box sx={{ mt: 1, wordBreak: 'break-all' }}><strong>token:</strong> {success.token}</Box>
                <Box sx={{ mt: 1 }}>
                  <Button size="small" variant="outlined" onClick={()=>router.push(`/reset-password?userName=${encodeURIComponent(userName)}&token=${encodeURIComponent(success.token)}`)}>{t('login.resetPassword') || 'Reset password'}</Button>
                </Box>
              </Alert>
            )}

            <Button type="submit" fullWidth variant="contained" sx={{ mt: 3, mb: 2 }} disabled={loading}>
              {loading ? (t('app.loading') || 'Loading...') : (t('login.requestReset') || 'Request reset')}
            </Button>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button onClick={()=>router.push('/login')} variant="text">{t('login.signIn') || 'Sign In'}</Button>
            </Box>
          </Box>
        </Paper>
      </Box>
    </Container>
  )
}
