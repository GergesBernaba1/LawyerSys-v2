"use client"
import React, { useCallback, useEffect, useState } from 'react';
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
  Edit as EditIcon,
  MarkEmailUnread as MarkEmailUnreadIcon,
  People as PeopleIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
  PersonAdd as PersonAddIcon,
  TextFields as TextFieldsIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
} from '@mui/icons-material';
import { InputAdornment } from '@mui/material';
import api from '../../src/services/api';
import { useRouter } from 'next/navigation';
import { useAuth } from '../../src/services/auth';
import useConfirmDialog from '../../src/hooks/useConfirmDialog';
import SearchableSelect from '../../src/components/SearchableSelect';

type IdentityDto = { id: string; userName?: string; email?: string; fullName?: string; requiresPasswordReset?: boolean };
type Customer = {
  id: number;
  usersId: number;
  identity?: IdentityDto;
  user?: any;
  profileImagePath?: string;
  profileImageUrl?: string;
  fullName: string;
  userName: string;
  email: string;
};

type UserOption = {
  id: number;
  fullName: string;
  userName: string;
};

type TenantOption = {
  id: number;
  name: string;
  isActive: boolean;
};

type EditCustomerForm = {
  fullName: string;
  email: string;
  address: string;
  job: string;
  phoneNumber: string;
  dateOfBirth: string;
  ssn: string;
  userName: string;
  usersId: number;
};

function toDateInput(value: any): string {
  if (!value) return '';
  const text = String(value);
  return text.length >= 10 ? text.substring(0, 10) : text;
}

function firstDefined<T>(...values: Array<T | undefined | null>): T | undefined {
  return values.find((value) => value !== undefined && value !== null) as T | undefined;
}

function normalizeImagePath(raw: any): string | undefined {
  const value = firstDefined(
    raw?.profileImagePath,
    raw?.ProfileImagePath,
    raw?.profile_Image_Path,
    raw?.Profile_Image_Path,
  );
  if (!value) return undefined;
  const text = String(value).trim();
  return text ? text : undefined;
}

function toCustomerImageUrl(customerId: number, path?: string): string | undefined {
  if (!path || !customerId) return undefined;
  const apiBase = String(api.defaults.baseURL || '');
  const apiRoot = apiBase.replace(/\/api\/?$/, '') || '';
  const token = typeof window !== 'undefined' ? localStorage.getItem('lawyersys-token') : '';
  const query = token ? `?access_token=${encodeURIComponent(token)}` : '';
  return `${apiRoot}/api/Customers/${customerId}/profile-image${query}`;
}

function normalizeIdentity(raw: any): IdentityDto | undefined {
  if (!raw) return undefined;
  const id = firstDefined(raw.id, raw.Id);
  if (!id) return undefined;

  return {
    id: String(id),
    userName: firstDefined(raw.userName, raw.UserName),
    email: firstDefined(raw.email, raw.Email),
    fullName: firstDefined(raw.fullName, raw.FullName),
    requiresPasswordReset: firstDefined(raw.requiresPasswordReset, raw.RequiresPasswordReset),
  };
}

function normalizeCustomer(raw: any): Customer {
  const identity = normalizeIdentity(firstDefined(raw.identity, raw.Identity));
  const user = firstDefined(raw.user, raw.User);
  const fallbackIdentity = normalizeIdentity({
    id: firstDefined(user?.id, user?.Id, raw.usersId, raw.UsersId, raw.id, raw.Id),
    userName: firstDefined(user?.userName, user?.UserName),
    email: firstDefined(user?.email, user?.Email),
    fullName: firstDefined(user?.fullName, user?.FullName),
  });

  const fullName = firstDefined(
    identity?.fullName,
    user?.fullName,
    user?.FullName,
    user?.full_Name,
    user?.Full_Name,
    raw?.fullName,
    raw?.FullName,
    raw?.full_Name,
    raw?.Full_Name,
  );
  const userName = firstDefined(
    identity?.userName,
    user?.userName,
    user?.UserName,
    user?.user_Name,
    user?.User_Name,
    raw?.userName,
    raw?.UserName,
    raw?.user_Name,
    raw?.User_Name,
  );
  const email = firstDefined(
    identity?.email,
    user?.email,
    user?.Email,
    raw?.email,
    raw?.Email,
  );
  const profileImagePath = normalizeImagePath(user) ?? normalizeImagePath(raw);

  const id = Number(firstDefined(raw.id, raw.Id, 0));

  return {
    id,
    usersId: Number(firstDefined(raw.usersId, raw.UsersId, raw.userId, raw.UserId, 0)),
    identity: identity ?? fallbackIdentity,
    user,
    profileImagePath,
    profileImageUrl: toCustomerImageUrl(id, profileImagePath),
    fullName: fullName || '-',
    userName: userName || '-',
    email: email || '-',
  };
}

function normalizeProfile(raw: any) {
  if (!raw) return null;
  const identity = normalizeIdentity(firstDefined(raw.identity, raw.Identity));
  const user = firstDefined(raw.user, raw.User);
  const casesRaw = firstDefined(raw.cases, raw.Cases, []);
  const cases = Array.isArray(casesRaw) ? casesRaw.map((item: any) => ({
    caseId: firstDefined(item.caseId, item.CaseId),
    caseName: firstDefined(item.caseName, item.CaseName),
    code: firstDefined(item.code, item.Code),
    assignedEmployee: firstDefined(item.assignedEmployee, item.AssignedEmployee),
  })) : [];
  const profileImagePath = normalizeImagePath(user) ?? normalizeImagePath(raw);

  const id = Number(firstDefined(raw.id, raw.Id, 0));

  return {
    id,
    identity,
    user,
    profileImagePath,
    profileImageUrl: toCustomerImageUrl(id, profileImagePath),
    cases,
  };
}

export default function CustomersPageClient() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = i18n.dir(i18n.language) === 'rtl' || theme.direction === 'rtl';
  const router = useRouter();
  const { isAuthenticated, hasRole } = useAuth();
  const isSuperAdmin = hasRole('SuperAdmin');
  const { confirm, confirmDialog } = useConfirmDialog();

  const [items, setItems] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(false);
  const [openCreateWithUser, setOpenCreateWithUser] = useState(false);
  const [openEditDialog, setOpenEditDialog] = useState(false);
  const [editItem, setEditItem] = useState<Customer | null>(null);
  const [usersOptions, setUsersOptions] = useState<UserOption[]>([]);
  const [tenants, setTenants] = useState<TenantOption[]>([]);
  const [selectedTenantId, setSelectedTenantId] = useState<number | ''>('');
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [savingEdit, setSavingEdit] = useState(false);
  const [uploadingProfileImage, setUploadingProfileImage] = useState(false);
  const [createProfileImageFile, setCreateProfileImageFile] = useState<File | null>(null);
  const [createProfileImagePreview, setCreateProfileImagePreview] = useState<string>('');
  const [sendingResetForId, setSendingResetForId] = useState<number | null>(null);
  const [editForm, setEditForm] = useState<EditCustomerForm>({
    fullName: '',
    email: '',
    address: '',
    job: '',
    phoneNumber: '',
    dateOfBirth: '',
    ssn: '',
    userName: '',
    usersId: 0,
  });
  const [createForm, setCreateForm] = useState({ fullName: '', email: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '', confirmPassword: '' });
  const [showCreatePassword, setShowCreatePassword] = useState(false);
  const [showCreateConfirmPassword, setShowCreateConfirmPassword] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  const [employees, setEmployees] = useState<any[]>([]);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });
  const [assignmentUndo, setAssignmentUndo] = useState<{ caseCode: number; prevEmployeeId?: number | null } | null>(null);
  const imageInputRef = React.useRef<HTMLInputElement | null>(null);
  const createImageInputRef = React.useRef<HTMLInputElement | null>(null);
  const customerItems = Array.isArray(items) ? items : [];

  useEffect(() => {
    if (!createProfileImageFile) {
      setCreateProfileImagePreview('');
      return;
    }
    const objectUrl = URL.createObjectURL(createProfileImageFile);
    setCreateProfileImagePreview(objectUrl);
    return () => URL.revokeObjectURL(objectUrl);
  }, [createProfileImageFile]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const customersRes = await api.get('/Customers');
      const data = customersRes.data;
      const source = Array.isArray(data) ? data : (Array.isArray(data?.items) ? data.items : []);
      setItems(source.map(normalizeCustomer));
    } catch (err) {
      setSnackbar({ open: true, message: t('customers.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }, [t]);

  useEffect(() => { void load(); }, [load]);

  useEffect(() => {
    if (!isSuperAdmin) return;

    let mounted = true;
    const loadTenants = async () => {
      try {
        const res = await api.get('/Tenants/available');
        if (!mounted) return;

        const nextTenants = Array.isArray(res.data?.items) ? res.data.items : [];
        setTenants(nextTenants);
        const currentTenantId = Number(res.data?.currentTenantId || 0) || 0;
        const storedTenantId = typeof window !== 'undefined'
          ? Number(localStorage.getItem('lawyersys-active-tenant-id') || 0) || 0
          : 0;
        setSelectedTenantId(storedTenantId || currentTenantId || nextTenants[0]?.id || '');
      } catch {
        if (mounted) setTenants([]);
      }
    };

    loadTenants();
    return () => { mounted = false; };
  }, [isSuperAdmin]);

  async function remove(id: number) {
    if (!(await confirm(t('customers.confirmDelete')))) return;
    try {
      await api.delete(`/Customers/${id}`);
      await load();
      setSnackbar({ open: true, message: t('customers.customerDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('customers.failedDelete'), severity: 'error' });
    }
  }

  async function openEdit(item: Customer) {
    setEditItem(item);
    setEditForm({
      fullName: item.fullName === '-' ? '' : item.fullName,
      email: item.email === '-' ? '' : item.email,
      address: firstDefined(item.user?.address, item.user?.Address, '') || '',
      job: firstDefined(item.user?.job, item.user?.Job, '') || '',
      phoneNumber: firstDefined(item.user?.phoneNumber, item.user?.PhoneNumber, '') || '',
      dateOfBirth: toDateInput(firstDefined(item.user?.dateOfBirth, item.user?.DateOfBirth, '')),
      ssn: firstDefined(item.user?.ssn, item.user?.SSN, '') || '',
      userName: item.userName === '-' ? '' : item.userName,
      usersId: item.usersId || 0,
    });
    setOpenEditDialog(true);

    try {
      const profileRes = await api.get(`/Customers/${item.id}/profile`);
      const currentProfile = normalizeProfile(profileRes.data);
      if (currentProfile) {
        setEditForm((prev) => ({
          ...prev,
          fullName: firstDefined(currentProfile.identity?.fullName, currentProfile.user?.fullName, currentProfile.user?.FullName, prev.fullName, '') || '',
          email: firstDefined(currentProfile.identity?.email, currentProfile.user?.email, currentProfile.user?.Email, prev.email, '') || '',
          address: firstDefined(currentProfile.user?.address, currentProfile.user?.Address, prev.address, '') || '',
          job: firstDefined(currentProfile.user?.job, currentProfile.user?.Job, prev.job, '') || '',
          phoneNumber: firstDefined(currentProfile.user?.phoneNumber, currentProfile.user?.PhoneNumber, prev.phoneNumber, '') || '',
          dateOfBirth: toDateInput(firstDefined(currentProfile.user?.dateOfBirth, currentProfile.user?.DateOfBirth, prev.dateOfBirth)),
          ssn: firstDefined(currentProfile.user?.ssn, currentProfile.user?.SSN, prev.ssn, '') || '',
          userName: firstDefined(currentProfile.identity?.userName, currentProfile.user?.userName, currentProfile.user?.UserName, prev.userName, '') || '',
        }));
      }
    } catch {
      // Keep the current table values if profile load fails.
    }

    if (usersOptions.length > 0) return;
    setLoadingUsers(true);
    try {
      const res = await api.get('/Users');
      const data = res.data;
      const source = Array.isArray(data) ? data : (Array.isArray(data?.items) ? data.items : []);
      const mapped = source.map((raw: any) => ({
        id: Number(firstDefined(raw.id, raw.Id, 0)),
        fullName: firstDefined(raw.fullName, raw.FullName, raw.full_Name, raw.Full_Name, '') || '',
        userName: firstDefined(raw.userName, raw.UserName, raw.user_Name, raw.User_Name, '') || '',
      })).filter((u: UserOption) => u.id > 0);
      setUsersOptions(mapped);
    } catch {
      setSnackbar({ open: true, message: t('users.failedLoad'), severity: 'error' });
    } finally {
      setLoadingUsers(false);
    }
  }

  async function uploadCustomerProfileImage(file: File) {
    if (!editItem) return;

    setUploadingProfileImage(true);
    try {
      const formData = new FormData();
      formData.append('file', file);
      const response = await api.post(`/Customers/${editItem.id}/profile-image`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const updated = normalizeCustomer(response.data);
      setEditItem(updated);
      setItems((prev) => prev.map((item) => (item.id === updated.id ? updated : item)));
      if (profileOpen && profile?.id === updated.id) {
        const profileResponse = await api.get(`/Customers/${updated.id}/profile`);
        setProfile(normalizeProfile(profileResponse.data));
      }
      setSnackbar({ open: true, message: t('customers.customerUpdated', { defaultValue: 'Customer updated successfully' }), severity: 'success' });
    } catch (err: any) {
      const msg = err?.response?.data?.message || t('customers.failedUpdate');
      setSnackbar({ open: true, message: msg, severity: 'error' });
    } finally {
      setUploadingProfileImage(false);
    }
  }

  async function uploadCustomerProfileImageById(customerId: number, file: File) {
    const formData = new FormData();
    formData.append('file', file);
    await api.post(`/Customers/${customerId}/profile-image`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  function getCreatedCustomerId(payload: any): number | undefined {
    const candidates = [
      payload?.id,
      payload?.Id,
      payload?.customerId,
      payload?.CustomerId,
      payload?.customer?.id,
      payload?.customer?.Id,
      payload?.data?.id,
      payload?.data?.Id,
      payload?.result?.id,
      payload?.result?.Id,
    ];
    for (const candidate of candidates) {
      const value = Number(candidate);
      if (Number.isFinite(value) && value > 0) return value;
    }
    return undefined;
  }

  async function handleUpdateCustomer() {
    if (!editItem) return;
    if (!editForm.fullName.trim()) {
      setSnackbar({ open: true, message: t('common.required'), severity: 'error' });
      return;
    }

    setSavingEdit(true);
    try {
      const payload = {
        usersId: editForm.usersId || undefined,
        fullName: editForm.fullName.trim(),
        email: editForm.email.trim() || undefined,
        address: editForm.address.trim() || undefined,
        job: editForm.job.trim() || undefined,
        phoneNumber: editForm.phoneNumber.trim() || undefined,
        dateOfBirth: editForm.dateOfBirth || undefined,
        ssn: editForm.ssn.trim() || undefined,
        userName: editForm.userName.trim() || undefined,
      };

      await api.put(`/Customers/${editItem.id}`, payload);
      setOpenEditDialog(false);
      setEditItem(null);
      setSnackbar({ open: true, message: t('customers.customerUpdated'), severity: 'success' });
      await load();
    } catch (err: any) {
      const msg = err?.response?.data?.message || t('customers.failedUpdate');
      setSnackbar({ open: true, message: msg, severity: 'error' });
    } finally {
      setSavingEdit(false);
    }
  }

  async function sendPasswordResetEmail(item: Customer) {
    const confirmed = await confirm(t('customers.confirmSendResetEmail', 'Send password reset email to this customer?'));
    if (!confirmed) return;

    setSendingResetForId(item.id);
    try {
      await api.post(`/Customers/${item.id}/send-password-reset-email`);
      setSnackbar({ open: true, message: t('customers.resetEmailSent', 'Password reset email sent successfully'), severity: 'success' });
    } catch (err: any) {
      const msg = err?.response?.data?.message || t('customers.failedSendResetEmail', 'Failed to send password reset email');
      setSnackbar({ open: true, message: msg, severity: 'error' });
    } finally {
      setSendingResetForId(null);
    }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'}>
      {confirmDialog}
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
              {t('customers.totalCustomers')}: <strong>{customerItems.length}</strong>
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
          {hasRole('Admin') && (
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
          )}
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
          <Table sx={{ minWidth: 650, tableLayout: 'fixed' }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700, width: '50%' }}>{t('customers.customer')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700, width: '35%' }}>{t('users.userName') || 'User'}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5, fontWeight: 700, width: '15%' }}>{t('cases.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(3)].map((__, j) => (
                      <TableCell key={j} sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : customerItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={3} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5, textAlign: 'center' }}>
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
                customerItems.map((item) => (
                  <TableRow 
                    key={item.id}
                    sx={{ 
                      '&:hover': { bgcolor: 'grey.50' },
                      transition: 'background 0.2s ease'
                    }}
                  >
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Box
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: 1.5,
                          // Let container direction (rtl/ltr) control inline ordering.
                          flexDirection: 'row',
                          justifyContent: 'flex-start',
                          width: '100%',
                        }}
                      >
                        <Avatar src={item.profileImageUrl} sx={{ width: 36, height: 36, bgcolor: 'primary.light', fontSize: '1rem' }}>
                          <PersonIcon fontSize="small" />
                        </Avatar>
                        <Button 
                          onClick={async ()=>{
                            const r = await api.get(`/Customers/${item.id}/profile`).then(res => normalizeProfile(res.data)).catch(()=>null);
                            setProfile(r);
                            setProfileOpen(true);
                          }} 
                          variant="text"
                          sx={{ textTransform: 'none', p: 0, minWidth: 0, textAlign: isRTL ? 'right' : 'left' }}
                        >
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.primary' }}>
                              {item.fullName}
                            </Typography>
                            {item.email !== '-' && (
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                {item.email}
                              </Typography>
                            )}
                          </Box>
                        </Button>
                      </Box>
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.userName}</TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
                        {hasRole('Admin') && (
                          <Tooltip title={t('common.edit')}>
                            <IconButton
                              color="primary"
                              onClick={() => openEdit(item)}
                              sx={{
                                '&:hover': { bgcolor: 'primary.light', color: 'white' },
                                transition: 'all 0.2s ease'
                              }}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        )}
                        {hasRole('Admin') && (
                          <Tooltip title={t('customers.sendResetEmail', 'Send reset email')}>
                            <span>
                              <IconButton
                                color="secondary"
                                disabled={sendingResetForId === item.id}
                                onClick={() => sendPasswordResetEmail(item)}
                                sx={{
                                  '&:hover': { bgcolor: 'secondary.light', color: 'white' },
                                  transition: 'all 0.2s ease'
                                }}
                              >
                                {sendingResetForId === item.id ? <CircularProgress size={16} color="inherit" /> : <MarkEmailUnreadIcon fontSize="small" />}
                              </IconButton>
                            </span>
                          </Tooltip>
                        )}
                        {hasRole('Admin') && (
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
                        )}
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
        dir={isRTL ? 'rtl' : 'ltr'}
        open={openCreateWithUser} 
        onClose={() => { setOpenCreateWithUser(false); setCreateProfileImageFile(null); }} 
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
          <Box sx={{ mt: 2, mb: 2.5, direction: 'inherit', textAlign: 'start' }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1, textAlign: 'start' }}>
              {t('profile.profileImageSection', { defaultValue: 'Profile Image' })}
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, direction: 'inherit', flexDirection: 'row', justifyContent: 'flex-start' }}>
              <Avatar src={createProfileImagePreview || undefined} sx={{ width: 56, height: 56, bgcolor: 'primary.main' }}>
                <PersonIcon fontSize="small" />
              </Avatar>
              <Button
                variant="outlined"
                onClick={() => createImageInputRef.current?.click()}
                sx={{ borderRadius: 2 }}
              >
                {t('files.upload', { defaultValue: 'Upload' })}
              </Button>
              <input
                ref={createImageInputRef}
                type="file"
                accept="image/*"
                hidden
                onChange={(event) => {
                  const selected = event.target.files?.[0] ?? null;
                  event.currentTarget.value = '';
                  setCreateProfileImageFile(selected);
                }}
              />
            </Box>
          </Box>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2.5, mt: 2 }}>
            {isSuperAdmin && (
              <SearchableSelect<number>
                label={t('app.tenant')}
                value={typeof selectedTenantId === 'number' ? selectedTenantId : null}
                onChange={(value) => setSelectedTenantId(value ?? '')}
                options={tenants.map((tenant) => ({ value: tenant.id, label: tenant.name }))}
                disableClearable
              />
            )}
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
              type={showCreatePassword ? 'text' : 'password'}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={() => setShowCreatePassword(prev => !prev)} edge="end" size="small">
                      {showCreatePassword ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                    </IconButton>
                  </InputAdornment>
                )
              }}
            />
            <TextField 
              label={t('customers.confirmPassword', t('register.confirmPassword'))} 
              value={createForm.confirmPassword} 
              onChange={(e)=>setCreateForm({...createForm, confirmPassword: e.target.value})} 
              fullWidth 
              variant="outlined"
              type={showCreateConfirmPassword ? 'text' : 'password'}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={() => setShowCreateConfirmPassword(prev => !prev)} edge="end" size="small">
                      {showCreateConfirmPassword ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                    </IconButton>
                  </InputAdornment>
                )
              }}
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
            onClick={() => { setOpenCreateWithUser(false); setCreateProfileImageFile(null); }}
            sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}
          >
            {t('app.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={async ()=>{
              if (!createForm.password || !createForm.confirmPassword) {
                setSnackbar({ open: true, message: t('customers.passwordRequired', 'Password is required'), severity: 'error' });
                return;
              }
              if (createForm.password !== createForm.confirmPassword) {
                setSnackbar({ open: true, message: t('register.passwordMismatch'), severity: 'error' });
                return;
              }
              try{
                const payload = {
                  fullName: createForm.fullName,
                  address: createForm.address,
                  email: createForm.email,
                  job: createForm.job,
                  phoneNumber: createForm.phoneNumber,
                  dateOfBirth: createForm.dateOfBirth || new Date().toISOString().slice(0,10),
                  ssn: createForm.ssn,
                  userName: createForm.userName,
                  password: createForm.password,
                  confirmPassword: createForm.confirmPassword
                };
                const r = await api.post(
                  '/Customers/withuser',
                  payload,
                  isSuperAdmin && selectedTenantId ? { headers: { 'X-Firm-Id': String(selectedTenantId) } } : undefined
                );
                let imageUploadFailed = false;
                if (createProfileImageFile) {
                  let createdId = getCreatedCustomerId(r.data);
                  if (!createdId) {
                    const listResponse = await api.get('/Customers');
                    const source = Array.isArray(listResponse.data) ? listResponse.data : (Array.isArray(listResponse.data?.items) ? listResponse.data.items : []);
                    const byUserName = source.map(normalizeCustomer).find((item) => item.userName?.toLowerCase() === createForm.userName.trim().toLowerCase());
                    createdId = byUserName?.id;
                  }
                  if (createdId) {
                    try {
                      await uploadCustomerProfileImageById(createdId, createProfileImageFile);
                    } catch {
                      imageUploadFailed = true;
                    }
                  } else {
                    imageUploadFailed = true;
                  }
                }
                const credentials = r.data?.tempCredentials;
                const successMessage = credentials?.userName
                  ? `${t('customers.customerCreated')} - ${t('customers.userName')}: ${credentials.userName}`
                  : t('customers.customerCreated');
                setSnackbar({
                  open: true,
                  message: imageUploadFailed ? `${successMessage}. ${t('customers.profileImageUploadFailedAfterCreate', { defaultValue: 'Customer created, but image upload failed.' })}` : successMessage,
                  severity: imageUploadFailed ? 'error' : 'success'
                });
                setOpenCreateWithUser(false);
                setCreateForm({ fullName: '', email: '', address: '', job: '', phoneNumber: '', dateOfBirth: '', ssn: '', userName: '', password: '', confirmPassword: '' });
                setCreateProfileImageFile(null);
                setShowCreatePassword(false);
                setShowCreateConfirmPassword(false);
                load();
              }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? t('customers.failedCreate'), severity: 'error' }); }
            }}
            disabled={isSuperAdmin && !selectedTenantId}
            sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}
          >
            {t('app.create')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Edit customer dialog */}
      <Dialog
        dir={isRTL ? 'rtl' : 'ltr'}
        open={openEditDialog}
        onClose={() => setOpenEditDialog(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{
          sx: { borderRadius: 3, p: 1 }
        }}
      >
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {t('common.edit')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ mt: 2, mb: 2.5, direction: 'inherit', textAlign: 'start' }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1, textAlign: 'start' }}>
              {t('profile.profileImageSection', { defaultValue: 'Profile Image' })}
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, direction: 'inherit', flexDirection: 'row', justifyContent: 'flex-start' }}>
              <Avatar src={editItem?.profileImageUrl} sx={{ width: 56, height: 56, bgcolor: 'primary.main' }}>
                <PersonIcon fontSize="small" />
              </Avatar>
              <Button
                variant="outlined"
                onClick={() => imageInputRef.current?.click()}
                disabled={!editItem || uploadingProfileImage}
                sx={{ borderRadius: 2 }}
              >
                {uploadingProfileImage ? t('customers.loading', { defaultValue: 'Loading...' }) : t('files.upload', { defaultValue: 'Upload' })}
              </Button>
              <input
                ref={imageInputRef}
                type="file"
                accept="image/*"
                hidden
                onChange={(event) => {
                  const selected = event.target.files?.[0];
                  event.currentTarget.value = '';
                  if (selected) {
                    void uploadCustomerProfileImage(selected);
                  }
                }}
              />
            </Box>
          </Box>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2.5, mt: 2 }}>
            <TextField
              fullWidth
              label={t('customers.fullName')}
              value={editForm.fullName}
              onChange={(e) => setEditForm({ ...editForm, fullName: e.target.value })}
              variant="outlined"
            />
            <TextField
              fullWidth
              label={t('customers.email')}
              value={editForm.email}
              onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
              variant="outlined"
            />
            <TextField
              fullWidth
              label={t('customers.userName')}
              value={editForm.userName}
              onChange={(e) => setEditForm({ ...editForm, userName: e.target.value })}
              variant="outlined"
            />
            <TextField
              fullWidth
              label={t('customers.job')}
              value={editForm.job}
              onChange={(e) => setEditForm({ ...editForm, job: e.target.value })}
              variant="outlined"
            />
            <TextField
              fullWidth
              label={t('customers.phoneNumber')}
              value={editForm.phoneNumber}
              onChange={(e) => setEditForm({ ...editForm, phoneNumber: e.target.value })}
              variant="outlined"
            />
            <TextField
              fullWidth
              label={t('customers.ssn')}
              value={editForm.ssn}
              onChange={(e) => setEditForm({ ...editForm, ssn: e.target.value })}
              variant="outlined"
            />
            <TextField
              fullWidth
              label={t('customers.dateOfBirth')}
              type="date"
              value={editForm.dateOfBirth}
              onChange={(e) => setEditForm({ ...editForm, dateOfBirth: e.target.value })}
              InputLabelProps={{ shrink: true }}
              variant="outlined"
            />
            <SearchableSelect<number>
              label={t('customers.selectUser')}
              value={editForm.usersId || null}
              onChange={(value) => setEditForm({ ...editForm, usersId: value ?? 0 })}
              disabled={loadingUsers}
              loading={loadingUsers}
              options={usersOptions.map((u) => ({
                value: u.id,
                label: u.fullName || u.userName || `#${u.id}`,
                keywords: [u.userName || ''],
              }))}
            />
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField
                fullWidth
                label={t('customers.address')}
                value={editForm.address}
                onChange={(e) => setEditForm({ ...editForm, address: e.target.value })}
                variant="outlined"
              />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenEditDialog(false)} sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}>
            {t('common.cancel')}
          </Button>
          <Button variant="contained" onClick={handleUpdateCustomer} disabled={savingEdit} sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}>
            {t('common.save')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Profile dialog */}
      <Dialog 
        dir={isRTL ? 'rtl' : 'ltr'}
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
                <Avatar src={profile.profileImageUrl} sx={{ width: 64, height: 64, bgcolor: 'primary.main', fontSize: '1.5rem' }}>
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
                              {c.code}
                            </Typography>
                            <Typography variant="body2" sx={{ mt: 0.5 }}>
                              <Box component="span" sx={{ color: 'text.secondary' }}>{t('customers.assignedEmployee')}: </Box>
                              <Box component="span" sx={{ fontWeight: 600 }}>{c.assignedEmployee?.fullName ?? t('customers.unassigned')}</Box>
                            </Typography>
                          </Box>
                          <Box sx={{ minWidth: 200 }}>
                            <SearchableSelect<number>
                              size="small"
                              label={t('customers.assignEmployee')}
                              value={null}
                              onOpen={async ()=>{ 
                                if(employees.length===0){ 
                                  const r = await api.get('/Employees');
                                  const source = Array.isArray(r.data) ? r.data : (Array.isArray(r.data?.items) ? r.data.items : []);
                                  const mappedEmployees = source.map((emp: any) => ({
                                    id: Number(firstDefined(emp.id, emp.Id, 0)),
                                    user: firstDefined(emp.user, emp.User),
                                    identity: normalizeIdentity(firstDefined(emp.identity, emp.Identity)),
                                  }));
                                  setEmployees(mappedEmployees);
                                } 
                              }}
                              onChange={async (value)=>{
                                if (!value) {
                                  return;
                                }
                                try{
                                  const prevEmployeeId = c.assignedEmployee?.id ?? null;
                                  await api.post(`/Cases/${c.code}/assign-employee`, { employeeId: value });
                                  const r = await api.get(`/Customers/${profile.id}/profile`);
                                  setProfile(normalizeProfile(r.data));
                                  load();
                                  setSnackbar({ open: true, message: t('customers.assignmentSuccess'), severity: 'success' });
                                  setAssignmentUndo({ caseCode: c.code, prevEmployeeId: prevEmployeeId });
                                }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? t('customers.failedAssign'), severity: 'error' }); }
                              }}
                              options={employees.map((emp) => ({
                                value: emp.id,
                                label: emp.identity?.fullName || emp.user?.fullName || emp.user?.FullName || emp.user?.userName || emp.user?.UserName || '-',
                                keywords: [emp.user?.userName || emp.user?.UserName || ''],
                              }))}
                              sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
                            />
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
                  setProfile(normalizeProfile(r.data));
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
