"use client";

import React, { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import api from '../../src/services/api';
import { useTranslation } from 'react-i18next';
import SearchableSelect from '../../src/components/SearchableSelect';

type Template = { key: string; name: string; description: string };

export default function DocumentGenerationPage() {
  const { t } = useTranslation();
  const [templates, setTemplates] = useState<Template[]>([]);
  const [templateType, setTemplateType] = useState('power-of-attorney');
  const [caseCode, setCaseCode] = useState('');
  const [customerId, setCustomerId] = useState('');
  const [format, setFormat] = useState<'txt' | 'pdf'>('txt');
  const [scope, setScope] = useState('');
  const [feeTerms, setFeeTerms] = useState('');
  const [subject, setSubject] = useState('');
  const [statement, setStatement] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const response = await api.get('/DocumentGeneration/templates');
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
  }, []);

  async function generate() {
    setError('');
    try {
      const response = await api.post('/DocumentGeneration/generate', {
        templateType,
        caseCode: caseCode ? Number(caseCode) : null,
        customerId: customerId ? Number(customerId) : null,
        format,
        variables: {
          Scope: scope,
          FeeTerms: feeTerms,
          Subject: subject,
          Statement: statement,
        },
      }, { responseType: 'blob' });

      const url = window.URL.createObjectURL(response.data);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${templateType}.${format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (err: any) {
      const backendMessage = err?.response?.data?.message;
      if (backendMessage === 'Invalid template type') {
        setError(t('documentGeneration.invalidTemplateType'));
      } else {
        setError(backendMessage || t('documentGeneration.failedGenerate'));
      }
    }
  }

  function getTemplateLabel(template: Template): string {
    const key = `documentGeneration.templates.${template.key}.name`;
    const localized = t(key);
    return localized === key ? (template.name || template.key) : localized;
  }

  return (
    <Box>
      <Card>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>{t('documentGeneration.title')}</Typography>

          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

          <Stack spacing={2}>
            <SearchableSelect<string>
              size="small"
              label={t('documentGeneration.template')}
              value={templateType}
              onChange={(value) => setTemplateType(value ?? templates[0]?.key ?? '')}
              options={templates.map((tpl) => ({ value: tpl.key, label: getTemplateLabel(tpl) }))}
              disableClearable
            />

            <TextField size="small" label={t('documentGeneration.caseCode')} value={caseCode} onChange={(e) => setCaseCode(e.target.value)} />
            <TextField size="small" label={t('documentGeneration.customerId')} value={customerId} onChange={(e) => setCustomerId(e.target.value)} />

            <SearchableSelect<'txt' | 'pdf'>
              size="small"
              label={t('documentGeneration.format')}
              value={format}
              onChange={(value) => setFormat((value ?? 'txt') as 'txt' | 'pdf')}
              options={[
                { value: 'txt', label: t('documentGeneration.formats.txt') },
                { value: 'pdf', label: t('documentGeneration.formats.pdf') },
              ]}
              disableClearable
            />

            <TextField size="small" label={t('documentGeneration.scope')} value={scope} onChange={(e) => setScope(e.target.value)} multiline minRows={2} />
            <TextField size="small" label={t('documentGeneration.feeTerms')} value={feeTerms} onChange={(e) => setFeeTerms(e.target.value)} multiline minRows={2} />
            <TextField size="small" label={t('documentGeneration.subject')} value={subject} onChange={(e) => setSubject(e.target.value)} />
            <TextField size="small" label={t('documentGeneration.statement')} value={statement} onChange={(e) => setStatement(e.target.value)} multiline minRows={3} />

            <Button variant="contained" onClick={() => void generate()}>{t('documentGeneration.generate')}</Button>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
