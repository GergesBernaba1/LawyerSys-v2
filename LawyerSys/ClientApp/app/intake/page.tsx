'use client'

import React, { useEffect, useMemo, useState } from 'react'
import {
  Alert,
  Box,
  Button,
  Chip,
  CircularProgress,
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

type IntakeLead = {
  id: number
  fullName: string
  email: string | null
  phoneNumber: string | null
  nationalId: string | null
  subject: string
  desiredCaseType: string | null
  status: string
  conflictChecked: boolean
  hasConflict: boolean
  conflictDetails: string | null
  assignedEmployeeId: number | null
  assignedEmployeeName: string | null
  nextFollowUpAt: string | null
  assignedAt: string | null
  createdAt: string
}

type EmployeeOption = {
  employeeId: number
  name: string
}

export default function IntakePage() {
  const { t } = useTranslation()
  const theme = useTheme()
  const isRTL = theme.direction === 'rtl'
  const { isAuthenticated, hasAnyRole, hasRole } = useAuth()
  const isAdmin = hasRole('Admin')
  const canUseIntake = hasAnyRole('Admin', 'Employee')

  const [items, setItems] = useState<IntakeLead[]>([])
  const [status, setStatus] = useState('')
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState<Record<number, boolean>>({})
  const [employees, setEmployees] = useState<EmployeeOption[]>([])
  const [assignmentDrafts, setAssignmentDrafts] = useState<Record<number, { employeeId: string; nextFollowUpAt: string }>>({})

  const ensureDrafts = (leads: IntakeLead[]) => {
    setAssignmentDrafts((prev) => {
      const next = { ...prev }
      leads.forEach((lead) => {
        if (!next[lead.id]) {
          next[lead.id] = {
            employeeId: lead.assignedEmployeeId ? String(lead.assignedEmployeeId) : '',
            nextFollowUpAt: lead.nextFollowUpAt ? lead.nextFollowUpAt.slice(0, 16) : '',
          }
        }
      })
      return next
    })
  }

  const loadAssignmentOptions = async () => {
    try {
      const response = await api.get('/Intake/assignment-options')
      setEmployees(response.data || [])
    } catch {
      setEmployees([])
    }
  }

  const load = async () => {
    if (!isAuthenticated || !canUseIntake) {
      setLoading(false)
      return
    }

    setLoading(true)
    setError('')
    try {
      const response = await api.get('/Intake', {
        params: {
          status: status || undefined,
          search: search || undefined,
        },
      })
      const leads = response.data || []
      setItems(leads)
      ensureDrafts(leads)
    } catch (e: any) {
      setError(e?.response?.data?.message || t('intake.failedLoad'))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [isAuthenticated, canUseIntake])

  useEffect(() => {
    if (!isAuthenticated || !canUseIntake) return
    loadAssignmentOptions()
  }, [isAuthenticated, canUseIntake])

  const setLeadBusy = (id: number, value: boolean) => {
    setBusy((prev) => ({ ...prev, [id]: value }))
  }

  const runConflictCheck = async (id: number) => {
    setLeadBusy(id, true)
    try {
      await api.get(`/Intake/${id}/conflict-check`)
      await load()
    } catch {
      setError(t('intake.failedConflict'))
    } finally {
      setLeadBusy(id, false)
    }
  }

  const setQualification = async (id: number, isQualified: boolean) => {
    setLeadBusy(id, true)
    try {
      await api.post(`/Intake/${id}/qualify`, {
        isQualified,
        notes: isQualified ? t('intake.defaultQualifiedNote') : t('intake.defaultRejectedNote'),
      })
      await load()
    } catch {
      setError(t('intake.failedQualify'))
    } finally {
      setLeadBusy(id, false)
    }
  }

  const convertLead = async (lead: IntakeLead) => {
    setLeadBusy(lead.id, true)
    try {
      await api.post(`/Intake/${lead.id}/convert`, {
        caseType: lead.desiredCaseType || undefined,
        initialAmount: 0,
      })
      await load()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('intake.failedConvert'))
    } finally {
      setLeadBusy(lead.id, false)
    }
  }

  const assignLead = async (leadId: number) => {
    const draft = assignmentDrafts[leadId]
    if (!draft?.employeeId) {
      setError(t('intake.assignment.employeeRequired'))
      return
    }

    setLeadBusy(leadId, true)
    try {
      await api.post(`/Intake/${leadId}/assign`, {
        assignedEmployeeId: Number(draft.employeeId),
        nextFollowUpAt: draft.nextFollowUpAt ? new Date(draft.nextFollowUpAt).toISOString() : null,
      })
      await load()
    } catch (e: any) {
      setError(e?.response?.data?.message || t('intake.assignment.failedAssign'))
    } finally {
      setLeadBusy(leadId, false)
    }
  }

  const statusColor = (lead: IntakeLead) => {
    if (lead.status === 'Converted') return 'success'
    if (lead.status === 'Rejected') return 'default'
    if (lead.status === 'Qualified') return 'primary'
    return 'warning'
  }

  const canConvert = (lead: IntakeLead) => isAdmin && lead.status === 'Qualified' && !lead.hasConflict

  const statuses = useMemo(
    () => [
      { value: '', label: t('intake.statuses.all') },
      { value: 'New', label: t('intake.statuses.new') },
      { value: 'Qualified', label: t('intake.statuses.qualified') },
      { value: 'Rejected', label: t('intake.statuses.rejected') },
      { value: 'Converted', label: t('intake.statuses.converted') },
    ],
    [t],
  )

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      <Paper elevation={0} sx={{ p: { xs: 2.5, md: 3 }, mb: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
        <Typography variant="h5" sx={{ fontWeight: 800 }}>{t('intake.title')}</Typography>
        <Typography variant="body2" color="text.secondary">{t('intake.subtitle')}</Typography>
      </Paper>

      <Paper elevation={0} sx={{ p: 2, mb: 2, borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 220px auto' }, gap: 1.5 }}>
          <TextField
            size="small"
            fullWidth
            label={t('intake.search')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <TextField
            select
            size="small"
            label={t('intake.status')}
            value={status}
            onChange={(e) => setStatus(e.target.value)}
          >
            {statuses.map((s) => (
              <MenuItem key={s.value || 'all'} value={s.value}>{s.label}</MenuItem>
            ))}
          </TextField>
          <Button variant="contained" onClick={load}>{t('common.refresh')}</Button>
        </Box>
      </Paper>

      {loading && <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>}

      {!loading && error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {!loading && !error && (
        <Paper elevation={0} sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider', overflow: 'hidden' }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t('intake.table.lead')}</TableCell>
                <TableCell>{t('intake.table.subject')}</TableCell>
                <TableCell>{t('intake.table.status')}</TableCell>
                <TableCell>{t('intake.table.conflict')}</TableCell>
                <TableCell>{t('intake.table.assignment')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'}>{t('intake.table.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {items.map((lead) => (
                <TableRow key={lead.id} hover>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 700 }}>{lead.fullName}</Typography>
                    <Typography variant="caption" color="text.secondary">{lead.email || lead.phoneNumber || '-'}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{lead.subject}</Typography>
                    <Typography variant="caption" color="text.secondary">{lead.desiredCaseType || '-'}</Typography>
                  </TableCell>
                  <TableCell>
                    <Chip size="small" color={statusColor(lead)} label={t(`intake.statuses.${lead.status.toLowerCase()}`)} />
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      color={lead.conflictChecked ? (lead.hasConflict ? 'error' : 'success') : 'default'}
                      label={
                        !lead.conflictChecked
                          ? t('intake.notChecked')
                          : (lead.hasConflict ? t('intake.conflictFound') : t('intake.noConflict'))
                      }
                    />
                  </TableCell>
                  <TableCell sx={{ minWidth: 280 }}>
                    <Box sx={{ display: 'grid', gap: 1 }}>
                      <TextField
                        select
                        size="small"
                        label={t('intake.assignment.employee')}
                        value={assignmentDrafts[lead.id]?.employeeId || ''}
                        onChange={(e) => setAssignmentDrafts((prev) => ({
                          ...prev,
                          [lead.id]: {
                            employeeId: e.target.value,
                            nextFollowUpAt: prev[lead.id]?.nextFollowUpAt || '',
                          },
                        }))}
                      >
                        <MenuItem value="">{t('intake.assignment.unassigned')}</MenuItem>
                        {employees.map((employee) => (
                          <MenuItem key={employee.employeeId} value={String(employee.employeeId)}>
                            {employee.name}
                          </MenuItem>
                        ))}
                      </TextField>
                      <TextField
                        size="small"
                        type="datetime-local"
                        label={t('intake.assignment.followUp')}
                        InputLabelProps={{ shrink: true }}
                        value={assignmentDrafts[lead.id]?.nextFollowUpAt || ''}
                        onChange={(e) => setAssignmentDrafts((prev) => ({
                          ...prev,
                          [lead.id]: {
                            employeeId: prev[lead.id]?.employeeId || '',
                            nextFollowUpAt: e.target.value,
                          },
                        }))}
                      />
                      {lead.assignedAt && (
                        <Typography variant="caption" color="text.secondary">
                          {t('intake.assignment.assignedAt')}: {new Date(lead.assignedAt).toLocaleString()}
                        </Typography>
                      )}
                    </Box>
                  </TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end', flexWrap: 'wrap' }}>
                      <Button size="small" variant="outlined" disabled={!!busy[lead.id]} onClick={() => assignLead(lead.id)}>
                        {t('intake.assignment.assign')}
                      </Button>
                      <Button size="small" variant="outlined" disabled={!!busy[lead.id]} onClick={() => runConflictCheck(lead.id)}>
                        {t('intake.checkConflict')}
                      </Button>
                      <Button size="small" variant="outlined" disabled={!!busy[lead.id]} onClick={() => setQualification(lead.id, true)}>
                        {t('intake.qualify')}
                      </Button>
                      <Button size="small" variant="outlined" color="inherit" disabled={!!busy[lead.id]} onClick={() => setQualification(lead.id, false)}>
                        {t('intake.reject')}
                      </Button>
                      {isAdmin && (
                        <Button
                          size="small"
                          variant="contained"
                          disabled={!!busy[lead.id] || !canConvert(lead)}
                          onClick={() => convertLead(lead)}
                        >
                          {t('intake.convert')}
                        </Button>
                      )}
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
              {items.length === 0 && (
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
