import React, { useEffect, useState } from 'react';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, Grid,
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, Event as EventIcon, Refresh as RefreshIcon, Gavel as GavelIcon,
} from '@mui/icons-material';
import api from '../services/api';

type Siting = { id: number; sitingTime?: string; sitingDate?: string; sitingNotification?: string; judgeName?: string; notes?: string };

export default function Sitings() {
  const [items, setItems] = useState<Siting[]>([]);
  const [loading, setLoading] = useState(false);
  const [sTime, setSTime] = useState('');
  const [sDate, setSDate] = useState('');
  const [sNotify, setSNotify] = useState('');
  const [judge, setJudge] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try { const r = await api.get('/Sitings'); setItems(r.data); }
    catch (err) { setSnackbar({ open: true, message: 'Failed to load', severity: 'error' }); }
    finally { setLoading(false); }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      await api.post('/Sitings', { sitingTime: sTime || undefined, sitingDate: sDate || undefined, sitingNotification: sNotify || undefined, judgeName: judge });
      setSTime(''); setSDate(''); setSNotify(''); setJudge('');
      setOpenDialog(false); await load();
      setSnackbar({ open: true, message: 'Siting created', severity: 'success' });
    } catch (e: any) { setSnackbar({ open: true, message: e?.response?.data?.message || 'Failed', severity: 'error' }); }
  }

  async function remove(id: number) {
    if (!confirm('Delete siting?')) return;
    try { await api.delete(`/Sitings/${id}`); await load(); setSnackbar({ open: true, message: 'Deleted', severity: 'success' }); }
    catch (err) { setSnackbar({ open: true, message: 'Failed to delete', severity: 'error' }); }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <EventIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>Sitings (Court Sessions)</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Refresh"><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>New Siting</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}><CardContent sx={{ py: 2 }}><Typography variant="body2" color="text.secondary">Total Sessions: <strong>{items.length}</strong></Typography></CardContent></Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>Date</TableCell><TableCell>Time</TableCell><TableCell>Notification</TableCell><TableCell>Judge</TableCell><TableCell align="right">Actions</TableCell></TableRow></TableHead>
          <TableBody>
            {loading ? [...Array(3)].map((_, i) => (<TableRow key={i}>{[...Array(5)].map((_, j) => (<TableCell key={j}><Skeleton /></TableCell>))}</TableRow>))
              : items.length === 0 ? (<TableRow><TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>No sitings found</TableCell></TableRow>)
              : items.map((s) => (
                <TableRow key={s.id} hover>
                  <TableCell><Chip icon={<EventIcon />} label={s.sitingDate?.slice(0, 10) || '-'} size="small" variant="outlined" /></TableCell>
                  <TableCell>{s.sitingTime?.slice(11, 16) || '-'}</TableCell>
                  <TableCell>{s.sitingNotification?.slice(0, 16) || '-'}</TableCell>
                  <TableCell><Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}><GavelIcon fontSize="small" color="action" />{s.judgeName || '-'}</Box></TableCell>
                  <TableCell align="right"><Tooltip title="Delete"><IconButton color="error" onClick={() => remove(s.id)}><DeleteIcon /></IconButton></Tooltip></TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New Siting</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label="Date" type="date" value={sDate} onChange={(e) => setSDate(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label="Time" type="datetime-local" value={sTime} onChange={(e) => setSTime(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label="Notification" type="datetime-local" value={sNotify} onChange={(e) => setSNotify(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
            <Grid size={{ xs: 12, sm: 6 }}><TextField fullWidth label="Judge Name" value={judge} onChange={(e) => setJudge(e.target.value)} /></Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={create}>Create</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
