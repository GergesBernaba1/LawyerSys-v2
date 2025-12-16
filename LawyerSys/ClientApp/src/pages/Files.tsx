import React, { useEffect, useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, styled, Grid,
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, Folder as FolderIcon, Refresh as RefreshIcon,
  CloudUpload as CloudUploadIcon, Download as DownloadIcon, InsertDriveFile as FileIcon,
} from '@mui/icons-material';
import api from '../services/api';

type FileDto = { id: number; path?: string; code?: string; type?: boolean };

const VisuallyHiddenInput = styled('input')({
  clip: 'rect(0 0 0 0)',
  clipPath: 'inset(50%)',
  height: 1,
  overflow: 'hidden',
  position: 'absolute',
  bottom: 0,
  left: 0,
  whiteSpace: 'nowrap',
  width: 1,
});

export default function Files() {
  const { t } = useTranslation();
  const [items, setItems] = useState<FileDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [file, setFile] = useState<File | undefined>();
  const [code, setCode] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function load() {
    setLoading(true);
    try {
      const r = await api.get('/Files');
      setItems(r.data);
    } catch (err) {
      setSnackbar({ open: true, message: t('files.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function submitUpload() {
    if (!file) {
      setSnackbar({ open: true, message: 'Please select a file', severity: 'error' });
      return;
    }
    try {
      const form = new FormData();
      form.append('file', file);
      form.append('code', code);
      await api.post('/Files/upload', form, { headers: { 'Content-Type': 'multipart/form-data' } });
      setFile(undefined);
      setCode('');
      setOpenDialog(false);
      await load();
      setSnackbar({ open: true, message: 'File uploaded successfully', severity: 'success' });
    } catch (e: any) {
      setSnackbar({ open: true, message: e?.response?.data?.message || 'Upload failed', severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('files.confirmDelete'))) return;
    try {
      await api.delete(`/Files/${id}`);
      await load();
      setSnackbar({ open: true, message: t('files.fileDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('files.failedDelete'), severity: 'error' });
    }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <FolderIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>{t('files.management')}</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title={t('cases.refresh')}><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<CloudUploadIcon />} onClick={() => setOpenDialog(true)}>{t('files.upload')}</Button>
        </Box>
      </Box>

      <Card sx={{ mb: 3 }}><CardContent sx={{ py: 2 }}><Typography variant="body2" color="text.secondary">Total Files: <strong>{items.length}</strong></Typography></CardContent></Card>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell><TableCell>Path</TableCell><TableCell>Code</TableCell><TableCell>Type</TableCell><TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? [...Array(3)].map((_, i) => (<TableRow key={i}>{[...Array(5)].map((_, j) => (<TableCell key={j}><Skeleton /></TableCell>))}</TableRow>))
              : items.length === 0 ? (
                <TableRow><TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}><FolderIcon sx={{ fontSize: 48, opacity: 0.3, mb: 1 }} /><Typography>{t('files.noFiles')}</Typography></TableCell></TableRow>
              ) : items.map((it) => (
                <TableRow key={it.id} hover>
                  <TableCell><Chip label={`#${it.id}`} size="small" variant="outlined" /></TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <FileIcon fontSize="small" color="action" />
                      {it.path || '-'}
                    </Box>
                  </TableCell>
                  <TableCell>{it.code || '-'}</TableCell>
                  <TableCell><Chip label={it.type ? 'Yes' : 'No'} size="small" color={it.type ? 'success' : 'default'} /></TableCell>
                  <TableCell align="right">
                    <Tooltip title={t('files.download')}>
                      <IconButton color="primary" component="a" href={`${process?.env?.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000/api'}/Files/${it.id}/download`} target="_blank">
                        <DownloadIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title={t('app.delete')}>
                      <IconButton color="error" onClick={() => remove(it.id)}>
                        <DeleteIcon />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t('files.upload')}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12 }}>
              <Button
                component="label"
                variant="outlined"
                startIcon={<CloudUploadIcon />}
                fullWidth
                sx={{ py: 2 }}
              >
                {file ? file.name : t('files.chooseFile')}
                <VisuallyHiddenInput type="file" onChange={(e) => setFile(e.target.files?.[0])} />
              </Button>
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField fullWidth label={t('files.code')} value={code} onChange={(e) => setCode(e.target.value)} />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenDialog(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={submitUpload} disabled={!file}>{t('files.upload')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
