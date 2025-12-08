import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, Grid,
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, LocationCity as LocationCityIcon, Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../services/api';

type Gov = { id: number; govName?: string };

export default function Governments() {
  const { t } = useTranslation();
  const [items, setItems] = useState<Gov[]>([]);
  const [loading, setLoading] = useState(false);
  const [name, setName] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try { const r = await api.get('/Governments'); setItems(r.data); }
    catch (err) { setSnackbar({ open: true, message: t('governments.failedLoad'), severity: 'error' }); }
    finally { setLoading(false); }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      await api.post('/Governments', { govName: name });
      setName(''); setOpenDialog(false); await load();
      setSnackbar({ open: true, message: t('governments.created'), severity: 'success' });
    } catch (e: any) { setSnackbar({ open: true, message: e?.response?.data?.message || t('governments.failed'), severity: 'error' }); }
  }

  async function remove(id: number) {
    if (!confirm(t('governments.confirmDelete'))) return;
    try { await api.delete(`/Governments/${id}`); await load(); setSnackbar({ open: true, message: t('governments.deleted'), severity: 'success' }); }
    catch (err) { setSnackbar({ open: true, message: t('governments.failed'), severity: 'error' }); }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <LocationCityIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>{t('governments.management')}</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title={t('cases.refresh')}><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>{t('governments.newGovernment')}</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}><CardContent sx={{ py: 2 }}><Typography variant="body2" color="text.secondary">{t('governments.totalGovernments')}: <strong>{items.length}</strong></Typography></CardContent></Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>{t('common.id')}</TableCell><TableCell>{t('governments.name')}</TableCell><TableCell align="right">{t('common.actions')}</TableCell></TableRow></TableHead>
          <TableBody>
            {loading ? [...Array(3)].map((_, i) => (<TableRow key={i}>{[...Array(3)].map((_, j) => (<TableCell key={j}><Skeleton /></TableCell>))}</TableRow>))
              : items.length === 0 ? (<TableRow><TableCell colSpan={3} align="center" sx={{ py: 4, color: 'text.secondary' }}>{t('governments.noGovernments')}</TableCell></TableRow>)
              : items.map((g) => (
                <TableRow key={g.id} hover>
                  <TableCell><Chip label={`#${g.id}`} size="small" variant="outlined" /></TableCell>
                  <TableCell><strong>{g.govName || '-'}</strong></TableCell>
                  <TableCell align="right"><Tooltip title={t('common.delete')}><IconButton color="error" onClick={() => remove(g.id)}><DeleteIcon /></IconButton></Tooltip></TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('governments.newGovernment')}</DialogTitle>
        <DialogContent>
          <TextField fullWidth label={t('governments.name')} value={name} onChange={(e) => setName(e.target.value)} sx={{ mt: 2 }} />
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenDialog(false)}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={create} disabled={!name}>{t('common.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
