import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Grid from '@mui/material/Grid'
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, TablePagination, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, FormControlLabel, Checkbox, useTheme
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

  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const filteredItems = items.filter(c => 
    c.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.ssn?.includes(searchTerm)
  );
  React.useEffect(() => { setPage(0); }, [searchTerm, items]);
  const pageItems = filteredItems.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);
  const handleChangePage = (_: any, newPage: number) => setPage(newPage);
  const handleChangeRowsPerPage = (e: React.ChangeEvent<HTMLInputElement>) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }; 

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
              <PersonSearchIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('contenders.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('contenders.description', 'Manage and track all contenders involved in legal cases.')}
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
              {t('contenders.newContender')}
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
              startAdornment: <PersonSearchIcon sx={{ color: 'text.disabled', mr: 1 }} />,
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
        <TableContainer component={Paper} sx={{ maxHeight: 520 }}>
          <Table stickyHeader>
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.50' }}>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('contenders.fullName')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('contenders.ssn')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('contenders.birthDate')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('contenders.type')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                [...Array(rowsPerPage)].map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(5)].map((_, j) => (
                      <TableCell key={j} sx={{ py: 2.5 }}><Skeleton variant="text" height={24} /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : pageItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                    <Box sx={{ opacity: 0.5, mb: 2 }}>
                      <PersonSearchIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('contenders.noContenders')}</Typography>
                  </TableCell>
                </TableRow>
              ) : pageItems.map((c) => (
                <TableRow key={c.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                  <TableCell sx={{ py: 2.5 }}>
                    <Typography variant="body1" fontWeight={700} color="primary.main">
                      {c.fullName || '-'}
                    </Typography>
                  </TableCell>
                  <TableCell sx={{ fontWeight: 600, color: 'text.secondary' }}>{c.ssn || '-'}</TableCell>
                  <TableCell sx={{ fontWeight: 600, color: 'text.secondary' }}>{c.birthDate?.slice(0, 10) || '-'}</TableCell>
                  <TableCell>
                    <Chip 
                      label={c.type ? t('common.yes', 'Yes') : t('common.no', 'No')} 
                      size="small" 
                      color={c.type ? 'success' : 'default'}
                      sx={{ borderRadius: 2, fontWeight: 700, px: 1 }}
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
          <TablePagination
            rowsPerPageOptions={[5,10,25]}
            component="div"
            count={filteredItems.length}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
          />
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
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('contenders.newContender')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4, fontWeight: 500 }}>
            {t('contenders.addDescription', 'Enter the details of the new contender below.')}
          </Typography>
          <Grid container spacing={3}>
            <Grid size={{ xs: 12 }}>
              <TextField 
                fullWidth 
                label={t('contenders.fullName')} 
                value={fullName} 
                onChange={(e) => setFullName(e.target.value)} 
                variant="outlined"
                slotProps={{ input: { sx: { borderRadius: 3 } } }}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField 
                fullWidth 
                label={t('contenders.ssn')} 
                value={ssn} 
                onChange={(e) => setSsn(e.target.value)} 
                variant="outlined"
                slotProps={{ input: { sx: { borderRadius: 3 } } }}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField 
                fullWidth 
                label={t('contenders.birthDate')} 
                type="date" 
                value={birthDate} 
                onChange={(e) => setBirthDate(e.target.value)} 
                slotProps={{ inputLabel: { shrink: true }, input: { sx: { borderRadius: 3 } } }}
                variant="outlined"
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <Box sx={{ 
                p: 2, 
                borderRadius: 3, 
                bgcolor: 'grey.50', 
                border: '1px solid', 
                borderColor: 'divider' 
              }}>
                <FormControlLabel 
                  control={
                    <Checkbox 
                      checked={ctype} 
                      onChange={(e) => setCtype(e.target.checked)} 
                      color="primary"
                    />
                  } 
                  label={<Typography fontWeight={600}>{t('contenders.type')}</Typography>} 
                />
              </Box>
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
            disabled={!fullName}
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
}
