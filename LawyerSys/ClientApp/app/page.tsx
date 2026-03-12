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
  Container,
  Link,
  Paper,
  Stack,
  Typography,
  alpha,
  useTheme,
} from "@mui/material";
import {
  ArrowOutward as ArrowOutwardIcon,
  AutoAwesome as AutoAwesomeIcon,
  Balance as BalanceIcon,
  Bolt as BoltIcon,
  Insights as InsightsIcon,
  Security as SecurityIcon,
} from "@mui/icons-material";
import api from "../src/services/api";
import { useAuth } from "../src/services/auth";

type LandingFeature = {
  iconKey: string;
  title: string;
  description: string;
};

type LandingPageData = {
  systemName: string;
  tagline: string;
  heroTitle: string;
  heroSubtitle: string;
  primaryButtonText: string;
  primaryButtonUrl: string;
  secondaryButtonText: string;
  secondaryButtonUrl: string;
  aboutTitle: string;
  aboutDescription: string;
  contactEmail: string;
  contactPhone: string;
  features: LandingFeature[];
};

function getFeatureIcon(iconKey: string) {
  switch (iconKey) {
    case "automation":
      return <BoltIcon sx={{ fontSize: 28 }} />;
    case "collaboration":
      return <SecurityIcon sx={{ fontSize: 28 }} />;
    case "insight":
      return <InsightsIcon sx={{ fontSize: 28 }} />;
    default:
      return <AutoAwesomeIcon sx={{ fontSize: 28 }} />;
  }
}

function getDefaultLandingPage(t: (key: string) => string): LandingPageData {
  return {
    systemName: t("landing.defaults.systemName"),
    tagline: t("landing.defaults.tagline"),
    heroTitle: t("landing.defaults.heroTitle"),
    heroSubtitle: t("landing.defaults.heroSubtitle"),
    primaryButtonText: t("landing.defaults.primaryButtonText"),
    primaryButtonUrl: "/register",
    secondaryButtonText: t("landing.defaults.secondaryButtonText"),
    secondaryButtonUrl: "/login",
    aboutTitle: t("landing.defaults.aboutTitle"),
    aboutDescription: t("landing.defaults.aboutDescription"),
    contactEmail: "support@qadaya.app",
    contactPhone: "01018206558",
    features: [
      {
        iconKey: "automation",
        title: t("landing.defaults.features.automation.title"),
        description: t("landing.defaults.features.automation.description"),
      },
      {
        iconKey: "collaboration",
        title: t("landing.defaults.features.collaboration.title"),
        description: t("landing.defaults.features.collaboration.description"),
      },
      {
        iconKey: "insight",
        title: t("landing.defaults.features.insight.title"),
        description: t("landing.defaults.features.insight.description"),
      },
    ],
  };
}

function pickText(value: string | null | undefined, fallback: string) {
  return typeof value === "string" && value.trim().length > 0 ? value : fallback;
}

function buildLandingData(responseData: Partial<LandingPageData> | undefined, fallback: LandingPageData): LandingPageData {
  const responseFeatures = Array.isArray(responseData?.features) ? responseData?.features : [];

  return {
    systemName: pickText(responseData?.systemName, fallback.systemName),
    tagline: pickText(responseData?.tagline, fallback.tagline),
    heroTitle: pickText(responseData?.heroTitle, fallback.heroTitle),
    heroSubtitle: pickText(responseData?.heroSubtitle, fallback.heroSubtitle),
    primaryButtonText: pickText(responseData?.primaryButtonText, fallback.primaryButtonText),
    primaryButtonUrl: pickText(responseData?.primaryButtonUrl, fallback.primaryButtonUrl),
    secondaryButtonText: pickText(responseData?.secondaryButtonText, fallback.secondaryButtonText),
    secondaryButtonUrl: pickText(responseData?.secondaryButtonUrl, fallback.secondaryButtonUrl),
    aboutTitle: pickText(responseData?.aboutTitle, fallback.aboutTitle),
    aboutDescription: pickText(responseData?.aboutDescription, fallback.aboutDescription),
    contactEmail: pickText(responseData?.contactEmail, fallback.contactEmail),
    contactPhone: pickText(responseData?.contactPhone, fallback.contactPhone),
    features: fallback.features.map((feature, index) => {
      const responseFeature = responseFeatures[index];
      return {
        iconKey: pickText(responseFeature?.iconKey, feature.iconKey),
        title: pickText(responseFeature?.title, feature.title),
        description: pickText(responseFeature?.description, feature.description),
      };
    }),
  };
}

export default function LandingPage() {
  const router = useRouter();
  const theme = useTheme();
  const { t, i18n } = useTranslation();
  const { isAuthenticated, isAuthInitialized } = useAuth();
  const currentLanguage = (i18n.resolvedLanguage || i18n.language || "ar").startsWith("ar") ? "ar" : "en";
  const isRTL = currentLanguage === "ar";
  const fallbackData = useMemo(() => getDefaultLandingPage(t), [t]);
  const [data, setData] = useState<LandingPageData>(fallbackData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    setData(fallbackData);
  }, [fallbackData]);

  useEffect(() => {
    let mounted = true;
    const requestLanguage = currentLanguage === "ar" ? "ar-SA" : "en-US";

    (async () => {
      try {
        const response = await api.get("/LandingPage", {
          skipTenantHeader: true,
          headers: {
            "Accept-Language": requestLanguage,
          },
        } as any);

        if (mounted) {
          setData(buildLandingData(response.data, fallbackData));
          setError("");
        }
      } catch {
        if (mounted) {
          setData(fallbackData);
          setError(t("landing.failedLoad"));
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
  }, [currentLanguage, fallbackData, t]);

  const stats = useMemo(
    () => [
      { value: "24/7", label: t("landing.stats.availability") },
      { value: "1", label: t("landing.stats.workspace") },
      { value: "360", label: t("landing.stats.visibility") },
    ],
    [t],
  );

  const footerLinks = useMemo(
    () => [
      { label: t("landing.footer.links.home"), path: "/" },
      { label: t("landing.footer.links.register"), path: data.primaryButtonUrl || "/register" },
      { label: isAuthenticated ? t("landing.footer.links.dashboard") : t("landing.footer.links.login"), path: isAuthenticated ? "/dashboard" : (data.secondaryButtonUrl || "/login") },
    ],
    [data.primaryButtonUrl, data.secondaryButtonUrl, isAuthenticated, t],
  );

  const navigateTo = (target?: string) => {
    if (!target) {
      return;
    }

    if (/^https?:\/\//i.test(target)) {
      window.open(target, "_blank", "noopener,noreferrer");
      return;
    }

    router.push(target);
  };

  const changeLanguage = (nextLanguage: "ar" | "en") => {
    if (nextLanguage === currentLanguage) {
      return;
    }

    try {
      localStorage.setItem("i18nextLng", nextLanguage);
    } catch {}

    void i18n.changeLanguage(nextLanguage);
  };

  return (
    <Box
      dir={isRTL ? "rtl" : "ltr"}
      sx={{
        minHeight: "100vh",
        background:
          "radial-gradient(circle at top, rgba(21,93,117,0.22) 0%, rgba(21,93,117,0) 34%), linear-gradient(180deg, #f3f8fb 0%, #ffffff 42%, #edf3f7 100%)",
      }}
    >
      <Box
        sx={{
          position: "sticky",
          top: 0,
          zIndex: 10,
          backdropFilter: "blur(18px)",
          backgroundColor: alpha("#ffffff", 0.84),
          borderBottom: "1px solid",
          borderColor: alpha(theme.palette.primary.main, 0.12),
        }}
      >
        <Container maxWidth="lg">
          <Box
            sx={{
              py: 2,
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              gap: 2,
              flexWrap: "wrap",
            }}
          >
            <Stack direction="row" spacing={1.5} alignItems="center">
              <Box
                sx={{
                  width: 44,
                  height: 44,
                  borderRadius: 3,
                  display: "grid",
                  placeItems: "center",
                  color: "common.white",
                  background: "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)",
                  boxShadow: "0 12px 24px -16px rgba(18,58,99,0.65)",
                }}
              >
                <BalanceIcon />
              </Box>
              <Box>
                <Typography variant="h6" sx={{ fontWeight: 900, letterSpacing: "-0.03em" }}>
                  {data.systemName || t("app.title")}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {data.tagline}
                </Typography>
              </Box>
            </Stack>

            <Stack direction="row" spacing={1} flexWrap="wrap" alignItems="center">
              <Stack
                direction="row"
                spacing={0.75}
                sx={{
                  p: 0.5,
                  borderRadius: 999,
                  bgcolor: alpha(theme.palette.primary.main, 0.06),
                }}
              >
                {(["ar", "en"] as const).map((languageCode) => (
                  <Button
                    key={languageCode}
                    size="small"
                    variant={currentLanguage === languageCode ? "contained" : "text"}
                    onClick={() => changeLanguage(languageCode)}
                    sx={{
                      minWidth: 52,
                      borderRadius: 999,
                      fontWeight: 800,
                      color: currentLanguage === languageCode ? "common.white" : "text.secondary",
                      background:
                        currentLanguage === languageCode
                          ? "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)"
                          : "transparent",
                    }}
                  >
                    {languageCode === "ar" ? t("landing.languages.ar") : t("landing.languages.en")}
                  </Button>
                ))}
              </Stack>
              {isAuthInitialized && isAuthenticated && (
                <Button variant="outlined" onClick={() => router.push("/dashboard")}>
                  {t("landing.actions.dashboard")}
                </Button>
              )}
              <Button variant="text" onClick={() => navigateTo(data.secondaryButtonUrl || "/login")}>
                {data.secondaryButtonText || t("landing.actions.login")}
              </Button>
              <Button
                variant="contained"
                endIcon={<ArrowOutwardIcon />}
                onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
                sx={{
                  background: "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)",
                  boxShadow: "0 14px 28px -18px rgba(18,58,99,0.7)",
                }}
              >
                {data.primaryButtonText || t("landing.actions.register")}
              </Button>
            </Stack>
          </Box>
        </Container>
      </Box>

      <Container maxWidth="lg" sx={{ py: { xs: 5, md: 8 } }}>
        {error && (
          <Alert severity="warning" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: { xs: "1fr", md: "minmax(0, 1.15fr) minmax(320px, 0.85fr)" },
            gap: 3,
            alignItems: "stretch",
            mb: 4,
          }}
        >
          <Paper
            elevation={0}
            sx={{
              p: { xs: 3, md: 5 },
              borderRadius: 6,
              minHeight: 420,
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
              color: "common.white",
              border: "1px solid",
              borderColor: alpha("#ffffff", 0.16),
              background:
                "linear-gradient(135deg, rgba(18,58,99,1) 0%, rgba(25,113,123,0.96) 58%, rgba(82,164,157,0.94) 100%)",
              boxShadow: "0 32px 64px -30px rgba(18,58,99,0.65)",
              position: "relative",
              overflow: "hidden",
              "&::after": {
                content: '""',
                position: "absolute",
                insetInlineEnd: -60,
                bottom: -70,
                width: 240,
                height: 240,
                borderRadius: "50%",
                background: "rgba(255,255,255,0.1)",
              },
            }}
          >
            <Box sx={{ position: "relative", zIndex: 1 }}>
              <Chip
                label={t("landing.badge")}
                sx={{
                  mb: 2,
                  color: "common.white",
                  backgroundColor: alpha("#ffffff", 0.14),
                  borderRadius: 999,
                }}
              />
              <Typography variant="h2" sx={{ fontWeight: 900, letterSpacing: "-0.05em", maxWidth: 720, mb: 2 }}>
                {data.heroTitle}
              </Typography>
              <Typography variant="h6" sx={{ maxWidth: 680, opacity: 0.9, lineHeight: 1.7 }}>
                {data.heroSubtitle}
              </Typography>
            </Box>

            <Stack
              direction={{ xs: "column", sm: "row" }}
              spacing={1.5}
              sx={{ mt: 4, position: "relative", zIndex: 1 }}
            >
              <Button
                size="large"
                variant="contained"
                endIcon={<ArrowOutwardIcon />}
                onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
                sx={{
                  px: 3.5,
                  py: 1.35,
                  color: "primary.dark",
                  backgroundColor: "common.white",
                  "&:hover": { backgroundColor: alpha("#ffffff", 0.92) },
                }}
              >
                {data.primaryButtonText || t("landing.actions.register")}
              </Button>
              <Button
                size="large"
                variant="outlined"
                onClick={() => navigateTo(data.secondaryButtonUrl || "/login")}
                sx={{
                  px: 3.5,
                  py: 1.35,
                  color: "common.white",
                  borderColor: alpha("#ffffff", 0.45),
                  "&:hover": {
                    borderColor: "common.white",
                    backgroundColor: alpha("#ffffff", 0.08),
                  },
                }}
              >
                {data.secondaryButtonText || t("landing.actions.login")}
              </Button>
            </Stack>
          </Paper>

          <Paper
            elevation={0}
            sx={{
              p: { xs: 3, md: 4 },
              borderRadius: 6,
              border: "1px solid",
              borderColor: alpha(theme.palette.primary.main, 0.12),
              background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(241,247,250,0.98) 100%)",
            }}
          >
            {loading ? (
              <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: 280 }}>
                <CircularProgress />
              </Box>
            ) : (
              <Stack spacing={2.5} sx={{ height: "100%", justifyContent: "space-between" }}>
                <Box>
                  <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
                    {t("landing.highlights")}
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 1.5 }}>
                    {data.aboutTitle}
                  </Typography>
                  <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.9 }}>
                    {data.aboutDescription}
                  </Typography>
                </Box>

                <Box
                  sx={{
                    display: "grid",
                    gridTemplateColumns: "repeat(3, minmax(0, 1fr))",
                    gap: 1.5,
                  }}
                >
                  {stats.map((item) => (
                    <Card
                      key={item.label}
                      elevation={0}
                      sx={{
                        borderRadius: 4,
                        border: "1px solid",
                        borderColor: "divider",
                        backgroundColor: alpha(theme.palette.primary.light, 0.06),
                      }}
                    >
                      <CardContent sx={{ p: 2.25 }}>
                        <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em" }}>
                          {item.value}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {item.label}
                        </Typography>
                      </CardContent>
                    </Card>
                  ))}
                </Box>
              </Stack>
            )}
          </Paper>
        </Box>

        <Box sx={{ mb: 4 }}>
          <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
            {t("landing.featuresTitle")}
          </Typography>
          <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 2.5 }}>
            {t("landing.featuresSubtitle")}
          </Typography>

          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "repeat(3, minmax(0, 1fr))" },
              gap: 2,
            }}
          >
            {(data.features || []).map((feature, index) => (
              <Card
                key={`${feature.title}-${index}`}
                elevation={0}
                sx={{
                  height: "100%",
                  borderRadius: 5,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                }}
              >
                <CardContent sx={{ p: 3.25 }}>
                  <Box
                    sx={{
                      width: 56,
                      height: 56,
                      display: "grid",
                      placeItems: "center",
                      borderRadius: 4,
                      mb: 2,
                      color: "primary.main",
                      backgroundColor: alpha(theme.palette.primary.main, 0.1),
                    }}
                  >
                    {getFeatureIcon(feature.iconKey)}
                  </Box>
                  <Typography variant="h6" sx={{ fontWeight: 800, mb: 1 }}>
                    {feature.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ lineHeight: 1.9 }}>
                    {feature.description}
                  </Typography>
                </CardContent>
              </Card>
            ))}
          </Box>
        </Box>

        <Paper
          elevation={0}
          sx={{
            p: { xs: 3, md: 4 },
            borderRadius: 6,
            border: "1px solid",
            borderColor: alpha(theme.palette.primary.main, 0.12),
            background: "linear-gradient(135deg, rgba(18,58,99,0.04) 0%, rgba(28,123,130,0.08) 100%)",
            mb: 4,
          }}
        >
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "minmax(0, 1.2fr) minmax(280px, 0.8fr)" },
              gap: 3,
              alignItems: "center",
            }}
          >
            <Box>
              <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 1 }}>
                {t("landing.contactTitle")}
              </Typography>
              <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.9 }}>
                {t("landing.contactSubtitle")}
              </Typography>
            </Box>

            <Stack spacing={1.25}>
              <Chip label={`${t("landing.contact.email")}: ${data.contactEmail || "-"}`} sx={{ justifyContent: "flex-start" }} />
              <Chip label={`${t("landing.contact.phone")}: ${data.contactPhone || "-"}`} sx={{ justifyContent: "flex-start" }} />
            </Stack>
          </Box>
        </Paper>
      </Container>

      <Box
        component="footer"
        sx={{
          borderTop: "1px solid",
          borderColor: alpha(theme.palette.primary.main, 0.12),
          background: "linear-gradient(180deg, rgba(14,43,73,1) 0%, rgba(18,58,99,1) 100%)",
          color: "common.white",
          py: 5,
        }}
      >
        <Container maxWidth="lg">
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "minmax(0, 1.2fr) repeat(2, minmax(220px, 0.4fr))" },
              gap: 3,
            }}
          >
            <Box>
              <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 1.5 }}>
                <Box
                  sx={{
                    width: 40,
                    height: 40,
                    borderRadius: 3,
                    display: "grid",
                    placeItems: "center",
                    color: "common.white",
                    backgroundColor: alpha("#ffffff", 0.12),
                  }}
                >
                  <BalanceIcon />
                </Box>
                <Typography variant="h6" sx={{ fontWeight: 900 }}>
                  {data.systemName}
                </Typography>
              </Stack>
              <Typography variant="body2" sx={{ opacity: 0.82, maxWidth: 560, lineHeight: 1.9 }}>
                {data.tagline}
              </Typography>
            </Box>

            <Box>
              <Typography variant="subtitle1" sx={{ fontWeight: 800, mb: 1.5 }}>
                {t("landing.footer.navigation")}
              </Typography>
              <Stack spacing={1}>
                {footerLinks.map((item) => (
                  <Link
                    key={item.label}
                    component="button"
                    onClick={() => navigateTo(item.path)}
                    underline="hover"
                    color="inherit"
                    sx={{ textAlign: "start", opacity: 0.86 }}
                  >
                    {item.label}
                  </Link>
                ))}
              </Stack>
            </Box>

            <Box>
              <Typography variant="subtitle1" sx={{ fontWeight: 800, mb: 1.5 }}>
                {t("landing.footer.contact")}
              </Typography>
              <Stack spacing={1}>
                <Typography variant="body2" sx={{ opacity: 0.86 }}>
                  {t("landing.contact.email")}: {data.contactEmail || "-"}
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.86 }}>
                  {t("landing.contact.phone")}: {data.contactPhone || "-"}
                </Typography>
              </Stack>
            </Box>
          </Box>

          <Typography
            variant="caption"
            sx={{
              display: "block",
              mt: 4,
              pt: 2,
              borderTop: "1px solid",
              borderColor: alpha("#ffffff", 0.14),
              opacity: 0.72,
              textAlign: "center",
            }}
          >
            {t("landing.footer.copyright", { year: new Date().getFullYear(), systemName: data.systemName })}
          </Typography>
        </Container>
      </Box>
    </Box>
  );
}
