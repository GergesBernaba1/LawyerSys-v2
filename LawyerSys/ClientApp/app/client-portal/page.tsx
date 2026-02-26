"use client";

import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Alert,
  Box,
  Card,
  CardContent,
  Chip,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
  useTheme,
} from '@mui/material';
import api from '../../src/services/api';

type PortalResponse = {
  customerName: string;
  cases: { code: number; type: string; date: string; totalAmount: number; status: number }[];
  hearings: { caseCode: number; date: string; time: string; judgeName: string }[];
  documents: { id: number; type: string; number: number; details: string }[];
  billing: { totalPayments: number; casesTotalAmount: number; outstandingBalance: number };
};

export default function ClientPortalPage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const [data, setData] = useState<PortalResponse | null>(null);
  const [error, setError] = useState('');
  const statusLabels = t('clientPortal.statuses', { returnObjects: true }) as string[];

  useEffect(() => {
    (async () => {
      try {
        const response = await api.get('/ClientPortal/overview');
        setData(response.data);
      } catch (err: any) {
        setError(err?.response?.data?.message || t('clientPortal.failedLoad'));
      }
    })();
  }, [t]);

  const formatNumber = (value: number) =>
    value.toLocaleString(isRTL ? 'ar' : (i18n.resolvedLanguage || 'en'));

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'}>
      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h5">{t('clientPortal.welcome')}, {data?.customerName || t('clientPortal.client')}</Typography>
        </CardContent>
      </Card>

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t('clientPortal.totalCaseValue')}</Typography>
              <Typography variant="h6">{formatNumber(data?.billing?.casesTotalAmount ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t('clientPortal.totalPaid')}</Typography>
              <Typography variant="h6">{formatNumber(data?.billing?.totalPayments ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t('clientPortal.outstanding')}</Typography>
              <Typography variant="h6">{formatNumber(data?.billing?.outstandingBalance ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t('clientPortal.myCases')}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t('clientPortal.code')}</TableCell>
                    <TableCell>{t('clientPortal.type')}</TableCell>
                    <TableCell>{t('clientPortal.status')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.cases || []).map((c) => (
                    <TableRow key={c.code}>
                      <TableCell>{c.code}</TableCell>
                      <TableCell>{c.type}</TableCell>
                      <TableCell><Chip size="small" label={statusLabels[c.status] || c.status} variant="outlined" /></TableCell>
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
              <Typography variant="h6" sx={{ mb: 1 }}>{t('clientPortal.upcomingHearings')}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t('clientPortal.case')}</TableCell>
                    <TableCell>{t('clientPortal.date')}</TableCell>
                    <TableCell>{t('clientPortal.judge')}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.hearings || []).map((h, i) => (
                    <TableRow key={`${h.caseCode}-${i}`}>
                      <TableCell>{h.caseCode}</TableCell>
                      <TableCell>{new Date(h.time).toLocaleString(isRTL ? 'ar' : (i18n.resolvedLanguage || 'en'))}</TableCell>
                      <TableCell>{h.judgeName}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card sx={{ mt: 2 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 1 }}>{t('clientPortal.myDocuments')}</Typography>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>#</TableCell>
                <TableCell>{t('clientPortal.type')}</TableCell>
                <TableCell>{t('clientPortal.details')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(data?.documents || []).map((d) => (
                <TableRow key={d.id}>
                  <TableCell>{d.number}</TableCell>
                  <TableCell>{d.type}</TableCell>
                  <TableCell>{d.details}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Box>
  );
}
