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
  CircularProgress,
  Container,
  Paper,
  Stack,
  Typography,
  alpha,
  useTheme,
} from "@mui/material";
import { ArrowOutward as ArrowOutwardIcon } from "@mui/icons-material";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";
import PublicSiteShell from "../../src/components/public/PublicSiteShell";
import { buildLandingData, getDefaultLandingPage, getRequestLanguage, type LandingPageData } from "../../src/services/publicSite";

export default function AboutUsPage() {
  const router = useRouter();
  const theme = useTheme();
  const { t, i18n } = useTranslation();
  const { isAuthenticated, isAuthInitialized } = useAuth();
  const currentLanguage = (i18n.resolvedLanguage || i18n.language || "ar").startsWith("ar") ? "ar" : "en";
  const fallbackData = useMemo(() => getDefaultLandingPage(t), [t]);
  const [data, setData] = useState<LandingPageData>(fallbackData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let mounted = true;

    (async () => {
      try {
        const response = await api.get("/LandingPage", {
          skipTenantHeader: true,
          headers: {
            "Accept-Language": getRequestLanguage(currentLanguage),
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
    <PublicSiteShell
      data={data}
      currentLanguage={currentLanguage}
      onChangeLanguage={changeLanguage}
      onNavigate={navigateTo}
      isAuthenticated={isAuthenticated}
      isAuthInitialized={isAuthInitialized}
    >
      <Container maxWidth="lg" sx={{ py: { xs: 5, md: 8 } }}>
        {error && (
          <Alert severity="warning" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        {loading ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 10 }}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            <Paper
              elevation={0}
              sx={{
                p: { xs: 3, md: 5 },
                mb: 3,
                borderRadius: 6,
                border: "1px solid",
                borderColor: alpha(theme.palette.primary.main, 0.12),
                background: "linear-gradient(135deg, rgba(18,58,99,1) 0%, rgba(25,113,123,0.96) 100%)",
                color: "common.white",
              }}
            >
              <Typography variant="overline" sx={{ opacity: 0.82, letterSpacing: "0.18em", fontWeight: 800 }}>
                {t("landing.footer.links.aboutUs")}
              </Typography>
              <Typography variant="h2" sx={{ fontWeight: 900, letterSpacing: "-0.05em", mt: 1, mb: 2 }}>
                {data.aboutPageTitle}
              </Typography>
              <Typography variant="h6" sx={{ lineHeight: 1.8, maxWidth: 880, opacity: 0.92 }}>
                {data.aboutPageSubtitle}
              </Typography>
            </Paper>

            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: { xs: "1fr", md: "minmax(0, 1.15fr) minmax(320px, 0.85fr)" },
                gap: 3,
                mb: 3,
              }}
            >
              <Paper
                elevation={0}
                sx={{
                  p: { xs: 3, md: 4 },
                  borderRadius: 5,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                }}
              >
                <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 2 }}>
                  {data.aboutTitle}
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 2 }}>
                  {data.aboutPageDescription}
                </Typography>
              </Paper>

              <Card
                elevation={0}
                sx={{
                  borderRadius: 5,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                }}
              >
                <CardContent sx={{ p: 3.5 }}>
                  <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.16em" }}>
                    {t("landing.aboutPage.contactCardLabel")}
                  </Typography>
                  <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.03em", mt: 1, mb: 1.5 }}>
                    {data.systemName}
                  </Typography>
                  <Stack spacing={1.25}>
                    <Typography variant="body2" color="text.secondary">
                      {t("landing.contact.email")}: {data.contactEmail}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {t("landing.contact.phone")}: {data.contactPhone}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {t("landing.contact.address")}: {data.contactAddress}
                    </Typography>
                  </Stack>
                  <Button
                    variant="contained"
                    endIcon={<ArrowOutwardIcon />}
                    sx={{ mt: 2.5, background: "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)" }}
                    onClick={() => navigateTo("/contact-us")}
                  >
                    {t("landing.aboutPage.contactAction")}
                  </Button>
                </CardContent>
              </Card>
            </Box>

            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: { xs: "1fr", md: "repeat(2, minmax(0, 1fr))" },
                gap: 3,
              }}
            >
              <Card
                elevation={0}
                sx={{
                  borderRadius: 5,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                }}
              >
                <CardContent sx={{ p: 3.5 }}>
                  <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.16em" }}>
                    {t("landing.aboutPage.missionBadge")}
                  </Typography>
                  <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.03em", mt: 1, mb: 1.5 }}>
                    {data.aboutPageMissionTitle}
                  </Typography>
                  <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 2 }}>
                    {data.aboutPageMissionDescription}
                  </Typography>
                </CardContent>
              </Card>

              <Card
                elevation={0}
                sx={{
                  borderRadius: 5,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                }}
              >
                <CardContent sx={{ p: 3.5 }}>
                  <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.16em" }}>
                    {t("landing.aboutPage.visionBadge")}
                  </Typography>
                  <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.03em", mt: 1, mb: 1.5 }}>
                    {data.aboutPageVisionTitle}
                  </Typography>
                  <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 2 }}>
                    {data.aboutPageVisionDescription}
                  </Typography>
                </CardContent>
              </Card>
            </Box>
          </>
        )}
      </Container>
    </PublicSiteShell>
  );
}
