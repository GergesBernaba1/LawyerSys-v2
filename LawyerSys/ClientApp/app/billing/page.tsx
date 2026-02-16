"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, useTheme, Tabs, Tab, Card, CardContent,
  MenuItem, Select, InputLabel, FormControl,
} from '@mui/material';
import {
  Receipt as ReceiptIcon,
  Add as AddIcon, Delete as DeleteIcon,
  Refresh as RefreshIcon, Payment as PaymentIcon,
  AccountBalanceWallet as WalletIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';

type BillingPayDto = { id: number; amount: number; dateOfOperation: string; notes: string; customerId: number; customerName?: string };
type BillingReceiptDto = { id: number; amount: number; dateOfOperation: string; notes: string; employeeId: number };
type CustomerItem = { id: number; usersId: number; identity?: { fullName?: string; email?: string } };
type EmployeeItem = { id: number; usersId: number; identity?: { fullName?: string; email?: string } };

export default function BillingPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const { isAuthenticated } = useAuth();

  const [tab, setTab] = useState(0);
  const [payments, setPayments] = useState<BillingPayDto[]>([]);
  const [receipts, setReceipts] = useState<BillingReceiptDto[]>([]);
  const [customers, setCustomers] = useState<CustomerItem[]>([]);
  const [employees, setEmployees] = useState<EmployeeItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [openPayDialog, setOpenPayDialog] = useState(false);
  const [openRecDialog, setOpenRecDialog] = useState(false);
  const [payForm, setPayForm] = useState({ amount: 0, dateOfOperation: '', notes: '', customerId: 0 });
  const [recForm, setRecForm] = useState({ amount: 0, dateOfOperation: '', notes: '', employeeId: 0 });
  const [summary, setSummary] = useState<any>(null);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const [payRes, recRes, custRes, empRes, sumRes] = await Promise.all([
        api.get('/Billing/payments'),
        api.get('/Billing/receipts'),
        api.get('/Customers'),
        api.get('/Employees'),
        api.get('/Billing/summary'),
      ]);
      setPayments(payRes.data || []);
      setReceipts(recRes.data || []);
      setCustomers(custRes.data || []);
      setEmployees(empRes.data || []);
      setSummary(sumRes.data || null);
    } catch {
      setSnackbar({ open: true, message: t('billing.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function submitPayment() {
    try {
      await api.post('/Billing/payments', payForm);
      setSnackbar({ open: true, message: t('billing.paymentCreated'), severity: 'success' });
      setOpenPayDialog(false);
      setPayForm({ amount: 0, dateOfOperation: '', notes: '', customerId: 0 });
      load();
    } catch {
      setSnackbar({ open: true, message: t('billing.failedCreate'), severity: 'error' });
    }
  }

  async function submitReceipt() {
    try {
      await api.post('/Billing/receipts', recForm);
      setSnackbar({ open: true, message: t('billing.receiptCreated'), severity: 'success' });
      setOpenRecDialog(false);
      setRecForm({ amount: 0, dateOfOperation: '', notes: '', employeeId: 0 });
      load();
    } catch {
      setSnackbar({ open: true, message: t('billing.failedCreate'), severity: 'error' });
    }
  }

  async function removePayment(id: number) {
    if (!confirm(t('billing.confirmDelete'))) return;
    try {
      await api.delete(`/Billing/payments/${id}`);
      setSnackbar({ open: true, message: t('billing.deleted'), severity: 'success' });
      load();
    } catch {
      setSnackbar({ open: true, message: t('billing.failedDelete'), severity: 'error' });
    }
  }

  async function removeReceipt(id: number) {
    if (!confirm(t('billing.confirmDelete'))) return;
    try {
      await api.delete(`/Billing/receipts/${id}`);
      setSnackbar({ open: true, message: t('billing.deleted'), severity: 'success' });
      load();
    } catch {
      setSnackbar({ open: true, message: t('billing.failedDelete'), severity: 'error' });
    }
  }

  function formatDate(d: string) {
    if (!d) return '-';
    try { return new Date(d).toLocaleDateString(); } catch { return d; }
  }

  function formatAmount(a: number) {
    return `${a.toLocaleString()} ${t('app.currency')}`;
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box sx={{ bgcolor: 'primary.main', color: 'white', p: 1.5, borderRadius: 3, display: 'flex', boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)' }}>
            <ReceiptIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>{t('billing.management')}</Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('common.refresh')}>
            <IconButton onClick={load} disabled={loading} sx={{ bgcolor: 'background.paper', border: '1px solid', borderColor: 'divider', '&:hover': { bgcolor: 'grey.50' } }}>
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      {/* Summary Cards */}
      {summary && (
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr 1fr' }, gap: 2, mb: 4 }}>
          <Card sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
            <CardContent sx={{ textAlign: 'center' }}>
              <PaymentIcon color="error" sx={{ fontSize: 32, mb: 1 }} />
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{formatAmount(summary.totalPayments || 0)}</Typography>
              <Typography variant="body2" color="text.secondary">{t('billing.totalPayments')}</Typography>
            </CardContent>
          </Card>
          <Card sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
            <CardContent sx={{ textAlign: 'center' }}>
              <WalletIcon color="success" sx={{ fontSize: 32, mb: 1 }} />
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{formatAmount(summary.totalReceipts || 0)}</Typography>
              <Typography variant="body2" color="text.secondary">{t('billing.totalReceipts')}</Typography>
            </CardContent>
          </Card>
          <Card sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
            <CardContent sx={{ textAlign: 'center' }}>
              <ReceiptIcon color="info" sx={{ fontSize: 32, mb: 1 }} />
              <Typography variant="h6" sx={{ fontWeight: 700, color: (summary.balance || 0) >= 0 ? 'success.main' : 'error.main' }}>{formatAmount(summary.balance || 0)}</Typography>
              <Typography variant="body2" color="text.secondary">{t('billing.balance')}</Typography>
            </CardContent>
          </Card>
        </Box>
      )}

      {/* Tabs */}
      <Box sx={{ mb: 3 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ direction: isRTL ? 'rtl' : 'ltr' }}>
          <Tab label={t('billing.payments')} />
          <Tab label={t('billing.receipts')} />
        </Tabs>
      </Box>

      {/* Payments Tab */}
      {tab === 0 && (
        <>
          <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', mb: 2 }}>
            <Button variant="contained" startIcon={!isRTL ? <AddIcon /> : undefined} endIcon={isRTL ? <AddIcon /> : undefined} onClick={() => setOpenPayDialog(true)}
              sx={{ borderRadius: 2.5, px: 3, fontWeight: 700, boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)' }}>
              {t('billing.createNewPayment')}
            </Button>
          </Box>
          <Paper elevation={0} sx={{ borderRadius: 4, border: '1px solid', borderColor: 'divider', overflow: 'hidden', bgcolor: 'background.paper', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
            <TableContainer>
              <Table sx={{ minWidth: 650 }}>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>ID</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.amount')}</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.date')}</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.customer')}</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.notes')}</TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5, fontWeight: 700 }}>{t('common.actions')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {loading ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <TableRow key={i}>{[...Array(6)].map((__, j) => <TableCell key={j}><Skeleton variant="text" /></TableCell>)}</TableRow>
                    ))
                  ) : payments.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} align="center" sx={{ py: 8 }}>
                        <Typography color="text.secondary">{t('billing.noPayments')}</Typography>
                      </TableCell>
                    </TableRow>
                  ) : payments.map((item) => (
                    <TableRow key={item.id} sx={{ '&:hover': { bgcolor: 'grey.50' } }}>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}><Chip label={`#${item.id}`} size="small" variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} /></TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, color: 'error.main' }}>{formatAmount(item.amount)}</TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{formatDate(item.dateOfOperation)}</TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{item.customerName || '-'}</TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left', maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.notes || '-'}</TableCell>
                      <TableCell align={isRTL ? 'left' : 'right'}>
                        <Tooltip title={t('common.delete')}>
                          <IconButton color="error" onClick={() => removePayment(item.id)} sx={{ '&:hover': { bgcolor: 'error.light', color: 'white' } }}>
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Paper>
        </>
      )}

      {/* Receipts Tab */}
      {tab === 1 && (
        <>
          <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', mb: 2 }}>
            <Button variant="contained" startIcon={!isRTL ? <AddIcon /> : undefined} endIcon={isRTL ? <AddIcon /> : undefined} onClick={() => setOpenRecDialog(true)}
              sx={{ borderRadius: 2.5, px: 3, fontWeight: 700, boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)' }}>
              {t('billing.createNewReceipt')}
            </Button>
          </Box>
          <Paper elevation={0} sx={{ borderRadius: 4, border: '1px solid', borderColor: 'divider', overflow: 'hidden', bgcolor: 'background.paper', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
            <TableContainer>
              <Table sx={{ minWidth: 650 }}>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>ID</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.amount')}</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.date')}</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.employee')}</TableCell>
                    <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('billing.notes')}</TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5, fontWeight: 700 }}>{t('common.actions')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {loading ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <TableRow key={i}>{[...Array(6)].map((__, j) => <TableCell key={j}><Skeleton variant="text" /></TableCell>)}</TableRow>
                    ))
                  ) : receipts.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} align="center" sx={{ py: 8 }}>
                        <Typography color="text.secondary">{t('billing.noReceipts')}</Typography>
                      </TableCell>
                    </TableRow>
                  ) : receipts.map((item) => (
                    <TableRow key={item.id} sx={{ '&:hover': { bgcolor: 'grey.50' } }}>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}><Chip label={`#${item.id}`} size="small" variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} /></TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, color: 'success.main' }}>{formatAmount(item.amount)}</TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{formatDate(item.dateOfOperation)}</TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{item.employeeId}</TableCell>
                      <TableCell sx={{ textAlign: isRTL ? 'right' : 'left', maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.notes || '-'}</TableCell>
                      <TableCell align={isRTL ? 'left' : 'right'}>
                        <Tooltip title={t('common.delete')}>
                          <IconButton color="error" onClick={() => removeReceipt(item.id)} sx={{ '&:hover': { bgcolor: 'error.light', color: 'white' } }}>
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Paper>
        </>
      )}

      {/* Payment Dialog */}
      <Dialog open={openPayDialog} onClose={() => setOpenPayDialog(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: 3, p: 1 } }}>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>{t('billing.createNewPayment')}</DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, mt: 2 }}>
            <TextField fullWidth label={t('billing.amount')} type="number" value={payForm.amount} onChange={(e) => setPayForm({ ...payForm, amount: Number(e.target.value) })} variant="outlined" />
            <TextField fullWidth label={t('billing.date')} type="date" value={payForm.dateOfOperation} onChange={(e) => setPayForm({ ...payForm, dateOfOperation: e.target.value })} InputLabelProps={{ shrink: true }} variant="outlined" />
            <FormControl fullWidth variant="outlined">
              <InputLabel>{t('billing.customer')}</InputLabel>
              <Select value={payForm.customerId} onChange={(e) => setPayForm({ ...payForm, customerId: Number(e.target.value) })} label={t('billing.customer')}>
                <MenuItem value={0}>-</MenuItem>
                {customers.map((c) => <MenuItem key={c.id} value={c.id}>{c.identity?.fullName || c.identity?.email || `#${c.id}`}</MenuItem>)}
              </Select>
            </FormControl>
            <TextField fullWidth label={t('billing.notes')} value={payForm.notes} onChange={(e) => setPayForm({ ...payForm, notes: e.target.value })} variant="outlined" multiline rows={2} />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenPayDialog(false)} sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={submitPayment} sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}>{t('common.create')}</Button>
        </DialogActions>
      </Dialog>

      {/* Receipt Dialog */}
      <Dialog open={openRecDialog} onClose={() => setOpenRecDialog(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: 3, p: 1 } }}>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>{t('billing.createNewReceipt')}</DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, mt: 2 }}>
            <TextField fullWidth label={t('billing.amount')} type="number" value={recForm.amount} onChange={(e) => setRecForm({ ...recForm, amount: Number(e.target.value) })} variant="outlined" />
            <TextField fullWidth label={t('billing.date')} type="date" value={recForm.dateOfOperation} onChange={(e) => setRecForm({ ...recForm, dateOfOperation: e.target.value })} InputLabelProps={{ shrink: true }} variant="outlined" />
            <FormControl fullWidth variant="outlined">
              <InputLabel>{t('billing.employee')}</InputLabel>
              <Select value={recForm.employeeId} onChange={(e) => setRecForm({ ...recForm, employeeId: Number(e.target.value) })} label={t('billing.employee')}>
                <MenuItem value={0}>-</MenuItem>
                {employees.map((emp) => <MenuItem key={emp.id} value={emp.id}>{emp.identity?.fullName || emp.identity?.email || `#${emp.id}`}</MenuItem>)}
              </Select>
            </FormControl>
            <TextField fullWidth label={t('billing.notes')} value={recForm.notes} onChange={(e) => setRecForm({ ...recForm, notes: e.target.value })} variant="outlined" multiline rows={2} />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenRecDialog(false)} sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={submitReceipt} sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}>{t('common.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled" sx={{ borderRadius: 2, fontWeight: 600 }}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
