"use client";

import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import { Gavel as GavelIcon, Download as DownloadIcon, Refresh as RefreshIcon } from "@mui/icons-material";
import api from "../../src/services/api";
import { useTranslation } from "react-i18next";

type CourtForm = { key: string; name: string; description: string };
type DeadlineRule = { key: string; name: string; description: string; offsetDays: number; anchor: string };
type CourtPack = {
  key: string;
  name: string;
  description: string;
  jurisdictionCode: string;
  forms: CourtForm[];
  deadlineRules: DeadlineRule[];
  filingChannels: string[];
};
type DeadlineItem = { ruleKey: string; name: string; dueDate: string; priority: "High" | "Medium" | "Low"; notes: string };
type FilingItem = {
  submissionId: string;
  packKey: string;
  formKey: string;
  filingChannel: string;
  caseCode?: number | null;
  courtId?: number | null;
  dueDate?: string | null;
  status: string;
  message: string;
  externalReference: string;
  submittedAt: string;
  lastStatusAt?: string | null;
  nextCheckAt?: string | null;
  notes?: string | null;
};

const today = () => new Date().toISOString().slice(0, 10);
const formatDate = (v?: string | null) => (!v ? "-" : new Date(v).toLocaleDateString());
const formatDateTime = (v?: string | null) => (!v ? "-" : new Date(v).toLocaleString());

export default function CourtAutomationPage() {
  const { t, i18n } = useTranslation();
  const language = useMemo(() => ((i18n.resolvedLanguage || i18n.language || "en").startsWith("ar") ? "ar" : "en"), [i18n.resolvedLanguage, i18n.language]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const [packs, setPacks] = useState<CourtPack[]>([]);
  const [packKey, setPackKey] = useState("");
  const [pack, setPack] = useState<CourtPack | null>(null);

  const [caseCode, setCaseCode] = useState("");
  const [customerId, setCustomerId] = useState("");
  const [triggerDate, setTriggerDate] = useState(today());
  const [hearingDate, setHearingDate] = useState("");
  const [deadlines, setDeadlines] = useState<DeadlineItem[]>([]);

  const [formKey, setFormKey] = useState("");
  const [format, setFormat] = useState<"txt" | "pdf">("pdf");
  const [subject, setSubject] = useState("");
  const [facts, setFacts] = useState("");
  const [requests, setRequests] = useState("");
  const [grounds, setGrounds] = useState("");
  const [reference, setReference] = useState("");
  const [scope, setScope] = useState("");

  const [filingChannel, setFilingChannel] = useState("");
  const [courtId, setCourtId] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [filingNotes, setFilingNotes] = useState("");
  const [filings, setFilings] = useState<FilingItem[]>([]);

  async function loadPacks() {
    setLoading(true);
    setError("");
    try {
      const res = await api.get("/CourtAutomation/packs", { params: { language } });
      const packItems: CourtPack[] = res.data || [];
      setPacks(packItems);
      if (!packKey && packItems.length > 0) {
        setPackKey(packItems[0].key);
      }
    } catch (err: any) {
      setError(err?.response?.data?.message || t("courtAutomation.failedLoadPacks"));
    } finally {
      setLoading(false);
    }
  }

  async function loadPackDetails(key: string) {
    if (!key) return;
    setError("");
    try {
      const [packRes, filingsRes] = await Promise.all([
        api.get(`/CourtAutomation/packs/${key}`, { params: { language } }),
        api.get("/CourtAutomation/filings", { params: { packKey: key, caseCode: caseCode ? Number(caseCode) : undefined } }),
      ]);
      const p: CourtPack = packRes.data;
      setPack(p || null);
      if (p?.forms?.length && (!formKey || !p.forms.some((f) => f.key === formKey))) {
        setFormKey(p.forms[0].key);
      }
      if (p?.filingChannels?.length && (!filingChannel || !p.filingChannels.includes(filingChannel))) {
        setFilingChannel(p.filingChannels[0]);
      }
      setFilings(filingsRes.data || []);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("courtAutomation.failedLoadPack"));
    }
  }

  async function calculateDeadlines() {
    if (!packKey) return;
    setError("");
    try {
      const res = await api.post("/CourtAutomation/calculate-deadlines", {
        packKey,
        caseCode: caseCode ? Number(caseCode) : null,
        triggerDate,
        hearingDate: hearingDate || null,
        language,
      });
      setDeadlines(res.data?.deadlines || []);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("courtAutomation.failedCalculate"));
    }
  }

  async function generateForm() {
    if (!packKey || !formKey) return;
    setError("");
    try {
      const payload = {
        packKey,
        formKey,
        caseCode: caseCode ? Number(caseCode) : null,
        customerId: customerId ? Number(customerId) : null,
        format,
        language,
        variables: {
          Subject: subject,
          Facts: facts,
          Requests: requests,
          Grounds: grounds,
          Reference: reference,
          Scope: scope,
        },
      };

      const response = await api.post("/CourtAutomation/generate-form", payload, { responseType: "blob" });
      const url = window.URL.createObjectURL(response.data);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${packKey}-${formKey}.${format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("courtAutomation.failedGenerate"));
    }
  }

  async function submitFiling() {
    if (!packKey || !formKey || !filingChannel) return;
    setError("");
    try {
      await api.post("/CourtAutomation/filings/submit", {
        packKey,
        formKey,
        filingChannel,
        caseCode: caseCode ? Number(caseCode) : null,
        courtId: courtId ? Number(courtId) : null,
        dueDate: dueDate || null,
        notes: filingNotes,
        language,
      });
      await loadPackDetails(packKey);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("courtAutomation.failedSubmit"));
    }
  }

  async function refreshSubmission(submissionId: string) {
    try {
      const res = await api.get(`/CourtAutomation/filings/${submissionId}`);
      const latest = res.data as FilingItem;
      setFilings((prev) => prev.map((x) => (x.submissionId === submissionId ? latest : x)));
    } catch {
      // Ignore individual refresh errors to avoid noisy UI
    }
  }

  useEffect(() => {
    void loadPacks();
  }, [language]);

  useEffect(() => {
    if (packKey) {
      void loadPackDetails(packKey);
    }
  }, [packKey]);

  const statusColor = (status: string): "default" | "success" | "warning" | "error" => {
    if (status === "Accepted") return "success";
    if (status === "InReview") return "warning";
    if (status === "Rejected") return "error";
    return "default";
  };

  return (
    <Box>
      <Stack direction={{ xs: "column", md: "row" }} justifyContent="space-between" alignItems={{ xs: "flex-start", md: "center" }} spacing={2} sx={{ mb: 2 }}>
        <Box>
          <Stack direction="row" spacing={1} alignItems="center">
            <GavelIcon color="primary" />
            <Typography variant="h5" sx={{ fontWeight: 800 }}>{t("courtAutomation.title")}</Typography>
          </Stack>
          <Typography variant="body2" color="text.secondary">{t("courtAutomation.subtitle")}</Typography>
        </Box>
        <Stack direction="row" spacing={1.25}>
          <FormControl size="small" sx={{ minWidth: 320 }}>
            <InputLabel>{t("courtAutomation.pack")}</InputLabel>
            <Select value={packKey} label={t("courtAutomation.pack")} onChange={(e) => setPackKey(String(e.target.value))}>
              {packs.map((p) => (
                <MenuItem key={p.key} value={p.key}>{p.name}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <Button variant="outlined" startIcon={<RefreshIcon />} onClick={() => void loadPackDetails(packKey)} disabled={!packKey}>
            {t("common.refresh")}
          </Button>
        </Stack>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Grid container spacing={2}>
        <Grid size={{ xs: 12 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("courtAutomation.packOverview")}</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>{pack?.description || "-"}</Typography>
              <Stack direction={{ xs: "column", md: "row" }} spacing={1.5}>
                <Chip label={`${t("courtAutomation.jurisdictionCode")}: ${pack?.jurisdictionCode || "-"}`} />
                <Chip label={`${t("courtAutomation.formsCount")}: ${pack?.forms?.length || 0}`} />
                <Chip label={`${t("courtAutomation.rulesCount")}: ${pack?.deadlineRules?.length || 0}`} />
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("courtAutomation.deadlineAutomation")}</Typography>
              <Grid container spacing={1.5} sx={{ mb: 1.25 }}>
                <Grid size={{ xs: 12, md: 2 }}><TextField fullWidth size="small" label={t("courtAutomation.caseCode")} value={caseCode} onChange={(e) => setCaseCode(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 2 }}><TextField fullWidth size="small" type="date" label={t("courtAutomation.triggerDate")} value={triggerDate} onChange={(e) => setTriggerDate(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
                <Grid size={{ xs: 12, md: 2 }}><TextField fullWidth size="small" type="date" label={t("courtAutomation.hearingDate")} value={hearingDate} onChange={(e) => setHearingDate(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
                <Grid size={{ xs: 12, md: 2 }}><Button fullWidth variant="contained" onClick={() => void calculateDeadlines()}>{t("courtAutomation.calculateDeadlines")}</Button></Grid>
              </Grid>

              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t("courtAutomation.deadline")}</TableCell>
                    <TableCell>{t("courtAutomation.dueDate")}</TableCell>
                    <TableCell>{t("app.status")}</TableCell>
                    <TableCell>{t("app.notes")}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {deadlines.map((d) => (
                    <TableRow key={d.ruleKey}>
                      <TableCell>{d.name}</TableCell>
                      <TableCell>{formatDate(d.dueDate)}</TableCell>
                      <TableCell><Chip size="small" label={d.priority} color={d.priority === "High" ? "error" : d.priority === "Medium" ? "warning" : "default"} /></TableCell>
                      <TableCell>{d.notes}</TableCell>
                    </TableRow>
                  ))}
                  {!deadlines.length && (
                    <TableRow>
                      <TableCell colSpan={4}><Typography color="text.secondary">{t("courtAutomation.noDeadlines")}</Typography></TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("courtAutomation.formGeneration")}</Typography>
              <Grid container spacing={1.5}>
                <Grid size={{ xs: 12, md: 3 }}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t("courtAutomation.form")}</InputLabel>
                    <Select value={formKey} label={t("courtAutomation.form")} onChange={(e) => setFormKey(String(e.target.value))}>
                      {(pack?.forms || []).map((f) => <MenuItem key={f.key} value={f.key}>{f.name}</MenuItem>)}
                    </Select>
                  </FormControl>
                </Grid>
                <Grid size={{ xs: 12, md: 2 }}><TextField fullWidth size="small" label={t("billing.customer")} value={customerId} onChange={(e) => setCustomerId(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 2 }}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t("courtAutomation.format")}</InputLabel>
                    <Select value={format} label={t("courtAutomation.format")} onChange={(e) => setFormat(String(e.target.value) as "txt" | "pdf")}>
                      <MenuItem value="pdf">PDF</MenuItem>
                      <MenuItem value="txt">TXT</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid size={{ xs: 12, md: 3 }}><TextField fullWidth size="small" label={t("courtAutomation.subject")} value={subject} onChange={(e) => setSubject(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 2 }}><Button fullWidth variant="outlined" startIcon={<DownloadIcon />} onClick={() => void generateForm()}>{t("courtAutomation.generateForm")}</Button></Grid>
                <Grid size={{ xs: 12, md: 6 }}><TextField fullWidth size="small" label={t("courtAutomation.facts")} value={facts} onChange={(e) => setFacts(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 6 }}><TextField fullWidth size="small" label={t("courtAutomation.requests")} value={requests} onChange={(e) => setRequests(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 4 }}><TextField fullWidth size="small" label={t("courtAutomation.grounds")} value={grounds} onChange={(e) => setGrounds(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 4 }}><TextField fullWidth size="small" label={t("courtAutomation.reference")} value={reference} onChange={(e) => setReference(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 4 }}><TextField fullWidth size="small" label={t("courtAutomation.scope")} value={scope} onChange={(e) => setScope(e.target.value)} /></Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("courtAutomation.filingIntegrations")}</Typography>
              <Grid container spacing={1.5} sx={{ mb: 1.25 }}>
                <Grid size={{ xs: 12, md: 3 }}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t("courtAutomation.channel")}</InputLabel>
                    <Select value={filingChannel} label={t("courtAutomation.channel")} onChange={(e) => setFilingChannel(String(e.target.value))}>
                      {(pack?.filingChannels || []).map((ch) => <MenuItem key={ch} value={ch}>{ch}</MenuItem>)}
                    </Select>
                  </FormControl>
                </Grid>
                <Grid size={{ xs: 12, md: 2 }}><TextField fullWidth size="small" label={t("courts.name")} value={courtId} onChange={(e) => setCourtId(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 2 }}><TextField fullWidth size="small" type="date" label={t("courtAutomation.dueDate")} value={dueDate} onChange={(e) => setDueDate(e.target.value)} InputLabelProps={{ shrink: true }} /></Grid>
                <Grid size={{ xs: 12, md: 3 }}><TextField fullWidth size="small" label={t("app.notes")} value={filingNotes} onChange={(e) => setFilingNotes(e.target.value)} /></Grid>
                <Grid size={{ xs: 12, md: 2 }}><Button fullWidth variant="contained" onClick={() => void submitFiling()}>{t("courtAutomation.submitFiling")}</Button></Grid>
              </Grid>

              <Paper variant="outlined">
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>No.</TableCell>
                      <TableCell>{t("courtAutomation.form")}</TableCell>
                      <TableCell>{t("courtAutomation.channel")}</TableCell>
                      <TableCell>{t("app.status")}</TableCell>
                      <TableCell>{t("courtAutomation.externalReference")}</TableCell>
                      <TableCell>{t("courtAutomation.submittedAt")}</TableCell>
                      <TableCell>{t("app.actions")}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filings.map((f, index) => (
                      <TableRow key={f.submissionId}>
                        <TableCell>{index + 1}</TableCell>
                        <TableCell>{f.formKey}</TableCell>
                        <TableCell>{f.filingChannel}</TableCell>
                        <TableCell><Chip size="small" label={f.status} color={statusColor(f.status)} /></TableCell>
                        <TableCell>{f.externalReference}</TableCell>
                        <TableCell>{formatDateTime(f.submittedAt)}</TableCell>
                        <TableCell>
                          <Button size="small" onClick={() => void refreshSubmission(f.submissionId)}>{t("common.refresh")}</Button>
                        </TableCell>
                      </TableRow>
                    ))}
                    {!filings.length && (
                      <TableRow>
                        <TableCell colSpan={7}><Typography color="text.secondary">{t("courtAutomation.noFilings")}</Typography></TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </Paper>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {loading && <Typography sx={{ mt: 2 }}>{t("common.loading")}</Typography>}
    </Box>
  );
}
