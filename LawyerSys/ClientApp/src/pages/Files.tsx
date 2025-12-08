import React, { useEffect, useState, useRef } from 'react';
import {
  Box, Card, CardContent, Typography, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, Grid, styled,
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
      setSnackbar({ open: true, message: 'Failed to load files', severity: 'error' });
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
    if (!confirm('Delete file?')) return;
    try {
      await api.delete(`/Files/${id}`);
      await load();
      setSnackbar({ open: true, message: 'File deleted', severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: 'Failed to delete', severity: 'error' });
    }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <FolderIcon sx={{ fontSize: 32, color: 'primary.main' }} />
          <Typography variant="h5" fontWeight={600}>Files Management</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Refresh"><IconButton onClick={load} disabled={loading}><RefreshIcon /></IconButton></Tooltip>
          <Button variant="contained" startIcon={<CloudUploadIcon />} onClick={() => setOpenDialog(true)}>Upload File</Button>
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
                <TableRow><TableCell colSpan={5} align="center" sx={{ py: 4, color: 'text.secondary' }}><FolderIcon sx={{ fontSize: 48, opacity: 0.3, mb: 1 }} /><Typography>No files found</Typography></TableCell></TableRow>
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
                    <Tooltip title="Download">
                      <IconButton color="primary" component="a" href={`${import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:5000/api'}/Files/${it.id}/download`} target="_blank">
                        <DownloadIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete">
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
        <DialogTitle>Upload New File</DialogTitle>
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
                {file ? file.name : 'Choose File'}
                <VisuallyHiddenInput type="file" onChange={(e) => setFile(e.target.files?.[0])} />
              </Button>
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField fullWidth label="Code" value={code} onChange={(e) => setCode(e.target.value)} />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={submitUpload} disabled={!file}>Upload</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled">{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
