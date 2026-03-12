"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
import {
  Alert,
  Box,
  Button,
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
import ApartmentIcon from "@mui/icons-material/Apartment";
import RefreshIcon from "@mui/icons-material/Refresh";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";

type TenantManagement = {
  id: number;
  name: string;
  phoneNumber: string;
  contactEmail: string;
  isActive: boolean;
  countryName: string;
  userCount: number;
  currentPackageName: string;
  subscriptionStatus: string;
  subscriptionEndDateUtc?: string | null;
};

function isDefaultFirm(tenantName: string) {
  return tenantName.trim().toLowerCase() === "default firm";
}

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

function formatDate(value?: string | null) {
  return value ? new Date(value).toLocaleDateString() : "-";
}

export default function TenantsPage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const router = useRouter();
  const { user, isAuthenticated, hasRole } = useAuth();
  const isRTL = theme.direction === "rtl";
  const isSuperAdmin = hasRole("SuperAdmin");

  const [tenants, setTenants] = useState<TenantManagement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [pendingAction, setPendingAction] = useState<Record<string, boolean>>({});

  useEffect(() => {
    if (isAuthenticated && !user) {
      return;
    }

    if (isAuthenticated && !isSuperAdmin) {
      router.replace("/dashboard");
    }
  }, [isAuthenticated, user, isSuperAdmin, router]);

  const loadTenants = async () => {
    setLoading(true);
    setError("");

    try {
      const language = (i18n.resolvedLanguage || i18n.language || "en").startsWith("ar") ? "ar-SA" : "en-US";
      const response = await api.get("/Tenants", { headers: { "Accept-Language": language } });
      setTenants((response.data || []).filter((tenant: TenantManagement) => !isDefaultFirm(tenant.name)));
    } catch (e: any) {
      setError(e?.response?.data?.message || t("tenantsPage.failedLoad", { defaultValue: "Failed to load tenants." }));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!isAuthenticated) {
      setLoading(false);
      return;
    }

    if (!user) {
      return;
    }

    if (!isSuperAdmin) {
      setLoading(false);
      return;
    }

    void loadTenants();
  }, [isAuthenticated, user, isSuperAdmin, i18n.language, i18n.resolvedLanguage]);

  const toggleTenantStatus = async (tenant: TenantManagement) => {
    setPendingAction((prev) => ({ ...prev, [`tenant-${tenant.id}`]: true }));
    try {
      await api.put(`/Tenants/${tenant.id}/status`, { isActive: !tenant.isActive });
      await loadTenants();
    } catch (e: any) {
      setError(e?.response?.data?.message || t("tenantsPage.statusUpdateFailed", { defaultValue: "Failed to update tenant status." }));
    } finally {
      setPendingAction((prev) => ({ ...prev, [`tenant-${tenant.id}`]: false }));
    }
  };

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
          <ApartmentIcon color="primary" />
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              {t("administration.tenants.title", { defaultValue: "Tenants" })}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {t("tenantsPage.subtitle", { defaultValue: "Activate or deactivate registered tenants. Inactive tenants cannot log in." })}
            </Typography>
          </Box>
        </Box>

        <Button variant="outlined" startIcon={<RefreshIcon />} onClick={() => void loadTenants()} disabled={loading}>
          {t("common.refresh", { defaultValue: "Refresh" })}
        </Button>
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

      {!loading && !error && (
        <Paper elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", overflow: "hidden" }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t("administration.tenants.name", { defaultValue: "Tenant" })}</TableCell>
                <TableCell>{t("administration.tenants.country", { defaultValue: "Country" })}</TableCell>
                <TableCell>{t("administration.tenants.phone", { defaultValue: "Phone" })}</TableCell>
                <TableCell>{t("administration.tenants.email", { defaultValue: "Email" })}</TableCell>
                <TableCell>{t("administration.tenants.users", { defaultValue: "Users" })}</TableCell>
                <TableCell>{t("administration.tenants.package", { defaultValue: "Package" })}</TableCell>
                <TableCell>{t("administration.tenants.subscription", { defaultValue: "Subscription" })}</TableCell>
                <TableCell>{t("administration.tenants.status", { defaultValue: "Status" })}</TableCell>
                <TableCell align={isRTL ? "left" : "right"}>{t("administration.tenants.actions", { defaultValue: "Actions" })}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {tenants.map((tenant) => (
                <TableRow key={tenant.id} hover>
                  <TableCell sx={{ fontWeight: 700 }}>{tenant.name}</TableCell>
                  <TableCell>{tenant.countryName || "-"}</TableCell>
                  <TableCell>{tenant.phoneNumber || "-"}</TableCell>
                  <TableCell>{tenant.contactEmail || "-"}</TableCell>
                  <TableCell>{tenant.userCount}</TableCell>
                  <TableCell>{tenant.currentPackageName || ""}</TableCell>
                  <TableCell>
                    {!!tenant.subscriptionStatus && (
                      <Chip
                        size="small"
                        color={getStatusColor(tenant.subscriptionStatus)}
                        label={t(`subscription.status.${tenant.subscriptionStatus.toLowerCase()}`, { defaultValue: tenant.subscriptionStatus })}
                      />
                    )}
                    {!!tenant.subscriptionStatus && tenant.subscriptionEndDateUtc && (
                      <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 0.5 }}>
                        {formatDate(tenant.subscriptionEndDateUtc)}
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      color={tenant.isActive ? "success" : "default"}
                      label={
                        tenant.isActive
                          ? t("administration.tenants.active", { defaultValue: "Active" })
                          : t("administration.tenants.inactive", { defaultValue: "Inactive" })
                      }
                    />
                  </TableCell>
                  <TableCell align={isRTL ? "left" : "right"}>
                    <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end", flexWrap: "wrap" }}>
                      <Button size="small" variant="outlined" onClick={() => router.push(`/tenants/${tenant.id}/subscription`)}>
                        {t("tenantsPage.manageSubscription", { defaultValue: "Manage subscription" })}
                      </Button>
                      <Button
                        size="small"
                        variant="contained"
                        color={tenant.isActive ? "warning" : "success"}
                        disabled={!!pendingAction[`tenant-${tenant.id}`]}
                        onClick={() => void toggleTenantStatus(tenant)}
                      >
                        {tenant.isActive
                          ? t("administration.tenants.deactivate", { defaultValue: "Deactivate" })
                          : t("administration.tenants.activate", { defaultValue: "Activate" })}
                      </Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
              {tenants.length === 0 && (
                <TableRow>
                  <TableCell colSpan={9} align="center" sx={{ py: 6 }}>
                    {t("tenantsPage.empty", { defaultValue: "No tenants found." })}
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </Paper>
      )}
    </Box>
  );
}
