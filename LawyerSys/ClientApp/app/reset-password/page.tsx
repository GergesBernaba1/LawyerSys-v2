'use client'
import React, { useState, useEffect, Suspense } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'
import { Box, Paper, TextField, Button, Typography, Alert, Container, Avatar } from '@mui/material'
import { Key as KeyIcon } from '@mui/icons-material'
import api from '../../src/services/api'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../../src/services/auth'

function ResetPasswordForm() {
  const search = useSearchParams()
  // guard in case useSearchParams returns something unexpected
  const safeSearch = (search && typeof (search as any).get === 'function') ? search : null
  const initialToken = safeSearch ? (safeSearch.get('token') || '') : ''
  const initialUser = safeSearch ? (safeSearch.get('userName') || '') : ''
  const [userName, setUserName] = useState(initialUser)
  const [token, setToken] = useState(initialToken)
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)

  // debug render trace to help locate hook mismatch
  console.debug('ResetPassword render', { token, userName, success, loading })
  const router = useRouter()
  const { t } = useTranslation()

  useEffect(()=>{
    console.debug('ResetPassword effect: initialToken, initialUser', { initialToken, initialUser })
    if (initialToken) setToken(initialToken)
    if (initialUser) setUserName(initialUser)
  }, [initialToken, initialUser])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (password !== confirm) { setError(t('register.passwordMismatch') || 'Passwords do not match'); return }
    setLoading(true)
    
    console.log('Submitting password reset:', { userName, tokenLength: token.length })
    
    try{
      const response = await api.post('/Account/reset-password', { userName, token, newPassword: password })
      console.log('Password reset response:', response.data)
      setSuccess(true)
    }catch(e:any){
      console.error('Password reset error:', e.response?.data || e.message)
      const errorMsg = e?.response?.data?.message 
        || (e?.response?.data?.errors ? JSON.stringify(e.response.data.errors) : '')
        || e?.message 
        || t('login.errorOccurred') 
        || 'Error'
      setError(errorMsg)
    }finally{ setLoading(false) }
  }

  if (success) return (
    <Container component="main" maxWidth="sm">
      <Box sx={{ marginTop: 8, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <Typography component="h1" variant="h5">{t('login.passwordResetSuccess') || 'Password updated'}</Typography>
        <Box sx={{ mt: 3 }}>
          <Button variant="contained" onClick={()=>router.push('/login')}>{t('login.signIn') || 'Sign In'}</Button>
        </Box>
      </Box>
    </Container>
  )

  return (
    <Container component="main" maxWidth="sm">
      <Box sx={{ marginTop: 8, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <Avatar sx={{ m: 1, bgcolor: 'primary.main' }}>
          <KeyIcon />
        </Avatar>
        <Typography component="h1" variant="h5">{t('login.resetPassword') || 'Reset password'}</Typography>
        <Paper elevation={3} sx={{ padding: 4, width: '100%', mt: 2 }}>
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <TextField margin="normal" required fullWidth id="userName" label={t('login.username')||'Username'} value={userName} onChange={(e)=>setUserName(e.target.value)} />
            <TextField margin="normal" required fullWidth id="token" label={t('login.resetToken')||'Token'} value={token} onChange={(e)=>setToken(e.target.value)} />
            <TextField margin="normal" required fullWidth id="password" type="password" label={t('register.password')||'Password'} value={password} onChange={(e)=>setPassword(e.target.value)} />
            <TextField margin="normal" required fullWidth id="confirm" type="password" label={t('register.confirmPassword')||'Confirm Password'} value={confirm} onChange={(e)=>setConfirm(e.target.value)} />

            {error && <Alert severity="error" sx={{ mt: 2 }}>{error}</Alert>}

            <Button type="submit" fullWidth variant="contained" sx={{ mt: 3, mb: 2 }} disabled={loading}>{loading ? (t('app.loading')||'Loading...') : (t('login.resetPassword')||'Reset password')}</Button>
          </Box>
        </Paper>
      </Box>
    </Container>
  )
}

export default function ResetPasswordPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ResetPasswordForm />
    </Suspense>
  )
}
