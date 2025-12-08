import React, { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import api from '../services/api'
import {
  Box, Card, Typography, Grid, TextField, Button, CircularProgress,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, IconButton,
  FormControl, InputLabel, Select, MenuItem
} from '@mui/material'
import { Delete } from '@mui/icons-material'

type Doc = { id:number; docType?:string; docNum?:number; docDetails?:string; notes?:string; numOfAgent?:number; customerId?:number; customerName?:string }

export default function JudicialDocuments(){
  const { t } = useTranslation()
  const [items,setItems] = useState<Doc[]>([])
  const [loading,setLoading] = useState(false)
  const [docType,setDocType] = useState('')
  const [docNum,setDocNum] = useState<number|undefined>(undefined)
  const [details,setDetails] = useState('')
  const [notes,setNotes] = useState('')
  const [numOfAgent,setNum] = useState<number|undefined>(undefined)
  const [customerId,setCustomerId] = useState<number|undefined>(undefined)
  const [customers,setCustomers] = useState<{id:number;user?:any}[]>([])

  async function load(){ setLoading(true); try{ const r = await api.get('/JudicialDocuments'); setItems(r.data); const c = await api.get('/Customers'); setCustomers(c.data); }finally{setLoading(false)} }
  useEffect(()=>{ load() },[])

  async function create(){ try{ await api.post('/JudicialDocuments', { docType, docNum, docDetails: details, notes, numOfAgent, customerId }); setDocType(''); setDocNum(undefined); setDetails(''); setNotes(''); setNum(undefined); setCustomerId(undefined); await load() }catch(e:any){alert(e?.response?.data?.message||'Failed') } }

  async function remove(id:number){ if (!confirm(t('judicial.confirmDelete'))) return; await api.delete(`/JudicialDocuments/${id}`); await load() }

  return (
    <Box>
      <Typography variant="h5" gutterBottom fontWeight={600}>{t('judicial.management')}</Typography>
      <Card sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('judicial.type')} value={docType} onChange={e=>setDocType(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('judicial.number')} type="number" value={docNum ?? ''} onChange={e=>setDocNum(Number(e.target.value)||undefined)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('judicial.details')} value={details} onChange={e=>setDetails(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('judicial.notes')} value={notes} onChange={e=>setNotes(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('judicial.numAgents')} type="number" value={numOfAgent ?? ''} onChange={e=>setNum(Number(e.target.value)||undefined)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <FormControl fullWidth size="small">
              <InputLabel>{t('judicial.customer')}</InputLabel>
              <Select value={customerId||''} label={t('judicial.customer')} onChange={e=>setCustomerId(Number(e.target.value)||undefined)}>
                <MenuItem value="">{t('common.select')}</MenuItem>
                {customers.map(c=> <MenuItem key={c.id} value={c.id}>#{c.id} {c.user?.fullName ?? ''}</MenuItem>)}
              </Select>
            </FormControl>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <Button variant="contained" fullWidth onClick={create}>{t('common.create')}</Button>
          </Grid>
        </Grid>
      </Card>

      {loading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box> : (
        <TableContainer component={Paper}>
          <Table size="small">
            <TableHead>
              <TableRow sx={{ backgroundColor: 'primary.main' }}>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('judicial.type')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('judicial.number')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('judicial.customer')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('judicial.details')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }} width={60}></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {items.map(d=> (
                <TableRow key={d.id} hover>
                  <TableCell>{d.docType}</TableCell>
                  <TableCell>{d.docNum}</TableCell>
                  <TableCell>{d.customerName}</TableCell>
                  <TableCell>{d.docDetails}</TableCell>
                  <TableCell>
                    <IconButton size="small" color="error" onClick={()=>remove(d.id)}><Delete fontSize="small" /></IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  )
}
