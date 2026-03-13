"use client"
import React, { useEffect, useRef, useState } from 'react';
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
  Chip,
  Switch,
  FormControlLabel,
} from '@mui/material';
import { ArrowBack, Delete as DeleteIcon, Download as DownloadIcon, Add as AddIcon, CloudUpload as CloudUploadIcon } from '@mui/icons-material';
import api from '../../../src/services/api';
import { useAuth } from '../../../src/services/auth';
import SearchableSelect from '../../../src/components/SearchableSelect';

export default function CaseDetailsPage() {
  const { t } = useTranslation();
  const params = useParams() as { code?: string } | undefined;
  const code = Number(params?.code);
  const router = useRouter();

  const { hasAnyRole, user } = useAuth();
  const canManageCase = hasAnyRole('Admin', 'Employee');
  const isCustomerOnly = Boolean(user?.roles?.includes('Customer') && !hasAnyRole('SuperAdmin', 'Admin', 'Employee'));
  const [data, setData] = useState<any | null>(null);
  const [conversation, setConversation] = useState<any[]>([]);
  const [conversationMessage, setConversationMessage] = useState('');
  const [conversationAttachment, setConversationAttachment] = useState<File | null>(null);
  const [sendingConversation, setSendingConversation] = useState(false);
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success'|'error' }>({ open: false, message: '', severity: 'success' });
  const [caseNotificationsEnabled, setCaseNotificationsEnabled] = useState(true);
  const [requestDocumentOpen, setRequestDocumentOpen] = useState(false);
  const [newRequestedDocument, setNewRequestedDocument] = useState({ customerId: '', title: '', description: '', dueDate: '' });
  const [documentReviewNotes, setDocumentReviewNotes] = useState<Record<number, string>>({});
  const [paymentProofReviewNotes, setPaymentProofReviewNotes] = useState<Record<number, string>>({});
  const [requestedDocumentUploadTarget, setRequestedDocumentUploadTarget] = useState<{ requestId: number; caseCode: number } | null>(null);
  const requestedDocumentInputRef = useRef<HTMLInputElement | null>(null);

  // edit state
  const [editing, setEditing] = useState(false);
  const [editFields, setEditFields] = useState({ invitionType: '', invitionDate: '', totalAmount: 0, notes: '' });

  // dialogs
  const [addCustomerOpen, setAddCustomerOpen] = useState(false);
  const [customersList, setCustomersList] = useState<any[]>([]);
  const [selectedCustomerToAdd, setSelectedCustomerToAdd] = useState<number | ''>('');

  const [fileInputKey, setFileInputKey] = useState(0);
  const [isDraggingFiles, setIsDraggingFiles] = useState(false);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

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
  const [statusOptions, setStatusOptions] = useState<Array<{ value: number; key: string; label: string; next: Array<{ value: number; key: string; label: string }> }>>([]);

  async function load() {
    setLoading(true);
    try {
      const requests = [
        api.get(`/cases/${code}/full`),
        api.get(`/cases/${code}/conversation`),
      ] as const;
      const [detailsResponse, conversationResponse, notificationResponse] = await Promise.all([
        ...requests,
        isCustomerOnly ? api.get(`/cases/${code}/notification-preferences`) : Promise.resolve({ data: { notificationsEnabled: true } }),
      ]);
      setData(detailsResponse.data);
      setConversation(conversationResponse.data || []);
      setCaseNotificationsEnabled(notificationResponse?.data?.notificationsEnabled ?? true);
    } catch (err: any) {
      setSnackbar({ open: true, message: err?.response?.data?.message ?? 'Failed to load case', severity: 'error' });
    } finally { setLoading(false); }
  }

  useEffect(() => { if (code) load(); }, [code, isCustomerOnly]);
  useEffect(() => {
    if (!canManageCase) {
      setStatusOptions([]);
      return;
    }

    (async () => {
      try {
        const r = await api.get('/Cases/status-options');
        setStatusOptions(r.data || []);
      } catch {
        setStatusOptions([]);
      }
    })();
  }, [canManageCase]);

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

  async function uploadFileArray(files:File[]){
    if(files.length === 0) return;
    try{
    for(const f of files){
      if (isCustomerOnly) {
        const fd = new FormData();
        fd.append('file', f);
        fd.append('title', f.name);
        await api.post(`/ClientPortal/cases/${code}/files`, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      } else {
        const fd = new FormData();
        fd.append('file', f);
        const r = await api.post('/Files/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
        const fileId = r.data.id;
        await api.post(`/cases/${code}/files/${fileId}`);
      }
    }
    setFileInputKey(k=>k+1);
    setSnackbar({ open:true, message: 'Files uploaded', severity:'success' });
    await load();
  }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to upload', severity:'error' }); } }

  async function uploadFiles(files:FileList | null){
    if(!files) return;
    await uploadFileArray(Array.from(files));
  }

  async function handleDropFiles(e: React.DragEvent<HTMLDivElement>){
    e.preventDefault();
    setIsDraggingFiles(false);
    await uploadFileArray(Array.from(e.dataTransfer.files || []));
  }

  async function removeFile(fileId:number){ try{ await api.delete(`/cases/${code}/files/${fileId}`); setSnackbar({ open:true, message: 'File removed', severity:'success' }); await load(); }catch(err:any){ setSnackbar({ open:true, message: 'Failed to remove file', severity:'error' }); } }

  async function sendConversationMessage(){
    const message = conversationMessage.trim();
    if((!message && !conversationAttachment) || sendingConversation) return;
    try{
      setSendingConversation(true);
      if (conversationAttachment) {
        const fd = new FormData();
        fd.append('message', message);
        fd.append('visibleToCustomer', 'true');
        fd.append('attachment', conversationAttachment);
        await api.post(`/cases/${code}/conversation/attachment`, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      } else {
        await api.post(`/cases/${code}/conversation`, { message });
      }
      setConversationMessage('');
      setConversationAttachment(null);
      await load();
      setSnackbar({ open:true, message: t('cases.conversation.sent', { defaultValue: 'Message sent' }), severity:'success' });
    }catch(err:any){
      setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.conversation.failedSend', { defaultValue: 'Failed to send message' }), severity:'error' });
    } finally {
      setSendingConversation(false);
    }
  }

  async function updateCaseNotificationPreference(nextValue:boolean){
    try{
      setCaseNotificationsEnabled(nextValue);
      await api.put(`/cases/${code}/notification-preferences`, { notificationsEnabled: nextValue });
      setSnackbar({ open:true, message: t('cases.customerNotifications.updated', { defaultValue: 'Notification preference updated' }), severity:'success' });
    }catch(err:any){
      setCaseNotificationsEnabled(!nextValue);
      setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.customerNotifications.failed', { defaultValue: 'Failed to update notification preference' }), severity:'error' });
    }
  }

  async function createRequestedDocument(){
    if(!newRequestedDocument.customerId || !newRequestedDocument.title.trim()){
      setSnackbar({ open:true, message: t('cases.requestedDocuments.validation', { defaultValue: 'Choose a customer and title.' }), severity:'error' });
      return;
    }
    try{
      await api.post(`/cases/${code}/requested-documents`, {
        customerId: Number(newRequestedDocument.customerId),
        title: newRequestedDocument.title.trim(),
        description: newRequestedDocument.description.trim(),
        dueDate: newRequestedDocument.dueDate || null,
      });
      setRequestDocumentOpen(false);
      setNewRequestedDocument({ customerId: '', title: '', description: '', dueDate: '' });
      setSnackbar({ open:true, message: t('cases.requestedDocuments.created', { defaultValue: 'Requested document created' }), severity:'success' });
      await load();
    }catch(err:any){
      setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.requestedDocuments.failedCreate', { defaultValue: 'Failed to create requested document' }), severity:'error' });
    }
  }

  async function reviewRequestedDocument(requestId:number, status:'Approved'|'Rejected'){
    try{
      await api.post(`/cases/${code}/requested-documents/${requestId}/review`, {
        status,
        reviewNotes: documentReviewNotes[requestId] || '',
      });
      setSnackbar({ open:true, message: t('cases.requestedDocuments.reviewed', { defaultValue: 'Requested document updated' }), severity:'success' });
      await load();
    }catch(err:any){
      setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.requestedDocuments.failedReview', { defaultValue: 'Failed to review requested document' }), severity:'error' });
    }
  }

  async function reviewPaymentProof(proofId:number, status:'Approved'|'Rejected'){
    try{
      await api.post(`/cases/${code}/payment-proofs/${proofId}/review`, {
        status,
        reviewNotes: paymentProofReviewNotes[proofId] || '',
      });
      setSnackbar({ open:true, message: t('cases.paymentProofs.reviewed', { defaultValue: 'Payment proof updated' }), severity:'success' });
      await load();
    }catch(err:any){
      setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.paymentProofs.failedReview', { defaultValue: 'Failed to review payment proof' }), severity:'error' });
    }
  }

  async function handleRequestedDocumentUpload(event: React.ChangeEvent<HTMLInputElement>){
    const nextFile = event.target.files?.[0];
    event.target.value = '';
    if(!nextFile || !requestedDocumentUploadTarget) return;
    try{
      const fd = new FormData();
      fd.append('file', nextFile);
      fd.append('notes', documentReviewNotes[requestedDocumentUploadTarget.requestId] || '');
      await api.post(`/ClientPortal/cases/${requestedDocumentUploadTarget.caseCode}/requested-documents/${requestedDocumentUploadTarget.requestId}/submit`, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      setSnackbar({ open:true, message: t('cases.requestedDocuments.uploaded', { defaultValue: 'Requested document uploaded' }), severity:'success' });
      await load();
    }catch(err:any){
      setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.requestedDocuments.failedUpload', { defaultValue: 'Failed to upload requested document' }), severity:'error' });
    } finally {
      setRequestedDocumentUploadTarget(null);
    }
  }

  const currentStatus = Number(data?.Case?.Status ?? 0);
  const currentStatusOption = statusOptions.find(s => s.value === currentStatus);
  const allowedNextValues = new Set<number>([currentStatus, ...(currentStatusOption?.next?.map(n => n.value) ?? [])]);
  const statusKeys = ['new', 'inprogress', 'awaitinghearing', 'closed', 'won', 'lost'];
  const nextSiting = [...(data?.Sitings || [])]
    .sort((a:any, b:any) => String(a.SitingDate || '').localeCompare(String(b.SitingDate || '')))
    .find((item:any) => {
      if (!item?.SitingDate) return false;
      const parsed = new Date(item.SitingDate);
      return Number.isNaN(parsed.getTime()) ? true : parsed >= new Date(new Date().toDateString());
    });
  const latestStatusHistory = data?.StatusHistory?.[0] ?? null;
  const totalPaid = (data?.BillingPayments || []).reduce((sum:number, item:any) => sum + Number(item.Amount || 0), 0);

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display:'flex', alignItems:'center', gap:2, mb:2 }}>
        <Tooltip title={t('app.back') || 'Back'}>
          <IconButton onClick={()=>router.push(isCustomerOnly ? '/client-portal' : '/cases')}><ArrowBack/></IconButton>
        </Tooltip>
        <Typography variant="h5">{t('cases.details') || 'Case Details'} - {data?.Case?.Code ?? code}</Typography>
        <Button size="small" variant="outlined" onClick={() => router.push(`/cases/${code}/timeline`)}>Timeline</Button>
      </Box>

      {data ? (
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
          <Box>
            <Card><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('cases.general') || 'General'}</Typography>
                {canManageCase && (!editing ? <Button size="small" onClick={startEditing}>{t('app.edit') || 'Edit'}</Button> : <Box><Button size="small" onClick={cancelEditing}>{t('app.cancel')}</Button> <Button size="small" variant="contained" onClick={saveCaseEdits}>{t('app.save') || 'Save'}</Button></Box>)}
              </Box>

              <Typography>{t('cases.code')}: <strong>{data.Case.Code}</strong></Typography>
              <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mt: 1 }}>
                <Typography variant="body2" sx={{ color: 'text.secondary' }}>{t('cases.status')}: </Typography>
                <Chip label={t(`cases.statuses.${statusKeys[data.Case.Status]}`) || ['New','In Progress','Awaiting Hearing','Closed','Won','Lost'][data.Case.Status]} size="small" color="default" variant="outlined" />
                {canManageCase && (
                  <SearchableSelect<number>
                    size="small"
                    label={t('cases.status')}
                    value={data.Case.Status ?? 0}
                    onChange={async (value) => {
                        const newStatus = Number(value ?? 0);
                        try {
                          await api.post(`/Cases/${code}/status`, { status: ['New','InProgress','AwaitingHearing','Closed','Won','Lost'][newStatus] });
                          setSnackbar({ open: true, message: 'Status updated', severity: 'success' });
                          await load();
                        } catch (err:any) { setSnackbar({ open:true, message: err?.response?.data?.message ?? 'Failed to update status', severity:'error' }); }
                    }}
                    options={[
                      { value: 0, label: t('cases.statuses.new'), disabled: !allowedNextValues.has(0) },
                      { value: 1, label: t('cases.statuses.inprogress'), disabled: !allowedNextValues.has(1) },
                      { value: 2, label: t('cases.statuses.awaitinghearing'), disabled: !allowedNextValues.has(2) },
                      { value: 3, label: t('cases.statuses.closed'), disabled: !allowedNextValues.has(3) },
                      { value: 4, label: t('cases.statuses.won'), disabled: !allowedNextValues.has(4) },
                      { value: 5, label: t('cases.statuses.lost'), disabled: !allowedNextValues.has(5) },
                    ]}
                    disableClearable
                    sx={{ ml: 1, minWidth: 160 }}
                  />
                )}
              </Box>

              {isCustomerOnly && (
                <Box sx={{ mt: 1.5, display:'grid', gridTemplateColumns:{ xs:'1fr', sm:'1fr 1fr' }, gap:1 }}>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{t('cases.status')}</Typography><Typography variant="subtitle1">{t(`cases.statuses.${statusKeys[data.Case.Status]}`) || '-'}</Typography></CardContent></Card>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{t('clientPortal.caseSessions', { defaultValue: 'Case Sessions' })}</Typography><Typography variant="subtitle1">{nextSiting ? `${nextSiting.SitingDate} - ${nextSiting.JudgeName}` : '-'}</Typography></CardContent></Card>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{t('cases.employees') || 'Employees'}</Typography><Typography variant="subtitle1">{data.Employees?.map((e:any)=>e.Full_Name || e.fullName).filter(Boolean).join(', ') || '-'}</Typography></CardContent></Card>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{t('clientPortal.totalPaid', { defaultValue: 'Total Paid' })}</Typography><Typography variant="subtitle1">{totalPaid}</Typography></CardContent></Card>
                </Box>
              )}
              {isCustomerOnly && (
                <FormControlLabel
                  sx={{ mt: 1 }}
                  control={<Switch checked={caseNotificationsEnabled} onChange={(e)=>void updateCaseNotificationPreference(e.target.checked)} />}
                  label={t('cases.customerNotifications.label', { defaultValue: 'Notify me about updates on this case' })}
                />
              )}

              {!editing || !canManageCase ? (
                <>
                  <Typography>{t('cases.type')}: {data.Case.InvitionType}</Typography>
                  <Typography>{t('cases.date')}: {String(data.Case.InvitionDate)}</Typography>
                  <Typography>{t('cases.amount')}: {data.Case.TotalAmount}</Typography>
                  <Typography>{t('cases.notes')}: {data.Case.Notes}</Typography>
                  {isCustomerOnly && (
                    <>
                      <Typography>{t('cases.courts') || 'Courts'}: {data.Courts?.map((c:any)=>c.CourtName).filter(Boolean).join(', ') || '-'}</Typography>
                      <Typography>{t('clientPortal.latestUpdate', { defaultValue: 'Latest Update' })}: {latestStatusHistory?.ChangedAt ? new Date(latestStatusHistory.ChangedAt).toLocaleString() : '-'}</Typography>
                    </>
                  )}
                </>
              ) : (
                <Box sx={{ mt:1, display:'grid', gridTemplateColumns:{ xs:'1fr', sm:'1fr 1fr'}, gap:1 }}>
                  <TextField label={t('cases.type')} value={editFields.invitionType} onChange={(e)=>setEditFields({...editFields, invitionType: e.target.value})} />
                  <TextField label={t('cases.date')} type="date" InputLabelProps={{ shrink:true }} value={editFields.invitionDate?.slice(0,10) ?? ''} onChange={(e)=>setEditFields({...editFields, invitionDate: e.target.value})} />
                  <TextField label={t('cases.amount')} type="number" value={editFields.totalAmount ?? ''} onChange={(e)=>setEditFields({...editFields, totalAmount: Number(e.target.value)})} />
                  <TextField label={t('cases.notes')} value={editFields.notes} onChange={(e)=>setEditFields({...editFields, notes: e.target.value})} multiline rows={2} />

                  <SearchableSelect<number>
                    label={t('courts.name')}
                    value={typeof selectedCourtToSet === 'number' ? selectedCourtToSet : null}
                    onOpen={async ()=>{ if(courtsList.length===0){ const r = await api.get('/Courts'); setCourtsList(r.data || []); } }}
                    onChange={(value)=>setSelectedCourtToSet(value ?? '')}
                    options={courtsList.map((c)=> ({ value: c.id, label: c.name }))}
                  />
                </Box>
              )}
            </CardContent></Card>

            {!isCustomerOnly && <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('customers.title') || 'Customers'}</Typography>
                <Button size="small" startIcon={<AddIcon/>} onClick={openAddCustomer}>{t('customers.add') || 'Add'}</Button>
              </Box>
              <List>
                {data.Customers.map((c:any)=> (
                  <ListItem key={c.Id} secondaryAction={<Button color="error" size="small" onClick={()=>removeCustomer(c.CustomerId)}>{t('app.delete')}</Button>}>
                    <ListItemText primary={c.CustomerName} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>}

            {!isCustomerOnly && <Card sx={{ mt:2 }}><CardContent>
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
            </CardContent></Card>}

          </Box>

          <Box>
            <Card><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('sitings.title') || 'Sitings'}</Typography>
                <Box>
                  {canManageCase && <Button size="small" onClick={()=>setCreateSitingOpen(true)} startIcon={<AddIcon/>}>{t('cases.createNewSiting') || 'Add'}</Button>}
                </Box>
              </Box>
              <List>
                {data.Sitings.map((s:any)=> (
                  <ListItem key={s.Id} secondaryAction={canManageCase ? <Box sx={{ display:'flex', gap:1 }}><Button size="small" onClick={()=>openEditSiting(s.SitingId)}>{t('app.edit') || 'Edit'}</Button><Button color="error" size="small" onClick={()=>removeSiting(s.SitingId)}>{t('app.delete')}</Button></Box> : undefined}>
                    <ListItemText primary={`${s.SitingDate} - ${s.JudgeName}`} secondary={s.Notes || ''} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('files.title') || 'Files'}</Typography>
                <Box>
                  <Button size="small" onClick={()=>fileInputRef.current?.click()} startIcon={<AddIcon/>}>{t('files.upload') || 'Upload'}</Button>
                </Box>
              </Box>
              <Box
                sx={{
                  mt: 1,
                  p: 2.5,
                  border: '2px dashed',
                  borderColor: isDraggingFiles ? 'primary.main' : 'divider',
                  borderRadius: 2,
                  bgcolor: isDraggingFiles ? 'action.hover' : 'transparent',
                  transition: 'all 0.2s ease',
                  textAlign: 'center',
                  cursor: 'pointer'
                }}
                onDragOver={(e)=>{ e.preventDefault(); setIsDraggingFiles(true); }}
                onDragLeave={(e)=>{ e.preventDefault(); setIsDraggingFiles(false); }}
                onDrop={(e)=>{ void handleDropFiles(e); }}
                onClick={()=>fileInputRef.current?.click()}
              >
                <CloudUploadIcon color={isDraggingFiles ? 'primary' : 'disabled'} sx={{ fontSize: 28 }} />
                <Typography variant="body2" sx={{ mt: 1 }}>
                  {t('files.dragOrClick') || 'Drag files here or click to choose'}
                </Typography>
                <input
                  ref={fileInputRef}
                  key={fileInputKey}
                  type="file"
                  multiple
                  style={{ display: 'none' }}
                  onChange={(e)=>{ void uploadFiles(e.target.files); }}
                />
              </Box>
              <List>
                {data.Files.map((f:any)=> (
                  <ListItem key={f.Id} secondaryAction={<Box sx={{ display:'flex', gap:1 }}>
                    {canManageCase && <Button size="small" onClick={()=>{ setEditingFile({ id: f.FileId, code: f.FileCode ?? '' }); setEditFileOpen(true); }}>{t('app.edit') || 'Edit'}</Button>}
                    <IconButton href={`/api/files/${f.FileId}/download`} target="_blank"><DownloadIcon/></IconButton>
                    {canManageCase && <IconButton color="error" onClick={()=>removeFile(f.FileId)}><DeleteIcon/></IconButton>}
                  </Box>}>
                    <ListItemText primary={`${f.FileCode || f.FileId}`} secondary={f.FilePath} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{t('clientPortal.myDocuments', { defaultValue: 'My Documents' })}</Typography>
              <List>
                {(data.Documents || []).map((item:any) => (
                  <ListItem key={item.Id}>
                    <ListItemText primary={`${item.DocType}${item.DocNum ? ` #${item.DocNum}` : ''}`} secondary={item.DocDetails || item.Notes || ''} />
                  </ListItem>
                ))}
                {(!data.Documents || data.Documents.length === 0) && <ListItem><ListItemText primary={t('clientPortal.noData', { defaultValue: 'No data available' })} /></ListItem>}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{t('clientPortal.myPayments', { defaultValue: 'My Payments' })}</Typography>
              <List>
                {(data.BillingPayments || []).map((item:any) => (
                  <ListItem key={item.Id}>
                    <ListItemText primary={`${item.Amount} - ${item.DateOfOperation}`} secondary={item.Notes || ''} />
                  </ListItem>
                ))}
                {(!data.BillingPayments || data.BillingPayments.length === 0) && <ListItem><ListItemText primary={t('clientPortal.noData', { defaultValue: 'No data available' })} /></ListItem>}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center', mb: 1 }}>
                <Typography variant="h6">{t('cases.requestedDocuments.title', { defaultValue: 'Requested Documents' })}</Typography>
                {canManageCase && <Button size="small" startIcon={<AddIcon/>} onClick={async ()=>{ if(customersList.length===0){ try{ const r = await api.get('/Customers'); setCustomersList(r.data || []); }catch{} } setRequestDocumentOpen(true); }}>{t('cases.requestedDocuments.request', { defaultValue: 'Request document' })}</Button>}
              </Box>
              <List>
                {(data.RequestedDocuments || []).map((item:any) => (
                  <ListItem key={item.Id} alignItems="flex-start">
                    <ListItemText
                      primary={`${item.Title} (${item.Status})`}
                      secondary={
                        <Box sx={{ display:'grid', gap: 1, mt: 0.5 }}>
                          <Typography variant="body2">{item.Description || '-'}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {t('cases.requestedDocuments.dueDate', { defaultValue: 'Due date' })}: {item.DueDate || '-'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {t('cases.requestedDocuments.customer', { defaultValue: 'Customer' })}: {item.CustomerName || item.CustomerId}
                          </Typography>
                          {item.UploadedFileId ? (
                            <Button size="small" component="a" href={`/api/files/${item.UploadedFileId}/download`} target="_blank">{t('clientPortal.download', { defaultValue: 'Download' })}</Button>
                          ) : null}
                          {isCustomerOnly && (item.Status === 'Pending' || item.Status === 'Rejected') && (
                            <Box sx={{ display:'flex', gap: 1, alignItems:'center', flexWrap:'wrap' }}>
                              <TextField
                                size="small"
                                label={t('cases.requestedDocuments.customerNote', { defaultValue: 'Note to office' })}
                                value={documentReviewNotes[item.Id] || ''}
                                onChange={(e)=>setDocumentReviewNotes((current)=>({ ...current, [item.Id]: e.target.value }))}
                              />
                              <Button size="small" variant="contained" onClick={() => { setRequestedDocumentUploadTarget({ requestId: item.Id, caseCode: item.CaseCode }); requestedDocumentInputRef.current?.click(); }}>
                                {t('cases.requestedDocuments.upload', { defaultValue: 'Upload file' })}
                              </Button>
                            </Box>
                          )}
                          {canManageCase && (
                            <Box sx={{ display:'grid', gap:1 }}>
                              <TextField
                                size="small"
                                label={t('cases.requestedDocuments.reviewNotes', { defaultValue: 'Review notes' })}
                                value={documentReviewNotes[item.Id] || ''}
                                onChange={(e)=>setDocumentReviewNotes((current)=>({ ...current, [item.Id]: e.target.value }))}
                              />
                              <Box sx={{ display:'flex', gap:1 }}>
                                <Button size="small" variant="contained" onClick={()=>void reviewRequestedDocument(item.Id, 'Approved')}>{t('cases.requestedDocuments.approve', { defaultValue: 'Approve' })}</Button>
                                <Button size="small" color="error" variant="outlined" onClick={()=>void reviewRequestedDocument(item.Id, 'Rejected')}>{t('cases.requestedDocuments.reject', { defaultValue: 'Reject' })}</Button>
                              </Box>
                            </Box>
                          )}
                        </Box>
                      }
                    />
                  </ListItem>
                ))}
                {(!data.RequestedDocuments || data.RequestedDocuments.length === 0) && <ListItem><ListItemText primary={t('cases.requestedDocuments.empty', { defaultValue: 'No requested documents for this case yet.' })} /></ListItem>}
              </List>
              <input ref={requestedDocumentInputRef} type="file" hidden onChange={(e)=>void handleRequestedDocumentUpload(e)} />
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{t('cases.paymentProofs.title', { defaultValue: 'Payment Proofs' })}</Typography>
              <List>
                {(data.PaymentProofs || []).map((item:any) => (
                  <ListItem key={item.Id} alignItems="flex-start">
                    <ListItemText
                      primary={`${item.Amount} - ${item.Status}`}
                      secondary={
                        <Box sx={{ display:'grid', gap:1, mt:0.5 }}>
                          <Typography variant="caption" color="text.secondary">
                            {t('clientPortal.paymentDate', { defaultValue: 'Payment date' })}: {item.PaymentDate}
                          </Typography>
                          <Typography variant="body2">{item.Notes || '-'}</Typography>
                          {item.ProofFileId ? (
                            <Button size="small" component="a" href={`/api/files/${item.ProofFileId}/download`} target="_blank">{t('clientPortal.download', { defaultValue: 'Download' })}</Button>
                          ) : null}
                          {item.ReviewNotes ? <Typography variant="caption" color="text.secondary">{item.ReviewNotes}</Typography> : null}
                          {canManageCase && (
                            <Box sx={{ display:'grid', gap:1 }}>
                              <TextField
                                size="small"
                                label={t('cases.paymentProofs.reviewNotes', { defaultValue: 'Review notes' })}
                                value={paymentProofReviewNotes[item.Id] || ''}
                                onChange={(e)=>setPaymentProofReviewNotes((current)=>({ ...current, [item.Id]: e.target.value }))}
                              />
                              <Box sx={{ display:'flex', gap:1 }}>
                                <Button size="small" variant="contained" onClick={()=>void reviewPaymentProof(item.Id, 'Approved')}>{t('cases.paymentProofs.approve', { defaultValue: 'Approve' })}</Button>
                                <Button size="small" color="error" variant="outlined" onClick={()=>void reviewPaymentProof(item.Id, 'Rejected')}>{t('cases.paymentProofs.reject', { defaultValue: 'Reject' })}</Button>
                              </Box>
                            </Box>
                          )}
                        </Box>
                      }
                    />
                  </ListItem>
                ))}
                {(!data.PaymentProofs || data.PaymentProofs.length === 0) && <ListItem><ListItemText primary={t('cases.paymentProofs.empty', { defaultValue: 'No payment proofs for this case yet.' })} /></ListItem>}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{t('cases.conversation.title', { defaultValue: 'Case Conversation' })}</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                {t('cases.conversation.subtitle', { defaultValue: 'Use this thread to communicate with the office about this case.' })}
              </Typography>
              <List sx={{ maxHeight: 320, overflowY: 'auto', mb: 1 }}>
                {conversation.map((item:any) => (
                  <ListItem key={item.id} sx={{ justifyContent: item.isMine ? 'flex-end' : 'flex-start' }}>
                    <Box sx={{ maxWidth: '85%', px: 1.5, py: 1, borderRadius: 2, bgcolor: item.isMine ? 'primary.main' : 'action.hover', color: item.isMine ? 'primary.contrastText' : 'text.primary' }}>
                      <Typography variant="caption" sx={{ display:'block', opacity: item.isMine ? 0.9 : 0.75 }}>
                        {item.senderName} • {item.senderRole} • {new Date(item.createdAtUtc).toLocaleString()}
                      </Typography>
                      <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>{item.message}</Typography>
                      {item.attachmentFileId ? (
                        <Button size="small" component="a" href={`/api/files/${item.attachmentFileId}/download`} target="_blank" sx={{ mt: 0.5 }}>
                          {item.attachmentFileCode || t('cases.conversation.attachment', { defaultValue: 'Attachment' })}
                        </Button>
                      ) : null}
                      {item.isMine ? (
                        <Typography variant="caption" sx={{ display:'block', mt: 0.5, opacity: 0.8 }}>
                          {item.isReadByOtherParty
                            ? t('cases.conversation.read', { defaultValue: 'Seen' })
                            : t('cases.conversation.unread', { defaultValue: 'Waiting for review' })}
                        </Typography>
                      ) : null}
                    </Box>
                  </ListItem>
                ))}
                {conversation.length === 0 && <ListItem><ListItemText primary={t('cases.conversation.empty', { defaultValue: 'No conversation messages yet.' })} /></ListItem>}
              </List>
              <TextField
                fullWidth
                multiline
                minRows={3}
                label={t('cases.conversation.message', { defaultValue: 'Message' })}
                value={conversationMessage}
                onChange={(e)=>setConversationMessage(e.target.value)}
              />
              <Button variant="outlined" component="label" sx={{ mt: 1.5 }}>
                {conversationAttachment
                  ? `${t('cases.conversation.attachmentSelected', { defaultValue: 'Attachment selected' })}: ${conversationAttachment.name}`
                  : t('cases.conversation.attach', { defaultValue: 'Attach file' })}
                <input hidden type="file" onChange={(e)=>setConversationAttachment(e.target.files?.[0] ?? null)} />
              </Button>
              <Box sx={{ display:'flex', justifyContent:'flex-end', mt: 1.5 }}>
                <Button variant="contained" onClick={sendConversationMessage} disabled={sendingConversation || (!conversationMessage.trim() && !conversationAttachment)}>
                  {t('cases.conversation.send', { defaultValue: 'Send message' })}
                </Button>
              </Box>
            </CardContent></Card>

            {/* Status history */}
            <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{t('cases.status')} {t('history') || 'History'}</Typography>
              <List>
                {(data.StatusHistory || []).map((h:any) => (
                  <ListItem key={h.Id}><ListItemText primary={`${h.ChangedAt ? new Date(h.ChangedAt).toLocaleString() : ''} — ${t(`cases.statuses.${['new','inprogress','awaitinghearing','closed','won','lost'][h.OldStatus]}`) || h.OldStatus} → ${t(`cases.statuses.${['new','inprogress','awaitinghearing','closed','won','lost'][h.NewStatus]}`) || h.NewStatus}`} secondary={h.ChangedBy || ''} /></ListItem>
                ))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('cases.courts') || 'Courts'}</Typography>
                {canManageCase && <Button size="small" onClick={async ()=>{ if(courtsList.length===0){ const r = await api.get('/Courts'); setCourtsList(r.data || []);} setSelectedCourtToSet(data.Courts?.[0]?.CourtId || data.Courts?.[0]?.Id || ''); setEditing(true); }}>{t('app.edit') || 'Edit'}</Button>}
              </Box>
              <List>
                {data.Courts.map((c:any)=> (<ListItem key={c.Id}><ListItemText primary={c.CourtName} /></ListItem>))}
              </List>
            </CardContent></Card>

            <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('cases.employees') || 'Employees'}</Typography>
                {canManageCase && <Button size="small" onClick={openAssignEmployee} startIcon={<AddIcon/>}>{t('employees.add') || 'Assign'}</Button>}
              </Box>
              <List>
                {data.Employees.map((e:any)=> (<ListItem key={e.id}><ListItemText primary={e.Full_Name || e.fullName} />{canManageCase && <Button size="small" color="error" onClick={async ()=>{ try{ await api.delete(`/cases/${code}/employees/${e.id}`); await load(); setSnackbar({ open:true, message: 'Employee removed', severity:'success' }); }catch(err:any){ setSnackbar({ open:true, message: 'Failed to remove', severity:'error' }); } }}>Remove</Button>}</ListItem>))}
              </List>
            </CardContent></Card>

          </Box>
        </Box>
      ) : (
        <Box sx={{ minHeight: 240, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Typography color="text.secondary">{loading ? 'Loading...' : 'No data found'}</Typography>
        </Box>
      )}

      {/* Add Customer Dialog */}
      <Dialog open={addCustomerOpen} onClose={()=>setAddCustomerOpen(false)}>
        <DialogTitle>{t('customers.add') || 'Add Customer to Case'}</DialogTitle>
        <DialogContent>
          <SearchableSelect<number>
            label={t('customers.customer')}
            value={typeof selectedCustomerToAdd === 'number' ? selectedCustomerToAdd : null}
            onChange={(value)=>setSelectedCustomerToAdd(value ?? '')}
            options={customersList.map((c) => ({
              value: c.id,
              label: c.identity?.fullName || c.user?.fullName || '-',
            }))}
            sx={{ mt:1 }}
          />
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
          <SearchableSelect<number>
            label={t('employees.employee') || 'Employee'}
            value={typeof selectedEmployeeToAdd === 'number' ? selectedEmployeeToAdd : null}
            onChange={(value)=>setSelectedEmployeeToAdd(value ?? '')}
            onOpen={async ()=>{ if(employeesList.length===0){ const r = await api.get('/Employees'); setEmployeesList(r.data || []);} }}
            options={employeesList.map((emp)=> ({
              value: emp.id,
              label: emp.user?.fullName || emp.user?.userName,
            }))}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setAssignEmployeeOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={assignEmployee}>{t('app.create')}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={requestDocumentOpen} onClose={()=>setRequestDocumentOpen(false)}>
        <DialogTitle>{t('cases.requestedDocuments.request', { defaultValue: 'Request document' })}</DialogTitle>
        <DialogContent>
          <Box sx={{ display:'grid', gap:1, mt: 1 }}>
            <SearchableSelect<number>
              label={t('cases.requestedDocuments.customer', { defaultValue: 'Customer' })}
              value={newRequestedDocument.customerId ? Number(newRequestedDocument.customerId) : null}
              onChange={(value)=>setNewRequestedDocument((current)=>({ ...current, customerId: value ? String(value) : '' }))}
              options={(data?.Customers || []).map((customer:any) => ({
                value: customer.CustomerId,
                label: customer.CustomerName,
              }))}
            />
            <TextField
              label={t('cases.requestedDocuments.documentTitle', { defaultValue: 'Document title' })}
              value={newRequestedDocument.title}
              onChange={(e)=>setNewRequestedDocument((current)=>({ ...current, title: e.target.value }))}
            />
            <TextField
              label={t('cases.requestedDocuments.description', { defaultValue: 'Description' })}
              value={newRequestedDocument.description}
              onChange={(e)=>setNewRequestedDocument((current)=>({ ...current, description: e.target.value }))}
              multiline
              minRows={3}
            />
            <TextField
              type="date"
              label={t('cases.requestedDocuments.dueDate', { defaultValue: 'Due date' })}
              value={newRequestedDocument.dueDate}
              onChange={(e)=>setNewRequestedDocument((current)=>({ ...current, dueDate: e.target.value }))}
              InputLabelProps={{ shrink: true }}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={()=>setRequestDocumentOpen(false)}>{t('app.cancel')}</Button>
          <Button variant="contained" onClick={()=>void createRequestedDocument()}>{t('app.create')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={()=>setSnackbar({...snackbar, open:false})}>
        <Alert severity={snackbar.severity} onClose={()=>setSnackbar({...snackbar, open:false})}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
