'use client'

import React, { useState } from 'react'
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
import api from '../../../src/services/api'

type PublicIntakeForm = {
  fullName: string
  email: string
  phoneNumber: string
  nationalId: string
  subject: string
  description: string
  desiredCaseType: string
}

const initialForm: PublicIntakeForm = {
  fullName: '',
  email: '',
  phoneNumber: '',
  nationalId: '',
  subject: '',
  description: '',
  desiredCaseType: '',
}

export default function PublicIntakePage() {
  const { t } = useTranslation()
  const theme = useTheme()
  const isRTL = theme.direction === 'rtl'

  const [form, setForm] = useState<PublicIntakeForm>(initialForm)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const submit = async (event: React.FormEvent) => {
    event.preventDefault()
    setError('')
    setSuccess('')

    if (!form.fullName.trim() || !form.subject.trim()) {
      setError(t('intake.public.required'))
      return
    }

    setLoading(true)
    try {
      await api.post('/Intake/public', {
        fullName: form.fullName,
        email: form.email || null,
        phoneNumber: form.phoneNumber || null,
        nationalId: form.nationalId || null,
        subject: form.subject,
        description: form.description || null,
        desiredCaseType: form.desiredCaseType || null,
      })
      setForm(initialForm)
      setSuccess(t('intake.public.success'))
    } catch (e: any) {
      setError(e?.response?.data?.message || t('intake.public.failed'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <Container maxWidth="md" dir={isRTL ? 'rtl' : 'ltr'} sx={{ py: 6 }}>
      <Paper elevation={0} sx={{ p: { xs: 2.5, md: 3 }, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="h5" sx={{ fontWeight: 800 }}>{t('intake.public.title')}</Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>{t('intake.public.subtitle')}</Typography>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

        <Box component="form" onSubmit={submit} sx={{ display: 'grid', gap: 1.5 }}>
          <TextField
            label={t('intake.public.fullName')}
            value={form.fullName}
            onChange={(e) => setForm((prev) => ({ ...prev, fullName: e.target.value }))}
            required
          />
          <TextField
            label={t('intake.public.subject')}
            value={form.subject}
            onChange={(e) => setForm((prev) => ({ ...prev, subject: e.target.value }))}
            required
          />
          <TextField
            label={t('intake.public.email')}
            value={form.email}
            onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))}
          />
          <TextField
            label={t('intake.public.phoneNumber')}
            value={form.phoneNumber}
            onChange={(e) => setForm((prev) => ({ ...prev, phoneNumber: e.target.value }))}
          />
          <TextField
            label={t('intake.public.nationalId')}
            value={form.nationalId}
            onChange={(e) => setForm((prev) => ({ ...prev, nationalId: e.target.value }))}
          />
          <TextField
            label={t('intake.public.caseType')}
            value={form.desiredCaseType}
            onChange={(e) => setForm((prev) => ({ ...prev, desiredCaseType: e.target.value }))}
          />
          <TextField
            label={t('intake.public.description')}
            value={form.description}
            onChange={(e) => setForm((prev) => ({ ...prev, description: e.target.value }))}
            multiline
            minRows={4}
          />

          <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
            <Button type="submit" variant="contained" disabled={loading}>
              {loading ? t('app.loading') : t('intake.public.submit')}
            </Button>
          </Box>
        </Box>
      </Paper>
    </Container>
  )
}
