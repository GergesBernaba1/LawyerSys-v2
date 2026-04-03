"use client"
import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  MenuItem,
  Paper,
  Snackbar,
  Stack,
  Switch,
  TextField,
  FormControlLabel,
  Typography,
  useTheme,
} from "@mui/material";
import { Lock as LockIcon, Person as PersonIcon } from "@mui/icons-material";
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
  const [changingPassword, setChangingPassword] = useState(false);
  const [snackbar, setSnackbar] = useState<SnackbarState>({
    open: false,
    message: "",
    severity: "success",
  });

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

  return (
    <Box dir={isRTL ? "rtl" : "ltr"} sx={{ pb: 4 }}>
      <Stack spacing={3}>
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
                label={t("profile.address", { defaultValue: "Address" })}
                value={profile.address}
                onChange={(e) => setProfile({ ...profile, address: e.target.value })}
                fullWidth
              />
              <TextField
                label={t("profile.jobTitle", { defaultValue: "Job title" })}
                value={profile.jobTitle}
                onChange={(e) => setProfile({ ...profile, jobTitle: e.target.value })}
                fullWidth
              />
              <TextField
                type="date"
                label={t("profile.dateOfBirth", { defaultValue: "Date of birth" })}
                value={profile.dateOfBirth}
                onChange={(e) => setProfile({ ...profile, dateOfBirth: e.target.value })}
                fullWidth
                InputLabelProps={{ shrink: true }}
              />
              <SearchableSelect
                label={t("profile.country", { defaultValue: "Country" })}
                value={profile.countryId ?? ""}
                onChange={(value) =>
                  setProfile({
                    ...profile,
                    countryId: value === null || value === "" ? null : Number(value),
                  })
                }
                options={[
                  { value: "", label: t("profile.selectCountry", { defaultValue: "Select country" }) },
                  ...countries.map((country) => ({ value: country.id, label: country.name })),
                ]}
              />
              <TextField
                select
                label={t("profile.preferredLanguage", { defaultValue: "Preferred language" })}
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
              >
                <MenuItem value="en">{t("profile.languageEnglish", { defaultValue: "English" })}</MenuItem>
                <MenuItem value="ar">{t("profile.languageArabic", { defaultValue: "Arabic" })}</MenuItem>
              </TextField>
              <Stack spacing={0.5}>
                <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                  {t("profile.notificationsTitle", { defaultValue: "Notification preferences" })}
                </Typography>
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
                  label={t("profile.caseUpdatesEnabled", { defaultValue: "Case updates" })}
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
                  label={t("profile.billingUpdatesEnabled", { defaultValue: "Billing updates" })}
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
                  label={t("profile.documentRequestsEnabled", { defaultValue: "Document requests" })}
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
                  label={t("profile.conversationUpdatesEnabled", { defaultValue: "Conversation updates" })}
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
                  label={t("profile.emailNotificationsEnabled", { defaultValue: "Email alerts" })}
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
                  label={t("profile.smsNotificationsEnabled", { defaultValue: "SMS alerts" })}
                />
              </Stack>
              {canEditTenant && profile.canManageTenant && (
                <>
                  <TextField
                    label={t("profile.tenantName", { defaultValue: "Lawyer Office Name" })}
                    value={profile.tenantName}
                    onChange={(e) => setProfile({ ...profile, tenantName: e.target.value })}
                    fullWidth
                  />
                  <TextField
                    label={t("profile.tenantPhoneNumber", { defaultValue: "Lawyer Office Phone Number" })}
                    value={profile.tenantPhoneNumber}
                    onChange={(e) => setProfile({ ...profile, tenantPhoneNumber: e.target.value })}
                    fullWidth
                  />
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
            />
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
