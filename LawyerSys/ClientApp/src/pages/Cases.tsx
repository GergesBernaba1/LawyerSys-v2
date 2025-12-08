import React, { useEffect, useState } from 'react';
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
  Grid,
  useTheme,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  Gavel as GavelIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../services/api';

type CaseItem = {
  id: number;
  code: number;
  invitionsStatment?: string;
  invitionType?: string;
  invitionDate?: string;
  totalAmount?: number;
  notes?: string;
};

export default function Cases() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const [items, setItems] = useState<CaseItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [code, setCode] = useState<number>(0);
  const [notes, setNotes] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  async function load() {
    setLoading(true);
    try {
      const r = await api.get('/Cases');
      setItems(r.data);
    } catch (err) {
      setSnackbar({ open: true, message: t('cases.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function create() {
    try {
      await api.post('/Cases', { code, notes });
      await load();
      setCode(0);
      setNotes('');
      setOpenDialog(false);
      setSnackbar({ open: true, message: t('cases.caseCreated'), severity: 'success' });
    } catch (err: any) {
      setSnackbar({ open: true, message: err?.response?.data?.message ?? t('cases.failedCreate'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('cases.confirmDelete'))) return;
    try {
      await api.delete(`/Cases/${id}`);
      await load();
      setSnackbar({ open: true, message: t('cases.caseDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('cases.failedDelete'), severity: 'error' });
    }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <GavelIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>
            {t('cases.management')}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton onClick={load} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          <Button
            variant="contained"
            startIcon={!isRTL ? <AddIcon /> : undefined}
            endIcon={isRTL ? <AddIcon /> : undefined}
            onClick={() => setOpenDialog(true)}
          >
            {t('cases.newCase')}
          </Button>
        </Box>
      </Box>

      {/* Stats Card */}
      <Card sx={{ mb: 3 }}>
        <CardContent sx={{ py: 2 }}>
          <Typography variant="body2" color="text.secondary" sx={{ textAlign: isRTL ? 'right' : 'left' }}>
            {t('cases.totalCases')}: <strong>{items.length}</strong>
          </Typography>
        </CardContent>
      </Card>

      {/* Data Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('cases.code')}</TableCell>
              <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('cases.type')}</TableCell>
              <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('cases.date')}</TableCell>
              <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('cases.amount')}</TableCell>
              <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('cases.notes')}</TableCell>
              <TableCell align={isRTL ? 'left' : 'right'}>{t('cases.actions')}</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              [...Array(5)].map((_, i) => (
                <TableRow key={i}>
                  {[...Array(6)].map((_, j) => (
                    <TableCell key={j}>
                      <Skeleton />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : items.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                  <Box sx={{ color: 'text.secondary' }}>
                    <GavelIcon sx={{ fontSize: 48, opacity: 0.3, mb: 1 }} />
                    <Typography>{t('cases.noCases')}</Typography>
                    <Button
                      variant="contained"
                      size="small"
                      sx={{ mt: 2 }}
                      onClick={() => setOpenDialog(true)}
                    >
                      {t('cases.createFirst')}
                    </Button>
                  </Box>
                </TableCell>
              </TableRow>
            ) : (
              items.map((item) => (
                <TableRow key={item.id} hover>
                  <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                    <Chip label={item.code} size="small" color="primary" variant="outlined" />
                  </TableCell>
                  <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{item.invitionType || '-'}</TableCell>
                  <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>{item.invitionDate?.slice(0, 10) || '-'}</TableCell>
                  <TableCell sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                    {item.totalAmount ? `$${item.totalAmount.toLocaleString()}` : '-'}
                  </TableCell>
                  <TableCell sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', textAlign: isRTL ? 'right' : 'left' }}>
                    {item.notes || '-'}
                  </TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Tooltip title={t('app.delete')}>
                      <IconButton color="error" onClick={() => remove(item.id)}>
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

      {/* Create Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left' }}>{t('cases.createNew')}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                fullWidth
                label={t('cases.code')}
                type="number"
                value={code || ''}
                onChange={(e) => setCode(Number(e.target.value))}
              />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField
                fullWidth
                label={t('cases.notes')}
                multiline
                rows={3}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2, flexDirection: isRTL ? 'row-reverse' : 'row', justifyContent: 'flex-end' }}>
          <Button onClick={() => setOpenDialog(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={create} disabled={!code}>
            {t('app.create')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          variant="filled"
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
