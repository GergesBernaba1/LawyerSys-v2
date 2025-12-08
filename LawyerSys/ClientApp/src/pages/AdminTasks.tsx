import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, FormControl, InputLabel, Select, MenuItem, Grid,
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, Task as TaskIcon, Refresh as RefreshIcon, NotificationsActive as ReminderIcon,
} from '@mui/icons-material';
import api from '../services/api';

type Task = { id: number; taskName?: string; type?: string; taskDate?: string; taskReminderDate?: string; notes?: string; employeeId?: number; employeeName?: string };

export default function AdminTasks() {
  const { t } = useTranslation();
  const [items, setItems] = useState<AdminTask[]>([]);
  const [loading, setLoading] = useState(false);
  const [taskName, setTaskName] = useState('');
  const [type, setType] = useState('');
  const [taskDate, setTaskDate] = useState('');
  const [taskReminderDate, setTaskReminderDate] = useState('');
  const [notes, setNotes] = useState('');
  const [employeeId, setEmployeeId] = useState<number | ''>('');
  const [employees, setEmployees] = useState<{ id: number; user?: any }[]>([]);
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const [r, e] = await Promise.all([api.get('/AdminTasks'), api.get('/Employees')]);
      setItems(r.data); setEmployees(e.data);
    } catch (err) { setSnackbar({ open: true, message: t('tasks.failedLoad'), severity: 'error' }); }
    finally { setLoading(false); }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      await api.post('/AdminTasks', { taskName, type, taskDate: taskDate || undefined, taskReminderDate: taskReminderDate || undefined, notes, employeeId: employeeId || undefined });
      setTaskName(''); setType(''); setTaskDate(''); setTaskReminderDate(''); setNotes(''); setEmployeeId('');
      setOpenDialog(false); await load();
      setSnackbar({ open: true, message: t('tasks.created'), severity: 'success' });
    } catch (e: any) { setSnackbar({ open: true, message: e?.response?.data?.message || t('tasks.failed'), severity: 'error' }); }
  }

  async function remove(id: number) {
    if (!confirm(t('tasks.confirmDelete'))) return;
    try { await api.delete(`/AdminTasks/${id}`); await load(); setSnackbar({ open: true, message: t('tasks.deleted'), severity: 'success' }); }
    catch (err) { setSnackbar({ open: true, message: t('tasks.failed'), severity: 'error' }); }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <TaskIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>{t('tasks.management')}</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title={t('cases.refresh')}><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>{t('tasks.newTask')}</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}><CardContent sx={{ py: 2 }}><Typography variant="body2" color="text.secondary">{t('tasks.totalTasks')}: <strong>{items.length}</strong></Typography></CardContent></Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow><TableCell>{t('tasks.taskName')}</TableCell><TableCell>{t('tasks.type')}</TableCell><TableCell>{t('tasks.reminder')}</TableCell><TableCell>{t('tasks.employee')}</TableCell><TableCell align="right">{t('common.actions')}</TableCell></TableRow>
          </TableHead>
          <TableBody>
            {loading ? [...Array(3)].map((_, i) => (<TableRow key={i}>{[...Array(5)].map((_, j) => (<TableCell key={j}><Skeleton /></TableCell>))}</TableRow>))
              : items.length === 0 ? (<TableRow><TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>{t('tasks.noTasks')}</TableCell></TableRow>)
              : items.map((t) => (
                <TableRow key={t.id} hover>
                  <TableCell><strong>{t.taskName || '-'}</strong></TableCell>
                  <TableCell><Chip label={t.type || 'General'} size="small" variant="outlined" /></TableCell>
                  <TableCell>
                    {t.taskReminderDate ? (
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <ReminderIcon fontSize="small" color="warning" />
                        {new Date(t.taskReminderDate).toLocaleDateString()}
                      </Box>
                    ) : '-'}
                  </TableCell>
                  <TableCell>{t.employeeName || '-'}</TableCell>
                  <TableCell align="right"><Tooltip title={t('common.delete')}><IconButton color="error" onClick={() => remove(t.id)}><DeleteIcon /></IconButton></Tooltip></TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('tasks.newTask')}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label={t('tasks.taskName')} value={taskName} onChange={(e) => setTaskName(e.target.value)} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label={t('tasks.type')} value={type} onChange={(e) => setType(e.target.value)} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label={t('tasks.taskDate')} type="date" value={taskDate} onChange={(e) => setTaskDate(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label={t('tasks.reminder')} type="datetime-local" value={taskReminderDate} onChange={(e) => setTaskReminderDate(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
            <Grid size={{ xs: 12 }}>
              <FormControl fullWidth>
                <InputLabel>{t('tasks.employee')}</InputLabel>
                <Select value={employeeId} label={t('tasks.employee')} onChange={(e) => setEmployeeId(Number(e.target.value) || '')}>
                  <MenuItem value=""><em>{t('common.select')}</em></MenuItem>
                  {employees.map((emp) => (<MenuItem key={emp.id} value={emp.id}>#{emp.id} {emp.user?.fullName || ''}</MenuItem>))}
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12 }}><TextField fullWidth label={t('tasks.notes')} multiline rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} /></Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenDialog(false)}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={create} disabled={!taskName}>{t('common.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
