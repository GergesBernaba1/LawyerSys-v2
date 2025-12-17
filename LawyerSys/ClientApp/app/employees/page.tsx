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
  TextField,
  Avatar,
  // Grid2: will import from Unstable_Grid2 below
  useTheme,
} from '@mui/material';
import Grid from '@mui/material/Grid'
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Badge as BadgeIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useRouter, useParams } from 'next/navigation';
import { useAuth } from '../../src/services/auth';

type UserDto = { id: number; fullName?: string; userName?: string };
type Employee = { id: number; salary?: number; usersId: number; user?: UserDto };

export default function EmployeesPageClient() {
  const { t } = useTranslation();
  const theme = useTheme();
  const params = useParams() as { locale?: string } | undefined;
  const locale = params?.locale || 'ar';
  const isRTL = theme.direction === 'rtl' || locale.startsWith('ar');
  const router = useRouter();
  const { isAuthenticated } = useAuth();

  const [items, setItems] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(false);
  const [users, setUsers] = useState<UserDto[]>([]);
  const [selectedUser, setSelectedUser] = useState<number | ''>('');
  const [salary, setSalary] = useState<number | ''>('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const [employeesRes, usersRes] = await Promise.all([api.get('/Employees'), api.get('/LegacyUsers')]);
      setItems(employeesRes.data || []);
      setUsers(usersRes.data || []);
    } catch (err) {
      setSnackbar({ open: true, message: t('employees.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    if (!selectedUser) {
      setSnackbar({ open: true, message: t('employees.pleaseSelectUser'), severity: 'error' });
      return;
    }
    try {
      await api.post('/Employees', { usersId: selectedUser, salary: Number(salary) || undefined });
      await load();
      setSelectedUser('');
      setSalary('');
      setOpenDialog(false);
      setSnackbar({ open: true, message: t('employees.employeeCreated'), severity: 'success' });
    } catch (err: any) {
      setSnackbar({ open: true, message: err?.response?.data?.message ?? t('employees.failedCreate'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('employees.confirmDelete'))) return;
    try {
      await api.delete(`/Employees/${id}`);
      await load();
      setSnackbar({ open: true, message: t('employees.employeeDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('employees.failedDelete'), severity: 'error' });
    }
  }

  const navigate = (path: string) => router.push(`/${locale}${path}`);

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header Section */}
      <Box 
        sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 4, 
          flexDirection: isRTL ? 'row-reverse' : 'row',
          bgcolor: 'background.paper',
          p: 3,
          borderRadius: 4,
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
          border: '1px solid',
          borderColor: 'divider'
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box 
            sx={{ 
              width: 56, 
              height: 56, 
              borderRadius: 3, 
              bgcolor: 'primary.main', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              boxShadow: '0 8px 16px rgba(79, 70, 229, 0.2)'
            }}
          >
            <BadgeIcon sx={{ fontSize: 32, color: 'white' }} />
          </Box>
          <Box sx={{ textAlign: isRTL ? 'right' : 'left' }}>
            <Typography variant="h4" sx={{ fontWeight: 800, color: 'text.primary', letterSpacing: -0.5 }}>
              {t('employees.management')}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
              {t('employees.totalEmployees')}: {items.length}
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton 
              onClick={load} 
              disabled={loading}
              sx={{ 
                bgcolor: 'grey.100', 
                '&:hover': { bgcolor: 'grey.200' },
                borderRadius: 2.5
              }}
            >
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          <Button 
            variant="contained" 
            startIcon={!isRTL ? <AddIcon /> : undefined} 
            endIcon={isRTL ? <AddIcon /> : undefined} 
            onClick={() => setOpenDialog(true)}
            sx={{ 
              borderRadius: 2.5, 
              px: 3,
              fontWeight: 700,
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
            }}
          >
            {t('employees.newEmployee')}
          </Button>
        </Box>
      </Box>

      {/* Table Section */}
      <Paper 
        elevation={0} 
        sx={{ 
          borderRadius: 4, 
          border: '1px solid', 
          borderColor: 'divider',
          overflow: 'hidden',
          bgcolor: 'background.paper',
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
        }}
      >
        <TableContainer>
          <Table sx={{ minWidth: 650 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>ID</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('employees.title')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('employees.salary')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5, fontWeight: 700 }}>{t('cases.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(4)].map((__, j) => (
                      <TableCell key={j} sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5 }}>
                      <Box sx={{ mb: 2, fontSize: 48, color: 'primary.main', opacity: 0.3 }}>
                        <BadgeIcon fontSize="inherit" />
                      </Box>
                      <Typography variant="h6" gutterBottom>{t('employees.noEmployees')}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={() => setOpenDialog(true)}>
                        {t('employees.createFirst')}
                      </Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ) : (
                items.map((item) => (
                  <TableRow 
                    key={item.id}
                    sx={{ 
                      '&:hover': { bgcolor: 'grey.50' },
                      transition: 'background 0.2s ease'
                    }}
                  >
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Chip 
                        label={`#${item.id}`} 
                        size="small" 
                        variant="outlined" 
                        sx={{ borderRadius: 1.5, fontWeight: 600 }}
                      />
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                        <Avatar sx={{ width: 36, height: 36, bgcolor: 'secondary.light', fontSize: '1rem' }}>
                          <PersonIcon fontSize="small" />
                        </Avatar>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {item.user?.fullName || item.user?.userName || 'Unknown'}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Chip 
                        label={item.salary ? `$${item.salary.toLocaleString()}` : 'N/A'} 
                        size="small" 
                        color="success" 
                        variant="outlined" 
                        sx={{ borderRadius: 1.5, fontWeight: 700 }}
                      />
                    </TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
                        <Tooltip title={t('app.delete')}>
                          <IconButton 
                            color="error" 
                            onClick={() => remove(item.id)}
                            sx={{ 
                              '&:hover': { bgcolor: 'error.light', color: 'white' },
                              transition: 'all 0.2s ease'
                            }}
                          >
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))
              )}
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
          sx: { borderRadius: 3, p: 1 }
        }}
      >
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {t('employees.createNew')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
            <FormControl fullWidth variant="outlined">
              <InputLabel>{t('employees.selectUser')}</InputLabel>
              <Select 
                value={selectedUser} 
                label={t('employees.selectUser')} 
                onChange={(e) => setSelectedUser(Number(e.target.value) || '')}
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value=""><em>-- {t('employees.selectUser')} --</em></MenuItem>
                {users.map((u) => (
                  <MenuItem key={u.id} value={u.id}>
                    {u.fullName || u.userName} (#{u.id})
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <TextField 
              fullWidth 
              label={t('employees.salary')} 
              type="number" 
              value={salary} 
              onChange={(e) => setSalary(Number(e.target.value) || '')} 
              variant="outlined"
              InputProps={{ 
                startAdornment: <Typography sx={{ mr: 1, color: 'text.secondary', fontWeight: 600 }}>$</Typography> 
              }}
              sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button 
            onClick={() => setOpenDialog(false)}
            sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}
          >
            {t('app.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={create} 
            disabled={!selectedUser}
            sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}
          >
            {t('app.create')}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={4000} 
        onClose={() => setSnackbar({ ...snackbar, open: false })} 
        anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity} 
          variant="filled"
          sx={{ borderRadius: 2, fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
    </Box>
  );
}
