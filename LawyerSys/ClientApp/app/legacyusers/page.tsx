"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, useTheme,
} from '@mui/material';
import {
  Person as PersonIcon,
  Add as AddIcon, Delete as DeleteIcon, Edit as EditIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';

type LegacyUserDto = { id: number; fullName: string; address?: string; job: string; phoneNumber: string; dateOfBirth: string; ssn: string; userName: string };

export default function LegacyUsersPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const { isAuthenticated } = useAuth();

  const [items, setItems] = useState<LegacyUserDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [openDialog, setOpenDialog] = useState(false);
  const [editItem, setEditItem] = useState<LegacyUserDto | null>(null);
  const [form, setForm] = useState({ fullName: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '' });
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const res = await api.get('/LegacyUsers');
      setItems(res.data || []);
    } catch {
      setSnackbar({ open: true, message: t('legacyUsers.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  function openCreate() {
    setEditItem(null);
    setForm({ fullName: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '' });
    setOpenDialog(true);
  }

  function openEdit(item: LegacyUserDto) {
    setEditItem(item);
    setForm({ fullName: item.fullName, address: item.address || '', job: item.job, phoneNumber: item.phoneNumber, dateOfBirth: item.dateOfBirth?.substring(0, 10) || '', ssn: item.ssn, userName: item.userName, password: '' });
    setOpenDialog(true);
  }

  async function handleSubmit() {
    try {
      if (editItem) {
        await api.put(`/LegacyUsers/${editItem.id}`, { fullName: form.fullName, address: form.address, job: form.job, phoneNumber: form.phoneNumber, dateOfBirth: form.dateOfBirth, ssn: form.ssn });
        setSnackbar({ open: true, message: t('legacyUsers.updated'), severity: 'success' });
      } else {
        await api.post('/LegacyUsers', form);
        setSnackbar({ open: true, message: t('legacyUsers.created'), severity: 'success' });
      }
      setOpenDialog(false);
      load();
    } catch (err: any) {
      const msg = err?.response?.data?.message || (editItem ? t('legacyUsers.failedUpdate') : t('legacyUsers.failedCreate'));
      setSnackbar({ open: true, message: msg, severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('legacyUsers.confirmDelete'))) return;
    try {
      await api.delete(`/LegacyUsers/${id}`);
      setSnackbar({ open: true, message: t('legacyUsers.deleted'), severity: 'success' });
      load();
    } catch (err: any) {
      const msg = err?.response?.data?.message || t('legacyUsers.failedDelete');
      setSnackbar({ open: true, message: msg, severity: 'error' });
    }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box sx={{ bgcolor: 'primary.main', color: 'white', p: 1.5, borderRadius: 3, display: 'flex', boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)' }}>
            <PersonIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>{t('legacyUsers.management')}</Typography>
            <Typography variant="body2" color="text.secondary">{t('legacyUsers.totalUsers')}: <strong>{items.length}</strong></Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('common.refresh')}>
            <IconButton onClick={load} disabled={loading} sx={{ bgcolor: 'background.paper', border: '1px solid', borderColor: 'divider', '&:hover': { bgcolor: 'grey.50' } }}>
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Button variant="contained" startIcon={!isRTL ? <AddIcon /> : undefined} endIcon={isRTL ? <AddIcon /> : undefined} onClick={openCreate}
            sx={{ borderRadius: 2.5, px: 3, fontWeight: 700, boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)' }}>
            {t('legacyUsers.createNew')}
          </Button>
        </Box>
      </Box>

      {/* Table */}
      <Paper elevation={0} sx={{ borderRadius: 4, border: '1px solid', borderColor: 'divider', overflow: 'hidden', bgcolor: 'background.paper', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
        <TableContainer>
          <Table sx={{ minWidth: 750 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>ID</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('legacyUsers.fullName')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('legacyUsers.userName')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('legacyUsers.job')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('legacyUsers.phoneNumber')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5, fontWeight: 700 }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(6)].map((__, j) => <TableCell key={j}><Skeleton variant="text" /></TableCell>)}
                  </TableRow>
                ))
              ) : items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5 }}>
                      <PersonIcon sx={{ fontSize: 48, color: 'primary.main', opacity: 0.3, mb: 2 }} />
                      <Typography variant="h6" gutterBottom>{t('legacyUsers.noUsers')}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={openCreate}>{t('legacyUsers.createFirst')}</Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ) : items.map((item) => (
                <TableRow key={item.id} sx={{ '&:hover': { bgcolor: 'grey.50' }, transition: 'background 0.2s ease' }}>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}><Chip label={`#${item.id}`} size="small" variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} /></TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left', fontWeight: 600 }}>{item.fullName}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.userName || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.job || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.phoneNumber || '-'}</TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                    <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
                      <Tooltip title={t('common.edit')}>
                        <IconButton color="primary" onClick={() => openEdit(item)} sx={{ '&:hover': { bgcolor: 'primary.light', color: 'white' }, transition: 'all 0.2s ease' }}>
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title={t('common.delete')}>
                        <IconButton color="error" onClick={() => remove(item.id)} sx={{ '&:hover': { bgcolor: 'error.light', color: 'white' }, transition: 'all 0.2s ease' }}>
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Create/Edit Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: 3, p: 1 } }}>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {editItem ? t('common.edit') : t('legacyUsers.createNew')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2.5, mt: 2 }}>
            <TextField fullWidth label={t('legacyUsers.fullName')} value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} variant="outlined" />
            {!editItem && <TextField fullWidth label={t('legacyUsers.userName')} value={form.userName} onChange={(e) => setForm({ ...form, userName: e.target.value })} variant="outlined" />}
            {!editItem && <TextField fullWidth label={t('legacyUsers.password')} type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} variant="outlined" />}
            <TextField fullWidth label={t('legacyUsers.job')} value={form.job} onChange={(e) => setForm({ ...form, job: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('legacyUsers.phoneNumber')} value={form.phoneNumber} onChange={(e) => setForm({ ...form, phoneNumber: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('legacyUsers.ssn')} value={form.ssn} onChange={(e) => setForm({ ...form, ssn: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('legacyUsers.dateOfBirth')} type="date" value={form.dateOfBirth} onChange={(e) => setForm({ ...form, dateOfBirth: e.target.value })} InputLabelProps={{ shrink: true }} variant="outlined" />
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField fullWidth label={t('legacyUsers.address')} value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} variant="outlined" />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenDialog(false)} sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={handleSubmit} sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}>{editItem ? t('common.save') : t('common.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled" sx={{ borderRadius: 2, fontWeight: 600 }}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
