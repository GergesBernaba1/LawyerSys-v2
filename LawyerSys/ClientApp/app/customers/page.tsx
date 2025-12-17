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

type IdentityDto = { id: string; userName?: string; email?: string; fullName?: string; requiresPasswordReset?: boolean };
type Customer = { id: number; usersId: number; identity?: IdentityDto };

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
  const [openCreateWithUser, setOpenCreateWithUser] = useState(false);
  const [createForm, setCreateForm] = useState({ fullName: '', email: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '' });
  const [profileOpen, setProfileOpen] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  const [employees, setEmployees] = useState<any[]>([]);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });
  const [assignmentUndo, setAssignmentUndo] = useState<{ caseCode: number; prevEmployeeId?: number | null } | null>(null);

  async function load() {
    setLoading(true);
    try {
      const customersRes = await api.get('/Customers');
      setItems(customersRes.data || []);
    } catch (err) {
      setSnackbar({ open: true, message: t('customers.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

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
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenCreateWithUser(true)}>{t('customers.createNewWithUser')}</Button>
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
                    <Button variant="contained" size="small" sx={{ mt: 2 }} onClick={() => setOpenCreateWithUser(true)}>{t('customers.createFirst')}</Button>
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
                        <div>{item.identity?.fullName || item.identity?.userName || item.identity?.email || 'Unknown'}</div>
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

      {/* Create with user dialog */}
      <Dialog open={openCreateWithUser} onClose={() => setOpenCreateWithUser(false)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('customers.createNewWithUser')}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2, mt: 1 }}>
            <Box><TextField label={t('customers.fullName')} placeholder={t('customers.fullName')} value={createForm.fullName} onChange={(e)=>setCreateForm({...createForm, fullName: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.email')} placeholder={t('customers.email')} value={createForm.email} onChange={(e)=>setCreateForm({...createForm, email: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.userName')} placeholder={t('customers.userName')} value={createForm.userName} onChange={(e)=>setCreateForm({...createForm, userName: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.password')} placeholder={t('customers.passwordOptional')} value={createForm.password} onChange={(e)=>setCreateForm({...createForm, password: e.target.value})} fullWidth helperText={t('customers.passwordOptional')} /></Box>
            <Box sx={{ gridColumn: '1 / -1' }}><TextField label={t('customers.address')} placeholder={t('customers.address')} value={createForm.address} onChange={(e)=>setCreateForm({...createForm, address: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.phoneNumber')} placeholder={t('customers.phoneNumber')} value={createForm.phoneNumber} onChange={(e)=>setCreateForm({...createForm, phoneNumber: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.ssn')} placeholder={t('customers.ssn')} value={createForm.ssn} onChange={(e)=>setCreateForm({...createForm, ssn: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.job')} placeholder={t('customers.job')} value={createForm.job} onChange={(e)=>setCreateForm({...createForm, job: e.target.value})} fullWidth /></Box>
            <Box><TextField label={t('customers.dateOfBirth')} type="date" value={createForm.dateOfBirth} onChange={(e)=>setCreateForm({...createForm, dateOfBirth: e.target.value})} fullWidth InputLabelProps={{ shrink: true }} /></Box>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 2, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenCreateWithUser(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={async ()=>{
            try{
              const payload = { fullName: createForm.fullName, address: createForm.address, email: createForm.email, job: createForm.job, phoneNumber: createForm.phoneNumber, dateOfBirth: createForm.dateOfBirth || new Date().toISOString().slice(0,10), ssn: createForm.ssn, userName: createForm.userName, password: createForm.password };
              const r = await api.post('/Customers/withuser', payload);
              setSnackbar({ open: true, message: t('customers.customerCreated'), severity: 'success' });
              // show temp credentials if returned
              if(r.data?.tempCredentials){ alert('Temporary credentials:\n' + JSON.stringify(r.data.tempCredentials)); }
              setOpenCreateWithUser(false);
              setCreateForm({ fullName: '', email: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '' });
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
                          <Select defaultValue="" onOpen={async ()=>{ if(employees.length===0){ const r = await api.get('/Employees'); setEmployees(r.data); } }} onChange={async (e)=>{
                            try{
                              const empId = Number(e.target.value);
                              const prevEmployeeId = c.assignedEmployee?.id ?? null;
                              await api.post(`/Cases/${c.code}/assign-employee`, { employeeId: empId });
                              const r = await api.get(`/Customers/${profile.id}/profile`);
                              setProfile(r.data);
                              load();
                              setSnackbar({ open: true, message: t('customers.assignmentSuccess'), severity: 'success' });
                              setAssignmentUndo({ caseCode: c.code, prevEmployeeId: prevEmployeeId });
                            }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? t('customers.failedAssign'), severity: 'error' }); }
                          }}>{employees.map(emp => (<MenuItem key={emp.id} value={emp.id}>{emp.user?.fullName || emp.user?.userName}</MenuItem>))}</Select>
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

      <Snackbar open={snackbar.open} autoHideDuration={6000} onClose={() => { setSnackbar({ ...snackbar, open: false }); setAssignmentUndo(null); }} anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}>
        <Alert onClose={() => { setSnackbar({ ...snackbar, open: false }); setAssignmentUndo(null); }} severity={snackbar.severity} variant="filled" action={assignmentUndo ? <Button color="inherit" size="small" onClick={async ()=>{
            // Undo logic
            const undo = assignmentUndo;
            if(!undo) return;
            try{
              if(undo.prevEmployeeId != null){
                await api.post(`/Cases/${undo.caseCode}/assign-employee`, { employeeId: undo.prevEmployeeId });
              }else{
                await api.delete(`/Cases/${undo.caseCode}/assign-employee`);
              }
              const r = await api.get(`/Customers/${profile.id}/profile`);
              setProfile(r.data);
              load();
              setSnackbar({ open: true, message: t('customers.assignmentUndone'), severity: 'success' });
            }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? t('customers.failedUndo'), severity: 'error' }); }
            setAssignmentUndo(null);
          }}>{t('app.undo')}</Button> : null}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
