"use client"
import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Alert,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  IconButton,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Skeleton,
  Snackbar,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
  Typography,
  useTheme,
} from "@mui/material";
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  LocationCity as LocationCityIcon,
  Public as PublicIcon,
  Refresh as RefreshIcon,
} from "@mui/icons-material";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";
import useConfirmDialog from "../../src/hooks/useConfirmDialog";
import SearchableSelect from "../../src/components/SearchableSelect";

type CountryOption = {
  id: number;
  name: string;
  nameEn: string;
  nameAr: string;
};

type LocationCity = {
  id: number;
  countryId: number;
  nameEn: string;
  nameAr: string;
  isTenantOwned: boolean;
  canEdit: boolean;
  canDelete: boolean;
};

type LocationCountry = {
  id: number;
  nameEn: string;
  nameAr: string;
  cityCount: number;
  cities: LocationCity[];
};

type CityFormState = {
  id: number;
  countryId: number;
  nameEn: string;
  nameAr: string;
};

const emptyForm: CityFormState = {
  id: 0,
  countryId: 0,
  nameEn: "",
  nameAr: "",
};

export default function GovernmentsPage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === "rtl" || (i18n.resolvedLanguage || i18n.language || "").startsWith("ar");
  const { user, hasRole, hasAnyRole } = useAuth();
  const isSuperAdmin = hasRole("SuperAdmin");
  const canManageCities = hasAnyRole("Admin", "SuperAdmin");
  const { confirm, confirmDialog } = useConfirmDialog();

  const [items, setItems] = useState<LocationCountry[]>([]);
  const [countryOptions, setCountryOptions] = useState<CountryOption[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedCountryId, setSelectedCountryId] = useState<number | "">("");
  const [editOpen, setEditOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState<CityFormState>(emptyForm);
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: "success" | "error";
  }>({ open: false, message: "", severity: "success" });

  const isArabic = (i18n.resolvedLanguage || i18n.language || "").startsWith("ar");

  async function load(countryId?: number | "") {
    setLoading(true);
    try {
      const params = isSuperAdmin && countryId ? { countryId } : undefined;
      const res = await api.get("/Governments/location-catalog", { params });
      const nextItems = Array.isArray(res.data) ? res.data : [];
      setItems(nextItems);

      if (!isSuperAdmin) {
        setSelectedCountryId(nextItems[0]?.id ?? "");
      }
    } catch {
      setSnackbar({
        open: true,
        message: t("governments.failedLocationsLoad"),
        severity: "error",
      });
    } finally {
      setLoading(false);
    }
  }

  async function loadCountryOptions() {
    try {
      const res = await api.get("/Account/countries");
      setCountryOptions(Array.isArray(res.data) ? res.data : []);
    } catch {
      // Keep the main page functional even if country options fail to load.
    }
  }

  useEffect(() => {
    void load(selectedCountryId);
  }, [isSuperAdmin, selectedCountryId]);

  useEffect(() => {
    if (isSuperAdmin) {
      void loadCountryOptions();
    }
  }, [isSuperAdmin]);

  const filterCountries = useMemo(
    () =>
      countryOptions.map((country) => ({
        id: country.id,
        label: isArabic ? country.nameAr : country.nameEn,
      })),
    [countryOptions, isArabic]
  );

  const visibleRows = useMemo(
    () =>
      items.flatMap((country) =>
        country.cities.map((city) => ({
          ...city,
          countryName: isArabic ? country.nameAr : country.nameEn,
          countryNameEn: country.nameEn,
          countryNameAr: country.nameAr,
        }))
      ),
    [items, isArabic]
  );

  const totalCities = visibleRows.length;
  const userCountryId = Number(user?.countryId || 0) || 0;
  const userCountryName =
    user?.countryName ||
    (selectedCountryId !== ""
      ? filterCountries.find((country) => country.id === selectedCountryId)?.label
      : visibleRows[0]?.countryName) ||
    "";
  const isEditing = form.id > 0;

  function openCreate() {
    const defaultCountryId = isSuperAdmin
      ? (selectedCountryId === "" ? filterCountries[0]?.id ?? 0 : Number(selectedCountryId))
      : userCountryId;

    setForm({
      id: 0,
      countryId: defaultCountryId,
      nameEn: "",
      nameAr: "",
    });
    setEditOpen(true);
  }

  function openEdit(city: LocationCity) {
    setForm({
      id: city.id,
      countryId: city.countryId,
      nameEn: city.nameEn,
      nameAr: city.nameAr,
    });
    setEditOpen(true);
  }

  async function handleSave() {
    const nextCountryId = isSuperAdmin ? form.countryId : userCountryId;
    if (!nextCountryId || !form.nameEn.trim() || !form.nameAr.trim()) {
      setSnackbar({
        open: true,
        message: t("governments.cityValidation"),
        severity: "error",
      });
      return;
    }

    setSaving(true);
    try {
      const payload = {
        countryId: nextCountryId,
        nameEn: form.nameEn.trim(),
        nameAr: form.nameAr.trim(),
      };

      if (isEditing) {
        await api.put(`/Governments/cities/${form.id}`, payload);
      } else {
        await api.post("/Governments/cities", payload);
      }

      setSnackbar({
        open: true,
        message: isEditing ? t("governments.cityUpdated") : t("governments.cityCreated"),
        severity: "success",
      });
      setEditOpen(false);
      setForm(emptyForm);
      await load(selectedCountryId);
    } catch (err: any) {
      setSnackbar({
        open: true,
        message:
          err?.response?.data?.message ||
          (isEditing ? t("governments.failedUpdateCity") : t("governments.failedCreateCity")),
        severity: "error",
      });
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(city: LocationCity) {
    if (!city.canDelete) {
      return;
    }

    if (!(await confirm(t("governments.confirmDeleteCity")))) {
      return;
    }

    try {
      await api.delete(`/Governments/cities/${city.id}`);
      setSnackbar({
        open: true,
        message: t("governments.cityDeleted"),
        severity: "success",
      });
      await load(selectedCountryId);
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err?.response?.data?.message || t("governments.failedDeleteCity"),
        severity: "error",
      });
    }
  }

  return (
    <Box dir={isRTL ? "rtl" : "ltr"} sx={{ pb: 4 }}>
      {confirmDialog}

      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: { xs: "flex-start", md: "center" },
          mb: 4,
          gap: 2,
          flexDirection: { xs: "column", md: isRTL ? "row-reverse" : "row" },
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 2.5, flexDirection: isRTL ? "row-reverse" : "row" }}>
          <Box
            sx={{
              bgcolor: "primary.main",
              color: "white",
              p: 1.5,
              borderRadius: 3,
              display: "flex",
              boxShadow: "0 4px 12px rgba(79, 70, 229, 0.3)",
            }}
          >
            <PublicIcon fontSize="medium" />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: "-0.02em" }}>
              {t("governments.management")}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {isSuperAdmin ? t("governments.adminSubtitle") : t("governments.userSubtitle")}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
              {t("governments.totalCountries")}: <strong>{items.length}</strong> | {t("governments.totalCities")}:{" "}
              <strong>{totalCities}</strong>
            </Typography>
          </Box>
        </Box>

        <Box sx={{ display: "flex", gap: 1.5, width: { xs: "100%", md: "auto" }, flexDirection: isRTL ? "row-reverse" : "row" }}>
          {canManageCities && (
            <Button variant="contained" startIcon={<AddIcon />} onClick={openCreate}>
              {t("governments.addCity")}
            </Button>
          )}
          {isSuperAdmin && (
            <SearchableSelect<number | "">
              size="small"
              label={t("governments.filterCountry")}
              value={selectedCountryId}
              onChange={(value) => setSelectedCountryId(value ?? "")}
              options={[
                { value: "", label: t("governments.allCountries") },
                ...filterCountries.map((country) => ({
                  value: country.id,
                  label: country.label,
                })),
              ]}
              disableClearable
              sx={{ minWidth: { xs: "100%", md: 220 } }}
            />
          )}
          <Tooltip title={t("common.refresh")}>
            <span>
              <IconButton
                onClick={() => void load(selectedCountryId)}
                disabled={loading}
                sx={{
                  bgcolor: "background.paper",
                  border: "1px solid",
                  borderColor: "divider",
                  "&:hover": { bgcolor: "grey.50" },
                }}
              >
              <RefreshIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
        </Box>
      </Box>

      <Paper
        elevation={0}
        sx={{
          borderRadius: 4,
          border: "1px solid",
          borderColor: "divider",
          overflow: "hidden",
        }}
      >
        <TableContainer>
          <Table sx={{ minWidth: 720 }}>
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 700 }}>{t("governments.country")}</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>{t("governments.cityNameEn")}</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>{t("governments.cityNameAr")}</TableCell>
                {canManageCities && (
                  <TableCell align={isRTL ? "left" : "right"} sx={{ fontWeight: 700 }}>
                    {t("common.actions")}
                  </TableCell>
                )}
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                Array.from({ length: 8 }).map((_, index) => (
                  <TableRow key={index}>
                    {Array.from({ length: canManageCities ? 4 : 3 }).map((__, cellIndex) => (
                      <TableCell key={cellIndex}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : visibleRows.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={canManageCities ? 4 : 3} align="center" sx={{ py: 10 }}>
                    <LocationCityIcon sx={{ fontSize: 56, color: "primary.main", opacity: 0.35, mb: 2 }} />
                    <Typography variant="h6" gutterBottom>
                      {t("governments.emptyCatalog")}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {isSuperAdmin ? t("governments.noGovernments") : t("governments.noCitiesForProfile")}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                visibleRows.map((row) => (
                  <TableRow key={row.id} sx={{ "&:hover": { bgcolor: "grey.50" } }}>
                    <TableCell>{row.countryName}</TableCell>
                    <TableCell>{row.nameEn}</TableCell>
                    <TableCell>{row.nameAr}</TableCell>
                    {canManageCities && (
                      <TableCell align={isRTL ? "left" : "right"}>
                        <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end" }}>
                          {row.canEdit && (
                            <Tooltip title={t("common.edit")}>
                              <IconButton color="primary" onClick={() => openEdit(row)}>
                                <EditIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                          )}
                          {row.canDelete && (
                            <Tooltip title={t("common.delete")}>
                              <IconButton color="error" onClick={() => void handleDelete(row)}>
                                <DeleteIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                          )}
                          {!row.canEdit && !row.canDelete && (
                            <Typography variant="caption" color="text.secondary">
                              {row.isTenantOwned ? "" : t("governments.readOnlyCity")}
                            </Typography>
                          )}
                        </Box>
                      </TableCell>
                    )}
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      <Dialog
        open={editOpen}
        onClose={() => {
          if (saving) {
            return;
          }

          setEditOpen(false);
          setForm(emptyForm);
        }}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>{isEditing ? t("governments.editCity") : t("governments.createCity")}</DialogTitle>
        <DialogContent>
          <Stack spacing={2.5} sx={{ mt: 1 }}>
            {isSuperAdmin ? (
              <SearchableSelect<number>
                label={t("governments.country")}
                value={form.countryId || null}
                onChange={(value) => setForm((current) => ({ ...current, countryId: value ?? 0 }))}
                options={filterCountries.map((country) => ({
                  value: country.id,
                  label: country.label,
                }))}
                disableClearable
              />
            ) : (
              <TextField label={t("governments.country")} value={userCountryName} fullWidth disabled />
            )}
            <TextField
              label={t("governments.cityNameEn")}
              value={form.nameEn}
              onChange={(event) => setForm((current) => ({ ...current, nameEn: event.target.value }))}
              fullWidth
            />
            <TextField
              label={t("governments.cityNameAr")}
              value={form.nameAr}
              onChange={(event) => setForm((current) => ({ ...current, nameAr: event.target.value }))}
              fullWidth
            />
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 3 }}>
          <Button
            onClick={() => {
              setEditOpen(false);
              setForm(emptyForm);
            }}
            disabled={saving}
          >
            {t("common.cancel")}
          </Button>
          <Button variant="contained" onClick={handleSave} disabled={saving}>
            {isEditing ? t("common.save") : t("common.create")}
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((current) => ({ ...current, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: isRTL ? "left" : "right" }}
      >
        <Alert
          onClose={() => setSnackbar((current) => ({ ...current, open: false }))}
          severity={snackbar.severity}
          variant="filled"
          sx={{ borderRadius: 2, fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
