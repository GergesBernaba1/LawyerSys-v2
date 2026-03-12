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
  MenuItem,
  Paper,
  TextField,
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

type AdministrationOverview = {
  counts: AdministrationCounts;
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
  contactEmail: string;
  isActive: boolean;
  countryName: string;
  userCount: number;
  currentPackageName: string;
  subscriptionStatus: string;
  subscriptionEndDateUtc?: string | null;
};

type SubscriptionPackageManagement = {
  officeSize: string;
  name: string;
  nameAr: string;
  description: string;
  descriptionAr: string;
  feature1: string;
  feature1Ar: string;
  feature2: string;
  feature2Ar: string;
  feature3: string;
  feature3Ar: string;
  monthlyPackageId?: number | null;
  annualPackageId?: number | null;
  monthlyPrice: number;
  annualPrice: number;
  currency: string;
  isActive: boolean;
  displayOrder: number;
};

type DemoRequestManagement = {
  id: number;
  fullName: string;
  email: string;
  phoneNumber: string;
  officeName: string;
  notes: string;
  status: string;
  createdAtUtc: string;
  reviewedAtUtc?: string | null;
  reviewedByName: string;
};

type TenantSubscriptionSummary = {
  tenantId: number;
  tenantName: string;
  tenantEmail: string;
  isTenantActive: boolean;
  packageName: string;
  status: string;
  startDateUtc?: string | null;
  endDateUtc?: string | null;
  nextBillingDateUtc?: string | null;
};

type TenantBillingTransaction = {
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

type AdminTenantBillingOverview = {
  tenants: TenantSubscriptionSummary[];
  transactions: TenantBillingTransaction[];
};

type LandingPageSettings = {
  systemName: string;
  systemNameAr: string;
  tagline: string;
  taglineAr: string;
  heroTitle: string;
  heroTitleAr: string;
  heroSubtitle: string;
  heroSubtitleAr: string;
  primaryButtonText: string;
  primaryButtonTextAr: string;
  primaryButtonUrl: string;
  secondaryButtonText: string;
  secondaryButtonTextAr: string;
  secondaryButtonUrl: string;
  aboutTitle: string;
  aboutTitleAr: string;
  aboutDescription: string;
  aboutDescriptionAr: string;
  feature1Title: string;
  feature1TitleAr: string;
  feature1Description: string;
  feature1DescriptionAr: string;
  feature2Title: string;
  feature2TitleAr: string;
  feature2Description: string;
  feature2DescriptionAr: string;
  feature3Title: string;
  feature3TitleAr: string;
  feature3Description: string;
  feature3DescriptionAr: string;
  contactEmail: string;
  contactPhone: string;
  updatedAtUtc?: string;
};

type AdministrationTab = "accounts" | "tenants" | "landing" | "pricing" | "billing" | "demos";

type PackageDraft = {
  officeSize: string;
  name: string;
  nameAr: string;
  description: string;
  descriptionAr: string;
  feature1: string;
  feature1Ar: string;
  feature2: string;
  feature2Ar: string;
  feature3: string;
  feature3Ar: string;
  monthlyPrice: string;
  annualPrice: string;
  currency: string;
  isActive: boolean;
  displayOrder: string;
};

const emptyPackageDraft: PackageDraft = {
  officeSize: "Small",
  name: "",
  nameAr: "",
  description: "",
  descriptionAr: "",
  feature1: "",
  feature1Ar: "",
  feature2: "",
  feature2Ar: "",
  feature3: "",
  feature3Ar: "",
  monthlyPrice: "0",
  annualPrice: "0",
  currency: "SAR",
  isActive: true,
  displayOrder: "0",
};

const emptyLandingSettings: LandingPageSettings = {
  systemName: "",
  systemNameAr: "",
  tagline: "",
  taglineAr: "",
  heroTitle: "",
  heroTitleAr: "",
  heroSubtitle: "",
  heroSubtitleAr: "",
  primaryButtonText: "",
  primaryButtonTextAr: "",
  primaryButtonUrl: "",
  secondaryButtonText: "",
  secondaryButtonTextAr: "",
  secondaryButtonUrl: "",
  aboutTitle: "",
  aboutTitleAr: "",
  aboutDescription: "",
  aboutDescriptionAr: "",
  feature1Title: "",
  feature1TitleAr: "",
  feature1Description: "",
  feature1DescriptionAr: "",
  feature2Title: "",
  feature2TitleAr: "",
  feature2Description: "",
  feature2DescriptionAr: "",
  feature3Title: "",
  feature3TitleAr: "",
  feature3Description: "",
  feature3DescriptionAr: "",
  contactEmail: "",
  contactPhone: "",
  updatedAtUtc: "",
};

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
  const [landingSettings, setLandingSettings] = useState<LandingPageSettings>(emptyLandingSettings);
  const [packages, setPackages] = useState<SubscriptionPackageManagement[]>([]);
  const [packageDraft, setPackageDraft] = useState<PackageDraft>(emptyPackageDraft);
  const [billingOverview, setBillingOverview] = useState<AdminTenantBillingOverview>({ tenants: [], transactions: [] });
  const [demoRequests, setDemoRequests] = useState<DemoRequestManagement[]>([]);
  const [pendingAction, setPendingAction] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [saveMessage, setSaveMessage] = useState("");
  const [activeTab, setActiveTab] = useState<AdministrationTab>("accounts");

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
          requests.push(api.get("/LandingPage/admin", { skipTenantHeader: true } as any));
          requests.push(api.get("/SubscriptionPackages", { skipTenantHeader: true } as any));
          requests.push(api.get("/TenantSubscriptions/admin", { skipTenantHeader: true } as any));
          requests.push(api.get("/DemoRequests", { skipTenantHeader: true } as any));
        }

        const [response, usersResponse, rolesResponse, tenantsResponse, landingResponse, packagesResponse, billingResponse, demoRequestsResponse] = await Promise.all(requests);
        if (mounted) {
          setOverview(response.data);
          setAccounts(usersResponse.data || []);
          setAvailableRoles((rolesResponse.data || []).filter((role: string) => role !== "SuperAdmin"));
          setTenants(isSuperAdmin ? (tenantsResponse?.data || []) : []);
          setLandingSettings(isSuperAdmin ? { ...emptyLandingSettings, ...(landingResponse?.data || {}) } : emptyLandingSettings);
          setPackages(isSuperAdmin ? (packagesResponse?.data || []) : []);
          setBillingOverview(isSuperAdmin ? (billingResponse?.data || { tenants: [], transactions: [] }) : { tenants: [], transactions: [] });
          setDemoRequests(isSuperAdmin ? (demoRequestsResponse?.data || []) : []);
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
    if (!isSuperAdmin && (activeTab === "tenants" || activeTab === "landing" || activeTab === "pricing" || activeTab === "billing" || activeTab === "demos")) {
      setActiveTab("accounts");
    }
  }, [activeTab, isSuperAdmin]);

  useEffect(() => {
    if (packages.length > 0 && !packageDraft.name && !packageDraft.description) {
      setPackageDraft({
        officeSize: packages[0].officeSize,
        name: packages[0].name,
        nameAr: packages[0].nameAr,
        description: packages[0].description,
        descriptionAr: packages[0].descriptionAr,
        feature1: packages[0].feature1,
        feature1Ar: packages[0].feature1Ar,
        feature2: packages[0].feature2,
        feature2Ar: packages[0].feature2Ar,
        feature3: packages[0].feature3,
        feature3Ar: packages[0].feature3Ar,
        monthlyPrice: String(packages[0].monthlyPrice),
        annualPrice: String(packages[0].annualPrice),
        currency: packages[0].currency,
        isActive: packages[0].isActive,
        displayOrder: String(packages[0].displayOrder),
      });
    }
  }, [packages, packageDraft.description, packageDraft.name]);

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

  const refreshPackages = async () => {
    const response = await api.get("/SubscriptionPackages", { skipTenantHeader: true } as any);
    setPackages(response.data || []);
  };

  const refreshBilling = async () => {
    const response = await api.get("/TenantSubscriptions/admin", { skipTenantHeader: true } as any);
    setBillingOverview(response.data || { tenants: [], transactions: [] });
  };

  const refreshDemoRequests = async () => {
    const response = await api.get("/DemoRequests", { skipTenantHeader: true } as any);
    setDemoRequests(response.data || []);
  };

  const updateLandingField = <K extends keyof LandingPageSettings>(field: K, value: LandingPageSettings[K]) => {
    setLandingSettings((prev) => ({ ...prev, [field]: value }));
    setSaveMessage("");
  };

  const saveLandingPage = async () => {
    setPendingAction((prev) => ({ ...prev, landing: true }));
    setSaveMessage("");
    try {
      const response = await api.put("/LandingPage", landingSettings, { skipTenantHeader: true } as any);
      setLandingSettings({ ...emptyLandingSettings, ...(response.data || {}) });
      setSaveMessage(t("administration.landing.saveSuccess"));
    } catch (e: any) {
      setSaveMessage(e?.response?.data?.message || t("administration.landing.saveFailed"));
    } finally {
      setPendingAction((prev) => ({ ...prev, landing: false }));
    }
  };

  const updatePackageDraft = <K extends keyof PackageDraft>(field: K, value: PackageDraft[K]) => {
    setPackageDraft((prev) => ({ ...prev, [field]: value }));
  };

  const editPackage = (pkg: SubscriptionPackageManagement) => {
    setPackageDraft({
      officeSize: pkg.officeSize,
      name: pkg.name,
      nameAr: pkg.nameAr,
      description: pkg.description,
      descriptionAr: pkg.descriptionAr,
      feature1: pkg.feature1,
      feature1Ar: pkg.feature1Ar,
      feature2: pkg.feature2,
      feature2Ar: pkg.feature2Ar,
      feature3: pkg.feature3,
      feature3Ar: pkg.feature3Ar,
      monthlyPrice: String(pkg.monthlyPrice),
      annualPrice: String(pkg.annualPrice),
      currency: pkg.currency,
      isActive: pkg.isActive,
      displayOrder: String(pkg.displayOrder),
    });
  };

  const savePackage = async () => {
    setPendingAction((prev) => ({ ...prev, package: true }));
    try {
      const payload = {
        name: packageDraft.name,
        nameAr: packageDraft.nameAr,
        description: packageDraft.description,
        descriptionAr: packageDraft.descriptionAr,
        feature1: packageDraft.feature1,
        feature1Ar: packageDraft.feature1Ar,
        feature2: packageDraft.feature2,
        feature2Ar: packageDraft.feature2Ar,
        feature3: packageDraft.feature3,
        feature3Ar: packageDraft.feature3Ar,
        monthlyPrice: Number(packageDraft.monthlyPrice || 0),
        annualPrice: Number(packageDraft.annualPrice || 0),
        currency: packageDraft.currency,
        isActive: packageDraft.isActive,
        displayOrder: Number(packageDraft.displayOrder || 0),
      };

      await api.put(`/SubscriptionPackages/${packageDraft.officeSize}`, payload, { skipTenantHeader: true } as any);

      await refreshPackages();
    } finally {
      setPendingAction((prev) => ({ ...prev, package: false }));
    }
  };

  const reviewDemoRequest = async (id: number, status: "Approved" | "Rejected") => {
    setPendingAction((prev) => ({ ...prev, [`demo-${id}`]: true }));
    try {
      await api.put(`/DemoRequests/${id}/review`, { status }, { skipTenantHeader: true } as any);
      await refreshDemoRequests();
    } finally {
      setPendingAction((prev) => ({ ...prev, [`demo-${id}`]: false }));
    }
  };

  const updateTransactionStatus = async (id: number, action: "pay" | "cancel") => {
    setPendingAction((prev) => ({ ...prev, [`billing-${id}`]: true }));
    try {
      await api.put(`/TenantSubscriptions/admin/transactions/${id}/${action}`, {}, { skipTenantHeader: true } as any);
      await refreshBilling();
      await refreshPackages();
    } finally {
      setPendingAction((prev) => ({ ...prev, [`billing-${id}`]: false }));
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
              <Tab value="accounts" label={t("administration.tabs.accounts")} />
              {isSuperAdmin && <Tab value="tenants" label={t("administration.tabs.tenants")} />}
              {isSuperAdmin && <Tab value="pricing" label={t("administration.tabs.pricing", { defaultValue: "Pricing" })} />}
              {isSuperAdmin && <Tab value="billing" label={t("administration.tabs.billing", { defaultValue: "Tenant billing" })} />}
              {isSuperAdmin && <Tab value="demos" label={t("administration.tabs.demos", { defaultValue: "Demo requests" })} />}
              {isSuperAdmin && <Tab value="landing" label={t("administration.tabs.landing")} />}
            </Tabs>
          </Paper>

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
                        <TableCell>
                          <Typography sx={{ fontWeight: 700 }}>{tenant.name}</Typography>
                          {isDefaultFirm(tenant.name) && (
                            <Chip size="small" sx={{ mt: 0.5 }} label={t("administration.tenants.ourOffice", { defaultValue: "Our office" })} />
                          )}
                        </TableCell>
                        <TableCell>{tenant.countryName || "-"}</TableCell>
                        <TableCell>{tenant.phoneNumber || "-"}</TableCell>
                        <TableCell>{tenant.contactEmail || "-"}</TableCell>
                        <TableCell>{tenant.userCount}</TableCell>
                        <TableCell>{tenant.currentPackageName || "-"}</TableCell>
                        <TableCell>
                          <Box>
                            <Chip
                              size="small"
                              label={t(`subscription.status.${tenant.subscriptionStatus.toLowerCase()}`, { defaultValue: tenant.subscriptionStatus || "-" })}
                            />
                            {tenant.subscriptionEndDateUtc && (
                              <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 0.5 }}>
                                {new Date(tenant.subscriptionEndDateUtc).toLocaleDateString()}
                              </Typography>
                            )}
                          </Box>
                        </TableCell>
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

          {activeTab === "pricing" && isSuperAdmin && (
            <>
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 2, mb: 2 }}>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 800 }}>
                    {t("administration.pricing.title", { defaultValue: "Pricing packages" })}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {t("administration.pricing.subtitle", { defaultValue: "Manage the packages shown on the landing page and registration flow." })}
                  </Typography>
                </Box>
              </Box>

              <Grid container spacing={2}>
                <Grid size={{ xs: 12, md: 7 }}>
                  <Paper elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", overflow: "hidden" }}>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>{t("administration.pricing.table.package", { defaultValue: "Package" })}</TableCell>
                          <TableCell>{t("administration.pricing.table.officeSize", { defaultValue: "Office size" })}</TableCell>
                          <TableCell>{t("administration.pricing.table.monthly", { defaultValue: "Monthly" })}</TableCell>
                          <TableCell>{t("administration.pricing.table.annual", { defaultValue: "Annual" })}</TableCell>
                          <TableCell>{t("administration.pricing.table.status", { defaultValue: "Status" })}</TableCell>
                          <TableCell align={isRTL ? "left" : "right"}>{t("administration.pricing.table.actions", { defaultValue: "Actions" })}</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {packages.map((pkg) => (
                          <TableRow key={pkg.officeSize} hover>
                            <TableCell>
                              <Typography sx={{ fontWeight: 700 }}>{pkg.name}</Typography>
                              <Typography variant="caption" color="text.secondary">{pkg.nameAr}</Typography>
                            </TableCell>
                            <TableCell>{t(`subscription.officeSize.${pkg.officeSize.toLowerCase()}`, { defaultValue: pkg.officeSize })}</TableCell>
                            <TableCell>{pkg.monthlyPrice.toFixed(2)} {pkg.currency}</TableCell>
                            <TableCell>{pkg.annualPrice.toFixed(2)} {pkg.currency}</TableCell>
                            <TableCell>
                              <Chip
                                size="small"
                                color={pkg.isActive ? "success" : "default"}
                                label={pkg.isActive ? t("administration.tenants.active", { defaultValue: "Active" }) : t("administration.tenants.inactive", { defaultValue: "Inactive" })}
                              />
                            </TableCell>
                            <TableCell align={isRTL ? "left" : "right"}>
                              <Button size="small" variant="outlined" onClick={() => editPackage(pkg)}>
                                {t("app.edit")}
                              </Button>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </Paper>
                </Grid>

                <Grid size={{ xs: 12, md: 5 }}>
                  <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider" }}>
                    <CardContent>
                      <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
                        {t("administration.pricing.editPackage", { defaultValue: "Edit package" })}
                      </Typography>
                      <Box sx={{ display: "grid", gap: 2 }}>
                        <TextField label={t("administration.pricing.fields.name", { defaultValue: "Name" })} value={packageDraft.name} onChange={(e) => updatePackageDraft("name", e.target.value)} fullWidth />
                        <TextField label={t("administration.pricing.fields.nameAr", { defaultValue: "Name (Arabic)" })} value={packageDraft.nameAr} onChange={(e) => updatePackageDraft("nameAr", e.target.value)} fullWidth />
                        <TextField label={t("administration.pricing.fields.description", { defaultValue: "Description" })} value={packageDraft.description} onChange={(e) => updatePackageDraft("description", e.target.value)} fullWidth multiline minRows={3} />
                        <TextField label={t("administration.pricing.fields.descriptionAr", { defaultValue: "Description (Arabic)" })} value={packageDraft.descriptionAr} onChange={(e) => updatePackageDraft("descriptionAr", e.target.value)} fullWidth multiline minRows={3} />
                        <TextField label={t("administration.pricing.fields.feature1", { defaultValue: "Feature 1" })} value={packageDraft.feature1} onChange={(e) => updatePackageDraft("feature1", e.target.value)} fullWidth />
                        <TextField label={t("administration.pricing.fields.feature1Ar", { defaultValue: "Feature 1 (Arabic)" })} value={packageDraft.feature1Ar} onChange={(e) => updatePackageDraft("feature1Ar", e.target.value)} fullWidth />
                        <TextField label={t("administration.pricing.fields.feature2", { defaultValue: "Feature 2" })} value={packageDraft.feature2} onChange={(e) => updatePackageDraft("feature2", e.target.value)} fullWidth />
                        <TextField label={t("administration.pricing.fields.feature2Ar", { defaultValue: "Feature 2 (Arabic)" })} value={packageDraft.feature2Ar} onChange={(e) => updatePackageDraft("feature2Ar", e.target.value)} fullWidth />
                        <TextField label={t("administration.pricing.fields.feature3", { defaultValue: "Feature 3" })} value={packageDraft.feature3} onChange={(e) => updatePackageDraft("feature3", e.target.value)} fullWidth />
                        <TextField label={t("administration.pricing.fields.feature3Ar", { defaultValue: "Feature 3 (Arabic)" })} value={packageDraft.feature3Ar} onChange={(e) => updatePackageDraft("feature3Ar", e.target.value)} fullWidth />
                        <TextField select label={t("administration.pricing.fields.officeSize", { defaultValue: "Office size" })} value={packageDraft.officeSize} onChange={(e) => updatePackageDraft("officeSize", e.target.value)} fullWidth>
                          <MenuItem value="Small">{t("subscription.officeSize.small", { defaultValue: "Small office" })}</MenuItem>
                          <MenuItem value="Medium">{t("subscription.officeSize.medium", { defaultValue: "Medium office" })}</MenuItem>
                        </TextField>
                        <Grid container spacing={2}>
                          <Grid size={{ xs: 12, sm: 6 }}>
                            <TextField label={t("administration.pricing.fields.monthlyPrice", { defaultValue: "Monthly price" })} type="number" value={packageDraft.monthlyPrice} onChange={(e) => updatePackageDraft("monthlyPrice", e.target.value)} fullWidth />
                          </Grid>
                          <Grid size={{ xs: 12, sm: 6 }}>
                            <TextField label={t("administration.pricing.fields.annualPrice", { defaultValue: "Annual price" })} type="number" value={packageDraft.annualPrice} onChange={(e) => updatePackageDraft("annualPrice", e.target.value)} fullWidth />
                          </Grid>
                        </Grid>
                        <Grid container spacing={2}>
                          <Grid size={{ xs: 12, sm: 6 }}>
                            <TextField label={t("administration.pricing.fields.currency", { defaultValue: "Currency" })} value={packageDraft.currency} onChange={(e) => updatePackageDraft("currency", e.target.value)} fullWidth />
                          </Grid>
                          <Grid size={{ xs: 12, sm: 6 }}>
                            <TextField label={t("administration.pricing.fields.displayOrder", { defaultValue: "Display order" })} type="number" value={packageDraft.displayOrder} onChange={(e) => updatePackageDraft("displayOrder", e.target.value)} fullWidth />
                          </Grid>
                        </Grid>
                        <Grid container spacing={2}>
                          <Grid size={{ xs: 12, sm: 6 }}>
                            <TextField select label={t("administration.pricing.fields.active", { defaultValue: "Visibility" })} value={packageDraft.isActive ? "true" : "false"} onChange={(e) => updatePackageDraft("isActive", e.target.value === "true")} fullWidth>
                              <MenuItem value="true">{t("administration.tenants.active", { defaultValue: "Active" })}</MenuItem>
                              <MenuItem value="false">{t("administration.tenants.inactive", { defaultValue: "Inactive" })}</MenuItem>
                            </TextField>
                          </Grid>
                        </Grid>
                        <Button variant="contained" onClick={savePackage} disabled={!!pendingAction.package}>
                          {t("app.save")}
                        </Button>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
            </>
          )}

          {activeTab === "billing" && isSuperAdmin && (
            <>
              <Typography variant="h6" sx={{ mb: 1.5, fontWeight: 800 }}>
                {t("administration.billing.title", { defaultValue: "Tenant billing" })}
              </Typography>

              <Grid container spacing={2} sx={{ mb: 3 }}>
                {billingOverview.tenants.map((tenant) => (
                  <Grid key={tenant.tenantId} size={{ xs: 12, md: 6 }}>
                    <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider" }}>
                      <CardContent>
                        <Box sx={{ display: "flex", justifyContent: "space-between", gap: 1, mb: 1 }}>
                          <Box>
                            <Typography sx={{ fontWeight: 800 }}>{tenant.tenantName}</Typography>
                            <Typography variant="body2" color="text.secondary">{tenant.tenantEmail || "-"}</Typography>
                          </Box>
                          <Chip
                            size="small"
                            color={tenant.isTenantActive ? "success" : "default"}
                            label={tenant.isTenantActive ? t("administration.tenants.active", { defaultValue: "Active" }) : t("administration.tenants.inactive", { defaultValue: "Inactive" })}
                          />
                        </Box>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 0.75 }}>
                          {t("administration.billing.currentPackage", { defaultValue: "Current package" })}: {tenant.packageName || "-"}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 0.75 }}>
                          {t("administration.billing.subscriptionStatus", { defaultValue: "Subscription status" })}: {t(`subscription.status.${tenant.status.toLowerCase()}`, { defaultValue: tenant.status || "-" })}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {t("administration.billing.nextBillingDate", { defaultValue: "Next billing date" })}: {tenant.nextBillingDateUtc ? new Date(tenant.nextBillingDateUtc).toLocaleDateString() : "-"}
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
                      <TableCell>{t("administration.billing.table.tenant", { defaultValue: "Tenant" })}</TableCell>
                      <TableCell>{t("administration.billing.table.package", { defaultValue: "Package" })}</TableCell>
                      <TableCell>{t("administration.billing.table.amount", { defaultValue: "Amount" })}</TableCell>
                      <TableCell>{t("administration.billing.table.dueDate", { defaultValue: "Due date" })}</TableCell>
                      <TableCell>{t("administration.billing.table.status", { defaultValue: "Status" })}</TableCell>
                      <TableCell align={isRTL ? "left" : "right"}>{t("administration.billing.table.actions", { defaultValue: "Actions" })}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {billingOverview.transactions.map((transaction) => (
                      <TableRow key={transaction.id} hover>
                        <TableCell>{transaction.tenantName}</TableCell>
                        <TableCell>
                          <Typography sx={{ fontWeight: 700 }}>{transaction.packageName}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {t(`subscription.billingCycle.${transaction.billingCycle.toLowerCase()}`, { defaultValue: transaction.billingCycle })}
                          </Typography>
                        </TableCell>
                        <TableCell>{transaction.amount.toFixed(2)} {transaction.currency}</TableCell>
                        <TableCell>{new Date(transaction.dueDateUtc).toLocaleDateString()}</TableCell>
                        <TableCell>
                          <Chip
                            size="small"
                            color={transaction.status === "Paid" ? "success" : transaction.status === "Pending" ? "warning" : transaction.status === "Overdue" ? "error" : "default"}
                            label={t(`subscription.status.${transaction.status.toLowerCase()}`, { defaultValue: transaction.status })}
                          />
                        </TableCell>
                        <TableCell align={isRTL ? "left" : "right"}>
                          <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end" }}>
                            {transaction.status !== "Paid" && (
                              <Button size="small" variant="contained" color="success" disabled={!!pendingAction[`billing-${transaction.id}`]} onClick={() => updateTransactionStatus(transaction.id, "pay")}>
                                {t("administration.billing.markPaid", { defaultValue: "Mark paid" })}
                              </Button>
                            )}
                            {transaction.status === "Pending" && (
                              <Button size="small" variant="outlined" color="warning" disabled={!!pendingAction[`billing-${transaction.id}`]} onClick={() => updateTransactionStatus(transaction.id, "cancel")}>
                                {t("administration.billing.cancel", { defaultValue: "Cancel" })}
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

          {activeTab === "demos" && isSuperAdmin && (
            <>
              <Typography variant="h6" sx={{ mb: 1.5, fontWeight: 800 }}>
                {t("administration.demos.title", { defaultValue: "Demo requests" })}
              </Typography>
              <Paper elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", overflow: "hidden" }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>{t("administration.demos.table.contact", { defaultValue: "Contact" })}</TableCell>
                      <TableCell>{t("administration.demos.table.office", { defaultValue: "Office" })}</TableCell>
                      <TableCell>{t("administration.demos.table.notes", { defaultValue: "Notes" })}</TableCell>
                      <TableCell>{t("administration.demos.table.status", { defaultValue: "Status" })}</TableCell>
                      <TableCell align={isRTL ? "left" : "right"}>{t("administration.demos.table.actions", { defaultValue: "Actions" })}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {demoRequests.map((demo) => (
                      <TableRow key={demo.id} hover>
                        <TableCell>
                          <Typography sx={{ fontWeight: 700 }}>{demo.fullName}</Typography>
                          <Typography variant="caption" color="text.secondary" sx={{ display: "block" }}>{demo.email}</Typography>
                          <Typography variant="caption" color="text.secondary" sx={{ display: "block" }}>{demo.phoneNumber || "-"}</Typography>
                        </TableCell>
                        <TableCell>
                          <Typography sx={{ fontWeight: 700 }}>{demo.officeName}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {new Date(demo.createdAtUtc).toLocaleString()}
                          </Typography>
                        </TableCell>
                        <TableCell>{demo.notes || "-"}</TableCell>
                        <TableCell>
                          <Chip size="small" label={t(`administration.demos.status.${demo.status.toLowerCase()}`, { defaultValue: demo.status })} />
                          {demo.reviewedAtUtc && (
                            <Typography variant="caption" color="text.secondary" sx={{ display: "block", mt: 0.5 }}>
                              {demo.reviewedByName ? `${demo.reviewedByName} - ` : ""}{new Date(demo.reviewedAtUtc).toLocaleString()}
                            </Typography>
                          )}
                        </TableCell>
                        <TableCell align={isRTL ? "left" : "right"}>
                          <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end" }}>
                            {demo.status === "Pending" && (
                              <>
                                <Button size="small" variant="contained" color="success" disabled={!!pendingAction[`demo-${demo.id}`]} onClick={() => reviewDemoRequest(demo.id, "Approved")}>
                                  {t("administration.demos.approve", { defaultValue: "Approve" })}
                                </Button>
                                <Button size="small" variant="outlined" color="warning" disabled={!!pendingAction[`demo-${demo.id}`]} onClick={() => reviewDemoRequest(demo.id, "Rejected")}>
                                  {t("administration.demos.reject", { defaultValue: "Reject" })}
                                </Button>
                              </>
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

          {activeTab === "landing" && isSuperAdmin && (
            <>
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 2, mb: 2 }}>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 800 }}>
                    {t("administration.landing.title")}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {t("administration.landing.subtitle")}
                  </Typography>
                </Box>
                <Button
                  variant="contained"
                  onClick={saveLandingPage}
                  disabled={!!pendingAction.landing}
                >
                  {t("administration.landing.save")}
                </Button>
              </Box>

              {saveMessage && (
                <Alert severity={saveMessage === t("administration.landing.saveSuccess") ? "success" : "error"} sx={{ mb: 2 }}>
                  {saveMessage}
                </Alert>
              )}

              <Grid container spacing={2}>
                <Grid size={{ xs: 12, md: 6 }}>
                  <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", height: "100%" }}>
                    <CardContent>
                      <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
                        {t("administration.landing.sections.general")}
                      </Typography>
                      <Box sx={{ display: "grid", gap: 2 }}>
                        <TextField
                          label={t("administration.landing.fields.systemName")}
                          value={landingSettings.systemName}
                          onChange={(e) => updateLandingField("systemName", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.systemNameAr")}
                          value={landingSettings.systemNameAr}
                          onChange={(e) => updateLandingField("systemNameAr", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.contactEmail")}
                          value={landingSettings.contactEmail}
                          onChange={(e) => updateLandingField("contactEmail", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.contactPhone")}
                          value={landingSettings.contactPhone}
                          onChange={(e) => updateLandingField("contactPhone", e.target.value)}
                          fullWidth
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                  <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider", height: "100%" }}>
                    <CardContent>
                      <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
                        {t("administration.landing.sections.actions")}
                      </Typography>
                      <Box sx={{ display: "grid", gap: 2 }}>
                        <TextField
                          label={t("administration.landing.fields.primaryButtonUrl")}
                          value={landingSettings.primaryButtonUrl}
                          onChange={(e) => updateLandingField("primaryButtonUrl", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.secondaryButtonUrl")}
                          value={landingSettings.secondaryButtonUrl}
                          onChange={(e) => updateLandingField("secondaryButtonUrl", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.updatedAt")}
                          value={landingSettings.updatedAtUtc ? new Date(landingSettings.updatedAtUtc).toLocaleString() : "-"}
                          fullWidth
                          disabled
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                  <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider" }}>
                    <CardContent>
                      <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
                        {t("administration.landing.sections.english")}
                      </Typography>
                      <Box sx={{ display: "grid", gap: 2 }}>
                        <TextField
                          label={t("administration.landing.fields.tagline")}
                          value={landingSettings.tagline}
                          onChange={(e) => updateLandingField("tagline", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.heroTitle")}
                          value={landingSettings.heroTitle}
                          onChange={(e) => updateLandingField("heroTitle", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.heroSubtitle")}
                          value={landingSettings.heroSubtitle}
                          onChange={(e) => updateLandingField("heroSubtitle", e.target.value)}
                          fullWidth
                          multiline
                          minRows={4}
                        />
                        <TextField
                          label={t("administration.landing.fields.primaryButtonText")}
                          value={landingSettings.primaryButtonText}
                          onChange={(e) => updateLandingField("primaryButtonText", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.secondaryButtonText")}
                          value={landingSettings.secondaryButtonText}
                          onChange={(e) => updateLandingField("secondaryButtonText", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.aboutTitle")}
                          value={landingSettings.aboutTitle}
                          onChange={(e) => updateLandingField("aboutTitle", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.aboutDescription")}
                          value={landingSettings.aboutDescription}
                          onChange={(e) => updateLandingField("aboutDescription", e.target.value)}
                          fullWidth
                          multiline
                          minRows={4}
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                  <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider" }}>
                    <CardContent>
                      <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
                        {t("administration.landing.sections.arabic")}
                      </Typography>
                      <Box sx={{ display: "grid", gap: 2 }}>
                        <TextField
                          label={t("administration.landing.fields.taglineAr")}
                          value={landingSettings.taglineAr}
                          onChange={(e) => updateLandingField("taglineAr", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.heroTitleAr")}
                          value={landingSettings.heroTitleAr}
                          onChange={(e) => updateLandingField("heroTitleAr", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.heroSubtitleAr")}
                          value={landingSettings.heroSubtitleAr}
                          onChange={(e) => updateLandingField("heroSubtitleAr", e.target.value)}
                          fullWidth
                          multiline
                          minRows={4}
                        />
                        <TextField
                          label={t("administration.landing.fields.primaryButtonTextAr")}
                          value={landingSettings.primaryButtonTextAr}
                          onChange={(e) => updateLandingField("primaryButtonTextAr", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.secondaryButtonTextAr")}
                          value={landingSettings.secondaryButtonTextAr}
                          onChange={(e) => updateLandingField("secondaryButtonTextAr", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.aboutTitleAr")}
                          value={landingSettings.aboutTitleAr}
                          onChange={(e) => updateLandingField("aboutTitleAr", e.target.value)}
                          fullWidth
                        />
                        <TextField
                          label={t("administration.landing.fields.aboutDescriptionAr")}
                          value={landingSettings.aboutDescriptionAr}
                          onChange={(e) => updateLandingField("aboutDescriptionAr", e.target.value)}
                          fullWidth
                          multiline
                          minRows={4}
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid size={{ xs: 12 }}>
                  <Card elevation={0} sx={{ borderRadius: 3, border: "1px solid", borderColor: "divider" }}>
                    <CardContent>
                      <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
                        {t("administration.landing.sections.features")}
                      </Typography>
                      <Grid container spacing={2}>
                        {[1, 2, 3].map((index) => (
                          <Grid key={index} size={{ xs: 12, md: 4 }}>
                            <Paper elevation={0} sx={{ p: 2, borderRadius: 3, border: "1px solid", borderColor: "divider", height: "100%" }}>
                              <Typography variant="subtitle1" sx={{ fontWeight: 800, mb: 2 }}>
                                {t("administration.landing.fields.feature", { number: index })}
                              </Typography>
                              <Box sx={{ display: "grid", gap: 2 }}>
                                <TextField
                                  label={t("administration.landing.fields.featureTitle")}
                                  value={landingSettings[`feature${index}Title` as keyof LandingPageSettings] as string}
                                  onChange={(e) =>
                                    updateLandingField(`feature${index}Title` as keyof LandingPageSettings, e.target.value as never)
                                  }
                                  fullWidth
                                />
                                <TextField
                                  label={t("administration.landing.fields.featureTitleAr")}
                                  value={landingSettings[`feature${index}TitleAr` as keyof LandingPageSettings] as string}
                                  onChange={(e) =>
                                    updateLandingField(`feature${index}TitleAr` as keyof LandingPageSettings, e.target.value as never)
                                  }
                                  fullWidth
                                />
                                <TextField
                                  label={t("administration.landing.fields.featureDescription")}
                                  value={landingSettings[`feature${index}Description` as keyof LandingPageSettings] as string}
                                  onChange={(e) =>
                                    updateLandingField(`feature${index}Description` as keyof LandingPageSettings, e.target.value as never)
                                  }
                                  fullWidth
                                  multiline
                                  minRows={3}
                                />
                                <TextField
                                  label={t("administration.landing.fields.featureDescriptionAr")}
                                  value={landingSettings[`feature${index}DescriptionAr` as keyof LandingPageSettings] as string}
                                  onChange={(e) =>
                                    updateLandingField(`feature${index}DescriptionAr` as keyof LandingPageSettings, e.target.value as never)
                                  }
                                  fullWidth
                                  multiline
                                  minRows={3}
                                />
                              </Box>
                            </Paper>
                          </Grid>
                        ))}
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
            </>
          )}
        </>
      )}
    </Box>
  );
}
