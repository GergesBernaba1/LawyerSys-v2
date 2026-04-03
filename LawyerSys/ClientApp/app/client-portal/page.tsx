"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Grid,
  MenuItem,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
  useTheme,
} from "@mui/material";
import api from "../../src/services/api";
import { useCurrency } from "../../src/hooks/useCurrency";

type RequestedDocument = {
  id: number;
  caseCode: number;
  title: string;
  description: string;
  dueDate?: string | null;
  status: string;
  customerNotes: string;
  reviewNotes: string;
  uploadedFileId?: number | null;
  uploadedFileCode: string;
  uploadedFilePath: string;
  requestedAtUtc: string;
  submittedAtUtc?: string | null;
};

type PaymentProof = {
  id: number;
  caseCode?: number | null;
  amount: number;
  paymentDate: string;
  notes: string;
  proofFileId?: number | null;
  proofFileCode: string;
  proofFilePath: string;
  status: string;
  billingPaymentId?: number | null;
  reviewNotes: string;
  submittedAtUtc: string;
};

type PortalResponse = {
  customerName: string;
  cases: { code: number; type: string; date: string; totalAmount: number; status: number; latestUpdate: string }[];
  hearings: { caseCode: number; date: string; time: string; judgeName: string; notes: string }[];
  documents: { id: number; type: string; number: number; details: string }[];
  payments: { id: number; date: string; amount: number; notes: string }[];
  caseFiles: { fileId: number; caseCode: number; fileCode: string; filePath: string }[];
  recentUpdates: { id: number; title: string; message: string; category: string; route: string; timestamp: string }[];
  conversationThreads: {
    caseCode: number;
    caseType: string;
    lastMessage: string;
    lastSenderName: string;
    lastSenderRole: string;
    lastMessageAtUtc?: string | null;
    unreadCount: number;
    waitingOnCustomer: boolean;
    hasAttachment: boolean;
  }[];
  officeContacts: { employeeId: number; name: string; jobTitle: string; phoneNumber: string }[];
  requestedDocuments: RequestedDocument[];
  paymentProofs: PaymentProof[];
  billing: { totalPayments: number; casesTotalAmount: number; outstandingBalance: number };
  summary: {
    activeCasesCount: number;
    pendingRequestedDocumentsCount: number;
    unreadMessagesCount: number;
    upcomingSessionsCount: number;
    pendingPaymentProofsCount: number;
    nextSessionAtUtc?: string | null;
    nextSessionLabel: string;
  };
};

const paymentProofInitialState = {
  caseCode: "",
  amount: "",
  paymentDate: "",
  notes: "",
};

export default function ClientPortalPage() {
  const { t, i18n } = useTranslation();
  const router = useRouter();
  const theme = useTheme();
  const { formatCurrency } = useCurrency();
  const isRTL = theme.direction === "rtl";
  const locale = isRTL ? "ar" : (i18n.resolvedLanguage || "en");
  const statusLabels = t("clientPortal.statuses", { returnObjects: true }) as string[];
  const [data, setData] = useState<PortalResponse | null>(null);
  const [error, setError] = useState("");
  const [uploadStatus, setUploadStatus] = useState("");
  const [selectedCaseCode, setSelectedCaseCode] = useState<number | "">("");
  const [uploading, setUploading] = useState(false);
  const [paymentProofForm, setPaymentProofForm] = useState(paymentProofInitialState);
  const [paymentProofFile, setPaymentProofFile] = useState<File | null>(null);
  const [submittingProof, setSubmittingProof] = useState(false);
  const [requestUploadTarget, setRequestUploadTarget] = useState<{ requestId: number; caseCode: number } | null>(null);
  const [requestUploadNotes, setRequestUploadNotes] = useState<Record<number, string>>({});
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const requestedDocumentInputRef = useRef<HTMLInputElement | null>(null);
  const apiBase = typeof api.defaults.baseURL === "string" ? api.defaults.baseURL : "";

  const loadOverview = useCallback(async () => {
    try {
      setError("");
      const response = await api.get("/ClientPortal/overview");
      setData(response.data);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("clientPortal.failedLoad"));
    }
  }, [t]);

  useEffect(() => {
    void loadOverview();
  }, [loadOverview]);

  useEffect(() => {
    if (!data?.cases?.length) {
      setSelectedCaseCode("");
      setPaymentProofForm(paymentProofInitialState);
      return;
    }

    const defaultCaseCode = data.cases[0].code;
    if (!selectedCaseCode || !data.cases.some((item) => item.code === selectedCaseCode)) {
      setSelectedCaseCode(defaultCaseCode);
    }

    setPaymentProofForm((current) => ({
      ...current,
      caseCode: current.caseCode || String(defaultCaseCode),
    }));
  }, [data, selectedCaseCode]);

  const formatNumber = (value: number) => value.toLocaleString(locale);
  const formatMoney = (value: number) => formatCurrency(Number(value || 0));
  const formatDate = (value?: string | null) => {
    if (!value) return "-";
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleDateString(locale);
  };
  const formatDateTime = (dateValue: string, timeValue?: string) => {
    const rawDateTime = dateValue && timeValue ? `${dateValue}T${timeValue}` : (dateValue || timeValue || "");
    if (!rawDateTime) return "-";
    const parsed = new Date(rawDateTime);
    return Number.isNaN(parsed.getTime()) ? rawDateTime : parsed.toLocaleString(locale);
  };
  const formatNotificationCategory = (value: string) =>
    t(`notifications.category.${value?.toLowerCase?.() || "system"}`, { defaultValue: value || t("notifications.category.system", { defaultValue: "System" }) });

  async function handleUploadChange(event: React.ChangeEvent<HTMLInputElement>) {
    const nextFile = event.target.files?.[0];
    event.target.value = "";

    if (!nextFile || !selectedCaseCode) {
      return;
    }

    try {
      setUploading(true);
      setUploadStatus("");

      const formData = new FormData();
      formData.append("file", nextFile);
      formData.append("title", nextFile.name);

      await api.post(`/ClientPortal/cases/${selectedCaseCode}/files`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      setUploadStatus(t("clientPortal.uploadSuccess", { defaultValue: "File uploaded successfully" }));
      await loadOverview();
    } catch (err: any) {
      setUploadStatus(err?.response?.data?.message || t("clientPortal.uploadFailed", { defaultValue: "Failed to upload file" }));
    } finally {
      setUploading(false);
    }
  }

  async function submitPaymentProof() {
    if (!paymentProofForm.caseCode || !paymentProofForm.amount || !paymentProofForm.paymentDate || !paymentProofFile) {
      setUploadStatus(t("clientPortal.paymentProofMissing", { defaultValue: "Complete the payment proof form first." }));
      return;
    }

    try {
      setSubmittingProof(true);
      setUploadStatus("");
      const formData = new FormData();
      formData.append("amount", paymentProofForm.amount);
      formData.append("paymentDate", paymentProofForm.paymentDate);
      formData.append("notes", paymentProofForm.notes);
      formData.append("file", paymentProofFile);

      await api.post(`/ClientPortal/cases/${paymentProofForm.caseCode}/payment-proofs`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      setPaymentProofForm((current) => ({ ...paymentProofInitialState, caseCode: current.caseCode }));
      setPaymentProofFile(null);
      setUploadStatus(t("clientPortal.paymentProofSuccess", { defaultValue: "Payment proof submitted successfully" }));
      await loadOverview();
    } catch (err: any) {
      setUploadStatus(err?.response?.data?.message || t("clientPortal.paymentProofFailed", { defaultValue: "Failed to submit payment proof" }));
    } finally {
      setSubmittingProof(false);
    }
  }

  async function handleRequestedDocumentUpload(event: React.ChangeEvent<HTMLInputElement>) {
    const nextFile = event.target.files?.[0];
    event.target.value = "";

    if (!nextFile || !requestUploadTarget) {
      return;
    }

    try {
      setUploading(true);
      setUploadStatus("");
      const formData = new FormData();
      formData.append("file", nextFile);
      formData.append("notes", requestUploadNotes[requestUploadTarget.requestId] || "");

      await api.post(
        `/ClientPortal/cases/${requestUploadTarget.caseCode}/requested-documents/${requestUploadTarget.requestId}/submit`,
        formData,
        { headers: { "Content-Type": "multipart/form-data" } }
      );

      setUploadStatus(t("clientPortal.requestedDocumentUploaded", { defaultValue: "Requested document uploaded successfully" }));
      await loadOverview();
    } catch (err: any) {
      setUploadStatus(err?.response?.data?.message || t("clientPortal.requestedDocumentUploadFailed", { defaultValue: "Failed to upload requested document" }));
    } finally {
      setUploading(false);
      setRequestUploadTarget(null);
    }
  }

  function renderEmptyRow(colSpan: number, message: string) {
    return (
      <TableRow>
        <TableCell colSpan={colSpan} align="center">
          {message}
        </TableCell>
      </TableRow>
    );
  }

  function formatRequestStatus(status: string) {
    return t(`clientPortal.requestStatus.${status.toLowerCase()}`, { defaultValue: status });
  }

  return (
    <Box dir={isRTL ? "rtl" : "ltr"}>
      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {!!uploadStatus && (
        <Alert severity={uploadStatus.includes("success") || uploadStatus.includes("successfully") ? "success" : "info"} sx={{ mb: 2 }}>
          {uploadStatus}
        </Alert>
      )}

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ alignItems: { md: "center" } }}>
            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="h5">
                {t("clientPortal.welcome")}, {data?.customerName || t("clientPortal.client")}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                {t("clientPortal.portalSummary", { defaultValue: "Track your cases, office requests, documents, payments, and the latest updates in one place." })}
              </Typography>
              {data?.summary?.nextSessionAtUtc ? (
                <Chip
                  size="small"
                  color="primary"
                  variant="outlined"
                  label={t("clientPortal.nextSessionChip", {
                    defaultValue: "Next session: {{label}} on {{date}}",
                    label: data.summary.nextSessionLabel || "#",
                    date: formatDateTime(data.summary.nextSessionAtUtc),
                  })}
                  sx={{ mt: 1.5 }}
                />
              ) : null}
            </Box>
            <Stack direction={{ xs: "column", sm: "row" }} spacing={1}>
              <Button variant="outlined" onClick={() => router.push("/client-portal/messages")}>
                {t("clientPortal.openMessagesPage", { defaultValue: "Open messages" })}
              </Button>
              <Button variant="outlined" onClick={() => router.push("/client-portal/documents")}>
                {t("clientPortal.openDocumentsPage", { defaultValue: "Open documents" })}
              </Button>
            </Stack>
          </Stack>
        </CardContent>
      </Card>

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t("clientPortal.activeCases", { defaultValue: "Active cases" })}</Typography>
              <Typography variant="h6">{formatNumber(data?.summary?.activeCasesCount ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t("clientPortal.pendingDocuments", { defaultValue: "Pending documents" })}</Typography>
              <Typography variant="h6">{formatNumber(data?.summary?.pendingRequestedDocumentsCount ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t("clientPortal.unreadMessages", { defaultValue: "Unread messages" })}</Typography>
              <Typography variant="h6">{formatNumber(data?.summary?.unreadMessagesCount ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t("clientPortal.upcomingSessionsCount", { defaultValue: "Upcoming sessions" })}</Typography>
              <Typography variant="h6">{formatNumber(data?.summary?.upcomingSessionsCount ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t("clientPortal.totalCaseValue")}</Typography>
              <Typography variant="h6">{formatMoney(data?.billing?.casesTotalAmount ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t("clientPortal.totalPaid")}</Typography>
              <Typography variant="h6">{formatMoney(data?.billing?.totalPayments ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card>
            <CardContent>
              <Typography variant="subtitle2" color="text.secondary">{t("clientPortal.outstanding")}</Typography>
              <Typography variant="h6">{formatMoney(data?.billing?.outstandingBalance ?? 0)}</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Card sx={{ height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.actionCenter", { defaultValue: "Action center" })}</Typography>
              <Stack spacing={1.25}>
                <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: "action.hover" }}>
                  <Typography variant="subtitle2">{t("clientPortal.pendingDocumentsAction", { defaultValue: "Requested documents waiting for you" })}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {t("clientPortal.pendingDocumentsActionSubtitle", {
                      defaultValue: "{{count}} item(s) still need your response.",
                      count: data?.summary?.pendingRequestedDocumentsCount ?? 0,
                    })}
                  </Typography>
                </Box>
                <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: "action.hover" }}>
                  <Typography variant="subtitle2">{t("clientPortal.unreadMessagesAction", { defaultValue: "Messages from the office" })}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {t("clientPortal.unreadMessagesActionSubtitle", {
                      defaultValue: "{{count}} unread update(s) are waiting in your inbox.",
                      count: data?.summary?.unreadMessagesCount ?? 0,
                    })}
                  </Typography>
                </Box>
                <Stack direction={{ xs: "column", sm: "row" }} spacing={1}>
                  <Button variant="contained" onClick={() => router.push("/client-portal/messages")}>
                    {t("clientPortal.openInbox", { defaultValue: "Open inbox" })}
                  </Button>
                  <Button variant="outlined" onClick={() => router.push("/client-portal/documents")}>
                    {t("clientPortal.reviewDocuments", { defaultValue: "Review documents" })}
                  </Button>
                </Stack>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Card sx={{ height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.recentUpdatesTitle", { defaultValue: "Recent updates" })}</Typography>
              <Stack spacing={1.25}>
                {(data?.recentUpdates?.length ?? 0) > 0 ? data?.recentUpdates.slice(0, 5).map((item) => (
                  <Box
                    key={item.id}
                    sx={{ p: 1.5, borderRadius: 2, border: "1px solid", borderColor: "divider", cursor: item.route ? "pointer" : "default" }}
                    onClick={() => item.route && router.push(item.route)}
                  >
                    <Stack direction="row" spacing={1} sx={{ alignItems: "center", mb: 0.5 }}>
                      <Chip size="small" variant="outlined" label={formatNotificationCategory(item.category)} />
                      <Typography variant="caption" color="text.secondary">{formatDateTime(item.timestamp)}</Typography>
                    </Stack>
                    <Typography variant="subtitle2">{item.title}</Typography>
                    <Typography variant="body2" color="text.secondary">{item.message}</Typography>
                  </Box>
                )) : (
                  <Typography color="text.secondary">
                    {t("clientPortal.noRecentUpdates", { defaultValue: "Your recent office updates will appear here." })}
                  </Typography>
                )}
              </Stack>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Card sx={{ height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.officeContactsTitle", { defaultValue: "Office contacts" })}</Typography>
              <Stack spacing={1.25}>
                {(data?.officeContacts?.length ?? 0) > 0 ? data?.officeContacts.map((item) => (
                  <Box key={item.employeeId} sx={{ p: 1.5, borderRadius: 2, border: "1px solid", borderColor: "divider" }}>
                    <Typography variant="subtitle2">{item.name}</Typography>
                    <Typography variant="body2" color="text.secondary">{item.jobTitle || t("clientPortal.officeRoleFallback", { defaultValue: "Case team" })}</Typography>
                    <Typography variant="caption" color="text.secondary">{item.phoneNumber || "-"}</Typography>
                  </Box>
                )) : (
                  <Typography color="text.secondary">
                    {t("clientPortal.noOfficeContacts", { defaultValue: "The office team assigned to your cases will appear here." })}
                  </Typography>
                )}
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.myCases")}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t("clientPortal.code")}</TableCell>
                    <TableCell>{t("clientPortal.type")}</TableCell>
                    <TableCell>{t("clientPortal.status")}</TableCell>
                    <TableCell>{t("clientPortal.latestUpdate", { defaultValue: "Latest update" })}</TableCell>
                    <TableCell>{t("clientPortal.actions", { defaultValue: "Actions" })}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.cases?.length ?? 0) > 0
                    ? data?.cases.map((item) => (
                        <TableRow key={item.code}>
                          <TableCell>{item.code}</TableCell>
                          <TableCell>{item.type}</TableCell>
                          <TableCell>
                            <Chip size="small" label={statusLabels[item.status] || item.status} variant="outlined" />
                          </TableCell>
                          <TableCell>{item.latestUpdate || "-"}</TableCell>
                          <TableCell>
                            <Stack direction="row" spacing={1}>
                              <Button size="small" onClick={() => router.push(`/cases/${item.code}`)}>
                                {t("clientPortal.openCase", { defaultValue: "Open case" })}
                              </Button>
                              <Button size="small" onClick={() => router.push(`/cases/${item.code}/timeline`)}>
                                {t("clientPortal.viewTimeline", { defaultValue: "View Timeline" })}
                              </Button>
                            </Stack>
                          </TableCell>
                        </TableRow>
                      ))
                    : renderEmptyRow(5, t("clientPortal.noCases", { defaultValue: "No linked cases yet. The office will add your cases here when they are ready." }))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.inboxPreviewTitle", { defaultValue: "Inbox preview" })}</Typography>
              <Stack spacing={1.25}>
                {(data?.conversationThreads?.length ?? 0) > 0 ? data?.conversationThreads.slice(0, 5).map((item) => (
                  <Box
                    key={item.caseCode}
                    sx={{ p: 1.5, borderRadius: 2, border: "1px solid", borderColor: "divider", cursor: "pointer" }}
                    onClick={() => router.push(`/client-portal/messages?caseCode=${item.caseCode}`)}
                  >
                    <Stack direction="row" spacing={1} sx={{ alignItems: "center", justifyContent: "space-between", mb: 0.5 }}>
                      <Typography variant="subtitle2">#{item.caseCode} - {item.caseType}</Typography>
                      {item.unreadCount > 0 ? <Chip size="small" color="primary" label={t("clientPortal.unreadCount", { defaultValue: "{{count}} unread", count: item.unreadCount })} /> : null}
                    </Stack>
                    <Typography variant="body2" color="text.secondary">
                      {item.lastMessage || t("clientPortal.noMessagesYet", { defaultValue: "No messages yet." })}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {item.lastSenderName
                        ? `${item.lastSenderName} - ${item.lastSenderRole} - ${formatDateTime(item.lastMessageAtUtc || "")}`
                        : t("clientPortal.awaitingFirstMessage", { defaultValue: "Start the conversation from the inbox." })}
                    </Typography>
                  </Box>
                )) : (
                  <Typography color="text.secondary">
                    {t("clientPortal.noMessagesYet", { defaultValue: "No messages yet." })}
                  </Typography>
                )}
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.caseSessions", { defaultValue: "Case Sessions" })}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t("clientPortal.case")}</TableCell>
                    <TableCell>{t("clientPortal.date")}</TableCell>
                    <TableCell>{t("clientPortal.judge")}</TableCell>
                    <TableCell>{t("clientPortal.notes", { defaultValue: "Notes" })}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.hearings?.length ?? 0) > 0
                    ? data?.hearings.map((item, index) => (
                        <TableRow key={`${item.caseCode}-${index}`}>
                          <TableCell>{item.caseCode}</TableCell>
                          <TableCell>{formatDateTime(item.date, item.time)}</TableCell>
                          <TableCell>{item.judgeName}</TableCell>
                          <TableCell>{item.notes || "-"}</TableCell>
                        </TableRow>
                      ))
                    : renderEmptyRow(4, t("clientPortal.noSessions", { defaultValue: "No sessions have been scheduled for your cases yet." }))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.myPayments", { defaultValue: "My Payments" })}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t("clientPortal.date")}</TableCell>
                    <TableCell>{t("clientPortal.amount", { defaultValue: "Amount" })}</TableCell>
                    <TableCell>{t("clientPortal.notes", { defaultValue: "Notes" })}</TableCell>
                    <TableCell>{t("clientPortal.actions", { defaultValue: "Actions" })}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.payments?.length ?? 0) > 0
                    ? data?.payments.map((item) => (
                        <TableRow key={item.id}>
                          <TableCell>{formatDate(item.date)}</TableCell>
                          <TableCell>{formatMoney(item.amount)}</TableCell>
                          <TableCell>{item.notes || "-"}</TableCell>
                          <TableCell>
                            <Button
                              size="small"
                              component="a"
                              href={`${apiBase}/ClientPortal/payments/${item.id}/receipt`}
                              target="_blank"
                              rel="noreferrer"
                            >
                              {t("clientPortal.downloadReceipt", { defaultValue: "Download receipt" })}
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))
                    : renderEmptyRow(4, t("clientPortal.noPayments", { defaultValue: "No payments have been recorded on your account yet." }))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.paymentProofs", { defaultValue: "Payment Proofs" })}</Typography>
              <Stack spacing={1.5} sx={{ mb: 2 }}>
                <TextField
                  select
                  size="small"
                  label={t("clientPortal.selectCase", { defaultValue: "Select Case" })}
                  value={paymentProofForm.caseCode}
                  onChange={(event) => setPaymentProofForm((current) => ({ ...current, caseCode: event.target.value }))}
                >
                  {(data?.cases || []).map((item) => (
                    <MenuItem key={item.code} value={item.code}>
                      {item.code} - {item.type}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  size="small"
                  label={t("clientPortal.amount", { defaultValue: "Amount" })}
                  type="number"
                  value={paymentProofForm.amount}
                  onChange={(event) => setPaymentProofForm((current) => ({ ...current, amount: event.target.value }))}
                />
                <TextField
                  size="small"
                  label={t("clientPortal.paymentDate", { defaultValue: "Payment date" })}
                  type="date"
                  value={paymentProofForm.paymentDate}
                  onChange={(event) => setPaymentProofForm((current) => ({ ...current, paymentDate: event.target.value }))}
                  InputLabelProps={{ shrink: true }}
                />
                <TextField
                  size="small"
                  label={t("clientPortal.notes", { defaultValue: "Notes" })}
                  value={paymentProofForm.notes}
                  onChange={(event) => setPaymentProofForm((current) => ({ ...current, notes: event.target.value }))}
                  multiline
                  minRows={2}
                />
                <Button variant="outlined" component="label">
                  {paymentProofFile
                    ? `${t("clientPortal.selectedFile", { defaultValue: "Selected file" })}: ${paymentProofFile.name}`
                    : t("clientPortal.attachProof", { defaultValue: "Attach proof file" })}
                  <input hidden type="file" onChange={(event) => setPaymentProofFile(event.target.files?.[0] ?? null)} />
                </Button>
                <Button variant="contained" onClick={submitPaymentProof} disabled={submittingProof}>
                  {submittingProof
                    ? t("clientPortal.submittingProof", { defaultValue: "Submitting..." })
                    : t("clientPortal.submitPaymentProof", { defaultValue: "Submit payment proof" })}
                </Button>
              </Stack>

              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t("clientPortal.date")}</TableCell>
                    <TableCell>{t("clientPortal.amount", { defaultValue: "Amount" })}</TableCell>
                    <TableCell>{t("clientPortal.status")}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.paymentProofs?.length ?? 0) > 0
                    ? data?.paymentProofs.slice(0, 5).map((item) => (
                        <TableRow key={item.id}>
                          <TableCell>{formatDate(item.paymentDate)}</TableCell>
                          <TableCell>{formatMoney(item.amount)}</TableCell>
                          <TableCell>{formatRequestStatus(item.status)}</TableCell>
                        </TableRow>
                      ))
                    : renderEmptyRow(3, t("clientPortal.noPaymentProofs", { defaultValue: "No payment proofs submitted yet." }))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.requestedDocumentsTitle", { defaultValue: "Requested Documents" })}</Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t("clientPortal.case")}</TableCell>
                    <TableCell>{t("clientPortal.type")}</TableCell>
                    <TableCell>{t("clientPortal.status")}</TableCell>
                    <TableCell>{t("clientPortal.actions", { defaultValue: "Actions" })}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.requestedDocuments?.length ?? 0) > 0
                    ? data?.requestedDocuments.map((item) => (
                        <TableRow key={item.id}>
                          <TableCell>{item.caseCode}</TableCell>
                          <TableCell>
                            <Stack spacing={0.5}>
                              <Typography variant="body2">{item.title}</Typography>
                              <Typography variant="caption" color="text.secondary">
                                {item.description || t("clientPortal.noDescription", { defaultValue: "No description provided." })}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {t("clientPortal.dueDate", { defaultValue: "Due date" })}: {formatDate(item.dueDate || undefined)}
                              </Typography>
                            </Stack>
                          </TableCell>
                          <TableCell>
                            <Chip size="small" label={formatRequestStatus(item.status)} variant="outlined" />
                          </TableCell>
                          <TableCell>
                            <Stack spacing={1}>
                              <TextField
                                size="small"
                                label={t("clientPortal.notes", { defaultValue: "Notes" })}
                                value={requestUploadNotes[item.id] ?? ""}
                                onChange={(event) => setRequestUploadNotes((current) => ({ ...current, [item.id]: event.target.value }))}
                              />
                              <Stack direction="row" spacing={1}>
                                {(item.status === "Pending" || item.status === "Rejected") && (
                                  <Button
                                    size="small"
                                    variant="contained"
                                    onClick={() => {
                                      setRequestUploadTarget({ requestId: item.id, caseCode: item.caseCode });
                                      requestedDocumentInputRef.current?.click();
                                    }}
                                  >
                                    {t("clientPortal.uploadRequestedDocument", { defaultValue: "Upload" })}
                                  </Button>
                                )}
                                <Button size="small" onClick={() => router.push(`/cases/${item.caseCode}`)}>
                                  {t("clientPortal.openCase", { defaultValue: "Open case" })}
                                </Button>
                                {item.uploadedFileId ? (
                                  <Button
                                    size="small"
                                    component="a"
                                    href={`${apiBase}/Files/${item.uploadedFileId}/download`}
                                    target="_blank"
                                    rel="noreferrer"
                                  >
                                    {t("clientPortal.download", { defaultValue: "Download" })}
                                  </Button>
                                ) : null}
                              </Stack>
                            </Stack>
                          </TableCell>
                        </TableRow>
                      ))
                    : renderEmptyRow(4, t("clientPortal.noRequestedDocuments", { defaultValue: "The office has not requested any documents from you yet." }))}
                </TableBody>
              </Table>
              <input
                ref={requestedDocumentInputRef}
                type="file"
                hidden
                onChange={handleRequestedDocumentUpload}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, lg: 6 }}>
          <Card>
            <CardContent>
              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} sx={{ mb: 2, alignItems: { sm: "center" } }}>
                <Typography variant="h6" sx={{ flexGrow: 1 }}>
                  {t("clientPortal.caseFiles", { defaultValue: "Case Files" })}
                </Typography>
                <TextField
                  select
                  size="small"
                  label={t("clientPortal.selectCase", { defaultValue: "Select Case" })}
                  value={selectedCaseCode}
                  onChange={(event) => setSelectedCaseCode(Number(event.target.value))}
                  sx={{ minWidth: 180 }}
                >
                  {(data?.cases || []).map((item) => (
                    <MenuItem key={item.code} value={item.code}>
                      {item.code} - {item.type}
                    </MenuItem>
                  ))}
                </TextField>
                <Button
                  variant="contained"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploading || !selectedCaseCode}
                >
                  {uploading ? <CircularProgress size={18} color="inherit" /> : t("clientPortal.uploadCaseFile", { defaultValue: "Upload File" })}
                </Button>
                <input
                  ref={fileInputRef}
                  type="file"
                  hidden
                  onChange={handleUploadChange}
                />
              </Stack>

              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>{t("clientPortal.case")}</TableCell>
                    <TableCell>{t("clientPortal.fileName", { defaultValue: "File" })}</TableCell>
                    <TableCell>{t("clientPortal.actions", { defaultValue: "Actions" })}</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(data?.caseFiles?.length ?? 0) > 0
                    ? data?.caseFiles.map((item) => (
                        <TableRow key={`${item.caseCode}-${item.fileId}`}>
                          <TableCell>{item.caseCode}</TableCell>
                          <TableCell>{item.fileCode || item.filePath || `#${item.fileId}`}</TableCell>
                          <TableCell>
                            <Button
                              size="small"
                              component="a"
                              href={`${apiBase}/Files/${item.fileId}/download`}
                              target="_blank"
                              rel="noreferrer"
                            >
                              {t("clientPortal.download", { defaultValue: "Download" })}
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))
                    : renderEmptyRow(3, t("clientPortal.noCaseFiles", { defaultValue: "No files are available for your cases yet." }))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card sx={{ mt: 2 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.myDocuments")}</Typography>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>#</TableCell>
                <TableCell>{t("clientPortal.type")}</TableCell>
                <TableCell>{t("clientPortal.details")}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(data?.documents?.length ?? 0) > 0
                ? data?.documents.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>{item.number}</TableCell>
                      <TableCell>{item.type}</TableCell>
                      <TableCell>{item.details}</TableCell>
                    </TableRow>
                  ))
                : renderEmptyRow(3, t("clientPortal.noDocuments", { defaultValue: "No judicial documents are available for you yet." }))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Box>
  );
}
