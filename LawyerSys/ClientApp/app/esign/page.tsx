'use client'

import React, { useEffect, useMemo, useState } from 'react'
import {
  Alert,
  Box,
  Button,
  Chip,
  MenuItem,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
  useTheme,
} from '@mui/material'
import { useTranslation } from 'react-i18next'
import api from '../../src/services/api'
import { useAuth } from '../../src/services/auth'

type ESignRequest = {
  id: number
  fileId: number | null
  fileCode: string | null
  filePath: string | null
  requestTitle: string
  templateType: string | null
  signerName: string
  signerEmail: string
  status: string
  externalReference: string | null
  publicSignUrl: string | null
  tokenExpiresAt: string | null
  signedByName: string | null
  requestedBy: string
  requestedAt: string
  signedAt: string | null
}

type FileItem = {
  id: number
  code: string | null
}

type TemplateItem = {
  key: string
  name: string
}

export default function ESignPage() {
  const { t } = useTranslation()
  const theme = useTheme()
  const isRTL = theme.direction === 'rtl'
  const { isAuthenticated, hasAnyRole } = useAuth()
  const canUseESign = hasAnyRole('Admin', 'Employee')

  const [requests, setRequests] = useState<ESignRequest[]>([])
  const [files, setFiles] = useState<FileItem[]>([])
  const [templates, setTemplates] = useState<TemplateItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState<Record<number, boolean>>({})

  const [statusFilter, setStatusFilter] = useState('')
  const [search, setSearch] = useState('')

  const [requestTitle, setRequestTitle] = useState('')
  const [signerName, setSignerName] = useState('')
  const [signerEmail, setSignerEmail] = useState('')
  const [fileId, setFileId] = useState('')
  const [templateType, setTemplateType] = useState('')

  const loadRequests = async () => {
    if (!isAuthenticated || !canUseESign) {
      setLoading(false)
      return
    }

    setLoading(true)
    setError('')
    try {
      const response = await api.get('/ESign', {
        params: {
          status: statusFilter || undefined,
          search: search || undefined,
        },
      })
      setRequests(response.data || [])
    } catch (e: any) {
      setError(e?.response?.data?.message || t('esign.failedLoad'))
    } finally {
      setLoading(false)
    }
  }

  const loadOptions = async () => {
    try {
      const [filesResponse, templatesResponse] = await Promise.all([
        api.get('/Files'),
        api.get('/DocumentGeneration/templates'),
      ])

      const filesData = Array.isArray(filesResponse.data)
        ? filesResponse.data
        : (filesResponse.data?.items || [])

      setFiles(filesData || [])
      setTemplates(templatesResponse.data || [])
    } catch {
      setFiles([])
      setTemplates([])
    }
  }

  useEffect(() => {
    loadRequests()
  }, [isAuthenticated, canUseESign])

  useEffect(() => {
    if (!isAuthenticated || !canUseESign) return
    loadOptions()
  }, [isAuthenticated, canUseESign])

  const createRequest = async () => {
    setError('')
    if (!signerName.trim() || !signerEmail.trim()) {
      setError(t('esign.validationSigner'))
      return
    }

    if (!fileId && !templateType) {
      setError(t('esign.validationDocument'))
      return
    }

    try {
      await api.post('/ESign/requests', {
        fileId: fileId ? Number(fileId) : null,
        templateType: templateType || null,
        requestTitle: requestTitle || null,
        signerName,
        signerEmail,
      })

      setRequestTitle('')
      setSignerName('')
      setSignerEmail('')
      setFileId('')
      setTemplateType('')
      await loadRequests()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('esign.failedCreate'))
    }
  }

  const updateStatus = async (id: number, status: 'Signed' | 'Declined' | 'Cancelled') => {
    setBusy((prev) => ({ ...prev, [id]: true }))
    setError('')
    try {
      await api.post(`/ESign/requests/${id}/status`, { status })
      await loadRequests()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('esign.failedStatus'))
    } finally {
      setBusy((prev) => ({ ...prev, [id]: false }))
    }
  }

  const createShareLink = async (id: number) => {
    setBusy((prev) => ({ ...prev, [id]: true }))
    setError('')
    try {
      const response = await api.post(`/ESign/requests/${id}/share-link`, { expireAfterHours: 72 })
      const link = response.data?.publicSignUrl
      if (link && typeof navigator !== 'undefined' && navigator.clipboard) {
        await navigator.clipboard.writeText(link)
      }
      await loadRequests()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('esign.failedShareLink'))
    } finally {
      setBusy((prev) => ({ ...prev, [id]: false }))
    }
  }

  const statuses = useMemo(
    () => [
      { value: '', label: t('esign.statuses.all') },
      { value: 'Pending', label: t('esign.statuses.pending') },
      { value: 'Signed', label: t('esign.statuses.signed') },
      { value: 'Declined', label: t('esign.statuses.declined') },
      { value: 'Cancelled', label: t('esign.statuses.cancelled') },
    ],
    [t],
  )

  const statusColor = (status: string) => {
    if (status === 'Signed') return 'success'
    if (status === 'Pending') return 'warning'
    if (status === 'Declined') return 'error'
    return 'default'
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      <Paper elevation={0} sx={{ p: { xs: 2.5, md: 3 }, mb: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="h5" sx={{ fontWeight: 800 }}>{t('esign.title')}</Typography>
        <Typography variant="body2" color="text.secondary">{t('esign.subtitle')}</Typography>
      </Paper>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Paper elevation={0} sx={{ p: 2, mb: 2, borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.5 }}>{t('esign.createTitle')}</Typography>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 1.5 }}>
          <TextField size="small" label={t('esign.requestTitle')} value={requestTitle} onChange={(e) => setRequestTitle(e.target.value)} />
          <TextField size="small" label={t('esign.signerName')} value={signerName} onChange={(e) => setSignerName(e.target.value)} />
          <TextField size="small" label={t('esign.signerEmail')} value={signerEmail} onChange={(e) => setSignerEmail(e.target.value)} />
          <TextField select size="small" label={t('esign.file')} value={fileId} onChange={(e) => setFileId(e.target.value)}>
            <MenuItem value="">{t('esign.none')}</MenuItem>
            {files.map((file) => (
              <MenuItem key={file.id} value={String(file.id)}>{file.code || `#${file.id}`}</MenuItem>
            ))}
          </TextField>
          <TextField select size="small" label={t('esign.template')} value={templateType} onChange={(e) => setTemplateType(e.target.value)}>
            <MenuItem value="">{t('esign.none')}</MenuItem>
            {templates.map((tpl) => (
              <MenuItem key={tpl.key} value={tpl.key}>{tpl.name}</MenuItem>
            ))}
          </TextField>
        </Box>
        <Box sx={{ mt: 1.5, display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button variant="contained" onClick={createRequest}>{t('esign.create')}</Button>
        </Box>
      </Paper>

      <Paper elevation={0} sx={{ p: 2, mb: 2, borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 220px auto' }, gap: 1.5 }}>
          <TextField size="small" label={t('esign.search')} value={search} onChange={(e) => setSearch(e.target.value)} />
          <TextField select size="small" label={t('esign.status')} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
            {statuses.map((s) => <MenuItem key={s.value || 'all'} value={s.value}>{s.label}</MenuItem>)}
          </TextField>
          <Button variant="outlined" onClick={loadRequests}>{t('common.refresh')}</Button>
        </Box>
      </Paper>

      {!loading && (
        <Paper elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', overflow: 'hidden' }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t('esign.table.request')}</TableCell>
                <TableCell>{t('esign.table.signer')}</TableCell>
                <TableCell>{t('esign.table.document')}</TableCell>
                <TableCell>{t('esign.table.status')}</TableCell>
                <TableCell>{t('esign.table.requestedAt')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'}>{t('esign.table.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {requests.map((item) => (
                <TableRow key={item.id} hover>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 700 }}>{item.requestTitle}</Typography>
                    <Typography variant="caption" color="text.secondary">#{item.id}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{item.signerName}</Typography>
                    <Typography variant="caption" color="text.secondary">{item.signerEmail}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{item.fileCode || '-'}</Typography>
                    <Typography variant="caption" color="text.secondary">{item.templateType || '-'}</Typography>
                  </TableCell>
                  <TableCell>
                    <Chip size="small" color={statusColor(item.status)} label={t(`esign.statuses.${item.status.toLowerCase()}`)} />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{new Date(item.requestedAt).toLocaleString()}</Typography>
                    {item.signedAt && <Typography variant="caption" color="text.secondary">{t('esign.signedAt')}: {new Date(item.signedAt).toLocaleString()}</Typography>}
                    {item.signedByName && <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>{t('esign.signedBy')}: {item.signedByName}</Typography>}
                    {item.tokenExpiresAt && <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>{t('esign.linkExpiresAt')}: {new Date(item.tokenExpiresAt).toLocaleString()}</Typography>}
                  </TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end', flexWrap: 'wrap' }}>
                      <Button size="small" variant="outlined" disabled={!!busy[item.id]} onClick={() => createShareLink(item.id)}>
                        {t('esign.shareLink')}
                      </Button>
                      {item.publicSignUrl && (
                        <Button size="small" variant="text" href={item.publicSignUrl} target="_blank" rel="noreferrer">
                          {t('esign.openLink')}
                        </Button>
                      )}
                      <Button size="small" variant="outlined" disabled={!!busy[item.id]} onClick={() => updateStatus(item.id, 'Signed')}>
                        {t('esign.markSigned')}
                      </Button>
                      <Button size="small" variant="outlined" color="error" disabled={!!busy[item.id]} onClick={() => updateStatus(item.id, 'Declined')}>
                        {t('esign.markDeclined')}
                      </Button>
                      <Button size="small" variant="outlined" color="inherit" disabled={!!busy[item.id]} onClick={() => updateStatus(item.id, 'Cancelled')}>
                        {t('esign.markCancelled')}
                      </Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
              {requests.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6}>
                    <Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>{t('common.noRecords')}</Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </Paper>
      )}
    </Box>
  )
}
