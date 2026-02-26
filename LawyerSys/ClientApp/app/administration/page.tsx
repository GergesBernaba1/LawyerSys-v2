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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
  useTheme,
} from "@mui/material";
import { Grid } from "@mui/material";
import AdminPanelSettingsIcon from "@mui/icons-material/AdminPanelSettings";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";

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
  requiresPasswordReset: boolean;
  isEnabled: boolean;
  roles: string[];
};

export default function AdministrationPage() {
  const { t } = useTranslation();
  const theme = useTheme();
  const router = useRouter();
  const { isAuthenticated, hasRole } = useAuth();
  const isRTL = theme.direction === "rtl";
  const isAdmin = hasRole("Admin");

  const [overview, setOverview] = useState<AdministrationOverview | null>(null);
  const [accounts, setAccounts] = useState<IdentityUserManagement[]>([]);
  const [roleDrafts, setRoleDrafts] = useState<Record<string, string>>({});
  const [pendingAction, setPendingAction] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (isAuthenticated && !isAdmin) {
      router.replace("/dashboard");
    }
  }, [isAuthenticated, isAdmin, router]);

  useEffect(() => {
    if (!isAuthenticated || !isAdmin) {
      setLoading(false);
      return;
    }

    let mounted = true;

    (async () => {
      try {
        const [response, usersResponse] = await Promise.all([
          api.get("/Administration/overview"),
          api.get("/Account/users"),
        ]);
        if (mounted) {
          setOverview(response.data);
          setAccounts(usersResponse.data || []);
          const draftMap: Record<string, string> = {};
          (usersResponse.data || []).forEach((u: IdentityUserManagement) => {
            draftMap[u.id] = (u.roles || []).join(", ");
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
  }, [t, isAuthenticated, isAdmin]);

  const refreshAccounts = async () => {
    const usersResponse = await api.get("/Account/users");
    const users = usersResponse.data || [];
    setAccounts(users);
    const draftMap: Record<string, string> = {};
    users.forEach((u: IdentityUserManagement) => {
      draftMap[u.id] = (u.roles || []).join(", ");
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
      const raw = roleDrafts[id] || "";
      const roles = raw
        .split(",")
        .map((r) => r.trim())
        .filter(Boolean);
      await api.put(`/Account/users/${id}/roles`, { roles });
      await refreshAccounts();
    } finally {
      setPendingAction((prev) => ({ ...prev, [id]: false }));
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

          <Typography variant="h6" sx={{ mt: 4, mb: 1.5, fontWeight: 800 }}>
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
                      <Typography variant="body2" sx={{ fontWeight: 700 }}>{account.fullName || account.userName}</Typography>
                      <Typography variant="caption" color="text.secondary">{account.userName}</Typography>
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
                      <TextField
                        size="small"
                        fullWidth
                        value={roleDrafts[account.id] || ""}
                        onChange={(e) => setRoleDrafts((prev) => ({ ...prev, [account.id]: e.target.value }))}
                        placeholder="Admin, Employee"
                      />
                    </TableCell>
                    <TableCell align={isRTL ? "left" : "right"}>
                      <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end" }}>
                        <Button
                          size="small"
                          variant="outlined"
                          disabled={!!pendingAction[account.id]}
                          onClick={() => saveRoles(account.id)}
                        >
                          {t("administration.accounts.saveRoles")}
                        </Button>
                        {account.isEnabled ? (
                          <Button
                            size="small"
                            color="warning"
                            variant="contained"
                            disabled={!!pendingAction[account.id]}
                            onClick={() => runUserAction(account.id, "disable")}
                          >
                            {t("administration.accounts.disable")}
                          </Button>
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
    </Box>
  );
}
