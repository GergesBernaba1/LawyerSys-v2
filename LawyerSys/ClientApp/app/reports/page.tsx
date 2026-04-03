"use client";

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
} from '@mui/material';
import { Download as DownloadIcon } from '@mui/icons-material';
import api from '../../src/services/api';
import { useTranslation } from 'react-i18next';
import { useCurrency } from '../../src/hooks/useCurrency';
import SearchableSelect from '../../src/components/SearchableSelect';

type MonthlyPoint = { year: number; month: number; payments: number; receipts: number; netCashFlow: number };
type FinancialSummaryResponse = {
  summary: { year: number; month: number; totalPayments: number; totalReceipts: number; netCashFlow: number; paymentsCount: number; receiptsCount: number };
  last6Months: MonthlyPoint[];
};
type OutstandingBalance = { customerId: number; customerName: string; casesTotalAmount: number; paidAmount: number; outstandingBalance: number };

type CustomerOption = { id: number; user?: { fullName?: string } };

export default function ReportsPage() {
  const { t } = useTranslation();
  const { formatCurrency } = useCurrency();
  const currentYear = new Date().getFullYear();
  const currentMonth = new Date().getMonth() + 1;
  const [year, setYear] = useState(currentYear);
  const [month, setMonth] = useState(currentMonth);
  const [customerId, setCustomerId] = useState<string>('');
  const [customers, setCustomers] = useState<CustomerOption[]>([]);
  const [summary, setSummary] = useState<FinancialSummaryResponse | null>(null);
  const [balances, setBalances] = useState<OutstandingBalance[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const yearOptions = useMemo(() => [currentYear - 1, currentYear, currentYear + 1], [currentYear]);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const params: Record<string, number> = { year, month };
      if (customerId !== '') params.customerId = Number(customerId);

      const [summaryRes, balancesRes, customersRes] = await Promise.all([
        api.get('/Reports/financial-summary', { params }),
        api.get('/Reports/outstanding-balances'),
        api.get('/Customers?page=1&pageSize=200'),
      ]);

      setSummary(summaryRes.data);
      setBalances(balancesRes.data || []);
      const customerItems = customersRes.data?.items || customersRes.data || [];
      setCustomers(customerItems);
    } catch (err: any) {
      setError(err?.response?.data?.message || t('common.failedLoad'));
    } finally {
      setLoading(false);
    }
  }, [year, month, customerId, t]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  async function download(format: 'csv' | 'pdf') {
    try {
      const params: Record<string, number | string> = { year, month, format };
      if (customerId !== '') params.customerId = Number(customerId);

      const response = await api.get('/Reports/financial-summary/export', {
        params,
        responseType: 'blob',
      });

      const url = window.URL.createObjectURL(response.data);
      const a = document.createElement('a');
      a.href = url;
      a.download = `financial-summary-${year}-${String(month).padStart(2, '0')}.${format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch {
      setError(t('common.failedExport'));
    }
  }

  return (
    <Box>
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ xs: 'stretch', md: 'center' }}>
            <SearchableSelect<number>
              size="small"
              label={t('app.year')}
              value={year}
              onChange={(value) => setYear(value ?? currentYear)}
              options={yearOptions.map((y) => ({ value: y, label: String(y) }))}
              disableClearable
              sx={{ minWidth: 140 }}
            />

            <SearchableSelect<number>
              size="small"
              label={t('app.month')}
              value={month}
              onChange={(value) => setMonth(value ?? currentMonth)}
              options={Array.from({ length: 12 }, (_, i) => i + 1).map((m) => ({ value: m, label: String(m) }))}
              disableClearable
              sx={{ minWidth: 140 }}
            />

            <SearchableSelect<string>
              size="small"
              label={t('billing.customer')}
              value={customerId}
              onChange={(value) => setCustomerId(value ?? '')}
              options={[
                { value: '', label: t('common.all') },
                ...customers.map((c) => ({ value: String(c.id), label: c.user?.fullName || '-' })),
              ]}
              disableClearable
              sx={{ minWidth: 220 }}
            />

            <Stack direction="row" spacing={1}>
              <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => void download('csv')}>CSV</Button>
              <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => void download('pdf')}>PDF</Button>
            </Stack>
          </Stack>
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t('billing.totalPayments')}</Typography>
              <Typography variant="h5">{formatCurrency(summary?.summary.totalPayments || 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t('billing.totalReceipts')}</Typography>
              <Typography variant="h5">{formatCurrency(summary?.summary.totalReceipts || 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t('billing.balance')}</Typography>
              <Typography variant="h5">{formatCurrency(summary?.summary.netCashFlow || 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1.5 }}>{t('app.trend')}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t('app.month') || 'Month'}</TableCell>
                    <TableCell>{t('billing.payments')}</TableCell>
                    <TableCell>{t('billing.receipts')}</TableCell>
                    <TableCell>{t('billing.balance')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(summary?.last6Months || []).map((point) => (
                    <TableRow key={`${point.year}-${point.month}`}>
                      <TableCell>{`${point.year}-${String(point.month).padStart(2, '0')}`}</TableCell>
                      <TableCell>{formatCurrency(point.payments)}</TableCell>
                      <TableCell>{formatCurrency(point.receipts)}</TableCell>
                      <TableCell>{formatCurrency(point.netCashFlow)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, md: 6 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1.5 }}>{t('app.outstanding')}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t('billing.customer')}</TableCell>
                    <TableCell>{t('cases.totalAmount')}</TableCell>
                    <TableCell>{t('billing.totalPayments')}</TableCell>
                    <TableCell>{t('billing.balance')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {balances.slice(0, 10).map((item) => (
                    <TableRow key={item.customerId}>
                      <TableCell>{item.customerName}</TableCell>
                      <TableCell>{formatCurrency(item.casesTotalAmount)}</TableCell>
                      <TableCell>{formatCurrency(item.paidAmount)}</TableCell>
                      <TableCell>{formatCurrency(item.outstandingBalance)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {loading && <Typography sx={{ mt: 2 }}>{t('common.loading')}</Typography>}
    </Box>
  );
}
