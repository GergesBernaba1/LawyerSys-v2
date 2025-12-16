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
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Tab,
  Tabs,
  Divider,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Receipt as ReceiptIcon,
  Payment as PaymentIcon,
  Refresh as RefreshIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
} from '@mui/icons-material';
import api from '../services/api';

type Pay = { id: number; amount?: number; dateOfOperation?: string; notes?: string; customerId?: number; customerName?: string };
type Receipt = { id: number; amount?: number; dateOfOperation?: string; notes?: string; employeeId?: number };

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div role="tabpanel" hidden={value !== index} {...other}>
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

export default function Billing() {
  const { t } = useTranslation();
  const [payments, setPayments] = useState<Pay[]>([]);
  const [receipts, setReceipts] = useState<Receipt[]>([]);
  const [loading, setLoading] = useState(false);
  const [tabValue, setTabValue] = useState(0);

  const [payAmount, setPayAmount] = useState<number | ''>('');
  const [payDate, setPayDate] = useState('');
  const [payNotes, setPayNotes] = useState('');
  const [payCustomer, setPayCustomer] = useState<number | ''>('');
  const [payDialogOpen, setPayDialogOpen] = useState(false);

  const [recAmount, setRecAmount] = useState<number | ''>('');
  const [recDate, setRecDate] = useState('');
  const [recNotes, setRecNotes] = useState('');
  const [recEmployee, setRecEmployee] = useState<number | ''>('');
  const [recDialogOpen, setRecDialogOpen] = useState(false);

  const [customers, setCustomers] = useState<{ id: number; user?: any }[]>([]);
  const [employees, setEmployees] = useState<{ id: number; user?: any }[]>([]);

  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  async function load() {
    setLoading(true);
    try {
      const [p, r, c, e] = await Promise.all([
        api.get('/Billing/payments'),
        api.get('/Billing/receipts'),
        api.get('/Customers'),
        api.get('/Employees'),
      ]);
      setPayments(p.data);
      setReceipts(r.data);
      setCustomers(c.data);
      setEmployees(e.data);
    } catch (err) {
      setSnackbar({ open: true, message: t('billing.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  const totalPayments = payments.reduce((sum, p) => sum + (p.amount || 0), 0);
  const totalReceipts = receipts.reduce((sum, r) => sum + (r.amount || 0), 0);

  async function createPayment() {
    try {
      await api.post('/Billing/payments', {
        amount: payAmount,
        dateOfOperation: payDate || undefined,
        notes: payNotes,
        customerId: payCustomer || undefined,
      });
      setPayAmount('');
      setPayDate('');
      setPayNotes('');
      setPayCustomer('');
      setPayDialogOpen(false);
      await load();
      setSnackbar({ open: true, message: t('billing.paymentCreated'), severity: 'success' });
    } catch (e: any) {
      setSnackbar({ open: true, message: e?.response?.data?.message || t('billing.failed'), severity: 'error' });
    }
  }

  async function createReceipt() {
    try {
      await api.post('/Billing/receipts', {
        amount: recAmount,
        dateOfOperation: recDate || undefined,
        notes: recNotes,
        employeeId: recEmployee || undefined,
      });
      setRecAmount('');
      setRecDate('');
      setRecNotes('');
      setRecEmployee('');
      setRecDialogOpen(false);
      await load();
      setSnackbar({ open: true, message: t('billing.receiptCreated'), severity: 'success' });
    } catch (e: any) {
      setSnackbar({ open: true, message: e?.response?.data?.message || t('billing.failed'), severity: 'error' });
    }
  }

  async function removePayment(id: number) {
    if (!confirm(t('billing.confirmDeletePayment'))) return;
    try {
      await api.delete(`/Billing/payments/${id}`);
      await load();
      setSnackbar({ open: true, message: t('billing.paymentDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('billing.failed'), severity: 'error' });
    }
  }

  async function removeReceipt(id: number) {
    if (!confirm(t('billing.confirmDeleteReceipt'))) return;
    try {
      await api.delete(`/Billing/receipts/${id}`);
      await load();
      setSnackbar({ open: true, message: t('billing.receiptDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('billing.failed'), severity: 'error' });
    }
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <ReceiptIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>
            {t('billing.management')}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton onClick={load} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ bgcolor: 'success.light', color: 'white' }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    {t('billing.totalPayments')}
                  </Typography>
                  <Typography variant="h4" fontWeight={700}>
                    ${totalPayments.toLocaleString()}
                  </Typography>
                </Box>
                <TrendingUpIcon sx={{ fontSize: 48, opacity: 0.5 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ bgcolor: 'error.light', color: 'white' }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    {t('billing.totalReceipts')}
                  </Typography>
                  <Typography variant="h4" fontWeight={700}>
                    ${totalReceipts.toLocaleString()}
                  </Typography>
                </Box>
                <TrendingDownIcon sx={{ fontSize: 48, opacity: 0.5 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ bgcolor: 'primary.main', color: 'white' }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    {t('billing.netBalance')}
                  </Typography>
                  <Typography variant="h4" fontWeight={700}>
                    ${(totalPayments - totalReceipts).toLocaleString()}
                  </Typography>
                </Box>
                <ReceiptIcon sx={{ fontSize: 48, opacity: 0.5 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)} sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tab icon={<PaymentIcon />} iconPosition="start" label={t('billing.payments')} />
          <Tab icon={<ReceiptIcon />} iconPosition="start" label={t('billing.receipts')} />
        </Tabs>

        <TabPanel value={tabValue} index={0}>
          <Box sx={{ p: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
              <Button variant="contained" startIcon={<AddIcon />} onClick={() => setPayDialogOpen(true)}>
                {t('billing.newPayment')}
              </Button>
            </Box>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>{t('billing.amount')}</TableCell>
                    <TableCell>{t('billing.date')}</TableCell>
                    <TableCell>{t('billing.customer')}</TableCell>
                    <TableCell>{t('billing.notes')}</TableCell>
                    <TableCell align="right">{t('common.actions')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {loading ? (
                    [...Array(3)].map((_, i) => (
                      <TableRow key={i}>
                        {[...Array(5)].map((_, j) => (
                          <TableCell key={j}>
                            <Skeleton />
                          </TableCell>
                        ))}
                      </TableRow>
                    ))
                  ) : payments.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>
                        {t('billing.noPayments')}
                      </TableCell>
                    </TableRow>
                  ) : (
                    payments.map((p) => (
                      <TableRow key={p.id} hover>
                        <TableCell>
                          <Chip label={`$${p.amount?.toLocaleString() || 0}`} color="success" variant="outlined" />
                        </TableCell>
                        <TableCell>{p.dateOfOperation?.slice(0, 10) || '-'}</TableCell>
                        <TableCell>{p.customerName || p.customerId || '-'}</TableCell>
                        <TableCell>{p.notes || '-'}</TableCell>
                        <TableCell align="right">
                          <Tooltip title={t('app.delete')}>
                            <IconButton color="error" onClick={() => removePayment(p.id)}>
                              <DeleteIcon />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Box sx={{ p: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
              <Button variant="contained" startIcon={<AddIcon />} onClick={() => setRecDialogOpen(true)}>
                {t('billing.newReceipt')}
              </Button>
            </Box>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>{t('billing.amount')}</TableCell>
                    <TableCell>{t('billing.date')}</TableCell>
                    <TableCell>{t('billing.employee')}</TableCell>
                    <TableCell>{t('billing.notes')}</TableCell>
                    <TableCell align="right">{t('common.actions')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {loading ? (
                    [...Array(3)].map((_, i) => (
                      <TableRow key={i}>
                        {[...Array(5)].map((_, j) => (
                          <TableCell key={j}>
                            <Skeleton />
                          </TableCell>
                        ))}
                      </TableRow>
                    ))
                  ) : receipts.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}>
                        {t('billing.noReceipts')}
                      </TableCell>
                    </TableRow>
                  ) : (
                    receipts.map((r) => (
                      <TableRow key={r.id} hover>
                        <TableCell>
                          <Chip label={`$${r.amount?.toLocaleString() || 0}`} color="error" variant="outlined" />
                        </TableCell>
                        <TableCell>{r.dateOfOperation?.slice(0, 10) || '-'}</TableCell>
                        <TableCell>{r.employeeId || '-'}</TableCell>
                        <TableCell>{r.notes || '-'}</TableCell>
                        <TableCell align="right">
                          <Tooltip title={t('common.delete')}>
                            <IconButton color="error" onClick={() => removeReceipt(r.id)}>
                              <DeleteIcon />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        </TabPanel>
      </Paper>

      {/* Payment Dialog */}
      <Dialog open={payDialogOpen} onClose={() => setPayDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('billing.newPayment')}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                label={t('billing.amount')}
                type="number"
                value={payAmount}
                onChange={(e) => setPayAmount(Number(e.target.value) || '')}
                InputProps={{ startAdornment: <Typography sx={{ mr: 1 }}>$</Typography> }}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                label={t('billing.date')}
                type="date"
                value={payDate}
                onChange={(e) => setPayDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <FormControl fullWidth>
                <InputLabel>{t('billing.customer')}</InputLabel>
                <Select value={payCustomer} label={t('billing.customer')} onChange={(e) => setPayCustomer(Number(e.target.value) || '')}>
                  <MenuItem value="">
                    <em>{t('billing.selectCustomer')}</em>
                  </MenuItem>
                  {customers.map((c) => (
                    <MenuItem key={c.id} value={c.id}>
                      #{c.id} - {c.user?.fullName || 'Unknown'}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField fullWidth label={t('billing.notes')} multiline rows={2} value={payNotes} onChange={(e) => setPayNotes(e.target.value)} />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setPayDialogOpen(false)}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={createPayment} disabled={!payAmount}>
            {t('common.create')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Receipt Dialog */}
      <Dialog open={recDialogOpen} onClose={() => setRecDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('billing.newReceipt')}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                label={t('billing.amount')}
                type="number"
                value={recAmount}
                onChange={(e) => setRecAmount(Number(e.target.value) || '')}
                InputProps={{ startAdornment: <Typography sx={{ mr: 1 }}>$</Typography> }}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                label={t('billing.date')}
                type="date"
                value={recDate}
                onChange={(e) => setRecDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <FormControl fullWidth>
                <InputLabel>{t('billing.employee')}</InputLabel>
                <Select value={recEmployee} label={t('billing.employee')} onChange={(e) => setRecEmployee(Number(e.target.value) || '')}>
                  <MenuItem value="">
                    <em>{t('billing.selectEmployee')}</em>
                  </MenuItem>
                  {employees.map((e) => (
                    <MenuItem key={e.id} value={e.id}>
                      #{e.id} - {e.user?.fullName || 'Unknown'}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField fullWidth label={t('billing.notes')} multiline rows={2} value={recNotes} onChange={(e) => setRecNotes(e.target.value)} />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setRecDialogOpen(false)}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={createReceipt} disabled={!recAmount}>
            {t('common.create')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
