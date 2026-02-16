"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, useTheme, FormControlLabel, Switch,
} from '@mui/material';
import {
  PersonSearch as PersonSearchIcon,
  Add as AddIcon, Delete as DeleteIcon, Edit as EditIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';

type ContenderDto = { id: number; fullName: string; ssn: string; birthDate: string; type?: boolean | null };

export default function ContendersPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const { isAuthenticated } = useAuth();

  const [items, setItems] = useState<ContenderDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [openDialog, setOpenDialog] = useState(false);
  const [editItem, setEditItem] = useState<ContenderDto | null>(null);
  const [form, setForm] = useState({ fullName: '', ssn: '', birthDate: '', type: false });
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const res = await api.get('/Contenders');
      setItems(res.data || []);
    } catch {
      setSnackbar({ open: true, message: t('contenders.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  function openCreate() {
    setEditItem(null);
    setForm({ fullName: '', ssn: '', birthDate: '', type: false });
    setOpenDialog(true);
  }

  function openEdit(item: ContenderDto) {
    setEditItem(item);
    setForm({ fullName: item.fullName, ssn: item.ssn, birthDate: item.birthDate || '', type: item.type ?? false });
    setOpenDialog(true);
  }

  async function handleSubmit() {
    try {
      if (editItem) {
        await api.put(`/Contenders/${editItem.id}`, form);
        setSnackbar({ open: true, message: t('contenders.updated'), severity: 'success' });
      } else {
        await api.post('/Contenders', form);
        setSnackbar({ open: true, message: t('contenders.created'), severity: 'success' });
      }
      setOpenDialog(false);
      load();
    } catch {
      setSnackbar({ open: true, message: editItem ? t('contenders.failedUpdate') : t('contenders.failedCreate'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('contenders.confirmDelete'))) return;
    try {
      await api.delete(`/Contenders/${id}`);
      setSnackbar({ open: true, message: t('contenders.deleted'), severity: 'success' });
      load();
    } catch {
      setSnackbar({ open: true, message: t('contenders.failedDelete'), severity: 'error' });
    }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box sx={{ bgcolor: 'primary.main', color: 'white', p: 1.5, borderRadius: 3, display: 'flex', boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)' }}>
            <PersonSearchIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>{t('contenders.management')}</Typography>
            <Typography variant="body2" color="text.secondary">{t('contenders.totalContenders')}: <strong>{items.length}</strong></Typography>
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
            {t('contenders.createNew')}
          </Button>
        </Box>
      </Box>

      {/* Table */}
      <Paper elevation={0} sx={{ borderRadius: 4, border: '1px solid', borderColor: 'divider', overflow: 'hidden', bgcolor: 'background.paper', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
        <TableContainer>
          <Table sx={{ minWidth: 650 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>ID</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('contenders.fullName')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('contenders.ssn')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('contenders.birthDate')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('contenders.type')}</TableCell>
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
                      <PersonSearchIcon sx={{ fontSize: 48, color: 'primary.main', opacity: 0.3, mb: 2 }} />
                      <Typography variant="h6" gutterBottom>{t('contenders.noContenders')}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={openCreate}>{t('contenders.createFirst')}</Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ) : items.map((item) => (
                <TableRow key={item.id} sx={{ '&:hover': { bgcolor: 'grey.50' }, transition: 'background 0.2s ease' }}>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}><Chip label={`#${item.id}`} size="small" variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} /></TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left', fontWeight: 600 }}>{item.fullName}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.ssn || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.birthDate || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                    <Chip label={item.type ? t('contenders.plaintiff') : t('contenders.defendant')} size="small" color={item.type ? 'success' : 'warning'} variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} />
                  </TableCell>
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
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: 3, p: 1 } }}>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {editItem ? t('common.edit') : t('contenders.createNew')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, mt: 2 }}>
            <TextField fullWidth label={t('contenders.fullName')} value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('contenders.ssn')} value={form.ssn} onChange={(e) => setForm({ ...form, ssn: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('contenders.birthDate')} type="date" value={form.birthDate} onChange={(e) => setForm({ ...form, birthDate: e.target.value })} InputLabelProps={{ shrink: true }} variant="outlined" />
            <FormControlLabel
              control={<Switch checked={form.type} onChange={(e) => setForm({ ...form, type: e.target.checked })} />}
              label={form.type ? t('contenders.plaintiff') : t('contenders.defendant')}
              sx={{ flexDirection: isRTL ? 'row-reverse' : 'row', ml: 0 }}
            />
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
