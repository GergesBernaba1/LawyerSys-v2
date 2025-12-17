import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { 
  Box, Typography, TextField, Button, CircularProgress, Table, TableBody, TableCell, 
  TableContainer, TableHead, TableRow, Paper, IconButton, Grid, useTheme, Tooltip,
  Dialog, DialogTitle, DialogContent, DialogActions, Stack
} from '@mui/material'
import { Delete, Add, Refresh as RefreshIcon, Group as GroupIcon } from '@mui/icons-material'
import { useTranslation } from 'react-i18next'

type User = { id:number; fullName?:string; userName?:string; address?:string; job?:string; phoneNumber?:string }

export default function LegacyUsers(){
  const { t } = useTranslation()
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const [items,setItems] = useState<User[]>([])
  const [loading,setLoading] = useState(false)
  const [open, setOpen] = useState(false)

  const [fullName,setFullName] = useState('')
  const [address,setAddress] = useState('')
  const [job,setJob] = useState('')
  const [phone,setPhone] = useState('')
  const [dob,setDob] = useState('')
  const [ssn,setSsn] = useState('')
  const [userName,setUserName] = useState('')
  const [password,setPassword] = useState('')

  async function load(){ 
    setLoading(true); 
    try{ 
      const r = await api.get('/LegacyUsers'); 
      setItems(r.data || []); 
    } finally {
      setLoading(false)
    } 
  }
  
  useEffect(()=>{ load() },[])

  async function create(){ 
    try{ 
      await api.post('/LegacyUsers', { 
        fullName, address, job, phoneNumber: phone, 
        dateOfBirth: dob || undefined, ssn, userName, password 
      }); 
      setFullName(''); setAddress(''); setJob(''); setPhone(''); 
      setDob(''); setSsn(''); setUserName(''); setPassword(''); 
      setOpen(false);
      await load() 
    } catch(e:any){
      alert(e?.response?.data?.message||'Failed') 
    } 
  }

  async function remove(id:number){ 
    if (!confirm(t('common.confirmDelete', 'Are you sure you want to delete this user?'))) return; 
    await api.delete(`/LegacyUsers/${id}`); 
    await load() 
  }

  const [searchTerm, setSearchTerm] = useState('')

  const filteredItems = items.filter(u => 
    u.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    u.userName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    u.phoneNumber?.includes(searchTerm)
  )

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
              <GroupIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('legacyUsers.title', 'Legacy Users')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('legacyUsers.description', 'Manage legacy system users and their credentials.')}
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
              startIcon={<Add />} 
              onClick={() => setOpen(true)}
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
              {t('common.create')}
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
              startAdornment: <RefreshIcon sx={{ color: 'text.disabled', mr: 1, transform: 'rotate(90deg)' }} />,
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
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.50' }}>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark', py: 2.5 }}>{t('common.id')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.name')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('legacyUsers.username')}</TableCell>
                <TableCell sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('legacyUsers.phone')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ fontWeight: 800, color: 'primary.dark' }}>{t('common.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                    <CircularProgress size={48} thickness={4} sx={{ color: 'primary.main' }} />
                    <Typography sx={{ mt: 2, color: 'text.secondary', fontWeight: 600 }}>{t('common.loading')}</Typography>
                  </TableCell>
                </TableRow>
              ) : filteredItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center" sx={{ py: 12 }}>
                    <Box sx={{ opacity: 0.5, mb: 2 }}>
                      <GroupIcon sx={{ fontSize: 64 }} />
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>{t('common.noData')}</Typography>
                  </TableCell>
                </TableRow>
              ) : filteredItems.map((u) => (
                <TableRow key={u.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 }, transition: 'background-color 0.2s' }}>
                  <TableCell sx={{ fontWeight: 800, color: 'primary.main' }}>#{u.id}</TableCell>
                  <TableCell>
                    <Typography variant="body1" fontWeight={700} color="text.primary">{u.fullName}</Typography>
                    <Typography variant="caption" fontWeight={600} color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>{u.job}</Typography>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ 
                      px: 1.5, 
                      py: 0.75, 
                      bgcolor: 'grey.100', 
                      borderRadius: 2, 
                      display: 'inline-flex',
                      alignItems: 'center',
                      border: '1px solid',
                      borderColor: 'grey.200'
                    }}>
                      <Typography variant="caption" fontWeight={800} sx={{ fontFamily: 'monospace', color: 'text.primary' }}>{u.userName}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell sx={{ fontWeight: 600, color: 'text.secondary' }}>{u.phoneNumber}</TableCell>
                  <TableCell align={isRTL ? 'left' : 'right'}>
                    <Tooltip title={t('common.delete')}>
                      <IconButton 
                        color="error" 
                        onClick={() => remove(u.id)} 
                        sx={{ 
                          bgcolor: 'error.50', 
                          '&:hover': { bgcolor: 'error.100', transform: 'scale(1.1)' },
                          transition: 'all 0.2s'
                        }}
                      >
                        <Delete fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Create Dialog */}
      <Dialog 
        open={open} 
        onClose={() => setOpen(false)} 
        maxWidth="md" 
        fullWidth 
        PaperProps={{ 
          sx: { 
            borderRadius: 6,
            boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)'
          } 
        }}
      >
        <DialogTitle sx={{ 
          fontWeight: 800, 
          px: 4, 
          pt: 4, 
          pb: 2,
          fontSize: '1.5rem',
          color: 'text.primary'
        }}>
          {t('legacyUsers.createNew', 'Create New Legacy User')}
        </DialogTitle>
        <DialogContent sx={{ px: 4 }}>
          <Grid container spacing={3} sx={{ mt: 0.5 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.fullName')} value={fullName} onChange={e=>setFullName(e.target.value)} slotProps={{ input: { sx: { borderRadius: 3 } } }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.username')} value={userName} onChange={e=>setUserName(e.target.value)} slotProps={{ input: { sx: { borderRadius: 3 } } }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.password')} type="password" value={password} onChange={e=>setPassword(e.target.value)} slotProps={{ input: { sx: { borderRadius: 3 } } }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.phone')} value={phone} onChange={e=>setPhone(e.target.value)} slotProps={{ input: { sx: { borderRadius: 3 } } }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.job')} value={job} onChange={e=>setJob(e.target.value)} slotProps={{ input: { sx: { borderRadius: 3 } } }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.ssn')} value={ssn} onChange={e=>setSsn(e.target.value)} slotProps={{ input: { sx: { borderRadius: 3 } } }} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.dateOfBirth')} type="date" slotProps={{ inputLabel: { shrink: true }, input: { sx: { borderRadius: 3 } } }} value={dob} onChange={e=>setDob(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField fullWidth multiline rows={3} label={t('legacyUsers.address')} value={address} onChange={e=>setAddress(e.target.value)} slotProps={{ input: { sx: { borderRadius: 3 } } }} />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 4, pt: 2 }}>
          <Button onClick={() => setOpen(false)} color="inherit" sx={{ fontWeight: 700, px: 3 }}>{t('common.cancel')}</Button>
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
            {t('common.create')}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )

      {/* Create Dialog */}
      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: 4 } }}>
        <DialogTitle sx={{ fontWeight: 700, px: 3, pt: 3 }}>{t('legacyUsers.createNew', 'Create New Legacy User')}</DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.fullName')} value={fullName} onChange={e=>setFullName(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.username')} value={userName} onChange={e=>setUserName(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.password')} type="password" value={password} onChange={e=>setPassword(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.phone')} value={phone} onChange={e=>setPhone(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.job')} value={job} onChange={e=>setJob(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.ssn')} value={ssn} onChange={e=>setSsn(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('legacyUsers.dateOfBirth')} type="date" slotProps={{ inputLabel: { shrink: true } }} value={dob} onChange={e=>setDob(e.target.value)} />
            </Grid>
            <Grid size={{ xs: 12 }}>
              <TextField fullWidth multiline rows={2} label={t('legacyUsers.address')} value={address} onChange={e=>setAddress(e.target.value)} />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 3 }}>
          <Button onClick={() => setOpen(false)} color="inherit" sx={{ fontWeight: 600 }}>{t('common.cancel')}</Button>
          <Button onClick={create} variant="contained" sx={{ borderRadius: 2, px: 4, fontWeight: 600 }}>{t('common.create')}</Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}
