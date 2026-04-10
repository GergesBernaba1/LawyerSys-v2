"use client"
import React, { useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
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
  List,
  ListItem,
  ListItemText,
  Avatar,
  useTheme,
  Pagination,
  useMediaQuery,
} from '@mui/material';
import Grid from '@mui/material/Grid'
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Gavel as GavelIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useRouter } from 'next/navigation';
import { useCurrency } from '../../src/hooks/useCurrency';
import { useAuth } from '../../src/services/auth';
import useConfirmDialog from '../../src/hooks/useConfirmDialog';
import SearchableSelect from '../../src/components/SearchableSelect';
import SearchableMultiSelect from '../../src/components/SearchableMultiSelect';
import LoadingButton from '../../src/components/LoadingButton';
import RetryAlert from '../../src/components/RetryAlert';

type CaseItem = {
  id: number;
  code: number;
  invitionsStatment?: string;
  invitionType?: string;
  invitionDate?: string;
  totalAmount?: number;
  notes?: string;
  status?: number; // matches backend Case.Status (enum int)
};

function normalizeCaseItem(raw: any): CaseItem {
  return {
    id: Number(raw?.id ?? raw?.Id ?? 0),
    code: Number(raw?.code ?? raw?.Code ?? 0),
    invitionsStatment: raw?.invitionsStatment ?? raw?.InvitionsStatment ?? '',
    invitionType: raw?.invitionType ?? raw?.InvitionType ?? '',
    invitionDate: raw?.invitionDate ?? raw?.InvitionDate ?? '',
    totalAmount: Number(raw?.totalAmount ?? raw?.TotalAmount ?? 0),
    notes: raw?.notes ?? raw?.Notes ?? '',
    status: Number(raw?.status ?? raw?.Status ?? 0),
  };
}

const CASE_TYPE_VALUES = [
  'Civil',
  'Criminal',
  'Labor',
  'Commercial',
  'Family',
  'Administrative',
  'PersonalStatus',
  'Enforcement',
  'Appeal',
  'Other',
] as const;

const MIN_STATEMENT_LENGTH = 30;
const MAX_CASE_DATE_FUTURE_DAYS = 365;
const MAX_TOTAL_AMOUNT = 1_000_000_000;

function sanitizeAmountInput(value: string) {
  return value.replace(/[^\d]/g, '');
}

function formatAmountInput(value: string) {
  if (!value) return '';
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return '';
  return new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 }).format(numeric);
}

export default function CasesPageClient() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isSmallScreen = useMediaQuery(theme.breakpoints.down('md'));
  const activeLanguage = (i18n.resolvedLanguage || i18n.language || '').toLowerCase();
  const isRTL = activeLanguage.startsWith('ar');
  const { formatCurrency } = useCurrency();
  const router = useRouter();
  const { hasAnyRole, user } = useAuth();
  const { confirm, confirmDialog } = useConfirmDialog();
  const isCustomerOnly = Boolean(
    user?.roles?.includes('Customer') &&
    !hasAnyRole('SuperAdmin', 'Admin', 'Employee')
  );

  const [items, setItems] = useState<CaseItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState(false);
  const [creating, setCreating] = useState(false);
  const [code, setCode] = useState<number>(0);
  const [invitionsStatment, setInvitionsStatment] = useState('');
  const [invitionType, setInvitionType] = useState('');
  const [invitionDate, setInvitionDate] = useState('');
  const [totalAmountInput, setTotalAmountInput] = useState<string>('');
  const [notes, setNotes] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // pagination
  const [page, setPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [search, setSearch] = useState<string>('');

  // New states for relations
  const [courts, setCourts] = useState<any[]>([]);
  const [customers, setCustomers] = useState<any[]>([]);
  const [contenders, setContenders] = useState<any[]>([]);
  const [selectedCourt, setSelectedCourt] = useState<number | ''>('');
  const [primaryCustomer, setPrimaryCustomer] = useState<number | ''>('');
  const [selectedCustomers, setSelectedCustomers] = useState<number[]>([]);
  const [selectedContenders, setSelectedContenders] = useState<number[]>([]);
  const [sitingDialogOpen, setSitingDialogOpen] = useState(false);
  const [contenderDialogOpen, setContenderDialogOpen] = useState(false);
  const [newSiting, setNewSiting] = useState({ date: '', time: '', judgeName: '', notes: '' });
  const [newContender, setNewContender] = useState({ fullName: '', ssn: '', birthDate: '' });
  const [pendingSitings, setPendingSitings] = useState<any[]>([]);
  const [pendingFiles, setPendingFiles] = useState<File[]>([]);
  const [creationOptionsLoaded, setCreationOptionsLoaded] = useState(false);
  const totalAmount = Number(totalAmountInput || '0');

  const caseTypeOptions = CASE_TYPE_VALUES.map((value) => ({
    value,
    label: t(`cases.caseTypes.${value}`, {
      defaultValue:
        value === 'PersonalStatus'
          ? 'Personal Status'
          : value,
    }),
  }));

  function validateCaseForm() {
    if (code <= 0) {
      return t('cases.validation.invalidCode', { defaultValue: 'Case code must be greater than 0.' });
    }
    if (!invitionType.trim()) {
      return t('cases.validation.typeRequired', { defaultValue: 'Case type is required.' });
    }
    if (!CASE_TYPE_VALUES.includes(invitionType as any)) {
      return t('cases.validation.typeInvalid', { defaultValue: 'Please select a valid case type.' });
    }
    const statementLength = invitionsStatment.trim().length;
    if (statementLength < MIN_STATEMENT_LENGTH) {
      return t('cases.validation.statementTooShort', {
        defaultValue: `Case statement must be at least ${MIN_STATEMENT_LENGTH} characters.`,
        min: MIN_STATEMENT_LENGTH,
      });
    }
    if (!invitionDate) {
      return t('cases.validation.dateRequired', { defaultValue: 'Case date is required.' });
    }
    const enteredDate = new Date(`${invitionDate}T00:00:00`);
    if (Number.isNaN(enteredDate.getTime())) {
      return t('cases.validation.dateInvalid', { defaultValue: 'Case date is invalid.' });
    }
    const maxAllowedDate = new Date();
    maxAllowedDate.setDate(maxAllowedDate.getDate() + MAX_CASE_DATE_FUTURE_DAYS);
    if (enteredDate > maxAllowedDate) {
      return t('cases.validation.dateTooFar', {
        defaultValue: `Case date cannot be more than ${MAX_CASE_DATE_FUTURE_DAYS} days in the future.`,
        days: MAX_CASE_DATE_FUTURE_DAYS,
      });
    }
    if (totalAmount < 0 || totalAmount > MAX_TOTAL_AMOUNT) {
      return t('cases.validation.amountInvalid', {
        defaultValue: `Amount must be between 0 and ${MAX_TOTAL_AMOUNT.toLocaleString()}.`,
        max: MAX_TOTAL_AMOUNT,
      });
    }
    return '';
  }

  const load = useCallback(async (p = page) => {
    setLoading(true);
    setLoadError(false);
    try {
      const r = await api.get(`/Cases?page=${p}&pageSize=${pageSize}${search ? `&search=${encodeURIComponent(search)}` : ''}`);

      // support legacy array response OR new paged response
      const casesData = r.data?.items ? r.data.items : r.data;
      setItems((casesData || []).map(normalizeCaseItem));
      if (r.data?.totalCount) setTotalCount(r.data.totalCount);
    } catch (err) {
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, search, t]);

  async function loadCreateOptions() {
    if (creationOptionsLoaded) return;
    try {
      const [courtsRes, customersRes, contendersRes] = await Promise.all([
        api.get('/Courts'),
        api.get('/Customers'),
        api.get('/Contenders'),
      ]);

      setCourts(courtsRes.data || []);
      setCustomers(customersRes.data || []);
      setContenders(contendersRes.data || []);
      setCreationOptionsLoaded(true);
    } catch {
      setSnackbar({ open: true, message: t('cases.failedLoad', { defaultValue: 'Failed to load data' }), severity: 'error' });
    }
  }

  async function openCreateDialog() {
    await loadCreateOptions();
    setOpenDialog(true);
  }

  useEffect(() => { void load(); }, [load]);

  async function create() {
    const validationMessage = validateCaseForm();
    if (validationMessage) {
      setSnackbar({
        open: true,
        message: validationMessage,
        severity: 'error',
      });
      return;
    }

    setCreating(true);
    try {
      // 1) Create case
      const created = await api.post('/Cases', {
        Code: code,
        InvitionsStatment: invitionsStatment.trim(),
        InvitionType: invitionType.trim(),
        InvitionDate: invitionDate,
        TotalAmount: Math.max(0, Number(totalAmount || 0)),
        Notes: notes?.trim() || '',
      });
      const createdCase = created.data;
      const caseCode = createdCase.code ?? createdCase.Code ?? code;

      // 2) Link court
      if (selectedCourt) {
        await api.post(`/cases/${caseCode}/courts/${selectedCourt}`);
      }

      // 3) Link customers (primary and additional)
      if (primaryCustomer) {
        await api.post(`/cases/${caseCode}/customers/${primaryCustomer}`);
        // ensure primary included in selected
        if (!selectedCustomers.includes(Number(primaryCustomer))) setSelectedCustomers(prev => [...prev, Number(primaryCustomer)]);
      }
      for (const cid of selectedCustomers) {
        try { await api.post(`/cases/${caseCode}/customers/${cid}`); } catch (e) { /* ignore duplicates */ }
      }

      // 4) Link contenders
      for (const cont of selectedContenders) {
        try { await api.post(`/cases/${caseCode}/contenders/${cont}`); } catch (e) { }
      }

      // 5) Create and link sitings
      for (const s of pendingSitings) {
        // create siting
        const sitDto = {
          SitingTime: new Date(`${s.date}T${s.time}`),
          SitingDate: s.date,
          SitingNotification: new Date(`${s.date}T${s.time}`),
          JudgeName: s.judgeName,
          Notes: s.notes
        };
        const r = await api.post('/Sitings', sitDto);
        const sitingId = r.data.id;
        await api.post(`/cases/${caseCode}/sitings/${sitingId}`);
      }

      // 6) Upload and link files
      for (const f of pendingFiles) {
        const fd = new FormData();
        fd.append('file', f);
        const uploadRes = await api.post('/Files/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
        const fileId = uploadRes.data.id;
        await api.post(`/cases/${caseCode}/files/${fileId}`);
      }

      await load();
      setCode(0);
      setInvitionsStatment('');
      setInvitionType('');
      setInvitionDate('');
      setTotalAmountInput('');
      setNotes('');
      setSelectedCourt('');
      setPrimaryCustomer('');
      setSelectedCustomers([]);
      setSelectedContenders([]);
      setPendingSitings([]);
      setPendingFiles([]);
      setOpenDialog(false);
      setSnackbar({ open: true, message: t('cases.caseCreated'), severity: 'success' });
    } catch (err: any) {
      console.error(err);
      setSnackbar({ open: true, message: err?.response?.data?.message ?? t('cases.failedCreate'), severity: 'error' });
    } finally {
      setCreating(false);
    }
  }

  async function remove(caseCode: number) {
    if (!(await confirm(t('cases.confirmDelete')))) return;
    try {
      await api.delete(`/Cases/${caseCode}`);
      await load();
      setSnackbar({ open: true, message: t('cases.caseDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('cases.failedDelete'), severity: 'error' });
    }
  }

  const openCaseDetails = (caseCode: number) => {
    router.push(`/cases/${caseCode}`);
  };

  const visibleColumnCount = isCustomerOnly ? 5 : 7;
  const actionButtonSx = {
    minWidth: isSmallScreen ? 96 : 110,
    borderRadius: 999,
    px: 2,
    fontWeight: 700,
    boxShadow: 'none',
    textTransform: 'none',
  };
  const paginationContainerSx = {
    p: 2,
    display: 'flex',
    justifyContent: 'flex-start',
    alignItems: 'center',
    gap: 2,
    flexWrap: isSmallScreen ? 'wrap' : 'nowrap',
    flexDirection: isRTL ? 'row-reverse' : 'row',
  } as const;

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
            <GavelIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
              {t('cases.management')}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {t('cases.totalCases')}: <strong>{totalCount || items.length}</strong>
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <span>
              <IconButton
                onClick={() => load()}
                disabled={loading}
                aria-label={t('cases.refresh')}
                sx={{
                  bgcolor: 'background.paper',
                  border: '1px solid',
                  borderColor: 'divider',
                  '&:hover': { bgcolor: 'grey.50' }
                }}
              >
                <RefreshIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
          {hasAnyRole('Admin', 'Employee') && (
            <Button
              variant="contained"
              startIcon={!isRTL ? <AddIcon /> : undefined}
              endIcon={isRTL ? <AddIcon /> : undefined}
              onClick={() => { void openCreateDialog(); }}
              sx={{ 
                borderRadius: 2.5, 
                px: 3,
                fontWeight: 700,
                boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
              }}
            >
              {t('cases.newCase')}
            </Button>
          )}
        </Box>
      </Box>

      {/* Load error */}
      {loadError && (
        <RetryAlert
          message={t('cases.failedLoad')}
          onRetry={() => load()}
          loading={loading}
          sx={{ mb: 3 }}
        />
      )}

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
          <Table sx={{ minWidth: isCustomerOnly ? 520 : 650 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.code')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.type')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.status')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.date')}</TableCell>
                {!isCustomerOnly && (
                  <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.amount')}</TableCell>
                )}
                {!isCustomerOnly && (
                  <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.notes')}</TableCell>
                )}
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5 }}>{t('cases.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(visibleColumnCount)].map((__, j) => (
                      <TableCell key={j} sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={visibleColumnCount} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5, textAlign: 'center' }}>
                      <Box sx={{ mb: 2, fontSize: 48, color: 'primary.main', opacity: 0.3 }}>
                        <GavelIcon fontSize="inherit" />
                      </Box>
                      <Typography variant="h6" gutterBottom>{t('cases.noCases')}</Typography>
                      {hasAnyRole('Admin', 'Employee') && (
                        <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={() => { void openCreateDialog(); }}>
                          {t('cases.createFirst')}
                        </Button>
                      )}
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
                        label={item.code} 
                        size="small" 
                        color="primary" 
                        variant="outlined" 
                        sx={{ borderRadius: 1.5, fontWeight: 600 }}
                      />
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.invitionType || '-'}</TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      {/* status chip */}
                      {(() => {
                        const s = item.status ?? 0;
                        const labels = ['New','In Progress','Awaiting Hearing','Closed','Won','Lost'];
                        const colors:any = ['default','primary','warning','success','success','error'];
                        return <Chip label={t(`cases.statuses.${labels[s].replace(/ /g,'').toLowerCase()}`) ?? labels[s]} size="small" color={colors[s]} variant="outlined" sx={{ fontWeight: 700 }} />;
                      })()}
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left', whiteSpace: isSmallScreen ? 'nowrap' : 'normal' }}>
                      {item.invitionDate?.slice(0,10) || '-'}
                    </TableCell>
                    {!isCustomerOnly && (
                      <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                        {item.totalAmount ? (
                          <Typography variant="body2" sx={{ fontWeight: 700, color: 'success.main' }}>
                            {formatCurrency(item.totalAmount)}
                          </Typography>
                        ) : '-'}
                      </TableCell>
                    )}
                    {!isCustomerOnly && (
                      <TableCell sx={{ py: 2, maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', textAlign: isRTL ? 'right' : 'left' }}>
                        {item.notes || '-'}
                      </TableCell>
                    )}
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end', flexWrap: 'wrap' }}>
                        <Button 
                          size="small" 
                          variant="contained"
                          onClick={() => openCaseDetails(item.code)}
                          sx={actionButtonSx}
                        >
                          {t('app.details') || 'Details'}
                        </Button>
                        {hasAnyRole('Admin', 'Employee') && (
                          <Tooltip title={t('app.delete')}>
                            <IconButton
                              color="error"
                              onClick={() => remove(item.code)}
                              aria-label={t('app.delete')}
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

        {/* Pagination */}
        <Box sx={paginationContainerSx}>
          <SearchableSelect<number>
            size="small"
            label={t('app.pageSize', { defaultValue: 'Rows per page' })}
            value={pageSize}
            onChange={(value) => {
              const ps = value ?? 10;
              setPageSize(ps);
              setPage(1);
              load(1);
            }}
            options={[
              { value: 5, label: '5' },
              { value: 10, label: '10' },
              { value: 20, label: '20' },
            ]}
            disableClearable
            sx={{ width: 170, flex: '0 0 auto' }}
          />
          <Pagination
            count={Math.max(1, Math.ceil((totalCount || items.length) / pageSize))}
            page={page}
            onChange={(_, v) => { setPage(v); load(v); }}
            color="primary"
            shape="rounded"
            showFirstButton
            showLastButton
            sx={{ flex: '0 0 auto' }}
          />
        </Box>
      </Paper>

      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{
          sx: { borderRadius: 4, p: 1 }
        }}
      >
        <DialogTitle sx={{ fontWeight: 800, fontSize: '1.5rem', pb: 1, textAlign: isRTL ? 'right' : 'left' }}>
          {t('cases.createNew')}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                required
                label={t('cases.code')}
                type="number"
                value={code || ''}
                onChange={(e) => setCode(Number(e.target.value))}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <SearchableSelect<string>
                label={t('cases.type')}
                value={invitionType || null}
                onChange={(value) => setInvitionType(value ?? '')}
                options={caseTypeOptions}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField
                fullWidth
                required
                label={t('cases.statement', { defaultValue: 'Statement' })}
                multiline
                minRows={3}
                value={invitionsStatment}
                onChange={(e) => setInvitionsStatment(e.target.value)}
                placeholder={t('cases.statementHint', { defaultValue: 'Case summary, allegations, and legal context' })}
                error={invitionsStatment.length > 0 && invitionsStatment.trim().length < MIN_STATEMENT_LENGTH}
                helperText={
                  invitionsStatment.length > 0 && invitionsStatment.trim().length < MIN_STATEMENT_LENGTH
                    ? t('cases.validation.statementTooShort', { defaultValue: `At least ${MIN_STATEMENT_LENGTH} characters required.`, min: MIN_STATEMENT_LENGTH })
                    : t('cases.statementCharCount', { defaultValue: `${invitionsStatment.trim().length} / ${MIN_STATEMENT_LENGTH}+ characters`, count: invitionsStatment.trim().length, min: MIN_STATEMENT_LENGTH })
                }
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                required
                label={t('cases.date')}
                type="date"
                InputLabelProps={{ shrink: true }}
                value={invitionDate}
                onChange={(e) => setInvitionDate(e.target.value)}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                label={t('cases.amount')}
                inputMode="numeric"
                value={formatAmountInput(totalAmountInput)}
                onChange={(e) => setTotalAmountInput(sanitizeAmountInput(e.target.value))}
                error={totalAmount < 0 || totalAmount > MAX_TOTAL_AMOUNT}
                helperText={
                  totalAmount < 0 || totalAmount > MAX_TOTAL_AMOUNT
                    ? t('cases.validation.amountInvalid', { defaultValue: `Amount must be between 0 and ${MAX_TOTAL_AMOUNT.toLocaleString()}.`, max: MAX_TOTAL_AMOUNT })
                    : `${t('cases.amountPreview', { defaultValue: 'Formatted' })}: ${formatCurrency(totalAmount || 0)}`
                }
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <SearchableSelect<number>
                label={t('courts.name')}
                value={typeof selectedCourt === 'number' ? selectedCourt : null}
                onChange={(value)=>setSelectedCourt(value ?? '')}
                options={courts.map((c)=> ({ value: c.id, label: c.name }))}
              />
            </Grid>

            <Grid size={{ xs: 12, sm: 6 }}>
              <SearchableSelect<number>
                label={t('customers.customer')}
                value={typeof primaryCustomer === 'number' ? primaryCustomer : null}
                onChange={(value)=>setPrimaryCustomer(value ?? '')}
                options={customers.map((c)=> ({
                  value: c.id,
                  label: c.identity?.fullName || c.user?.fullName || c.identity?.email || '-',
                  keywords: [c.identity?.email || '', c.user?.fullName || ''],
                }))}
              />
            </Grid>

            <Grid size={{ xs: 12, sm: 6 }}>
              <SearchableMultiSelect<number>
                label={t('customers.management')}
                value={selectedCustomers}
                onChange={setSelectedCustomers}
                options={customers.map((c) => ({
                  value: c.id,
                  label: c.identity?.fullName || c.user?.fullName || '-',
                  keywords: [c.identity?.email || '', c.user?.fullName || ''],
                }))}
              />
            </Grid>

            <Grid size={{ xs: 12, sm: 6 }}>
              <Box>
                <SearchableMultiSelect<number>
                  label={t('contenders.title') || 'Contenders'}
                  value={selectedContenders}
                  onChange={setSelectedContenders}
                  options={contenders.map((c)=> ({
                    value: c.id,
                    label: c.fullName,
                  }))}
                />
                <Box sx={{ mt:1 }}>
                  <Button size="small" onClick={()=>setContenderDialogOpen(true)}>{t('contenders.title')}: {t('app.add') || 'Add'}</Button>
                </Box>
              </Box>
            </Grid>

            <Grid size={{ xs: 12 }}>
              <Box>
                <Typography variant="subtitle2">{t('cases.sitings') || 'Sitings'}</Typography>
                <List dense>
                  {pendingSitings.map((s, idx)=>(
                    <ListItem key={idx} secondaryAction={<Button size="small" onClick={()=>setPendingSitings(prev=>prev.filter((_,i)=>i!==idx))}>{t('app.delete')}</Button>}>
                      <ListItemText primary={`${s.date} ${s.time} - ${s.judgeName}`} secondary={s.notes} />
                    </ListItem>
                  ))}
                </List>
                <Button size="small" onClick={()=>setSitingDialogOpen(true)}>{t('cases.createNewSiting') || 'Add Siting'}</Button>
              </Box>
            </Grid>

            <Grid size={{ xs: 12 }}>
              <Box>
                <Typography variant="subtitle2">{t('files.title') || 'Files'}</Typography>
                <input type="file" multiple onChange={(e)=>{
                  if(!e.target.files) return;
                  const list = Array.from(e.target.files);
                  setPendingFiles(prev => [...prev, ...list]);
                }} />
                <List dense>
                  {pendingFiles.map((f, idx)=> (<ListItem key={idx} secondaryAction={<Button size="small" onClick={()=>setPendingFiles(prev=>prev.filter((_,i)=>i!==idx))}>{t('app.delete')}</Button>}><ListItemText primary={f.name} /></ListItem>))}
                </List>
              </Box>
            </Grid>

            <Grid size={{ xs: 12 }}>
              <TextField fullWidth label={t('cases.notes')} multiline rows={3} value={notes} onChange={(e) => setNotes(e.target.value)} />
            </Grid>
          </Grid>
        </DialogContent>

        {/* New Contender Dialog */}
        <Dialog open={contenderDialogOpen} onClose={() => setContenderDialogOpen(false)} maxWidth="sm" fullWidth>
          <DialogTitle>{t('contenders.title')}</DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid size={{ xs: 12 }}>
                <TextField fullWidth label={t('contenders.title')} value={newContender.fullName} onChange={(e)=>setNewContender({...newContender, fullName: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('customers.ssn')} value={newContender.ssn} onChange={(e)=>setNewContender({...newContender, ssn: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('customers.dateOfBirth')} type="date" InputLabelProps={{ shrink: true }} value={newContender.birthDate} onChange={(e)=>setNewContender({...newContender, birthDate: e.target.value})} />
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={()=>setContenderDialogOpen(false)}>{t('app.cancel')}</Button>
            <Button variant="contained" onClick={async ()=>{
              try{
                const payload = { FullName: newContender.fullName, SSN: newContender.ssn, BirthDate: newContender.birthDate };
                const r = await api.post('/Contenders', payload);
                setSelectedContenders(prev => [...prev, r.data.id]);
                setContenders(prev => [...prev, r.data]);
                setContenderDialogOpen(false);
                setNewContender({ fullName: '', ssn: '', birthDate: '' });
                setSnackbar({ open: true, message: t('contenders.title') + ' created', severity: 'success' });
              }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? 'Failed to create contender', severity: 'error' }); }
            }}>{t('app.create')}</Button>
          </DialogActions>
        </Dialog>

        {/* New Siting Dialog (local add) */}
        <Dialog open={sitingDialogOpen} onClose={() => setSitingDialogOpen(false)} maxWidth="sm" fullWidth>
          <DialogTitle>{t('cases.createNewSiting') || 'Add Siting'}</DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('cases.date') }
                  type="date" InputLabelProps={{ shrink: true }} value={newSiting.date} onChange={(e)=>setNewSiting({...newSiting, date: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('cases.time') || 'Time'} type="time" value={newSiting.time} onChange={(e)=>setNewSiting({...newSiting, time: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12 }}>
                <TextField fullWidth label={t('cases.judge') || 'Judge'} value={newSiting.judgeName} onChange={(e)=>setNewSiting({...newSiting, judgeName: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12 }}>
                <TextField fullWidth label={t('cases.notes')} value={newSiting.notes} onChange={(e)=>setNewSiting({...newSiting, notes: e.target.value})} />
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={()=>setSitingDialogOpen(false)}>{t('app.cancel')}</Button>
            <Button variant="contained" onClick={()=>{
              setPendingSitings(prev => [...prev, newSiting]);
              setSitingDialogOpen(false);
              setNewSiting({ date: '', time: '', judgeName: '', notes: '' });
            }}>{t('app.create')}</Button>
          </DialogActions>
        </Dialog>

        <DialogActions sx={{ p: 3, pt: 1, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Button onClick={() => setOpenDialog(false)} sx={{ fontWeight: 600 }}>{t('app.cancel')}</Button>
          <LoadingButton
            variant="contained"
            onClick={create}
            loading={creating}
            loadingPosition="start"
            disabled={!code || !invitionsStatment.trim() || !invitionType.trim() || !invitionDate}
            sx={{
              borderRadius: 2.5,
              px: 4,
              fontWeight: 700,
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
            }}
          >
            {t('app.create')}
          </LoadingButton>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={6000} 
        onClose={() => setSnackbar({ ...snackbar, open: false })} 
        anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          variant="filled"
          role="alert"
          aria-live="polite"
          sx={{ width: '100%', borderRadius: 3, boxShadow: '0 8px 16px rgba(0,0,0,0.1)' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
