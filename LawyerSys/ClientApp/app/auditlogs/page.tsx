"use client";

import React, { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Card,
  CardContent,
  Chip,
  Pagination,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import api from '../../src/services/api';
import SearchableSelect from '../../src/components/SearchableSelect';

type AuditLogItem = {
  id: number;
  entityName: string;
  action: string;
  entityId?: string;
  oldValues?: string;
  newValues?: string;
  userName?: string;
  timestamp: string;
  requestPath?: string;
};

export default function AuditLogsPage() {
  const [items, setItems] = useState<AuditLogItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [totalCount, setTotalCount] = useState(0);
  const [search, setSearch] = useState('');
  const [action, setAction] = useState('');

  async function load(p = page) {
    setLoading(true);
    setError('');

    try {
      const response = await api.get('/AuditLogs', {
        params: {
          page: p,
          pageSize,
          search: search || undefined,
          action: action || undefined,
        },
      });

      setItems(response.data?.items || []);
      setTotalCount(response.data?.totalCount || 0);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Failed to load audit logs');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load(1);
    setPage(1);
  }, [pageSize, action]);

  return (
    <Box>
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
            <TextField
              size="small"
              label="Search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  void load(1);
                  setPage(1);
                }
              }}
            />

            <SearchableSelect<string>
              size="small"
              label="Action"
              value={action}
              onChange={(value) => setAction(value ?? '')}
              options={[
                { value: '', label: 'All' },
                { value: 'Create', label: 'Create' },
                { value: 'Update', label: 'Update' },
                { value: 'Delete', label: 'Delete' },
              ]}
              disableClearable
              sx={{ minWidth: 160 }}
            />

            <SearchableSelect<number>
              size="small"
              label="Page Size"
              value={pageSize}
              onChange={(value) => setPageSize(value ?? 20)}
              options={[
                { value: 10, label: '10' },
                { value: 20, label: '20' },
                { value: 50, label: '50' },
              ]}
              disableClearable
              sx={{ minWidth: 120 }}
            />
          </Stack>
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Card>
        <CardContent>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Time</TableCell>
                <TableCell>Entity</TableCell>
                <TableCell>Action</TableCell>
                <TableCell>User</TableCell>
                <TableCell>Path</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {items.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{new Date(item.timestamp).toLocaleString()}</TableCell>
                  <TableCell>{item.entityName}</TableCell>
                  <TableCell>
                    <Chip
                      label={item.action}
                      size="small"
                      color={item.action === 'Delete' ? 'error' : item.action === 'Create' ? 'success' : 'primary'}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>{item.userName || '-'}</TableCell>
                  <TableCell>{item.requestPath || '-'}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          {loading && <Typography sx={{ mt: 1 }}>Loading...</Typography>}

          <Stack direction="row" justifyContent="center" sx={{ mt: 2 }}>
            <Pagination
              page={page}
              onChange={(_, value) => {
                setPage(value);
                void load(value);
              }}
              count={Math.max(1, Math.ceil(totalCount / pageSize))}
              color="primary"
            />
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
