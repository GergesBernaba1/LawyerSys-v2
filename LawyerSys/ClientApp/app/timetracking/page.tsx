'use client'

import React, { useEffect, useMemo, useState } from 'react'
import {
  Alert,
  Box,
  Button,
  Chip,
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

type TimeEntry = {
  id: number
  caseCode: number | null
  customerId: number | null
  workType: string
  description: string | null
  status: string
  startedBy: string
  startedAt: string
  endedAt: string | null
  durationMinutes: number
  suggestedAmount: number | null
}

type Suggestion = {
  caseCode: number | null
  customerId: number | null
  totalMinutes: number
  suggestedAmount: number
}

export default function TimeTrackingPage() {
  const { t } = useTranslation()
  const theme = useTheme()
  const isRTL = theme.direction === 'rtl'

  const [entries, setEntries] = useState<TimeEntry[]>([])
  const [suggestions, setSuggestions] = useState<Suggestion[]>([])
  const [error, setError] = useState('')
  const [busyId, setBusyId] = useState<number | null>(null)

  const [caseCode, setCaseCode] = useState('')
  const [customerId, setCustomerId] = useState('')
  const [workType, setWorkType] = useState('General')
  const [description, setDescription] = useState('')
  const [hourlyRate, setHourlyRate] = useState('')

  const runningEntries = useMemo(() => entries.filter((x) => x.status === 'Running'), [entries])

  const load = async () => {
    setError('')
    try {
      const [entriesResp, suggestionsResp] = await Promise.all([
        api.get('/TimeTracking'),
        api.get('/TimeTracking/suggestions', {
          params: {
            hourlyRate: hourlyRate ? Number(hourlyRate) : 0,
          },
        }),
      ])
      setEntries(entriesResp.data || [])
      setSuggestions(suggestionsResp.data || [])
    } catch (e: any) {
      setError(e?.response?.data?.message || t('timetracking.failedLoad'))
    }
  }

  useEffect(() => {
    load()
  }, [])

  const start = async () => {
    setError('')
    try {
      await api.post('/TimeTracking/start', {
        caseCode: caseCode ? Number(caseCode) : null,
        customerId: customerId ? Number(customerId) : null,
        workType,
        description: description || null,
      })
      setCaseCode('')
      setCustomerId('')
      setDescription('')
      await load()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('timetracking.failedStart'))
    }
  }

  const stop = async (id: number) => {
    setBusyId(id)
    setError('')
    try {
      await api.post(`/TimeTracking/${id}/stop`, {
        hourlyRate: hourlyRate ? Number(hourlyRate) : null,
      })
      await load()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('timetracking.failedStop'))
    } finally {
      setBusyId(null)
    }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      <Paper elevation={0} sx={{ p: { xs: 2.5, md: 3 }, mb: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="h5" sx={{ fontWeight: 800 }}>{t('timetracking.title')}</Typography>
        <Typography variant="body2" color="text.secondary">{t('timetracking.subtitle')}</Typography>
      </Paper>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Paper elevation={0} sx={{ p: 2, mb: 2, borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.5 }}>{t('timetracking.startTitle')}</Typography>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, minmax(0, 1fr))' }, gap: 1.5 }}>
          <TextField size="small" label={t('timetracking.caseCode')} value={caseCode} onChange={(e) => setCaseCode(e.target.value)} />
          <TextField size="small" label={t('timetracking.customerId')} value={customerId} onChange={(e) => setCustomerId(e.target.value)} />
          <TextField size="small" label={t('timetracking.workType')} value={workType} onChange={(e) => setWorkType(e.target.value)} />
          <TextField size="small" label={t('timetracking.description')} value={description} onChange={(e) => setDescription(e.target.value)} sx={{ gridColumn: { xs: 'span 1', md: 'span 2' } }} />
          <TextField size="small" label={t('timetracking.hourlyRate')} value={hourlyRate} onChange={(e) => setHourlyRate(e.target.value)} />
        </Box>
        <Box sx={{ mt: 1.5, display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button variant="outlined" onClick={load}>{t('common.refresh')}</Button>
          <Button variant="contained" onClick={start}>{t('timetracking.start')}</Button>
        </Box>
      </Paper>

      <Paper elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', overflow: 'hidden', mb: 2 }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>{t('timetracking.table.entry')}</TableCell>
              <TableCell>{t('timetracking.table.status')}</TableCell>
              <TableCell>{t('timetracking.table.duration')}</TableCell>
              <TableCell>{t('timetracking.table.amount')}</TableCell>
              <TableCell align={isRTL ? 'left' : 'right'}>{t('timetracking.table.actions')}</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {entries.map((entry) => (
              <TableRow key={entry.id} hover>
                <TableCell>
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>#{entry.id} - {entry.workType}</Typography>
                  <Typography variant="caption" color="text.secondary">{entry.description || '-'} | {new Date(entry.startedAt).toLocaleString()}</Typography>
                </TableCell>
                <TableCell>
                  <Chip size="small" color={entry.status === 'Running' ? 'warning' : 'success'} label={entry.status === 'Running' ? t('timetracking.running') : t('timetracking.stopped')} />
                </TableCell>
                <TableCell>{entry.durationMinutes} {t('timetracking.minutes')}</TableCell>
                <TableCell>{entry.suggestedAmount ?? 0}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'}>
                  {entry.status === 'Running' && (
                    <Button size="small" variant="outlined" disabled={busyId === entry.id} onClick={() => stop(entry.id)}>
                      {t('timetracking.stop')}
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
            {entries.length === 0 && (
              <TableRow>
                <TableCell colSpan={5}><Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>{t('common.noRecords')}</Typography></TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Paper>

      <Paper elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', overflow: 'hidden' }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>{t('timetracking.suggestions.case')}</TableCell>
              <TableCell>{t('timetracking.suggestions.customer')}</TableCell>
              <TableCell>{t('timetracking.suggestions.minutes')}</TableCell>
              <TableCell>{t('timetracking.suggestions.amount')}</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {suggestions.map((item, idx) => (
              <TableRow key={`${item.caseCode ?? 'x'}-${item.customerId ?? 'y'}-${idx}`}>
                <TableCell>{item.caseCode ?? '-'}</TableCell>
                <TableCell>{item.customerId ?? '-'}</TableCell>
                <TableCell>{item.totalMinutes}</TableCell>
                <TableCell>{item.suggestedAmount}</TableCell>
              </TableRow>
            ))}
            {suggestions.length === 0 && (
              <TableRow>
                <TableCell colSpan={4}><Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>{t('common.noRecords')}</Typography></TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Paper>

      {runningEntries.length > 0 && (
        <Alert severity="info" sx={{ mt: 2 }}>
          {t('timetracking.runningNotice', { count: runningEntries.length })}
        </Alert>
      )}
    </Box>
  )
}
