"use client"
import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Avatar,
  Alert,
  Box,
  Button,
  CircularProgress,
  MenuItem,
  Paper,
  Tab,
  Tabs,
  Snackbar,
  Stack,
  Switch,
  TextField,
  FormControlLabel,
  Typography,
  useTheme,
} from "@mui/material";
import {
  Lock as LockIcon,
  Notifications as NotificationsIcon,
  Person as PersonIcon,
} from "@mui/icons-material";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";
import SearchableSelect from "../../src/components/SearchableSelect";

type MyProfile = {
  userName: string;
  fullName: string;
  email: string;
  phoneNumber: string;
  countryId: number | null;
  tenantName: string;
  tenantPhoneNumber: string;
  canManageTenant: boolean;
  address: string;
  jobTitle: string;
  dateOfBirth: string;
  profileImagePath?: string;
  profileImageUrl?: string;
  tenantLogoPath?: string;
  tenantLogoUrl?: string;
  notificationPreferences: {
    caseUpdatesEnabled: boolean;
    billingUpdatesEnabled: boolean;
    documentRequestsEnabled: boolean;
    conversationUpdatesEnabled: boolean;
    emailNotificationsEnabled: boolean;
    smsNotificationsEnabled: boolean;
    preferredLanguage: string;
  };
};

type SnackbarState = {
  open: boolean;
  message: string;
  severity: "success" | "error";
};

type CountryOption = {
  id: number;
  name: string;
};

const emptyProfile: MyProfile = {
  userName: "",
  fullName: "",
  email: "",
  phoneNumber: "",
  countryId: null,
  tenantName: "",
  tenantPhoneNumber: "",
  canManageTenant: false,
  address: "",
  jobTitle: "",
  dateOfBirth: "",
  profileImagePath: "",
  profileImageUrl: "",
  tenantLogoPath: "",
  tenantLogoUrl: "",
  notificationPreferences: {
    caseUpdatesEnabled: true,
    billingUpdatesEnabled: true,
    documentRequestsEnabled: true,
    conversationUpdatesEnabled: true,
    emailNotificationsEnabled: false,
    smsNotificationsEnabled: false,
    preferredLanguage: "en",
  },
};

function toProtectedImageUrl(path: string | undefined | null, endpoint: string): string | undefined {
  if (!path) return undefined;
  const apiBase = String(api.defaults.baseURL || "");
  const apiRoot = apiBase.replace(/\/api\/?$/, "") || "";
  const token = typeof window !== "undefined" ? localStorage.getItem("lawyersys-token") : "";
  const query = token ? `?access_token=${encodeURIComponent(token)}` : "";
  return `${apiRoot}${endpoint}${query}`;
}

export default function ProfilePage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === "rtl";
  const { isAuthenticated, setAuthToken, hasAnyRole, syncUserProfile } = useAuth();
  const canEditTenant = hasAnyRole("Admin", "SuperAdmin");

  const [profile, setProfile] = useState<MyProfile>(emptyProfile);
  const [initialProfile, setInitialProfile] = useState<MyProfile>(emptyProfile);
  const [countries, setCountries] = useState<CountryOption[]>([]);
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: "",
    newPassword: "",
    confirmNewPassword: "",
  });
  const [loadingProfile, setLoadingProfile] = useState(false);
  const [savingProfile, setSavingProfile] = useState(false);
  const [uploadingProfileImage, setUploadingProfileImage] = useState(false);
  const [uploadingTenantLogo, setUploadingTenantLogo] = useState(false);
  const [changingPassword, setChangingPassword] = useState(false);
  const [snackbar, setSnackbar] = useState<SnackbarState>({
    open: false,
    message: "",
    severity: "success",
  });
  const [activeTab, setActiveTab] = useState(0);
  const profileImageInputRef = React.useRef<HTMLInputElement | null>(null);
  const tenantLogoInputRef = React.useRef<HTMLInputElement | null>(null);

  const hasProfileChanges = useMemo(
    () => JSON.stringify(profile) !== JSON.stringify(initialProfile),
    [profile, initialProfile]
  );

  useEffect(() => {
    if (!isAuthenticated) return;

    let mounted = true;
    const loadPageData = async () => {
      setLoadingProfile(true);
      try {
        const language = (i18n.resolvedLanguage || i18n.language || "en").startsWith("ar") ? "ar-SA" : "en-US";
        const [profileRes, countriesRes] = await Promise.all([
          api.get("/Account/me", { headers: { "Accept-Language": language } }),
          api.get("/Account/countries", { headers: { "Accept-Language": language } }),
        ]);
        if (!mounted) return;

        const countryOptions = Array.isArray(countriesRes.data) ? countriesRes.data : [];
        setCountries(countryOptions);

        const incoming: MyProfile = {
          userName: profileRes.data?.userName ?? "",
          fullName: profileRes.data?.fullName ?? "",
          email: profileRes.data?.email ?? "",
          phoneNumber: profileRes.data?.phoneNumber ?? "",
          countryId: profileRes.data?.countryId ?? null,
          tenantName: profileRes.data?.tenantName ?? "",
          tenantPhoneNumber: profileRes.data?.tenantPhoneNumber ?? "",
          canManageTenant: !!profileRes.data?.canManageTenant,
          address: profileRes.data?.address ?? "",
          jobTitle: profileRes.data?.jobTitle ?? "",
          dateOfBirth: profileRes.data?.dateOfBirth ?? "",
          profileImagePath: profileRes.data?.profileImagePath ?? "",
          profileImageUrl: toProtectedImageUrl(profileRes.data?.profileImagePath, "/api/Account/me/profile-image") ?? "",
          tenantLogoPath: profileRes.data?.tenantLogoPath ?? "",
          tenantLogoUrl: toProtectedImageUrl(profileRes.data?.tenantLogoPath, "/api/Account/me/tenant-logo") ?? "",
          notificationPreferences: {
            caseUpdatesEnabled: profileRes.data?.notificationPreferences?.caseUpdatesEnabled ?? true,
            billingUpdatesEnabled: profileRes.data?.notificationPreferences?.billingUpdatesEnabled ?? true,
            documentRequestsEnabled: profileRes.data?.notificationPreferences?.documentRequestsEnabled ?? true,
            conversationUpdatesEnabled: profileRes.data?.notificationPreferences?.conversationUpdatesEnabled ?? true,
            emailNotificationsEnabled: profileRes.data?.notificationPreferences?.emailNotificationsEnabled ?? false,
            smsNotificationsEnabled: profileRes.data?.notificationPreferences?.smsNotificationsEnabled ?? false,
            preferredLanguage: profileRes.data?.notificationPreferences?.preferredLanguage ?? (i18n.resolvedLanguage?.startsWith("ar") ? "ar" : "en"),
          },
        };
        setProfile(incoming);
        setInitialProfile(incoming);
      } catch {
        if (mounted) {
          setSnackbar({
            open: true,
            message: t("profile.failedLoad"),
            severity: "error",
          });
        }
      } finally {
        if (mounted) {
          setLoadingProfile(false);
        }
      }
    };

    loadPageData();
    return () => {
      mounted = false;
    };
  }, [isAuthenticated, i18n.language, i18n.resolvedLanguage, t]);

  async function saveProfile() {
    setSavingProfile(true);
    try {
      const res = await api.put("/Account/me", {
        ...profile,
        countryId: profile.countryId,
        address: profile.address,
        jobTitle: profile.jobTitle,
        dateOfBirth: profile.dateOfBirth || null,
        notificationPreferences: profile.notificationPreferences,
      });
      const updatedProfile: MyProfile = {
        userName: res.data?.profile?.userName ?? profile.userName,
        fullName: res.data?.profile?.fullName ?? profile.fullName,
        email: res.data?.profile?.email ?? profile.email,
        phoneNumber: res.data?.profile?.phoneNumber ?? profile.phoneNumber,
        countryId: res.data?.profile?.countryId ?? profile.countryId,
        tenantName: res.data?.profile?.tenantName ?? profile.tenantName,
        tenantPhoneNumber: res.data?.profile?.tenantPhoneNumber ?? profile.tenantPhoneNumber,
        canManageTenant: !!res.data?.profile?.canManageTenant,
        address: res.data?.profile?.address ?? profile.address,
        jobTitle: res.data?.profile?.jobTitle ?? profile.jobTitle,
        dateOfBirth: res.data?.profile?.dateOfBirth ?? profile.dateOfBirth,
        profileImagePath: res.data?.profile?.profileImagePath ?? profile.profileImagePath,
        profileImageUrl:
          toProtectedImageUrl(res.data?.profile?.profileImagePath, "/api/Account/me/profile-image") ??
          profile.profileImageUrl,
        tenantLogoPath: res.data?.profile?.tenantLogoPath ?? profile.tenantLogoPath,
        tenantLogoUrl:
          toProtectedImageUrl(res.data?.profile?.tenantLogoPath, "/api/Account/me/tenant-logo") ??
          profile.tenantLogoUrl,
        notificationPreferences: {
          caseUpdatesEnabled: res.data?.profile?.notificationPreferences?.caseUpdatesEnabled ?? profile.notificationPreferences.caseUpdatesEnabled,
          billingUpdatesEnabled: res.data?.profile?.notificationPreferences?.billingUpdatesEnabled ?? profile.notificationPreferences.billingUpdatesEnabled,
          documentRequestsEnabled: res.data?.profile?.notificationPreferences?.documentRequestsEnabled ?? profile.notificationPreferences.documentRequestsEnabled,
          conversationUpdatesEnabled: res.data?.profile?.notificationPreferences?.conversationUpdatesEnabled ?? profile.notificationPreferences.conversationUpdatesEnabled,
          emailNotificationsEnabled: res.data?.profile?.notificationPreferences?.emailNotificationsEnabled ?? profile.notificationPreferences.emailNotificationsEnabled,
          smsNotificationsEnabled: res.data?.profile?.notificationPreferences?.smsNotificationsEnabled ?? profile.notificationPreferences.smsNotificationsEnabled,
          preferredLanguage: res.data?.profile?.notificationPreferences?.preferredLanguage ?? profile.notificationPreferences.preferredLanguage,
        },
      };

      if (typeof res.data?.token === "string" && res.data.token.length > 0) {
        setAuthToken(res.data.token);
      }

      syncUserProfile({
        countryId: updatedProfile.countryId,
        countryName: countries.find((item) => item.id === updatedProfile.countryId)?.name ?? "",
        tenantName: updatedProfile.tenantName,
        profileImagePath: updatedProfile.profileImagePath,
        profileImageUrl: updatedProfile.profileImageUrl,
        tenantLogoPath: updatedProfile.tenantLogoPath,
        tenantLogoUrl: updatedProfile.tenantLogoUrl,
      });

      setProfile(updatedProfile);
      setInitialProfile(updatedProfile);
      setSnackbar({
        open: true,
        message: t("profile.updated"),
        severity: "success",
      });
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err?.response?.data?.message || t("profile.failedUpdate"),
        severity: "error",
      });
    } finally {
      setSavingProfile(false);
    }
  }

  async function changePassword() {
    if (passwordForm.newPassword !== passwordForm.confirmNewPassword) {
      setSnackbar({
        open: true,
        message: t("profile.passwordMismatch"),
        severity: "error",
      });
      return;
    }

    setChangingPassword(true);
    try {
      await api.post("/Account/change-password", {
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
      });
      setPasswordForm({
        currentPassword: "",
        newPassword: "",
        confirmNewPassword: "",
      });
      setSnackbar({
        open: true,
        message: t("profile.passwordUpdated"),
        severity: "success",
      });
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err?.response?.data?.message || t("profile.failedPasswordUpdate"),
        severity: "error",
      });
    } finally {
      setChangingPassword(false);
    }
  }

  async function uploadMyProfileImage(file: File) {
    setUploadingProfileImage(true);
    try {
      const form = new FormData();
      form.append("file", file);
      const response = await api.post("/Account/me/profile-image", form, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      const nextPath = response.data?.profileImagePath ?? "";
      const nextUrl = toProtectedImageUrl(nextPath, "/api/Account/me/profile-image") ?? "";
      setProfile((prev) => ({ ...prev, profileImagePath: nextPath, profileImageUrl: nextUrl }));
      setInitialProfile((prev) => ({ ...prev, profileImagePath: nextPath, profileImageUrl: nextUrl }));
      syncUserProfile({ profileImagePath: nextPath, profileImageUrl: nextUrl });
      setSnackbar({
        open: true,
        message: t("profile.updated"),
        severity: "success",
      });
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err?.response?.data?.message || t("profile.failedUpdate"),
        severity: "error",
      });
    } finally {
      setUploadingProfileImage(false);
    }
  }

  async function uploadTenantLogo(file: File) {
    setUploadingTenantLogo(true);
    try {
      const form = new FormData();
      form.append("file", file);
      const response = await api.post("/Account/me/tenant-logo", form, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      const nextPath = response.data?.tenantLogoPath ?? "";
      const nextUrl = toProtectedImageUrl(nextPath, "/api/Account/me/tenant-logo") ?? "";
      setProfile((prev) => ({ ...prev, tenantLogoPath: nextPath, tenantLogoUrl: nextUrl }));
      setInitialProfile((prev) => ({ ...prev, tenantLogoPath: nextPath, tenantLogoUrl: nextUrl }));
      syncUserProfile({ tenantLogoPath: nextPath, tenantLogoUrl: nextUrl });
      setSnackbar({
        open: true,
        message: t("profile.updated"),
        severity: "success",
      });
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err?.response?.data?.message || t("profile.failedUpdate"),
        severity: "error",
      });
    } finally {
      setUploadingTenantLogo(false);
    }
  }

  return (
    <Box dir={isRTL ? "rtl" : "ltr"} sx={{ pb: 4 }}>
      <Stack spacing={3}>
        <Paper
          elevation={0}
          sx={{
            borderRadius: 4,
            border: "1px solid",
            borderColor: "divider",
            overflow: "hidden",
          }}
        >
          <Tabs
            value={activeTab}
            onChange={(_, value: number) => setActiveTab(value)}
            variant="fullWidth"
            sx={{ px: { xs: 1, sm: 2 }, pt: 1 }}
          >
            <Tab label={t("profile.profileTab")} />
            <Tab label={t("profile.notificationsTab")} />
            <Tab label={t("profile.passwordTab")} />
          </Tabs>
        </Paper>

        {activeTab === 0 && (
        <Paper
          elevation={0}
          sx={{
            p: 3,
            borderRadius: 4,
            border: "1px solid",
            borderColor: "divider",
          }}
        >
          <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 3 }}>
            <PersonIcon color="primary" />
            <Typography variant="h6" sx={{ fontWeight: 800 }}>
              {t("profile.editProfile")}
            </Typography>
          </Box>

          {loadingProfile ? (
            <Box sx={{ py: 6, display: "flex", justifyContent: "center" }}>
              <CircularProgress />
            </Box>
          ) : (
            <Stack spacing={2.5}>
              <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                {t("profile.profileImageSection")}
              </Typography>
              <Box
                sx={{
                  display: "flex",
                  width: "100%",
                  gap: 2,
                  alignItems: { xs: isRTL ? "flex-end" : "flex-start", sm: "center" },
                  justifyContent: isRTL ? "flex-end" : "flex-start",
                  flexDirection: { xs: "column", sm: isRTL ? "row-reverse" : "row" },
                }}
              >
                <Avatar
                  src={profile.profileImageUrl || undefined}
                  sx={{ width: 64, height: 64, bgcolor: "primary.main", fontWeight: 800 }}
                >
                  {(profile.fullName?.charAt(0) || profile.userName?.charAt(0) || "U").toUpperCase()}
                </Avatar>
                <Box
                  sx={{
                    width: { xs: "100%", sm: "auto" },
                    textAlign: isRTL ? "right" : "left",
                    display: "flex",
                    justifyContent: isRTL ? "flex-end" : "flex-start",
                  }}
                >
                  <Button
                    variant="outlined"
                    onClick={() => profileImageInputRef.current?.click()}
                    disabled={uploadingProfileImage}
                    sx={{ fontWeight: 700 }}
                  >
                    {uploadingProfileImage ? t("profile.saving") : t("files.upload")}
                  </Button>
                  <input
                    ref={profileImageInputRef}
                    type="file"
                    accept="image/*"
                    hidden
                    onChange={(e) => {
                      const selected = e.target.files?.[0];
                      e.currentTarget.value = "";
                      if (selected) void uploadMyProfileImage(selected);
                    }}
                  />
                </Box>
              </Box>
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" },
                  gap: 2,
                }}
              >
                <TextField
                  label={t("profile.userName")}
                  value={profile.userName}
                  onChange={(e) => setProfile({ ...profile, userName: e.target.value })}
                  fullWidth
                />
                <TextField
                  label={t("profile.fullName")}
                  value={profile.fullName}
                  onChange={(e) => setProfile({ ...profile, fullName: e.target.value })}
                  fullWidth
                />
                <TextField
                  label={t("profile.email")}
                  value={profile.email}
                  onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                  fullWidth
                />
                <TextField
                  label={t("profile.phoneNumber")}
                  value={profile.phoneNumber}
                  onChange={(e) => setProfile({ ...profile, phoneNumber: e.target.value })}
                  fullWidth
                />
                <TextField
                  label={t("profile.address")}
                  value={profile.address}
                  onChange={(e) => setProfile({ ...profile, address: e.target.value })}
                  fullWidth
                />
                <TextField
                  label={t("profile.jobTitle")}
                  value={profile.jobTitle}
                  onChange={(e) => setProfile({ ...profile, jobTitle: e.target.value })}
                  fullWidth
                />
                <TextField
                  type="date"
                  label={t("profile.dateOfBirth")}
                  value={profile.dateOfBirth}
                  onChange={(e) => setProfile({ ...profile, dateOfBirth: e.target.value })}
                  fullWidth
                  InputLabelProps={{ shrink: true }}
                />
                <SearchableSelect
                  label={t("profile.country")}
                  value={profile.countryId ?? ""}
                  onChange={(value) =>
                    setProfile({
                      ...profile,
                      countryId: value === null || value === "" ? null : Number(value),
                    })
                  }
                  options={[
                    { value: "", label: t("profile.selectCountry") },
                    ...countries.map((country) => ({ value: country.id, label: country.name })),
                  ]}
                />
              </Box>
              {canEditTenant && profile.canManageTenant && (
                <>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                    {t("profile.tenantLogoSection")}
                  </Typography>
                  <Box
                    sx={{
                      display: "flex",
                      width: "100%",
                      gap: 2,
                      alignItems: { xs: isRTL ? "flex-end" : "flex-start", sm: "center" },
                      justifyContent: isRTL ? "flex-end" : "flex-start",
                      flexDirection: { xs: "column", sm: isRTL ? "row-reverse" : "row" },
                    }}
                  >
                    <Avatar
                      src={profile.tenantLogoUrl || undefined}
                      variant="rounded"
                      sx={{ width: 64, height: 64, bgcolor: "secondary.main", fontWeight: 800, borderRadius: 2 }}
                    >
                      {(profile.tenantName?.charAt(0) || "T").toUpperCase()}
                    </Avatar>
                    <Box
                      sx={{
                        width: { xs: "100%", sm: "auto" },
                        textAlign: isRTL ? "right" : "left",
                        display: "flex",
                        justifyContent: isRTL ? "flex-end" : "flex-start",
                      }}
                    >
                      <Button
                        variant="outlined"
                        onClick={() => tenantLogoInputRef.current?.click()}
                        disabled={uploadingTenantLogo}
                        sx={{ fontWeight: 700 }}
                      >
                        {uploadingTenantLogo ? t("profile.saving") : t("files.upload")}
                      </Button>
                      <input
                        ref={tenantLogoInputRef}
                        type="file"
                        accept="image/*"
                        hidden
                        onChange={(e) => {
                          const selected = e.target.files?.[0];
                          e.currentTarget.value = "";
                          if (selected) void uploadTenantLogo(selected);
                        }}
                      />
                    </Box>
                  </Box>
                  <Box
                    sx={{
                      display: "grid",
                      gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" },
                      gap: 2,
                    }}
                  >
                    <TextField
                      label={t("profile.tenantName")}
                      value={profile.tenantName}
                      onChange={(e) => setProfile({ ...profile, tenantName: e.target.value })}
                      fullWidth
                    />
                    <TextField
                      label={t("profile.tenantPhoneNumber")}
                      value={profile.tenantPhoneNumber}
                      onChange={(e) => setProfile({ ...profile, tenantPhoneNumber: e.target.value })}
                      fullWidth
                    />
                  </Box>
                </>
              )}
              <Box sx={{ display: "flex", justifyContent: isRTL ? "flex-start" : "flex-end" }}>
                <Button
                  variant="contained"
                  onClick={saveProfile}
                  disabled={savingProfile || loadingProfile || !hasProfileChanges}
                  sx={{ minWidth: 180, fontWeight: 700 }}
                >
                  {savingProfile ? t("profile.saving") : t("profile.saveProfile")}
                </Button>
              </Box>
            </Stack>
          )}
        </Paper>
        )}

        {activeTab === 1 && (
        <Paper
          elevation={0}
          sx={{
            p: 3,
            borderRadius: 4,
            border: "1px solid",
            borderColor: "divider",
          }}
        >
          <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 3 }}>
            <NotificationsIcon color="primary" />
            <Typography variant="h6" sx={{ fontWeight: 800 }}>
              {t("profile.notificationsTab")}
            </Typography>
          </Box>

          <Stack spacing={2.5}>
            <TextField
              select
              label={t("profile.preferredLanguage")}
              value={profile.notificationPreferences.preferredLanguage}
              onChange={(e) =>
                setProfile({
                  ...profile,
                  notificationPreferences: {
                    ...profile.notificationPreferences,
                    preferredLanguage: e.target.value,
                  },
                })
              }
              fullWidth
              sx={{ maxWidth: { xs: "100%", md: "50%" } }}
            >
              <MenuItem value="en">{t("profile.languageEnglish")}</MenuItem>
              <MenuItem value="ar">{t("profile.languageArabic")}</MenuItem>
            </TextField>
            <Stack spacing={1}>
              <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                {t("profile.notificationsTitle")}
              </Typography>
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" },
                  gap: 1.5,
                }}
              >
                <FormControlLabel
                  control={
                    <Switch
                      checked={profile.notificationPreferences.caseUpdatesEnabled}
                      onChange={(e) =>
                        setProfile({
                          ...profile,
                          notificationPreferences: {
                            ...profile.notificationPreferences,
                            caseUpdatesEnabled: e.target.checked,
                          },
                        })
                      }
                    />
                  }
                  label={t("profile.caseUpdatesEnabled")}
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={profile.notificationPreferences.billingUpdatesEnabled}
                      onChange={(e) =>
                        setProfile({
                          ...profile,
                          notificationPreferences: {
                            ...profile.notificationPreferences,
                            billingUpdatesEnabled: e.target.checked,
                          },
                        })
                      }
                    />
                  }
                  label={t("profile.billingUpdatesEnabled")}
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={profile.notificationPreferences.documentRequestsEnabled}
                      onChange={(e) =>
                        setProfile({
                          ...profile,
                          notificationPreferences: {
                            ...profile.notificationPreferences,
                            documentRequestsEnabled: e.target.checked,
                          },
                        })
                      }
                    />
                  }
                  label={t("profile.documentRequestsEnabled")}
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={profile.notificationPreferences.conversationUpdatesEnabled}
                      onChange={(e) =>
                        setProfile({
                          ...profile,
                          notificationPreferences: {
                            ...profile.notificationPreferences,
                            conversationUpdatesEnabled: e.target.checked,
                          },
                        })
                      }
                    />
                  }
                  label={t("profile.conversationUpdatesEnabled")}
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={profile.notificationPreferences.emailNotificationsEnabled}
                      onChange={(e) =>
                        setProfile({
                          ...profile,
                          notificationPreferences: {
                            ...profile.notificationPreferences,
                            emailNotificationsEnabled: e.target.checked,
                          },
                        })
                      }
                    />
                  }
                  label={t("profile.emailNotificationsEnabled")}
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={profile.notificationPreferences.smsNotificationsEnabled}
                      onChange={(e) =>
                        setProfile({
                          ...profile,
                          notificationPreferences: {
                            ...profile.notificationPreferences,
                            smsNotificationsEnabled: e.target.checked,
                          },
                        })
                      }
                    />
                  }
                  label={t("profile.smsNotificationsEnabled")}
                />
              </Box>
            </Stack>
            <Box sx={{ display: "flex", justifyContent: isRTL ? "flex-start" : "flex-end" }}>
              <Button
                variant="contained"
                onClick={saveProfile}
                disabled={savingProfile || loadingProfile || !hasProfileChanges}
                sx={{ minWidth: 180, fontWeight: 700 }}
              >
                {savingProfile ? t("profile.saving") : t("profile.saveProfile")}
              </Button>
            </Box>
          </Stack>
        </Paper>
        )}

        {activeTab === 2 && (
        <Paper
          elevation={0}
          sx={{
            p: 3,
            borderRadius: 4,
            border: "1px solid",
            borderColor: "divider",
          }}
        >
          <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 3 }}>
            <LockIcon color="primary" />
            <Typography variant="h6" sx={{ fontWeight: 800 }}>
              {t("profile.changePassword")}
            </Typography>
          </Box>

          <Stack spacing={2.5}>
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" },
                gap: 2,
              }}
            >
              <TextField
                type="password"
                label={t("profile.currentPassword")}
                value={passwordForm.currentPassword}
                onChange={(e) =>
                  setPasswordForm({ ...passwordForm, currentPassword: e.target.value })
                }
                fullWidth
              />
              <TextField
                type="password"
                label={t("profile.newPassword")}
                value={passwordForm.newPassword}
                onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
                fullWidth
              />
              <TextField
                type="password"
                label={t("profile.confirmNewPassword")}
                value={passwordForm.confirmNewPassword}
                onChange={(e) =>
                  setPasswordForm({ ...passwordForm, confirmNewPassword: e.target.value })
                }
                fullWidth
                sx={{ gridColumn: { xs: "auto", md: "1 / span 2" } }}
              />
            </Box>
            <Box sx={{ display: "flex", justifyContent: isRTL ? "flex-start" : "flex-end" }}>
              <Button
                variant="contained"
                onClick={changePassword}
                disabled={
                  changingPassword ||
                  !passwordForm.currentPassword ||
                  !passwordForm.newPassword ||
                  !passwordForm.confirmNewPassword
                }
                sx={{ minWidth: 220, fontWeight: 700 }}
              >
                {changingPassword ? t("profile.saving") : t("profile.savePassword")}
              </Button>
            </Box>
          </Stack>
        </Paper>
        )}
      </Stack>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: isRTL ? "left" : "right" }}
      >
        <Alert
          severity={snackbar.severity}
          variant="filled"
          onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
          sx={{ borderRadius: 2, fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
