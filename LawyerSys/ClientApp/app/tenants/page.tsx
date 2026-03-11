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
  isActive: boolean;
  countryName: string;
  userCount: number;
};

export default function TenantsPage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const router = useRouter();
  const { isAuthenticated, hasRole } = useAuth();
  const isRTL = theme.direction === "rtl";
  const isSuperAdmin = hasRole("SuperAdmin");

  const [tenants, setTenants] = useState<TenantManagement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [pendingAction, setPendingAction] = useState<Record<number, boolean>>({});

  useEffect(() => {
    if (isAuthenticated && !isSuperAdmin) {
      router.replace("/dashboard");
    }
  }, [isAuthenticated, isSuperAdmin, router]);

  const loadTenants = async () => {
    setLoading(true);
    setError("");

    try {
      const language = (i18n.resolvedLanguage || i18n.language || "en").startsWith("ar") ? "ar-SA" : "en-US";
      const response = await api.get("/Tenants", { headers: { "Accept-Language": language } });
      setTenants(response.data || []);
    } catch (e: any) {
      setError(e?.response?.data?.message || t("tenantsPage.failedLoad", { defaultValue: "Failed to load tenants." }));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!isAuthenticated || !isSuperAdmin) {
      setLoading(false);
      return;
    }

    void loadTenants();
  }, [isAuthenticated, isSuperAdmin, i18n.language, i18n.resolvedLanguage]);

  const toggleTenantStatus = async (tenant: TenantManagement) => {
    setPendingAction((prev) => ({ ...prev, [tenant.id]: true }));
    try {
      await api.put(`/Tenants/${tenant.id}/status`, { isActive: !tenant.isActive });
      await loadTenants();
    } catch (e: any) {
      setError(e?.response?.data?.message || t("tenantsPage.statusUpdateFailed", { defaultValue: "Failed to update tenant status." }));
    } finally {
      setPendingAction((prev) => ({ ...prev, [tenant.id]: false }));
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
                <TableCell>{t("administration.tenants.users", { defaultValue: "Users" })}</TableCell>
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
                  <TableCell>{tenant.userCount}</TableCell>
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
                    <Button
                      size="small"
                      variant="contained"
                      color={tenant.isActive ? "warning" : "success"}
                      disabled={!!pendingAction[tenant.id]}
                      onClick={() => void toggleTenantStatus(tenant)}
                    >
                      {tenant.isActive
                        ? t("administration.tenants.deactivate", { defaultValue: "Deactivate" })
                        : t("administration.tenants.activate", { defaultValue: "Activate" })}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {tenants.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 6 }}>
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
