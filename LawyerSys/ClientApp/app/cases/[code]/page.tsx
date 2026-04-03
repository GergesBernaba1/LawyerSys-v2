"use client"
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
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
  Tabs,
  Tab,
} from '@mui/material';
import { ArrowBack, Delete as DeleteIcon, Download as DownloadIcon, Add as AddIcon, CloudUpload as CloudUploadIcon } from '@mui/icons-material';
import api from '../../../src/services/api';
import { useAuth } from '../../../src/services/auth';
import { useCurrency } from '../../../src/hooks/useCurrency';
import SearchableSelect from '../../../src/components/SearchableSelect';

const CASE_TYPE_VALUES = [
  'Civil',
  'Criminal',
  'Labor',
  'Commercial',
  'Family',
  'Administrative',
  'PersonalStatus',
  'Enforcement',
  'Appeal',
  'Other',
] as const;

const MIN_STATEMENT_LENGTH = 30;
const MAX_CASE_DATE_FUTURE_DAYS = 365;
const MAX_TOTAL_AMOUNT = 1_000_000_000;

function pickValue<T = any>(source: any, keys: string[], fallback?: T): T | undefined {
  for (const key of keys) {
    const value = source?.[key];
    if (value !== undefined && value !== null) {
      return value as T;
    }
  }

  return fallback;
}

function normalizeStatusValue(raw: any): number {
  if (typeof raw === 'number' && Number.isFinite(raw)) {
    return raw;
  }

  const normalized = String(raw ?? '')
    .trim()
    .toLowerCase()
    .replace(/[\s_-]/g, '');

  const mapping: Record<string, number> = {
    new: 0,
    inprogress: 1,
    awaitinghearing: 2,
    closed: 3,
    won: 4,
    lost: 5,
  };

  return mapping[normalized] ?? 0;
}

function normalizeCaseInfo(raw: any) {
  if (!raw) return null;

  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    Code: Number(pickValue(raw, ['Code', 'code'], 0)),
    InvitionsStatment: pickValue(raw, ['InvitionsStatment', 'invitionsStatment'], ''),
    InvitionType: pickValue(raw, ['InvitionType', 'invitionType'], ''),
    InvitionDate: pickValue(raw, ['InvitionDate', 'invitionDate'], ''),
    TotalAmount: Number(pickValue(raw, ['TotalAmount', 'totalAmount'], 0)),
    Notes: pickValue(raw, ['Notes', 'notes'], ''),
    Status: normalizeStatusValue(pickValue(raw, ['Status', 'status'], 0)),
  };
}

function normalizeCustomer(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    CustomerId: Number(pickValue(raw, ['CustomerId', 'customerId', 'Id', 'id'], 0)),
    CustomerName: pickValue(raw, ['CustomerName', 'customerName', 'Full_Name', 'full_Name', 'fullName', 'name'], '-'),
  };
}

function normalizeContender(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    ContenderId: Number(pickValue(raw, ['ContenderId', 'contenderId', 'Id', 'id'], 0)),
    ContenderName: pickValue(raw, ['ContenderName', 'contenderName', 'Full_Name', 'full_Name', 'fullName', 'name'], '-'),
    FullName: pickValue(raw, ['FullName', 'fullName', 'Full_Name', 'full_Name'], ''),
    SSN: pickValue(raw, ['SSN', 'ssn'], ''),
    BirthDate: pickValue(raw, ['BirthDate', 'birthDate'], ''),
  };
}

function normalizeCourt(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    CourtId: Number(pickValue(raw, ['CourtId', 'courtId', 'Id', 'id'], 0)),
    CourtName: pickValue(raw, ['CourtName', 'courtName', 'Name', 'name'], '-'),
    Name: pickValue(raw, ['Name', 'name', 'CourtName', 'courtName'], '-'),
  };
}

function normalizeEmployee(raw: any) {
  const name = pickValue(raw, ['Full_Name', 'full_Name', 'fullName', 'name'], '-');
  return {
    id: Number(pickValue(raw, ['id', 'Id'], 0)),
    Full_Name: name,
    fullName: name,
  };
}

function normalizeSiting(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    SitingId: Number(pickValue(raw, ['SitingId', 'sitingId', 'Id', 'id'], 0)),
    SitingDate: pickValue(raw, ['SitingDate', 'sitingDate', 'Siting_Date', 'siting_Date'], ''),
    JudgeName: pickValue(raw, ['JudgeName', 'judgeName', 'Judge_Name', 'judge_Name'], ''),
    Notes: pickValue(raw, ['Notes', 'notes'], ''),
  };
}

function normalizeFile(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    FileId: Number(pickValue(raw, ['FileId', 'fileId', 'Id', 'id'], 0)),
    FileCode: pickValue(raw, ['FileCode', 'fileCode', 'Code', 'code'], ''),
    FilePath: pickValue(raw, ['FilePath', 'filePath', 'Path', 'path'], ''),
  };
}

function normalizeDocument(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    DocType: pickValue(raw, ['DocType', 'docType'], ''),
    DocNum: pickValue(raw, ['DocNum', 'docNum'], ''),
    DocDetails: pickValue(raw, ['DocDetails', 'docDetails'], ''),
    Notes: pickValue(raw, ['Notes', 'notes'], ''),
  };
}

function normalizeBillingPayment(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    Amount: Number(pickValue(raw, ['Amount', 'amount'], 0)),
    DateOfOperation: pickValue(raw, ['DateOfOperation', 'dateOfOperation'], ''),
    Notes: pickValue(raw, ['Notes', 'notes'], ''),
    CustomerId: Number(pickValue(raw, ['CustomerId', 'customerId'], 0)),
  };
}

function normalizeStatusHistoryItem(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    OldStatus: normalizeStatusValue(pickValue(raw, ['OldStatus', 'oldStatus'], 0)),
    NewStatus: normalizeStatusValue(pickValue(raw, ['NewStatus', 'newStatus'], 0)),
    ChangedBy: pickValue(raw, ['ChangedBy', 'changedBy'], ''),
    ChangedAt: pickValue(raw, ['ChangedAt', 'changedAt'], ''),
  };
}

function normalizeRequestedDocument(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    CaseCode: Number(pickValue(raw, ['CaseCode', 'caseCode'], 0)),
    CustomerId: Number(pickValue(raw, ['CustomerId', 'customerId'], 0)),
    CustomerName: pickValue(raw, ['CustomerName', 'customerName'], '-'),
    Title: pickValue(raw, ['Title', 'title'], ''),
    Description: pickValue(raw, ['Description', 'description'], ''),
    DueDate: pickValue(raw, ['DueDate', 'dueDate'], ''),
    Status: pickValue(raw, ['Status', 'status'], ''),
    RequestedByName: pickValue(raw, ['RequestedByName', 'requestedByName'], ''),
    CustomerNotes: pickValue(raw, ['CustomerNotes', 'customerNotes'], ''),
    ReviewNotes: pickValue(raw, ['ReviewNotes', 'reviewNotes'], ''),
    UploadedFileId: pickValue(raw, ['UploadedFileId', 'uploadedFileId'], null),
    UploadedFileCode: pickValue(raw, ['UploadedFileCode', 'uploadedFileCode'], ''),
    UploadedFilePath: pickValue(raw, ['UploadedFilePath', 'uploadedFilePath'], ''),
    RequestedAtUtc: pickValue(raw, ['RequestedAtUtc', 'requestedAtUtc'], ''),
    SubmittedAtUtc: pickValue(raw, ['SubmittedAtUtc', 'submittedAtUtc'], ''),
    ReviewedAtUtc: pickValue(raw, ['ReviewedAtUtc', 'reviewedAtUtc'], ''),
  };
}

function normalizePaymentProof(raw: any) {
  return {
    Id: Number(pickValue(raw, ['Id', 'id'], 0)),
    CustomerId: Number(pickValue(raw, ['CustomerId', 'customerId'], 0)),
    CustomerName: pickValue(raw, ['CustomerName', 'customerName'], '-'),
    Amount: Number(pickValue(raw, ['Amount', 'amount'], 0)),
    PaymentDate: pickValue(raw, ['PaymentDate', 'paymentDate'], ''),
    Notes: pickValue(raw, ['Notes', 'notes'], ''),
    ProofFileId: pickValue(raw, ['ProofFileId', 'proofFileId'], null),
    ProofFileCode: pickValue(raw, ['ProofFileCode', 'proofFileCode'], ''),
    ProofFilePath: pickValue(raw, ['ProofFilePath', 'proofFilePath'], ''),
    Status: pickValue(raw, ['Status', 'status'], ''),
    BillingPaymentId: pickValue(raw, ['BillingPaymentId', 'billingPaymentId'], null),
    ReviewNotes: pickValue(raw, ['ReviewNotes', 'reviewNotes'], ''),
    SubmittedAtUtc: pickValue(raw, ['SubmittedAtUtc', 'submittedAtUtc'], ''),
    ReviewedAtUtc: pickValue(raw, ['ReviewedAtUtc', 'reviewedAtUtc'], ''),
  };
}

type CaseTabKey =
  | 'overview'
  | 'parties'
  | 'sitings'
  | 'files'
  | 'documents'
  | 'payments'
  | 'requestedDocuments'
  | 'paymentProofs'
  | 'conversation'
  | 'history'
  | 'courts'
  | 'employees';

export default function CaseDetailsPage() {
  const { t, i18n } = useTranslation();
  const params = useParams() as { code?: string } | undefined;
  const code = Number(params?.code);
  const router = useRouter();
  const isRtl = (i18n.resolvedLanguage || i18n.language || 'en').toLowerCase().startsWith('ar');
  const locale = isRtl ? 'ar-EG' : 'en-US';

  const { hasAnyRole, user } = useAuth();
  const { formatCurrency } = useCurrency();
  const translateText = useCallback((key: string, defaultValue: string) => {
    const translated = t(key, { defaultValue });
    return translated === key ? defaultValue : translated;
  }, [t]);
  const canManageCase = hasAnyRole('Admin', 'Employee');
  const isCustomerOnly = Boolean(user?.roles?.includes('Customer') && !hasAnyRole('SuperAdmin', 'Admin', 'Employee'));
  const caseTypeOptions = CASE_TYPE_VALUES.map((value) => ({
    value,
    label: translateText(
      `cases.caseTypes.${value}`,
      value === 'PersonalStatus' ? 'Personal Status' : value,
    ),
  }));
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
  const [editFields, setEditFields] = useState({ invitionsStatment: '', invitionType: '', invitionDate: '', totalAmount: 0, notes: '' });

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
  const [activeTab, setActiveTab] = useState<CaseTabKey>('overview');
  const [statusOptions, setStatusOptions] = useState<Array<{ value: number; key: string; label: string; next: Array<{ value: number; key: string; label: string }> }>>([]);
  const caseInfo = normalizeCaseInfo(data?.Case ?? data?.case);
  const caseCourts = (data?.Courts ?? data?.courts ?? []).map(normalizeCourt);
  const caseSitings = (data?.Sitings ?? data?.sitings ?? []).map(normalizeSiting);
  const caseEmployees = (data?.Employees ?? data?.employees ?? []).map(normalizeEmployee);
  const caseBillingPayments = (data?.BillingPayments ?? data?.billingPayments ?? []).map(normalizeBillingPayment);
  const caseStatusHistory = (data?.StatusHistory ?? data?.statusHistory ?? []).map(normalizeStatusHistoryItem);
  const caseCustomers = (data?.Customers ?? data?.customers ?? []).map(normalizeCustomer);
  const caseContenders = (data?.Contenders ?? data?.contenders ?? []).map(normalizeContender);
  const caseFiles = (data?.Files ?? data?.files ?? []).map(normalizeFile);
  const caseDocuments = (data?.Documents ?? data?.documents ?? []).map(normalizeDocument);
  const caseRequestedDocuments = (data?.RequestedDocuments ?? data?.requestedDocuments ?? []).map(normalizeRequestedDocument);
  const casePaymentProofs = (data?.PaymentProofs ?? data?.paymentProofs ?? []).map(normalizePaymentProof);

  function validateCaseEditForm() {
    if (!editFields.invitionType.trim() || !CASE_TYPE_VALUES.includes(editFields.invitionType as any)) {
      return t('cases.validation.typeInvalid', { defaultValue: 'Please select a valid case type.' });
    }
    if ((editFields.invitionsStatment ?? '').trim().length < MIN_STATEMENT_LENGTH) {
      return t('cases.validation.statementTooShort', {
        defaultValue: `Case statement must be at least ${MIN_STATEMENT_LENGTH} characters.`,
        min: MIN_STATEMENT_LENGTH,
      });
    }
    if (!editFields.invitionDate) {
      return t('cases.validation.dateRequired', { defaultValue: 'Case date is required.' });
    }
    const enteredDate = new Date(`${editFields.invitionDate}T00:00:00`);
    if (Number.isNaN(enteredDate.getTime())) {
      return t('cases.validation.dateInvalid', { defaultValue: 'Case date is invalid.' });
    }
    const maxAllowedDate = new Date();
    maxAllowedDate.setDate(maxAllowedDate.getDate() + MAX_CASE_DATE_FUTURE_DAYS);
    if (enteredDate > maxAllowedDate) {
      return t('cases.validation.dateTooFar', {
        defaultValue: `Case date cannot be more than ${MAX_CASE_DATE_FUTURE_DAYS} days in the future.`,
        days: MAX_CASE_DATE_FUTURE_DAYS,
      });
    }
    const amount = Number(editFields.totalAmount || 0);
    if (!Number.isFinite(amount) || amount < 0 || amount > MAX_TOTAL_AMOUNT) {
      return t('cases.validation.amountInvalid', {
        defaultValue: `Amount must be between 0 and ${MAX_TOTAL_AMOUNT.toLocaleString()}.`,
        max: MAX_TOTAL_AMOUNT,
      });
    }
    return '';
  }

  const load = useCallback(async () => {
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
      setSnackbar({ open: true, message: err?.response?.data?.message ?? t('cases.failedLoadCase', { defaultValue: 'Failed to load case' }), severity: 'error' });
    } finally { setLoading(false); }
  }, [code, isCustomerOnly, t]);

  useEffect(() => { if (code) void load(); }, [code, load]);
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

  // initialize edit fields when API payload changes
  useEffect(() => {
    const normalizedCase = normalizeCaseInfo(data?.Case ?? data?.case);
    if (!normalizedCase) return;

    setEditFields({
      invitionsStatment: normalizedCase.InvitionsStatment ?? '',
      invitionType: normalizedCase.InvitionType ?? '',
      invitionDate: normalizedCase.InvitionDate ?? '',
      totalAmount: normalizedCase.TotalAmount ?? 0,
      notes: normalizedCase.Notes ?? '',
    });

    const normalizedCourts = (data?.Courts ?? data?.courts ?? []).map(normalizeCourt);
    if (normalizedCourts.length > 0) {
      setSelectedCourtToSet(normalizedCourts[0].CourtId || normalizedCourts[0].Id);
    } else {
      setSelectedCourtToSet('');
    }
  }, [data]);

  async function removeCustomer(customerId:number){
    try{ await api.delete(`/cases/${code}/customers/${customerId}`); setSnackbar({ open: true, message: t('customers.customerDeleted'), severity: 'success' }); await load(); }catch(err:any){ setSnackbar({ open: true, message: err?.response?.data?.message ?? t('cases.failedRemoveCustomer', { defaultValue: 'Failed to remove customer' }), severity: 'error' }); }
  }

  async function openAddCustomer(){
    try{ const r = await api.get('/Customers'); setCustomersList(r.data || []);}catch(e){ setSnackbar({ open: true, message: t('cases.failedLoadCustomers', { defaultValue: 'Failed to load customers' }), severity: 'error' }); }
    setAddCustomerOpen(true);
  }

  async function addCustomer(){
    if(!selectedCustomerToAdd) return setSnackbar({ open:true, message: t('cases.chooseCustomer', { defaultValue: 'Choose customer' }), severity: 'error' });
    try{ await api.post(`/cases/${code}/customers/${selectedCustomerToAdd}`); setAddCustomerOpen(false); setSelectedCustomerToAdd(''); await load(); setSnackbar({ open:true, message: t('cases.customerAdded', { defaultValue: 'Customer added' }), severity: 'success' }); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.failedAddCustomer', { defaultValue: 'Failed to add customer' }), severity: 'error' }); }
  }

  // Edit case general info
  function startEditing(){ setEditing(true); }
  function cancelEditing(){
    setEditing(false);
    setEditFields({
      invitionsStatment: caseInfo?.InvitionsStatment ?? '',
      invitionType: caseInfo?.InvitionType ?? '',
      invitionDate: caseInfo?.InvitionDate ?? '',
      totalAmount: caseInfo?.TotalAmount ?? 0,
      notes: caseInfo?.Notes ?? '',
    });
    setSelectedCourtToSet(caseCourts?.[0]?.CourtId || caseCourts?.[0]?.Id || '');
  }

  async function saveCaseEdits(){
    const validationMessage = validateCaseEditForm();
    if (validationMessage) {
      setSnackbar({ open:true, message: validationMessage, severity: 'error' });
      return;
    }

    try{
      // Update basic case
      const payload:any = {};
      if (editFields.invitionsStatment != null) payload.InvitionsStatment = editFields.invitionsStatment;
      if (editFields.invitionType != null) payload.InvitionType = editFields.invitionType;
      if (editFields.invitionDate) payload.InvitionDate = editFields.invitionDate;
      if (editFields.totalAmount != null) payload.TotalAmount = Number(editFields.totalAmount);
      if (editFields.notes != null) payload.Notes = editFields.notes;
      await api.put(`/Cases/${code}`, payload);

      // Update court with optimal history semantics:
      // - replace old->new via dedicated change endpoint (single "Changed" history record)
      // - otherwise keep add/remove behavior for multi-court edge cases
      const existingCourtIds = Array.from(new Set((caseCourts || [])
        .map((c:any) => Number(c.CourtId || c.Id))
        .filter((id:number) => Number.isFinite(id) && id > 0)));

      if (selectedCourtToSet !== ''){
        const targetCourtId = Number(selectedCourtToSet);
        if (existingCourtIds.length === 1 && existingCourtIds[0] !== targetCourtId){
          await api.put(`/cases/${code}/courts/${existingCourtIds[0]}/change/${targetCourtId}`);
        } else {
          for (const existingId of existingCourtIds){
            if (existingId !== targetCourtId){
              try{ await api.delete(`/cases/${code}/courts/${existingId}`); }catch(e){}
            }
          }

          if (!existingCourtIds.includes(targetCourtId)){
            try{ await api.post(`/cases/${code}/courts/${targetCourtId}`); }catch(e){}
          }
        }
      } else {
        for (const existingId of existingCourtIds){
          try{ await api.delete(`/cases/${code}/courts/${existingId}`); }catch(e){}
        }
      }

      setSnackbar({ open:true, message: t('cases.caseUpdated', { defaultValue: 'Case updated' }), severity: 'success' });
      setEditing(false);
      await load();
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.failedUpdate', { defaultValue: 'Failed to update case' }), severity: 'error' }); }
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
      setSnackbar({ open:true, message: t('cases.sitingCreated', { defaultValue: 'Hearing created' }), severity: 'success' });
      await load();
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('sitings.failedCreate', { defaultValue: 'Failed to create hearing' }), severity: 'error' }); }
  }

  // Edit siting
  async function openEditSiting(sitingId:number){
    try{
      const r = await api.get(`/Sitings/${sitingId}`);
      // API returns full siting dto
      const sit = r.data;
      setEditingSiting({ id: sit.Id, date: sit.SitingDate ?? sit.Siting_Date ?? '', time: sit.SitingTime ? new Date(sit.SitingTime).toISOString().slice(11,19) : '', judgeName: sit.JudgeName ?? sit.Judge_Name, notes: sit.Notes });
      setEditSitingOpen(true);
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('sitings.failedLoad', { defaultValue: 'Failed to load hearings data' }), severity:'error' }); }
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
      setSnackbar({ open:true, message: t('cases.sitingUpdated', { defaultValue: 'Hearing updated' }), severity:'success' });
      await load();
    }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('sitings.failedUpdate', { defaultValue: 'Failed to update hearing' }), severity:'error' }); }
  }

  // Contender edit
  function openEditContender(cont:any){ setEditingContender(cont); setEditContenderOpen(true); }
  async function saveContenderEdit(){
    if(!editingContender) return;
    try{ await api.put(`/Contenders/${editingContender.ContenderId || editingContender.Id}`, { FullName: editingContender.FullName ?? editingContender.ContenderName, SSN: editingContender.SSN, BirthDate: editingContender.BirthDate }); setEditContenderOpen(false); setEditingContender(null); setSnackbar({ open:true, message: t('cases.contenderUpdated', { defaultValue: 'Contender updated' }), severity:'success' }); await load(); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.failedUpdate', { defaultValue: 'Failed to update case' }), severity:'error' }); }
  }

  // Employees assign
  async function openAssignEmployee(){ try{ const r = await api.get('/Employees'); setEmployeesList(r.data || []); setAssignEmployeeOpen(true); }catch(err:any){ setSnackbar({ open:true, message: t('cases.failedLoadEmployees', { defaultValue: 'Failed to load employees' }), severity:'error' }); } }
  async function assignEmployee(){ if(!selectedEmployeeToAdd) return; try{ await api.post(`/cases/${code}/employees/${selectedEmployeeToAdd}`); setAssignEmployeeOpen(false); setSelectedEmployeeToAdd(''); setSnackbar({ open:true, message: t('cases.employeeAssigned', { defaultValue: 'Employee assigned' }), severity:'success' }); await load(); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.failedUpdate', { defaultValue: 'Failed to update case' }), severity:'error' }); } }

  async function removeContender(id:number){ try{ await api.delete(`/cases/${code}/contenders/${id}`); await load(); setSnackbar({ open:true, message: t('cases.contenderRemoved', { defaultValue: 'Contender removed' }), severity:'success' }); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('contenders.failedDelete', { defaultValue: 'Failed to delete contender' }), severity:'error' }); } }

  async function removeSiting(sitingId:number){ try{ await api.delete(`/cases/${code}/sitings/${sitingId}`); await load(); setSnackbar({ open:true, message: t('cases.sitingRemoved', { defaultValue: 'Hearing removed' }), severity:'success' }); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('sitings.failedDelete', { defaultValue: 'Failed to delete hearing' }), severity:'error' }); } }

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
    setSnackbar({ open:true, message: t('files.fileUploaded', { defaultValue: 'File uploaded successfully' }), severity:'success' });
    await load();
  }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('files.failedUpload', { defaultValue: 'Failed to upload file' }), severity:'error' }); } }

  async function uploadFiles(files:FileList | null){
    if(!files) return;
    await uploadFileArray(Array.from(files));
  }

  async function handleDropFiles(e: React.DragEvent<HTMLDivElement>){
    e.preventDefault();
    setIsDraggingFiles(false);
    await uploadFileArray(Array.from(e.dataTransfer.files || []));
  }

  async function removeFile(fileId:number){ try{ await api.delete(`/cases/${code}/files/${fileId}`); setSnackbar({ open:true, message: t('files.fileDeleted', { defaultValue: 'File deleted successfully' }), severity:'success' }); await load(); }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('files.failedDelete', { defaultValue: 'Failed to delete file' }), severity:'error' }); } }

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

  const currentStatus = normalizeStatusValue(caseInfo?.Status ?? 0);
  const currentStatusOption = statusOptions.find(s => s.value === currentStatus);
  const allowedNextValues = new Set<number>([currentStatus, ...(currentStatusOption?.next?.map(n => n.value) ?? [])]);
  const statusKeys = ['new', 'inprogress', 'awaitinghearing', 'closed', 'won', 'lost'];
  const statusFallbackLabels = ['New', 'In Progress', 'Awaiting Hearing', 'Closed', 'Won', 'Lost'];
  const getStatusLabel = (status: number) => {
    const normalizedStatus = normalizeStatusValue(status);
    const key = statusKeys[normalizedStatus];
    if (!key) return '-';
    return translateText(`cases.statuses.${key}`, statusFallbackLabels[normalizedStatus] ?? '-');
  };
  const nextSiting = [...caseSitings]
    .sort((a:any, b:any) => String(a.SitingDate || '').localeCompare(String(b.SitingDate || '')))
    .find((item:any) => {
      if (!item?.SitingDate) return false;
      const parsed = new Date(item.SitingDate);
      return Number.isNaN(parsed.getTime()) ? true : parsed >= new Date(new Date().toDateString());
    });
  const latestStatusHistory = caseStatusHistory[0] ?? null;
  const totalPaid = caseBillingPayments.reduce((sum:number, item:any) => sum + Number(item.Amount || 0), 0);
  const formatDate = (value?: string | null) => {
    if (!value) return '-';
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? String(value) : parsed.toLocaleDateString(locale);
  };
  const formatDateTime = (value?: string | null) => {
    if (!value) return '-';
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? String(value) : parsed.toLocaleString(locale);
  };
  const formatNumber = (value?: number | string | null) => {
    const numeric = Number(value ?? 0);
    return Number.isFinite(numeric) ? numeric.toLocaleString(locale) : '-';
  };
  const formatMoney = (value?: number | string | null) => {
    const numeric = Number(value ?? 0);
    return Number.isFinite(numeric) ? formatCurrency(numeric) : '-';
  };
  const tabs: Array<{ value: CaseTabKey; label: string }> = useMemo(
    () => (isCustomerOnly
      ? [
          { value: 'overview', label: translateText('cases.general', 'General') },
          { value: 'sitings', label: translateText('cases.sitings', 'Hearings') },
          { value: 'files', label: translateText('files.title', 'Files') },
          { value: 'documents', label: translateText('clientPortal.myDocuments', 'My Documents') },
          { value: 'payments', label: translateText('clientPortal.myPayments', 'My Payments') },
          { value: 'requestedDocuments', label: translateText('cases.requestedDocuments.title', 'Requested Documents') },
          { value: 'paymentProofs', label: translateText('cases.paymentProofs.title', 'Payment Proofs') },
          { value: 'conversation', label: translateText('cases.conversation.title', 'Case Conversation') },
          { value: 'history', label: translateText('cases.history', 'History') },
        ]
      : [
          { value: 'overview', label: translateText('cases.general', 'General') },
          { value: 'parties', label: translateText('cases.relatedCustomers', 'Related Parties') },
          { value: 'sitings', label: translateText('cases.sitings', 'Hearings') },
          { value: 'files', label: translateText('files.title', 'Files') },
          { value: 'requestedDocuments', label: translateText('cases.requestedDocuments.title', 'Requested Documents') },
          { value: 'paymentProofs', label: translateText('cases.paymentProofs.title', 'Payment Proofs') },
          { value: 'conversation', label: translateText('cases.conversation.title', 'Case Conversation') },
          { value: 'history', label: translateText('cases.history', 'History') },
          { value: 'courts', label: translateText('cases.courts', 'Courts') },
          { value: 'employees', label: translateText('cases.employees', 'Employees') },
        ]),
    [isCustomerOnly, translateText]
  );
  const isTabActive = (tab: CaseTabKey) => activeTab === tab;
  const isPrimaryGroupTabActive = isTabActive('overview') || (!isCustomerOnly && isTabActive('parties'));
  const isSecondaryGroupTabActive =
    isTabActive('sitings') ||
    isTabActive('files') ||
    isTabActive('documents') ||
    isTabActive('payments') ||
    isTabActive('requestedDocuments') ||
    isTabActive('paymentProofs') ||
    isTabActive('conversation') ||
    isTabActive('history') ||
    (!isCustomerOnly && (isTabActive('courts') || isTabActive('employees')));

  useEffect(() => {
    if (!tabs.some((tab) => tab.value === activeTab)) {
      setActiveTab('overview');
    }
  }, [activeTab, tabs]);

  return (
    <Box dir={isRtl ? 'rtl' : 'ltr'} sx={{ p: 2 }}>
      <Box sx={{ display:'flex', alignItems:'center', gap:2, mb:2 }}>
        <Tooltip title={t('app.back') || 'Back'}>
          <IconButton onClick={()=>router.push(isCustomerOnly ? '/client-portal' : '/cases')}><ArrowBack/></IconButton>
        </Tooltip>
        <Typography variant="h5">{t('cases.details', { defaultValue: 'Case Details' })} - {caseInfo?.Code ?? code}</Typography>
        <Button size="small" variant="outlined" onClick={() => router.push(`/cases/${code}/timeline`)}>{t('cases.timeline', { defaultValue: 'Timeline' })}</Button>
      </Box>

      {caseInfo ? (
        <Card sx={{ mb: 2 }}>
          <CardContent sx={{ pb: '16px !important' }}>
            <Tabs
              dir={isRtl ? 'rtl' : 'ltr'}
              value={activeTab}
              onChange={(_, value) => setActiveTab(value)}
              variant="scrollable"
              scrollButtons="auto"
              allowScrollButtonsMobile
            >
              {tabs.map((tab) => (
                <Tab key={tab.value} value={tab.value} label={tab.label} />
              ))}
            </Tabs>
          </CardContent>
        </Card>
      ) : null}

      {caseInfo ? (
        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr', gap: 2, alignItems: 'start' }}>
          {isPrimaryGroupTabActive && <Box>
            {isTabActive('overview') && <Card><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('cases.general') || 'General'}</Typography>
                {canManageCase && (!editing ? <Button size="small" onClick={startEditing}>{t('app.edit') || 'Edit'}</Button> : <Box><Button size="small" onClick={cancelEditing}>{t('app.cancel')}</Button> <Button size="small" variant="contained" onClick={saveCaseEdits}>{t('app.save') || 'Save'}</Button></Box>)}
              </Box>

              <Typography>{t('cases.code')}: <strong>{caseInfo.Code}</strong></Typography>
              <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mt: 1 }}>
                <Typography variant="body2" sx={{ color: 'text.secondary' }}>{t('cases.status')}: </Typography>
                <Chip label={getStatusLabel(caseInfo.Status)} size="small" color="default" variant="outlined" />
                {canManageCase && (
                  <SearchableSelect<number>
                    size="small"
                    label={t('cases.status')}
                    value={caseInfo.Status ?? 0}
                    onChange={async (value) => {
                        const newStatus = Number(value ?? 0);
                        try {
                          await api.post(`/Cases/${code}/status`, { status: ['New','InProgress','AwaitingHearing','Closed','Won','Lost'][newStatus] });
                          setSnackbar({ open: true, message: t('cases.statusUpdated', { defaultValue: 'Status updated' }), severity: 'success' });
                          await load();
                        } catch (err:any) { setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.failedStatusUpdate', { defaultValue: 'Failed to update status' }), severity:'error' }); }
                    }}
                    options={[
                      { value: 0, label: translateText('cases.statuses.new', 'New'), disabled: !allowedNextValues.has(0) },
                      { value: 1, label: translateText('cases.statuses.inprogress', 'In Progress'), disabled: !allowedNextValues.has(1) },
                      { value: 2, label: translateText('cases.statuses.awaitinghearing', 'Awaiting Hearing'), disabled: !allowedNextValues.has(2) },
                      { value: 3, label: translateText('cases.statuses.closed', 'Closed'), disabled: !allowedNextValues.has(3) },
                      { value: 4, label: translateText('cases.statuses.won', 'Won'), disabled: !allowedNextValues.has(4) },
                      { value: 5, label: translateText('cases.statuses.lost', 'Lost'), disabled: !allowedNextValues.has(5) },
                    ]}
                    disableClearable
                    sx={{ ...(isRtl ? { mr: 1 } : { ml: 1 }), minWidth: 160 }}
                  />
                )}
              </Box>

              {isCustomerOnly && (
                <Box sx={{ mt: 1.5, display:'grid', gridTemplateColumns:{ xs:'1fr', sm:'1fr 1fr' }, gap:1 }}>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{t('cases.status')}</Typography><Typography variant="subtitle1">{getStatusLabel(caseInfo.Status)}</Typography></CardContent></Card>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{t('clientPortal.caseSessions', { defaultValue: 'Case Sessions' })}</Typography><Typography variant="subtitle1">{nextSiting ? `${formatDate(nextSiting.SitingDate)} - ${nextSiting.JudgeName}` : '-'}</Typography></CardContent></Card>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{translateText('cases.employees', 'Employees')}</Typography><Typography variant="subtitle1">{caseEmployees?.map((e:any)=>e.Full_Name || e.fullName).filter(Boolean).join(', ') || '-'}</Typography></CardContent></Card>
                  <Card variant="outlined"><CardContent><Typography variant="caption" color="text.secondary">{t('clientPortal.totalPaid', { defaultValue: 'Total Paid' })}</Typography><Typography variant="subtitle1">{formatMoney(totalPaid)}</Typography></CardContent></Card>
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
                  <Typography>{t('cases.statement', { defaultValue: 'Statement' })}: {caseInfo.InvitionsStatment || '-'}</Typography>
                  <Typography>{t('cases.type')}: {caseInfo.InvitionType}</Typography>
                  <Typography>{t('cases.date')}: {formatDate(caseInfo.InvitionDate)}</Typography>
                  <Typography>{t('cases.amount')}: {formatMoney(caseInfo.TotalAmount)}</Typography>
                  <Typography>{t('cases.notes')}: {caseInfo.Notes}</Typography>
                  {isCustomerOnly && (
                    <>
                      <Typography>{translateText('cases.courts', 'Courts')}: {caseCourts?.map((c:any)=>c.CourtName || c.Name).filter(Boolean).join(', ') || '-'}</Typography>
                      <Typography>{t('clientPortal.latestUpdate', { defaultValue: 'Latest Update' })}: {formatDateTime(latestStatusHistory?.ChangedAt)}</Typography>
                    </>
                  )}
                </>
              ) : (
                <Box sx={{ mt:1, display:'grid', gridTemplateColumns:{ xs:'1fr', sm:'1fr 1fr'}, gap:1 }}>
                  <TextField
                    label={t('cases.statement', { defaultValue: 'Statement' })}
                    value={editFields.invitionsStatment}
                    onChange={(e)=>setEditFields({...editFields, invitionsStatment: e.target.value})}
                    multiline
                    minRows={2}
                    sx={{ gridColumn: { xs: '1 / -1', sm: '1 / -1' } }}
                  />
                  <SearchableSelect<string>
                    label={t('cases.type')}
                    value={editFields.invitionType || null}
                    onChange={(value)=>setEditFields({ ...editFields, invitionType: value ?? '' })}
                    options={caseTypeOptions}
                  />
                  <TextField label={t('cases.date')} type="date" InputLabelProps={{ shrink:true }} value={editFields.invitionDate?.slice(0,10) ?? ''} onChange={(e)=>setEditFields({...editFields, invitionDate: e.target.value})} />
                  <Box>
                    <TextField label={t('cases.amount')} type="number" value={editFields.totalAmount ?? ''} onChange={(e)=>setEditFields({...editFields, totalAmount: Number(e.target.value)})} />
                    <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
                      {t('cases.amountPreview', { defaultValue: 'Formatted amount' })}: {formatMoney(editFields.totalAmount)}
                    </Typography>
                  </Box>
                  <TextField label={t('cases.notes')} value={editFields.notes} onChange={(e)=>setEditFields({...editFields, notes: e.target.value})} multiline rows={2} />

                  <SearchableSelect<number>
                    label={t('courts.name')}
                    value={typeof selectedCourtToSet === 'number' ? selectedCourtToSet : null}
                    onOpen={async ()=>{ if(courtsList.length===0){ const r = await api.get('/Courts'); setCourtsList(r.data || []); } }}
                    onChange={(value)=>setSelectedCourtToSet(value ?? '')}
                    options={courtsList
                      .map((c:any)=> ({ value: Number(c.id ?? c.Id), label: c.name ?? c.Name }))
                      .filter((o)=> Number.isFinite(o.value) && !!o.label)}
                  />
                </Box>
              )}
            </CardContent></Card>}

            {!isCustomerOnly && isTabActive('parties') && <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('customers.title') || 'Customers'}</Typography>
                <Button size="small" startIcon={<AddIcon/>} onClick={openAddCustomer}>{t('customers.add') || 'Add'}</Button>
              </Box>
              <List>
                {caseCustomers.map((c:any)=> (
                  <ListItem key={c.Id} secondaryAction={<Button color="error" size="small" onClick={()=>removeCustomer(c.CustomerId)}>{t('app.delete')}</Button>}>
                    <ListItemText primary={c.CustomerName} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>}

            {!isCustomerOnly && isTabActive('parties') && <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{t('contenders.title') || 'Contenders'}</Typography>
              </Box>
              <List>
                {caseContenders.map((c:any)=> (
                  <ListItem key={c.Id} secondaryAction={<Box>
                    <Button size="small" onClick={()=>openEditContender(c)}>{t('app.edit') || 'Edit'}</Button>
                    <Button color="error" size="small" onClick={()=>removeContender(c.ContenderId)}>{t('app.delete')}</Button>
                  </Box>}>
                    <ListItemText primary={c.ContenderName} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>}

          </Box>}

          {isSecondaryGroupTabActive && <Box>
            {isTabActive('sitings') && <Card><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{translateText('sitings.title', 'Sitings')}</Typography>
                <Box>
                  {canManageCase && <Button size="small" onClick={()=>setCreateSitingOpen(true)} startIcon={<AddIcon/>}>{t('cases.createNewSiting') || 'Add'}</Button>}
                </Box>
              </Box>
              <List>
                {caseSitings.map((s:any)=> (
                  <ListItem key={s.Id} secondaryAction={canManageCase ? <Box sx={{ display:'flex', gap:1 }}><Button size="small" onClick={()=>openEditSiting(s.SitingId)}>{t('app.edit') || 'Edit'}</Button><Button color="error" size="small" onClick={()=>removeSiting(s.SitingId)}>{t('app.delete')}</Button></Box> : undefined}>
                    <ListItemText primary={`${formatDate(s.SitingDate)} - ${s.JudgeName}`} secondary={s.Notes || ''} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>}

            {isTabActive('files') && <Card sx={{ mt:2 }}><CardContent>
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
                {caseFiles.map((f:any)=> (
                  <ListItem key={f.Id} secondaryAction={<Box sx={{ display:'flex', gap:1 }}>
                    {canManageCase && <Button size="small" onClick={()=>{ setEditingFile({ id: f.FileId, code: f.FileCode ?? '' }); setEditFileOpen(true); }}>{t('app.edit') || 'Edit'}</Button>}
                    <IconButton href={`/api/files/${f.FileId}/download`} target="_blank"><DownloadIcon/></IconButton>
                    {canManageCase && <IconButton color="error" onClick={()=>removeFile(f.FileId)}><DeleteIcon/></IconButton>}
                  </Box>}>
                    <ListItemText primary={`${f.FileCode || f.FileId}`} secondary={f.FilePath} />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>}

            {isTabActive('documents') && <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{translateText('clientPortal.myDocuments', 'My Documents')}</Typography>
              <List>
                {caseDocuments.map((item:any) => (
                  <ListItem key={item.Id}>
                    <ListItemText primary={`${item.DocType}${item.DocNum ? ` #${item.DocNum}` : ''}`} secondary={item.DocDetails || item.Notes || ''} />
                  </ListItem>
                ))}
                {caseDocuments.length === 0 && <ListItem><ListItemText primary={t('clientPortal.noData', { defaultValue: 'No data available' })} /></ListItem>}
              </List>
            </CardContent></Card>}

            {isTabActive('payments') && <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{translateText('clientPortal.myPayments', 'My Payments')}</Typography>
              <List>
                {caseBillingPayments.map((item:any) => (
                  <ListItem key={item.Id}>
                    <ListItemText primary={`${formatMoney(item.Amount)} - ${formatDate(item.DateOfOperation)}`} secondary={item.Notes || ''} />
                  </ListItem>
                ))}
                {caseBillingPayments.length === 0 && <ListItem><ListItemText primary={t('clientPortal.noData', { defaultValue: 'No data available' })} /></ListItem>}
              </List>
            </CardContent></Card>}

            {isTabActive('requestedDocuments') && <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center', mb: 1 }}>
                <Typography variant="h6">{translateText('cases.requestedDocuments.title', 'Requested Documents')}</Typography>
                {canManageCase && <Button size="small" startIcon={<AddIcon/>} onClick={async ()=>{ if(customersList.length===0){ try{ const r = await api.get('/Customers'); setCustomersList(r.data || []); }catch{} } setRequestDocumentOpen(true); }}>{t('cases.requestedDocuments.request', { defaultValue: 'Request document' })}</Button>}
              </Box>
              <List>
                {caseRequestedDocuments.map((item:any) => (
                  <ListItem key={item.Id} alignItems="flex-start">
                    <ListItemText
                      primary={`${item.Title} (${item.Status})`}
                      secondary={
                        <Box sx={{ display:'grid', gap: 1, mt: 0.5 }}>
                          <Typography variant="body2">{item.Description || '-'}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {t('cases.requestedDocuments.dueDate', { defaultValue: 'Due date' })}: {formatDate(item.DueDate)}
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
                {caseRequestedDocuments.length === 0 && <ListItem><ListItemText primary={t('cases.requestedDocuments.empty', { defaultValue: 'No requested documents for this case yet.' })} /></ListItem>}
              </List>
              <input ref={requestedDocumentInputRef} type="file" hidden onChange={(e)=>void handleRequestedDocumentUpload(e)} />
            </CardContent></Card>}

            {isTabActive('paymentProofs') && <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{translateText('cases.paymentProofs.title', 'Payment Proofs')}</Typography>
              <List>
                {casePaymentProofs.map((item:any) => (
                  <ListItem key={item.Id} alignItems="flex-start">
                    <ListItemText
                      primary={`${formatMoney(item.Amount)} - ${item.Status}`}
                      secondary={
                        <Box sx={{ display:'grid', gap:1, mt:0.5 }}>
                          <Typography variant="caption" color="text.secondary">
                            {t('clientPortal.paymentDate', { defaultValue: 'Payment date' })}: {formatDate(item.PaymentDate)}
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
                {casePaymentProofs.length === 0 && <ListItem><ListItemText primary={t('cases.paymentProofs.empty', { defaultValue: 'No payment proofs for this case yet.' })} /></ListItem>}
              </List>
            </CardContent></Card>}

            {isTabActive('conversation') && <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{translateText('cases.conversation.title', 'Case Conversation')}</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                {t('cases.conversation.subtitle', { defaultValue: 'Use this thread to communicate with the office about this case.' })}
              </Typography>
              <List sx={{ maxHeight: 320, overflowY: 'auto', mb: 1 }}>
                {conversation.map((item:any) => (
                  <ListItem key={item.id} sx={{ justifyContent: item.isMine ? 'flex-end' : 'flex-start' }}>
                    <Box sx={{ maxWidth: '85%', px: 1.5, py: 1, borderRadius: 2, bgcolor: item.isMine ? 'primary.main' : 'action.hover', color: item.isMine ? 'primary.contrastText' : 'text.primary' }}>
                      <Typography variant="caption" sx={{ display:'block', opacity: item.isMine ? 0.9 : 0.75 }}>
                        {item.senderName} - {item.senderRole} - {formatDateTime(item.createdAtUtc)}
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
            </CardContent></Card>}

            {isTabActive('history') && <Card sx={{ mt:2 }}><CardContent>
              <Typography variant="h6">{`${translateText('cases.status', 'Status')} ${translateText('cases.history', 'History')}`}</Typography>
              <List>
                {caseStatusHistory.map((h:any) => (
                  <ListItem key={h.Id}>
                    <ListItemText
                      primary={`${formatDateTime(h.ChangedAt)} - ${getStatusLabel(h.OldStatus)} -> ${getStatusLabel(h.NewStatus)}`}
                      secondary={h.ChangedBy || ''}
                    />
                  </ListItem>
                ))}
              </List>
            </CardContent></Card>}

            {!isCustomerOnly && isTabActive('courts') && <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{translateText('cases.courts', 'Courts')}</Typography>
                {canManageCase && (!editing ? (
                  <Button
                    size="small"
                    onClick={async ()=>{
                      if(courtsList.length===0){
                        const r = await api.get('/Courts');
                        setCourtsList(r.data || []);
                      }
                      setSelectedCourtToSet(caseCourts?.[0]?.CourtId || caseCourts?.[0]?.Id || '');
                      setEditing(true);
                    }}
                  >
                    {t('app.edit') || 'Edit'}
                  </Button>
                ) : (
                  <Box sx={{ display:'flex', gap:1 }}>
                    <Button size="small" onClick={cancelEditing}>{t('app.cancel') || 'Cancel'}</Button>
                    <Button size="small" variant="contained" onClick={saveCaseEdits}>{t('app.save') || 'Save'}</Button>
                  </Box>
                ))}
              </Box>
              {canManageCase && editing && (
                <Box sx={{ mt: 1.5, mb: 1.5, maxWidth: 420 }}>
                  <SearchableSelect<number>
                    label={t('courts.name')}
                    value={typeof selectedCourtToSet === 'number' ? selectedCourtToSet : null}
                    onOpen={async ()=>{ if(courtsList.length===0){ const r = await api.get('/Courts'); setCourtsList(r.data || []); } }}
                    onChange={(value)=>setSelectedCourtToSet(value ?? '')}
                    options={courtsList
                      .map((c:any)=> ({ value: Number(c.id ?? c.Id), label: c.name ?? c.Name }))
                      .filter((o)=> Number.isFinite(o.value) && !!o.label)}
                  />
                </Box>
              )}
              <List>
                {caseCourts.map((c:any)=> (<ListItem key={c.Id}><ListItemText primary={c.CourtName || c.Name} /></ListItem>))}
              </List>
            </CardContent></Card>}

            {!isCustomerOnly && isTabActive('employees') && <Card sx={{ mt:2 }}><CardContent>
              <Box sx={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                <Typography variant="h6">{translateText('cases.employees', 'Employees')}</Typography>
                {canManageCase && <Button size="small" onClick={openAssignEmployee} startIcon={<AddIcon/>}>{t('employees.add', { defaultValue: 'Assign' })}</Button>}
              </Box>
              <List>
                {caseEmployees.map((e:any)=> (<ListItem key={e.id}><ListItemText primary={e.Full_Name || e.fullName} />{canManageCase && <Button size="small" color="error" onClick={async ()=>{ try{ await api.delete(`/cases/${code}/employees/${e.id}`); await load(); setSnackbar({ open:true, message: t('cases.employeeDeleted', { defaultValue: 'Employee removed' }), severity:'success' }); }catch(err:any){ setSnackbar({ open:true, message: t('cases.failedDelete', { defaultValue: 'Failed to remove' }), severity:'error' }); } }}>{t('app.remove', { defaultValue: 'Remove' })}</Button>}</ListItem>))}
              </List>
            </CardContent></Card>}

          </Box>}
        </Box>
      ) : (
        <Box sx={{ minHeight: 240, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Typography color="text.secondary">{loading ? t('app.loading', { defaultValue: 'Loading...' }) : t('cases.noDataFound', { defaultValue: 'No data found' })}</Typography>
        </Box>
      )}

      {/* Add Customer Dialog */}
      <Dialog open={addCustomerOpen} onClose={()=>setAddCustomerOpen(false)}>
        <DialogTitle>{t('cases.addCustomerToCase', { defaultValue: 'Add customer to case' })}</DialogTitle>
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
            <TextField label={t('cases.time', { defaultValue: 'Time' })} type="time" value={newSiting.time} onChange={(e)=>setNewSiting({...newSiting, time: e.target.value})} />
            <TextField label={t('cases.judge', { defaultValue: 'Judge' })} value={newSiting.judgeName} onChange={(e)=>setNewSiting({...newSiting, judgeName: e.target.value})} />
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
            <TextField label={t('cases.time', { defaultValue: 'Time' })} type="time" value={editingSiting?.time ?? ''} onChange={(e)=>setEditingSiting({...editingSiting, time: e.target.value})} />
            <TextField label={t('cases.judge', { defaultValue: 'Judge' })} value={editingSiting?.judgeName ?? ''} onChange={(e)=>setEditingSiting({...editingSiting, judgeName: e.target.value})} />
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
              setSnackbar({ open:true, message: t('cases.fileUpdated', { defaultValue: 'File updated' }), severity:'success' });
              await load();
            }catch(err:any){ setSnackbar({ open:true, message: err?.response?.data?.message ?? t('cases.failedUpdate', { defaultValue: 'Failed to update case' }), severity:'error' }); }
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
              options={caseCustomers.map((customer:any) => ({
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

