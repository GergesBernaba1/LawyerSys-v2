'use client'

import React, { useCallback, useEffect, useMemo, useState } from 'react'
import {
  Alert,
  Box,
  Button,
  Chip,
  Card,
  CardContent,
  Paper,
  Stack,
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
import SearchableSelect from '../../src/components/SearchableSelect'
import { useCurrency } from '../../src/hooks/useCurrency'

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
  const { hasRole } = useAuth()
  const { formatCurrency } = useCurrency()
  const isEmployeeOnly = hasRole('Employee') && !hasRole('Admin') && !hasRole('SuperAdmin')

  const [entries, setEntries] = useState<TimeEntry[]>([])
  const [suggestions, setSuggestions] = useState<Suggestion[]>([])
  const [caseOptions, setCaseOptions] = useState<Array<{ value: number; label: string }>>([])
  const [error, setError] = useState('')
  const [busyId, setBusyId] = useState<number | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>('All')

  const [caseCode, setCaseCode] = useState('')
  const [workType, setWorkType] = useState('General')
  const [description, setDescription] = useState('')
  const [hourlyRate, setHourlyRate] = useState('')

  const runningEntries = useMemo(() => entries.filter((x) => x.status === 'Running'), [entries])
  const stoppedEntries = useMemo(() => entries.filter((x) => x.status === 'Stopped'), [entries])
  const totalTrackedMinutes = useMemo(() => stoppedEntries.reduce((sum, entry) => sum + (entry.durationMinutes || 0), 0), [stoppedEntries])

  const load = useCallback(async () => {
    setError('')
    try {
      const [entriesResp, suggestionsResp, casesResp] = await Promise.all([
        api.get('/TimeTracking', {
          params: {
            status: statusFilter === 'All' ? undefined : statusFilter,
          },
        }),
        api.get('/TimeTracking/suggestions', {
          params: {
            hourlyRate: hourlyRate ? Number(hourlyRate) : 0,
          },
        }),
        api.get('/Cases?page=1&pageSize=100'),
      ])
      setEntries(entriesResp.data || [])
      setSuggestions(suggestionsResp.data || [])
      const cases = Array.isArray(casesResp.data) ? casesResp.data : (casesResp.data?.items || [])
      setCaseOptions(
        cases.map((item: any) => ({
          value: Number(item.code ?? item.Code ?? item.id ?? item.Id),
          label: `#${item.code ?? item.Code ?? item.id ?? item.Id} ${item.invitionsStatment ?? item.InvitionsStatment ?? item.caseName ?? ''}`.trim(),
        }))
      )
    } catch (e: any) {
      setError(e?.response?.data?.message || t('timetracking.failedLoad'))
    }
  }, [statusFilter, hourlyRate, t])

  useEffect(() => {
    void load()
  }, [load])

  const start = async () => {
    setError('')
    try {
      await api.post('/TimeTracking/start', {
        caseCode: caseCode ? Number(caseCode) : null,
        customerId: null,
        workType,
        description: description || null,
      })
      setCaseCode('')
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
        <Typography variant="h5" sx={{ fontWeight: 800 }}>{isEmployeeOnly ? t('timetracking.employeeTitle', { defaultValue: 'My Time Tracking' }) : t('timetracking.title')}</Typography>
        <Typography variant="body2" color="text.secondary">
          {isEmployeeOnly ? t('timetracking.employeeSubtitle', { defaultValue: 'Track time only for the cases assigned to you.' }) : t('timetracking.subtitle')}
        </Typography>
      </Paper>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {isEmployeeOnly && (
        <Alert severity="info" sx={{ mb: 2 }}>
          {t('timetracking.employeeHint', { defaultValue: 'Only your own entries and assigned cases appear here.' })}
        </Alert>
      )}

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 2, mb: 2 }}>
        <Card><CardContent><Typography color="text.secondary">{t('timetracking.running', { defaultValue: 'Running' })}</Typography><Typography variant="h6">{runningEntries.length}</Typography></CardContent></Card>
        <Card><CardContent><Typography color="text.secondary">{t('timetracking.stopped', { defaultValue: 'Stopped' })}</Typography><Typography variant="h6">{stoppedEntries.length}</Typography></CardContent></Card>
        <Card><CardContent><Typography color="text.secondary">{t('timetracking.totalMinutes', { defaultValue: 'Tracked minutes' })}</Typography><Typography variant="h6">{totalTrackedMinutes}</Typography></CardContent></Card>
      </Box>

      <Paper elevation={0} sx={{ p: 2, mb: 2, borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.5 }}>{t('timetracking.startTitle')}</Typography>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, minmax(0, 1fr))' }, gap: 1.5 }}>
          <SearchableSelect<number>
            size="small"
            label={t('timetracking.caseCode')}
            value={caseCode ? Number(caseCode) : null}
            onChange={(value) => setCaseCode(value ? String(value) : '')}
            options={caseOptions}
            sx={{ minWidth: 220 }}
          />
          <TextField size="small" label={t('timetracking.workType')} value={workType} onChange={(e) => setWorkType(e.target.value)} />
          <TextField size="small" label={t('timetracking.description')} value={description} onChange={(e) => setDescription(e.target.value)} sx={{ gridColumn: { xs: 'span 1', md: 'span 2' } }} />
          <TextField size="small" label={t('timetracking.hourlyRate')} value={hourlyRate} onChange={(e) => setHourlyRate(e.target.value)} />
          <SearchableSelect<string>
            size="small"
            label={t('timetracking.table.status')}
            value={statusFilter}
            onChange={(value) => setStatusFilter(value ?? 'All')}
            options={[
              { value: 'All', label: t('common.all', { defaultValue: 'All' }) as string },
              { value: 'Running', label: t('timetracking.running') as string },
              { value: 'Stopped', label: t('timetracking.stopped') as string },
            ]}
            disableClearable
            sx={{ minWidth: 180 }}
          />
        </Box>
        <Box sx={{ mt: 1.5, display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button variant="outlined" onClick={load}>{t('common.refresh')}</Button>
          <Button variant="contained" onClick={start} disabled={!caseCode}>{t('timetracking.start')}</Button>
        </Box>
      </Paper>

      {runningEntries.length > 0 && (
        <Paper elevation={0} sx={{ p: 2, mb: 2, borderRadius: 3, border: '1px solid', borderColor: 'warning.light', bgcolor: 'warning.50' }}>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.5} justifyContent="space-between" alignItems={{ xs: 'flex-start', md: 'center' }}>
            <Typography sx={{ fontWeight: 700 }}>
              {t('timetracking.runningNotice', { count: runningEntries.length })}
            </Typography>
            <Button variant="outlined" onClick={() => setStatusFilter('Running')}>
              {t('timetracking.viewRunning', { defaultValue: 'View running timers' })}
            </Button>
          </Stack>
        </Paper>
      )}

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
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>{entry.workType}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {entry.description || '-'} | {new Date(entry.startedAt).toLocaleString()} {entry.caseCode ? `| #${entry.caseCode}` : ''}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip size="small" color={entry.status === 'Running' ? 'warning' : 'success'} label={entry.status === 'Running' ? t('timetracking.running') : t('timetracking.stopped')} />
                </TableCell>
                <TableCell>{entry.durationMinutes} {t('timetracking.minutes')}</TableCell>
                <TableCell>{entry.suggestedAmount != null ? formatCurrency(Number(entry.suggestedAmount)) : '-'}</TableCell>
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
                <TableCell colSpan={5} align="center"><Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>{t('common.noRecords')}</Typography></TableCell>
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
                <TableCell>{formatCurrency(Number(item.suggestedAmount || 0))}</TableCell>
              </TableRow>
            ))}
            {suggestions.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} align="center"><Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>{t('common.noRecords')}</Typography></TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Paper>
    </Box>
  )
}
