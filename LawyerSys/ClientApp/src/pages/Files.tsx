import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, styled, Grid, useTheme,
} from '@mui/material';
import {
  Add as AddIcon, Delete as DeleteIcon, Folder as FolderIcon, Refresh as RefreshIcon,
  CloudUpload as CloudUploadIcon, Download as DownloadIcon, InsertDriveFile as FileIcon,
  Search as SearchIcon,
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
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const [items, setItems] = useState<FileDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [file, setFile] = useState<File | undefined>();
  const [code, setCode] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const filteredItems = items.filter(item => 
    item.path?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.code?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.id.toString().includes(searchTerm)
  );

  React.useEffect(() => { setPage(0); }, [searchTerm, items]);
  const pageItems = filteredItems.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);
  const handleChangePage = (_: any, newPage: number) => setPage(newPage);
  const handleChangeRowsPerPage = (e: React.ChangeEvent<HTMLInputElement>) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); };

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
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 1600, margin: '0 auto' }}>
      {/* Header Section */}
      <Paper 
        elevation={0}
        sx={{ 
          p: { xs: 3, md: 5 }, 
          mb: 4, 
          borderRadius: 6, 
          background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
          color: 'white',
          position: 'relative',
          overflow: 'hidden',
          boxShadow: '0 20px 40px rgba(99, 102, 241, 0.2)'
        }}
      >
        <Box sx={{ position: 'relative', zIndex: 1, display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
            <Box sx={{ 
              width: 70, 
              height: 70, 
              borderRadius: 4, 
              bgcolor: 'rgba(255, 255, 255, 0.2)', 
              backdropFilter: 'blur(10px)',
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              border: '1px solid rgba(255, 255, 255, 0.3)'
            }}>
              <FolderIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('files.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('files.description', 'Securely store and manage case-related documents and evidence.')}
              </Typography>
            </Box>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Tooltip title={t('common.refresh')}>
              <IconButton 
                onClick={load} 
                disabled={loading}
                sx={{ 
                  bgcolor: 'rgba(255, 255, 255, 0.1)',
                  color: 'white',
                  '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.2)' },
                  backdropFilter: 'blur(10px)',
                  width: 50,
                  height: 50
                }}
              >
                <RefreshIcon />
              </IconButton>
            </Tooltip>
            <Button 
              variant="contained" 
              startIcon={<CloudUploadIcon />} 
              onClick={() => setOpenDialog(true)}
              sx={{ 
                bgcolor: 'white',
                color: 'primary.main',
                '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.9)' },
                borderRadius: 3, 
                px: 4, 
                py: 1.5,
                fontWeight: 800,
                textTransform: 'none',
                boxShadow: '0 10px 20px rgba(0,0,0,0.1)'
              }}
            >
              {t('files.upload')}
            </Button>
          </Box>
        </Box>
        
        {/* Decorative background elements */}
        <Box sx={{ position: 'absolute', top: -50, right: -50, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,255,255,0.1)', zIndex: 0 }} />
        <Box sx={{ position: 'absolute', bottom: -30, left: '20%', width: 120, height: 120, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', zIndex: 0 }} />
      </Paper>

      {/* Search Bar */}
      <Paper 
        elevation={0} 
        sx={{ 
          p: 2, 
          mb: 4, 
          borderRadius: 4, 
          border: '1px solid', 
          borderColor: 'divider',
          bgcolor: 'background.paper',
          display: 'flex',
          alignItems: 'center',
          gap: 2,
          boxShadow: '0 4px 20px rgba(0,0,0,0.02)'
        }}
      >
        <TextField
          fullWidth
          variant="outlined"
          placeholder={t('common.search')}
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          slotProps={{
            input: {
              startAdornment: <SearchIcon sx={{ color: 'text.disabled', mr: 1 }} />,
              sx: { borderRadius: 3, bgcolor: 'grey.50' }
            }
          }}
        />
      </Paper>

      {/* Table Section */}
      <Paper 
        elevation={0} 
        sx={{ 
          borderRadius: 5, 
          overflow: 'hidden', 
          border: '1px solid', 
          borderColor: 'divider',
          boxShadow: '0 10px 30px rgba(0,0,0,0.04)'
        }}
      >
        <TableContainer sx={{ maxHeight: '60vh', overflow: 'auto' }}>
          <Table stickyHeader>
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.50' }}>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('common.id')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('files.path') || 'Path'}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('files.code') || 'Code'}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('files.type') || 'Type'}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                [...Array(rowsPerPage)].map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(5)].map((_, j) => (
                      <TableCell key={j} sx={{ py: 2.5 }}><Skeleton variant="text" height={24} /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : filteredItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                    <Box sx={{ opacity: 0.5, mb: 2 }}>
                      <FolderIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('files.noFiles')}</Typography>
                  </TableCell>
                </TableRow>
              ) : pageItems.map((it) => (
                <TableRow key={it.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                  <TableCell sx={{ py: 2.5 }}>
                    <Chip 
                      label={`#${it.id}`} 
                      size="small" 
                      sx={{ 
                        borderRadius: 2, 
                        fontWeight: 800,
                        bgcolor: 'grey.100',
                        color: 'text.primary',
                        border: '1px solid',
                        borderColor: 'grey.200',
                        px: 1
                      }} 
                    />
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Box sx={{ 
                        width: 36, 
                        height: 36, 
                        borderRadius: 2, 
                        bgcolor: 'primary.50', 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center',
                        color: 'primary.main'
                      }}>
                        <FileIcon fontSize="small" />
                      </Box>
                      <Typography variant="body1" fontWeight={700} color="primary.main">
                        {it.path || '-'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary" fontWeight={500}>
                      {it.code || '-'}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip 
                      label={it.type ? (t('app.yes') || 'Yes') : (t('app.no') || 'No')} 
                      size="small" 
                      color={it.type ? 'success' : 'default'} 
                      sx={{ fontWeight: 700, borderRadius: 1.5 }}
                    />
                  </TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', gap: 1 }}>
                      <Tooltip title={t('files.download')}>
                        <IconButton 
                          color="primary" 
                          component="a" 
                          href={`${process?.env?.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000/api'}/Files/${it.id}/download`} 
                          target="_blank"
                          sx={{ 
                            bgcolor: 'primary.50',
                            '&:hover': { bgcolor: 'primary.100', transform: 'scale(1.1)' },
                            transition: 'all 0.2s'
                          }}
                        >
                          <DownloadIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title={t('common.delete')}>
                        <IconButton 
                          color="error" 
                          onClick={() => remove(it.id)}
                          sx={{ 
                            bgcolor: 'error.50',
                            '&:hover': { bgcolor: 'error.100', transform: 'scale(1.1)' },
                            transition: 'all 0.2s'
                          }}
                        >
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
        <TablePagination component="div" count={filteredItems.length} page={page} onPageChange={handleChangePage} rowsPerPage={rowsPerPage} onRowsPerPageChange={handleChangeRowsPerPage} rowsPerPageOptions={[5,10,25]} />
      </Paper>

      {/* Upload Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth 
        PaperProps={{ sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('files.upload')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4, fontWeight: 500 }}>
            {t('files.uploadSubtitle', 'Select a file to upload and provide an optional code for identification.')}
          </Typography>
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Button
                component="label"
                variant="outlined"
                startIcon={<CloudUploadIcon />}
                fullWidth
                sx={{ 
                  py: 6, 
                  borderRadius: 4, 
                  borderStyle: 'dashed',
                  borderWidth: 2,
                  bgcolor: file ? 'primary.50' : 'grey.50',
                  borderColor: file ? 'primary.main' : 'divider',
                  '&:hover': {
                    borderStyle: 'dashed',
                    borderWidth: 2,
                    bgcolor: 'primary.50',
                  }
                }}
              >
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="h6" fontWeight={800} color={file ? 'primary.main' : 'text.primary'}>
                    {file ? file.name : t('files.chooseFile')}
                  </Typography>
                  {!file && (
                    <Typography variant="body2" color="text.secondary">
                      {t('files.dragDrop', 'or drag and drop here')}
                    </Typography>
                  )}
                </Box>
                <VisuallyHiddenInput type="file" onChange={(e) => setFile(e.target.files?.[0])} />
              </Button>
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                label={t('files.code')} 
                value={code} 
                onChange={(e) => setCode(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 4, pt: 2, gap: 1 }}>
          <Button 
            onClick={() => setOpenDialog(false)}
            sx={{ borderRadius: 3, px: 3, fontWeight: 700, color: 'text.secondary' }}
          >
            {t('common.cancel')}
          </Button>
          <Button 
            variant="contained" 
            onClick={submitUpload} 
            disabled={!file}
            sx={{ 
              borderRadius: 3, 
              px: 5, 
              py: 1.5,
              fontWeight: 800,
              boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
            }}
          >
            {t('files.upload')}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={4000} 
        onClose={() => setSnackbar({ ...snackbar, open: false })} 
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity} 
          variant="filled"
          sx={{ borderRadius: 3, boxShadow: '0 10px 20px rgba(0,0,0,0.1)', fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
