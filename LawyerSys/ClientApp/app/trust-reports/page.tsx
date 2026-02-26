"use client";

import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  Typography,
} from "@mui/material";
import { Refresh as RefreshIcon, ShowChart as ChartIcon } from "@mui/icons-material";
import api from "../../src/services/api";
import { useTranslation } from "react-i18next";

type TrustAccount = {
  customerId: number;
  customerName: string;
};

type MonthlyPoint = {
  year: number;
  month: number;
  deposits: number;
  withdrawals: number;
  netFlow: number;
  endingBalance: number;
};

type ReconciliationPoint = {
  year: number;
  month: number;
  count: number;
  averageBankToBookDifference: number;
  maxAbsoluteBankToBookDifference: number;
};

type TrendsReport = {
  months: number;
  fromMonth: string;
  toDate: string;
  customerId?: number | null;
  customerName?: string | null;
  totalDeposits: number;
  totalWithdrawals: number;
  netFlow: number;
  openingBalance: number;
  endingBalance: number;
  monthlyPoints: MonthlyPoint[];
  reconciliationPoints: ReconciliationPoint[];
};

const monthLabel = (year: number, month: number) => `${String(month).padStart(2, "0")}/${String(year).slice(-2)}`;
const money = (value: number) =>
  new Intl.NumberFormat(undefined, { style: "currency", currency: "SAR", maximumFractionDigits: 2 }).format(value || 0);

function MonthlyBarChart({ points, t }: { points: MonthlyPoint[]; t: any }) {
  const max = Math.max(1, ...points.flatMap((p) => [p.deposits, p.withdrawals]));

  return (
    <Box>
      <Stack direction="row" spacing={2} sx={{ mb: 1.5 }}>
        <Stack direction="row" spacing={1} alignItems="center"><Box sx={{ width: 12, height: 12, bgcolor: "success.main", borderRadius: 0.5 }} /><Typography variant="caption">{t("trustReports.deposits")}</Typography></Stack>
        <Stack direction="row" spacing={1} alignItems="center"><Box sx={{ width: 12, height: 12, bgcolor: "error.main", borderRadius: 0.5 }} /><Typography variant="caption">{t("trustReports.withdrawals")}</Typography></Stack>
      </Stack>
      <Box sx={{ display: "grid", gridTemplateColumns: `repeat(${Math.max(points.length, 1)}, minmax(36px, 1fr))`, gap: 1, alignItems: "end", height: 220 }}>
        {points.map((p) => (
          <Box key={`${p.year}-${p.month}`} sx={{ textAlign: "center" }}>
            <Box sx={{ height: 170, display: "flex", alignItems: "end", justifyContent: "center", gap: 0.5 }}>
              <Box title={`${t("trustReports.deposits")}: ${money(p.deposits)}`} sx={{ width: 10, height: `${(p.deposits / max) * 100}%`, minHeight: p.deposits > 0 ? 4 : 0, bgcolor: "success.main", borderRadius: 0.8 }} />
              <Box title={`${t("trustReports.withdrawals")}: ${money(p.withdrawals)}`} sx={{ width: 10, height: `${(p.withdrawals / max) * 100}%`, minHeight: p.withdrawals > 0 ? 4 : 0, bgcolor: "error.main", borderRadius: 0.8 }} />
            </Box>
            <Typography variant="caption" color="text.secondary">{monthLabel(p.year, p.month)}</Typography>
          </Box>
        ))}
      </Box>
    </Box>
  );
}

function DualLineChart({ points, t }: { points: MonthlyPoint[]; t: any }) {
  const netValues = points.map((p) => p.netFlow);
  const endingValues = points.map((p) => p.endingBalance);
  const all = [...netValues, ...endingValues];
  const min = Math.min(0, ...all);
  const max = Math.max(1, ...all);
  const range = max - min || 1;
  const width = 760;
  const height = 230;
  const pad = 24;

  const pointToSvg = (index: number, value: number) => {
    const x = pad + (index * (width - pad * 2)) / Math.max(points.length - 1, 1);
    const y = pad + ((max - value) * (height - pad * 2)) / range;
    return `${x},${y}`;
  };

  const netPolyline = points.map((p, i) => pointToSvg(i, p.netFlow)).join(" ");
  const endingPolyline = points.map((p, i) => pointToSvg(i, p.endingBalance)).join(" ");
  const zeroY = pad + ((max - 0) * (height - pad * 2)) / range;

  return (
    <Box>
      <Stack direction="row" spacing={2} sx={{ mb: 1.5 }}>
        <Stack direction="row" spacing={1} alignItems="center"><Box sx={{ width: 12, height: 3, bgcolor: "info.main", borderRadius: 1 }} /><Typography variant="caption">{t("trustReports.netFlow")}</Typography></Stack>
        <Stack direction="row" spacing={1} alignItems="center"><Box sx={{ width: 12, height: 3, bgcolor: "primary.main", borderRadius: 1 }} /><Typography variant="caption">{t("trustReports.endingBalance")}</Typography></Stack>
      </Stack>
      <Box sx={{ overflowX: "auto" }}>
        <svg viewBox={`0 0 ${width} ${height}`} width="100%" height={height}>
          <line x1={pad} y1={zeroY} x2={width - pad} y2={zeroY} stroke="#cbd5e1" strokeWidth="1" />
          <polyline fill="none" stroke="#0284c7" strokeWidth="2.5" points={netPolyline} />
          <polyline fill="none" stroke="#4f46e5" strokeWidth="2.5" points={endingPolyline} />
          {points.map((p, i) => {
            const [netX, netY] = pointToSvg(i, p.netFlow).split(",").map(Number);
            const [endX, endY] = pointToSvg(i, p.endingBalance).split(",").map(Number);
            return (
              <g key={`${p.year}-${p.month}`}>
                <circle cx={netX} cy={netY} r="3" fill="#0284c7" />
                <circle cx={endX} cy={endY} r="3" fill="#4f46e5" />
              </g>
            );
          })}
        </svg>
      </Box>
      <Box sx={{ display: "grid", gridTemplateColumns: `repeat(${Math.max(points.length, 1)}, minmax(36px, 1fr))`, gap: 1 }}>
        {points.map((p) => <Typography key={`${p.year}-${p.month}`} variant="caption" color="text.secondary" align="center">{monthLabel(p.year, p.month)}</Typography>)}
      </Box>
    </Box>
  );
}

function ReconciliationChart({ points, t }: { points: ReconciliationPoint[]; t: any }) {
  const max = Math.max(1, ...points.map((p) => p.maxAbsoluteBankToBookDifference));
  return (
    <Box>
      <Typography variant="caption" color="text.secondary">{t("trustReports.maxBankToBookDifference")}</Typography>
      <Box sx={{ display: "grid", gridTemplateColumns: `repeat(${Math.max(points.length, 1)}, minmax(36px, 1fr))`, gap: 1, alignItems: "end", height: 210, mt: 1 }}>
        {points.map((p) => (
          <Box key={`${p.year}-${p.month}`} sx={{ textAlign: "center" }}>
            <Box sx={{ height: 160, display: "flex", alignItems: "end", justifyContent: "center" }}>
              <Box title={`${t("trustReports.maxBankToBookDifference")}: ${money(p.maxAbsoluteBankToBookDifference)}`} sx={{ width: 16, height: `${(p.maxAbsoluteBankToBookDifference / max) * 100}%`, minHeight: p.maxAbsoluteBankToBookDifference > 0 ? 4 : 0, bgcolor: "warning.main", borderRadius: 0.8 }} />
            </Box>
            <Typography variant="caption" color="text.secondary">{monthLabel(p.year, p.month)}</Typography>
            <Typography variant="caption" display="block" color="text.secondary">n={p.count}</Typography>
          </Box>
        ))}
      </Box>
    </Box>
  );
}

export default function TrustReportsPage() {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [months, setMonths] = useState(12);
  const [customerId, setCustomerId] = useState<string>("");
  const [accounts, setAccounts] = useState<TrustAccount[]>([]);
  const [report, setReport] = useState<TrendsReport | null>(null);

  const monthsOptions = useMemo(() => [6, 12, 18, 24], []);

  async function load() {
    setLoading(true);
    setError("");
    try {
      const params: Record<string, number> = { months };
      if (customerId) params.customerId = Number(customerId);

      const [accountsRes, reportRes] = await Promise.all([
        api.get("/TrustAccounting/accounts"),
        api.get("/TrustAccounting/reports/monthly-trends", { params }),
      ]);

      setAccounts(accountsRes.data || []);
      setReport(reportRes.data || null);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("trustReports.failedLoad"));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
  }, [months, customerId]);

  return (
    <Box>
      <Stack direction={{ xs: "column", md: "row" }} justifyContent="space-between" alignItems={{ xs: "flex-start", md: "center" }} spacing={2} sx={{ mb: 2 }}>
        <Box>
          <Stack direction="row" spacing={1} alignItems="center">
            <ChartIcon color="primary" />
            <Typography variant="h5" sx={{ fontWeight: 800 }}>{t("trustReports.title")}</Typography>
          </Stack>
          <Typography variant="body2" color="text.secondary">{t("trustReports.subtitle")}</Typography>
        </Box>
        <Stack direction="row" spacing={1.5}>
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>{t("trustReports.months")}</InputLabel>
            <Select value={months} label={t("trustReports.months")} onChange={(e) => setMonths(Number(e.target.value))}>
              {monthsOptions.map((m) => <MenuItem key={m} value={m}>{m}</MenuItem>)}
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 240 }}>
            <InputLabel>{t("billing.customer")}</InputLabel>
            <Select value={customerId} label={t("billing.customer")} onChange={(e) => setCustomerId(String(e.target.value))}>
              <MenuItem value="">{t("trustReports.allCustomers")}</MenuItem>
              {accounts.map((a) => <MenuItem key={a.customerId} value={String(a.customerId)}>{a.customerName} (#{a.customerId})</MenuItem>)}
            </Select>
          </FormControl>
          <Button variant="outlined" startIcon={<RefreshIcon />} onClick={() => void load()} disabled={loading}>{t("trustReports.refresh")}</Button>
        </Stack>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid size={{ xs: 12, md: 3 }}><Card><CardContent><Typography color="text.secondary">{t("trustReports.deposits")}</Typography><Typography variant="h6">{money(report?.totalDeposits || 0)}</Typography></CardContent></Card></Grid>
        <Grid size={{ xs: 12, md: 3 }}><Card><CardContent><Typography color="text.secondary">{t("trustReports.withdrawals")}</Typography><Typography variant="h6">{money(report?.totalWithdrawals || 0)}</Typography></CardContent></Card></Grid>
        <Grid size={{ xs: 12, md: 3 }}><Card><CardContent><Typography color="text.secondary">{t("trustReports.netFlow")}</Typography><Typography variant="h6">{money(report?.netFlow || 0)}</Typography></CardContent></Card></Grid>
        <Grid size={{ xs: 12, md: 3 }}><Card><CardContent><Typography color="text.secondary">{t("trustReports.endingBalance")}</Typography><Typography variant="h6">{money(report?.endingBalance || 0)}</Typography></CardContent></Card></Grid>
      </Grid>

      <Grid container spacing={2}>
        <Grid size={{ xs: 12 }}>
          <Paper sx={{ p: 2.5 }}>
            <Typography variant="h6" sx={{ mb: 1.5 }}>{t("trustReports.depositWithdrawalTrend")}</Typography>
            {report?.monthlyPoints?.length ? <MonthlyBarChart points={report.monthlyPoints} t={t} /> : <Typography color="text.secondary">{t("trustReports.noData")}</Typography>}
          </Paper>
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Paper sx={{ p: 2.5 }}>
            <Typography variant="h6" sx={{ mb: 1.5 }}>{t("trustReports.netEndingTrend")}</Typography>
            {report?.monthlyPoints?.length ? <DualLineChart points={report.monthlyPoints} t={t} /> : <Typography color="text.secondary">{t("trustReports.noData")}</Typography>}
          </Paper>
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Paper sx={{ p: 2.5 }}>
            <Typography variant="h6" sx={{ mb: 1.5 }}>{t("trustReports.reconciliationTrend")}</Typography>
            {report?.reconciliationPoints?.length ? <ReconciliationChart points={report.reconciliationPoints} t={t} /> : <Typography color="text.secondary">{t("trustReports.noData")}</Typography>}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
