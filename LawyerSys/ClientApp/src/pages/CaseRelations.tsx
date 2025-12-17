import React, { useEffect, useState, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import api from '../services/api'
import Grid from '@mui/material/Grid'
import {
  Box, Card, Typography, TextField, Button,
  FormControl, InputLabel, Select, MenuItem, List, ListItem, ListItemText, IconButton, Chip, useTheme, Paper, Tooltip
} from '@mui/material'
import { Delete, Add, People, Gavel, AccountBalance, Work, Event, Folder, Refresh as RefreshIcon, Link as LinkIcon } from '@mui/icons-material'

type CaseItem = { id:number; code:number }

export default function CaseRelations(){
  const { t } = useTranslation()
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';

  const [cases,setCases] = useState<CaseItem[]>([])
  const [selectedCase, setSelectedCase] = useState<number|undefined>(undefined)
  const [customers,setCustomers] = useState<any[]>([])
  const [contenders,setContenders] = useState<any[]>([])
  const [courts,setCourts] = useState<any[]>([])
  const [employees,setEmployees] = useState<any[]>([])
  const [sitings,setSitings] = useState<any[]>([])
  const [files,setFiles] = useState<any[]>([])
  const [loading, setLoading] = useState(false);

  const custIdRef = useRef<HTMLInputElement>(null)
  const contIdRef = useRef<HTMLInputElement>(null)
  const courtIdRef = useRef<HTMLInputElement>(null)
  const empIdRef = useRef<HTMLInputElement>(null)
  const sitingIdRef = useRef<HTMLInputElement>(null)
  const fileIdRef = useRef<HTMLInputElement>(null)

  async function loadCases(){ 
    setLoading(true);
    try {
      const r = await api.get('/Cases'); 
      setCases(r.data || []);
    } finally {
      setLoading(false);
    }
  }

  useEffect(()=>{ loadCases() },[])

  async function loadRelations(caseCode:number){
    const [cs,cont,co,emp,sit,fil] = await Promise.all([
      api.get(`/cases/${caseCode}/customers`).then(r=>r.data).catch(()=>[]),
      api.get(`/cases/${caseCode}/contenders`).then(r=>r.data).catch(()=>[]),
      api.get(`/cases/${caseCode}/courts`).then(r=>r.data).catch(()=>[]),
      api.get(`/cases/${caseCode}/employees`).then(r=>r.data).catch(()=>[]),
      api.get(`/cases/${caseCode}/sitings`).then(r=>r.data).catch(()=>[]),
      api.get(`/cases/${caseCode}/files`).then(r=>r.data).catch(()=>[])
    ])
    setCustomers(cs); setContenders(cont); setCourts(co); setEmployees(emp); setSitings(sit); setFiles(fil)
  }

  async function attach(type:string, id:number){ if(!selectedCase) return; await api.post(`/cases/${selectedCase}/${type}/${id}`); loadRelations(selectedCase); }
  async function detach(type:string, id:number){ if(!selectedCase) return; await api.delete(`/cases/${selectedCase}/${type}/${id}`); loadRelations(selectedCase); }

  const RelationCard = ({ title, icon, items, idField, displayField, type, inputRef }: { title: string; icon: React.ReactNode; items: any[]; idField: string; displayField: string | ((item:any)=>string); type: string; inputRef: React.RefObject<HTMLInputElement | null> }) => (
    <Paper 
      elevation={0} 
      sx={{ 
        p: 3, 
        height: '100%', 
        borderRadius: 5, 
        border: '1px solid', 
        borderColor: 'divider',
        boxShadow: '0 4px 12px rgba(0, 0, 0, 0.03)',
        display: 'flex',
        flexDirection: 'column',
        transition: 'transform 0.2s, box-shadow 0.2s',
        '&:hover': {
          transform: 'translateY(-4px)',
          boxShadow: '0 12px 24px rgba(0, 0, 0, 0.06)',
          borderColor: 'primary.200'
        }
      }}
    >
      <Box display="flex" alignItems="center" gap={2} mb={3}>
        <Box sx={{ 
          width: 48, 
          height: 48, 
          borderRadius: 3, 
          bgcolor: 'primary.50', 
          color: 'primary.main',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: 'inset 0 0 0 1px rgba(99, 102, 241, 0.1)'
        }}>
          {React.cloneElement(icon as React.ReactElement, { sx: { fontSize: 24 } })}
        </Box>
        <Typography variant="h6" fontWeight={800} sx={{ flex: 1, color: 'text.primary' }}>{title}</Typography>
        <Chip 
          label={items.length} 
          size="small" 
          sx={{ 
            fontWeight: 800, 
            bgcolor: 'primary.main', 
            color: 'white',
            borderRadius: 2,
            px: 1
          }} 
        />
      </Box>
      
      <List dense sx={{ 
        flex: 1,
        maxHeight: 300, 
        overflow: 'auto', 
        mb: 3,
        bgcolor: 'grey.50',
        borderRadius: 3,
        p: 1.5,
        border: '1px solid',
        borderColor: 'grey.100'
      }}>
        {items.map((item:any, idx) => (
          <ListItem 
            key={idx} 
            sx={{ 
              borderRadius: 2,
              mb: 1,
              bgcolor: 'background.paper',
              border: '1px solid transparent',
              transition: 'all 0.2s',
              '&:hover': { 
                bgcolor: 'background.paper',
                borderColor: 'primary.100',
                boxShadow: '0 2px 8px rgba(0,0,0,0.04)'
              }
            }}
            secondaryAction={
              <IconButton edge="end" size="small" color="error" onClick={()=>detach(type, item[idField] ?? item.id)} sx={{ bgcolor: 'error.50', '&:hover': { bgcolor: 'error.100' } }}>
                <Delete fontSize="small" />
              </IconButton>
            }
          >
            <ListItemText 
              primary={typeof displayField === 'function' ? displayField(item) : (item[displayField] ?? `#${item[idField] ?? item.id}`)} 
              primaryTypographyProps={{ variant: 'body2', fontWeight: 700, color: 'text.primary' }}
            />
          </ListItem>
        ))}
        {items.length === 0 && (
          <Box sx={{ p: 4, textAlign: 'center', opacity: 0.6 }}>
            <Typography variant="body2" fontWeight={500}>{t('caseRelations.noItems')}</Typography>
          </Box>
        )}
      </List>

      <Box display="flex" gap={1.5}>
        <TextField 
          size="small" 
          label={t('caseRelations.addById')} 
          type="number" 
          inputRef={inputRef} 
          sx={{ 
            flex: 1,
            '& .MuiOutlinedInput-root': { borderRadius: 3 }
          }} 
          variant="outlined"
        />
        <Button 
          variant="contained" 
          size="medium" 
          startIcon={<Add />} 
          onClick={()=>{ const val = inputRef.current?.value; if(val) { attach(type, Number(val)); inputRef.current!.value = ''; } }}
          sx={{ borderRadius: 3, px: 3, fontWeight: 700, textTransform: 'none' }}
        >
          {t('common.add')}
        </Button>
      </Box>
    </Paper>
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
              <LinkIcon sx={{ fontSize: 40, color: 'white' }} />
            </Box>
            <Box>
              <Typography variant="h3" fontWeight={800} sx={{ mb: 0.5, letterSpacing: '-0.02em' }}>
                {t('caseRelations.management')}
              </Typography>
              <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
                {t('caseRelations.description', 'Link customers, contenders, courts, and employees to specific cases.')}
              </Typography>
            </Box>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Tooltip title={t('cases.refresh')}>
              <IconButton 
                onClick={loadCases} 
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
          </Box>
        </Box>
        
        {/* Decorative background elements */}
        <Box sx={{ position: 'absolute', top: -50, right: -50, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,255,255,0.1)', zIndex: 0 }} />
        <Box sx={{ position: 'absolute', bottom: -30, left: '20%', width: 120, height: 120, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', zIndex: 0 }} />
      </Paper>

      {/* Case Selector */}
      <Paper 
        elevation={0} 
        sx={{ 
          p: 4, 
          mb: 4, 
          borderRadius: 5, 
          border: '1px solid', 
          borderColor: 'divider',
          bgcolor: 'background.paper',
          boxShadow: '0 4px 20px rgba(0,0,0,0.03)'
        }}
      >
        <Grid container spacing={3} alignItems="center">
          <Grid size={{ xs: 12, md: 6 }}>
            <FormControl fullWidth>
              <InputLabel sx={{ fontWeight: 600 }}>{t('caseRelations.selectCase')}</InputLabel>
              <Select 
                value={selectedCase || ''} 
                label={t('caseRelations.selectCase')} 
                onChange={e=>{ setSelectedCase(Number(e.target.value)||undefined); if(Number(e.target.value)) loadRelations(Number(e.target.value)) }}
                sx={{ 
                  borderRadius: 3,
                  '& .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' },
                  '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: 'primary.main' },
                  fontWeight: 600
                }}
              >
                <MenuItem value="" sx={{ fontWeight: 500 }}>{t('caseRelations.selectCasePlaceholder')}</MenuItem>
                {cases.map(c=> <MenuItem key={c.id} value={c.code} sx={{ fontWeight: 500 }}>Case #{c.code} (ID: {c.id})</MenuItem>)}
              </Select>
            </FormControl>
          </Grid>
          {selectedCase && (
            <Grid size={{ xs: 12, md: 6 }}>
              <Box sx={{ 
                display: 'flex', 
                alignItems: 'center', 
                gap: 2, 
                p: 2, 
                bgcolor: 'primary.50', 
                borderRadius: 3,
                border: '1px solid',
                borderColor: 'primary.100'
              }}>
                <Work sx={{ color: 'primary.main' }} />
                <Box>
                  <Typography variant="caption" color="primary.main" fontWeight={700} sx={{ textTransform: 'uppercase', letterSpacing: 1 }}>
                    {t('caseRelations.activeCase', 'Active Case')}
                  </Typography>
                  <Typography variant="h6" fontWeight={800} color="primary.dark">
                    #{selectedCase}
                  </Typography>
                </Box>
              </Box>
            </Grid>
          )}
        </Grid>
      </Paper>

      {selectedCase ? (
        <Grid container spacing={4}>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title={t('caseRelations.customers')} icon={<People />} items={customers} idField="customerId" displayField={(c)=> c.customerName ?? c.CustomerName ?? `#${c.customerId}`} type="customers" inputRef={custIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title={t('caseRelations.contenders')} icon={<Gavel />} items={contenders} idField="contenderId" displayField="fullName" type="contenders" inputRef={contIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title={t('caseRelations.courts')} icon={<AccountBalance />} items={courts} idField="courtId" displayField={(c)=> c.courtName ?? c.CourtName ?? `#${c.courtId}`} type="courts" inputRef={courtIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title={t('caseRelations.employees')} icon={<Work />} items={employees} idField="employeeId" displayField={(e)=> e.employeeName ?? e.EmployeeName ?? `#${e.employeeId}`} type="employees" inputRef={empIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title={t('caseRelations.sitings')} icon={<Event />} items={sitings} idField="sitingId" displayField={(s)=> `${s.sitingDate ?? ''} ${s.sitingTime ?? ''}`} type="sitings" inputRef={sitingIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title={t('caseRelations.files')} icon={<Folder />} items={files} idField="fileId" displayField="path" type="files" inputRef={fileIdRef} />
          </Grid>
        </Grid>
      ) : (
        <Box sx={{ 
          py: 15, 
          textAlign: 'center', 
          bgcolor: 'background.paper', 
          borderRadius: 6, 
          border: '2px dashed', 
          borderColor: 'divider',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 2
        }}>
          <Box sx={{ 
            width: 100, 
            height: 100, 
            borderRadius: '50%', 
            bgcolor: 'grey.50', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            mb: 2
          }}>
            <LinkIcon sx={{ fontSize: 50, color: 'text.disabled', opacity: 0.5 }} />
          </Box>
          <Typography variant="h5" fontWeight={800} color="text.primary">
            {t('caseRelations.selectToStart', 'Select a Case to Begin')}
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ maxWidth: 400 }}>
            {t('caseRelations.selectToStartDesc', 'Choose a case from the dropdown above to manage its associated customers, contenders, and other relations.')}
          </Typography>
        </Box>
      )}
    </Box>
  )
}
