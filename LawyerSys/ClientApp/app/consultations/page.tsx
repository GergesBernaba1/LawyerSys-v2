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
  Chat as ChatIcon,
  Add as AddIcon, Delete as DeleteIcon, Edit as EditIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';

type ConsultationDto = { id: number; consultionState: string; type: string; subject: string; description: string; feedback: string; notes: string; dateTime: string };

export default function ConsultationsPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const { isAuthenticated } = useAuth();

  const [items, setItems] = useState<ConsultationDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [openDialog, setOpenDialog] = useState(false);
  const [editItem, setEditItem] = useState<ConsultationDto | null>(null);
  const [form, setForm] = useState({ consultionState: '', type: '', subject: '', description: '', feedback: '', notes: '', dateTime: '' });
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const res = await api.get('/Consulations');
      setItems(res.data || []);
    } catch {
      setSnackbar({ open: true, message: t('consultations.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  function openCreate() {
    setEditItem(null);
    setForm({ consultionState: '', type: '', subject: '', description: '', feedback: '', notes: '', dateTime: '' });
    setOpenDialog(true);
  }

  function openEdit(item: ConsultationDto) {
    setEditItem(item);
    setForm({
      consultionState: item.consultionState,
      type: item.type,
      subject: item.subject,
      description: item.description,
      feedback: item.feedback,
      notes: item.notes,
      dateTime: item.dateTime ? new Date(item.dateTime).toISOString().substring(0, 16) : '',
    });
    setOpenDialog(true);
  }

  async function handleSubmit() {
    try {
      const payload = {
        ...form,
        dateTime: form.dateTime ? new Date(form.dateTime).toISOString() : new Date().toISOString(),
      };
      if (editItem) {
        await api.put(`/Consulations/${editItem.id}`, payload);
        setSnackbar({ open: true, message: t('consultations.updated'), severity: 'success' });
      } else {
        await api.post('/Consulations', payload);
        setSnackbar({ open: true, message: t('consultations.created'), severity: 'success' });
      }
      setOpenDialog(false);
      load();
    } catch {
      setSnackbar({ open: true, message: editItem ? t('consultations.failedUpdate') : t('consultations.failedCreate'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('consultations.confirmDelete'))) return;
    try {
      await api.delete(`/Consulations/${id}`);
      setSnackbar({ open: true, message: t('consultations.deleted'), severity: 'success' });
      load();
    } catch {
      setSnackbar({ open: true, message: t('consultations.failedDelete'), severity: 'error' });
    }
  }

  function formatDate(d: string) {
    if (!d) return '-';
    try { return new Date(d).toLocaleString(); } catch { return d; }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box sx={{ bgcolor: 'primary.main', color: 'white', p: 1.5, borderRadius: 3, display: 'flex', boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)' }}>
            <ChatIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>{t('consultations.management')}</Typography>
            <Typography variant="body2" color="text.secondary">{t('consultations.totalConsultations')}: <strong>{items.length}</strong></Typography>
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
            {t('consultations.createNew')}
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
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('consultations.subject')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('consultations.type')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('consultations.state')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('consultations.dateTime')}</TableCell>
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
                      <ChatIcon sx={{ fontSize: 48, color: 'primary.main', opacity: 0.3, mb: 2 }} />
                      <Typography variant="h6" gutterBottom>{t('consultations.noConsultations')}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={openCreate}>{t('consultations.createFirst')}</Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ) : items.map((item) => (
                <TableRow key={item.id} sx={{ '&:hover': { bgcolor: 'grey.50' }, transition: 'background 0.2s ease' }}>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}><Chip label={`#${item.id}`} size="small" variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} /></TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left', fontWeight: 600 }}>{item.subject || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.type || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                    <Chip label={item.consultionState || '-'} size="small" color="info" variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} />
                  </TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{formatDate(item.dateTime)}</TableCell>
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
          {editItem ? t('common.edit') : t('consultations.createNew')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2.5, mt: 2 }}>
            <TextField fullWidth label={t('consultations.subject')} value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('consultations.type')} value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('consultations.state')} value={form.consultionState} onChange={(e) => setForm({ ...form, consultionState: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('consultations.dateTime')} type="datetime-local" value={form.dateTime} onChange={(e) => setForm({ ...form, dateTime: e.target.value })} InputLabelProps={{ shrink: true }} variant="outlined" />
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField fullWidth label={t('consultations.description')} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} variant="outlined" multiline rows={3} />
            </Box>
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField fullWidth label={t('consultations.feedback')} value={form.feedback} onChange={(e) => setForm({ ...form, feedback: e.target.value })} variant="outlined" multiline rows={2} />
            </Box>
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField fullWidth label={t('consultations.notes')} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} variant="outlined" multiline rows={2} />
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
