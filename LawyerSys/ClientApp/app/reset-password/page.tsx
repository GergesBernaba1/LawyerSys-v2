'use client'
import React, { useState, useEffect } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'
import { Box, Paper, TextField, Button, Typography, Alert, Container, Avatar } from '@mui/material'
import { Key as KeyIcon } from '@mui/icons-material'
import api from '../../src/services/api'
import { useTranslation } from 'react-i18next'

export default function ResetPasswordPage(){
  const search = useSearchParams()
  const initialToken = search.get('token') || ''
  const initialUser = search.get('userName') || ''
  const [userName, setUserName] = useState(initialUser)
  const [token, setToken] = useState(initialToken)
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  const router = useRouter()
  const { t } = useTranslation()

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
      setError(e?.response?.data?.message || t('login.errorOccurred') || 'Error')
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
