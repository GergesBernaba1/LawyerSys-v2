import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, TablePagination, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, FormControl, InputLabel, Select, MenuItem, Grid,
  Tab, Tabs, useTheme, alpha, Avatar, Card, CardContent
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, Receipt as ReceiptIcon, Payment as PaymentIcon,
  Refresh as RefreshIcon, TrendingUp as TrendingUpIcon, TrendingDown as TrendingDownIcon,
  AccountBalanceWallet as WalletIcon, Person as PersonIcon, Event as EventIcon,
  Description as DescriptionIcon
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
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const [payments, setPayments] = useState<Pay[]>([]);
  const [receipts, setReceipts] = useState<Receipt[]>([]);
  const [loading, setLoading] = useState(false);
  const [tabValue, setTabValue] = useState(0);

  // Pagination for payments
  const [paymentsPage, setPaymentsPage] = useState(0);
  const [paymentsRowsPerPage, setPaymentsRowsPerPage] = useState(10);
  React.useEffect(() => { setPaymentsPage(0); }, [payments]);
  const paymentsPageItems = payments.slice(paymentsPage * paymentsRowsPerPage, paymentsPage * paymentsRowsPerPage + paymentsRowsPerPage);
  const handlePaymentsPageChange = (_: any, newPage: number) => setPaymentsPage(newPage);
  const handlePaymentsRowsPerPageChange = (e: React.ChangeEvent<HTMLInputElement>) => { setPaymentsRowsPerPage(parseInt(e.target.value, 10)); setPaymentsPage(0); };

  // Pagination for receipts
  const [receiptsPage, setReceiptsPage] = useState(0);
  const [receiptsRowsPerPage, setReceiptsRowsPerPage] = useState(10);
  React.useEffect(() => { setReceiptsPage(0); }, [receipts]);
  const receiptsPageItems = receipts.slice(receiptsPage * receiptsRowsPerPage, receiptsPage * receiptsRowsPerPage + receiptsRowsPerPage);
  const handleReceiptsPageChange = (_: any, newPage: number) => setReceiptsPage(newPage);
  const handleReceiptsRowsPerPageChange = (e: React.ChangeEvent<HTMLInputElement>) => { setReceiptsRowsPerPage(parseInt(e.target.value, 10)); setReceiptsPage(0); }; 

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
              <ReceiptIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('billing.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('billing.subtitle', 'Manage financial transactions, payments, and receipts with precision.')}
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
          </Box>
        </Box>
        
        {/* Decorative background elements */}
        <Box sx={{ position: 'absolute', top: -50, right: -50, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,255,255,0.1)', zIndex: 0 }} />
        <Box sx={{ position: 'absolute', bottom: -30, left: '20%', width: 120, height: 120, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', zIndex: 0 }} />
      </Paper>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={4}>
          <Card sx={{ 
            borderRadius: 5, 
            bgcolor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider',
            boxShadow: '0 10px 30px rgba(0,0,0,0.04)',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <CardContent sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" color="success.main" fontWeight={800} sx={{ mb: 1, textTransform: 'uppercase', letterSpacing: 1 }}>
                    {t('billing.totalPayments')}
                  </Typography>
                  <Typography variant="h3" fontWeight={800} color="text.primary">
                    ${totalPayments.toLocaleString()}
                  </Typography>
                </Box>
                <Box sx={{ 
                  width: 60, 
                  height: 60, 
                  borderRadius: 3, 
                  bgcolor: alpha(theme.palette.success.main, 0.1), 
                  color: 'success.main',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <TrendingUpIcon fontSize="large" />
                </Box>
              </Box>
            </CardContent>
            <Box sx={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 4, bgcolor: 'success.main' }} />
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card sx={{ 
            borderRadius: 5, 
            bgcolor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider',
            boxShadow: '0 10px 30px rgba(0,0,0,0.04)',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <CardContent sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" color="error.main" fontWeight={800} sx={{ mb: 1, textTransform: 'uppercase', letterSpacing: 1 }}>
                    {t('billing.totalReceipts')}
                  </Typography>
                  <Typography variant="h3" fontWeight={800} color="text.primary">
                    ${totalReceipts.toLocaleString()}
                  </Typography>
                </Box>
                <Box sx={{ 
                  width: 60, 
                  height: 60, 
                  borderRadius: 3, 
                  bgcolor: alpha(theme.palette.error.main, 0.1), 
                  color: 'error.main',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <TrendingDownIcon fontSize="large" />
                </Box>
              </Box>
            </CardContent>
            <Box sx={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 4, bgcolor: 'error.main' }} />
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card sx={{ 
            borderRadius: 5, 
            bgcolor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider',
            boxShadow: '0 10px 30px rgba(0,0,0,0.04)',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <CardContent sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" color="primary.main" fontWeight={800} sx={{ mb: 1, textTransform: 'uppercase', letterSpacing: 1 }}>
                    {t('billing.netBalance')}
                  </Typography>
                  <Typography variant="h3" fontWeight={800} color="text.primary">
                    ${(totalPayments - totalReceipts).toLocaleString()}
                  </Typography>
                </Box>
                <Box sx={{ 
                  width: 60, 
                  height: 60, 
                  borderRadius: 3, 
                  bgcolor: alpha(theme.palette.primary.main, 0.1), 
                  color: 'primary.main',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <WalletIcon fontSize="large" />
                </Box>
              </Box>
            </CardContent>
            <Box sx={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 4, bgcolor: 'primary.main' }} />
          </Card>
        </Grid>
      </Grid>

      {/* Tabs Section */}
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
        <Tabs 
          value={tabValue} 
          onChange={(_, v) => setTabValue(v)} 
          sx={{ 
            px: 2,
            pt: 1,
            borderBottom: 1, 
            borderColor: 'divider',
            bgcolor: 'grey.50',
            '& .MuiTab-root': {
              fontWeight: 800,
              minHeight: 70,
              fontSize: '1rem',
              textTransform: 'none',
              color: 'text.secondary',
              '&.Mui-selected': {
                color: 'primary.main'
              }
            },
            '& .MuiTabs-indicator': {
              height: 4,
              borderRadius: '4px 4px 0 0'
            }
          }}
        >
          <Tab icon={<PaymentIcon />} iconPosition="start" label={t('billing.payments')} />
          <Tab icon={<ReceiptIcon />} iconPosition="start" label={t('billing.receipts')} />
        </Tabs>

        <TabPanel value={tabValue} index={0}>
          <Box sx={{ p: 4 }}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 4 }}>
              <Button 
                variant="contained" 
                startIcon={<AddIcon />} 
                onClick={() => setPayDialogOpen(true)}
                sx={{ 
                  borderRadius: 3, 
                  px: 4, 
                  py: 1.5,
                  fontWeight: 800,
                  boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
                }}
              >
                {t('billing.newPayment')}
              </Button>
            </Box>
            <TableContainer component={Paper} sx={{ maxHeight: 520 }}>
              <Table stickyHeader>
                <TableHead>
                  <TableRow sx={{ bgcolor: 'primary.50' }}>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('billing.amount')}</TableCell>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('billing.date')}</TableCell>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('billing.customer')}</TableCell>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('billing.notes')}</TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {loading ? (
                    [...Array(paymentsRowsPerPage)].map((_, i) => (
                      <TableRow key={i}>
                        {[...Array(5)].map((_, j) => (
                          <TableCell key={j} sx={{ py: 2.5 }}><Skeleton variant="text" height={24} /></TableCell>
                        ))}
                      </TableRow>
                    ))
                  ) : payments.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                        <Box sx={{ opacity: 0.5, mb: 2 }}>
                          <PaymentIcon sx={{ fontSize: 64 }} />
                        </Box>
                        <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('billing.noPayments')}</Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    paymentsPageItems.map((p) => (
                      <TableRow key={p.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                        <TableCell sx={{ py: 2.5 }}>
                          <Chip 
                            label={`$${p.amount?.toLocaleString() || 0}`} 
                            sx={{ 
                              fontWeight: 800, 
                              bgcolor: alpha(theme.palette.success.main, 0.1), 
                              color: 'success.main',
                              borderRadius: 2,
                              fontSize: '0.95rem',
                              px: 1
                            }} 
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, color: 'text.secondary' }}>
                            <EventIcon sx={{ fontSize: 18, opacity: 0.7 }} />
                            <Typography variant="body2" fontWeight={600}>
                              {p.dateOfOperation?.slice(0, 10) || '-'}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                            <Box sx={{ 
                              width: 32, 
                              height: 32, 
                              borderRadius: '50%', 
                              bgcolor: 'primary.50', 
                              display: 'flex', 
                              alignItems: 'center', 
                              justifyContent: 'center',
                              color: 'primary.main'
                            }}>
                              <PersonIcon sx={{ fontSize: 18 }} />
                            </Box>
                            <Typography variant="body2" fontWeight={700}>
                              {p.customerName || p.customerId || '-'}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 250, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontWeight: 500 }}>
                            {p.notes || '-'}
                          </Typography>
                        </TableCell>
                        <TableCell align={isRTL ? 'left' : 'right'}>
                          <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', gap: 1 }}>
                            <Tooltip title={t('common.delete')}>
                              <IconButton 
                                color="error" 
                                onClick={() => removePayment(p.id)}
                                sx={{ 
                                  bgcolor: 'error.50',
                                  '&:hover': { bgcolor: 'error.100', transform: 'scale(1.1)' },
                                  transition: 'all 0.2s'
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
              <TablePagination
                rowsPerPageOptions={[5,10,25]}
                component="div"
                count={payments.length}
                rowsPerPage={paymentsRowsPerPage}
                page={paymentsPage}
                onPageChange={handlePaymentsPageChange}
                onRowsPerPageChange={handlePaymentsRowsPerPageChange}
              />
            </TableContainer>
          </Box>
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Box sx={{ p: 4 }}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 4 }}>
              <Button 
                variant="contained" 
                startIcon={<AddIcon />} 
                onClick={() => setRecDialogOpen(true)}
                sx={{ 
                  borderRadius: 3, 
                  px: 4, 
                  py: 1.5,
                  fontWeight: 800,
                  boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
                }}
              >
                {t('billing.newReceipt')}
              </Button>
            </Box>
            <TableContainer component={Paper} sx={{ maxHeight: 520 }}>
              <Table stickyHeader>
                <TableHead>
                  <TableRow sx={{ bgcolor: 'primary.50' }}>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('billing.amount')}</TableCell>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('billing.date')}</TableCell>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('billing.employee')}</TableCell>
                    <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('billing.notes')}</TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {loading ? (
                    [...Array(receiptsRowsPerPage)].map((_, i) => (
                      <TableRow key={i}>
                        {[...Array(5)].map((_, j) => (
                          <TableCell key={j} sx={{ py: 2.5 }}><Skeleton variant="text" height={24} /></TableCell>
                        ))}
                      </TableRow>
                    ))
                  ) : receipts.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                        <Box sx={{ opacity: 0.5, mb: 2 }}>
                          <ReceiptIcon sx={{ fontSize: 64 }} />
                        </Box>
                        <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('billing.noReceipts')}</Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    receiptsPageItems.map((r) => (
                      <TableRow key={r.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                        <TableCell sx={{ py: 2.5 }}>
                          <Chip 
                            label={`$${r.amount?.toLocaleString() || 0}`} 
                            sx={{ 
                              fontWeight: 800, 
                              bgcolor: alpha(theme.palette.error.main, 0.1), 
                              color: 'error.main',
                              borderRadius: 2,
                              fontSize: '0.95rem',
                              px: 1
                            }} 
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, color: 'text.secondary' }}>
                            <EventIcon sx={{ fontSize: 18, opacity: 0.7 }} />
                            <Typography variant="body2" fontWeight={600}>
                              {r.dateOfOperation?.slice(0, 10) || '-'}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                            <Box sx={{ 
                              width: 32, 
                              height: 32, 
                              borderRadius: '50%', 
                              bgcolor: 'error.50', 
                              display: 'flex', 
                              alignItems: 'center', 
                              justifyContent: 'center',
                              color: 'error.main'
                            }}>
                              <PersonIcon sx={{ fontSize: 18 }} />
                            </Box>
                            <Typography variant="body2" fontWeight={700}>
                              {r.employeeId || '-'}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 250, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontWeight: 500 }}>
                            {r.notes || '-'}
                          </Typography>
                        </TableCell>
                        <TableCell align={isRTL ? 'left' : 'right'}>
                          <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', gap: 1 }}>
                            <Tooltip title={t('common.delete')}>
                              <IconButton 
                                color="error" 
                                onClick={() => removeReceipt(r.id)}
                                sx={{ 
                                  bgcolor: 'error.50',
                                  '&:hover': { bgcolor: 'error.100', transform: 'scale(1.1)' },
                                  transition: 'all 0.2s'
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
              <TablePagination
                rowsPerPageOptions={[5,10,25]}
                component="div"
                count={receipts.length}
                rowsPerPage={receiptsRowsPerPage}
                page={receiptsPage}
                onPageChange={handleReceiptsPageChange}
                onRowsPerPageChange={handleReceiptsRowsPerPageChange}
              />
            </TableContainer>
          </Box>
        </TabPanel>
      </Paper>

      {/* Payment Dialog */}
      <Dialog 
        open={payDialogOpen} 
        onClose={() => setPayDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{ sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('billing.newPayment')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Grid container spacing={3} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label={t('billing.amount')}
                type="number"
                value={payAmount}
                onChange={(e) => setPayAmount(Number(e.target.value) || '')}
                InputProps={{ startAdornment: <Typography sx={{ mr: 1, fontWeight: 800, color: 'success.main' }}>$</Typography> }}
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label={t('billing.date')}
                type="date"
                value={payDate}
                onChange={(e) => setPayDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}>
                <InputLabel>{t('billing.customer')}</InputLabel>
                <Select value={payCustomer} label={t('billing.customer')} onChange={(e) => setPayCustomer(Number(e.target.value) || '')}>
                  <MenuItem value=""><em>{t('billing.selectCustomer')}</em></MenuItem>
                  {customers.map((c) => (
                    <MenuItem key={c.id} value={c.id}>#{c.id} - {c.user?.fullName || 'Unknown'}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                label={t('billing.notes')} 
                multiline 
                rows={3} 
                value={payNotes} 
                onChange={(e) => setPayNotes(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 4, pt: 2, gap: 1 }}>
          <Button 
            onClick={() => setPayDialogOpen(false)} 
            sx={{ borderRadius: 3, px: 3, fontWeight: 700, color: 'text.secondary' }}
          >
            {t('common.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={createPayment} 
            disabled={!payAmount} 
            sx={{ 
              borderRadius: 3, 
              px: 5, 
              py: 1.5,
              fontWeight: 800,
              boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
            }}
          >
            {t('common.save')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Receipt Dialog */}
      <Dialog 
        open={recDialogOpen} 
        onClose={() => setRecDialogOpen(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{ sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('billing.newReceipt')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Grid container spacing={3} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label={t('billing.amount')}
                type="number"
                value={recAmount}
                onChange={(e) => setRecAmount(Number(e.target.value) || '')}
                InputProps={{ startAdornment: <Typography sx={{ mr: 1, fontWeight: 800, color: 'error.main' }}>$</Typography> }}
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label={t('billing.date')}
                type="date"
                value={recDate}
                onChange={(e) => setRecDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}>
                <InputLabel>{t('billing.employee')}</InputLabel>
                <Select value={recEmployee} label={t('billing.employee')} onChange={(e) => setRecEmployee(Number(e.target.value) || '')}>
                  <MenuItem value=""><em>{t('billing.selectEmployee')}</em></MenuItem>
                  {employees.map((e) => (
                    <MenuItem key={e.id} value={e.id}>#{e.id} - {e.user?.fullName || 'Unknown'}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                label={t('billing.notes')} 
                multiline 
                rows={3} 
                value={recNotes} 
                onChange={(e) => setRecNotes(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 4, pt: 2, gap: 1 }}>
          <Button 
            onClick={() => setRecDialogOpen(false)} 
            sx={{ borderRadius: 3, px: 3, fontWeight: 700, color: 'text.secondary' }}
          >
            {t('common.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={createReceipt} 
            disabled={!recAmount} 
            sx={{ 
              borderRadius: 3, 
              px: 5, 
              py: 1.5,
              fontWeight: 800,
              boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
            }}
          >
            {t('common.save')}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
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
