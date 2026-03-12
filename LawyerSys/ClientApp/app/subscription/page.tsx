"use client";

import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
} from "@mui/material";
import { Grid } from "@mui/material";
import WorkspacePremiumIcon from "@mui/icons-material/WorkspacePremium";
import { useTranslation } from "react-i18next";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";

type PackageCycleOption = {
  subscriptionPackageId: number;
  billingCycle: string;
  price: number;
  currency: string;
  isActive: boolean;
};

type AvailablePackage = {
  name: string;
  description: string;
  officeSize: string;
  features: string[];
  monthlyOption?: PackageCycleOption | null;
  annualOption?: PackageCycleOption | null;
};

type BillingTransaction = {
  id: number;
  packageName: string;
  billingCycle: string;
  status: string;
  amount: number;
  currency: string;
  dueDateUtc: string;
  paidAtUtc?: string | null;
  periodStartUtc: string;
  periodEndUtc: string;
  reference: string;
  notes: string;
};

type CurrentSubscription = {
  tenantId: number;
  tenantName: string;
  tenantEmail: string;
  status: string;
  packageId: number;
  packageName: string;
  packageDescription: string;
  billingCycle: string;
  officeSize: string;
  price: number;
  currency: string;
  packageFeatures: string[];
  startDateUtc: string;
  endDateUtc: string;
  nextBillingDateUtc: string;
  transactions: BillingTransaction[];
  availablePackages: AvailablePackage[];
};

export default function SubscriptionPage() {
  const { t } = useTranslation();
  const { hasRole } = useAuth();
  const [data, setData] = useState<CurrentSubscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [pendingPackageId, setPendingPackageId] = useState<number | null>(null);
  const isSuperAdmin = hasRole("SuperAdmin");
  const canManageSubscription = hasRole("Admin") && !isSuperAdmin;

  useEffect(() => {
    if (isSuperAdmin) {
      setLoading(false);
      return;
    }

    let mounted = true;
    (async () => {
      try {
        const response = await api.get("/TenantSubscriptions/current");
        if (!mounted) return;
        setData(response.data || null);
      } catch (e: any) {
        if (!mounted) return;
        setError(e?.response?.data?.message || t("subscription.failedLoad"));
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    })();

    return () => {
      mounted = false;
    };
  }, [isSuperAdmin, t]);

  const summaryCards = useMemo(() => {
    if (!data) return [];

    return [
      { key: "price", value: `${data.price.toFixed(0)} ${data.currency}` },
      { key: "status", value: t(`subscription.status.${data.status.toLowerCase()}`, { defaultValue: data.status }) },
      { key: "nextBilling", value: new Date(data.nextBillingDateUtc).toLocaleDateString() },
      { key: "endDate", value: new Date(data.endDateUtc).toLocaleDateString() },
    ];
  }, [data, t]);

  const changePackage = async (packageId: number) => {
    setPendingPackageId(packageId);
    setError("");
    try {
      const response = await api.put("/TenantSubscriptions/current/package", { subscriptionPackageId: packageId });
      setData(response.data || null);
    } catch (e: any) {
      setError(e?.response?.data?.message || t("subscription.failedLoad"));
    } finally {
      setPendingPackageId(null);
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (isSuperAdmin) {
    return (
      <Alert severity="info">
        {t("subscription.superAdminNotice", { defaultValue: "Super admin billing is available from Administration." })}
      </Alert>
    );
  }

  return (
    <Box sx={{ pb: 4 }}>
      <Paper
        elevation={0}
        sx={{
          p: { xs: 2.5, md: 3 },
          mb: 3,
          borderRadius: 4,
          border: "1px solid",
          borderColor: "divider",
          display: "flex",
          alignItems: "center",
          gap: 1.5,
        }}
      >
        <WorkspacePremiumIcon color="primary" />
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800 }}>
            {t("subscription.title", { defaultValue: "Subscription" })}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {t("subscription.subtitle", { defaultValue: "Review your current package and tenant billing history." })}
          </Typography>
        </Box>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {data && (
        <>
          <Grid container spacing={2} sx={{ mb: 3 }}>
            {summaryCards.map((card) => (
              <Grid key={card.key} size={{ xs: 12, sm: 6, md: 3 }}>
                <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider" }}>
                  <CardContent>
                    <Typography variant="subtitle2" color="text.secondary">
                      {t(`subscription.cards.${card.key}`)}
                    </Typography>
                    <Typography variant="h6" sx={{ fontWeight: 800, mt: 0.5 }}>
                      {card.value}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>

          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid size={{ xs: 12, md: 7 }}>
              <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", height: "100%" }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 800, mb: 1.5 }}>
                    {t("subscription.currentPackageTitle", { defaultValue: "Current subscription" })}
                  </Typography>
                  <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
                    {data.packageDescription}
                  </Typography>
                  <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap", mb: 2 }}>
                    <Chip label={t(`subscription.billingCycle.${data.billingCycle.toLowerCase()}`, { defaultValue: data.billingCycle })} />
                    <Chip color="primary" label={`${data.price.toFixed(0)} ${data.currency}`} />
                  </Box>
                  <Box sx={{ display: "grid", gap: 0.75, mb: 2 }}>
                    {(data.packageFeatures || []).map((feature) => (
                      <Typography key={feature} variant="body2" color="text.secondary">
                        • {feature}
                      </Typography>
                    ))}
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    {t("subscription.tenantEmail", { defaultValue: "Tenant email" })}: {data.tenantEmail || "-"}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid size={{ xs: 12, md: 5 }}>
              <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", height: "100%" }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 800, mb: 1.5 }}>
                    {t("subscription.availablePackages", { defaultValue: "Available packages" })}
                  </Typography>
                  <Box sx={{ display: "grid", gap: 1.25 }}>
                    {data.availablePackages.map((pkg) => (
                      <Paper key={pkg.officeSize} elevation={0} sx={{ p: 1.5, borderRadius: 2.5, border: "1px solid", borderColor: pkg.officeSize === data.officeSize ? "primary.main" : "divider" }}>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                          {pkg.description}
                        </Typography>
                        <Box sx={{ display: "grid", gap: 0.5, mb: 1.25 }}>
                          {(pkg.features || []).map((feature) => (
                            <Typography key={feature} variant="caption" color="text.secondary">
                              • {feature}
                            </Typography>
                          ))}
                        </Box>
                        <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
                          {pkg.monthlyOption && (
                            <Chip
                              size="small"
                              color={pkg.monthlyOption.subscriptionPackageId === data.packageId ? "primary" : "default"}
                              label={`${t('subscription.billingCycle.monthly', { defaultValue: 'Monthly' })}: ${pkg.monthlyOption.price.toFixed(0)} ${pkg.monthlyOption.currency}`}
                            />
                          )}
                          {pkg.annualOption && (
                            <Chip
                              size="small"
                              color={pkg.annualOption.subscriptionPackageId === data.packageId ? "primary" : "default"}
                              label={`${t('subscription.billingCycle.annual', { defaultValue: 'Annual' })}: ${pkg.annualOption.price.toFixed(0)} ${pkg.annualOption.currency}`}
                            />
                          )}
                        </Box>
                        <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap", mt: 1.25 }}>
                          {canManageSubscription && pkg.monthlyOption && pkg.monthlyOption.subscriptionPackageId !== data.packageId && (
                            <Button
                              size="small"
                              variant="outlined"
                              disabled={pendingPackageId === pkg.monthlyOption.subscriptionPackageId}
                              onClick={() => changePackage(pkg.monthlyOption!.subscriptionPackageId)}
                            >
                              {t("subscription.changePackageToMonthly", { defaultValue: "Switch to monthly" })}
                            </Button>
                          )}
                          {canManageSubscription && pkg.annualOption && pkg.annualOption.subscriptionPackageId !== data.packageId && (
                            <Button
                              size="small"
                              variant="outlined"
                              disabled={pendingPackageId === pkg.annualOption.subscriptionPackageId}
                              onClick={() => changePackage(pkg.annualOption!.subscriptionPackageId)}
                            >
                              {t("subscription.changePackageToAnnual", { defaultValue: "Switch to annual" })}
                            </Button>
                          )}
                        </Box>
                      </Paper>
                    ))}
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          <Typography variant="h6" sx={{ mb: 1.5, fontWeight: 800 }}>
            {t("subscription.transactionsTitle", { defaultValue: "Billing transactions" })}
          </Typography>
          <Paper elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", overflow: "hidden" }}>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>{t("subscription.table.package", { defaultValue: "Package" })}</TableCell>
                  <TableCell>{t("subscription.table.cycle", { defaultValue: "Cycle" })}</TableCell>
                  <TableCell>{t("subscription.table.amount", { defaultValue: "Amount" })}</TableCell>
                  <TableCell>{t("subscription.table.dueDate", { defaultValue: "Due date" })}</TableCell>
                  <TableCell>{t("subscription.table.status", { defaultValue: "Status" })}</TableCell>
                  <TableCell>{t("subscription.table.reference", { defaultValue: "Reference" })}</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {data.transactions.map((transaction) => (
                  <TableRow key={transaction.id} hover>
                    <TableCell>{transaction.packageName}</TableCell>
                    <TableCell>{t(`subscription.billingCycle.${transaction.billingCycle.toLowerCase()}`, { defaultValue: transaction.billingCycle })}</TableCell>
                    <TableCell>{transaction.amount.toFixed(2)} {transaction.currency}</TableCell>
                    <TableCell>{new Date(transaction.dueDateUtc).toLocaleDateString()}</TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        color={transaction.status === "Paid" ? "success" : transaction.status === "Pending" ? "warning" : "default"}
                        label={t(`subscription.status.${transaction.status.toLowerCase()}`, { defaultValue: transaction.status })}
                      />
                    </TableCell>
                    <TableCell>{transaction.reference || "-"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Paper>
        </>
      )}
    </Box>
  );
}
