"use client";

import React, { useEffect, useState } from 'react';
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
} from '@mui/material';
import api from '../../src/services/api';

type PortalResponse = {
  customerName: string;
  cases: { code: number; type: string; date: string; totalAmount: number; status: number }[];
  hearings: { caseCode: number; date: string; time: string; judgeName: string }[];
  documents: { id: number; type: string; number: number; details: string }[];
  billing: { totalPayments: number; casesTotalAmount: number; outstandingBalance: number };
};

const statusLabels = ['New', 'In Progress', 'Awaiting Hearing', 'Closed', 'Won', 'Lost'];

export default function ClientPortalPage() {
  const [data, setData] = useState<PortalResponse | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const response = await api.get('/ClientPortal/overview');
        setData(response.data);
      } catch (err: any) {
        setError(err?.response?.data?.message || 'Failed to load portal data');
      }
    })();
  }, []);

  return (
    <Box>
      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h5">Welcome, {data?.customerName || 'Client'}</Typography>
        </CardContent>
      </Card>

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">Total Case Value</Typography>
              <Typography variant="h6">{data?.billing?.casesTotalAmount ?? 0}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">Total Paid</Typography>
              <Typography variant="h6">{data?.billing?.totalPayments ?? 0}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">Outstanding</Typography>
              <Typography variant="h6">{data?.billing?.outstandingBalance ?? 0}</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>My Cases</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Code</TableCell>
                    <TableCell>Type</TableCell>
                    <TableCell>Status</TableCell>
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
              <Typography variant="h6" sx={{ mb: 1 }}>Upcoming Hearings</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Case</TableCell>
                    <TableCell>Date</TableCell>
                    <TableCell>Judge</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.hearings || []).map((h, i) => (
                    <TableRow key={`${h.caseCode}-${i}`}>
                      <TableCell>{h.caseCode}</TableCell>
                      <TableCell>{new Date(h.time).toLocaleString()}</TableCell>
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
          <Typography variant="h6" sx={{ mb: 1 }}>My Documents</Typography>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>#</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Details</TableCell>
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
