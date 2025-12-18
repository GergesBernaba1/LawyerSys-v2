import React, { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import api from '../services/api'
import {
  Box, Typography, TextField, Button, CircularProgress,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination, Paper, IconButton,
  FormControl, InputLabel, Select, MenuItem, Grid, Tooltip, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, useTheme, alpha, Avatar
} from '@mui/material'
import { 
  Delete as DeleteIcon, 
  Add as AddIcon, 
  Refresh as RefreshIcon, 
  Description as DescriptionIcon,
  Search as SearchIcon,
  FilterList as FilterListIcon,
  Person as PersonIcon,
  Numbers as NumbersIcon
} from '@mui/icons-material'

type Doc = { id:number; docType?:string; docNum?:number; docDetails?:string; notes?:string; numOfAgent?:number; customerId?:number; customerName?:string }

export default function JudicialDocuments(){
  const { t } = useTranslation()
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const [items,setItems] = useState<Doc[]>([])
  const [loading,setLoading] = useState(false)
  const [docType,setDocType] = useState('')
  const [docNum,setDocNum] = useState<number|undefined>(undefined)
  const [details,setDetails] = useState('')
  const [notes,setNotes] = useState('')
  const [numOfAgent,setNum] = useState<number|undefined>(undefined)
  const [customerId,setCustomerId] = useState<number|undefined>(undefined)
  const [customers,setCustomers] = useState<{id:number;user?:any}[]>([])
  const [openDialog, setOpenDialog] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  React.useEffect(() => { setPage(0); }, [searchQuery, items]);
  const filteredItems = items.filter(item => 
    item.docType?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    item.customerName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    item.docNum?.toString().includes(searchQuery)
  );
  const pageItems = filteredItems.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);
  const handleChangePage = (_: any, newPage: number) => setPage(newPage);
  const handleChangeRowsPerPage = (e: React.ChangeEvent<HTMLInputElement>) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }; 

  async function load(){ setLoading(true); try{ const r = await api.get('/JudicialDocuments'); setItems(r.data); const c = await api.get('/Customers'); setCustomers(c.data); }finally{setLoading(false)} }
  useEffect(()=>{ load() },[])

  async function create(){ 
    try{ 
      await api.post('/JudicialDocuments', { docType, docNum, docDetails: details, notes, numOfAgent, customerId }); 
      setDocType(''); setDocNum(undefined); setDetails(''); setNotes(''); setNum(undefined); setCustomerId(undefined); 
      setOpenDialog(false);
      await load() 
    }catch(e:any){alert(e?.response?.data?.message||'Failed') } 
  }

  async function remove(id:number){ if (!confirm(t('judicial.confirmDelete'))) return; await api.delete(`/JudicialDocuments/${id}`); await load() }

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
              <DescriptionIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('judicial.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('judicial.subtitle', 'Manage and track judicial documents, powers of attorney, and legal records.')}
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
              startIcon={<AddIcon />} 
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
              {t('judicial.new')}
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
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          slotProps={{
            input: {
              startAdornment: <SearchIcon sx={{ color: 'text.disabled', mr: 1 }} />,
              sx: { borderRadius: 3, bgcolor: 'grey.50' }
            }
          }}
        />
        <Button 
          startIcon={<FilterListIcon />} 
          sx={{ 
            fontWeight: 700, 
            borderRadius: 3, 
            px: 3,
            bgcolor: 'grey.50',
            color: 'text.secondary',
            '&:hover': { bgcolor: 'grey.100' }
          }}
        >
          {t('common.filter')}
        </Button>
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
        <TableContainer component={Paper} sx={{ maxHeight: 520 }}>
          <Table stickyHeader>
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.50' }}>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('judicial.type')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('judicial.number')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('judicial.customer')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('judicial.details')}</TableCell>
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
              ) : pageItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                    <Box sx={{ opacity: 0.5, mb: 2 }}>
                      <DescriptionIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('common.noData')}</Typography>
                  </TableCell>
                </TableRow>
              ) : pageItems.map((item) => (
                <TableRow key={item.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                  <TableCell sx={{ py: 2.5 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Box sx={{ 
                        width: 40, 
                        height: 40, 
                        borderRadius: 2, 
                        bgcolor: 'primary.50', 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center',
                        color: 'primary.main'
                      }}>
                        <DescriptionIcon fontSize="small" />
                      </Box>
                      <Chip 
                        label={item.docType || '-'} 
                        size="small" 
                        sx={{ 
                          fontWeight: 800, 
                          borderRadius: 2,
                          bgcolor: 'primary.50',
                          color: 'primary.dark',
                          border: '1px solid',
                          borderColor: 'primary.100'
                        }} 
                      />
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <NumbersIcon sx={{ fontSize: 18, color: 'text.disabled' }} />
                      <Typography variant="body2" fontWeight={700} color="text.primary">
                        {item.docNum || '-'}
                      </Typography>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <TablePagination
            rowsPerPageOptions={[5,10,25]}
            component="div"
            count={filteredItems.length}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
          />
        </TableContainer>
      </Paper>

      {/* Add Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{ sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('judicial.new')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Grid container spacing={3} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth 
                label={t('judicial.type')} 
                value={docType} 
                onChange={(e)=>setDocType(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth 
                label={t('judicial.number')} 
                type="number" 
                value={docNum ?? ''} 
                onChange={(e)=>setDocNum(Number(e.target.value)||undefined)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                multiline 
                rows={3} 
                label={t('judicial.details')} 
                value={details} 
                onChange={(e)=>setDetails(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth 
                label={t('judicial.numAgents')} 
                type="number" 
                value={numOfAgent ?? ''} 
                onChange={(e)=>setNum(Number(e.target.value)||undefined)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }}>
                <InputLabel>{t('judicial.customer')}</InputLabel>
                <Select 
                  value={customerId||''} 
                  label={t('judicial.customer')} 
                  onChange={(e)=>setCustomerId(Number(e.target.value)||undefined)}
                >
                  <MenuItem value="">{t('common.select')}</MenuItem>
                  {customers.map(c=> <MenuItem key={c.id} value={c.id}>#{c.id} {c.user?.fullName ?? ''}</MenuItem>)}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                label={t('judicial.notes')} 
                value={notes} 
                onChange={(e)=>setNotes(e.target.value)} 
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
            onClick={create} 
            variant="contained" 
            sx={{ 
              borderRadius: 3, 
              px: 5, 
              py: 1.5,
              fontWeight: 800,
              boxShadow: '0 8px 16px rgba(99, 102, 241, 0.2)'
            }}
          >
            {t('common.save')}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
