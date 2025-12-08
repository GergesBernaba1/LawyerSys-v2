import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, Grid, FormControlLabel, Checkbox,
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, PersonSearch as PersonSearchIcon, Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../services/api';

type Contender = { id: number; fullName?: string; ssn?: string; birthDate?: string; type?: boolean };

export default function Contenders() {
  const { t } = useTranslation();
  const [items, setItems] = useState<Contender[]>([]);
  const [loading, setLoading] = useState(false);
  const [fullName, setFullName] = useState('');
  const [ssn, setSsn] = useState('');
  const [birthDate, setBirthDate] = useState('');
  const [ctype, setCtype] = useState(false);
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try { const r = await api.get('/Contenders'); setItems(r.data); }
    catch (err) { setSnackbar({ open: true, message: t('contenders.failedLoad'), severity: 'error' }); }
    finally { setLoading(false); }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      await api.post('/Contenders', { fullName, ssn, birthDate: birthDate || undefined, type: ctype });
      setFullName(''); setSsn(''); setBirthDate(''); setCtype(false);
      setOpenDialog(false); await load();
      setSnackbar({ open: true, message: t('contenders.created'), severity: 'success' });
    } catch (e: any) { setSnackbar({ open: true, message: e?.response?.data?.message || t('contenders.failed'), severity: 'error' }); }
  }

  async function remove(id: number) {
    if (!confirm(t('contenders.confirmDelete'))) return;
    try { await api.delete(`/Contenders/${id}`); await load(); setSnackbar({ open: true, message: t('contenders.deleted'), severity: 'success' }); }
    catch (err) { setSnackbar({ open: true, message: t('contenders.failed'), severity: 'error' }); }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <PersonSearchIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>{t('contenders.management')}</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title={t('cases.refresh')}><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>{t('contenders.newContender')}</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}><CardContent sx={{ py: 2 }}><Typography variant="body2" color="text.secondary">{t('contenders.totalContenders')}: <strong>{items.length}</strong></Typography></CardContent></Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>{t('contenders.fullName')}</TableCell><TableCell>{t('contenders.ssn')}</TableCell><TableCell>{t('contenders.birthDate')}</TableCell><TableCell>{t('contenders.type')}</TableCell><TableCell align="right">{t('common.actions')}</TableCell></TableRow></TableHead>
          <TableBody>
            {loading ? [...Array(3)].map((_, i) => (<TableRow key={i}>{[...Array(5)].map((_, j) => (<TableCell key={j}><Skeleton /></TableCell>))}</TableRow>))
              : items.length === 0 ? (<TableRow><TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>{t('contenders.noContenders')}</TableCell></TableRow>)
              : items.map((c) => (
                <TableRow key={c.id} hover>
                  <TableCell><strong>{c.fullName || '-'}</strong></TableCell>
                  <TableCell>{c.ssn || '-'}</TableCell>
                  <TableCell>{c.birthDate?.slice(0, 10) || '-'}</TableCell>
                  <TableCell><Chip label={c.type ? 'Yes' : 'No'} size="small" color={c.type ? 'success' : 'default'} /></TableCell>
                  <TableCell align="right"><Tooltip title={t('common.delete')}><IconButton color="error" onClick={() => remove(c.id)}><DeleteIcon /></IconButton></Tooltip></TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('contenders.newContender')}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12 }}><TextField fullWidth label={t('contenders.fullName')} value={fullName} onChange={(e) => setFullName(e.target.value)} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label={t('contenders.ssn')} value={ssn} onChange={(e) => setSsn(e.target.value)} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label={t('contenders.birthDate')} type="date" value={birthDate} onChange={(e) => setBirthDate(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
            <Grid size={{ xs: 12 }}><FormControlLabel control={<Checkbox checked={ctype} onChange={(e) => setCtype(e.target.checked)} />} label={t('contenders.type')} /></Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenDialog(false)}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={create} disabled={!fullName}>{t('common.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
