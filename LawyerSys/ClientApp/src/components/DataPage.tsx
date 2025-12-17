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
  useTheme,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { useTranslation } from 'react-i18next';

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
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  
  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'}>
      {/* Header */}
      <Box 
        sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 4,
          flexDirection: isRTL ? 'row-reverse' : 'row' 
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box 
            sx={{ 
              bgcolor: 'primary.main', 
              color: 'white', 
              p: 1.5, 
              borderRadius: 3, 
              display: 'flex',
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)',
            }}
          >
            {React.cloneElement(icon as React.ReactElement, { fontSize: 'medium' })}
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
              {title}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {t('common.total')}: <strong>{data.length}</strong>
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton 
              onClick={onRefresh} 
              disabled={loading}
              sx={{ 
                bgcolor: 'background.paper', 
                border: '1px solid', 
                borderColor: 'divider',
                '&:hover': { bgcolor: 'grey.50' }
              }}
            >
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          {createDialog && (
            <Button 
              variant="contained" 
              startIcon={!isRTL ? <AddIcon /> : undefined} 
              endIcon={isRTL ? <AddIcon /> : undefined} 
              onClick={createDialog.onOpen}
              sx={{ 
                borderRadius: 2.5, 
                px: 3,
                fontWeight: 700,
                boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
              }}
            >
              {t('app.add')}
            </Button>
          )}
        </Box>
      </Box>

      {/* Data Table */}
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
                {columns.map((col) => (
                  <TableCell key={col.key} sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{col.label}</TableCell>
                ))}
                {onDelete && <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5 }}>{t('app.actions')}</TableCell>}
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, i) => (
                  <TableRow key={i}>
                    {columns.map((col) => (
                      <TableCell key={col.key} sx={{ textAlign: isRTL ? 'right' : 'left' }}><Skeleton variant="text" /></TableCell>
                    ))}
                    {onDelete && <TableCell align={isRTL ? 'left' : 'right'}><Skeleton variant="circular" width={40} height={40} /></TableCell>}
                  </TableRow>
                ))
              ) : data.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={columns.length + (onDelete ? 1 : 0)} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5 }}>
                      <Box sx={{ mb: 2, fontSize: 48, color: 'primary.main', opacity: 0.3 }}>{icon}</Box>
                      <Typography variant="h6" gutterBottom>{t('common.noRecords')}</Typography>
                      {createDialog && (
                        <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={createDialog.onOpen}>
                          {t('common.createFirst')}
                        </Button>
                      )}
                    </Box>
                  </TableCell>
                </TableRow>
              ) : (
                data.map((row) => (
                  <TableRow 
                    key={row[idField]}
                    sx={{ 
                      '&:hover': { bgcolor: 'grey.50' },
                      transition: 'background 0.2s ease'
                    }}
                  >
                    {columns.map((col) => (
                      <TableCell key={col.key} sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                        {col.render ? col.render(row[col.key], row) : row[col.key] ?? '-'}
                      </TableCell>
                    ))}
                    {onDelete && (
                      <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                        <Tooltip title={t('app.delete')}>
                          <IconButton 
                            color="error" 
                            onClick={() => onDelete(row[idField])}
                            sx={{ 
                              '&:hover': { bgcolor: 'error.light', color: 'white' },
                              transition: 'all 0.2s ease'
                            }}
                          >
                            <DeleteIcon fontSize="small" />
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
      </Paper>

      {/* Create Dialog */}
      {createDialog && (
        <Dialog 
          open={createDialog.open} 
          onClose={createDialog.onClose} 
          fullWidth 
          maxWidth="sm"
          PaperProps={{
            sx: { borderRadius: 4, p: 1 }
          }}
        >
          <DialogTitle sx={{ fontWeight: 800, fontSize: '1.5rem', pb: 1, textAlign: isRTL ? 'right' : 'left' }}>
            {createDialog.title}
          </DialogTitle>
          <DialogContent sx={{ pt: 2 }}>
            {createDialog.content}
          </DialogContent>
          <DialogActions sx={{ p: 3, pt: 1, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
            <Button onClick={createDialog.onClose} sx={{ fontWeight: 600 }}>{t('app.cancel')}</Button>
            <Button 
              onClick={createDialog.onSubmit} 
              variant="contained" 
              disabled={createDialog.submitDisabled}
              sx={{ 
                borderRadius: 2.5, 
                px: 4,
                fontWeight: 700,
                boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
              }}
            >
              {t('app.create')}
            </Button>
          </DialogActions>
        </Dialog>
      )}

      {/* Snackbar */}
      {snackbar && (
        <Snackbar 
          open={snackbar.open} 
          autoHideDuration={6000} 
          onClose={snackbar.onClose}
          anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
        >
          <Alert 
            onClose={snackbar.onClose} 
            severity={snackbar.severity} 
            variant="filled"
            sx={{ width: '100%', borderRadius: 3, boxShadow: '0 8px 16px rgba(0,0,0,0.1)' }}
          >
            {snackbar.message}
          </Alert>
        </Snackbar>
      )}
    </Box>
  );
}
