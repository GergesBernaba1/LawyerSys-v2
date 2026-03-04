"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, styled, useTheme
} from '@mui/material';
import {
  CloudUpload as CloudUploadIcon, Download as DownloadIcon, Folder as FolderIcon,
  Delete as DeleteIcon, Refresh as RefreshIcon, InsertDriveFile as FileIcon, OpenInNew as OpenInNewIcon
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useParams } from 'next/navigation';
import useConfirmDialog from '../../src/hooks/useConfirmDialog';

type FileDto = { id: number; path?: string; code?: string; type?: boolean };
const ALLOWED_UPLOAD_EXTENSIONS = ['.pdf', '.doc', '.docx', '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

function getFileExtension(fileNameOrPath?: string): string {
  if (!fileNameOrPath) return '';
  const clean = fileNameOrPath.split('?')[0].toLowerCase();
  const idx = clean.lastIndexOf('.');
  return idx >= 0 ? clean.substring(idx) : '';
}

function isAllowedUpload(file?: File): boolean {
  if (!file) return false;
  return ALLOWED_UPLOAD_EXTENSIONS.includes(getFileExtension(file.name));
}

function canViewInBrowser(path?: string): boolean {
  return ALLOWED_UPLOAD_EXTENSIONS.includes(getFileExtension(path));
}

function displayFileTitle(item: FileDto): string {
  if (item.code?.trim()) return item.code.trim();
  const fromPath = item.path?.split('/').pop();
  if (!fromPath) return '-';
  return decodeURIComponent(fromPath);
}

function sanitizeFileName(name: string): string {
  return name.replace(/[\\/:*?"<>|]/g, '_').trim();
}

function getFallbackFileName(item: FileDto): string {
  const ext = getFileExtension(item.path || '');
  const base = sanitizeFileName(displayFileTitle(item)) || 'file';
  return base.toLowerCase().endsWith(ext) ? base : `${base}${ext || ''}`;
}

function tryGetNameFromContentDisposition(contentDisposition?: string): string | undefined {
  if (!contentDisposition) return undefined;
  const utf8Match = contentDisposition.match(/filename\*\s*=\s*UTF-8''([^;]+)/i);
  if (utf8Match?.[1]) return decodeURIComponent(utf8Match[1]);
  const plainMatch = contentDisposition.match(/filename\s*=\s*\"?([^\";]+)\"?/i);
  return plainMatch?.[1];
}

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
  const { confirm, confirmDialog } = useConfirmDialog();

  const [items, setItems] = useState<FileDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [file, setFile] = useState<File | undefined>();
  const [titleOrDescription, setTitleOrDescription] = useState('');
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
      setSnackbar({ open: true, message: t('files.chooseFile'), severity: 'error' });
      return;
    }
    if (!isAllowedUpload(file)) {
      setSnackbar({ open: true, message: t('files.invalidFileType'), severity: 'error' });
      return;
    }
    try {
      const form = new FormData();
      form.append('file', file);
      form.append('title', titleOrDescription);
      await api.post('/Files/upload', form, { headers: { 'Content-Type': 'multipart/form-data' } });
      setFile(undefined);
      setTitleOrDescription('');
      setOpenDialog(false);
      await load();
      setSnackbar({ open: true, message: t('files.fileUploaded'), severity: 'success' });
    } catch (e: any) {
      setSnackbar({ open: true, message: e?.response?.data?.message || t('files.failedUpload'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!(await confirm(t('files.confirmDelete')))) return;
    try {
      await api.delete(`/Files/${id}`);
      await load();
      setSnackbar({ open: true, message: t('files.fileDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('files.failedDelete'), severity: 'error' });
    }
  }

  async function viewFile(item: FileDto) {
    const opened = window.open('about:blank', '_blank', 'noopener,noreferrer');
    try {
      const response = await api.get(`/Files/${item.id}/view`, { responseType: 'blob' });
      const blob = new Blob([response.data], { type: response.headers?.['content-type'] || undefined });
      const objectUrl = URL.createObjectURL(blob);
      if (opened) {
        opened.location.href = objectUrl;
      } else {
        window.open(objectUrl, '_blank', 'noopener,noreferrer');
      }
      setTimeout(() => URL.revokeObjectURL(objectUrl), 60_000);
    } catch (error: any) {
      if (opened) opened.close();
      setSnackbar({ open: true, message: error?.response?.data?.message || t('files.failedView'), severity: 'error' });
    }
  }

  async function downloadFile(item: FileDto) {
    try {
      const response = await api.get(`/Files/${item.id}/download`, { responseType: 'blob' });
      const blob = new Blob([response.data], { type: response.headers?.['content-type'] || undefined });
      const objectUrl = URL.createObjectURL(blob);
      const contentDisposition = response.headers?.['content-disposition'] as string | undefined;
      const suggestedName = tryGetNameFromContentDisposition(contentDisposition) || getFallbackFileName(item);

      const a = document.createElement('a');
      a.href = objectUrl;
      a.download = suggestedName;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(objectUrl);
    } catch (error: any) {
      setSnackbar({ open: true, message: error?.response?.data?.message || t('files.failedDownload'), severity: 'error' });
    }
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {confirmDialog}
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
              {t('files.totalFiles')}: {items.length}
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('common.refresh')}>
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
          <Table sx={{ minWidth: 650, tableLayout: 'fixed' }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left', fontWeight: 700, width: '50%' }}>{t('files.titleOrDescription')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: 'center', fontWeight: 700, width: '20%' }}>{t('files.fileType')}</TableCell>
                <TableCell align="center" sx={{ py: 2.5, fontWeight: 700, width: '30%' }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(3)].map((__, j) => (
                      <TableCell key={j} sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={3} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5, textAlign: 'center' }}>
                      <Box sx={{ mb: 2, fontSize: 48, color: 'primary.main', opacity: 0.3 }}>
                        <FolderIcon fontSize="inherit" />
                      </Box>
                      <Typography variant="h6" gutterBottom>{t('files.noFiles')}</Typography>
                      <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={() => setOpenDialog(true)}>
                        {t('files.uploadFirst')}
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
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row', justifyContent: isRTL ? 'flex-end' : 'flex-start', width: '100%' }}>
                        <FileIcon fontSize="small" color="action" />
                        <Typography variant="body2" sx={{ fontWeight: 500, maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {displayFileTitle(it)}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: 'center' }}>
                      <Chip 
                        label={(getFileExtension(it.path || '').replace('.', '').toUpperCase() || '-')}
                        size="small" 
                        color="default" 
                        variant="outlined"
                        sx={{ borderRadius: 1.5, fontWeight: 600 }}
                      />
                    </TableCell>
                    <TableCell align="center" sx={{ py: 2 }}>
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
                        {canViewInBrowser(it.path) && (
                          <Tooltip title={t('files.view')}>
                            <IconButton
                              color="info"
                              onClick={() => viewFile(it)}
                              sx={{
                                '&:hover': { bgcolor: 'info.light', color: 'white' },
                                transition: 'all 0.2s ease'
                              }}
                            >
                              <OpenInNewIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        )}
                        <Tooltip title={t('files.download')}>
                          <IconButton 
                            color="primary" 
                            onClick={() => downloadFile(it)}
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
              {file ? file.name : t('files.chooseFile')}
              <VisuallyHiddenInput type="file" accept={ALLOWED_UPLOAD_EXTENSIONS.join(',')} onChange={(e: any) => setFile(e.target.files?.[0])} />
            </Button>
            <Typography variant="caption" color="text.secondary">
              {t('files.allowedTypesHint')}
            </Typography>
            
            <TextField 
              fullWidth 
              label={t('files.titleOrDescription')} 
              value={titleOrDescription} 
              onChange={(e) => setTitleOrDescription(e.target.value)} 
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
