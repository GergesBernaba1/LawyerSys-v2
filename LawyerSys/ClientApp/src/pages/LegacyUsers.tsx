import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Box, Card, Typography, TextField, Button, CircularProgress, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, IconButton, Grid } from '@mui/material'
import { Delete } from '@mui/icons-material'

type User = { id:number; fullName?:string; userName?:string; address?:string; job?:string; phoneNumber?:string }

import {useTranslation} from 'react-i18next'

export default function LegacyUsers(){
  const { t } = useTranslation()
  const [items,setItems] = useState<User[]>([])
  const [loading,setLoading] = useState(false)

  const [fullName,setFullName] = useState('')
  const [address,setAddress] = useState('')
  const [job,setJob] = useState('')
  const [phone,setPhone] = useState('')
  const [dob,setDob] = useState('')
  const [ssn,setSsn] = useState('')
  const [userName,setUserName] = useState('')
  const [password,setPassword] = useState('')

  async function load(){ setLoading(true); try{ const r = await api.get('/LegacyUsers'); setItems(r.data); }finally{setLoading(false)} }
  useEffect(()=>{ load() },[])

  async function create(){ try{ await api.post('/LegacyUsers', { fullName, address, job, phoneNumber: phone, dateOfBirth: dob || undefined, ssn, userName, password }); setFullName(''); setAddress(''); setJob(''); setPhone(''); setDob(''); setSsn(''); setUserName(''); setPassword(''); await load() }catch(e:any){alert(e?.response?.data?.message||'Failed') } }

  async function remove(id:number){ if (!confirm('Delete user?')) return; await api.delete(`/LegacyUsers/${id}`); await load() }

  return (
    <Box>
      <Typography variant="h5" gutterBottom fontWeight={600}>Users (Legacy)</Typography>
      <Card sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.fullName')} value={fullName} onChange={e=>setFullName(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 2 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.address')} value={address} onChange={e=>setAddress(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 1.5 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.job')} value={job} onChange={e=>setJob(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 1.5 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.phone')} value={phone} onChange={e=>setPhone(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 1.5 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.dateOfBirth')} type="date" slotProps={{ inputLabel: { shrink: true } }} value={dob} onChange={e=>setDob(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 1.5 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.ssn')} value={ssn} onChange={e=>setSsn(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 1.5 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.username')} value={userName} onChange={e=>setUserName(e.target.value)} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 1.5 }}>
            <TextField fullWidth size="small" label={t('legacyUsers.password')} type="password" value={password} onChange={e=>setPassword(e.target.value)} />
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
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('common.id')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('common.name')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('legacyUsers.username')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }}>{t('legacyUsers.phone')}</TableCell>
                <TableCell sx={{ color: 'white', fontWeight: 600 }} width={60}></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {items.map(u=> (
                <TableRow key={u.id} hover>
                  <TableCell>{u.id}</TableCell>
                  <TableCell>{u.fullName}</TableCell>
                  <TableCell>{u.userName}</TableCell>
                  <TableCell>{u.phoneNumber}</TableCell>
                  <TableCell>
                    <IconButton size="small" color="error" onClick={()=>remove(u.id)}><Delete fontSize="small" /></IconButton>
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
