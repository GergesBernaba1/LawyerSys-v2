"use client";

import React, { useMemo, useState } from "react";
import {
  Alert,
  alpha,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  TextField,
  Typography,
  useTheme,
} from "@mui/material";
import { AutoAwesome as AIIcon, Refresh as RefreshIcon } from "@mui/icons-material";
import api from "../../src/services/api";
import { useTranslation } from "react-i18next";

type SummaryResponse = {
  language: string;
  summary: string;
  keyPoints: string[];
  usedAiModel: boolean;
};

type DraftResponse = {
  language: string;
  draftType: string;
  draftText: string;
  disclaimer: string;
  usedAiModel: boolean;
};

type SuggestionItem = {
  title: string;
  suggestedDueDate: string;
  suggestedReminderAt: string;
  priority: "High" | "Medium" | "Low";
  rationale: string;
  sourceType: string;
  sourceId?: number | null;
  caseCode?: number | null;
};

type SuggestionsResponse = {
  language: string;
  generatedForDate: string;
  daysWindow: number;
  suggestions: SuggestionItem[];
  usedAiModel: boolean;
};

const formatDate = (v: string) => {
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return v;
  return d.toLocaleDateString();
};

const formatDateTime = (v: string) => {
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return v;
  return d.toLocaleString();
};

export default function AIAssistantPage() {
  const { t, i18n } = useTranslation();
  const [language, setLanguage] = useState<"ar" | "en">((i18n.resolvedLanguage || i18n.language || "en").startsWith("ar") ? "ar" : "en");
  const theme = useTheme();
  const isRTL = language === "ar";
  const [error, setError] = useState("");

  const [summaryInput, setSummaryInput] = useState("");
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [summaryResult, setSummaryResult] = useState<SummaryResponse | null>(null);

  const [draftType, setDraftType] = useState("Memo");
  const [draftInstructions, setDraftInstructions] = useState("");
  const [draftContext, setDraftContext] = useState("");
  const [draftLoading, setDraftLoading] = useState(false);
  const [draftResult, setDraftResult] = useState<DraftResponse | null>(null);

  const [daysWindow, setDaysWindow] = useState(14);
  const [suggestionsLoading, setSuggestionsLoading] = useState(false);
  const [suggestionsResult, setSuggestionsResult] = useState<SuggestionsResponse | null>(null);
  const legalHeroGradient = `linear-gradient(125deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.main} 58%, ${theme.palette.secondary.main} 100%)`;
  const sectionCardSx = {
    borderRadius: 4,
    border: "1px solid",
    borderColor: "divider",
    boxShadow: "0 8px 20px rgba(2, 12, 27, 0.06)",
    overflow: "hidden",
  } as const;
  const primaryActionSx = {
    borderRadius: 2.5,
    px: 2.5,
    fontWeight: 800,
    textTransform: "none",
    color: "#ffffff",
    background: "linear-gradient(135deg, #14345a 0%, #2d6a87 100%)",
    boxShadow: "0 10px 22px -8px rgba(20, 52, 90, 0.35)",
    "&:hover": {
      background: "linear-gradient(135deg, #112b4b 0%, #255a74 100%)",
    },
    "&.Mui-disabled": {
      color: alpha("#ffffff", 0.78),
      background: alpha(theme.palette.primary.main, 0.42),
      boxShadow: "none",
    },
  } as const;
  const outlinedActionSx = {
    borderRadius: 2.5,
    px: 2.2,
    fontWeight: 700,
    textTransform: "none",
    borderWidth: 2,
    borderColor: alpha(theme.palette.primary.main, 0.35),
    color: "primary.main",
    "&:hover": {
      borderWidth: 2,
      borderColor: theme.palette.primary.main,
      bgcolor: alpha(theme.palette.primary.main, 0.05),
    },
    "&.Mui-disabled": {
      borderColor: alpha(theme.palette.primary.main, 0.2),
      color: alpha(theme.palette.primary.main, 0.45),
    },
  } as const;

  const draftTypes = useMemo(
    () => [
      { value: "Memo", label: t("aiAssistant.draftTypes.memo") },
      { value: "Email", label: t("aiAssistant.draftTypes.email") },
      { value: "CourtFiling", label: t("aiAssistant.draftTypes.courtFiling") },
      { value: "ContractClause", label: t("aiAssistant.draftTypes.contractClause") },
      { value: "General", label: t("aiAssistant.draftTypes.general") },
    ],
    [t]
  );

  async function generateSummary() {
    if (!summaryInput.trim()) return;
    setSummaryLoading(true);
    setError("");
    try {
      const res = await api.post("/AIAssistant/summarize", {
        text: summaryInput,
        language,
        maxKeyPoints: 5,
      });
      setSummaryResult(res.data || null);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("aiAssistant.failedSummary"));
    } finally {
      setSummaryLoading(false);
    }
  }

  async function generateDraft() {
    if (!draftInstructions.trim()) return;
    setDraftLoading(true);
    setError("");
    try {
      const res = await api.post("/AIAssistant/draft", {
        language,
        draftType,
        instructions: draftInstructions,
        context: draftContext,
      });
      setDraftResult(res.data || null);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("aiAssistant.failedDraft"));
    } finally {
      setDraftLoading(false);
    }
  }

  async function loadSuggestions() {
    setSuggestionsLoading(true);
    setError("");
    try {
      const res = await api.get("/AIAssistant/task-deadline-suggestions", {
        params: { days: daysWindow, maxSuggestions: 12, language },
      });
      setSuggestionsResult(res.data || null);
    } catch (err: any) {
      setError(err?.response?.data?.message || t("aiAssistant.failedSuggestions"));
    } finally {
      setSuggestionsLoading(false);
    }
  }

  return (
    <Box dir={isRTL ? "rtl" : "ltr"} sx={{ pb: 4 }}>
      <Paper
        elevation={0}
        sx={{
          p: { xs: 2.5, md: 3.5 },
          mb: 3,
          borderRadius: 4,
          color: "white",
          background: legalHeroGradient,
          boxShadow: `0 20px 40px -12px ${alpha(theme.palette.primary.main, 0.35)}`,
        }}
      >
        <Stack direction={{ xs: "column", md: "row" }} justifyContent="space-between" alignItems={{ xs: "flex-start", md: "center" }} spacing={2}>
          <Box>
            <Stack direction="row" spacing={1} alignItems="center">
              <AIIcon sx={{ color: theme.palette.secondary.light }} />
              <Typography variant="h5" sx={{ fontWeight: 800 }}>{t("aiAssistant.title")}</Typography>
            </Stack>
            <Typography variant="body2" sx={{ mt: 0.5, opacity: 0.92 }}>{t("aiAssistant.subtitle")}</Typography>
          </Box>
          <FormControl
            size="small"
            sx={{
              minWidth: 180,
              bgcolor: alpha("#ffffff", 0.1),
              borderRadius: 2.5,
              "& .MuiInputLabel-root": { color: alpha("#ffffff", 0.92) },
              "& .MuiOutlinedInput-root": {
                color: "white",
                borderRadius: 2.5,
                "& fieldset": { borderColor: alpha("#ffffff", 0.4) },
                "&:hover fieldset": { borderColor: alpha("#ffffff", 0.65) },
                "&.Mui-focused fieldset": { borderColor: alpha("#ffffff", 0.85) },
              },
              "& .MuiSvgIcon-root": { color: "white" },
            }}
          >
            <InputLabel>{t("aiAssistant.language")}</InputLabel>
            <Select value={language} label={t("aiAssistant.language")} onChange={(e) => setLanguage(String(e.target.value) as "ar" | "en")}>
              <MenuItem value="en">{t("aiAssistant.english")}</MenuItem>
              <MenuItem value="ar">{t("aiAssistant.arabic")}</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Grid container spacing={2}>
        <Grid size={{ xs: 12 }}>
          <Card sx={sectionCardSx}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("aiAssistant.summaryTitle")}</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>{t("aiAssistant.summaryHint")}</Typography>
              <Stack spacing={1.5}>
                <TextField
                  label={t("aiAssistant.summaryInput")}
                  value={summaryInput}
                  onChange={(e) => setSummaryInput(e.target.value)}
                  multiline
                  minRows={5}
                  placeholder={t("aiAssistant.summaryPlaceholder")}
                />
                <Stack direction="row" spacing={1}>
                  <Button variant="contained" sx={primaryActionSx} onClick={() => void generateSummary()} disabled={summaryLoading || !summaryInput.trim()}>
                    {t("aiAssistant.generateSummary")}
                  </Button>
                  <Button variant="outlined" sx={outlinedActionSx} startIcon={<RefreshIcon />} onClick={() => setSummaryResult(null)}>
                    {t("app.reset")}
                  </Button>
                </Stack>

                {summaryResult && (
                  <Paper variant="outlined" sx={{ p: 2, borderRadius: 3, bgcolor: alpha(theme.palette.primary.main, 0.02), borderColor: alpha(theme.palette.primary.main, 0.2) }}>
                    <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
                      <Typography sx={{ fontWeight: 700 }}>{t("aiAssistant.summaryOutput")}</Typography>
                      <Chip size="small" label={summaryResult.usedAiModel ? t("aiAssistant.modelAi") : t("aiAssistant.modelFallback")} color={summaryResult.usedAiModel ? "primary" : "default"} />
                    </Stack>
                    <Typography sx={{ whiteSpace: "pre-wrap", mb: 1.5 }}>{summaryResult.summary}</Typography>
                    <Typography variant="subtitle2" sx={{ mb: 0.75 }}>{t("aiAssistant.keyPoints")}</Typography>
                    <Stack spacing={0.5}>
                      {(summaryResult.keyPoints || []).map((point, idx) => (
                        <Typography key={idx} variant="body2">• {point}</Typography>
                      ))}
                    </Stack>
                  </Paper>
                )}
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Card sx={sectionCardSx}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{t("aiAssistant.draftTitle")}</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>{t("aiAssistant.draftHint")}</Typography>
              <Grid container spacing={1.5}>
                <Grid size={{ xs: 12, md: 3 }}>
                  <FormControl fullWidth>
                    <InputLabel>{t("aiAssistant.draftType")}</InputLabel>
                    <Select value={draftType} label={t("aiAssistant.draftType")} onChange={(e) => setDraftType(String(e.target.value))}>
                      {draftTypes.map((item) => <MenuItem key={item.value} value={item.value}>{item.label}</MenuItem>)}
                    </Select>
                  </FormControl>
                </Grid>
                <Grid size={{ xs: 12, md: 9 }}>
                  <TextField
                    fullWidth
                    label={t("aiAssistant.instructions")}
                    value={draftInstructions}
                    onChange={(e) => setDraftInstructions(e.target.value)}
                    placeholder={t("aiAssistant.instructionsPlaceholder")}
                  />
                </Grid>
                <Grid size={{ xs: 12 }}>
                  <TextField
                    fullWidth
                    label={t("aiAssistant.context")}
                    value={draftContext}
                    onChange={(e) => setDraftContext(e.target.value)}
                    multiline
                    minRows={4}
                    placeholder={t("aiAssistant.contextPlaceholder")}
                  />
                </Grid>
              </Grid>
              <Stack direction="row" spacing={1} sx={{ mt: 1.5 }}>
                <Button variant="contained" sx={primaryActionSx} onClick={() => void generateDraft()} disabled={draftLoading || !draftInstructions.trim()}>
                  {t("aiAssistant.generateDraft")}
                </Button>
                <Button variant="outlined" sx={outlinedActionSx} startIcon={<RefreshIcon />} onClick={() => setDraftResult(null)}>
                  {t("app.reset")}
                </Button>
              </Stack>

              {draftResult && (
                <Paper variant="outlined" sx={{ p: 2, mt: 1.5, borderRadius: 3, bgcolor: alpha(theme.palette.primary.main, 0.02), borderColor: alpha(theme.palette.primary.main, 0.2) }}>
                  <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
                    <Typography sx={{ fontWeight: 700 }}>{t("aiAssistant.draftOutput")}</Typography>
                    <Chip size="small" label={draftResult.usedAiModel ? t("aiAssistant.modelAi") : t("aiAssistant.modelFallback")} color={draftResult.usedAiModel ? "primary" : "default"} />
                  </Stack>
                  <Typography sx={{ whiteSpace: "pre-wrap" }}>{draftResult.draftText}</Typography>
                  <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1.25 }}>{draftResult.disclaimer}</Typography>
                </Paper>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Card sx={sectionCardSx}>
            <CardContent>
              <Stack direction={{ xs: "column", md: "row" }} justifyContent="space-between" alignItems={{ xs: "flex-start", md: "center" }} spacing={1.5} sx={{ mb: 1 }}>
                <Box>
                  <Typography variant="h6">{t("aiAssistant.suggestionsTitle")}</Typography>
                  <Typography variant="body2" color="text.secondary">{t("aiAssistant.suggestionsHint")}</Typography>
                </Box>
                <Stack direction="row" spacing={1}>
                  <FormControl size="small" sx={{ minWidth: 120 }}>
                    <InputLabel>{t("aiAssistant.days")}</InputLabel>
                    <Select value={daysWindow} label={t("aiAssistant.days")} onChange={(e) => setDaysWindow(Number(e.target.value))}>
                      <MenuItem value={7}>7</MenuItem>
                      <MenuItem value={14}>14</MenuItem>
                      <MenuItem value={30}>30</MenuItem>
                    </Select>
                  </FormControl>
                  <Button variant="contained" sx={primaryActionSx} onClick={() => void loadSuggestions()} disabled={suggestionsLoading}>
                    {t("aiAssistant.generateSuggestions")}
                  </Button>
                </Stack>
              </Stack>

              {suggestionsResult && (
                <Stack spacing={1}>
                  {(suggestionsResult.suggestions || []).map((s, idx) => (
                    <Paper key={`${s.sourceType}-${s.sourceId || idx}`} variant="outlined" sx={{ p: 1.5, borderRadius: 3 }}>
                      <Stack direction={{ xs: "column", md: "row" }} justifyContent="space-between" spacing={1}>
                        <Box>
                          <Typography sx={{ fontWeight: 700 }}>{s.title}</Typography>
                          <Typography variant="body2" color="text.secondary">{s.rationale}</Typography>
                        </Box>
                        <Stack direction="row" spacing={1} alignItems="center">
                          <Chip size="small" label={s.priority} color={s.priority === "High" ? "error" : s.priority === "Medium" ? "warning" : "default"} />
                          <Chip size="small" variant="outlined" label={`${t("aiAssistant.dueDate")}: ${formatDate(s.suggestedDueDate)}`} />
                          <Chip size="small" variant="outlined" label={`${t("aiAssistant.reminderAt")}: ${formatDateTime(s.suggestedReminderAt)}`} />
                        </Stack>
                      </Stack>
                    </Paper>
                  ))}
                </Stack>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
