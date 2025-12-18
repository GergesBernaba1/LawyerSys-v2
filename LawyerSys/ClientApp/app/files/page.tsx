"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, styled, useTheme
} from '@mui/material';
import Grid from '@mui/material/Grid'
import {
  CloudUpload as CloudUploadIcon, Download as DownloadIcon, Folder as FolderIcon,
  Add as AddIcon, Delete as DeleteIcon, Refresh as RefreshIcon, InsertDriveFile as FileIcon
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useRouter, useParams } from 'next/navigation';
import { useAuth } from '../../src/services/auth';

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

export default function FilesPageClient() {
  const { t } = useTranslation();
  const theme = useTheme();
  const params = useParams() as { locale?: string } | undefined;
  const locale = params?.locale || 'ar';
  const isRTL = theme.direction === 'rtl' || locale.startsWith('ar');
  const router = useRouter();
  const { isAuthenticated } = useAuth();

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
      setItems(r.data || []);
    } catch (err) {
      setSnackbar({ open: true, message: t('files.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function submitUpload() {
    if (!file) {
      setSnackbar({ open: true, message: t('files.chooseFile') || 'Please select a file', severity: 'error' });
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
      setSnackbar({ open: true, message: t('files.fileUploaded') || 'File uploaded successfully', severity: 'success' });
    } catch (e: any) {
      setSnackbar({ open: true, message: e?.response?.data?.message || t('files.failedUpload') || 'Upload failed', severity: 'error' });
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

  const base = (typeof process !== 'undefined' && process.env.NEXT_PUBLIC_API_BASE_URL)
    || (typeof import.meta !== 'undefined' ? (import.meta as any).env?.VITE_API_BASE_URL : undefined)
    || 'http://localhost:5000/api';

  const downloadUrl = (id: number) => `${base}/Files/${id}/download`;

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header Section */}
      <Box 
        sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 4, 
          flexDirection: isRTL ? 'row-reverse' : 'row',
          bgcolor: 'background.paper',
          p: 3,
          borderRadius: 4,
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
          border: '1px solid',
          borderColor: 'divider'
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box 
            sx={{ 
              width: 56, 
              height: 56, 
              borderRadius: 3, 
              bgcolor: 'primary.main', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              boxShadow: '0 8px 16px rgba(79, 70, 229, 0.2)'
            }}
          >
            <FolderIcon sx={{ fontSize: 32, color: 'white' }} />
          </Box>
          <Box sx={{ textAlign: isRTL ? 'right' : 'left' }}>
            <Typography variant="h4" sx={{ fontWeight: 800, color: 'text.primary', letterSpacing: -0.5 }}>
              {t('files.management')}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
              {t('files.totalFiles') || 'Total Files'}: {items.length}
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton 
              onClick={load} 
              disabled={loading}
              sx={{ 
                bgcolor: 'grey.100', 
                '&:hover': { bgcolor: 'grey.200' },
                borderRadius: 2.5
              }}
            >
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          <Button 
            variant="contained" 
            startIcon={!isRTL ? <CloudUploadIcon /> : undefined} 
            endIcon={isRTL ? <CloudUploadIcon /> : undefined} 
            onClick={() => setOpenDialog(true)}
            sx={{ 
              borderRadius: 2.5, 
              px: 3,
              fontWeight: 700,
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
            }}
          >
            {t('files.upload')}
          </Button>
        </Box>
      </Box>

      {/* Table Section */}
      <Paper 
        elevation={0} 
        sx={{ 
          borderRadius: 4, 
          border: '1px solid', 
          borderColor: 'divider',
          overflow: 'hidden',
          bgcolor: 'background.paper',
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
        }}
      >
        <TableContainer>
          <Table sx={{ minWidth: 650 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>ID</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('files.path') || 'Path'}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('files.code') || 'Code'}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700 }}>{t('files.type') || 'Type'}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5, fontWeight: 700 }}>{t('cases.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(5)].map((__, j) => (
                      <TableCell key={j} sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5 }}>
                      <Box sx={{ mb: 2, fontSize: 48, color: 'primary.main', opacity: 0.3 }}>
                        <FolderIcon fontSize="inherit" />
                      </Box>
                      <Typography variant="h6" gutterBottom>{t('files.noFiles') || 'No files found'}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={() => setOpenDialog(true)}>
                        {t('files.uploadFirst') || 'Upload First File'}
                      </Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ) : (
                items.map((it) => (
                  <TableRow 
                    key={it.id}
                    sx={{ 
                      '&:hover': { bgcolor: 'grey.50' },
                      transition: 'background 0.2s ease'
                    }}
                  >
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Chip 
                        label={`#${it.id}`} 
                        size="small" 
                        variant="outlined" 
                        sx={{ borderRadius: 1.5, fontWeight: 600 }}
                      />
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                        <FileIcon fontSize="small" color="action" />
                        <Typography variant="body2" sx={{ fontWeight: 500, maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {it.path || '-'}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{it.code || '-'}</Typography>
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Chip 
                        label={it.type ? t('app.yes') : t('app.no')} 
                        size="small" 
                        color={it.type ? 'success' : 'default'} 
                        variant="outlined"
                        sx={{ borderRadius: 1.5, fontWeight: 600 }}
                      />
                    </TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
                        <Tooltip title={t('files.download')}>
                          <IconButton 
                            color="primary" 
                            component="a" 
                            href={downloadUrl(it.id)} 
                            target="_blank"
                            sx={{ 
                              '&:hover': { bgcolor: 'primary.light', color: 'white' },
                              transition: 'all 0.2s ease'
                            }}
                          >
                            <DownloadIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title={t('app.delete')}>
                          <IconButton 
                            color="error" 
                            onClick={() => remove(it.id)}
                            sx={{ 
                              '&:hover': { bgcolor: 'error.light', color: 'white' },
                              transition: 'all 0.2s ease'
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
        </TableContainer>
      </Paper>

      {/* Upload Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{
          sx: { borderRadius: 3, p: 1 }
        }}
      >
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {t('files.upload')}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
            <Button 
              component="label" 
              variant="outlined" 
              startIcon={<CloudUploadIcon />} 
              fullWidth 
              sx={{ 
                py: 4, 
                borderRadius: 3, 
                borderStyle: 'dashed',
                borderWidth: 2,
                '&:hover': { borderWidth: 2, borderStyle: 'dashed' }
              }}
            >
              {file ? file.name : t('common.chooseFile') || 'Choose File'}
              <VisuallyHiddenInput type="file" onChange={(e: any) => setFile(e.target.files?.[0])} />
            </Button>
            
            <TextField 
              fullWidth 
              label={t('files.fileName') || 'Code'} 
              value={code} 
              onChange={(e) => setCode(e.target.value)} 
              variant="outlined"
              sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            />
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button 
            onClick={() => setOpenDialog(false)}
            sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}
          >
            {t('app.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={submitUpload} 
            disabled={!file}
            sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}
          >
            {t('files.upload')}
          </Button>
        </DialogActions>
      </Dialog>

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
          sx={{ borderRadius: 2, fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
