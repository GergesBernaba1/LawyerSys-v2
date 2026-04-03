"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Snackbar,
  Stack,
  Tab,
  Tabs,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import {
  AccountBalanceWallet as TrustIcon,
  Add as AddIcon,
  Download as DownloadIcon,
  Refresh as RefreshIcon,
} from "@mui/icons-material";
import api from "../../src/services/api";
import { useTranslation } from "react-i18next";
import { useAuth } from "../../src/services/auth";
import { useCurrency } from "../../src/hooks/useCurrency";
import type { PagedResult } from "../../src/types/paging";
import SearchableSelect from "../../src/components/SearchableSelect";

type TrustAccount = {
  customerId: number;
  customerName: string;
  currentBalance: number;
  lastMovementDate?: string | null;
};

type TrustLedgerEntry = {
  id: number;
  customerId: number;
  customerName?: string;
  caseCode?: number | null;
  entryType: string;
  amount: number;
  operationDate: string;
  description?: string | null;
  reference?: string | null;
  createdAt: string;
  createdBy?: string | null;
  runningBalance: number;
};

type TrustReconciliation = {
  id: number;
  reconciliationDate: string;
  bankStatementBalance: number;
  bookBalance: number;
  clientLedgerBalance: number;
  bankToBookDifference: number;
  clientToBookDifference: number;
  notes?: string | null;
  createdAt: string;
  createdBy?: string | null;
};

type TrustSummary = {
  asOfDate: string;
  bookBalance: number;
  totalClientLedgerBalance: number;
  activeClientAccounts: number;
  negativeBalanceAccounts: number;
  latestReconciliation?: TrustReconciliation | null;
};

const today = () => new Date().toISOString().slice(0, 10);

export default function TrustAccountingPage() {
  const { t } = useTranslation();
  const { hasAnyRole } = useAuth();
  const { formatCurrency } = useCurrency();
  const canManageTrust = hasAnyRole("Admin", "SuperAdmin");
  const isEmployeeOnly = !canManageTrust;

  const [tab, setTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [accounts, setAccounts] = useState<TrustAccount[]>([]);
  const [summary, setSummary] = useState<TrustSummary | null>(null);
  const [search, setSearch] = useState("");

  const [selectedCustomerId, setSelectedCustomerId] = useState<number>(0);
  const [ledgerRows, setLedgerRows] = useState<TrustLedgerEntry[]>([]);
  const [ledgerFromDate, setLedgerFromDate] = useState("");
  const [ledgerToDate, setLedgerToDate] = useState("");

  const [reconciliationFromDate, setReconciliationFromDate] = useState("");
  const [reconciliationToDate, setReconciliationToDate] = useState("");
  const [reconciliationPage, setReconciliationPage] = useState(1);
  const [reconciliations, setReconciliations] = useState<PagedResult<TrustReconciliation> | null>(null);

  const [openDeposit, setOpenDeposit] = useState(false);
  const [openWithdrawal, setOpenWithdrawal] = useState(false);
  const [openAdjustment, setOpenAdjustment] = useState(false);
  const [openReconciliation, setOpenReconciliation] = useState(false);

  const [depositForm, setDepositForm] = useState({
    customerId: 0,
    amount: 0,
    operationDate: today(),
    caseCode: "",
    description: "",
    reference: "",
  });

  const [withdrawalForm, setWithdrawalForm] = useState({
    customerId: 0,
    amount: 0,
    operationDate: today(),
    caseCode: "",
    description: "",
    reference: "",
  });

  const [adjustmentForm, setAdjustmentForm] = useState({
    customerId: 0,
    amount: 0,
    operationDate: today(),
    caseCode: "",
    direction: "Increase",
    description: "",
    reference: "",
  });

  const [newReconciliationForm, setNewReconciliationForm] = useState({
    reconciliationDate: today(),
    bankStatementBalance: 0,
    notes: "",
  });

  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: "success" | "error" }>({
    open: false,
    message: "",
    severity: "success",
  });

  const accountOptions = useMemo(
    () => accounts.map((a) => ({ value: a.customerId, label: a.customerName || "-" })),
    [accounts]
  );

  const loadOverview = useCallback(async () => {
    setLoading(true);
    try {
      const [accountsRes, summaryRes] = await Promise.all([
        api.get("/TrustAccounting/accounts", { params: { search: search.trim() || undefined } }),
        api.get("/TrustAccounting/summary"),
      ]);

      const accountItems: TrustAccount[] = accountsRes.data || [];
      setAccounts(accountItems);
      setSummary(summaryRes.data || null);

      if (selectedCustomerId === 0 && accountItems.length > 0) {
        const firstId = accountItems[0].customerId;
        setSelectedCustomerId(firstId);
        setDepositForm((p) => ({ ...p, customerId: firstId }));
        setWithdrawalForm((p) => ({ ...p, customerId: firstId }));
        setAdjustmentForm((p) => ({ ...p, customerId: firstId }));
      }
    } catch (error: any) {
      setSnackbar({
        open: true,
        severity: "error",
        message: error?.response?.data?.message || t("trust.failedLoad"),
      });
    } finally {
      setLoading(false);
    }
  }, [search, selectedCustomerId, t]);

  const loadLedger = useCallback(async (customerId: number) => {
    if (!customerId) {
      setLedgerRows([]);
      return;
    }

    try {
      const params: Record<string, string> = {};
      if (ledgerFromDate) params.fromDate = ledgerFromDate;
      if (ledgerToDate) params.toDate = ledgerToDate;

      const response = await api.get(`/TrustAccounting/accounts/${customerId}/ledger`, { params });
      setLedgerRows(response.data || []);
    } catch (error: any) {
      setSnackbar({
        open: true,
        severity: "error",
        message: error?.response?.data?.message || t("trust.failedLoadLedger"),
      });
    }
  }, [ledgerFromDate, ledgerToDate, t]);

  const loadReconciliations = useCallback(async (page = reconciliationPage) => {
    try {
      const params: Record<string, string | number> = { page, pageSize: 10 };
      if (reconciliationFromDate) params.fromDate = reconciliationFromDate;
      if (reconciliationToDate) params.toDate = reconciliationToDate;

      const response = await api.get("/TrustAccounting/reconciliations", { params });
      setReconciliations(response.data);
    } catch (error: any) {
      setSnackbar({
        open: true,
        severity: "error",
        message: error?.response?.data?.message || t("trust.failedLoadReconciliations"),
      });
    }
  }, [reconciliationPage, reconciliationFromDate, reconciliationToDate, t]);

  useEffect(() => {
    void loadOverview();
  }, [loadOverview]);

  useEffect(() => {
    if (selectedCustomerId) {
      void loadLedger(selectedCustomerId);
    }
  }, [selectedCustomerId, loadLedger]);

  useEffect(() => {
    if (canManageTrust) {
      void loadReconciliations(1);
    }
  }, [canManageTrust, loadReconciliations]);

  useEffect(() => {
    if (!canManageTrust && tab === 2) {
      setTab(1);
    }
  }, [canManageTrust, tab]);

  async function submitDeposit() {
    try {
      await api.post("/TrustAccounting/deposits", {
        customerId: depositForm.customerId,
        amount: Number(depositForm.amount),
        operationDate: depositForm.operationDate,
        caseCode: depositForm.caseCode ? Number(depositForm.caseCode) : null,
        description: depositForm.description,
        reference: depositForm.reference,
      });
      setOpenDeposit(false);
      setSnackbar({ open: true, severity: "success", message: t("trust.depositCreated") });
      await loadOverview();
      await loadLedger(depositForm.customerId);
    } catch (error: any) {
      setSnackbar({
        open: true,
        severity: "error",
        message: error?.response?.data?.message || t("trust.failedCreateDeposit"),
      });
    }
  }

  async function submitWithdrawal() {
    try {
      await api.post("/TrustAccounting/withdrawals", {
        customerId: withdrawalForm.customerId,
        amount: Number(withdrawalForm.amount),
        operationDate: withdrawalForm.operationDate,
        caseCode: withdrawalForm.caseCode ? Number(withdrawalForm.caseCode) : null,
        description: withdrawalForm.description,
        reference: withdrawalForm.reference,
      });
      setOpenWithdrawal(false);
      setSnackbar({ open: true, severity: "success", message: t("trust.withdrawalCreated") });
      await loadOverview();
      await loadLedger(withdrawalForm.customerId);
    } catch (error: any) {
      setSnackbar({
        open: true,
        severity: "error",
        message: error?.response?.data?.message || t("trust.failedCreateWithdrawal"),
      });
    }
  }

  async function submitAdjustment() {
    try {
      await api.post("/TrustAccounting/adjustments", {
        customerId: adjustmentForm.customerId,
        amount: Number(adjustmentForm.amount),
        operationDate: adjustmentForm.operationDate,
        caseCode: adjustmentForm.caseCode ? Number(adjustmentForm.caseCode) : null,
        direction: adjustmentForm.direction,
        description: adjustmentForm.description,
        reference: adjustmentForm.reference,
      });
      setOpenAdjustment(false);
      setSnackbar({ open: true, severity: "success", message: t("trust.adjustmentCreated") });
      await loadOverview();
      await loadLedger(adjustmentForm.customerId);
    } catch (error: any) {
      setSnackbar({
        open: true,
        severity: "error",
        message: error?.response?.data?.message || t("trust.failedCreateAdjustment"),
      });
    }
  }

  async function submitReconciliation() {
    try {
      await api.post("/TrustAccounting/reconciliations", {
        reconciliationDate: newReconciliationForm.reconciliationDate,
        bankStatementBalance: Number(newReconciliationForm.bankStatementBalance),
        notes: newReconciliationForm.notes,
      });
      setOpenReconciliation(false);
      setSnackbar({ open: true, severity: "success", message: t("trust.reconciliationCreated") });
      await loadOverview();
      await loadReconciliations(1);
    } catch (error: any) {
      setSnackbar({
        open: true,
        severity: "error",
        message: error?.response?.data?.message || t("trust.failedCreateReconciliation"),
      });
    }
  }

  async function exportLedger(format: "csv" | "pdf") {
    if (!selectedCustomerId) return;

    try {
      const params: Record<string, string> = { format };
      if (ledgerFromDate) params.fromDate = ledgerFromDate;
      if (ledgerToDate) params.toDate = ledgerToDate;

      const response = await api.get(`/TrustAccounting/accounts/${selectedCustomerId}/ledger/export`, {
        params,
        responseType: "blob",
      });

      const url = window.URL.createObjectURL(response.data);
      const a = document.createElement("a");
      a.href = url;
      a.download = `trust-ledger-${selectedCustomerId}.${format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch {
      setSnackbar({ open: true, severity: "error", message: t("trust.failedExportLedger") });
    }
  }

  async function exportReconciliations(format: "csv" | "pdf") {
    try {
      const params: Record<string, string> = { format };
      if (reconciliationFromDate) params.fromDate = reconciliationFromDate;
      if (reconciliationToDate) params.toDate = reconciliationToDate;

      const response = await api.get("/TrustAccounting/reconciliations/export", {
        params,
        responseType: "blob",
      });

      const url = window.URL.createObjectURL(response.data);
      const a = document.createElement("a");
      a.href = url;
      a.download = `trust-reconciliations.${format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch {
      setSnackbar({ open: true, severity: "error", message: t("trust.failedExportReconciliations") });
    }
  }

  function accountNameById(customerId: number) {
    return accounts.find((a) => a.customerId === customerId)?.customerName || "-";
  }

  return (
    <Box>
      <Stack direction={{ xs: "column", md: "row" }} justifyContent="space-between" alignItems={{ xs: "flex-start", md: "center" }} spacing={2} sx={{ mb: 3 }}>
        <Stack direction="row" spacing={1.5} alignItems="center">
          <TrustIcon color="primary" />
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              {isEmployeeOnly ? t("trust.employeeTitle", { defaultValue: "Assigned Trust Ledger" }) : t("trust.management")}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {isEmployeeOnly
                ? t("trust.employeeSubtitle", { defaultValue: "Read-only balances and ledgers for customers linked to your assigned cases." })
                : t("trust.subtitle", { defaultValue: "Manage trust balances, ledgers, and reconciliations." })}
            </Typography>
          </Box>
        </Stack>
        <Stack direction="row" spacing={1.5}>
          <Button variant="outlined" startIcon={<RefreshIcon />} onClick={() => void loadOverview()} disabled={loading}>
            {t("common.refresh")}
          </Button>
        </Stack>
      </Stack>

      {isEmployeeOnly && (
        <Alert severity="info" sx={{ mb: 2 }}>
          {t("trust.employeeHint", { defaultValue: "You can review only the customers assigned to your cases. Reconciliations and adjustments stay admin-only." })}
        </Alert>
      )}

      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid size={{ xs: 12, md: 3 }}>
          <Card><CardContent><Typography color="text.secondary">{t("trust.bookBalance")}</Typography><Typography variant="h6">{formatCurrency(summary?.bookBalance || 0)}</Typography></CardContent></Card>
        </Grid>
        <Grid size={{ xs: 12, md: 3 }}>
          <Card><CardContent><Typography color="text.secondary">{t("trust.clientLedgerBalance")}</Typography><Typography variant="h6">{formatCurrency(summary?.totalClientLedgerBalance || 0)}</Typography></CardContent></Card>
        </Grid>
        <Grid size={{ xs: 12, md: 3 }}>
          <Card><CardContent><Typography color="text.secondary">{t("trust.activeAccounts")}</Typography><Typography variant="h6">{summary?.activeClientAccounts || 0}</Typography></CardContent></Card>
        </Grid>
        <Grid size={{ xs: 12, md: 3 }}>
          <Card><CardContent><Typography color="text.secondary">{t("trust.negativeAccounts")}</Typography><Typography variant="h6">{summary?.negativeBalanceAccounts || 0}</Typography></CardContent></Card>
        </Grid>
      </Grid>

      <Paper sx={{ mb: 2 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)}>
          <Tab label={t("trust.accounts")} />
          <Tab label={t("trust.ledger")} />
          {canManageTrust && <Tab label={t("trust.reconciliations")} />}
        </Tabs>
      </Paper>

      {tab === 0 && (
        <Paper sx={{ p: 2 }}>
          <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ mb: 2 }}>
            <TextField
              label={t("common.search")}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              fullWidth
            />
          </Stack>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t("billing.customer")}</TableCell>
                <TableCell>{t("trust.currentBalance")}</TableCell>
                <TableCell>{t("trust.lastMovementDate")}</TableCell>
                <TableCell>{t("common.actions")}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {accounts.map((a) => (
                <TableRow key={a.customerId}>
                  <TableCell>{a.customerName || "-"}</TableCell>
                  <TableCell>{formatCurrency(a.currentBalance)}</TableCell>
                  <TableCell>{a.lastMovementDate || "-"}</TableCell>
                  <TableCell>
                    <Button
                      size="small"
                      onClick={() => {
                        setSelectedCustomerId(a.customerId);
                        setDepositForm((p) => ({ ...p, customerId: a.customerId }));
                        setWithdrawalForm((p) => ({ ...p, customerId: a.customerId }));
                        setAdjustmentForm((p) => ({ ...p, customerId: a.customerId }));
                        setTab(1);
                      }}
                    >
                      {t("trust.viewLedger")}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {accounts.length === 0 && (
                <TableRow>
                  <TableCell colSpan={4} align="center">{t("common.noData")}</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </Paper>
      )}

      {tab === 1 && (
        <Paper sx={{ p: 2 }}>
          <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ mb: 2 }}>
            <SearchableSelect<number>
              label={t("billing.customer")}
              value={selectedCustomerId || null}
              onChange={(value) => setSelectedCustomerId(value ?? 0)}
              options={accountOptions.map((option) => ({
                value: option.value,
                label: option.label,
              }))}
              sx={{ minWidth: 260 }}
            />
            <TextField label={t("billing.fromDate")} type="date" InputLabelProps={{ shrink: true }} value={ledgerFromDate} onChange={(e) => setLedgerFromDate(e.target.value)} />
            <TextField label={t("billing.toDate")} type="date" InputLabelProps={{ shrink: true }} value={ledgerToDate} onChange={(e) => setLedgerToDate(e.target.value)} />
            <Button variant="outlined" onClick={() => void loadLedger(selectedCustomerId)}>{t("common.filter")}</Button>
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => void exportLedger("csv")} disabled={!selectedCustomerId}>CSV</Button>
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => void exportLedger("pdf")} disabled={!selectedCustomerId}>PDF</Button>
          </Stack>

          {canManageTrust && (
            <Stack direction={{ xs: "column", md: "row" }} spacing={1.5} sx={{ mb: 2 }}>
              <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDeposit(true)}>{t("trust.addDeposit")}</Button>
              <Button variant="contained" color="warning" startIcon={<AddIcon />} onClick={() => setOpenWithdrawal(true)}>{t("trust.addWithdrawal")}</Button>
              <Button variant="contained" color="secondary" startIcon={<AddIcon />} onClick={() => setOpenAdjustment(true)}>{t("trust.addAdjustment")}</Button>
            </Stack>
          )}

          <Typography sx={{ mb: 1, color: "text.secondary" }}>
            {selectedCustomerId ? `${t("billing.customer")}: ${accountNameById(selectedCustomerId)}` : "-"}
          </Typography>

          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t("billing.date")}</TableCell>
                <TableCell>{t("cases.type")}</TableCell>
                <TableCell>{t("billing.amount")}</TableCell>
                <TableCell>{t("trust.runningBalance")}</TableCell>
                <TableCell>{t("cases.caseCode")}</TableCell>
                <TableCell>{t("billing.notes")}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {ledgerRows.map((row) => (
                <TableRow key={row.id}>
                  <TableCell>{row.operationDate}</TableCell>
                  <TableCell>{row.entryType}</TableCell>
                  <TableCell>{formatCurrency(row.amount)}</TableCell>
                  <TableCell>{formatCurrency(row.runningBalance)}</TableCell>
                  <TableCell>{row.caseCode || "-"}</TableCell>
                  <TableCell>{row.description || "-"}</TableCell>
                </TableRow>
              ))}
              {ledgerRows.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} align="center">{t("common.noData")}</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </Paper>
      )}

      {canManageTrust && tab === 2 && (
        <Paper sx={{ p: 2 }}>
          <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ mb: 2 }}>
            <TextField label={t("billing.fromDate")} type="date" InputLabelProps={{ shrink: true }} value={reconciliationFromDate} onChange={(e) => setReconciliationFromDate(e.target.value)} />
            <TextField label={t("billing.toDate")} type="date" InputLabelProps={{ shrink: true }} value={reconciliationToDate} onChange={(e) => setReconciliationToDate(e.target.value)} />
            <Button variant="outlined" onClick={() => void loadReconciliations(1)}>{t("common.filter")}</Button>
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => void exportReconciliations("csv")}>CSV</Button>
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => void exportReconciliations("pdf")}>PDF</Button>
            {canManageTrust && (
              <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenReconciliation(true)}>
                {t("trust.createReconciliation")}
              </Button>
            )}
          </Stack>

          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t("billing.date")}</TableCell>
                <TableCell>{t("trust.bankStatementBalance")}</TableCell>
                <TableCell>{t("trust.bookBalance")}</TableCell>
                <TableCell>{t("trust.clientLedgerBalance")}</TableCell>
                <TableCell>{t("trust.bankToBookDifference")}</TableCell>
                <TableCell>{t("billing.notes")}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(reconciliations?.items || []).map((r) => (
                <TableRow key={r.id}>
                  <TableCell>{r.reconciliationDate}</TableCell>
                  <TableCell>{formatCurrency(r.bankStatementBalance)}</TableCell>
                  <TableCell>{formatCurrency(r.bookBalance)}</TableCell>
                  <TableCell>{formatCurrency(r.clientLedgerBalance)}</TableCell>
                  <TableCell>{formatCurrency(r.bankToBookDifference)}</TableCell>
                  <TableCell>{r.notes || "-"}</TableCell>
                </TableRow>
              ))}
              {(reconciliations?.items?.length || 0) === 0 && (
                <TableRow>
                  <TableCell colSpan={6} align="center">{t("common.noData")}</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>

          <Stack direction="row" spacing={1.5} sx={{ mt: 2 }}>
            <Button
              variant="outlined"
              disabled={!reconciliations || reconciliationPage <= 1}
              onClick={() => {
                const next = Math.max(1, reconciliationPage - 1);
                setReconciliationPage(next);
                void loadReconciliations(next);
              }}
            >
              {t("app.previous")}
            </Button>
            <Typography sx={{ alignSelf: "center" }}>
              {reconciliationPage} / {reconciliations?.totalPages || 1}
            </Typography>
            <Button
              variant="outlined"
              disabled={!reconciliations || reconciliationPage >= (reconciliations?.totalPages || 1)}
              onClick={() => {
                const next = reconciliationPage + 1;
                setReconciliationPage(next);
                void loadReconciliations(next);
              }}
            >
              {t("app.next")}
            </Button>
          </Stack>
        </Paper>
      )}

      <Dialog open={openDeposit} onClose={() => setOpenDeposit(false)} fullWidth maxWidth="sm">
        <DialogTitle>{t("trust.addDeposit")}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <SearchableSelect<number>
              label={t("billing.customer")}
              value={depositForm.customerId || null}
              onChange={(value) => setDepositForm((p) => ({ ...p, customerId: value ?? 0 }))}
              options={accountOptions.map((option) => ({
                value: option.value,
                label: option.label,
              }))}
            />
            <TextField type="number" label={t("billing.amount")} value={depositForm.amount} onChange={(e) => setDepositForm((p) => ({ ...p, amount: Number(e.target.value) }))} />
            <TextField type="date" label={t("billing.date")} InputLabelProps={{ shrink: true }} value={depositForm.operationDate} onChange={(e) => setDepositForm((p) => ({ ...p, operationDate: e.target.value }))} />
            <TextField type="number" label={t("cases.caseCode")} value={depositForm.caseCode} onChange={(e) => setDepositForm((p) => ({ ...p, caseCode: e.target.value }))} />
            <TextField label={t("billing.notes")} value={depositForm.description} onChange={(e) => setDepositForm((p) => ({ ...p, description: e.target.value }))} />
            <TextField label={t("trust.reference")} value={depositForm.reference} onChange={(e) => setDepositForm((p) => ({ ...p, reference: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDeposit(false)}>{t("common.cancel")}</Button>
          <Button onClick={() => void submitDeposit()} variant="contained">{t("common.create")}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={openWithdrawal} onClose={() => setOpenWithdrawal(false)} fullWidth maxWidth="sm">
        <DialogTitle>{t("trust.addWithdrawal")}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <SearchableSelect<number>
              label={t("billing.customer")}
              value={withdrawalForm.customerId || null}
              onChange={(value) => setWithdrawalForm((p) => ({ ...p, customerId: value ?? 0 }))}
              options={accountOptions.map((option) => ({
                value: option.value,
                label: option.label,
              }))}
            />
            <TextField type="number" label={t("billing.amount")} value={withdrawalForm.amount} onChange={(e) => setWithdrawalForm((p) => ({ ...p, amount: Number(e.target.value) }))} />
            <TextField type="date" label={t("billing.date")} InputLabelProps={{ shrink: true }} value={withdrawalForm.operationDate} onChange={(e) => setWithdrawalForm((p) => ({ ...p, operationDate: e.target.value }))} />
            <TextField type="number" label={t("cases.caseCode")} value={withdrawalForm.caseCode} onChange={(e) => setWithdrawalForm((p) => ({ ...p, caseCode: e.target.value }))} />
            <TextField label={t("billing.notes")} value={withdrawalForm.description} onChange={(e) => setWithdrawalForm((p) => ({ ...p, description: e.target.value }))} />
            <TextField label={t("trust.reference")} value={withdrawalForm.reference} onChange={(e) => setWithdrawalForm((p) => ({ ...p, reference: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenWithdrawal(false)}>{t("common.cancel")}</Button>
          <Button onClick={() => void submitWithdrawal()} variant="contained">{t("common.create")}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={openAdjustment} onClose={() => setOpenAdjustment(false)} fullWidth maxWidth="sm">
        <DialogTitle>{t("trust.addAdjustment")}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <SearchableSelect<number>
              label={t("billing.customer")}
              value={adjustmentForm.customerId || null}
              onChange={(value) => setAdjustmentForm((p) => ({ ...p, customerId: value ?? 0 }))}
              options={accountOptions.map((option) => ({
                value: option.value,
                label: option.label,
              }))}
            />
            <TextField type="number" label={t("billing.amount")} value={adjustmentForm.amount} onChange={(e) => setAdjustmentForm((p) => ({ ...p, amount: Number(e.target.value) }))} />
            <TextField type="date" label={t("billing.date")} InputLabelProps={{ shrink: true }} value={adjustmentForm.operationDate} onChange={(e) => setAdjustmentForm((p) => ({ ...p, operationDate: e.target.value }))} />
            <TextField type="number" label={t("cases.caseCode")} value={adjustmentForm.caseCode} onChange={(e) => setAdjustmentForm((p) => ({ ...p, caseCode: e.target.value }))} />
            <SearchableSelect<string>
              label={t("cases.type")}
              value={adjustmentForm.direction}
              onChange={(value) => setAdjustmentForm((p) => ({ ...p, direction: value ?? "Increase" }))}
              options={[
                { value: "Increase", label: t("trust.increase") },
                { value: "Decrease", label: t("trust.decrease") },
              ]}
              disableClearable
            />
            <TextField label={t("billing.notes")} value={adjustmentForm.description} onChange={(e) => setAdjustmentForm((p) => ({ ...p, description: e.target.value }))} />
            <TextField label={t("trust.reference")} value={adjustmentForm.reference} onChange={(e) => setAdjustmentForm((p) => ({ ...p, reference: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenAdjustment(false)}>{t("common.cancel")}</Button>
          <Button onClick={() => void submitAdjustment()} variant="contained">{t("common.create")}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={openReconciliation} onClose={() => setOpenReconciliation(false)} fullWidth maxWidth="sm">
        <DialogTitle>{t("trust.createReconciliation")}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField type="date" label={t("billing.date")} InputLabelProps={{ shrink: true }} value={newReconciliationForm.reconciliationDate} onChange={(e) => setNewReconciliationForm((p) => ({ ...p, reconciliationDate: e.target.value }))} />
            <TextField type="number" label={t("trust.bankStatementBalance")} value={newReconciliationForm.bankStatementBalance} onChange={(e) => setNewReconciliationForm((p) => ({ ...p, bankStatementBalance: Number(e.target.value) }))} />
            <TextField label={t("billing.notes")} value={newReconciliationForm.notes} onChange={(e) => setNewReconciliationForm((p) => ({ ...p, notes: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenReconciliation(false)}>{t("common.cancel")}</Button>
          <Button onClick={() => void submitReconciliation()} variant="contained">{t("common.create")}</Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={5000}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
      >
        <Alert severity={snackbar.severity} onClose={() => setSnackbar((s) => ({ ...s, open: false }))} variant="filled">
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
