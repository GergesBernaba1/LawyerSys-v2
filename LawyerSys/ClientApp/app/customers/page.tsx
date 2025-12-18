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
  Divider,
  CircularProgress,
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
      {/* Header */}
      <Box 
        sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 4,
          flexDirection: isRTL ? 'row-reverse' : 'row' 
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box 
            sx={{ 
              bgcolor: 'primary.main', 
              color: 'white', 
              p: 1.5, 
              borderRadius: 3, 
              display: 'flex',
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)',
            }}
          >
            <PeopleIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
              {t('customers.management')}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {t('customers.totalCustomers')}: <strong>{items.length}</strong>
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton 
              onClick={load} 
              disabled={loading}
              sx={{ 
                bgcolor: 'background.paper', 
                border: '1px solid', 
                borderColor: 'divider',
                '&:hover': { bgcolor: 'grey.50' }
              }}
            >
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Button 
            variant="contained" 
            startIcon={!isRTL ? <AddIcon /> : undefined} 
            endIcon={isRTL ? <AddIcon /> : undefined} 
            onClick={() => setOpenCreateWithUser(true)}
            sx={{ 
              borderRadius: 2.5, 
              px: 3,
              fontWeight: 700,
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
            }}
          >
            {t('customers.createNewWithUser')}
          </Button>
        </Box>
      </Box>

      {/* Table */}
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
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('customers.customer')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('customers.userId')}</TableCell>
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
                        <PeopleIcon fontSize="inherit" />
                      </Box>
                      <Typography variant="h6" gutterBottom>{t('customers.noCustomers')}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={() => setOpenCreateWithUser(true)}>
                        {t('customers.createFirst')}
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
                        <Avatar sx={{ width: 36, height: 36, bgcolor: 'primary.light', fontSize: '1rem' }}>
                          <PersonIcon fontSize="small" />
                        </Avatar>
                        <Button 
                          onClick={async ()=>{ const r = await api.get(`/Customers/${item.id}/profile`).then(r=>r.data).catch(()=>null); setProfile(r); setProfileOpen(true); }} 
                          variant="text"
                          sx={{ textTransform: 'none', p: 0, minWidth: 0, textAlign: isRTL ? 'right' : 'left' }}
                        >
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.primary' }}>
                              {item.identity?.fullName || item.identity?.userName || item.identity?.email || 'Unknown'}
                            </Typography>
                            {item.identity?.email && (
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                {item.identity.email}
                              </Typography>
                            )}
                          </Box>
                        </Button>
                      </Box>
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.usersId}</TableCell>
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

      {/* Create with user dialog */}
      <Dialog 
        open={openCreateWithUser} 
        onClose={() => setOpenCreateWithUser(false)} 
        maxWidth="md" 
        fullWidth
        PaperProps={{
          sx: { borderRadius: 3, p: 1 }
        }}
      >
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {t('customers.createNewWithUser')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2.5, mt: 2 }}>
            <TextField 
              label={t('customers.fullName')} 
              value={createForm.fullName} 
              onChange={(e)=>setCreateForm({...createForm, fullName: e.target.value})} 
              fullWidth 
              variant="outlined"
            />
            <TextField 
              label={t('customers.email')} 
              value={createForm.email} 
              onChange={(e)=>setCreateForm({...createForm, email: e.target.value})} 
              fullWidth 
              variant="outlined"
            />
            <TextField 
              label={t('customers.userName')} 
              value={createForm.userName} 
              onChange={(e)=>setCreateForm({...createForm, userName: e.target.value})} 
              fullWidth 
              variant="outlined"
            />
            <TextField 
              label={t('customers.password')} 
              value={createForm.password} 
              onChange={(e)=>setCreateForm({...createForm, password: e.target.value})} 
              fullWidth 
              variant="outlined"
              helperText={t('customers.passwordOptional')} 
            />
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField 
                label={t('customers.address')} 
                value={createForm.address} 
                onChange={(e)=>setCreateForm({...createForm, address: e.target.value})} 
                fullWidth 
                variant="outlined"
              />
            </Box>
            <TextField 
              label={t('customers.phoneNumber')} 
              value={createForm.phoneNumber} 
              onChange={(e)=>setCreateForm({...createForm, phoneNumber: e.target.value})} 
              fullWidth 
              variant="outlined"
            />
            <TextField 
              label={t('customers.ssn')} 
              value={createForm.ssn} 
              onChange={(e)=>setCreateForm({...createForm, ssn: e.target.value})} 
              fullWidth 
              variant="outlined"
            />
            <TextField 
              label={t('customers.job')} 
              value={createForm.job} 
              onChange={(e)=>setCreateForm({...createForm, job: e.target.value})} 
              fullWidth 
              variant="outlined"
            />
            <TextField 
              label={t('customers.dateOfBirth')} 
              type="date" 
              value={createForm.dateOfBirth} 
              onChange={(e)=>setCreateForm({...createForm, dateOfBirth: e.target.value})} 
              fullWidth 
              InputLabelProps={{ shrink: true }} 
              variant="outlined"
            />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button 
            onClick={() => setOpenCreateWithUser(false)}
            sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}
          >
            {t('app.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={async ()=>{
              try{
                const payload = { fullName: createForm.fullName, address: createForm.address, email: createForm.email, job: createForm.job, phoneNumber: createForm.phoneNumber, dateOfBirth: createForm.dateOfBirth || new Date().toISOString().slice(0,10), ssn: createForm.ssn, userName: createForm.userName, password: createForm.password };
                const r = await api.post('/Customers/withuser', payload);
                setSnackbar({ open: true, message: t('customers.customerCreated'), severity: 'success' });
                if(r.data?.tempCredentials){ alert('Temporary credentials:\n' + JSON.stringify(r.data.tempCredentials)); }
                setOpenCreateWithUser(false);
                setCreateForm({ fullName: '', email: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '' });
                load();
              }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? t('customers.failedCreate'), severity: 'error' }); }
            }}
            sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}
          >
            {t('app.create')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Profile dialog */}
      <Dialog 
        open={profileOpen} 
        onClose={()=>setProfileOpen(false)} 
        maxWidth="md" 
        fullWidth
        PaperProps={{
          sx: { borderRadius: 3, p: 1 }
        }}
      >
        <DialogTitle sx={{ fontWeight: 700, px: 3, pt: 3, textAlign: isRTL ? 'right' : 'left' }}>
          {t('customers.profile')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          {profile ? (
            <Box sx={{ mt: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                <Avatar sx={{ width: 64, height: 64, bgcolor: 'primary.main', fontSize: '1.5rem' }}>
                  {(profile.identity?.fullName ?? profile.user?.fullName ?? '?')[0]}
                </Avatar>
                <Box sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                  <Typography variant="h5" sx={{ fontWeight: 700 }}>
                    {profile.identity?.fullName ?? profile.user?.fullName}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {profile.identity?.email ?? '-'} • {profile.identity?.userName ?? '-'}
                  </Typography>
                </Box>
              </Box>

              <Divider sx={{ mb: 3 }} />

              <Box sx={{ mb: 4 }}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1 }}>
                  {t('customers.accountStatus')}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                  <Chip 
                    label={profile.identity?.requiresPasswordReset ? t('customers.passwordResetRequired') : t('customers.accountActive')} 
                    color={profile.identity?.requiresPasswordReset ? "warning" : "success"}
                    size="small"
                    sx={{ fontWeight: 600, borderRadius: 1.5 }}
                  />
                </Box>
              </Box>

              <Box>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1 }}>
                  {t('customers.cases')}
                </Typography>
                {profile.cases.length === 0 ? (
                  <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                    {t('customers.noCasesFound')}
                  </Typography>
                ) : (
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
                    {profile.cases.map((c:any)=> (
                      <Paper 
                        key={c.caseId} 
                        elevation={0} 
                        sx={{ 
                          p: 2, 
                          border: '1px solid', 
                          borderColor: 'divider', 
                          borderRadius: 2.5,
                          bgcolor: 'grey.50'
                        }}
                      >
                        <Box sx={{ display:'flex', alignItems:'center', justifyContent:'space-between', flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                          <Box sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                            <Typography sx={{ fontWeight: 700 }}>{c.caseName}</Typography>
                            <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                              #{c.code}
                            </Typography>
                            <Typography variant="body2" sx={{ mt: 0.5 }}>
                              <Box component="span" sx={{ color: 'text.secondary' }}>{t('customers.assignedEmployee')}: </Box>
                              <Box component="span" sx={{ fontWeight: 600 }}>{c.assignedEmployee?.fullName ?? t('customers.unassigned')}</Box>
                            </Typography>
                          </Box>
                          <Box sx={{ minWidth: 200 }}>
                            <FormControl fullWidth size="small">
                              <InputLabel>{t('customers.assignEmployee')}</InputLabel>
                              <Select 
                                label={t('customers.assignEmployee')}
                                defaultValue="" 
                                onOpen={async ()=>{ if(employees.length===0){ const r = await api.get('/Employees'); setEmployees(r.data); } }} 
                                onChange={async (e)=>{
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
                                }}
                                sx={{ borderRadius: 2 }}
                              >
                                {employees.map(emp => (
                                  <MenuItem key={emp.id} value={emp.id}>
                                    {emp.user?.fullName || emp.user?.userName}
                                  </MenuItem>
                                ))}
                              </Select>
                            </FormControl>
                          </Box>
                        </Box>
                      </Paper>
                    ))}
                  </Box>
                )}
              </Box>
            </Box>
          ) : (
            <Box sx={{ py: 5, textAlign: 'center' }}>
              <CircularProgress size={32} />
              <Typography sx={{ mt: 2 }} color="text.secondary">{t('customers.loading')}</Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions sx={{ p: 3, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button 
            onClick={()=>setProfileOpen(false)}
            sx={{ borderRadius: 2, px: 3 }}
          >
            {t('app.close')}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={6000} 
        onClose={() => { setSnackbar({ ...snackbar, open: false }); setAssignmentUndo(null); }} 
        anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
      >
        <Alert 
          onClose={() => { setSnackbar({ ...snackbar, open: false }); setAssignmentUndo(null); }} 
          severity={snackbar.severity} 
          variant="filled" 
          sx={{ borderRadius: 2, fontWeight: 600 }}
          action={assignmentUndo ? (
            <Button 
              color="inherit" 
              size="small" 
              onClick={async ()=>{
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
              }}
              sx={{ fontWeight: 700 }}
            >
              {t('app.undo')}
            </Button>
          ) : null}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
