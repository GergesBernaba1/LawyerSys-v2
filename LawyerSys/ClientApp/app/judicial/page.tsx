"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, useTheme, MenuItem, Select, InputLabel, FormControl, Pagination,
} from '@mui/material';
import {
  Description as DescriptionIcon,
  Add as AddIcon, Delete as DeleteIcon, Edit as EditIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';

type JudicialDocDto = { id: number; docType: string; docNum: number; docDetails: string; notes: string; numOfAgent: number; customerId: number; customerName?: string };
type CustomerItem = { id: number; usersId: number; identity?: { fullName?: string; email?: string } };

export default function JudicialDocumentsPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const { isAuthenticated } = useAuth();

  const [items, setItems] = useState<JudicialDocDto[]>([]);
  const [customers, setCustomers] = useState<CustomerItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [openDialog, setOpenDialog] = useState(false);
  const [editItem, setEditItem] = useState<JudicialDocDto | null>(null);
  const [form, setForm] = useState({ docType: '', docNum: 0, docDetails: '', notes: '', numOfAgent: 0, customerId: 0 });
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  // pagination & search
  const [page, setPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [search, setSearch] = useState<string>('');

  async function load(p = page) {
    setLoading(true);
    try {
      const [docsRes, custRes] = await Promise.all([
        api.get(`/JudicialDocuments?page=${p}&pageSize=${pageSize}${search ? `&search=${encodeURIComponent(search)}` : ''}`),
        api.get('/Customers')
      ]);

      // support legacy array response OR paged response
      const docsData = docsRes.data?.items ? docsRes.data.items : docsRes.data;
      setItems(docsData || []);
      if (docsRes.data?.totalCount) setTotalCount(docsRes.data.totalCount);

      setCustomers(custRes.data || []);
    } catch {
      setSnackbar({ open: true, message: t('judicial.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  function openCreate() {
    setEditItem(null);
    setForm({ docType: '', docNum: 0, docDetails: '', notes: '', numOfAgent: 0, customerId: 0 });
    setOpenDialog(true);
  }

  function openEdit(item: JudicialDocDto) {
    setEditItem(item);
    setForm({ docType: item.docType, docNum: item.docNum, docDetails: item.docDetails, notes: item.notes, numOfAgent: item.numOfAgent, customerId: item.customerId });
    setOpenDialog(true);
  }

  async function handleSubmit() {
    try {
      if (editItem) {
        await api.put(`/JudicialDocuments/${editItem.id}`, { docType: form.docType, docNum: form.docNum, docDetails: form.docDetails, notes: form.notes, numOfAgent: form.numOfAgent });
        setSnackbar({ open: true, message: t('judicial.updated'), severity: 'success' });
      } else {
        await api.post('/JudicialDocuments', form);
        setSnackbar({ open: true, message: t('judicial.created'), severity: 'success' });
      }
      setOpenDialog(false);
      load();
    } catch {
      setSnackbar({ open: true, message: editItem ? t('judicial.failedUpdate') : t('judicial.failedCreate'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('judicial.confirmDelete'))) return;
    try {
      await api.delete(`/JudicialDocuments/${id}`);
      setSnackbar({ open: true, message: t('judicial.deleted'), severity: 'success' });
      load();
    } catch {
      setSnackbar({ open: true, message: t('judicial.failedDelete'), severity: 'error' });
    }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box sx={{ bgcolor: 'primary.main', color: 'white', p: 1.5, borderRadius: 3, display: 'flex', boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)' }}>
            <DescriptionIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>{t('judicial.management')}</Typography>
            <Typography variant="body2" color="text.secondary">{t('judicial.totalDocuments')}: <strong>{totalCount || items.length}</strong></Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center', flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <TextField size="small" placeholder={t('app.search') as string} value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); load(1); }} sx={{ minWidth: 240 }} />
          <Tooltip title={t('common.refresh')}>
            <IconButton onClick={() => load()} disabled={loading} sx={{ bgcolor: 'background.paper', border: '1px solid', borderColor: 'divider', '&:hover': { bgcolor: 'grey.50' } }}>
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Button variant="contained" startIcon={!isRTL ? <AddIcon /> : undefined} endIcon={isRTL ? <AddIcon /> : undefined} onClick={openCreate}
            sx={{ borderRadius: 2.5, px: 3, fontWeight: 700, boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)' }}>
            {t('judicial.createNew')}
          </Button>
        </Box>
      </Box>

      {/* Table */}
      <Paper elevation={0} sx={{ borderRadius: 4, border: '1px solid', borderColor: 'divider', overflow: 'hidden', bgcolor: 'background.paper', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
        <TableContainer>
          <Table sx={{ minWidth: 750 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>ID</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('judicial.docType')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('judicial.docNumber')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('judicial.customer')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('judicial.agentNumber')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5, fontWeight: 700 }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(6)].map((__, j) => <TableCell key={j}><Skeleton variant="text" /></TableCell>)}
                  </TableRow>
                ))
              ) : items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5 }}>
                      <DescriptionIcon sx={{ fontSize: 48, color: 'primary.main', opacity: 0.3, mb: 2 }} />
                      <Typography variant="h6" gutterBottom>{t('judicial.noDocuments')}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={openCreate}>{t('judicial.createFirst')}</Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ) : items.map((item) => (
                <TableRow key={item.id} sx={{ '&:hover': { bgcolor: 'grey.50' }, transition: 'background 0.2s ease' }}>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}><Chip label={`#${item.id}`} size="small" variant="outlined" sx={{ borderRadius: 1.5, fontWeight: 600 }} /></TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left', fontWeight: 600 }}>{item.docType || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.docNum}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.customerName || '-'}</TableCell>
                  <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.numOfAgent}</TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                    <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
                      <Tooltip title={t('common.edit')}>
                        <IconButton color="primary" onClick={() => openEdit(item)} sx={{ '&:hover': { bgcolor: 'primary.light', color: 'white' }, transition: 'all 0.2s ease' }}>
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title={t('common.delete')}>
                        <IconButton color="error" onClick={() => remove(item.id)} sx={{ '&:hover': { bgcolor: 'error.light', color: 'white' }, transition: 'all 0.2s ease' }}>
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Pagination */}
      <Box sx={{ p: 2, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 2 }}>
        <Pagination
          count={Math.max(1, Math.ceil((totalCount || items.length) / pageSize))}
          page={page}
          onChange={(_, v) => { setPage(v); load(v); }}
          color="primary"
          shape="rounded"
          showFirstButton
          showLastButton
        />
        <FormControl size="small" sx={{ minWidth: 90 }}>
          <InputLabel id="pagesize-label">/page</InputLabel>
          <Select
            labelId="pagesize-label"
            value={pageSize}
            label="/page"
            onChange={(e) => { const ps = Number(e.target.value); setPageSize(ps); setPage(1); load(1); }}
          >
            <MenuItem value={5}>5</MenuItem>
            <MenuItem value={10}>10</MenuItem>
            <MenuItem value={20}>20</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {/* Create/Edit Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: 3, p: 1 } }}>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {editItem ? t('common.edit') : t('judicial.createNew')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2.5, mt: 2 }}>
            <TextField fullWidth label={t('judicial.docType')} value={form.docType} onChange={(e) => setForm({ ...form, docType: e.target.value })} variant="outlined" />
            <TextField fullWidth label={t('judicial.docNumber')} type="number" value={form.docNum} onChange={(e) => setForm({ ...form, docNum: Number(e.target.value) })} variant="outlined" />
            <TextField fullWidth label={t('judicial.agentNumber')} type="number" value={form.numOfAgent} onChange={(e) => setForm({ ...form, numOfAgent: Number(e.target.value) })} variant="outlined" />
            {!editItem && (
              <FormControl fullWidth variant="outlined">
                <InputLabel>{t('judicial.customer')}</InputLabel>
                <Select value={form.customerId} onChange={(e) => setForm({ ...form, customerId: Number(e.target.value) })} label={t('judicial.customer')}>
                  <MenuItem value={0}>-</MenuItem>
                  {customers.map((c) => <MenuItem key={c.id} value={c.id}>{c.identity?.fullName || c.identity?.email || `#${c.id}`}</MenuItem>)}
                </Select>
              </FormControl>
            )}
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField fullWidth label={t('judicial.details')} value={form.docDetails} onChange={(e) => setForm({ ...form, docDetails: e.target.value })} variant="outlined" multiline rows={3} />
            </Box>
            <Box sx={{ gridColumn: '1 / -1' }}>
              <TextField fullWidth label={t('judicial.notes')} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} variant="outlined" multiline rows={2} />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setOpenDialog(false)} sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={handleSubmit} sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}>{editItem ? t('common.save') : t('common.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled" sx={{ borderRadius: 2, fontWeight: 600 }}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
