"use client"
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box, Typography, Button, Paper, IconButton, Skeleton, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Snackbar,
  Tooltip, TextField, Autocomplete, Tabs, Tab, List, ListItem,
  ListItemText, ListItemSecondaryAction, Divider, useTheme, Card, CardContent,
} from '@mui/material';
import {
  AccountTree as TreeIcon, Add as AddIcon, Delete as DeleteIcon,
  Refresh as RefreshIcon, Person as PersonIcon, Gavel as GavelIcon,
  AccountBalance as CourtIcon, Work as EmployeeIcon, CalendarMonth as SitingIcon,
  Folder as FileIcon, Search as SearchIcon, Link as LinkIcon,
} from '@mui/icons-material';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';

type CaseOption = { id: number; code: number; invitionsStatment: string };
type RelationItem = { id?: number; [key: string]: any };

interface TabPanelProps { children?: React.ReactNode; index: number; value: number }
function TabPanel({ children, value, index }: TabPanelProps) {
  return value === index ? <Box sx={{ py: 3 }}>{children}</Box> : null;
}

export default function CaseRelationsPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const { isAuthenticated } = useAuth();

  const [cases, setCases] = useState<CaseOption[]>([]);
  const [selectedCase, setSelectedCase] = useState<CaseOption | null>(null);
  const [loading, setLoading] = useState(false);
  const [loadingRelations, setLoadingRelations] = useState(false);
  const [tab, setTab] = useState(0);

  // Relation data
  const [customers, setCustomers] = useState<RelationItem[]>([]);
  const [contenders, setContenders] = useState<RelationItem[]>([]);
  const [courts, setCourts] = useState<RelationItem[]>([]);
  const [employees, setEmployees] = useState<RelationItem[]>([]);
  const [sitings, setSitings] = useState<RelationItem[]>([]);
  const [files, setFiles] = useState<RelationItem[]>([]);

  // Available items for linking
  const [allCustomers, setAllCustomers] = useState<RelationItem[]>([]);
  const [allContenders, setAllContenders] = useState<RelationItem[]>([]);
  const [allCourts, setAllCourts] = useState<RelationItem[]>([]);
  const [allEmployees, setAllEmployees] = useState<RelationItem[]>([]);
  const [allSitings, setAllSitings] = useState<RelationItem[]>([]);
  const [allFiles, setAllFiles] = useState<RelationItem[]>([]);

  // Dialog
  const [linkDialog, setLinkDialog] = useState(false);
  const [linkType, setLinkType] = useState('');
  const [linkItemId, setLinkItemId] = useState<number | null>(null);

  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

  async function loadCases() {
    setLoading(true);
    try {
      const res = await api.get('/Cases');
      setCases(res.data || []);
    } catch {
      setSnackbar({ open: true, message: t('caseRelations.failedLoad'), severity: 'error' });
    } finally {
      setLoading(false);
    }
  }

  async function loadAllEntities() {
    try {
      const [cust, cont, crt, emp, sit, fil] = await Promise.all([
        api.get('/Customers'), api.get('/Contenders'), api.get('/Courts'),
        api.get('/Employees'), api.get('/Sitings'), api.get('/Files'),
      ]);
      setAllCustomers(cust.data || []);
      setAllContenders(cont.data || []);
      setAllCourts(crt.data || []);
      setAllEmployees(emp.data || []);
      setAllSitings(sit.data || []);
      setAllFiles(fil.data || []);
    } catch { /* silently fail - items won't be available for linking */ }
  }

  async function loadRelations(caseCode: number) {
    setLoadingRelations(true);
    try {
      const res = await api.get(`/cases/${caseCode}/full`);
      const data = res.data;
      setCustomers(data.customers || []);
      setContenders(data.contenders || []);
      setCourts(data.courts || []);
      setEmployees(data.employees || []);
      setSitings(data.sitings || []);
      setFiles(data.files || []);
    } catch {
      setSnackbar({ open: true, message: t('caseRelations.failedLoadRelations'), severity: 'error' });
    } finally {
      setLoadingRelations(false);
    }
  }

  useEffect(() => { loadCases(); loadAllEntities(); }, []);

  useEffect(() => {
    if (selectedCase) loadRelations(selectedCase.code);
    else { setCustomers([]); setContenders([]); setCourts([]); setEmployees([]); setSitings([]); setFiles([]); }
  }, [selectedCase]);

  async function linkItem() {
    if (!selectedCase || !linkItemId) return;
    try {
      await api.post(`/cases/${selectedCase.code}/${linkType}/${linkItemId}`);
      setSnackbar({ open: true, message: t('caseRelations.linked'), severity: 'success' });
      setLinkDialog(false);
      setLinkItemId(null);
      loadRelations(selectedCase.code);
    } catch (err: any) {
      const msg = err?.response?.data?.message || t('caseRelations.failedLink');
      setSnackbar({ open: true, message: msg, severity: 'error' });
    }
  }

  async function unlinkItem(type: string, itemId: number) {
    if (!selectedCase) return;
    if (!confirm(t('caseRelations.confirmUnlink'))) return;
    try {
      await api.delete(`/cases/${selectedCase.code}/${type}/${itemId}`);
      setSnackbar({ open: true, message: t('caseRelations.unlinked'), severity: 'success' });
      loadRelations(selectedCase.code);
    } catch (err: any) {
      const msg = err?.response?.data?.message || t('caseRelations.failedUnlink');
      setSnackbar({ open: true, message: msg, severity: 'error' });
    }
  }

  function openLinkDialog(type: string) {
    setLinkType(type);
    setLinkItemId(null);
    setLinkDialog(true);
  }

  function getLinkOptions(): { id: number; label: string }[] {
    const linked = linkType === 'customers' ? customers.map(c => c.id)
      : linkType === 'contenders' ? contenders.map(c => c.id)
      : linkType === 'courts' ? courts.map(c => c.id)
      : linkType === 'employees' ? employees.map(e => e.id)
      : linkType === 'sitings' ? sitings.map(s => s.id)
      : files.map(f => f.id);

    if (linkType === 'customers') return allCustomers.filter(c => !linked.includes(c.id)).map(c => ({ id: c.id, label: c.fullName || c.full_Name || `#${c.id}` }));
    if (linkType === 'contenders') return allContenders.filter(c => !linked.includes(c.id)).map(c => ({ id: c.id, label: c.fullName || c.full_Name || `#${c.id}` }));
    if (linkType === 'courts') return allCourts.filter(c => !linked.includes(c.id)).map(c => ({ id: c.id, label: c.name || `#${c.id}` }));
    if (linkType === 'employees') return allEmployees.filter(e => !linked.includes(e.id)).map(e => ({ id: e.id, label: e.fullName || e.full_Name || `#${e.id}` }));
    if (linkType === 'sitings') return allSitings.filter(s => !linked.includes(s.id)).map(s => ({ id: s.id, label: `${s.sitingDate || s.siting_Date || ''} - ${s.judgeName || s.judge_Name || ''}`.trim() || `#${s.id}` }));
    if (linkType === 'files') return allFiles.filter(f => !linked.includes(f.id)).map(f => ({ id: f.id, label: f.path || f.code || `#${f.id}` }));
    return [];
  }

  const tabDefs = [
    { key: 'customers', icon: <PersonIcon />, items: customers, nameField: 'full_Name', idField: 'id' },
    { key: 'contenders', icon: <GavelIcon />, items: contenders, nameField: 'full_Name', idField: 'id' },
    { key: 'courts', icon: <CourtIcon />, items: courts, nameField: 'name', idField: 'id' },
    { key: 'employees', icon: <EmployeeIcon />, items: employees, nameField: 'full_Name', idField: 'id' },
    { key: 'sitings', icon: <SitingIcon />, items: sitings, nameField: 'siting_Date', idField: 'id' },
    { key: 'files', icon: <FileIcon />, items: files, nameField: 'path', idField: 'id' },
  ];

  function getItemName(item: RelationItem, nameField: string): string {
    // Try common naming patterns from the API
    return item.customerName || item.contenderName || item.courtName || item.employeeName
      || item.judgeName || item.filePath || item.fileCode
      || item[nameField] || item.name || item.full_Name || `#${item.id || item[Object.keys(item).find(k => k.toLowerCase().includes('id')) || 'id']}`;
  }

  function getItemId(item: RelationItem, key: string): number {
    // Extract the FK id for unlinking
    if (key === 'customers') return item.customerId || item.id;
    if (key === 'contenders') return item.contenderId || item.id;
    if (key === 'courts') return item.courtId || item.id;
    if (key === 'employees') return item.employeeId || item.id;
    if (key === 'sitings') return item.sitingId || item.id;
    if (key === 'files') return item.fileId || item.id;
    return item.id;
  }

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box sx={{ bgcolor: 'primary.main', color: 'white', p: 1.5, borderRadius: 3, display: 'flex', boxShadow: '0 4px 12px rgba(79, 70, 229, 0.3)' }}>
            <TreeIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>{t('caseRelations.management')}</Typography>
            <Typography variant="body2" color="text.secondary">{t('caseRelations.description')}</Typography>
          </Box>
        </Box>
        <Tooltip title={t('common.refresh')}>
          <IconButton onClick={() => { loadCases(); if (selectedCase) loadRelations(selectedCase.code); }} sx={{ bgcolor: 'background.paper', border: '1px solid', borderColor: 'divider', '&:hover': { bgcolor: 'grey.50' } }}>
            <RefreshIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      </Box>

      {/* Case Selector */}
      <Paper elevation={0} sx={{ borderRadius: 4, border: '1px solid', borderColor: 'divider', p: 3, mb: 3, bgcolor: 'background.paper', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 2 }}>{t('caseRelations.selectCase')}</Typography>
        <Autocomplete
          options={cases}
          getOptionLabel={(opt) => `#${opt.code} - ${opt.invitionsStatment || ''}`}
          value={selectedCase}
          onChange={(_, val) => setSelectedCase(val)}
          loading={loading}
          renderInput={(params) => (
            <TextField {...params} placeholder={t('caseRelations.searchCase')} variant="outlined" InputProps={{ ...params.InputProps, startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} /> }} />
          )}
          sx={{ maxWidth: 600 }}
        />
      </Paper>

      {/* Relations */}
      {selectedCase && (
        <Paper elevation={0} sx={{ borderRadius: 4, border: '1px solid', borderColor: 'divider', overflow: 'hidden', bgcolor: 'background.paper', boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' }}>
          {/* Case info card */}
          <Box sx={{ p: 3, borderBottom: '1px solid', borderColor: 'divider', bgcolor: 'grey.50' }}>
            <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap', flexDirection: isRTL ? 'row-reverse' : 'row' }}>
              <Chip label={`${t('cases.code')}: ${selectedCase.code}`} color="primary" variant="outlined" sx={{ fontWeight: 700 }} />
              <Typography variant="body1" sx={{ fontWeight: 600 }}>{selectedCase.invitionsStatment}</Typography>
            </Box>
          </Box>

          <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
            <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="scrollable" scrollButtons="auto"
              sx={{ '& .MuiTab-root': { minHeight: 56, textTransform: 'none', fontWeight: 600, gap: 1 } }}>
              {tabDefs.map((td, i) => (
                <Tab key={td.key} icon={td.icon} iconPosition={isRTL ? 'end' : 'start'}
                  label={
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {t(`caseRelations.${td.key}`)}
                      <Chip label={td.items.length} size="small" variant="outlined" sx={{ height: 20, minWidth: 20, fontSize: 11, fontWeight: 700 }} />
                    </Box>
                  }
                />
              ))}
            </Tabs>
          </Box>

          {loadingRelations ? (
            <Box sx={{ p: 4 }}>
              {[1, 2, 3].map(i => <Skeleton key={i} variant="rectangular" height={48} sx={{ mb: 1, borderRadius: 2 }} />)}
            </Box>
          ) : (
            tabDefs.map((td, i) => (
              <TabPanel key={td.key} value={tab} index={i}>
                <Box sx={{ px: 3 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                    <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                      {t(`caseRelations.linked${td.key.charAt(0).toUpperCase() + td.key.slice(1)}`)} ({td.items.length})
                    </Typography>
                    <Button variant="outlined" size="small" startIcon={!isRTL ? <LinkIcon /> : undefined} endIcon={isRTL ? <LinkIcon /> : undefined}
                      onClick={() => openLinkDialog(td.key)} sx={{ borderRadius: 2, fontWeight: 600 }}>
                      {t('caseRelations.linkNew')}
                    </Button>
                  </Box>

                  {td.items.length === 0 ? (
                    <Card variant="outlined" sx={{ textAlign: 'center', py: 6, borderStyle: 'dashed', borderRadius: 3 }}>
                      <CardContent>
                        <Box sx={{ opacity: 0.4, mb: 1 }}>{td.icon}</Box>
                        <Typography color="text.secondary">{t('caseRelations.noLinked')}</Typography>
                      </CardContent>
                    </Card>
                  ) : (
                    <List sx={{ bgcolor: 'background.paper', borderRadius: 3, border: '1px solid', borderColor: 'divider', overflow: 'hidden' }}>
                      {td.items.map((item, idx) => (
                        <React.Fragment key={idx}>
                          {idx > 0 && <Divider />}
                          <ListItem sx={{ py: 1.5, '&:hover': { bgcolor: 'grey.50' } }}>
                            <ListItemText
                              primary={<Typography sx={{ fontWeight: 600 }}>{getItemName(item, td.nameField)}</Typography>}
                              sx={{ textAlign: isRTL ? 'right' : 'left' }}
                            />
                            <ListItemSecondaryAction sx={{ [isRTL ? 'left' : 'right']: 16, [isRTL ? 'right' : 'left']: 'auto' }}>
                              <Tooltip title={t('caseRelations.unlink')}>
                                <IconButton edge="end" color="error" onClick={() => unlinkItem(td.key, getItemId(item, td.key))}
                                  sx={{ '&:hover': { bgcolor: 'error.light', color: 'white' }, transition: 'all 0.2s ease' }}>
                                  <DeleteIcon fontSize="small" />
                                </IconButton>
                              </Tooltip>
                            </ListItemSecondaryAction>
                          </ListItem>
                        </React.Fragment>
                      ))}
                    </List>
                  )}
                </Box>
              </TabPanel>
            ))
          )}
        </Paper>
      )}

      {!selectedCase && !loading && (
        <Paper elevation={0} sx={{ borderRadius: 4, border: '1px dashed', borderColor: 'divider', p: 8, textAlign: 'center', bgcolor: 'background.paper' }}>
          <TreeIcon sx={{ fontSize: 56, color: 'primary.main', opacity: 0.3, mb: 2 }} />
          <Typography variant="h6" color="text.secondary" gutterBottom>{t('caseRelations.selectCasePrompt')}</Typography>
          <Typography variant="body2" color="text.secondary">{t('caseRelations.selectCaseHint')}</Typography>
        </Paper>
      )}

      {/* Link Dialog */}
      <Dialog open={linkDialog} onClose={() => setLinkDialog(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: 3, p: 1 } }}>
        <DialogTitle sx={{ textAlign: isRTL ? 'right' : 'left', fontWeight: 700, px: 3, pt: 3 }}>
          {t('caseRelations.linkNew')} - {t(`caseRelations.${linkType}`)}
        </DialogTitle>
        <DialogContent sx={{ px: 3 }}>
          <Autocomplete
            options={getLinkOptions()}
            getOptionLabel={(opt) => opt.label}
            onChange={(_, val) => setLinkItemId(val?.id ?? null)}
            renderInput={(params) => (
              <TextField {...params} label={t('caseRelations.selectItem')} variant="outlined" sx={{ mt: 2 }} />
            )}
          />
        </DialogContent>
        <DialogActions sx={{ p: 3, gap: 1.5, justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
          <Button onClick={() => setLinkDialog(false)} sx={{ borderRadius: 2, px: 3, color: 'text.secondary' }}>{t('common.cancel')}</Button>
          <Button variant="contained" onClick={linkItem} disabled={!linkItemId}
            sx={{ borderRadius: 2, px: 4, fontWeight: 700 }}>{t('caseRelations.link')}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} variant="filled" sx={{ borderRadius: 2, fontWeight: 600 }}>{snackbar.message}</Alert>
      </Snackbar>
    </Box>
  );
}
