"use client";

import React, { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Card,
  CardContent,
  Chip,
  FormControl,
  InputLabel,
  MenuItem,
  Pagination,
  Select,
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

            <FormControl size="small" sx={{ minWidth: 160 }}>
              <InputLabel>Action</InputLabel>
              <Select value={action} label="Action" onChange={(e) => setAction(String(e.target.value))}>
                <MenuItem value="">All</MenuItem>
                <MenuItem value="Create">Create</MenuItem>
                <MenuItem value="Update">Update</MenuItem>
                <MenuItem value="Delete">Delete</MenuItem>
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Page Size</InputLabel>
              <Select value={pageSize} label="Page Size" onChange={(e) => setPageSize(Number(e.target.value))}>
                <MenuItem value={10}>10</MenuItem>
                <MenuItem value={20}>20</MenuItem>
                <MenuItem value={50}>50</MenuItem>
              </Select>
            </FormControl>
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
                <TableCell>Entity Id</TableCell>
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
                  <TableCell>{item.entityId || '-'}</TableCell>
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
