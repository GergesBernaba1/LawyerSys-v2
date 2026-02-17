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

type Template = { key: string; name: string; description: string };

export default function DocumentGenerationPage() {
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
        setTemplates(response.data || []);
      } catch {
        setError('Failed to load templates');
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
      setError(err?.response?.data?.message || 'Failed to generate document');
    }
  }

  return (
    <Box>
      <Card>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>Generate Legal Document</Typography>

          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

          <Stack spacing={2}>
            <FormControl size="small">
              <InputLabel>Template</InputLabel>
              <Select value={templateType} label="Template" onChange={(e) => setTemplateType(String(e.target.value))}>
                {templates.map((t) => (
                  <MenuItem key={t.key} value={t.key}>{t.name}</MenuItem>
                ))}
              </Select>
            </FormControl>

            <TextField size="small" label="Case Code" value={caseCode} onChange={(e) => setCaseCode(e.target.value)} />
            <TextField size="small" label="Customer Id" value={customerId} onChange={(e) => setCustomerId(e.target.value)} />

            <FormControl size="small">
              <InputLabel>Format</InputLabel>
              <Select value={format} label="Format" onChange={(e) => setFormat(e.target.value as 'txt' | 'pdf')}>
                <MenuItem value="txt">TXT</MenuItem>
                <MenuItem value="pdf">PDF</MenuItem>
              </Select>
            </FormControl>

            <TextField size="small" label="Scope" value={scope} onChange={(e) => setScope(e.target.value)} multiline minRows={2} />
            <TextField size="small" label="Fee Terms" value={feeTerms} onChange={(e) => setFeeTerms(e.target.value)} multiline minRows={2} />
            <TextField size="small" label="Subject" value={subject} onChange={(e) => setSubject(e.target.value)} />
            <TextField size="small" label="Statement" value={statement} onChange={(e) => setStatement(e.target.value)} multiline minRows={3} />

            <Button variant="contained" onClick={() => void generate()}>Generate</Button>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
