'use client'

import React, { useEffect, useState } from 'react'
import {
  Alert,
  Box,
  Button,
  Container,
  Paper,
  TextField,
  Typography,
  useTheme,
} from '@mui/material'
import { useTranslation } from 'react-i18next'
import { useParams } from 'next/navigation'
import api from '../../../../src/services/api'

type PublicSignRequest = {
  id: number
  requestTitle: string
  signerName: string
  signerEmail: string
  message: string | null
  status: string
  requestedAt: string
  tokenExpiresAt: string | null
}

export default function PublicESignPage() {
  const { t } = useTranslation()
  const theme = useTheme()
  const isRTL = theme.direction === 'rtl'
  const params = useParams<{ token: string }>()
  const token = params?.token

  const [item, setItem] = useState<PublicSignRequest | null>(null)
  const [signedByName, setSignedByName] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const load = async () => {
    if (!token) return
    setLoading(true)
    setError('')
    try {
      const response = await api.get(`/ESign/public/${token}`)
      setItem(response.data)
      setSignedByName(response.data?.signerName || '')
    } catch (e: any) {
      setError(e?.response?.data?.message || t('esign.public.failedLoad'))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [token])

  const sign = async () => {
    if (!token) return
    if (!signedByName.trim()) {
      setError(t('esign.public.signerRequired'))
      return
    }

    setSubmitting(true)
    setError('')
    setSuccess('')
    try {
      await api.post(`/ESign/public/${token}/sign`, { signedByName: signedByName.trim() })
      setSuccess(t('esign.public.signedSuccess'))
      await load()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('esign.public.failedSign'))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Container maxWidth="sm" dir={isRTL ? 'rtl' : 'ltr'} sx={{ py: 6 }}>
      <Paper elevation={0} sx={{ p: { xs: 2.5, md: 3 }, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="h5" sx={{ fontWeight: 800 }}>{t('esign.public.title')}</Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>{t('esign.public.subtitle')}</Typography>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

        {loading && <Typography variant="body2">{t('app.loading')}</Typography>}

        {!loading && item && (
          <Box sx={{ display: 'grid', gap: 1.5 }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>{item.requestTitle}</Typography>
            <Typography variant="body2" color="text.secondary">{t('esign.public.signer')}: {item.signerName} ({item.signerEmail})</Typography>
            {item.message && <Typography variant="body2">{item.message}</Typography>}
            <Typography variant="body2" color="text.secondary">{t('esign.status')}: {t(`esign.statuses.${item.status.toLowerCase()}`)}</Typography>
            {item.tokenExpiresAt && <Typography variant="body2" color="text.secondary">{t('esign.public.expiresAt')}: {new Date(item.tokenExpiresAt).toLocaleString()}</Typography>}

            {item.status === 'Pending' ? (
              <>
                <TextField
                  label={t('esign.public.signedByName')}
                  value={signedByName}
                  onChange={(e) => setSignedByName(e.target.value)}
                  fullWidth
                />
                <Button variant="contained" disabled={submitting} onClick={sign}>
                  {submitting ? t('app.loading') : t('esign.public.signNow')}
                </Button>
              </>
            ) : (
              <Alert severity="info">{t('esign.public.alreadyHandled')}</Alert>
            )}
          </Box>
        )}
      </Paper>
    </Container>
  )
}
