import React, { useEffect, useState, useRef } from 'react'
import api from '../services/api'
import {
  Box, Card, Typography, Grid, TextField, Button,
  FormControl, InputLabel, Select, MenuItem, List, ListItem, ListItemText, IconButton, Chip
} from '@mui/material'
import { Delete, Add, People, Gavel, AccountBalance, Work, Event, Folder } from '@mui/icons-material'

type CaseItem = { id:number; code:number }

export default function CaseRelations(){
  const [cases,setCases] = useState<CaseItem[]>([])
  const [selectedCase, setSelectedCase] = useState<number|undefined>(undefined)
  const [customers,setCustomers] = useState<any[]>([])
  const [contenders,setContenders] = useState<any[]>([])
  const [courts,setCourts] = useState<any[]>([])
  const [employees,setEmployees] = useState<any[]>([])
  const [sitings,setSitings] = useState<any[]>([])
  const [files,setFiles] = useState<any[]>([])

  const custIdRef = useRef<HTMLInputElement>(null)
  const contIdRef = useRef<HTMLInputElement>(null)
  const courtIdRef = useRef<HTMLInputElement>(null)
  const empIdRef = useRef<HTMLInputElement>(null)
  const sitingIdRef = useRef<HTMLInputElement>(null)
  const fileIdRef = useRef<HTMLInputElement>(null)

  useEffect(()=>{ async function loadAll(){ const r = await api.get('/Cases'); setCases(r.data || []) } loadAll() },[])

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
    <Card sx={{ p: 2, height: '100%' }}>
      <Box display="flex" alignItems="center" gap={1} mb={2}>
        {icon}
        <Typography variant="h6" fontWeight={600}>{title}</Typography>
        <Chip label={items.length} size="small" color="primary" sx={{ ml: 'auto' }} />
      </Box>
      <List dense sx={{ maxHeight: 200, overflow: 'auto', mb: 2 }}>
        {items.map((item:any, idx) => (
          <ListItem key={idx} secondaryAction={
            <IconButton edge="end" size="small" color="error" onClick={()=>detach(type, item[idField] ?? item.id)}>
              <Delete fontSize="small" />
            </IconButton>
          }>
            <ListItemText primary={typeof displayField === 'function' ? displayField(item) : (item[displayField] ?? `#${item[idField] ?? item.id}`)} />
          </ListItem>
        ))}
        {items.length === 0 && <Typography variant="body2" color="text.secondary" sx={{ p: 1 }}>No items linked</Typography>}
      </List>
      <Box display="flex" gap={1}>
        <TextField size="small" label="Add by ID" type="number" inputRef={inputRef} sx={{ flex: 1 }} />
        <Button variant="outlined" size="small" startIcon={<Add />} onClick={()=>{ const val = inputRef.current?.value; if(val) { attach(type, Number(val)); inputRef.current!.value = ''; } }}>Add</Button>
      </Box>
    </Card>
  )

  return (
    <Box>
      <Typography variant="h5" gutterBottom fontWeight={600}>Case Relations</Typography>
      <Card sx={{ p: 2, mb: 3 }}>
        <FormControl sx={{ minWidth: 300 }} size="small">
          <InputLabel>Select Case</InputLabel>
          <Select value={selectedCase || ''} label="Select Case" onChange={e=>{ setSelectedCase(Number(e.target.value)||undefined); if(Number(e.target.value)) loadRelations(Number(e.target.value)) }}>
            <MenuItem value="">-- Select a Case --</MenuItem>
            {cases.map(c=> <MenuItem key={c.id} value={c.code}>Case #{c.code} (ID: {c.id})</MenuItem>)}
          </Select>
        </FormControl>
      </Card>

      {selectedCase && (
        <Grid container spacing={2}>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title="Customers" icon={<People color="primary" />} items={customers} idField="customerId" displayField={(c)=> c.customerName ?? c.CustomerName ?? `#${c.customerId}`} type="customers" inputRef={custIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title="Contenders" icon={<Gavel color="primary" />} items={contenders} idField="contenderId" displayField="fullName" type="contenders" inputRef={contIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title="Courts" icon={<AccountBalance color="primary" />} items={courts} idField="courtId" displayField={(c)=> c.courtName ?? c.CourtName ?? `#${c.courtId}`} type="courts" inputRef={courtIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title="Employees" icon={<Work color="primary" />} items={employees} idField="employeeId" displayField={(e)=> e.employeeName ?? e.EmployeeName ?? `#${e.employeeId}`} type="employees" inputRef={empIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title="Sitings" icon={<Event color="primary" />} items={sitings} idField="sitingId" displayField={(s)=> `${s.sitingDate ?? ''} ${s.sitingTime ?? ''}`} type="sitings" inputRef={sitingIdRef} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <RelationCard title="Files" icon={<Folder color="primary" />} items={files} idField="fileId" displayField="path" type="files" inputRef={fileIdRef} />
          </Grid>
        </Grid>
      )}
    </Box>
  )
}
