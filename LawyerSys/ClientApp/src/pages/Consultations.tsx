import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import api from '../services/api'
import {
  Box, Typography, TextField, Button, CircularProgress,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, IconButton,
  Tooltip, Skeleton, Chip, Dialog, DialogTitle, DialogContent, DialogActions, useTheme,
  alpha, Avatar, Grid
} from '@mui/material'
import { 
  Delete as DeleteIcon, 
  Add as AddIcon, 
  Refresh as RefreshIcon, 
  Chat as ChatIcon,
  Search as SearchIcon,
  FilterList as FilterListIcon,
  CalendarToday as CalendarIcon,
  Assignment as AssignmentIcon
} from '@mui/icons-material'

type Cons = { id:number; consultionState?:string; type?:string; subject?:string; description?:string; feedback?:string; notes?:string; dateTime?:string }

export default function Consultations(){
  const [items,setItems] = useState<Cons[]>([])
  const [loading,setLoading] = useState(false)
  const { t } = useTranslation()
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const [state,setState] = useState('')
  const [ctype,setCtype] = useState('')
  const [subject,setSubject] = useState('')
  const [desc,setDesc] = useState('')
  const [feedback,setFeedback] = useState('')
  const [notes,setNotes] = useState('')
  const [dateTime,setDateTime] = useState('')
  const [openDialog, setOpenDialog] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  async function load(){ setLoading(true); try{ const r = await api.get('/Consulations'); setItems(r.data); }finally{setLoading(false)} }
  useEffect(()=>{ load() },[])

  async function create(){ 
    try{ 
      await api.post('/Consulations', { consultionState: state, type: ctype, subject, description: desc, feedback, notes, dateTime: dateTime || undefined }); 
      setState(''); setCtype(''); setSubject(''); setDesc(''); setFeedback(''); setNotes(''); setDateTime(''); 
      setOpenDialog(false);
      await load() 
    }catch(e:any){alert(e?.response?.data?.message||'Failed') } 
  }

  async function remove(id:number){ if (!confirm(t('common.confirmDelete'))) return; await api.delete(`/Consulations/${id}`); await load() }

  const filteredItems = items.filter(item => 
    item.subject?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    item.type?.toLowerCase().includes(searchQuery.toLowerCase())
  );

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
              <ChatIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('consultations.title')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('consultations.subtitle', 'Manage and track legal consultations and client feedback.')}
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
              {t('consultations.add')}
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
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.50' }}>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('consultations.subject')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('consultations.type')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('consultations.state')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('consultations.dateTime')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                [...Array(5)].map((_, i) => (
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
                      <ChatIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('common.noData')}</Typography>
                  </TableCell>
                </TableRow>
              ) : filteredItems.map((item) => (
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
                        <AssignmentIcon fontSize="small" />
                      </Box>
                      <Box>
                        <Typography variant="body1" fontWeight={700} color="text.primary">
                          {item.subject}
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {item.description}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Chip 
                      label={item.type} 
                      size="small" 
                      sx={{ 
                        borderRadius: 1.5, 
                        fontWeight: 700,
                        bgcolor: 'grey.100',
                        color: 'text.primary',
                        px: 1
                      }} 
                    />
                  </TableCell>
                  <TableCell>
                    <Chip 
                      label={item.consultionState} 
                      size="small" 
                      color={item.consultionState === 'Completed' ? 'success' : 'warning'}
                      sx={{ fontWeight: 800, borderRadius: 1.5 }} 
                    />
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, color: 'text.secondary' }}>
                      <CalendarIcon sx={{ fontSize: 18, opacity: 0.7 }} />
                      <Typography variant="body2" fontWeight={500}>
                        {item.dateTime ? new Date(item.dateTime).toLocaleDateString() : '-'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', gap: 1 }}>
                      <Tooltip title={t('common.delete')}>
                        <IconButton 
                          color="error" 
                          onClick={() => remove(item.id)}
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
      </Paper>

      {/* Add Dialog */}
      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{ sx: { borderRadius: 6, boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
      >
        <DialogTitle sx={{ fontWeight: 800, px: 4, pt: 4, pb: 1, fontSize: '1.5rem' }}>{t('consultations.add')}</DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Grid container spacing={3} sx={{ mt: 0.5 }}>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                label={t('consultations.subject')} 
                value={subject} 
                onChange={(e)=>setSubject(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={6}>
              <TextField 
                fullWidth 
                label={t('consultations.type')} 
                value={ctype} 
                onChange={(e)=>setCtype(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={6}>
              <TextField 
                fullWidth 
                label={t('consultations.state')} 
                value={state} 
                onChange={(e)=>setState(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                label={t('consultations.dateTime')} 
                type="datetime-local" 
                value={dateTime} 
                onChange={(e)=>setDateTime(e.target.value)} 
                InputLabelProps={{ shrink: true }} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                multiline 
                rows={3} 
                label={t('consultations.description')} 
                value={desc} 
                onChange={(e)=>setDesc(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                multiline 
                rows={2} 
                label={t('consultations.feedback')} 
                value={feedback} 
                onChange={(e)=>setFeedback(e.target.value)} 
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3 } }} 
              />
            </Grid>
            <Grid item xs={12}>
              <TextField 
                fullWidth 
                multiline 
                rows={2} 
                label={t('consultations.notes')} 
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
