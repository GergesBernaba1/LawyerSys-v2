import React, { useEffect, useState } from 'react';
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
  const [items, setItems] = useState<Gov[]>([]);
  const [loading, setLoading] = useState(false);
  const [name, setName] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try { const r = await api.get('/Governments'); setItems(r.data); }
    catch (err) { setSnackbar({ open: true, message: 'Failed to load', severity: 'error' }); }
    finally { setLoading(false); }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      await api.post('/Governments', { govName: name });
      setName(''); setOpenDialog(false); await load();
      setSnackbar({ open: true, message: 'Government created', severity: 'success' });
    } catch (e: any) { setSnackbar({ open: true, message: e?.response?.data?.message || 'Failed', severity: 'error' }); }
  }

  async function remove(id: number) {
    if (!confirm('Delete government?')) return;
    try { await api.delete(`/Governments/${id}`); await load(); setSnackbar({ open: true, message: 'Deleted', severity: 'success' }); }
    catch (err) { setSnackbar({ open: true, message: 'Failed to delete', severity: 'error' }); }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <LocationCityIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>Governments Management</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Refresh"><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>New Government</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}><CardContent sx={{ py: 2 }}><Typography variant="body2" color="text.secondary">Total: <strong>{items.length}</strong></Typography></CardContent></Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead><TableRow><TableCell>ID</TableCell><TableCell>Name</TableCell><TableCell align="right">Actions</TableCell></TableRow></TableHead>
          <TableBody>
            {loading ? [...Array(3)].map((_, i) => (<TableRow key={i}>{[...Array(3)].map((_, j) => (<TableCell key={j}><Skeleton /></TableCell>))}</TableRow>))
              : items.length === 0 ? (<TableRow><TableCell colSpan={3} align="center" sx={{ py: 4, color: 'text.secondary' }}>No governments found</TableCell></TableRow>)
              : items.map((g) => (
                <TableRow key={g.id} hover>
                  <TableCell><Chip label={`#${g.id}`} size="small" variant="outlined" /></TableCell>
                  <TableCell><strong>{g.govName || '-'}</strong></TableCell>
                  <TableCell align="right"><Tooltip title="Delete"><IconButton color="error" onClick={() => remove(g.id)}><DeleteIcon /></IconButton></Tooltip></TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New Government</DialogTitle>
        <DialogContent>
          <TextField fullWidth label="Government Name" value={name} onChange={(e) => setName(e.target.value)} sx={{ mt: 2 }} />
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={create} disabled={!name}>Create</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
