import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, useTheme, alpha, Avatar, Grid
} from '@mui/material';
import {
  Add as AddIcon, 
  Delete as DeleteIcon, 
  Event as EventIcon, 
  Refresh as RefreshIcon, 
  Gavel as GavelIcon,
  Search as SearchIcon,
  FilterList as FilterListIcon,
  AccessTime as TimeIcon,
  Notifications as NotificationsIcon
} from '@mui/icons-material';
import api from '../services/api';

type Siting = { id: number; sitingTime?: string; sitingDate?: string; sitingNotification?: string; judgeName?: string; notes?: string };

export default function Sitings() {
  const { t } = useTranslation();
  const [items, setItems] = useState<Siting[]>([]);
  const [loading, setLoading] = useState(false);
  const [sTime, setSTime] = useState('');
  const [sDate, setSDate] = useState('');
  const [sNotify, setSNotify] = useState('');
  const [judge, setJudge] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try { const r = await api.get('/Sitings'); setItems(r.data); }
    catch (err) { setSnackbar({ open: true, message: t('sitings.failedLoad'), severity: 'error' }); }
    finally { setLoading(false); }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      await api.post('/Sitings', { sitingTime: sTime || undefined, sitingDate: sDate || undefined, sitingNotification: sNotify || undefined, judgeName: judge });
      setSTime(''); setSDate(''); setSNotify(''); setJudge('');
      setOpenDialog(false); await load();
      setSnackbar({ open: true, message: t('sitings.created'), severity: 'success' });
    } catch (e: any) { setSnackbar({ open: true, message: e?.response?.data?.message || t('sitings.failed'), severity: 'error' }); }
  }

  async function remove(id: number) {
    if (!confirm(t('sitings.confirmDelete'))) return;
    try { await api.delete(`/Sitings/${id}`); await load(); setSnackbar({ open: true, message: t('sitings.deleted'), severity: 'success' }); }
    catch (err) { setSnackbar({ open: true, message: t('sitings.failed'), severity: 'error' }); }
  }

  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const filteredItems = items.filter(item => 
    item.judgeName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    item.sitingDate?.includes(searchQuery)
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
              <EventIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('sitings.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('sitings.subtitle', 'Manage and track court sitings, hearings, and judicial notifications.')}
              </Typography>
            </Box>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Tooltip title={t('common.refresh')}>
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
              {t('sitings.newSiting')}
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
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          slotProps={{
            input: {
              startAdornment: <SearchIcon sx={{ color: 'text.disabled', mr: 1 }} />,
              sx: { borderRadius: 3, bgcolor: 'grey.50' }
            }
          }}
        />
        <Button 
          startIcon={<FilterListIcon />} 
          sx={{ 
            fontWeight: 700, 
            borderRadius: 3, 
            px: 3,
            bgcolor: 'grey.50',
            color: 'text.secondary',
            '&:hover': { bgcolor: 'grey.100' }
          }}
        >
          {t('common.filter')}
        </Button>
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
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('sitings.date')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('sitings.time')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('sitings.notification')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('sitings.judge')}</TableCell>
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
                      <EventIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('common.noData')}</Typography>
                  </TableCell>
                </TableRow>
              ) : filteredItems.map((item) => (
                <TableRow key={item.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                  <TableCell sx={{ py: 2.5 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Box sx={{ 
                        width: 40, 
                        height: 40, 
                        borderRadius: 2, 
                        bgcolor: 'primary.50', 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center',
                        color: 'primary.main'
                      }}>
                        <EventIcon fontSize="small" />
                      </Box>
                      <Typography variant="body1" fontWeight={700} color="text.primary">
                        {item.sitingDate ? new Date(item.sitingDate).toLocaleDateString() : '-'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, color: 'text.secondary' }}>
                      <TimeIcon sx={{ fontSize: 18, opacity: 0.7 }} />
                      <Typography variant="body2" fontWeight={600}>
                        {item.sitingTime ? new Date(item.sitingTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, color: 'text.secondary' }}>
                      <NotificationsIcon sx={{ fontSize: 18, opacity: 0.7 }} />
                      <Typography variant="body2" fontWeight={500}>
                        {item.sitingNotification ? new Date(item.sitingNotification).toLocaleString() : '-'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <GavelIcon sx={{ fontSize: 18, color: 'primary.main' }} />
                      <Typography variant="body2" fontWeight={700}>{item.judgeName || '-'}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', gap: 1 }}>
                      <Tooltip title={t('common.delete')}>
                        <IconButton 
                          color="error" 
                          onClick={() => remove(item.id)}
                          sx={{ 
                            bgcolor: 'error.50',
                            '&:hover': { bgcolor: 'error.100', transform: 'scale(1.1)' },
                            transition: 'all 0.2s'
                          }}
                        >
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

      {/* Add Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{ sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('sitings.newSiting')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Grid container spacing={3} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth 
                label={t('sitings.date')} 
                type="date" 
                value={sDate} 
                onChange={(e) => setSDate(e.target.value)} 
                InputLabelProps={{ shrink: true }} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth 
                label={t('sitings.time')} 
                type="datetime-local" 
                value={sTime} 
                onChange={(e) => setSTime(e.target.value)} 
                InputLabelProps={{ shrink: true }} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth 
                label={t('sitings.notification')} 
                type="datetime-local" 
                value={sNotify} 
                onChange={(e) => setSNotify(e.target.value)} 
                InputLabelProps={{ shrink: true }} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth 
                label={t('sitings.judge')} 
                value={judge} 
                onChange={(e) => setJudge(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
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
            onClick={create} 
            variant="contained" 
            sx={{ 
              borderRadius: 3, 
              px: 5, 
              py: 1.5,
              fontWeight: 800,
              boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
            }}
          >
            {t('common.save')}
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
  );;
}
