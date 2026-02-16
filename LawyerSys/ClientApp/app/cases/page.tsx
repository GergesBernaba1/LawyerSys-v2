"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Skeleton,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Snackbar,
  Tooltip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Checkbox,
  List,
  ListItem,
  ListItemText,
  Avatar,
  useTheme,
  Pagination,
} from '@mui/material';
import Grid from '@mui/material/Grid'
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Gavel as GavelIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useRouter, useParams } from 'next/navigation';
import { useAuth } from '../../src/services/auth';

type CaseItem = {
  id: number;
  code: number;
  invitionsStatment?: string;
  invitionType?: string;
  invitionDate?: string;
  totalAmount?: number;
  notes?: string;
};

export default function CasesPageClient() {
  const { t } = useTranslation();
  const theme = useTheme();
  const params = useParams() as { locale?: string } | undefined;
  const locale = params?.locale || 'ar';
  const isRTL = theme.direction === 'rtl' || locale.startsWith('ar');
  const router = useRouter();
  const { isAuthenticated, hasAnyRole } = useAuth();

  const [items, setItems] = useState<CaseItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [code, setCode] = useState<number>(0);
  const [notes, setNotes] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // pagination
  const [page, setPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(10);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [search, setSearch] = useState<string>('');

  // New states for relations
  const [courts, setCourts] = useState<any[]>([]);
  const [customers, setCustomers] = useState<any[]>([]);
  const [contenders, setContenders] = useState<any[]>([]);
  const [selectedCourt, setSelectedCourt] = useState<number | ''>('');
  const [primaryCustomer, setPrimaryCustomer] = useState<number | ''>('');
  const [selectedCustomers, setSelectedCustomers] = useState<number[]>([]);
  const [selectedContenders, setSelectedContenders] = useState<number[]>([]);
  const [sitingDialogOpen, setSitingDialogOpen] = useState(false);
  const [contenderDialogOpen, setContenderDialogOpen] = useState(false);
  const [newSiting, setNewSiting] = useState({ date: '', time: '', judgeName: '', notes: '' });
  const [newContender, setNewContender] = useState({ fullName: '', ssn: '', birthDate: '' });
  const [pendingSitings, setPendingSitings] = useState<any[]>([]);
  const [pendingFiles, setPendingFiles] = useState<File[]>([]);

  async function load(p = page) {
    setLoading(true);
    try {
      const [r, courtsRes, customersRes, contendersRes] = await Promise.all([
        api.get(`/Cases?page=${p}&pageSize=${pageSize}${search ? `&search=${encodeURIComponent(search)}` : ''}`),
        api.get('/Courts'),
        api.get('/Customers'),
        api.get('/Contenders')
      ]);

      // support legacy array response OR new paged response
      const casesData = r.data?.items ? r.data.items : r.data;
      setItems(casesData || []);
      if (r.data?.totalCount) setTotalCount(r.data.totalCount);

      setCourts(courtsRes.data || []);
      setCustomers(customersRes.data || []);
      setContenders(contendersRes.data || []);
    } catch (err) {
      setSnackbar({ open: true, message: t('cases.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function create() {
    try {
      // 1) Create case
      const created = await api.post('/Cases', { code, notes });
      const createdCase = created.data;
      const caseCode = createdCase.code ?? createdCase.Code ?? code;

      // 2) Link court
      if (selectedCourt) {
        await api.post(`/cases/${caseCode}/courts/${selectedCourt}`);
      }

      // 3) Link customers (primary and additional)
      if (primaryCustomer) {
        await api.post(`/cases/${caseCode}/customers/${primaryCustomer}`);
        // ensure primary included in selected
        if (!selectedCustomers.includes(Number(primaryCustomer))) setSelectedCustomers(prev => [...prev, Number(primaryCustomer)]);
      }
      for (const cid of selectedCustomers) {
        try { await api.post(`/cases/${caseCode}/customers/${cid}`); } catch (e) { /* ignore duplicates */ }
      }

      // 4) Link contenders
      for (const cont of selectedContenders) {
        try { await api.post(`/cases/${caseCode}/contenders/${cont}`); } catch (e) { }
      }

      // 5) Create and link sitings
      for (const s of pendingSitings) {
        // create siting
        const sitDto = {
          SitingTime: new Date(`${s.date}T${s.time}`),
          SitingDate: s.date,
          SitingNotification: new Date(`${s.date}T${s.time}`),
          JudgeName: s.judgeName,
          Notes: s.notes
        };
        const r = await api.post('/Sitings', sitDto);
        const sitingId = r.data.id;
        await api.post(`/cases/${caseCode}/sitings/${sitingId}`);
      }

      // 6) Upload and link files
      for (const f of pendingFiles) {
        const fd = new FormData();
        fd.append('file', f);
        const uploadRes = await api.post('/Files/upload', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
        const fileId = uploadRes.data.id;
        await api.post(`/cases/${caseCode}/files/${fileId}`);
      }

      await load();
      setCode(0);
      setNotes('');
      setSelectedCourt('');
      setPrimaryCustomer('');
      setSelectedCustomers([]);
      setSelectedContenders([]);
      setPendingSitings([]);
      setPendingFiles([]);
      setOpenDialog(false);
      setSnackbar({ open: true, message: t('cases.caseCreated'), severity: 'success' });
    } catch (err: any) {
      console.error(err);
      setSnackbar({ open: true, message: err?.response?.data?.message ?? t('cases.failedCreate'), severity: 'error' });
    }
  }

  async function remove(id: number) {
    if (!confirm(t('cases.confirmDelete'))) return;
    try {
      await api.delete(`/Cases/${id}`);
      await load();
      setSnackbar({ open: true, message: t('cases.caseDeleted'), severity: 'success' });
    } catch (err) {
      setSnackbar({ open: true, message: t('cases.failedDelete'), severity: 'error' });
    }
  }

  const navigate = (path: string) => router.push(`/${locale}${path}`);

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'}>
      {/* Header */}
      <Box 
        sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 4,
          flexDirection: isRTL ? 'row-reverse' : 'row' 
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box 
            sx={{ 
              bgcolor: 'primary.main', 
              color: 'white', 
              p: 1.5, 
              borderRadius: 3, 
              display: 'flex',
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)',
            }}
          >
            <GavelIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
              {t('cases.management')}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {t('cases.totalCases')}: <strong>{totalCount || items.length}</strong>
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Tooltip title={t('cases.refresh')}>
            <IconButton 
              onClick={load} 
              disabled={loading}
              sx={{ 
                bgcolor: 'background.paper', 
                border: '1px solid', 
                borderColor: 'divider',
                '&:hover': { bgcolor: 'grey.50' }
              }}
            >
              <RefreshIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          {hasAnyRole('Admin', 'Employee') && (
            <Button
              variant="contained"
              startIcon={!isRTL ? <AddIcon /> : undefined}
              endIcon={isRTL ? <AddIcon /> : undefined}
              onClick={() => setOpenDialog(true)}
              sx={{ 
                borderRadius: 2.5, 
                px: 3,
                fontWeight: 700,
                boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
              }}
            >
              {t('cases.newCase')}
            </Button>
          )}
        </Box>
      </Box>

      {/* Table */}
      <Paper 
        elevation={0} 
        sx={{ 
          borderRadius: 4, 
          border: '1px solid', 
          borderColor: 'divider',
          overflow: 'hidden',
          bgcolor: 'background.paper',
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
        }}
      >
        <TableContainer>
          <Table sx={{ minWidth: 650 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.code')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.type')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.date')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.amount')}</TableCell>
                <TableCell sx={{ py: 2.5, textAlign: isRTL ? 'right' : 'left' }}>{t('cases.notes')}</TableCell>
                <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2.5 }}>{t('cases.actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from(new Array(5)).map((_, i) => (
                  <TableRow key={i}>
                    {[...Array(6)].map((__, j) => (
                      <TableCell key={j} sx={{ textAlign: isRTL ? 'right' : 'left' }}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 10 }}>
                    <Box sx={{ opacity: 0.5 }}>
                      <Box sx={{ mb: 2, fontSize: 48, color: 'primary.main', opacity: 0.3 }}>
                        <GavelIcon fontSize="inherit" />
                      </Box>
                      <Typography variant="h6" gutterBottom>{t('cases.noCases')}</Typography>
                      {hasAnyRole('Admin', 'Employee') && (
                        <Button variant="outlined" size="small" sx={{ mt: 2, borderRadius: 2 }} onClick={() => setOpenDialog(true)}>
                          {t('cases.createFirst')}
                        </Button>
                      )}
                    </Box>
                  </TableCell>
                </TableRow>
              ) : (
                items.map((item) => (
                  <TableRow 
                    key={item.id}
                    sx={{ 
                      '&:hover': { bgcolor: 'grey.50' },
                      transition: 'background 0.2s ease'
                    }}
                  >
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      <Chip 
                        label={item.code} 
                        size="small" 
                        color="primary" 
                        variant="outlined" 
                        sx={{ borderRadius: 1.5, fontWeight: 600 }}
                      />
                    </TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.invitionType || '-'}</TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>{item.invitionDate?.slice(0,10) || '-'}</TableCell>
                    <TableCell sx={{ py: 2, textAlign: isRTL ? 'right' : 'left' }}>
                      {item.totalAmount ? (
                        <Typography variant="body2" sx={{ fontWeight: 700, color: 'success.main' }}>
                          ${item.totalAmount.toLocaleString()}
                        </Typography>
                      ) : '-'}
                    </TableCell>
                    <TableCell sx={{ py: 2, maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', textAlign: isRTL ? 'right' : 'left' }}>
                      {item.notes || '-'}
                    </TableCell>
                    <TableCell align={isRTL ? 'left' : 'right'} sx={{ py: 2 }}>
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
                        <Button 
                          size="small" 
                          variant="text"
                          onClick={()=>navigate(`/cases/${item.code}`)}
                          sx={{ fontWeight: 600 }}
                        >
                          {t('app.details') || 'Details'}
                        </Button>
                        {hasAnyRole('Admin', 'Employee') && (
                          <Tooltip title={t('app.delete')}>
                            <IconButton 
                              color="error" 
                              onClick={() => remove(item.id)}
                              sx={{ 
                                '&:hover': { bgcolor: 'error.light', color: 'white' },
                                transition: 'all 0.2s ease'
                              }}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        )}
                      </Box>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>

        {/* Pagination */}
        <Box sx={{ p: 2, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 2 }}>
          <Pagination
            count={Math.max(1, Math.ceil((totalCount || items.length) / pageSize))}
            page={page}
            onChange={(_, v) => { setPage(v); load(v); }}
            color="primary"
            shape="rounded"
            showFirstButton
            showLastButton
          />
          <FormControl size="small" sx={{ minWidth: 90 }}>
            <InputLabel id="pagesize-label">/page</InputLabel>
            <Select
              labelId="pagesize-label"
              value={pageSize}
              label="/page"
              onChange={(e) => { const ps = Number(e.target.value); setPageSize(ps); setPage(1); load(1); }}
            >
              <MenuItem value={5}>5</MenuItem>
              <MenuItem value={10}>10</MenuItem>
              <MenuItem value={20}>20</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </Paper>

      <Dialog 
        open={openDialog} 
        onClose={() => setOpenDialog(false)} 
        maxWidth="sm" 
        fullWidth
        PaperProps={{
          sx: { borderRadius: 4, p: 1 }
        }}
      >
        <DialogTitle sx={{ fontWeight: 800, fontSize: '1.5rem', pb: 1, textAlign: isRTL ? 'right' : 'left' }}>
          {t('cases.createNew')}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField fullWidth label={t('cases.code')} type="number" value={code || ''} onChange={(e) => setCode(Number(e.target.value))} />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <FormControl fullWidth>
                <InputLabel>{t('courts.name')}</InputLabel>
                <Select value={selectedCourt} label={t('courts.name')} onChange={(e)=>setSelectedCourt(Number(e.target.value) || '')}>
                  <MenuItem value=""><em>--</em></MenuItem>
                  {courts.map(c=> (<MenuItem key={c.id} value={c.id}>{c.name}</MenuItem>))}
                </Select>
              </FormControl>
            </Grid>

            <Grid size={{ xs: 12, sm: 6 }}>
              <FormControl fullWidth>
                <InputLabel>{t('customers.customer')}</InputLabel>
                <Select value={primaryCustomer} label={t('customers.customer')} onChange={(e)=>setPrimaryCustomer(Number(e.target.value) || '')}>
                  <MenuItem value=""><em>--</em></MenuItem>
                  {customers.map(c=> (<MenuItem key={c.id} value={c.id}>{c.identity?.fullName || c.user?.fullName || c.identity?.email || ('#'+c.usersId)}</MenuItem>))}
                </Select>
              </FormControl>
            </Grid>

            <Grid size={{ xs: 12, sm: 6 }}>
              <FormControl fullWidth>
                <InputLabel>{t('customers.management')}</InputLabel>
                <Select multiple value={selectedCustomers} onChange={(e)=>{
                  const value = e.target.value as unknown as number[];
                  setSelectedCustomers(value);
                }} inputProps={{ 'aria-label': 'select multiple customers' }} renderValue={(selected)=> (selected as number[]).map(id => (customers.find(c=>c.id===id)?.identity?.fullName || customers.find(c=>c.id===id)?.user?.fullName || ('#'+id))).join(', ')}>
                  {customers.map(c => (<MenuItem key={c.id} value={c.id}><Checkbox checked={selectedCustomers.indexOf(c.id) > -1} /><ListItemText primary={c.identity?.fullName || c.user?.fullName || ('#'+c.usersId)} /></MenuItem>))}
                </Select>
              </FormControl>
            </Grid>

            <Grid size={{ xs: 12, sm: 6 }}>
              <FormControl fullWidth>
                <InputLabel>{t('contenders.title') || 'Contenders'}</InputLabel>
                <Select multiple value={selectedContenders} onChange={(e)=>{ const value = e.target.value as unknown as number[]; setSelectedContenders(value); }} renderValue={(sel)=> (sel as number[]).map(id => contenders.find(c=>c.id===id)?.fullName || ('#'+id)).join(', ')}>
                  {contenders.map(c=> (<MenuItem key={c.id} value={c.id}><Checkbox checked={selectedContenders.indexOf(c.id) > -1} /><ListItemText primary={c.fullName} /></MenuItem>))}
                </Select>
                <Box sx={{ mt:1 }}>
                  <Button size="small" onClick={()=>setContenderDialogOpen(true)}>{t('contenders.title')}: {t('app.add') || 'Add'}</Button>
                </Box>
              </FormControl>
            </Grid>

            <Grid size={{ xs: 12 }}>
              <Box>
                <Typography variant="subtitle2">{t('cases.sitings') || 'Sitings'}</Typography>
                <List dense>
                  {pendingSitings.map((s, idx)=>(
                    <ListItem key={idx} secondaryAction={<Button size="small" onClick={()=>setPendingSitings(prev=>prev.filter((_,i)=>i!==idx))}>{t('app.delete')}</Button>}>
                      <ListItemText primary={`${s.date} ${s.time} - ${s.judgeName}`} secondary={s.notes} />
                    </ListItem>
                  ))}
                </List>
                <Button size="small" onClick={()=>setSitingDialogOpen(true)}>{t('cases.createNewSiting') || 'Add Siting'}</Button>
              </Box>
            </Grid>

            <Grid size={{ xs: 12 }}>
              <Box>
                <Typography variant="subtitle2">{t('files.title') || 'Files'}</Typography>
                <input type="file" multiple onChange={(e)=>{
                  if(!e.target.files) return;
                  const list = Array.from(e.target.files);
                  setPendingFiles(prev => [...prev, ...list]);
                }} />
                <List dense>
                  {pendingFiles.map((f, idx)=> (<ListItem key={idx} secondaryAction={<Button size="small" onClick={()=>setPendingFiles(prev=>prev.filter((_,i)=>i!==idx))}>{t('app.delete')}</Button>}><ListItemText primary={f.name} /></ListItem>))}
                </List>
              </Box>
            </Grid>

            <Grid size={{ xs: 12 }}>
              <TextField fullWidth label={t('cases.notes')} multiline rows={3} value={notes} onChange={(e) => setNotes(e.target.value)} />
            </Grid>
          </Grid>
        </DialogContent>

        {/* New Contender Dialog */}
        <Dialog open={contenderDialogOpen} onClose={() => setContenderDialogOpen(false)} maxWidth="sm" fullWidth>
          <DialogTitle>{t('contenders.title')}</DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid size={{ xs: 12 }}>
                <TextField fullWidth label={t('contenders.title')} value={newContender.fullName} onChange={(e)=>setNewContender({...newContender, fullName: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('customers.ssn')} value={newContender.ssn} onChange={(e)=>setNewContender({...newContender, ssn: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('customers.dateOfBirth')} type="date" InputLabelProps={{ shrink: true }} value={newContender.birthDate} onChange={(e)=>setNewContender({...newContender, birthDate: e.target.value})} />
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={()=>setContenderDialogOpen(false)}>{t('app.cancel')}</Button>
            <Button variant="contained" onClick={async ()=>{
              try{
                const payload = { FullName: newContender.fullName, SSN: newContender.ssn, BirthDate: newContender.birthDate };
                const r = await api.post('/Contenders', payload);
                setSelectedContenders(prev => [...prev, r.data.id]);
                setContenders(prev => [...prev, r.data]);
                setContenderDialogOpen(false);
                setNewContender({ fullName: '', ssn: '', birthDate: '' });
                setSnackbar({ open: true, message: t('contenders.title') + ' created', severity: 'success' });
              }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? 'Failed to create contender', severity: 'error' }); }
            }}>{t('app.create')}</Button>
          </DialogActions>
        </Dialog>

        {/* New Siting Dialog (local add) */}
        <Dialog open={sitingDialogOpen} onClose={() => setSitingDialogOpen(false)} maxWidth="sm" fullWidth>
          <DialogTitle>{t('cases.createNewSiting') || 'Add Siting'}</DialogTitle>
          <DialogContent>
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('cases.date') }
                  type="date" InputLabelProps={{ shrink: true }} value={newSiting.date} onChange={(e)=>setNewSiting({...newSiting, date: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth label={t('cases.time') || 'Time'} type="time" value={newSiting.time} onChange={(e)=>setNewSiting({...newSiting, time: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12 }}>
                <TextField fullWidth label={t('cases.judge') || 'Judge'} value={newSiting.judgeName} onChange={(e)=>setNewSiting({...newSiting, judgeName: e.target.value})} />
              </Grid>
              <Grid size={{ xs: 12 }}>
                <TextField fullWidth label={t('cases.notes')} value={newSiting.notes} onChange={(e)=>setNewSiting({...newSiting, notes: e.target.value})} />
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={()=>setSitingDialogOpen(false)}>{t('app.cancel')}</Button>
            <Button variant="contained" onClick={()=>{
              setPendingSitings(prev => [...prev, newSiting]);
              setSitingDialogOpen(false);
              setNewSiting({ date: '', time: '', judgeName: '', notes: '' });
            }}>{t('app.create')}</Button>
          </DialogActions>
        </Dialog>

        <DialogActions sx={{ p: 3, pt: 1, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Button onClick={() => setOpenDialog(false)} sx={{ fontWeight: 600 }}>{t('app.cancel')}</Button>
          <Button 
            variant="contained" 
            onClick={create} 
            disabled={!code}
            sx={{ 
              borderRadius: 2.5, 
              px: 4,
              fontWeight: 700,
              boxShadow: '0 4px 12px rgba(79, 70, 229, 0.25)',
            }}
          >
            {t('app.create')}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={6000} 
        onClose={() => setSnackbar({ ...snackbar, open: false })} 
        anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity} 
          variant="filled"
          sx={{ width: '100%', borderRadius: 3, boxShadow: '0 8px 16px rgba(0,0,0,0.1)' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
