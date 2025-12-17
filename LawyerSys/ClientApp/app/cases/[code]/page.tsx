"use client"
import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Snackbar,
  Alert,
  Tooltip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import { ArrowBack, Delete as DeleteIcon, Download as DownloadIcon, Add as AddIcon } from '@mui/icons-material';
import api from '../../../src/services/api';

export default function CaseDetailsPage() {
  const { t } = useTranslation();
  const params = useParams() as { code?: string } | undefined;
  const code = Number(params?.code);
  const router = useRouter();

  const [data, setData] = useState<any | null>(null);
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success'|'error' }>({ open: false, message: '', severity: 'success' });

  // edit state
  const [editing, setEditing] = useState(false);
  const [editFields, setEditFields] = useState({ invitionType: '', invitionDate: '', totalAmount: 0, notes: '' });

  // dialogs
  const [addCustomerOpen, setAddCustomerOpen] = useState(false);
  const [customersList, setCustomersList] = useState<any[]>([]);
  const [selectedCustomerToAdd, setSelectedCustomerToAdd] = useState<number | ''>('');

  const [fileInputKey, setFileInputKey] = useState(0);

  // siting dialog
  const [createSitingOpen, setCreateSitingOpen] = useState(false);
  const [newSiting, setNewSiting] = useState({ date: '', time: '', judgeName: '', notes: '' });

  // contender edit dialog
  const [editContenderOpen, setEditContenderOpen] = useState(false);
  const [editingContender, setEditingContender] = useState<any | null>(null);

  // employees assign
  const [assignEmployeeOpen, setAssignEmployeeOpen] = useState(false);
  const [employeesList, setEmployeesList] = useState<any[]>([]);
  const [selectedEmployeeToAdd, setSelectedEmployeeToAdd] = useState<number | ''>('');

  // courts selection
  const [courtsList, setCourtsList] = useState<any[]>([]);
  const [selectedCourtToSet, setSelectedCourtToSet] = useState<number | ''>('');

  // inline edit for siting & files
  const [editSitingOpen, setEditSitingOpen] = useState(false);
  const [editingSiting, setEditingSiting] = useState<any | null>(null);
  const [editFileOpen, setEditFileOpen] = useState(false);
  const [editingFile, setEditingFile] = useState<any | null>(null);

  async function load() {
    setLoading(true);
    try {
      const r = await api.get(`/cases/${code}/full`);
      setData(r.data);
    } catch (err: any) {
      setSnackbar({ open: true, message: err?.response?.data?.message ?? 'Failed to load case', severity: 'error' });
    } finally { setLoading(false); }
  }

  useEffect(() => { if (code) load(); }, [code]);

  // initialize edit fields when data loads
  useEffect(() => {
    if (!data?.Case) return;
    setEditFields({ invitionType: data.Case.InvitionType ?? '', invitionDate: data.Case.InvitionDate ?? '', totalAmount: data.Case.TotalAmount ?? 0, notes: data.Case.Notes ?? '' });
    // set selected court if present
    if (data.Courts && data.Courts.length > 0) setSelectedCourtToSet(data.Courts[0].CourtId || data.Courts[0].Id);
  }, [data]);

  async function removeCustomer(customerId:number){
    try{ await api.delete(`/cases/${code}/customers/${customerId}`); setSnackbar({ open: true, message: t('customers.customerDeleted'), severity: 'success' }); await load(); }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? 'Failed', severity: 'error' }); }
  }

  async function openAddCustomer(){
    try{ const r = await api.get('/Customers'); setCustomersList(r.data || []);}catch(e){ setSnackbar({ open: true, message: 'Failed to load customers', severity: 'error' }); }
    setAddCustomerOpen(true);
  }

  async function addCustomer(){
    if(!selectedCustomerToAdd) return setSnackbar({ open:true, message: 'Choose customer', severity: 'error' });
    try{ await api.post(`/cases/${code}/customers/${selectedCustomerToAdd}`); setAddCustomerOpen(false); setSelectedCustomerToAdd(''); await load(); setSnackbar({ open:true, message: 'Customer added', severity: 'success' }); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to add', severity: 'error' }); }
  }

  // Edit case general info
  function startEditing(){ setEditing(true); }
  function cancelEditing(){ setEditing(false); setEditFields({ invitionType: data?.Case?.InvitionType ?? '', invitionDate: data?.Case?.InvitionDate ?? '', totalAmount: data?.Case?.TotalAmount ?? 0, notes: data?.Case?.Notes ?? '' }); setSelectedCourtToSet(data?.Courts?.[0]?.CourtId || data?.Courts?.[0]?.Id || ''); }

  async function saveCaseEdits(){
    try{
      // Update basic case
      const payload:any = {};
      if (editFields.invitionType != null) payload.InvitionType = editFields.invitionType;
      if (editFields.invitionDate) payload.InvitionDate = editFields.invitionDate;
      if (editFields.totalAmount != null) payload.TotalAmount = Number(editFields.totalAmount);
      if (editFields.notes != null) payload.Notes = editFields.notes;
      await api.put(`/Cases/${code}`, payload);

      // Update court: remove existing courts and add selected if provided
      if (selectedCourtToSet !== ''){
        // remove all current
        for (const c of data.Courts || []){
          try{ await api.delete(`/cases/${code}/courts/${c.CourtId || c.Id}`); }catch(e){}
        }
        try{ await api.post(`/cases/${code}/courts/${selectedCourtToSet}`); }catch(e){}
      }

      setSnackbar({ open:true, message: 'Case updated', severity: 'success' });
      setEditing(false);
      await load();
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to update', severity: 'error' }); }
  }

  // Sitings: create and link
  async function createAndLinkSiting(){
    try{
      const payload = { SitingTime: new Date(`${newSiting.date}T${newSiting.time}`), SitingDate: newSiting.date, SitingNotification: new Date(`${newSiting.date}T${newSiting.time}`), JudgeName: newSiting.judgeName, Notes: newSiting.notes };
      const r = await api.post('/Sitings', payload);
      const sitingId = r.data.id;
      await api.post(`/cases/${code}/sitings/${sitingId}`);
      setCreateSitingOpen(false);
      setNewSiting({ date:'', time:'', judgeName:'', notes:'' });
      setSnackbar({ open:true, message: t('sitingCreated') ?? 'Siting created', severity: 'success' });
      await load();
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to create siting', severity: 'error' }); }
  }

  // Edit siting
  async function openEditSiting(sitingId:number){
    try{
      const r = await api.get(`/Sitings/${sitingId}`);
      // API returns full siting dto
      const sit = r.data;
      setEditingSiting({ id: sit.Id, date: sit.SitingDate ?? sit.Siting_Date ?? '', time: sit.SitingTime ? new Date(sit.SitingTime).toISOString().slice(11,19) : '', judgeName: sit.JudgeName ?? sit.Judge_Name, notes: sit.Notes });
      setEditSitingOpen(true);
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to load siting', severity:'error' }); }
  }

  async function saveSitingEdit(){
    if(!editingSiting) return;
    try{
      const payload:any = {};
      if(editingSiting.date) payload.SitingDate = editingSiting.date;
      if(editingSiting.time) payload.SitingTime = new Date(`${editingSiting.date}T${editingSiting.time}`);
      if(editingSiting.judgeName != null) payload.JudgeName = editingSiting.judgeName;
      if(editingSiting.notes != null) payload.Notes = editingSiting.notes;
      await api.put(`/Sitings/${editingSiting.id}`, payload);
      setEditSitingOpen(false);
      setEditingSiting(null);
      setSnackbar({ open:true, message: t('sitingUpdated') ?? 'Siting updated', severity:'success' });
      await load();
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to update siting', severity:'error' }); }
  }

  // Contender edit
  function openEditContender(cont:any){ setEditingContender(cont); setEditContenderOpen(true); }
  async function saveContenderEdit(){
    if(!editingContender) return;
    try{ await api.put(`/Contenders/${editingContender.ContenderId || editingContender.Id}`, { FullName: editingContender.FullName ?? editingContender.ContenderName, SSN: editingContender.SSN, BirthDate: editingContender.BirthDate }); setEditContenderOpen(false); setEditingContender(null); setSnackbar({ open:true, message: 'Contender updated', severity:'success' }); await load(); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to update contender', severity:'error' }); }
  }

  // Employees assign
  async function openAssignEmployee(){ try{ const r = await api.get('/Employees'); setEmployeesList(r.data || []); setAssignEmployeeOpen(true); }catch(err:any){ setSnackbar({ open:true, message: 'Failed to load employees', severity:'error' }); } }
  async function assignEmployee(){ if(!selectedEmployeeToAdd) return; try{ await api.post(`/cases/${code}/employees/${selectedEmployeeToAdd}`); setAssignEmployeeOpen(false); setSelectedEmployeeToAdd(''); setSnackbar({ open:true, message: 'Employee assigned', severity:'success' }); await load(); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to assign', severity:'error' }); } }

  async function removeContender(id:number){ try{ await api.delete(`/cases/${code}/contenders/${id}`); await load(); setSnackbar({ open:true, message: 'Contender removed', severity:'success' }); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed', severity:'error' }); } }

  async function removeSiting(sitingId:number){ try{ await api.delete(`/cases/${code}/sitings/${sitingId}`); await load(); setSnackbar({ open:true, message: 'Siting removed', severity:'success' }); }catch(err:any){ setSnackbar({ open:true, message: 'Failed to remove siting', severity:'error' }); } }

  async function uploadFiles(files:FileList | null){ if(!files) return; try{
    for(const f of Array.from(files)){
      const fd = new FormData(); fd.append('file', f); const r = await api.post('/Files/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } }); const fileId = r.data.id; await api.post(`/cases/${code}/files/${fileId}`);
    }
    setFileInputKey(k=>k+1);
    setSnackbar({ open:true, message: 'Files uploaded', severity:'success' });
    await load();
  }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to upload', severity:'error' }); } }

  async function removeFile(fileId:number){ try{ await api.delete(`/cases/${code}/files/${fileId}`); setSnackbar({ open:true, message: 'File removed', severity:'success' }); await load(); }catch(err:any){ setSnackbar({ open:true, message: 'Failed to remove file', severity:'error' }); } }

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display:'flex', alignItems:'center', gap:2, mb:2 }}>
        <Tooltip title={t('app.back') || 'Back'}>
          <IconButton onClick={()=>router.push('/cases')}><ArrowBack/></IconButton>
        </Tooltip>
        <Typography variant="h5">{t('cases.details') || 'Case Details'} - #{data?.Case?.Code ?? code}</Typography>
      </Box>

      {data ? (
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
          <Box>
            <Card><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('cases.general') || 'General'}</Typography>
                {!editing ? <Button size="small" onClick={startEditing}>{t('app.edit') || 'Edit'}</Button> : <Box><Button size="small" onClick={cancelEditing}>{t('app.cancel')}</Button> <Button size="small" variant="contained" onClick={saveCaseEdits}>{t('app.save') || 'Save'}</Button></Box>}
              </Box>

              <Typography>{t('cases.code')}: <strong>{data.Case.Code}</strong></Typography>

              {!editing ? (
                <>
                  <Typography>{t('cases.type')}: {data.Case.InvitionType}</Typography>
                  <Typography>{t('cases.date')}: {String(data.Case.InvitionDate)}</Typography>
                  <Typography>{t('cases.amount')}: {data.Case.TotalAmount}</Typography>
                  <Typography>{t('cases.notes')}: {data.Case.Notes}</Typography>
                </>
              ) : (
                <Box sx={{ mt:1, display:'grid', gridTemplateColumns:{ xs:'1fr', sm:'1fr 1fr'}, gap:1 }}>
                  <TextField label={t('cases.type')} value={editFields.invitionType} onChange={(e)=>setEditFields({...editFields, invitionType: e.target.value})} />
                  <TextField label={t('cases.date')} type="date" InputLabelProps={{ shrink:true }} value={editFields.invitionDate?.slice(0,10) ?? ''} onChange={(e)=>setEditFields({...editFields, invitionDate: e.target.value})} />
                  <TextField label={t('cases.amount')} type="number" value={editFields.totalAmount ?? ''} onChange={(e)=>setEditFields({...editFields, totalAmount: Number(e.target.value)})} />
                  <TextField label={t('cases.notes')} value={editFields.notes} onChange={(e)=>setEditFields({...editFields, notes: e.target.value})} multiline rows={2} />

                  <FormControl fullWidth>
                    <InputLabel>{t('courts.name')}</InputLabel>
                    <Select value={selectedCourtToSet} label={t('courts.name')} onOpen={async ()=>{ if(courtsList.length===0){ const r = await api.get('/Courts'); setCourtsList(r.data || []); } }} onChange={(e)=>setSelectedCourtToSet(Number(e.target.value) || '')}>
                      <MenuItem value=""><em>--</em></MenuItem>
                      {courtsList.map(c=> (<MenuItem key={c.id} value={c.id}>{c.name}</MenuItem>))}
                    </Select>
                  </FormControl>
                </Box>
              )}
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('customers.title') || 'Customers'}</Typography>
                <Button size="small" startIcon={<AddIcon/>} onClick={openAddCustomer}>{t('customers.add') || 'Add'}</Button>
              </Box>
              <List>
                {data.Customers.map((c:any)=> (
                  <ListItem key={c.Id} secondaryAction={<Button color="error" size="small" onClick={()=>removeCustomer(c.CustomerId)}>{t('app.delete')}</Button>}>
                    <ListItemText primary={c.CustomerName} secondary={`#${c.CustomerId}`} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('contenders.title') || 'Contenders'}</Typography>
              </Box>
              <List>
                {data.Contenders.map((c:any)=> (
                  <ListItem key={c.Id} secondaryAction={<Box>
                    <Button size="small" onClick={()=>openEditContender(c)}>{t('app.edit') || 'Edit'}</Button>
                    <Button color="error" size="small" onClick={()=>removeContender(c.ContenderId)}>{t('app.delete')}</Button>
                  </Box>}>
                    <ListItemText primary={c.ContenderName} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>

          </Box>

          <Box>
            <Card><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('sitings.title') || 'Sitings'}</Typography>
                <Box>
                  <Button size="small" onClick={()=>setCreateSitingOpen(true)} startIcon={<AddIcon/>}>{t('cases.createNewSiting') || 'Add'}</Button>
                </Box>
              </Box>
              <List>
                {data.Sitings.map((s:any)=> (
                  <ListItem key={s.Id} secondaryAction={<Box sx={{ display:'flex', gap:1 }}><Button size="small" onClick={()=>openEditSiting(s.SitingId)}>{t('app.edit') || 'Edit'}</Button><Button color="error" size="small" onClick={()=>removeSiting(s.SitingId)}>{t('app.delete')}</Button></Box>}>
                    <ListItemText primary={`${s.SitingDate} - ${s.JudgeName}`} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('files.title') || 'Files'}</Typography>
                <Box>
                  <Button size="small" onClick={()=>setFileInputKey(k=>k+1)} startIcon={<AddIcon/>}>{t('files.upload') || 'Upload'}</Button>
                </Box>
              </Box>
              <Box sx={{ mt:1 }}>
                <input key={fileInputKey} type="file" multiple onChange={(e)=>uploadFiles(e.target.files)} />
              </Box>
              <List>
                {data.Files.map((f:any)=> (
                  <ListItem key={f.Id} secondaryAction={<Box sx={{ display:'flex', gap:1 }}>
                    <Button size="small" onClick={()=>{ setEditingFile({ id: f.FileId, code: f.FileCode ?? '' }); setEditFileOpen(true); }}>{t('app.edit') || 'Edit'}</Button>
                    <IconButton href={`/api/files/${f.FileId}/download`} target="_blank"><DownloadIcon/></IconButton>
                    <IconButton color="error" onClick={()=>removeFile(f.FileId)}><DeleteIcon/></IconButton>
                  </Box>}>
                    <ListItemText primary={`${f.FileCode || f.FileId}`} secondary={f.FilePath} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('cases.courts') || 'Courts'}</Typography>
                <Button size="small" onClick={async ()=>{ if(courtsList.length===0){ const r = await api.get('/Courts'); setCourtsList(r.data || []);} setSelectedCourtToSet(data.Courts?.[0]?.CourtId || data.Courts?.[0]?.Id || ''); setEditing(true); }}>{t('app.edit') || 'Edit'}</Button>
              </Box>
              <List>
                {data.Courts.map((c:any)=> (<ListItem key={c.Id}><ListItemText primary={c.CourtName} /></ListItem>))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('cases.employees') || 'Employees'}</Typography>
                <Button size="small" onClick={openAssignEmployee} startIcon={<AddIcon/>}>{t('employees.add') || 'Assign'}</Button>
              </Box>
              <List>
                {data.Employees.map((e:any)=> (<ListItem key={e.id}><ListItemText primary={e.Full_Name || e.fullName} /><Button size="small" color="error" onClick={async ()=>{ try{ await api.delete(`/cases/${code}/employees/${e.id}`); await load(); setSnackbar({ open:true, message: 'Employee removed', severity:'success' }); }catch(err:any){ setSnackbar({ open:true, message: 'Failed to remove', severity:'error' }); } }}>Remove</Button></ListItem>))}
              </List>
            </CardContent></Card>

          </Box>
        </Box>
      ) : (
        <Typography>{loading ? 'Loading...' : 'No data'}</Typography>
      )}

      {/* Add Customer Dialog */}
      <Dialog open={addCustomerOpen} onClose={()=>setAddCustomerOpen(false)}>
        <DialogTitle>{t('customers.add') || 'Add Customer to Case'}</DialogTitle>
        <DialogContent>
          <FormControl fullWidth sx={{ mt:1 }}>
            <InputLabel>{t('customers.customer')}</InputLabel>
            <Select value={selectedCustomerToAdd} onChange={(e)=>setSelectedCustomerToAdd(Number(e.target.value) || '')}>
              <MenuItem value=""><em>--</em></MenuItem>
              {customersList.map(c => (<MenuItem key={c.id} value={c.id}>{c.identity?.fullName || c.user?.fullName || ('#'+c.usersId)}</MenuItem>))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setAddCustomerOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={addCustomer}>{t('app.create')}</Button>
        </DialogActions>
      </Dialog>

      {/* Create Siting Dialog */}
      <Dialog open={createSitingOpen} onClose={()=>setCreateSitingOpen(false)}>
        <DialogTitle>{t('cases.createNewSiting') || 'Add Siting'}</DialogTitle>
        <DialogContent>
          <Box sx={{ display:'grid', gap:1, gridTemplateColumns:{ xs:'1fr', sm:'1fr 1fr' } }}>
            <TextField label={t('cases.date')} type="date" InputLabelProps={{ shrink:true }} value={newSiting.date} onChange={(e)=>setNewSiting({...newSiting, date: e.target.value})} />
            <TextField label={t('time') || 'Time'} type="time" value={newSiting.time} onChange={(e)=>setNewSiting({...newSiting, time: e.target.value})} />
            <TextField label={t('judge') || 'Judge'} value={newSiting.judgeName} onChange={(e)=>setNewSiting({...newSiting, judgeName: e.target.value})} />
            <TextField label={t('cases.notes')} value={newSiting.notes} onChange={(e)=>setNewSiting({...newSiting, notes: e.target.value})} />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setCreateSitingOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={createAndLinkSiting}>{t('app.create')}</Button>
        </DialogActions>
      </Dialog>

      {/* Edit Contender Dialog */}
      <Dialog open={editContenderOpen} onClose={()=>setEditContenderOpen(false)}>
        <DialogTitle>{t('contenders.title')}</DialogTitle>
        <DialogContent>
          <Box sx={{ display:'grid', gap:1 }}>
            <TextField label={t('contenders.title')} value={editingContender?.ContenderName ?? editingContender?.FullName} onChange={(e)=>setEditingContender({...editingContender, FullName: e.target.value, ContenderName: e.target.value})} />
            <TextField label={t('customers.ssn')} value={editingContender?.SSN ?? ''} onChange={(e)=>setEditingContender({...editingContender, SSN: e.target.value})} />
            <TextField label={t('customers.dateOfBirth')} type="date" InputLabelProps={{ shrink:true }} value={editingContender?.BirthDate ?? ''} onChange={(e)=>setEditingContender({...editingContender, BirthDate: e.target.value})} />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setEditContenderOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={saveContenderEdit}>{t('app.save')}</Button>
        </DialogActions>
      </Dialog>

      {/* Edit Siting Dialog */}
      <Dialog open={editSitingOpen} onClose={()=>setEditSitingOpen(false)}>
        <DialogTitle>{t('sitings.title') || 'Edit Siting'}</DialogTitle>
        <DialogContent>
          <Box sx={{ display:'grid', gap:1, gridTemplateColumns:{ xs:'1fr', sm:'1fr 1fr' } }}>
            <TextField label={t('cases.date')} type="date" InputLabelProps={{ shrink:true }} value={editingSiting?.date ?? ''} onChange={(e)=>setEditingSiting({...editingSiting, date: e.target.value})} />
            <TextField label={t('time') || 'Time'} type="time" value={editingSiting?.time ?? ''} onChange={(e)=>setEditingSiting({...editingSiting, time: e.target.value})} />
            <TextField label={t('judge') || 'Judge'} value={editingSiting?.judgeName ?? ''} onChange={(e)=>setEditingSiting({...editingSiting, judgeName: e.target.value})} />
            <TextField label={t('cases.notes')} value={editingSiting?.notes ?? ''} onChange={(e)=>setEditingSiting({...editingSiting, notes: e.target.value})} />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setEditSitingOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={saveSitingEdit}>{t('app.save')}</Button>
        </DialogActions>
      </Dialog>

      {/* Edit File Dialog */}
      <Dialog open={editFileOpen} onClose={()=>setEditFileOpen(false)}>
        <DialogTitle>{t('files.title') || 'Edit File'}</DialogTitle>
        <DialogContent>
          <Box sx={{ display:'grid', gap:1 }}>
            <TextField label={t('files.code')} value={editingFile?.code ?? ''} onChange={(e)=>setEditingFile({...editingFile, code: e.target.value})} />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setEditFileOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={async ()=>{
            try{
              if(!editingFile) return;
              await api.put(`/Files/${editingFile.id}`, { Code: editingFile.code });
              setEditFileOpen(false);
              setEditingFile(null);
              setSnackbar({ open:true, message: t('fileUpdated') ?? 'File updated', severity:'success' });
              await load();
            }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to update file', severity:'error' }); }
          }}>{t('app.save')}</Button>
        </DialogActions>
      </Dialog>

      {/* Assign Employee Dialog */}
      <Dialog open={assignEmployeeOpen} onClose={()=>setAssignEmployeeOpen(false)}>
        <DialogTitle>{t('employees.add') || 'Assign Employee'}</DialogTitle>
        <DialogContent>
          <FormControl fullWidth>
            <InputLabel>{t('employees.employee') || 'Employee'}</InputLabel>
            <Select value={selectedEmployeeToAdd} onChange={(e)=>setSelectedEmployeeToAdd(Number(e.target.value) || '')} onOpen={async ()=>{ if(employeesList.length===0){ const r = await api.get('/Employees'); setEmployeesList(r.data || []);} }}>
              <MenuItem value=""><em>--</em></MenuItem>
              {employeesList.map(emp=> (<MenuItem key={emp.id} value={emp.id}>{emp.user?.fullName || emp.user?.userName}</MenuItem>))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setAssignEmployeeOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={assignEmployee}>{t('app.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={()=>setSnackbar({...snackbar, open:false})}>
        <Alert severity={snackbar.severity} onClose={()=>setSnackbar({...snackbar, open:false})}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
