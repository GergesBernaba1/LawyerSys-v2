import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, FormControl, InputLabel, Select, MenuItem, Grid,
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, AccountBalance as AccountBalanceIcon, Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../services/api';

type Court = { id: number; name?: string; address?: string; telephone?: string; notes?: string; govId?: number; governmentName?: string };

export default function Courts() {
  const { t } = useTranslation();
  const [items, setItems] = useState<Court[]>([]);
  const [loading, setLoading] = useState(false);
  const [name, setName] = useState('');
  const [address, setAddress] = useState('');
  const [telephone, setTelephone] = useState('');
  const [govId, setGovId] = useState<number | ''>('');
  const [govs, setGovs] = useState<{ id: number; govName?: string }[]>([]);
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const [r, gg] = await Promise.all([api.get('/Courts'), api.get('/Governments')]);
      setItems(r.data);
      setGovs(gg.data);
    } catch (err) {
      setSnackbar({ open: true, message: t('courts.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      await api.post('/Courts', { name, address, telephone, govId: govId || undefined });
      setName(''); setAddress(''); setTelephone(''); setGovId('');
      setOpenDialog(false);
      await load();
      setSnackbar({ open: true, message: t('courts.created'), severity: 'success' });
    } catch (e: any) {
      setSnackbar({ open: true, message: e?.response?.data?.message || t('courts.failed'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('courts.confirmDelete'))) return;
    try {
      await api.delete(`/Courts/${id}`);
      await load();
      setSnackbar({ open: true, message: t('courts.deleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('courts.failed'), severity: 'error' });
    }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <AccountBalanceIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>{t('courts.management')}</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title={t('cases.refresh')}><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>{t('courts.newCourt')}</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}><CardContent sx={{ py: 2 }}><Typography variant="body2" color="text.secondary">{t('courts.totalCourts')}: <strong>{items.length}</strong></Typography></CardContent></Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>{t('courts.name')}</TableCell><TableCell>{t('courts.address')}</TableCell><TableCell>{t('courts.telephone')}</TableCell><TableCell>{t('courts.government')}</TableCell><TableCell align="right">{t('common.actions')}</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? [...Array(3)].map((_, i) => (<TableRow key={i}>{[...Array(5)].map((_, j) => (<TableCell key={j}><Skeleton /></TableCell>))}</TableRow>))
              : items.length === 0 ? (
                <TableRow><TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>{t('courts.noCourts')}</TableCell></TableRow>
              ) : items.map((c) => (
                <TableRow key={c.id} hover>
                  <TableCell><strong>{c.name || '-'}</strong></TableCell>
                  <TableCell>{c.address || '-'}</TableCell>
                  <TableCell>{c.telephone || '-'}</TableCell>
                  <TableCell><Chip label={c.governmentName || 'N/A'} size="small" variant="outlined" /></TableCell>
                  <TableCell align="right"><Tooltip title={t('common.delete')}><IconButton color="error" onClick={() => remove(c.id)}><DeleteIcon /></IconButton></Tooltip></TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('courts.newCourt')}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12 }}><TextField fullWidth label={t('courts.name')} value={name} onChange={e => setName(e.target.value)} /></Grid>
            <Grid size={{ xs: 12 }}><TextField fullWidth label={t('courts.address')} value={address} onChange={e => setAddress(e.target.value)} /></Grid>
            <Grid size={{ xs: 12 }}><TextField fullWidth label={t('courts.telephone')} value={telephone} onChange={e => setTelephone(e.target.value)} /></Grid>
            <Grid size={{ xs: 12 }}>
              <FormControl fullWidth>
                <InputLabel>{t('courts.government')}</InputLabel>
                <Select value={govId} label={t('courts.government')} onChange={e => setGovId(Number(e.target.value) || '')}>
                  <MenuItem value=""><em>{t('common.select')}</em></MenuItem>
                  {govs.map((g) => (<MenuItem key={g.id} value={g.id}>{g.govName}</MenuItem>))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
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
