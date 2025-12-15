"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
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
import api from '../../src/services/api';
import { useRouter, useParams } from 'next/navigation';
import { useAuth } from '../../src/services/auth';

type UserDto = { id: number; fullName?: string; userName?: string };
type Customer = { id: number; usersId: number; user?: UserDto };

export default function CustomersPageClient() {
  const { t } = useTranslation();
  const theme = useTheme();
  const params = useParams() as { locale?: string } | undefined;
  const locale = params?.locale || 'ar';
  const isRTL = theme.direction === 'rtl' || locale.startsWith('ar');
  const router = useRouter();
  const { isAuthenticated } = useAuth();

  const [items, setItems] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(false);
  const [users, setUsers] = useState<UserDto[]>([]);
  const [selectedUser, setSelectedUser] = useState<number | ''>('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const [customersRes, usersRes] = await Promise.all([api.get('/Customers'), api.get('/LegacyUsers')]);
      setItems(customersRes.data || []);
      setUsers(usersRes.data || []);
    } catch (err) {
      setSnackbar({ open: true, message: t('customers.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

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

  const navigate = (path: string) => router.push(`/${locale}${path}`);

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <PeopleIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>{t('customers.management')}</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton>
          </Tooltip>
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>{t('customers.newCustomer')}</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}>
        <CardContent sx={{ py: 2 }}>
          <Typography variant="body2" color="text.secondary" sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('customers.totalCustomers')}: <strong>{items.length}</strong></Typography>
        </CardContent>
      </Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell>
              <TableCell>{t('customers.customer')}</TableCell>
              <TableCell>{t('customers.userId')}</TableCell>
              <TableCell align={isRTL ? 'left' : 'right'}>{t('cases.actions')}</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              [...Array(5)].map((_, i) => (
                <TableRow key={i}>{[...Array(4)].map((__, j) => <TableCell key={j}><Skeleton /></TableCell>)}</TableRow>
              ))
            ) : items.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} align="center" sx={{ py: 4 }}>
                  <Box sx={{ color: 'text.secondary' }}>
                    <PeopleIcon sx={{ fontSize: 48, opacity: 0.3, mb: 1 }} />
                    <Typography>{t('customers.noCustomers')}</Typography>
                    <Button variant="contained" size="small" sx={{ mt: 2 }} onClick={() => setOpenDialog(true)}>{t('customers.createFirst')}</Button>
                  </Box>
                </TableCell>
              </TableRow>
            ) : (
              items.map((item) => (
                <TableRow key={item.id} hover>
                  <TableCell><Chip label={`#${item.id}`} size="small" variant="outlined" /></TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.light' }}><PersonIcon fontSize="small" /></Avatar>
                      {item.user?.fullName || item.user?.userName || 'Unknown'}
                    </Box>
                  </TableCell>
                  <TableCell>{item.usersId}</TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Tooltip title={t('app.delete')}>
                      <IconButton color="error" onClick={() => remove(item.id)}><DeleteIcon /></IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('customers.createNew')}</DialogTitle>
        <DialogContent>
          <FormControl fullWidth sx={{ mt: 2 }}>
            <InputLabel>{t('customers.selectUser')}</InputLabel>
            <Select value={selectedUser} label={t('customers.selectUser')} onChange={(e) => setSelectedUser(Number(e.target.value) || '')}>
              <MenuItem value=""><em>-- Select a user --</em></MenuItem>
              {users.map((u) => (<MenuItem key={u.id} value={u.id}>{u.fullName || u.userName} (#{u.id})</MenuItem>))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions sx={{ p: 2, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenDialog(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={create} disabled={!selectedUser}>{t('app.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
