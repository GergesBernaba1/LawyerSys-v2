"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
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
  useTheme,
} from "@mui/material";
import { Grid } from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import WorkspacePremiumIcon from "@mui/icons-material/WorkspacePremium";
import api from "../../../../src/services/api";
import { useAuth } from "../../../../src/services/auth";
import { useCurrency } from "../../../../src/hooks/useCurrency";

type PackageCycleOption = {
  subscriptionPackageId: number;
  billingCycle: string;
  price: number;
  currency: string;
  isActive: boolean;
};

type PackageCycleCard = {
  key: string;
  billingCycle: string;
  subscriptionPackageId: number;
  price: number;
  currency: string;
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
  tenantId: number;
  tenantName: string;
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

type TenantSubscriptionDetails = {
  hasSubscription: boolean;
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
  startDateUtc?: string | null;
  endDateUtc?: string | null;
  nextBillingDateUtc?: string | null;
  transactions: BillingTransaction[];
  availablePackages: AvailablePackage[];
};

function getStatusColor(status: string) {
  switch (status) {
    case "Active":
    case "Paid":
      return "success" as const;
    case "Pending":
      return "warning" as const;
    case "Overdue":
    case "Expired":
      return "error" as const;
    default:
      return "default" as const;
  }
}

export default function TenantSubscriptionAdminPage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const router = useRouter();
  const params = useParams() as { tenantId?: string } | undefined;
  const { user, isAuthenticated, hasRole } = useAuth();
  const { formatCurrency: formatProfileCurrency } = useCurrency();
  const isRTL = theme.direction === "rtl";
  const isSuperAdmin = hasRole("SuperAdmin");
  const tenantId = Number(params?.tenantId || 0);
  const locale = useMemo(
    () => ((i18n.resolvedLanguage || i18n.language || "en").startsWith("ar") ? "ar-SA" : "en-US"),
    [i18n.language, i18n.resolvedLanguage],
  );

  const [data, setData] = useState<TenantSubscriptionDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [pendingAction, setPendingAction] = useState<Record<string, boolean>>({});
  const [pendingPackageId, setPendingPackageId] = useState<number | null>(null);

  const formatDate = useCallback((value?: string | null) => {
    return value ? new Intl.DateTimeFormat(locale).format(new Date(value)) : "-";
  }, [locale]);

  const formatCurrency = useCallback((amount: number) => formatProfileCurrency(amount), [formatProfileCurrency]);

  useEffect(() => {
    if (isAuthenticated && !user) {
      return;
    }

    if (isAuthenticated && !isSuperAdmin) {
      router.replace("/dashboard");
    }
  }, [isAuthenticated, user, isSuperAdmin, router]);

  const loadSubscription = useCallback(async () => {
    if (!tenantId) {
      setLoading(false);
      setError(t("tenantsPage.subscriptionLoadFailed", { defaultValue: "Failed to load tenant subscription." }));
      return;
    }

    setLoading(true);
    setError("");

    try {
      const response = await api.get(`/TenantSubscriptions/admin/${tenantId}`, {
        skipTenantHeader: true,
        headers: { "Accept-Language": locale },
      } as any);
      setData(response.data || null);
    } catch (e: any) {
      setData(null);
      setError(
        e?.response?.data?.message || t("tenantsPage.subscriptionLoadFailed", { defaultValue: "Failed to load tenant subscription." }),
      );
    } finally {
      setLoading(false);
    }
  }, [tenantId, locale, t]);

  useEffect(() => {
    if (!isAuthenticated) {
      setLoading(false);
      return;
    }

    if (!user || !isSuperAdmin) {
      return;
    }

    void loadSubscription();
  }, [isAuthenticated, user, isSuperAdmin, loadSubscription]);

  const changePackage = async (packageId: number) => {
    if (!tenantId) {
      return;
    }

    setPendingPackageId(packageId);
    setError("");

    try {
      const response = await api.put(
        `/TenantSubscriptions/admin/${tenantId}/package`,
        { subscriptionPackageId: packageId },
        {
          skipTenantHeader: true,
          headers: { "Accept-Language": locale },
        } as any,
      );
      setData(response.data || null);
    } catch (e: any) {
      setError(
        e?.response?.data?.message || t("tenantsPage.packageUpdateFailed", { defaultValue: "Failed to update tenant package." }),
      );
    } finally {
      setPendingPackageId(null);
    }
  };

  const updateTransactionStatus = async (id: number, action: "pay" | "cancel") => {
    setPendingAction((prev) => ({ ...prev, [`billing-${id}`]: true }));
    setError("");

    try {
      await api.put(
        `/TenantSubscriptions/admin/transactions/${id}/${action}`,
        {},
        {
          skipTenantHeader: true,
          headers: { "Accept-Language": locale },
        } as any,
      );
      await loadSubscription();
    } catch (e: any) {
      setError(
        e?.response?.data?.message || t("tenantsPage.transactionUpdateFailed", { defaultValue: "Failed to update billing transaction." }),
      );
    } finally {
      setPendingAction((prev) => ({ ...prev, [`billing-${id}`]: false }));
    }
  };

  const summaryCards = useMemo(() => {
    if (!data || !data.hasSubscription) {
      return [];
    }

    return [
      { key: "price", value: formatCurrency(data.price) },
      { key: "status", value: t(`subscription.status.${data.status.toLowerCase()}`, { defaultValue: data.status }) },
      { key: "nextBilling", value: formatDate(data.nextBillingDateUtc) },
      { key: "endDate", value: formatDate(data.endDateUtc) },
    ];
  }, [data, t, formatCurrency, formatDate]);

  const packageCycleCards = useMemo(() => {
    if (!data) {
      return [];
    }

    const currentGroup = data.availablePackages.find(
      (pkg) =>
        pkg.monthlyOption?.subscriptionPackageId === data.packageId ||
        pkg.annualOption?.subscriptionPackageId === data.packageId,
    );

    const monthlyOption =
      currentGroup?.monthlyOption ||
      data.availablePackages.find((pkg) => pkg.monthlyOption)?.monthlyOption ||
      null;

    const annualOption =
      currentGroup?.annualOption ||
      data.availablePackages.find((pkg) => pkg.annualOption)?.annualOption ||
      null;

    return [
      monthlyOption
        ? {
            key: "monthly",
            billingCycle: "monthly",
            subscriptionPackageId: monthlyOption.subscriptionPackageId,
            price: monthlyOption.price,
            currency: monthlyOption.currency,
          }
        : null,
      annualOption
        ? {
            key: "annual",
            billingCycle: "annual",
            subscriptionPackageId: annualOption.subscriptionPackageId,
            price: annualOption.price,
            currency: annualOption.currency,
          }
        : null,
    ].filter((item): item is PackageCycleCard => item !== null);
  }, [data]);

  return (
    <Box dir={isRTL ? "rtl" : "ltr"} sx={{ pb: 4 }}>
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
          justifyContent: "space-between",
          gap: 2,
          flexWrap: "wrap",
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
          <WorkspacePremiumIcon color="primary" />
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              {data?.tenantName || t("tenantsPage.manageSubscription", { defaultValue: "Manage subscription" })}
            </Typography>
            <Typography variant="body2" color="text.secondary">
                      {t("tenantsPage.subscriptionPageSubtitle", {
                        defaultValue: "Review and manage this tenant subscription from a dedicated page.",
                      })}
            </Typography>
          </Box>
        </Box>

        <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
          <Button
            variant="outlined"
            startIcon={isRTL ? null : <ArrowBackIcon />}
            endIcon={isRTL ? <ArrowBackIcon sx={{ transform: "rotate(180deg)" }} /> : null}
            onClick={() => router.push("/tenants")}
          >
            {t("app.back", { defaultValue: "Back" })}
          </Button>
          <Button variant="outlined" onClick={() => void loadSubscription()} disabled={loading}>
            {t("common.refresh", { defaultValue: "Refresh" })}
          </Button>
        </Box>
      </Paper>

      {loading && (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      )}

      {!loading && error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {!loading && data && (
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

          {!data.hasSubscription && (
            <Alert severity="info" sx={{ mb: 3 }}>
              {t("tenantsPage.noPackageSelected", { defaultValue: "This tenant has not chosen any package yet." })}
            </Alert>
          )}

          <Grid container spacing={2} sx={{ mb: 3 }}>
            {data.hasSubscription && (
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
                      <Chip color="primary" label={formatCurrency(data.price)} />
                    </Box>
                    <Box sx={{ display: "grid", gap: 0.75, mb: 2 }}>
                      {(data.packageFeatures || []).map((feature) => (
                        <Typography key={feature} variant="body2" color="text.secondary">
                          - {feature}
                        </Typography>
                      ))}
                    </Box>
                    <Typography variant="body2" color="text.secondary">
                      {t("subscription.tenantEmail", { defaultValue: "Tenant email" })}: {data.tenantEmail || "-"}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            )}
            <Grid size={{ xs: 12, md: data.hasSubscription ? 5 : 12 }}>
              <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", height: "100%" }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 800, mb: 1.5 }}>
                    {t("subscription.availablePackages", { defaultValue: "Available packages" })}
                  </Typography>
                  <Box sx={{ display: "grid", gap: 1.25 }}>
                    {packageCycleCards.map((pkg) => (
                      <Paper
                        key={pkg.key}
                        elevation={0}
                        sx={{
                          p: 1.5,
                          borderRadius: 2.5,
                          border: "1px solid",
                          borderColor: pkg.subscriptionPackageId === data.packageId ? "primary.main" : "divider",
                        }}
                      >
                        <Typography sx={{ fontWeight: 700, mb: 0.75 }}>
                          {t(`subscription.billingCycle.${pkg.billingCycle}`, {
                            defaultValue: pkg.billingCycle,
                          })}
                        </Typography>
                        <Chip
                          size="small"
                          color={pkg.subscriptionPackageId === data.packageId ? "primary" : "default"}
                          label={formatCurrency(pkg.price)}
                        />
                        <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap", mt: 1.25 }}>
                          {pkg.subscriptionPackageId !== data.packageId && (
                            <Button
                              size="small"
                              variant="outlined"
                              disabled={pendingPackageId === pkg.subscriptionPackageId}
                              onClick={() => void changePackage(pkg.subscriptionPackageId)}
                            >
                              {pkg.billingCycle === "monthly"
                                ? t("subscription.changePackageToMonthly", { defaultValue: "Switch to monthly" })
                                : t("subscription.changePackageToAnnual", { defaultValue: "Switch to annual" })}
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

          {data.hasSubscription && (
            <>
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
                      <TableCell align={isRTL ? "left" : "right"}>{t("administration.billing.table.actions", { defaultValue: "Actions" })}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {data.transactions.map((transaction) => (
                      <TableRow key={transaction.id} hover>
                        <TableCell>{transaction.packageName}</TableCell>
                        <TableCell>{t(`subscription.billingCycle.${transaction.billingCycle.toLowerCase()}`, { defaultValue: transaction.billingCycle })}</TableCell>
                        <TableCell>{formatCurrency(transaction.amount)}</TableCell>
                        <TableCell>{formatDate(transaction.dueDateUtc)}</TableCell>
                        <TableCell>
                          <Chip
                            size="small"
                            color={getStatusColor(transaction.status)}
                            label={t(`subscription.status.${transaction.status.toLowerCase()}`, { defaultValue: transaction.status })}
                          />
                        </TableCell>
                        <TableCell>{transaction.reference || "-"}</TableCell>
                        <TableCell align={isRTL ? "left" : "right"}>
                          <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end", flexWrap: "wrap" }}>
                            {transaction.status !== "Paid" && (
                              <Button
                                size="small"
                                variant="contained"
                                color="success"
                                disabled={!!pendingAction[`billing-${transaction.id}`]}
                                onClick={() => void updateTransactionStatus(transaction.id, "pay")}
                              >
                                {t("administration.billing.markPaid", { defaultValue: "Mark paid" })}
                              </Button>
                            )}
                            {transaction.status === "Pending" && (
                              <Button
                                size="small"
                                variant="outlined"
                                color="warning"
                                disabled={!!pendingAction[`billing-${transaction.id}`]}
                                onClick={() => void updateTransactionStatus(transaction.id, "cancel")}
                              >
                                {t("administration.billing.cancel", { defaultValue: "Cancel" })}
                              </Button>
                            )}
                          </Box>
                        </TableCell>
                      </TableRow>
                    ))}
                    {data.transactions.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                          {t("tenantsPage.noTransactions", { defaultValue: "No billing transactions found." })}
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </Paper>
            </>
          )}
        </>
      )}
    </Box>
  );
}
