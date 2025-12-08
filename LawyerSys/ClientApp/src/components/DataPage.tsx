import React, { ReactNode } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
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
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Snackbar,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';

interface Column {
  key: string;
  label: string;
  render?: (value: any, row: any) => ReactNode;
}

interface DataPageProps {
  title: string;
  icon: ReactNode;
  data: any[];
  columns: Column[];
  loading: boolean;
  onRefresh: () => void;
  onDelete?: (id: number) => void;
  idField?: string;
  createDialog?: {
    open: boolean;
    onOpen: () => void;
    onClose: () => void;
    onSubmit: () => void;
    title: string;
    content: ReactNode;
    submitDisabled?: boolean;
  };
  snackbar?: {
    open: boolean;
    message: string;
    severity: 'success' | 'error';
    onClose: () => void;
  };
}

export default function DataPage({
  title,
  icon,
  data,
  columns,
  loading,
  onRefresh,
  onDelete,
  idField = 'id',
  createDialog,
  snackbar,
}: DataPageProps) {
  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Box sx={{ color: 'primary.main', fontSize: 32, display: 'flex' }}>{icon}</Box>
          <Typography variant="h5" fontWeight={600}>
            {title}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Refresh">
            <IconButton onClick={onRefresh} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          {createDialog && (
            <Button variant="contained" startIcon={<AddIcon />} onClick={createDialog.onOpen}>
              Add New
            </Button>
          )}
        </Box>
      </Box>

      {/* Stats Card */}
      <Card sx={{ mb: 3 }}>
        <CardContent sx={{ py: 2 }}>
          <Typography variant="body2" color="text.secondary">
            Total Records: <strong>{data.length}</strong>
          </Typography>
        </CardContent>
      </Card>

      {/* Data Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              {columns.map((col) => (
                <TableCell key={col.key}>{col.label}</TableCell>
              ))}
              {onDelete && <TableCell align="right">Actions</TableCell>}
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              [...Array(5)].map((_, i) => (
                <TableRow key={i}>
                  {[...Array(columns.length + (onDelete ? 1 : 0))].map((_, j) => (
                    <TableCell key={j}>
                      <Skeleton />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={columns.length + (onDelete ? 1 : 0)} align="center" sx={{ py: 4 }}>
                  <Box sx={{ color: 'text.secondary' }}>
                    <Box sx={{ opacity: 0.3, mb: 1, fontSize: 48 }}>{icon}</Box>
                    <Typography>No records found</Typography>
                    {createDialog && (
                      <Button variant="contained" size="small" sx={{ mt: 2 }} onClick={createDialog.onOpen}>
                        Create First Record
                      </Button>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ) : (
              data.map((row) => (
                <TableRow key={row[idField]} hover>
                  {columns.map((col) => (
                    <TableCell key={col.key}>
                      {col.render ? col.render(row[col.key], row) : row[col.key] ?? '-'}
                    </TableCell>
                  ))}
                  {onDelete && (
                    <TableCell align="right">
                      <Tooltip title="Delete">
                        <IconButton color="error" onClick={() => onDelete(row[idField])}>
                          <DeleteIcon />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  )}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Create Dialog */}
      {createDialog && (
        <Dialog open={createDialog.open} onClose={createDialog.onClose} maxWidth="sm" fullWidth>
          <DialogTitle>{createDialog.title}</DialogTitle>
          <DialogContent>{createDialog.content}</DialogContent>
          <DialogActions sx={{ p: 2 }}>
            <Button onClick={createDialog.onClose}>Cancel</Button>
            <Button variant="contained" onClick={createDialog.onSubmit} disabled={createDialog.submitDisabled}>
              Create
            </Button>
          </DialogActions>
        </Dialog>
      )}

      {/* Snackbar */}
      {snackbar && (
        <Snackbar
          open={snackbar.open}
          autoHideDuration={4000}
          onClose={snackbar.onClose}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        >
          <Alert onClose={snackbar.onClose} severity={snackbar.severity} variant="filled">
            {snackbar.message}
          </Alert>
        </Snackbar>
      )}
    </Box>
  );
}
