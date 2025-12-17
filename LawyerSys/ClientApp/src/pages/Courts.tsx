import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Grid from '@mui/material/Grid'
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, FormControl, InputLabel, Select, MenuItem, useTheme
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

  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const [searchTerm, setSearchTerm] = useState('');

  const filteredItems = items.filter(c => 
    c.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.address?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.governmentName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 1600, margin: '0 auto' }}>
      {/* Header Section */}
      <Paper 
        elevation={0}
        sx={{ 
          p: { xs: 3, md: 5 }, 
          mb: 4, 
          borderRadius: 6, 
          background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
          color: 'white',
          position: 'relative',
          overflow: 'hidden',
          boxShadow: '0 20px 40px rgba(99, 102, 241, 0.2)'
        }}
      >
        <Box sx={{ position: 'relative', zIndex: 1, display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
            <Box sx={{ 
              width: 70, 
              height: 70, 
              borderRadius: 4, 
              bgcolor: 'rgba(255, 255, 255, 0.2)', 
              backdropFilter: 'blur(10px)',
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              border: '1px solid rgba(255, 255, 255, 0.3)'
            }}>
              <AccountBalanceIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('courts.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('courts.description', 'Manage court locations, contact details, and regional jurisdictions.')}
              </Typography>
            </Box>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Tooltip title={t('cases.refresh')}>
              <IconButton 
                onClick={load} 
                disabled={loading}
                sx={{ 
                  bgcolor: 'rgba(255, 255, 255, 0.1)',
                  color: 'white',
                  '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.2)' },
                  backdropFilter: 'blur(10px)',
                  width: 50,
                  height: 50
                }}
              >
                <RefreshIcon />
              </IconButton>
            </Tooltip>
            <Button 
              variant="contained" 
              startIcon={<AddIcon />} 
              onClick={() => setOpenDialog(true)}
              sx={{ 
                bgcolor: 'white',
                color: 'primary.main',
                '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.9)' },
                borderRadius: 3, 
                px: 4, 
                py: 1.5,
                fontWeight: 800,
                textTransform: 'none',
                boxShadow: '0 10px 20px rgba(0,0,0,0.1)'
              }}
            >
              {t('courts.newCourt')}
            </Button>
          </Box>
        </Box>
        
        {/* Decorative background elements */}
        <Box sx={{ position: 'absolute', top: -50, right: -50, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,255,255,0.1)', zIndex: 0 }} />
        <Box sx={{ position: 'absolute', bottom: -30, left: '20%', width: 120, height: 120, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', zIndex: 0 }} />
      </Paper>

      {/* Search Bar */}
      <Paper 
        elevation={0} 
        sx={{ 
          p: 2, 
          mb: 4, 
          borderRadius: 4, 
          border: '1px solid', 
          borderColor: 'divider',
          bgcolor: 'background.paper',
          display: 'flex',
          alignItems: 'center',
          gap: 2,
          boxShadow: '0 4px 20px rgba(0,0,0,0.02)'
        }}
      >
        <TextField
          fullWidth
          variant="outlined"
          placeholder={t('common.search')}
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          slotProps={{
            input: {
              startAdornment: <AccountBalanceIcon sx={{ color: 'text.disabled', mr: 1 }} />,
              sx: { borderRadius: 3, bgcolor: 'grey.50' }
            }
          }}
        />
      </Paper>

      {/* Table Section */}
      <Paper 
        elevation={0} 
        sx={{ 
          borderRadius: 5, 
          overflow: 'hidden', 
          border: '1px solid', 
          borderColor: 'divider',
          boxShadow: '0 10px 30px rgba(0,0,0,0.04)'
        }}
      >
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.50' }}>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('courts.name')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('courts.address')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('courts.telephone')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('courts.government')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(5)].map((_, j) => (
                      <TableCell key={j} sx={{ py: 2.5 }}><Skeleton variant="text" height={24} /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : filteredItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                    <Box sx={{ opacity: 0.5, mb: 2 }}>
                      <AccountBalanceIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('courts.noCourts')}</Typography>
                  </TableCell>
                </TableRow>
              ) : filteredItems.map((c) => (
                <TableRow key={c.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                  <TableCell sx={{ py: 2.5 }}>
                    <Typography variant="body1" fontWeight={700} color="primary.main">
                      {c.name || '-'}
                    </Typography>
                  </TableCell>
                  <TableCell sx={{ fontWeight: 600, color: 'text.secondary' }}>{c.address || '-'}</TableCell>
                  <TableCell sx={{ fontWeight: 600, color: 'text.secondary' }}>{c.telephone || '-'}</TableCell>
                  <TableCell>
                    <Chip 
                      label={c.governmentName || 'N/A'} 
                      size="small" 
                      sx={{ 
                        borderRadius: 2, 
                        fontWeight: 700,
                        bgcolor: 'primary.50',
                        color: 'primary.dark',
                        border: '1px solid',
                        borderColor: 'primary.100',
                        px: 1
                      }} 
                    />
                  </TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Tooltip title={t('common.delete')}>
                      <IconButton 
                        color="error" 
                        onClick={() => remove(c.id)}
                        sx={{ 
                          bgcolor: 'error.50',
                          '&:hover': { bgcolor: 'error.100', transform: 'scale(1.1)' },
                          transition: 'all 0.2s'
                        }}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Create Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{
          sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' }
        }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('courts.newCourt')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4, fontWeight: 500 }}>
            {t('courts.addDescription', 'Enter the details of the new court below.')}
          </Typography>
          <Grid container spacing={3}>
            <Grid size={{ xs: 12 }}>
              <TextField 
                fullWidth 
                label={t('courts.name')} 
                value={name} 
                onChange={e => setName(e.target.value)}
                variant="outlined"
                slotProps={{ input: { sx: { borderRadius: 3 } } }}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField 
                fullWidth 
                label={t('courts.address')} 
                value={address} 
                onChange={e => setAddress(e.target.value)}
                variant="outlined"
                slotProps={{ input: { sx: { borderRadius: 3 } } }}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField 
                fullWidth 
                label={t('courts.telephone')} 
                value={telephone} 
                onChange={e => setTelephone(e.target.value)}
                variant="outlined"
                slotProps={{ input: { sx: { borderRadius: 3 } } }}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <FormControl fullWidth>
                <InputLabel sx={{ fontWeight: 600 }}>{t('courts.government')}</InputLabel>
                <Select 
                  value={govId} 
                  label={t('courts.government')} 
                  onChange={e => setGovId(Number(e.target.value) || '')}
                  sx={{ borderRadius: 3 }}
                >
                  <MenuItem value="" sx={{ fontWeight: 500 }}><em>{t('common.select')}</em></MenuItem>
                  {govs.map((g) => (<MenuItem key={g.id} value={g.id} sx={{ fontWeight: 500 }}>{g.govName}</MenuItem>))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 4, pt: 2, gap: 1 }}>
          <Button 
            onClick={() => setOpenDialog(false)}
            sx={{ borderRadius: 3, px: 3, fontWeight: 700, color: 'text.secondary' }}
          >
            {t('common.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={create} 
            disabled={!name}
            sx={{ 
              borderRadius: 3, 
              px: 5, 
              py: 1.5,
              fontWeight: 800,
              boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
            }}
          >
            {t('common.create')}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={4000} 
        onClose={() => setSnackbar({ ...snackbar, open: false })} 
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity} 
          variant="filled"
          sx={{ borderRadius: 3, boxShadow: '0 10px 20px rgba(0,0,0,0.1)', fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );

      {/* Create Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{
          sx: { borderRadius: 3, p: 1 }
        }}
      >
        <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>{t('courts.newCourt')}</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
            {t('courts.addDescription', 'Enter the details of the new court below.')}
          </Typography>
          <Grid container spacing={2.5}>
            <Grid size={{ xs: 12 }}>
              <TextField 
                fullWidth 
                label={t('courts.name')} 
                value={name} 
                onChange={e => setName(e.target.value)}
                variant="outlined"
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField 
                fullWidth 
                label={t('courts.address')} 
                value={address} 
                onChange={e => setAddress(e.target.value)}
                variant="outlined"
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField 
                fullWidth 
                label={t('courts.telephone')} 
                value={telephone} 
                onChange={e => setTelephone(e.target.value)}
                variant="outlined"
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <FormControl fullWidth>
                <InputLabel>{t('courts.government')}</InputLabel>
                <Select 
                  value={govId} 
                  label={t('courts.government')} 
                  onChange={e => setGovId(Number(e.target.value) || '')}
                >
                  <MenuItem value=""><em>{t('common.select')}</em></MenuItem>
                  {govs.map((g) => (<MenuItem key={g.id} value={g.id}>{g.govName}</MenuItem>))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1 }}>
          <Button 
            onClick={() => setOpenDialog(false)}
            sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}
          >
            {t('common.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={create} 
            disabled={!name}
            sx={{ borderRadius: 2, px: 4, fontWeight: 600 }}
          >
            {t('common.create')}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={4000} 
        onClose={() => setSnackbar({ ...snackbar, open: false })} 
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity} 
          variant="filled"
          sx={{ borderRadius: 2, boxShadow: 3 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
