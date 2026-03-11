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
  Delete as DeleteIcon,
  Edit as EditIcon,
  LocationCity as LocationCityIcon,
  Public as PublicIcon,
  Refresh as RefreshIcon,
} from "@mui/icons-material";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";
import useConfirmDialog from "../../src/hooks/useConfirmDialog";

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
  const { hasRole } = useAuth();
  const isAdmin = hasRole("Admin");
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
      const params = isAdmin && countryId ? { countryId } : undefined;
      const res = await api.get("/Governments/location-catalog", { params });
      const nextItems = Array.isArray(res.data) ? res.data : [];
      setItems(nextItems);

      if (!isAdmin && nextItems.length > 0) {
        setSelectedCountryId(nextItems[0].id);
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
  }, [isAdmin, selectedCountryId]);

  useEffect(() => {
    if (isAdmin) {
      void loadCountryOptions();
    }
  }, [isAdmin]);

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
    if (!form.countryId || !form.nameEn.trim() || !form.nameAr.trim()) {
      setSnackbar({
        open: true,
        message: t("governments.cityValidation"),
        severity: "error",
      });
      return;
    }

    setSaving(true);
    try {
      await api.put(`/Governments/cities/${form.id}`, {
        countryId: form.countryId,
        nameEn: form.nameEn.trim(),
        nameAr: form.nameAr.trim(),
      });
      setSnackbar({
        open: true,
        message: t("governments.cityUpdated"),
        severity: "success",
      });
      setEditOpen(false);
      await load(selectedCountryId);
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err?.response?.data?.message || t("governments.failedUpdateCity"),
        severity: "error",
      });
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(city: LocationCity) {
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
              {isAdmin ? t("governments.adminSubtitle") : t("governments.userSubtitle")}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
              {t("governments.totalCountries")}: <strong>{items.length}</strong> | {t("governments.totalCities")}:{" "}
              <strong>{totalCities}</strong>
            </Typography>
          </Box>
        </Box>

        <Box sx={{ display: "flex", gap: 1.5, width: { xs: "100%", md: "auto" }, flexDirection: isRTL ? "row-reverse" : "row" }}>
          {isAdmin && (
            <FormControl size="small" sx={{ minWidth: { xs: "100%", md: 220 } }}>
              <InputLabel id="country-filter-label">{t("governments.filterCountry")}</InputLabel>
              <Select
                labelId="country-filter-label"
                value={selectedCountryId}
                label={t("governments.filterCountry")}
                onChange={(event) => setSelectedCountryId(event.target.value === "" ? "" : Number(event.target.value))}
              >
                <MenuItem value="">{t("governments.allCountries")}</MenuItem>
                {filterCountries.map((country) => (
                  <MenuItem key={country.id} value={country.id}>
                    {country.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
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
                {isAdmin && (
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
                    {Array.from({ length: isAdmin ? 4 : 3 }).map((__, cellIndex) => (
                      <TableCell key={cellIndex}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : visibleRows.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={isAdmin ? 4 : 3} align="center" sx={{ py: 10 }}>
                    <LocationCityIcon sx={{ fontSize: 56, color: "primary.main", opacity: 0.35, mb: 2 }} />
                    <Typography variant="h6" gutterBottom>
                      {t("governments.emptyCatalog")}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {isAdmin ? t("governments.noGovernments") : t("governments.noCitiesForProfile")}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                visibleRows.map((row) => (
                  <TableRow key={row.id} sx={{ "&:hover": { bgcolor: "grey.50" } }}>
                    <TableCell>{row.countryName}</TableCell>
                    <TableCell>{row.nameEn}</TableCell>
                    <TableCell>{row.nameAr}</TableCell>
                    {isAdmin && (
                      <TableCell align={isRTL ? "left" : "right"}>
                        <Box sx={{ display: "flex", gap: 1, justifyContent: isRTL ? "flex-start" : "flex-end" }}>
                          <Tooltip title={t("common.edit")}>
                            <IconButton color="primary" onClick={() => openEdit(row)}>
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title={t("common.delete")}>
                            <IconButton color="error" onClick={() => void handleDelete(row)}>
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
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

      <Dialog open={editOpen} onClose={() => !saving && setEditOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{t("governments.editCity")}</DialogTitle>
        <DialogContent>
          <Stack spacing={2.5} sx={{ mt: 1 }}>
            <FormControl fullWidth>
              <InputLabel id="edit-country-label">{t("governments.country")}</InputLabel>
              <Select
                labelId="edit-country-label"
                value={form.countryId}
                label={t("governments.country")}
                onChange={(event) => setForm((current) => ({ ...current, countryId: Number(event.target.value) }))}
              >
                {filterCountries.map((country) => (
                  <MenuItem key={country.id} value={country.id}>
                    {country.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
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
          <Button onClick={() => setEditOpen(false)} disabled={saving}>
            {t("common.cancel")}
          </Button>
          <Button variant="contained" onClick={handleSave} disabled={saving}>
            {t("common.save")}
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
