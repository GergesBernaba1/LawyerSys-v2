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
  TextField,
  Grid,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  People as PeopleIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
  PersonAdd as PersonAddIcon,
  TextFields as TextFieldsIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useRouter, useParams } from 'next/navigation';
import { useAuth } from '../../src/services/auth';

type UserDto = { id: number; fullName?: string; userName?: string };
type IdentityDto = { id: string; userName?: string; email?: string; fullName?: string; requiresPasswordReset?: boolean };
type Customer = { id: number; usersId: number; user?: UserDto; identity?: IdentityDto };

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
  const [openCreateWithUser, setOpenCreateWithUser] = useState(false);
  const [createForm, setCreateForm] = useState({ fullName: '', email: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '' });
  const [profileOpen, setProfileOpen] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  const [employees, setEmployees] = useState<any[]>([]);
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
          <Button variant="outlined" startIcon={<PersonAddIcon sx={{ ml: 1 }} />} onClick={() => setOpenCreateWithUser(true)} sx={{ ml: 1 }}>{t('customers.newWithUser')}</Button>
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
                      <Button onClick={async ()=>{ const r = await api.get(`/Customers/${item.id}/profile`).then(r=>r.data).catch(()=>null); setProfile(r); setProfileOpen(true); }} variant="text">
                      <Box sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                        <div>{item.identity?.fullName || item.user?.fullName || item.identity?.userName || item.user?.userName || item.identity?.email || 'Unknown'}</div>
                        {item.identity?.email && <Typography variant="caption" color="text.secondary">{item.identity.email}</Typography>}
                      </Box>
                    </Button>
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

      {/* Create with user dialog */}
      <Dialog open={openCreateWithUser} onClose={() => setOpenCreateWithUser(false)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('customers.createNewWithUser')}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2, mt: 1 }}>
            <Box><TextField label={t('customers.fullName')} value={createForm.fullName} onChange={(e)=>setCreateForm({...createForm, fullName: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.email')} value={createForm.email} onChange={(e)=>setCreateForm({...createForm, email: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.userName')} value={createForm.userName} onChange={(e)=>setCreateForm({...createForm, userName: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.password')} value={createForm.password} onChange={(e)=>setCreateForm({...createForm, password: e.target.value})} fullWidth helperText={t('customers.passwordOptional')} /></Box>
            <Box sx={{ gridColumn: '1 / -1' }}><TextField label={t('customers.address')} value={createForm.address} onChange={(e)=>setCreateForm({...createForm, address: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.phoneNumber')} value={createForm.phoneNumber} onChange={(e)=>setCreateForm({...createForm, phoneNumber: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.ssn')} value={createForm.ssn} onChange={(e)=>setCreateForm({...createForm, ssn: e.target.value})} fullWidth /></Box>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 2, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenCreateWithUser(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={async ()=>{
            try{
              const payload = { fullName: createForm.fullName, address: createForm.address, email: createForm.email, job: createForm.job, phoneNumber: createForm.phoneNumber, dateOfBirth: new Date().toISOString().slice(0,10), ssn: createForm.ssn, userName: createForm.userName, password: createForm.password };
              const r = await api.post('/Customers/withuser', payload);
              setSnackbar({ open: true, message: t('customers.customerCreated'), severity: 'success' });
              // show temp credentials if returned
              if(r.data?.tempCredentials){ alert('Temporary credentials:\n' + JSON.stringify(r.data.tempCredentials)); }
              setOpenCreateWithUser(false);
              load();
            }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? t('customers.failedCreate'), severity: 'error' }); }
          }}>{t('app.create')}</Button>
        </DialogActions>
      </Dialog>

      {/* Profile dialog */}
      <Dialog open={profileOpen} onClose={()=>setProfileOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>{t('customers.profile')}</DialogTitle>
        <DialogContent>
          {profile ? (
            <Box>
              <Typography variant="h6">{profile.identity?.fullName ?? profile.user?.fullName}</Typography>
              <Typography variant="body2">{t('customers.email')}: {profile.identity?.email ?? '-'}</Typography>
              <Typography variant="body2">{t('customers.userName')}: {profile.identity?.userName ?? '-'}</Typography>
              <Typography variant="body2">{t('customers.requiresPasswordReset')}: {profile.identity?.requiresPasswordReset ? t('app.yes') : t('app.no')}</Typography>
              <Box sx={{ mt: 2 }}>
                <Typography variant="subtitle1">{t('customers.cases')}</Typography>
                {profile.cases.map((c:any)=> (
                  <Paper key={c.caseId} sx={{ p:1, mt:1 }}>
                    <Box sx={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
                      <Box>
                        <Typography><strong>{c.caseName}</strong> (#{c.code})</Typography>
                        <Typography variant="body2">{t('customers.assignedEmployee')}: {c.assignedEmployee?.fullName ?? t('customers.unassigned')}</Typography>
                      </Box>
                      <Box>
                        <FormControl fullWidth>
                          <InputLabel>{t('customers.assignEmployee')}</InputLabel>
                          <Select defaultValue="" onOpen={async ()=>{ if(employees.length===0){ const r = await api.get('/Employees'); setEmployees(r.data); } }} onChange={async (e)=>{ const empId = Number(e.target.value); await api.post(`/Cases/${c.code}/assign-employee`, { employeeId: empId }); const r = await api.get(`/Customers/${profile.id}/profile`); setProfile(r.data); load(); }}>{employees.map(emp => (<MenuItem key={emp.id} value={emp.id}>{emp.user?.fullName || emp.user?.userName}</MenuItem>))}</Select>
                        </FormControl>
                      </Box>
                    </Box>
                  </Paper>
                ))}
              </Box>
            </Box>
          ) : <Typography>{t('customers.loading')}</Typography>}
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setProfileOpen(false)}>{t('app.close')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
