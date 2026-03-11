"use client";

import React, { useEffect, useMemo, useState } from "react";
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
  Paper,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tabs,
  Typography,
  useTheme,
} from "@mui/material";
import { Grid } from "@mui/material";
import AdminPanelSettingsIcon from "@mui/icons-material/AdminPanelSettings";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";
import SearchableMultiSelect from "../../src/components/SearchableMultiSelect";
import type { SearchableOption } from "../../src/components/SearchableSelect";

type AdministrationCounts = {
  users: number;
  employees: number;
  customers: number;
  cases: number;
  hearings: number;
  tasks: number;
  overdueTasks: number;
  auditLogs: number;
};

type AdministrationModule = {
  key: string;
  route: string;
  apiPath: string;
  canView: boolean;
  canCreateOrUpdate: boolean;
};

type AdministrationOverview = {
  counts: AdministrationCounts;
  modules: AdministrationModule[];
};

type IdentityUserManagement = {
  id: string;
  userName: string;
  email: string;
  fullName: string;
  tenantId: number;
  tenantName: string;
  requiresPasswordReset: boolean;
  isEnabled: boolean;
  roles: string[];
};

type TenantManagement = {
  id: number;
  name: string;
  phoneNumber: string;
  isActive: boolean;
  countryName: string;
  userCount: number;
};

type AdministrationTab = "overview" | "accounts" | "tenants";

function isDefaultFirm(tenantName: string) {
  return tenantName.trim().toLowerCase() === "default firm";
}

function getLocalizedRoleLabel(t: (key: string, options?: any) => string, role: string) {
  return t(`administration.roleLabels.${role}`, { defaultValue: role });
}

function getRoleOptions(
  t: (key: string, options?: any) => string,
  availableRoles: string[],
  selectedRoles: string[],
) {
  const optionMap = new Map<string, SearchableOption<string>>(
    availableRoles
      .filter((role) => role !== "SuperAdmin")
      .map((role) => [
        role,
        {
          value: role,
          label: getLocalizedRoleLabel(t, role),
        },
      ]),
  );

  selectedRoles.forEach((role) => {
    if (!optionMap.has(role)) {
      optionMap.set(role, {
        value: role,
        label: getLocalizedRoleLabel(t, role),
        disabled: role === "SuperAdmin",
      });
    }
  });

  return Array.from(optionMap.values());
}

export default function AdministrationPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const router = useRouter();
  const { user, isAuthenticated, hasRole } = useAuth();
  const isRTL = theme.direction === "rtl";
  const isAdmin = hasRole("Admin");
  const isSuperAdmin = hasRole("SuperAdmin");

  const [overview, setOverview] = useState<AdministrationOverview | null>(null);
  const [accounts, setAccounts] = useState<IdentityUserManagement[]>([]);
  const [tenants, setTenants] = useState<TenantManagement[]>([]);
  const [availableRoles, setAvailableRoles] = useState<string[]>([]);
  const [roleDrafts, setRoleDrafts] = useState<Record<string, string[]>>({});
  const [pendingAction, setPendingAction] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [activeTab, setActiveTab] = useState<AdministrationTab>("overview");

  useEffect(() => {
    if (isAuthenticated && !user) {
      return;
    }

    if (isAuthenticated && !isAdmin) {
      router.replace("/dashboard");
    }
  }, [isAuthenticated, user, isAdmin, router]);

  useEffect(() => {
    if (!isAuthenticated) {
      setLoading(false);
      return;
    }

    if (!user) {
      return;
    }

    if (!isAdmin) {
      setLoading(false);
      return;
    }

    let mounted = true;

    (async () => {
      try {
        const requests: Promise<any>[] = [
          api.get("/Administration/overview"),
          api.get("/Account/users"),
          api.get("/Account/users/roles"),
        ];
        if (isSuperAdmin) {
          requests.push(api.get("/Tenants"));
        }

        const [response, usersResponse, rolesResponse, tenantsResponse] = await Promise.all(requests);
        if (mounted) {
          setOverview(response.data);
          setAccounts(usersResponse.data || []);
          setAvailableRoles((rolesResponse.data || []).filter((role: string) => role !== "SuperAdmin"));
          setTenants(isSuperAdmin ? (tenantsResponse?.data || []) : []);
          const draftMap: Record<string, string[]> = {};
          (usersResponse.data || []).forEach((u: IdentityUserManagement) => {
            draftMap[u.id] = u.roles || [];
          });
          setRoleDrafts(draftMap);
        }
      } catch (e: any) {
        if (mounted) {
          setError(e?.response?.data?.message || t("administration.failedLoad"));
        }
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    })();

    return () => {
      mounted = false;
    };
  }, [t, isAuthenticated, user, isAdmin, isSuperAdmin]);

  useEffect(() => {
    if (!isSuperAdmin && activeTab === "tenants") {
      setActiveTab("overview");
    }
  }, [activeTab, isSuperAdmin]);

  const refreshAccounts = async () => {
    const usersResponse = await api.get("/Account/users");
    const users = usersResponse.data || [];
    setAccounts(users);
    const draftMap: Record<string, string[]> = {};
    users.forEach((u: IdentityUserManagement) => {
      draftMap[u.id] = u.roles || [];
    });
    setRoleDrafts(draftMap);
  };

  const runUserAction = async (id: string, action: "enable" | "disable") => {
    setPendingAction((prev) => ({ ...prev, [id]: true }));
    try {
      await api.post(`/Account/users/${id}/${action}`);
      await refreshAccounts();
    } finally {
      setPendingAction((prev) => ({ ...prev, [id]: false }));
    }
  };

  const saveRoles = async (id: string) => {
    setPendingAction((prev) => ({ ...prev, [id]: true }));
    try {
      const roles = roleDrafts[id] || [];
      await api.put(`/Account/users/${id}/roles`, { roles });
      await refreshAccounts();
    } finally {
      setPendingAction((prev) => ({ ...prev, [id]: false }));
    }
  };

  const toggleTenantStatus = async (id: number, isActive: boolean) => {
    setPendingAction((prev) => ({ ...prev, [`tenant-${id}`]: true }));
    try {
      await api.put(`/Tenants/${id}/status`, { isActive });
      const tenantsResponse = await api.get("/Tenants");
      setTenants(tenantsResponse.data || []);
    } finally {
      setPendingAction((prev) => ({ ...prev, [`tenant-${id}`]: false }));
    }
  };

  const cards = useMemo(() => {
    if (!overview) return [];

    return [
      { key: "users", value: overview.counts.users },
      { key: "employees", value: overview.counts.employees },
      { key: "customers", value: overview.counts.customers },
      { key: "cases", value: overview.counts.cases },
      { key: "hearings", value: overview.counts.hearings },
      { key: "tasks", value: overview.counts.tasks },
      { key: "overdueTasks", value: overview.counts.overdueTasks },
      { key: "auditLogs", value: overview.counts.auditLogs },
    ];
  }, [overview]);

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
          gap: 1.5,
        }}
      >
        <AdminPanelSettingsIcon color="primary" />
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800 }}>
            {t("administration.title")}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {t("administration.subtitle")}
          </Typography>
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

      {!loading && !error && overview && (
        <>
          <Grid container spacing={2} sx={{ mb: 3 }}>
            {cards.map((card) => (
              <Grid key={card.key} size={{ xs: 12, sm: 6, md: 3 }}>
                <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider" }}>
                  <CardContent>
                    <Typography variant="subtitle2" color="text.secondary">
                      {t(`administration.cards.${card.key}`)}
                    </Typography>
                    <Typography variant="h5" sx={{ fontWeight: 800, mt: 0.5 }}>
                      {card.value}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>

          <Paper elevation={0} sx={{ mb: 3, borderRadius: 3, border: "1px solid", borderColor: "divider", overflow: "hidden" }}>
            <Tabs
              value={activeTab}
              onChange={(_, value: AdministrationTab) => setActiveTab(value)}
              variant="scrollable"
              scrollButtons="auto"
            >
              <Tab value="overview" label={t("administration.tabs.overview")} />
              <Tab value="accounts" label={t("administration.tabs.accounts")} />
              {isSuperAdmin && <Tab value="tenants" label={t("administration.tabs.tenants")} />}
            </Tabs>
          </Paper>

          {activeTab === "overview" && (
            <>
              <Paper elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", overflow: "hidden" }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>{t("administration.table.module")}</TableCell>
                      <TableCell>{t("administration.table.api")}</TableCell>
                      <TableCell>{t("administration.table.view")}</TableCell>
                      <TableCell>{t("administration.table.manage")}</TableCell>
                      <TableCell align={isRTL ? "left" : "right"}>{t("administration.table.open")}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {overview.modules.map((module) => (
                      <TableRow key={module.key} hover>
                        <TableCell>{t(`administration.modules.${module.key}`)}</TableCell>
                        <TableCell>
                          <Chip size="small" label={module.apiPath} variant="outlined" />
                        </TableCell>
                        <TableCell>
                          <Chip
                            size="small"
                            color={module.canView ? "success" : "default"}
                            label={module.canView ? t("administration.yes") : t("administration.no")}
                          />
                        </TableCell>
                        <TableCell>
                          <Chip
                            size="small"
                            color={module.canCreateOrUpdate ? "primary" : "default"}
                            label={module.canCreateOrUpdate ? t("administration.manageEnabled") : t("administration.manageReadOnly")}
                          />
                        </TableCell>
                        <TableCell align={isRTL ? "left" : "right"}>
                          <Button size="small" variant="outlined" onClick={() => router.push(module.route)}>
                            {t("administration.open")}
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </Paper>
            </>
          )}

          {activeTab === "accounts" && (
            <>
              <Typography variant="h6" sx={{ mb: 1.5, fontWeight: 800 }}>
                {t("administration.accounts.title")}
              </Typography>
              <Paper elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", overflow: "hidden" }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>{t("administration.accounts.user")}</TableCell>
                      <TableCell>{t("administration.accounts.email")}</TableCell>
                      <TableCell>{t("administration.accounts.status")}</TableCell>
                      <TableCell>{t("administration.accounts.roles")}</TableCell>
                      <TableCell align={isRTL ? "left" : "right"}>{t("administration.accounts.actions")}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {accounts.map((account) => (
                      <TableRow key={account.id} hover>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 700 }}>
                            {account.fullName || account.userName}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {account.userName}
                            {account.tenantName ? ` - ${account.tenantName}` : ""}
                          </Typography>
                        </TableCell>
                        <TableCell>{account.email || "-"}</TableCell>
                        <TableCell>
                          <Chip
                            size="small"
                            color={account.isEnabled ? "success" : "default"}
                            label={account.isEnabled ? t("administration.accounts.enabled") : t("administration.accounts.disabled")}
                          />
                        </TableCell>
                        <TableCell sx={{ minWidth: 220 }}>
                          <SearchableMultiSelect<string>
                            size="small"
                            label={t("administration.accounts.roles")}
                            value={roleDrafts[account.id] || []}
                            onChange={(value) => setRoleDrafts((prev) => ({ ...prev, [account.id]: value }))}
                            options={getRoleOptions(t, availableRoles, roleDrafts[account.id] || [])}
                            disabled={account.id === user?.id}
                            limitTags={3}
                          />
                        </TableCell>
                        <TableCell align={isRTL ? "left" : "right"}>
                          <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end" }}>
                            {account.id !== user?.id && (
                              <Button
                                size="small"
                                variant="outlined"
                                disabled={!!pendingAction[account.id]}
                                onClick={() => saveRoles(account.id)}
                              >
                                {t("administration.accounts.saveRoles")}
                              </Button>
                            )}
                            {account.isEnabled ? (
                              account.id !== user?.id && (
                                <Button
                                  size="small"
                                  color="warning"
                                  variant="contained"
                                  disabled={!!pendingAction[account.id]}
                                  onClick={() => runUserAction(account.id, "disable")}
                                >
                                  {t("administration.accounts.disable")}
                                </Button>
                              )
                            ) : (
                              <Button
                                size="small"
                                color="success"
                                variant="contained"
                                disabled={!!pendingAction[account.id]}
                                onClick={() => runUserAction(account.id, "enable")}
                              >
                                {t("administration.accounts.enable")}
                              </Button>
                            )}
                          </Box>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </Paper>
            </>
          )}

          {activeTab === "tenants" && isSuperAdmin && (
            <>
              <Typography variant="h6" sx={{ mb: 1.5, fontWeight: 800 }}>
                {t("administration.tenants.title", { defaultValue: "Tenants" })}
              </Typography>
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
                            label={tenant.isActive
                              ? t("administration.tenants.active", { defaultValue: "Active" })
                              : t("administration.tenants.inactive", { defaultValue: "Inactive" })}
                          />
                        </TableCell>
                        <TableCell align={isRTL ? "left" : "right"}>
                          {!isDefaultFirm(tenant.name) && (
                            <Button
                              size="small"
                              variant="contained"
                              color={tenant.isActive ? "warning" : "success"}
                              disabled={!!pendingAction[`tenant-${tenant.id}`]}
                              onClick={() => toggleTenantStatus(tenant.id, !tenant.isActive)}
                            >
                              {tenant.isActive
                                ? t("administration.tenants.deactivate", { defaultValue: "Deactivate" })
                                : t("administration.tenants.activate", { defaultValue: "Activate" })}
                            </Button>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
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
