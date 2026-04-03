"use client";

import React, { useEffect, useState } from 'react';
import {
  Alert,
  Backdrop,
  Box,
  Button,
  Card,
  CardContent,
  Checkbox,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  FormControlLabel,
  Grid,
  IconButton,
  LinearProgress,
  Paper,
  Step,
  StepLabel,
  Stepper,
  Stack,
  Snackbar,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tabs,
  TextField,
  Tooltip,
  Typography,
  Chip,
} from '@mui/material';
import { DataGrid, GridActionsCellItem } from '@mui/x-data-grid';
import { Download, Delete, Visibility, Edit, Print, ExpandMore, ExpandLess, History, Restore, Close } from '@mui/icons-material';
import api from '../../src/services/api';
import { useTranslation } from 'react-i18next';
import SearchableSelect from '../../src/components/SearchableSelect';
import HtmlEditor from '../../src/components/HtmlEditor';

type Template = { key: string; name: string; description: string };
type ClauseItem = { key: string; text: string };
type Party = { name: string; role: string; contactInfo?: string };
type Branding = {
  firmName: string;
  address: string;
  contactInfo: string;
  footerText: string;
  signatureBlock: string;
};
type CustomTemplate = {
  id: string;
  name: string;
  body: string;
};

type GeneratedDocument = {
  id: number;
  templateType: string;
  caseCode?: number;
  format: string;
  documentTitle: string;
  documentReference?: string;
  documentCategory?: string;
  generatedAt: string;
  generatedBy: string;
  version: number;
  branding?: Branding;
  parties?: Party[];
  clauseKeys?: string[];
};

type DocumentDraft = {
  id: number;
  draftName: string;
  templateType: string;
  caseCode?: number;
  format: string;
  scope?: string;
  feeTerms?: string;
  subject?: string;
  statement?: string;
  aiInstructions?: string;
  previewContent?: string;
  documentTitle?: string;
  documentReference?: string;
  documentCategory?: string;
  documentNotes?: string;
  branding?: Branding;
  parties?: Party[];
  clauseKeys?: string[];
  createdAt: string;
  lastModifiedAt?: string;
};

type DocumentVersionDto = {
  id: number;
  version: number;
  generatedBy: string;
  generatedAt: string;
  parentId?: number;
  isCurrent: boolean;
};

type DocumentVersionChainDto = {
  rootDocumentId: number;
  title: string;
  templateType: string;
  totalVersions: number;
  versions: DocumentVersionDto[];
};

export default function DocumentGenerationPage() {
  const { t, i18n } = useTranslation();
  const [mainTab, setMainTab] = useState(0); // 0=Generator, 1=History, 2=Drafts
  const [templates, setTemplates] = useState<Template[]>([]);
  const [templateType, setTemplateType] = useState('power-of-attorney');
  const [caseCode, setCaseCode] = useState('');
  const [customerId, setCustomerId] = useState('');
  const [format, setFormat] = useState<'txt' | 'pdf' | 'docx'>('docx');
  const [scope, setScope] = useState('');
  const [feeTerms, setFeeTerms] = useState('');
  const [subject, setSubject] = useState('');
  const [statement, setStatement] = useState('');
  const [aiInstructions, setAiInstructions] = useState('');
  const [previewContent, setPreviewContent] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [snackbarOpen, setSnackbarOpen] = useState(false);
  const [snackbarSeverity, setSnackbarSeverity] = useState<'success' | 'error'>('success');
  const [snackbarMessage, setSnackbarMessage] = useState('');
  const [activeTab, setActiveTab] = useState(0); // Form tabs: 0=Content, 1=Preview, 2=Metadata
  const [workflowStep, setWorkflowStep] = useState(0);
  
  // Phase 1: New metadata fields
  const [saveToCase, setSaveToCase] = useState(false);
  const [documentTitle, setDocumentTitle] = useState('');
  const [documentReference, setDocumentReference] = useState('');
  const [documentCategory, setDocumentCategory] = useState('');
  const [documentNotes, setDocumentNotes] = useState('');

  // Phase 2: History and Drafts
  const [history, setHistory] = useState<GeneratedDocument[]>([]);
  const [drafts, setDrafts] = useState<DocumentDraft[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [draftsLoading, setDraftsLoading] = useState(false);
  const [currentDraftId, setCurrentDraftId] = useState<number | null>(null);
  const [clauses, setClauses] = useState<ClauseItem[]>([]);
  const [selectedClauseKeys, setSelectedClauseKeys] = useState<string[]>([]);
  const [parties, setParties] = useState<Party[]>([{ name: '', role: 'Client', contactInfo: '' }]);
  const [branding, setBranding] = useState<Branding>({
    firmName: '',
    address: '',
    contactInfo: '',
    footerText: '',
    signatureBlock: '',
  });
  const [customTemplates, setCustomTemplates] = useState<CustomTemplate[]>([]);
  const [customTemplateName, setCustomTemplateName] = useState('');
  const [customTemplateBody, setCustomTemplateBody] = useState('');
  const [analysisOutput, setAnalysisOutput] = useState('');
  const [bulkCaseCodes, setBulkCaseCodes] = useState('');
  const [bulkRunning, setBulkRunning] = useState(false);
  const [bulkProgress, setBulkProgress] = useState(0);
  const [bulkTotal, setBulkTotal] = useState(0);
  const [comparisonOutput, setComparisonOutput] = useState('');
  const [compareHistoryId, setCompareHistoryId] = useState<number | null>(null);
  const [simpleAiMode, setSimpleAiMode] = useState(true);
  const [pageLoading, setPageLoading] = useState(false);
  const [pageLoadingMessage, setPageLoadingMessage] = useState('');
  
  // Version chain dialog
  const [versionChainDialogOpen, setVersionChainDialogOpen] = useState(false);
  const [versionChainData, setVersionChainData] = useState<DocumentVersionChainDto | null>(null);
  const [versionChainLoading, setVersionChainLoading] = useState(false);
  const [restoreInProgress, setRestoreInProgress] = useState<number | null>(null);
  const previewTabIndex = 1;
  const metadataTabIndex = simpleAiMode ? -1 : 2;
  const advancedTabIndex = simpleAiMode ? -1 : 3;

  const culture = (i18n.resolvedLanguage || i18n.language || 'en').startsWith('ar') ? 'ar-SA' : 'en-US';
  const steps = [
    t('documentGeneration.detailsTab', { defaultValue: 'Details' }),
    t('documentGeneration.contentTab', { defaultValue: 'Content' }),
    t('documentGeneration.metadataTab', { defaultValue: 'Metadata' }),
    t('documentGeneration.previewTitle', { defaultValue: 'Preview' }),
  ];

  function escapeHtml(value: string): string {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function toEditorHtml(value: string): string {
    const trimmed = (value || '').trim();
    if (!trimmed) {
      return '';
    }

    if (/<[a-z][\s\S]*>/i.test(trimmed)) {
      return value;
    }

    return value
      .split(/\r?\n/)
      .map((line) => (line.trim().length ? `<p>${escapeHtml(line)}</p>` : '<p><br/></p>'))
      .join('');
  }

  function toPlainText(value: string): string {
    if (!value) {
      return '';
    }

    if (typeof window === 'undefined') {
      return value.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
    }

    const container = document.createElement('div');
    container.innerHTML = value;
    return (container.textContent || container.innerText || '').replace(/\u00A0/g, ' ').trim();
  }

  useEffect(() => {
    (async () => {
      try {
        const response = await api.get('/DocumentGeneration/templates', { params: { culture } });
        const loadedTemplates = response.data || [];
        setTemplates(loadedTemplates);
        setTemplateType((current) => (
          loadedTemplates.length > 0 && !loadedTemplates.some((tpl: Template) => tpl.key === current)
            ? loadedTemplates[0].key
            : current
        ));
      } catch (err: any) {
        setError(err?.response?.data?.message || t('documentGeneration.failedLoadTemplates'));
      }
    })();
  }, [culture, t]);

  useEffect(() => {
    (async () => {
      try {
        const response = await api.get('/DocumentGeneration/clauses', { params: { culture } });
        setClauses(response.data || []);
      } catch {
        setClauses([]);
      }
    })();
  }, [culture]);

  useEffect(() => {
    try {
      const raw = localStorage.getItem('documentGeneration.customTemplates');
      if (!raw) {
        return;
      }

      const parsed = JSON.parse(raw) as CustomTemplate[];
      if (Array.isArray(parsed)) {
        setCustomTemplates(parsed);
      }
    } catch {
      setCustomTemplates([]);
    }
  }, []);

  useEffect(() => {
    localStorage.setItem('documentGeneration.customTemplates', JSON.stringify(customTemplates));
  }, [customTemplates]);

  useEffect(() => {
    if (successMessage) {
      setSnackbarMessage(successMessage);
      setSnackbarSeverity('success');
      setSnackbarOpen(true);
    }
  }, [successMessage]);

  useEffect(() => {
    if (error) {
      setSnackbarMessage(error);
      setSnackbarSeverity('error');
      setSnackbarOpen(true);
    }
  }, [error]);

  // Load history when History tab is opened
  useEffect(() => {
    if (mainTab === 1) {
      loadHistory();
    }
  }, [mainTab]);

  // Load drafts when Drafts tab is opened
  useEffect(() => {
    if (mainTab === 2) {
      loadDrafts();
    }
  }, [mainTab]);

  useEffect(() => {
    if (simpleAiMode && activeTab > previewTabIndex) {
      setActiveTab(previewTabIndex);
    }
  }, [simpleAiMode, activeTab, previewTabIndex]);

  async function loadHistory() {
    setHistoryLoading(true);
    try {
      const response = await api.get('/DocumentGeneration/history', {
        params: { caseCode: caseCode || undefined, limit: 50 }
      });
      setHistory(response.data || []);
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedLoadHistory', { defaultValue: 'Failed to load history.' }));
    } finally {
      setHistoryLoading(false);
    }
  }

  async function loadDrafts() {
    setDraftsLoading(true);
    try {
      const response = await api.get('/DocumentGeneration/drafts');
      setDrafts(response.data || []);
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedLoadDrafts', { defaultValue: 'Failed to load drafts.' }));
    } finally {
      setDraftsLoading(false);
    }
  }

  async function viewHistoryDocument(id: number) {
    try {
      const response = await api.get(`/DocumentGeneration/history/${id}/content`);
      const content = response.data?.content || '';
      setPreviewContent(toEditorHtml(content));
      setBranding(response.data?.branding || { firmName: '', address: '', contactInfo: '', footerText: '', signatureBlock: '' });
      setParties(response.data?.parties?.length ? response.data.parties : [{ name: '', role: 'Client', contactInfo: '' }]);
      setSelectedClauseKeys(response.data?.clauseKeys || []);
      setMainTab(0); // Switch to Generator tab to view
      setWorkflowStep(3);
      setSuccessMessage(t('documentGeneration.historyLoaded', { defaultValue: 'Document loaded from history.' }));
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedLoadHistoryContent', { defaultValue: 'Failed to load document content.' }));
    }
  }

  async function downloadHistoryDocument(id: number) {
    try {
      const histItem = history.find(h => h.id === id);
      if (!histItem) return;
      
      const response = await api.get(`/DocumentGeneration/history/${id}/content`);
      const content = response.data?.content || '';
      
      const blob = new Blob([content], { type: 'text/plain' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${histItem.documentTitle}.${histItem.format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
      
      setSuccessMessage(t('documentGeneration.downloaded', { defaultValue: 'Document downloaded successfully!' }));
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedDownload', { defaultValue: 'Failed to download document.' }));
    }
  }

  async function loadVersionChain(id: number) {
    setVersionChainLoading(true);
    setVersionChainDialogOpen(true);
    try {
      const response = await api.get(`/DocumentGeneration/history/${id}/versions`);
      setVersionChainData(response.data);
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedLoadVersions', { defaultValue: 'Failed to load version chain.' }));
      setVersionChainDialogOpen(false);
    } finally {
      setVersionChainLoading(false);
    }
  }

  async function restoreVersion(id: number) {
    if (!confirm(t('documentGeneration.confirmRestore', { defaultValue: 'Restore this version as the current version?' }))) {
      return;
    }
    setRestoreInProgress(id);
    try {
      await api.post(`/DocumentGeneration/history/${id}/restore`);
      setSuccessMessage(t('documentGeneration.versionRestored', { defaultValue: 'Version restored successfully!' }));
      await loadHistory();
      if (versionChainData?.rootDocumentId) {
        await loadVersionChain(versionChainData.rootDocumentId);
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedRestore', { defaultValue: 'Failed to restore version.' }));
    } finally {
      setRestoreInProgress(null);
    }
  }

  async function loadDraft(draft: DocumentDraft) {
    setTemplateType(draft.templateType);
    setCaseCode(draft.caseCode?.toString() || '');
    setFormat(draft.format as 'txt' | 'pdf' | 'docx');
    setScope(draft.scope || '');
    setFeeTerms(draft.feeTerms || '');
    setSubject(draft.subject || '');
    setStatement(draft.statement || '');
    setAiInstructions(draft.aiInstructions || '');
    setPreviewContent(toEditorHtml(draft.previewContent || ''));
    setDocumentTitle(draft.documentTitle || '');
    setDocumentReference(draft.documentReference || '');
    setDocumentCategory(draft.documentCategory || '');
    setDocumentNotes(draft.documentNotes || '');
    setBranding(draft.branding || { firmName: '', address: '', contactInfo: '', footerText: '', signatureBlock: '' });
    setParties(draft.parties?.length ? draft.parties : [{ name: '', role: 'Client', contactInfo: '' }]);
    setSelectedClauseKeys(draft.clauseKeys || []);
    setCurrentDraftId(draft.id);
    setMainTab(0); // Switch to Generator tab
    setWorkflowStep(3);
    setSuccessMessage(t('documentGeneration.draftLoaded', { defaultValue: 'Draft loaded successfully!' }));
  }

  async function saveDraft() {
    setError('');
    setSaving(true);
    try {
      const draftName = documentTitle || `${templateType}-${new Date().toISOString().split('T')[0]}`;
      const draftData = {
        draftName,
        templateType,
        caseCode: caseCode ? Number(caseCode) : null,
        customerId: customerId ? Number(customerId) : null,
        format,
        scope,
        feeTerms,
        subject,
        statement,
        aiInstructions,
        previewContent,
        documentTitle,
        documentReference,
        documentCategory,
        documentNotes,
        branding,
        parties: parties.filter((p) => p.name.trim()),
        clauseKeys: selectedClauseKeys,
      };

      if (currentDraftId) {
        await api.put(`/DocumentGeneration/drafts/${currentDraftId}`, draftData);
        setSuccessMessage(t('documentGeneration.draftUpdated', { defaultValue: 'Draft updated successfully!' }));
      } else {
        const response = await api.post('/DocumentGeneration/drafts', draftData);
        setCurrentDraftId(response.data?.id);
        setSuccessMessage(t('documentGeneration.draftSaved', { defaultValue: 'Draft saved successfully!' }));
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedSaveDraft', { defaultValue: 'Failed to save draft.' }));
    } finally {
      setSaving(false);
    }
  }

  async function deleteDraft(id: number) {
    if (!confirm(t('documentGeneration.confirmDeleteDraft', { defaultValue: 'Are you sure you want to delete this draft?' }))) {
      return;
    }
    
    try {
      await api.delete(`/DocumentGeneration/drafts/${id}`);
      setSuccessMessage(t('documentGeneration.draftDeleted', { defaultValue: 'Draft deleted successfully!' }));
      loadDrafts(); // Reload the list
      if (currentDraftId === id) {
        setCurrentDraftId(null);
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedDeleteDraft', { defaultValue: 'Failed to delete draft.' }));
    }
  }

  async function generateDraftWithAi() {
    setError('');
    setSuccessMessage('');
    setAiLoading(true);
    setPageLoading(true);
    setPageLoadingMessage(t('documentGeneration.loadingAiGeneration', { defaultValue: 'Generating draft...' }));
    try {
      const instructions = [
        aiInstructions.trim(),
        scope.trim() ? `${t('documentGeneration.scope', { defaultValue: 'Scope' })}: ${scope.trim()}` : '',
        feeTerms.trim() ? `${t('documentGeneration.feeTerms', { defaultValue: 'Fee Terms' })}: ${feeTerms.trim()}` : '',
        subject.trim() ? `${t('documentGeneration.subject', { defaultValue: 'Subject' })}: ${subject.trim()}` : '',
        statement.trim() ? `${t('documentGeneration.statement', { defaultValue: 'Statement/context' })}: ${statement.trim()}` : '',
      ]
        .filter(Boolean)
        .join('\n');

      const context = [
        caseCode.trim() ? `${t('documentGeneration.caseCode', { defaultValue: 'Case Code' })}: ${caseCode.trim()}` : '',
        customerId.trim() ? `${t('documentGeneration.customerId', { defaultValue: 'Customer ID' })}: ${customerId.trim()}` : '',
        `${t('documentGeneration.template', { defaultValue: 'Template' })}: ${templateType}`,
      ]
        .filter(Boolean)
        .join('\n');

      const response = await api.post('/AIAssistant/draft', {
        draftType: templateType,
        instructions: instructions || t('documentGeneration.aiDefaultInstructions', { defaultValue: 'Create a professional legal draft.' }),
        context,
        language: culture.startsWith('ar') ? 'ar' : 'en',
      });

      const draftText = response.data?.draftText || '';
      const usedAiModel = Boolean(response.data?.usedAiModel);
      if (usedAiModel) {
        setPreviewContent(toEditorHtml(draftText));
      } else {
        // If AI is unavailable, fall back to the actual template renderer (better than generic fallback prose).
        const previewResponse = await api.post('/DocumentGeneration/template-preview', {
          templateType,
          caseCode: caseCode ? Number(caseCode) : null,
          customerId: customerId ? Number(customerId) : null,
          culture,
          variables: {
            Scope: scope,
            FeeTerms: feeTerms,
            Subject: subject,
            Statement: statement,
          },
          branding,
          parties: parties.filter((p) => p.name.trim()),
          clauseKeys: selectedClauseKeys,
        });
        setPreviewContent(toEditorHtml(previewResponse.data?.content || draftText));
      }
      setActiveTab(previewTabIndex); // Switch to preview tab
      setWorkflowStep(3);
      if (usedAiModel) {
        setSuccessMessage(t('documentGeneration.aiGeneratedToPreview', { defaultValue: 'AI draft generated and loaded in preview.' }));
      } else {
        setError(t('documentGeneration.aiContactAdmin', { defaultValue: 'AI service is currently unavailable. Please contact your system administrator.' }));
      }
    } catch (err: any) {
      setError(
        err?.response?.data?.message ||
        t('documentGeneration.aiContactAdmin', { defaultValue: 'AI service is currently unavailable. Please contact your system administrator.' })
      );
    } finally {
      setAiLoading(false);
      setPageLoading(false);
      setPageLoadingMessage('');
    }
  }

  async function previewTemplate() {
    setError('');
    setSuccessMessage('');
    setPageLoading(true);
    setPageLoadingMessage(t('documentGeneration.loadingPreview', { defaultValue: 'Loading preview...' }));
    try {
      const response = await api.post('/DocumentGeneration/template-preview', {
        templateType,
        caseCode: caseCode ? Number(caseCode) : null,
        customerId: customerId ? Number(customerId) : null,
        culture,
        variables: {
          Scope: scope,
          FeeTerms: feeTerms,
          Subject: subject,
          Statement: statement,
        },
        branding,
        parties: parties.filter((p) => p.name.trim()),
        clauseKeys: selectedClauseKeys,
      });

      setPreviewContent(toEditorHtml(response.data?.content || ''));
      setActiveTab(previewTabIndex);
      setWorkflowStep(3);
      setSuccessMessage(t('documentGeneration.previewLoaded', { defaultValue: 'Template preview loaded.' }));
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedGenerate'));
    } finally {
      setPageLoading(false);
      setPageLoadingMessage('');
    }
  }

  function saveCustomTemplate() {
    setError('');
    if (!customTemplateName.trim() || !customTemplateBody.trim()) {
      setError(t('documentGeneration.customTemplateRequired', { defaultValue: 'Template name and body are required.' }));
      return;
    }

    const next: CustomTemplate = {
      id: crypto.randomUUID(),
      name: customTemplateName.trim(),
      body: customTemplateBody.trim(),
    };
    setCustomTemplates((prev) => [next, ...prev]);
    setCustomTemplateName('');
    setCustomTemplateBody('');
    setSuccessMessage(t('documentGeneration.customTemplateSaved', { defaultValue: 'Custom template saved.' }));
  }

  function applyCustomTemplate(template: CustomTemplate) {
    setPreviewContent(toEditorHtml(template.body));
    setDocumentTitle((prev) => prev || template.name);
    setSuccessMessage(t('documentGeneration.customTemplateApplied', { defaultValue: 'Custom template applied to preview.' }));
  }

  function deleteCustomTemplate(id: string) {
    setCustomTemplates((prev) => prev.filter((t) => t.id !== id));
  }

  async function runBulkGeneration() {
    setError('');
    setSuccessMessage('');
    const caseList = bulkCaseCodes
      .split(',')
      .map((x) => x.trim())
      .filter(Boolean)
      .map((x) => Number(x))
      .filter((x) => Number.isFinite(x) && x > 0);

    if (caseList.length === 0) {
      setError(t('documentGeneration.bulkCasesRequired', { defaultValue: 'Enter at least one valid case code.' }));
      return;
    }

    setBulkRunning(true);
    setBulkProgress(0);
    setBulkTotal(caseList.length);
    let done = 0;

    try {
      for (const code of caseList) {
        const previewPlainText = toPlainText(previewContent);
        const requestData = {
          templateType,
          caseCode: code,
          customerId: customerId ? Number(customerId) : null,
          format,
          culture,
          generatedContent: previewPlainText || undefined,
          variables: {
            Scope: scope,
            FeeTerms: feeTerms,
            Subject: subject,
            Statement: statement,
          },
          branding,
          parties: parties.filter((p) => p.name.trim()),
          clauseKeys: selectedClauseKeys,
          saveToCase,
          documentTitle: documentTitle || `${templateType}-${code}`,
          documentReference,
          documentCategory,
          documentNotes,
        };

        await api.post('/DocumentGeneration/generate', requestData, saveToCase ? {} : { responseType: 'blob' });
        done += 1;
        setBulkProgress(done);
      }

      setSuccessMessage(t('documentGeneration.bulkDone', { defaultValue: 'Bulk generation completed.' }));
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.bulkFailed', { defaultValue: 'Bulk generation failed.' }));
    } finally {
      setBulkRunning(false);
    }
  }

  function analyzeDraft() {
    const previewPlainText = toPlainText(previewContent);
    if (!previewPlainText.trim()) {
      setError(t('documentGeneration.previewRequired', { defaultValue: 'Generate and review content before saving.' }));
      return;
    }

    const lines = previewPlainText.split('\n').map((l) => l.trim()).filter(Boolean);
    const unresolvedVariables = (previewPlainText.match(/{{[^}]+}}/g) || []).length;
    const words = previewPlainText.split(/\s+/).filter(Boolean).length;
    const hasSignature = /signature|توقيع/i.test(previewPlainText);
    const hasDate = /\d{4}-\d{2}-\d{2}/.test(previewPlainText) || /date|التاريخ/i.test(previewPlainText);

    const result = [
      `Word count: ${words}`,
      `Paragraphs: ${lines.length}`,
      `Unresolved placeholders: ${unresolvedVariables}`,
      `Contains signature section: ${hasSignature ? 'Yes' : 'No'}`,
      `Contains date section: ${hasDate ? 'Yes' : 'No'}`,
      unresolvedVariables > 0 ? 'Action: Resolve all template placeholders before export.' : 'Action: Placeholder validation passed.',
    ].join('\n');

    setAnalysisOutput(result);
  }

  async function compareWithHistory(id: number) {
    try {
      const response = await api.get(`/DocumentGeneration/history/${id}/content`);
      const base = (response.data?.content || '') as string;
      const currentLines = toPlainText(previewContent).split('\n');
      const baseLines = base.split('\n');
      const max = Math.max(currentLines.length, baseLines.length);
      const out: string[] = [];

      for (let i = 0; i < max; i += 1) {
        const a = baseLines[i] ?? '';
        const b = currentLines[i] ?? '';
        if (a === b) {
          continue;
        }

        if (a) {
          out.push(`- ${a}`);
        }
        if (b) {
          out.push(`+ ${b}`);
        }
      }

      setComparisonOutput(out.length ? out.join('\n') : t('documentGeneration.noDiff', { defaultValue: 'No differences found.' }));
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.compareFailed', { defaultValue: 'Failed to compare documents.' }));
    }
  }

  function printPreview() {
    const previewPlainText = toPlainText(previewContent);
    if (!previewPlainText.trim()) {
      setError(t('documentGeneration.previewRequired', { defaultValue: 'Generate and review content before saving.' }));
      return;
    }

    const printWindow = window.open('', '_blank', 'width=900,height=700');
    if (!printWindow) {
      setError(t('documentGeneration.failedPrint', { defaultValue: 'Could not open print window.' }));
      return;
    }

    const escaped = previewPlainText
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');

    printWindow.document.write(`
      <html>
        <head>
          <title>${documentTitle || templateType}</title>
          <style>
            @page { margin: 18mm; }
            body { font-family: "Times New Roman", serif; color: #111; font-size: 12pt; line-height: 1.6; }
            pre { white-space: pre-wrap; word-wrap: break-word; font-family: inherit; margin: 0; }
          </style>
        </head>
        <body>
          <pre>${escaped}</pre>
        </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
  }

  async function saveAndDownload() {
    setError('');
    setSuccessMessage('');
    const previewPlainText = toPlainText(previewContent);
    if (!previewPlainText.trim()) {
      setError(t('documentGeneration.previewRequired', { defaultValue: 'Generate and review content before saving.' }));
      return;
    }

    setSaving(true);
    setPageLoading(true);
    setPageLoadingMessage(t('documentGeneration.loadingSave', { defaultValue: 'Saving document...' }));
    try {
      const requestData = {
        templateType,
        caseCode: caseCode ? Number(caseCode) : null,
        customerId: customerId ? Number(customerId) : null,
        format,
        culture,
        generatedContent: previewPlainText,
        variables: {
          Scope: scope,
          FeeTerms: feeTerms,
          Subject: subject,
          Statement: statement,
        },
        branding,
        parties: parties.filter((p) => p.name.trim()),
        clauseKeys: selectedClauseKeys,
        saveToCase,
        documentTitle: documentTitle || templateType,
        documentReference,
        documentCategory,
        documentNotes,
      };

      const response = await api.post('/DocumentGeneration/generate', requestData, 
        saveToCase ? {} : { responseType: 'blob' }
      );

      if (saveToCase) {
        // Response is JSON with file ID
        setSuccessMessage(t('documentGeneration.savedToCase', { defaultValue: 'Document saved to case successfully!' }));
        // Clear form after successful save
        setPreviewContent('');
        setActiveTab(0);
      } else {
        // Response is blob for download
        const url = window.URL.createObjectURL(response.data);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${documentTitle || templateType}.${format}`;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
        setSuccessMessage(t('documentGeneration.downloaded', { defaultValue: 'Document downloaded successfully!' }));
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || t('documentGeneration.failedGenerate'));
    } finally {
      setSaving(false);
      setPageLoading(false);
      setPageLoadingMessage('');
    }
  }

  function getTemplateLabel(template: Template): string {
    const key = `documentGeneration.templates.${template.key}.name`;
    const localized = t(key);
    return localized === key ? (template.name || template.key) : localized;
  }

  return (
    <Box>
      <Backdrop
        open={pageLoading}
        sx={{ color: '#fff', zIndex: (theme) => theme.zIndex.drawer + 2000, flexDirection: 'column', gap: 1.5 }}
      >
        <CircularProgress color="inherit" />
        <Typography variant="body2">{pageLoadingMessage || t('documentGeneration.loading', { defaultValue: 'Loading...' })}</Typography>
      </Backdrop>

      <Snackbar
        open={snackbarOpen}
        autoHideDuration={4000}
        onClose={() => setSnackbarOpen(false)}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Alert onClose={() => setSnackbarOpen(false)} severity={snackbarSeverity} sx={{ width: '100%' }}>
          {snackbarMessage}
        </Alert>
      </Snackbar>

      <Typography variant="h4" sx={{ mb: 3 }}>
        {t('documentGeneration.title', { defaultValue: 'Generate Legal Document' })}
      </Typography>

      <Tabs value={mainTab} onChange={(_, newValue) => setMainTab(newValue)} sx={{ mb: 3, borderBottom: 1, borderColor: 'divider' }}>
        <Tab label={t('documentGeneration.generatorTab', { defaultValue: 'Generator' })} />
        <Tab label={t('documentGeneration.historyTab', { defaultValue: 'History' })} />
        <Tab label={t('documentGeneration.draftsTab', { defaultValue: 'Drafts' })} />
      </Tabs>

      {/* Generator Tab */}
      {mainTab === 0 && (
        <Card sx={{ borderRadius: 2, boxShadow: 2 }}>
          <Box sx={{ borderBottom: 1, borderColor: 'divider', display: 'flex', alignItems: 'center', justifyContent: 'space-between', px: 2 }}>
            <Tabs value={activeTab} onChange={(_, newValue) => setActiveTab(newValue)}>
              <Tab label={t('documentGeneration.contentTab', { defaultValue: 'Content' })} />
              <Tab label={t('documentGeneration.previewTitle', { defaultValue: 'Preview' })} />
              {!simpleAiMode && <Tab label={t('documentGeneration.metadataTab', { defaultValue: 'Metadata' })} />}
              {!simpleAiMode && <Tab label={t('documentGeneration.advancedFeatures', { defaultValue: 'Advanced' })} />}
            </Tabs>
            <Button
              size="small"
              onClick={() => setSimpleAiMode(!simpleAiMode)}
              startIcon={simpleAiMode ? <ExpandMore /> : <ExpandLess />}
              sx={{ mr: 1 }}
            >
              {simpleAiMode 
                ? t('documentGeneration.showAdvanced', { defaultValue: 'Advanced' })
                : t('documentGeneration.simpleMode', { defaultValue: 'Simple Mode' })}
            </Button>
          </Box>

          <CardContent sx={{ p: 3 }}>
            {/* Content Tab - Primary for AI generation */}
            {activeTab === 0 && (
              <Stack spacing={2.5}>
                <Grid container spacing={2}>
                  <Grid size={{ xs: 12, md: simpleAiMode ? 6 : 4 }}>
                    <SearchableSelect<string>
                      size="small"
                      label={t('documentGeneration.template')}
                      value={templateType}
                      onChange={(value) => setTemplateType(value ?? templates[0]?.key ?? '')}
                      options={templates.map((tpl) => ({ value: tpl.key, label: getTemplateLabel(tpl) }))}
                      disableClearable
                    />
                  </Grid>
                  <Grid size={{ xs: 12, md: simpleAiMode ? 6 : 4 }}>
                    <SearchableSelect<'txt' | 'pdf' | 'docx'>
                      size="small"
                      label={t('documentGeneration.format')}
                      value={format}
                      onChange={(value) => setFormat((value ?? 'docx') as 'txt' | 'pdf' | 'docx')}
                      options={[
                        { value: 'txt', label: t('documentGeneration.formats.txt') },
                        { value: 'pdf', label: t('documentGeneration.formats.pdf') },
                        { value: 'docx', label: t('documentGeneration.formats.docx', { defaultValue: 'DOCX' }) },
                      ]}
                      disableClearable
                    />
                  </Grid>
                  {!simpleAiMode && (
                    <>
                      <Grid size={{ xs: 12, md: 4 }}>
                        <TextField 
                          size="small" 
                          fullWidth
                          label={t('documentGeneration.caseCode')} 
                          value={caseCode} 
                          onChange={(e) => setCaseCode(e.target.value)}
                          type="number"
                        />
                      </Grid>
                      <Grid size={{ xs: 12, md: 6 }}>
                        <TextField 
                          size="small" 
                          fullWidth
                          label={t('documentGeneration.customerId')} 
                          value={customerId} 
                          onChange={(e) => setCustomerId(e.target.value)}
                          type="number"
                        />
                      </Grid>
                    </>
                  )}
                </Grid>

                <TextField 
                  size="small" 
                  fullWidth
                  label={t('documentGeneration.aiInstructions', { defaultValue: 'AI instructions' })}
                  value={aiInstructions}
                  onChange={(e) => setAiInstructions(e.target.value)}
                  multiline
                  minRows={3}
                  placeholder={t('documentGeneration.aiInstructionsPlaceholder', { defaultValue: 'Describe what you want the AI to generate...' })}
                />

                {simpleAiMode && (
                  <>
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.subject')} 
                      value={subject} 
                      onChange={(e) => setSubject(e.target.value)} 
                    />
                    
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.statement')} 
                      value={statement} 
                      onChange={(e) => setStatement(e.target.value)} 
                      multiline 
                      minRows={3} 
                    />
                  </>
                )}

                <Stack direction="row" spacing={1}>
                  <Button 
                    variant="contained" 
                    onClick={() => void generateDraftWithAi()} 
                    disabled={aiLoading}
                    sx={{ borderRadius: 2 }}
                  >
                    {aiLoading ? <CircularProgress size={18} color="inherit" /> : t('documentGeneration.generateWithAi', { defaultValue: 'Generate With AI' })}
                  </Button>
                  
                  <Button 
                    variant="outlined" 
                    onClick={() => void previewTemplate()}
                    sx={{ borderRadius: 2 }}
                  >
                    {t('documentGeneration.previewTemplate', { defaultValue: 'Preview Template' })}
                  </Button>
                </Stack>

                {!simpleAiMode && (
                  <>
                    <Divider sx={{ my: 1 }} />
                    
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.subject')} 
                      value={subject} 
                      onChange={(e) => setSubject(e.target.value)} 
                    />
                    
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.scope')} 
                      value={scope} 
                      onChange={(e) => setScope(e.target.value)} 
                      multiline 
                      minRows={3} 
                    />
                    
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.feeTerms')} 
                      value={feeTerms} 
                      onChange={(e) => setFeeTerms(e.target.value)} 
                      multiline 
                      minRows={2} 
                    />
                    
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.statement')} 
                      value={statement} 
                      onChange={(e) => setStatement(e.target.value)} 
                      multiline 
                      minRows={4} 
                    />

                    <Divider sx={{ my: 1 }} />

                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {t('documentGeneration.clauses', { defaultValue: 'Clause Library' })}
                    </Typography>
                    
                    <TextField
                      select
                      size="small"
                      fullWidth
                      label={t('documentGeneration.selectedClauses', { defaultValue: 'Select Clauses' })}
                      SelectProps={{ native: true, multiple: true }}
                      value={selectedClauseKeys}
                      onChange={(e) => {
                        const target = e.target as unknown as HTMLSelectElement;
                        const values = Array.from(target.selectedOptions).map((option) => option.value);
                        setSelectedClauseKeys(values);
                      }}
                    >
                      {clauses.map((clause) => (
                        <option key={clause.key} value={clause.key}>
                          {clause.text}
                        </option>
                      ))}
                    </TextField>
                  </>
                )}
              </Stack>
            )}

            {/* Metadata Tab */}
            {activeTab === metadataTabIndex && (
              <Stack spacing={2.5}>
                <Grid container spacing={2}>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.documentTitle', { defaultValue: 'Document Title' })}
                      value={documentTitle} 
                      onChange={(e) => setDocumentTitle(e.target.value)}
                      placeholder={templateType}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.documentReference', { defaultValue: 'Reference Number' })}
                      value={documentReference} 
                      onChange={(e) => setDocumentReference(e.target.value)}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <TextField 
                      size="small" 
                      fullWidth
                      label={t('documentGeneration.documentCategory', { defaultValue: 'Category' })}
                      value={documentCategory} 
                      onChange={(e) => setDocumentCategory(e.target.value)}
                    />
                  </Grid>
                </Grid>
                
                <TextField 
                  size="small" 
                  fullWidth
                  label={t('documentGeneration.documentNotes', { defaultValue: 'Notes' })}
                  value={documentNotes} 
                  onChange={(e) => setDocumentNotes(e.target.value)}
                  multiline
                  minRows={3}
                />

                <Divider sx={{ my: 1 }} />
                
                <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                  {t('documentGeneration.branding', { defaultValue: 'Firm Branding & Letterhead' })}
                </Typography>

                <Grid container spacing={2}>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <TextField
                      size="small"
                      fullWidth
                      label={t('documentGeneration.firmName', { defaultValue: 'Firm Name' })}
                      value={branding.firmName}
                      onChange={(e) => setBranding((prev) => ({ ...prev, firmName: e.target.value }))}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <TextField
                      size="small"
                      fullWidth
                      label={t('documentGeneration.firmContactInfo', { defaultValue: 'Contact Info' })}
                      value={branding.contactInfo}
                      onChange={(e) => setBranding((prev) => ({ ...prev, contactInfo: e.target.value }))}
                    />
                  </Grid>
                </Grid>
                
                <TextField
                  size="small"
                  fullWidth
                  label={t('documentGeneration.firmAddress', { defaultValue: 'Address' })}
                  value={branding.address}
                  onChange={(e) => setBranding((prev) => ({ ...prev, address: e.target.value }))}
                  multiline
                  minRows={2}
                />
                
                <Grid container spacing={2}>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <TextField
                      size="small"
                      fullWidth
                      label={t('documentGeneration.footerText', { defaultValue: 'Footer Text' })}
                      value={branding.footerText}
                      onChange={(e) => setBranding((prev) => ({ ...prev, footerText: e.target.value }))}
                    />
                  </Grid>
                  <Grid size={{ xs: 12, md: 6 }}>
                    <TextField
                      size="small"
                      fullWidth
                      label={t('documentGeneration.signatureBlock', { defaultValue: 'Signature Block' })}
                      value={branding.signatureBlock}
                      onChange={(e) => setBranding((prev) => ({ ...prev, signatureBlock: e.target.value }))}
                    />
                  </Grid>
                </Grid>

                <Divider sx={{ my: 1 }} />
                
                <FormControlLabel
                  control={
                    <Checkbox 
                      checked={saveToCase} 
                      onChange={(e) => setSaveToCase(e.target.checked)}
                      disabled={!caseCode}
                    />
                  }
                  label={t('documentGeneration.saveToCase', { defaultValue: 'Save to case file' })}
                />
                
                <Typography variant="caption" color="text.secondary">
                  {t('documentGeneration.saveToCaseHint', { defaultValue: 'When enabled, the document will be saved to the case files instead of downloaded.' })}
                </Typography>
              </Stack>
            )}

            {/* Preview Tab */}
            {activeTab === previewTabIndex && (
              <Stack spacing={2.5}>
                <Typography variant="body2" color="text.secondary">
                  {t('documentGeneration.previewHint', { defaultValue: 'Review and edit the generated content before saving.' })}
                </Typography>

                <HtmlEditor
                  value={previewContent}
                  onChange={setPreviewContent}
                  minHeight={previewContent.trim() ? 420 : 300}
                  placeholder={t('documentGeneration.previewPlaceholder', { defaultValue: 'Generated content will appear here...' })}
                />

                <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                  <Button 
                    variant="contained" 
                    color="success" 
                    onClick={() => void saveAndDownload()} 
                    disabled={saving || !toPlainText(previewContent).trim()}
                    sx={{ borderRadius: 2 }}
                  >
                    {saving ? (
                      <CircularProgress size={18} color="inherit" />
                    ) : saveToCase ? (
                      t('documentGeneration.saveToCaseButton', { defaultValue: 'Save to Case' })
                    ) : (
                      t('documentGeneration.saveAndDownload', { defaultValue: 'Save & Download' })
                    )}
                  </Button>

                  <Button
                    variant="outlined"
                    onClick={() => void saveDraft()}
                    disabled={saving}
                    sx={{ borderRadius: 2 }}
                  >
                    {t('documentGeneration.saveDraft', { defaultValue: 'Save as Draft' })}
                  </Button>

                  <Button
                    variant="outlined"
                    startIcon={<Print />}
                    onClick={printPreview}
                    disabled={!toPlainText(previewContent).trim()}
                    sx={{ borderRadius: 2 }}
                  >
                    {t('documentGeneration.print', { defaultValue: 'Print' })}
                  </Button>
                </Stack>
              </Stack>
            )}

            {/* Advanced Tab */}
            {activeTab === advancedTabIndex && (
              <Grid container spacing={2}>
                <Grid size={{ xs: 12, md: 6 }}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'action.hover', borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
                    <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 600 }}>
                      {t('documentGeneration.aiAnalysis', { defaultValue: 'AI Document Analysis (Quick)' })}
                    </Typography>
                  
                    <Button 
                      variant="outlined" 
                      onClick={analyzeDraft}
                      size="small"
                      sx={{ mb: 1.5, borderRadius: 2 }}
                    >
                      {t('documentGeneration.analyze', { defaultValue: 'Analyze Draft' })}
                    </Button>
                    
                    <TextField
                      value={analysisOutput}
                      multiline
                      minRows={4}
                      fullWidth
                      placeholder={t('documentGeneration.analysisPlaceholder', { defaultValue: 'Analysis output will appear here...' })}
                      size="small"
                      sx={{ '& .MuiInputBase-root': { borderRadius: 2 } }}
                    />
                  </Paper>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'action.hover', borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
                    <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 600 }}>
                      {t('documentGeneration.documentComparison', { defaultValue: 'Document Comparison' })}
                    </Typography>
                    
                    <SearchableSelect<number>
                      size="small"
                      label={t('documentGeneration.compareWithHistory', { defaultValue: 'Compare with history item' })}
                      value={(compareHistoryId ?? undefined) as number | undefined}
                      onChange={(value) => {
                        if (value) {
                          setCompareHistoryId(value);
                          void compareWithHistory(value);
                        }
                      }}
                      options={history.map((h) => ({
                        value: h.id,
                        label: `${h.id} - ${h.documentTitle || h.templateType}`,
                      }))}
                      sx={{ mb: 1.5 }}
                    />
                    
                    <TextField
                      value={comparisonOutput}
                      multiline
                      minRows={4}
                      fullWidth
                      placeholder={t('documentGeneration.comparePlaceholder', { defaultValue: 'Comparison output (- removed / + added)...' })}
                      size="small"
                      sx={{ '& .MuiInputBase-root': { fontFamily: 'monospace', borderRadius: 2 } }}
                    />
                  </Paper>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'action.hover', borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
                    <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 600 }}>
                      {t('documentGeneration.customTemplateBuilder', { defaultValue: 'Custom Template Builder' })}
                    </Typography>
                    
                    <TextField
                      size="small"
                      fullWidth
                      label={t('documentGeneration.templateName', { defaultValue: 'Template Name' })}
                      value={customTemplateName}
                      onChange={(e) => setCustomTemplateName(e.target.value)}
                      sx={{ mb: 1.5, '& .MuiInputBase-root': { borderRadius: 2 } }}
                    />
                    
                    <TextField
                      label={t('documentGeneration.templateBody', { defaultValue: 'Template Body' })}
                      value={customTemplateBody}
                      onChange={(e) => setCustomTemplateBody(e.target.value)}
                      multiline
                      minRows={4}
                      fullWidth
                      placeholder="{{CustomerName}} ... {{CaseCode}}"
                      size="small"
                      sx={{ mb: 1.5, '& .MuiInputBase-root': { borderRadius: 2 } }}
                    />
                    
                    <Button 
                      variant="outlined" 
                      onClick={saveCustomTemplate}
                      size="small"
                      sx={{ borderRadius: 2 }}
                    >
                      {t('documentGeneration.saveCustomTemplate', { defaultValue: 'Save Custom Template' })}
                    </Button>

                    {customTemplates.map((ct) => (
                      <Paper key={ct.id} elevation={0} sx={{ p: 1.5, mt: 1.5, bgcolor: 'background.default', borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
                        <Stack direction="row" justifyContent="space-between" alignItems="center">
                          <Typography variant="body2">{ct.name}</Typography>
                          <Stack direction="row" spacing={1}>
                            <Button size="small" onClick={() => applyCustomTemplate(ct)}>
                              {t('documentGeneration.apply', { defaultValue: 'Apply' })}
                            </Button>
                            <Button size="small" color="error" onClick={() => deleteCustomTemplate(ct.id)}>
                              {t('documentGeneration.delete', { defaultValue: 'Delete' })}
                            </Button>
                          </Stack>
                        </Stack>
                      </Paper>
                    ))}
                  </Paper>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                  <Paper elevation={0} sx={{ p: 2, bgcolor: 'action.hover', borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
                    <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 600 }}>
                      {t('documentGeneration.bulkGeneration', { defaultValue: 'Bulk Generation' })}
                    </Typography>
                    
                    <TextField
                      size="small"
                      fullWidth
                      label={t('documentGeneration.caseCodes', { defaultValue: 'Case Codes (comma separated)' })}
                      value={bulkCaseCodes}
                      onChange={(e) => setBulkCaseCodes(e.target.value)}
                      placeholder="101, 102, 103"
                      sx={{ mb: 1.5, '& .MuiInputBase-root': { borderRadius: 2 } }}
                    />
                    
                    {bulkRunning && (
                      <Box sx={{ mb: 1.5 }}>
                        <Typography variant="body2" sx={{ mb: 0.5 }}>
                          {t('documentGeneration.bulkProgress', { defaultValue: 'Bulk Progress' })}: {bulkProgress}/{bulkTotal}
                        </Typography>
                        <LinearProgress variant="determinate" value={bulkTotal > 0 ? (bulkProgress / bulkTotal) * 100 : 0} sx={{ borderRadius: 2 }} />
                      </Box>
                    )}
                    
                    <Button 
                      variant="contained" 
                      onClick={() => void runBulkGeneration()} 
                      disabled={bulkRunning}
                      size="small"
                      sx={{ borderRadius: 2 }}
                    >
                      {bulkRunning
                        ? t('documentGeneration.running', { defaultValue: 'Running...' })
                        : t('documentGeneration.runBulkGeneration', { defaultValue: 'Run Bulk Generation' })}
                    </Button>
                  </Paper>
                </Grid>
              </Grid>
            )}
          </CardContent>
        </Card>
      )}

      {/* History Tab */}
      {mainTab === 1 && (
        <Card sx={{ borderRadius: 2, boxShadow: 2 }}>
          <CardContent sx={{ p: 3 }}>
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
              <Typography variant="h6" sx={{ fontWeight: 600, color: 'primary.main' }}>
                {t('documentGeneration.documentHistory', { defaultValue: 'Document History' })}
              </Typography>
              <Button variant="outlined" size="small" onClick={loadHistory} disabled={historyLoading} sx={{ borderRadius: 2 }}>
                {historyLoading ? <CircularProgress size={18} /> : t('documentGeneration.refresh', { defaultValue: 'Refresh' })}
              </Button>
            </Stack>

            <DataGrid
              rows={history}
              columns={[
                { field: 'id', headerName: 'ID', width: 70 },
                { 
                  field: 'documentTitle', 
                  headerName: t('documentGeneration.documentTitle', { defaultValue: 'Document Title' }), 
                  flex: 1,
                  minWidth: 200
                },
                { 
                  field: 'templateType', 
                  headerName: t('documentGeneration.template', { defaultValue: 'Template' }), 
                  width: 150
                },
                { 
                  field: 'caseCode', 
                  headerName: t('documentGeneration.caseCode', { defaultValue: 'Case Code' }), 
                  width: 100
                },
                { 
                  field: 'format', 
                  headerName: t('documentGeneration.format', { defaultValue: 'Format' }), 
                  width: 80
                },
                { 
                  field: 'documentCategory', 
                  headerName: t('documentGeneration.documentCategory', { defaultValue: 'Category' }), 
                  width: 130
                },
                { 
                  field: 'generatedAt', 
                  headerName: t('documentGeneration.generatedAt', { defaultValue: 'Generated At' }), 
                  width: 160,
                  valueFormatter: (params) => new Date(params as string).toLocaleString()
                },
                { 
                  field: 'version', 
                  headerName: t('documentGeneration.version', { defaultValue: 'Version' }), 
                  width: 80
                },
                {
                  field: 'actions',
                  type: 'actions',
                  headerName: t('documentGeneration.actions', { defaultValue: 'Actions' }),
                  width: 180,
                  getActions: (params) => [
                    <GridActionsCellItem
                      key="view"
                      icon={<Tooltip title={t('documentGeneration.view', { defaultValue: 'View' })}><Visibility /></Tooltip>}
                      label="View"
                      onClick={() => void viewHistoryDocument(params.row.id)}
                      showInMenu={false}
                    />,
                    <GridActionsCellItem
                      key="download"
                      icon={<Tooltip title={t('documentGeneration.download', { defaultValue: 'Download' })}><Download /></Tooltip>}
                      label="Download"
                      onClick={() => void downloadHistoryDocument(params.row.id)}
                      showInMenu={false}
                    />,
                    <GridActionsCellItem
                      key="versions"
                      icon={<Tooltip title={t('documentGeneration.viewVersions', { defaultValue: 'View Versions' })}><History /></Tooltip>}
                      label="View Versions"
                      onClick={() => void loadVersionChain(params.row.id)}
                      showInMenu={false}
                    />,
                  ],
                },
              ]}
              loading={historyLoading}
              autoHeight
              pageSizeOptions={[10, 25, 50]}
              initialState={{
                pagination: { paginationModel: { pageSize: 25 } },
              }}
            />
          </CardContent>
        </Card>
      )}

      {/* Drafts Tab */}
      {mainTab === 2 && (
        <Card sx={{ borderRadius: 2, boxShadow: 2 }}>
          <CardContent sx={{ p: 3 }}>
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
              <Typography variant="h6" sx={{ fontWeight: 600, color: 'primary.main' }}>
                {t('documentGeneration.savedDrafts', { defaultValue: 'Saved Drafts' })}
              </Typography>
              <Button variant="outlined" size="small" onClick={loadDrafts} disabled={draftsLoading} sx={{ borderRadius: 2 }}>
                {draftsLoading ? <CircularProgress size={18} /> : t('documentGeneration.refresh', { defaultValue: 'Refresh' })}
              </Button>
            </Stack>

            <DataGrid
              rows={drafts}
              columns={[
                { field: 'id', headerName: 'ID', width: 70 },
                { 
                  field: 'draftName', 
                  headerName: t('documentGeneration.draftName', { defaultValue: 'Draft Name' }), 
                  flex: 1,
                  minWidth: 200
                },
                { 
                  field: 'templateType', 
                  headerName: t('documentGeneration.template', { defaultValue: 'Template' }), 
                  width: 150
                },
                { 
                  field: 'caseCode', 
                  headerName: t('documentGeneration.caseCode', { defaultValue: 'Case Code' }), 
                  width: 100
                },
                { 
                  field: 'format', 
                  headerName: t('documentGeneration.format', { defaultValue: 'Format' }), 
                  width: 80
                },
                { 
                  field: 'createdAt', 
                  headerName: t('documentGeneration.createdAt', { defaultValue: 'Created' }), 
                  width: 160,
                  valueFormatter: (params) => new Date(params as string).toLocaleString()
                },
                { 
                  field: 'lastModifiedAt', 
                  headerName: t('documentGeneration.lastModifiedAt', { defaultValue: 'Last Modified' }), 
                  width: 160,
                  valueFormatter: (params) => params ? new Date(params as string).toLocaleString() : '-'
                },
                {
                  field: 'actions',
                  type: 'actions',
                  headerName: t('documentGeneration.actions', { defaultValue: 'Actions' }),
                  width: 120,
                  getActions: (params) => [
                    <GridActionsCellItem
                      key="load"
                      icon={<Tooltip title={t('documentGeneration.load', { defaultValue: 'Load' })}><Edit /></Tooltip>}
                      label="Load"
                      onClick={() => void loadDraft(params.row)}
                      showInMenu={false}
                    />,
                    <GridActionsCellItem
                      key="delete"
                      icon={<Tooltip title={t('documentGeneration.delete', { defaultValue: 'Delete' })}><Delete /></Tooltip>}
                      label="Delete"
                      onClick={() => void deleteDraft(params.row.id)}
                      showInMenu={false}
                    />,
                  ],
                },
              ]}
              loading={draftsLoading}
              autoHeight
              pageSizeOptions={[10, 25, 50]}
              initialState={{
                pagination: { paginationModel: { pageSize: 25 } },
              }}
            />
          </CardContent>
        </Card>
      )}

      {/* Version Chain Dialog */}
      <Dialog
        open={versionChainDialogOpen}
        onClose={() => setVersionChainDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box>
            {t('documentGeneration.versionChain', { defaultValue: 'Version Chain' })}
            {versionChainData && (
              <Chip
                label={`${t('documentGeneration.totalVersions', { defaultValue: 'Total Versions' })}: ${versionChainData.totalVersions}`}
                size="small"
                sx={{ ml: 2 }}
              />
            )}
          </Box>
          <IconButton onClick={() => setVersionChainDialogOpen(false)} size="small">
            <Close />
          </IconButton>
        </DialogTitle>
        <DialogContent dividers>
          {versionChainLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
              <CircularProgress />
            </Box>
          ) : versionChainData ? (
            <Box>
              <Typography variant="subtitle2" sx={{ mb: 2, color: 'text.secondary' }}>
                {versionChainData.title} ({versionChainData.templateType})
              </Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t('documentGeneration.version', { defaultValue: 'Version' })}</TableCell>
                    <TableCell>{t('documentGeneration.generatedBy', { defaultValue: 'Generated By' })}</TableCell>
                    <TableCell>{t('documentGeneration.generatedAt', { defaultValue: 'Generated At' })}</TableCell>
                    <TableCell align="center">{t('documentGeneration.currentVersion', { defaultValue: 'Current' })}</TableCell>
                    <TableCell align="center">{t('documentGeneration.actions', { defaultValue: 'Actions' })}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {versionChainData.versions.map((v) => (
                    <TableRow key={v.id} hover>
                      <TableCell>
                        <Typography fontWeight={v.isCurrent ? 'bold' : 'normal'}>
                          v{v.version}
                        </Typography>
                      </TableCell>
                      <TableCell>{v.generatedBy}</TableCell>
                      <TableCell>{new Date(v.generatedAt).toLocaleString()}</TableCell>
                      <TableCell align="center">
                        {v.isCurrent && (
                          <Chip
                            label={t('documentGeneration.currentVersion', { defaultValue: 'Current' })}
                            color="primary"
                            size="small"
                          />
                        )}
                      </TableCell>
                      <TableCell align="center">
                        {!v.isCurrent && (
                          <Tooltip title={t('documentGeneration.restoreVersion', { defaultValue: 'Restore' })}>
                            <IconButton
                              size="small"
                              onClick={() => void restoreVersion(v.id)}
                              disabled={restoreInProgress === v.id}
                            >
                              {restoreInProgress === v.id ? (
                                <CircularProgress size={18} />
                              ) : (
                                <Restore fontSize="small" />
                              )}
                            </IconButton>
                          </Tooltip>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </Box>
          ) : (
            <Typography color="text.secondary">{t('documentGeneration.failedLoadVersions', { defaultValue: 'Failed to load version chain.' })}</Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setVersionChainDialogOpen(false)}>
            {t('common.close', { defaultValue: 'Close' })}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
