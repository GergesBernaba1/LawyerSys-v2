import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import api from '../services/api'
import { Grid } from '@mui/material'
import {
  Box, Card, Typography, TextField, Button, CircularProgress,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, IconButton
} from '@mui/material'
import { Delete } from '@mui/icons-material'

type Cons = { id:number; consultionState?:string; type?:string; subject?:string; description?:string; feedback?:string; notes?:string; dateTime?:string }

export default function Consultations(){
  const [items,setItems] = useState<Cons[]>([])
  const [loading,setLoading] = useState(false)

  const [state,setState] = useState('')
  const [ctype,setCtype] = useState('')
  const [subject,setSubject] = useState('')
  const [desc,setDesc] = useState('')
  const [feedback,setFeedback] = useState('')
  const [notes,setNotes] = useState('')
  const [dateTime,setDateTime] = useState('')

  async function load(){ setLoading(true); try{ const r = await api.get('/Consulations'); setItems(r.data); }finally{setLoading(false)} }
  useEffect(()=>{ load() },[])

  async function create(){ try{ await api.post('/Consulations', { consultionState: state, type: ctype, subject, description: desc, feedback, notes, dateTime: dateTime || undefined }); setState(''); setCtype(''); setSubject(''); setDesc(''); setFeedback(''); setNotes(''); setDateTime(''); await load() }catch(e:any){alert(e?.response?.data?.message||'Failed') } }

  async function remove(id:number){ if (!confirm(t('common.confirmDelete'))) return; await api.delete(`/Consulations/${id}`); await load() }

  return (
    <Box>
      <Typography variant="h5" gutterBottom fontWeight={600}>{t('consultations.title')}</Typography>
      <Card sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('consultations.state')} value={state} onChange={e=>setState(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('consultations.type')} value={ctype} onChange={e=>setCtype(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('consultations.subject')} value={subject} onChange={e=>setSubject(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('consultations.description')} value={desc} onChange={e=>setDesc(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('consultations.feedback')} value={feedback} onChange={e=>setFeedback(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('consultations.dateTime')} type="datetime-local" slotProps={{ inputLabel: { shrink: true } }} value={dateTime} onChange={e=>setDateTime(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <Button variant="contained" fullWidth onClick={create}>{t('app.create')}</Button>
          </Grid>
        </Grid>
      </Card>

      {loading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box> : (
        <TableContainer component={Paper}>
          <Table size="small">
            <TableHead>
              <TableRow sx={{ backgroundColor: 'primary.main' }}>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>State</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>Type</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>Subject</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>Date</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }} width={60}></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {items.map(i=> (
                <TableRow key={i.id} hover>
                  <TableCell>{i.consultionState}</TableCell>
                  <TableCell>{i.type}</TableCell>
                  <TableCell>{i.subject}</TableCell>
                  <TableCell>{i.dateTime}</TableCell>
                  <TableCell>
                    <IconButton size="small" color="error" onClick={()=>remove(i.id)}><Delete fontSize="small" /></IconButton>
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
