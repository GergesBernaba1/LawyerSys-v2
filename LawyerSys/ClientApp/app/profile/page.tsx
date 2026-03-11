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
  TextField,
  Typography,
  useTheme,
} from "@mui/material";
import { Lock as LockIcon, Person as PersonIcon } from "@mui/icons-material";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";

type MyProfile = {
  userName: string;
  fullName: string;
  email: string;
  phoneNumber: string;
  countryId: number | null;
  tenantName: string;
  tenantPhoneNumber: string;
  canManageTenant: boolean;
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
};

export default function ProfilePage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === "rtl";
  const { isAuthenticated, setAuthToken, hasAnyRole } = useAuth();
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
      };

      if (typeof res.data?.token === "string" && res.data.token.length > 0) {
        setAuthToken(res.data.token);
      }

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
                select
                label={t("profile.country", { defaultValue: "Country" })}
                value={profile.countryId ?? ""}
                onChange={(e) =>
                  setProfile({
                    ...profile,
                    countryId: e.target.value === "" ? null : Number(e.target.value),
                  })
                }
                fullWidth
              >
                <MenuItem value="">
                  {t("profile.selectCountry", { defaultValue: "Select country" })}
                </MenuItem>
                {countries.map((country) => (
                  <MenuItem key={country.id} value={country.id}>
                    {country.name}
                  </MenuItem>
                ))}
              </TextField>
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
