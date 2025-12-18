import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Typography,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Paper,
  IconButton,
  Skeleton,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Snackbar,
  Tooltip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Avatar,
  useTheme,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  People as PeopleIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import api from '../services/api';

type UserDto = { id: number; fullName?: string; userName?: string };
type Customer = { id: number; usersId: number; user?: UserDto };

export default function Customers() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const [items, setItems] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(false);
  const [users, setUsers] = useState<UserDto[]>([]);
  const [selectedUser, setSelectedUser] = useState<number | ''>('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  async function load() {
    setLoading(true);
    try {
      const [customersRes, usersRes] = await Promise.all([
        api.get('/Customers'),
        api.get('/LegacyUsers'),
      ]);
      setItems(customersRes.data || []);
      setUsers(usersRes.data || []);
    } catch (err) {
      setSnackbar({ open: true, message: t('customers.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function create() {
    if (!selectedUser) {
      setSnackbar({ open: true, message: t('customers.pleaseSelectUser'), severity: 'error' });
      return;
    }
    try {
      await api.post('/Customers', { usersId: selectedUser });
      await load();
      setSelectedUser('');
      setOpenDialog(false);
      setSnackbar({ open: true, message: t('customers.customerCreated'), severity: 'success' });
    } catch (err: any) {
      setSnackbar({ open: true, message: err?.response?.data?.message ?? t('customers.failedCreate'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('customers.confirmDelete'))) return;
    try {
      await api.delete(`/Customers/${id}`);
      await load();
      setSnackbar({ open: true, message: t('customers.customerDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('customers.failedDelete'), severity: 'error' });
    }
  }

  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const filteredItems = items.filter(item => 
    item.user?.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.user?.userName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.id.toString().includes(searchTerm)
  );

  // Reset page when filter changes
  React.useEffect(() => { setPage(0); }, [searchTerm, items]);

  const pageItems = filteredItems.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);
  const handleChangePage = (_event: any, newPage: number) => setPage(newPage);
  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => { setRowsPerPage(parseInt(event.target.value, 10)); setPage(0); };

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
              <PeopleIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('customers.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('customers.description', 'Manage your client base and link them to system users.')}
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
              {t('customers.newCustomer')}
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
              startAdornment: <PeopleIcon sx={{ color: 'text.disabled', mr: 1 }} />,
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
        <TableContainer sx={{ maxHeight: '60vh', overflow: 'auto' }}>
          <Table stickyHeader>
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.50' }}>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('common.id')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('customers.customer')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('customers.userId')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                [...Array(rowsPerPage)].map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(4)].map((_, j) => (
                      <TableCell key={j} sx={{ py: 2.5 }}><Skeleton variant="text" height={24} /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : filteredItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center" sx={{ py: 12 }}>
                    <Box sx={{ opacity: 0.5, mb: 2 }}>
                      <PeopleIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('customers.noCustomers')}</Typography>
                  </TableCell>
                </TableRow>
              ) : (
                pageItems.map((item) => (
                  <TableRow key={item.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                    <TableCell sx={{ py: 2.5 }}>
                      <Chip 
                        label={`#${item.id}`} 
                        size="small" 
                        sx={{ 
                          borderRadius: 2, 
                          fontWeight: 800,
                          bgcolor: 'grey.100',
                          color: 'text.primary',
                          border: '1px solid',
                          borderColor: 'grey.200',
                          px: 1
                        }} 
                      />
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32, fontSize: '0.875rem', fontWeight: 700 }}>
                          {item.user?.fullName?.charAt(0) || <PersonIcon />}
                        </Avatar>
                        <Typography variant="body1" fontWeight={700} color="primary.main">
                          {item.user?.fullName || item.user?.userName || 'Unknown'}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip 
                        label={item.usersId} 
                        size="small" 
                        sx={{ 
                          fontWeight: 700, 
                          bgcolor: 'primary.50', 
                          color: 'primary.main',
                          borderRadius: 1.5
                        }} 
                      />
                    </TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'}>
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
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          component="div"
          count={filteredItems.length}
          page={page}
          onPageChange={handleChangePage}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          rowsPerPageOptions={[5,10,25,50]}
        />
      </Paper>

      {/* Create Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth 
        PaperProps={{ sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('customers.newCustomer')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4, fontWeight: 500 }}>
            {t('customers.addDescription', 'Select a user to register as a customer.')}
          </Typography>
          <FormControl fullWidth variant="outlined">
            <InputLabel>{t('customers.selectUser')}</InputLabel>
            <Select
              value={selectedUser}
              onChange={(e) => setSelectedUser(Number(e.target.value) || '')}
              label={t('customers.selectUser')}
              sx={{ borderRadius: 3 }}
            >
              {users.map((u) => (
                <MenuItem key={u.id} value={u.id}>
                  {u.fullName} (@{u.userName})
                </MenuItem>
              ))}
            </Select>
          </FormControl>
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
            disabled={!selectedUser}
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
