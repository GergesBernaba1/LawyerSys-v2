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
import { Call as CallIcon, Email as EmailIcon, Place as PlaceIcon, Schedule as ScheduleIcon } from "@mui/icons-material";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";
import PublicSiteShell from "../../src/components/public/PublicSiteShell";
import { buildLandingData, getDefaultLandingPage, getRequestLanguage, type LandingPageData } from "../../src/services/publicSite";

export default function ContactUsPage() {
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

  const contactCards = [
    {
      key: "email",
      icon: <EmailIcon color="primary" />,
      title: t("landing.contact.email"),
      value: data.contactEmail,
      actionLabel: t("landing.contactPage.emailAction"),
      actionHref: `mailto:${data.contactEmail}`,
    },
    {
      key: "phone",
      icon: <CallIcon color="primary" />,
      title: t("landing.contact.phone"),
      value: data.contactPhone,
      actionLabel: t("landing.contactPage.phoneAction"),
      actionHref: `tel:${data.contactPhone}`,
    },
    {
      key: "address",
      icon: <PlaceIcon color="primary" />,
      title: t("landing.contact.address"),
      value: data.contactAddress,
      actionLabel: t("landing.contactPage.addressAction"),
      actionHref: undefined,
    },
    {
      key: "hours",
      icon: <ScheduleIcon color="primary" />,
      title: t("landing.contact.workingHours"),
      value: data.contactWorkingHours,
      actionLabel: "",
      actionHref: undefined,
    },
  ];

  return (
    <PublicSiteShell
      data={data}
      currentLanguage={currentLanguage}
      onChangeLanguage={changeLanguage}
      onNavigate={navigateTo}
      isAuthenticated={isAuthenticated}
      isAuthInitialized={isAuthInitialized}
    >
      <Container maxWidth="lg" sx={{ py: { xs: 5, md: 8 }, animation: "fade-in-up 0.45s ease-out" }}>
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
                borderRadius: 7,
                border: "1px solid",
                borderColor: alpha(theme.palette.primary.main, 0.12),
                background: "linear-gradient(135deg, rgba(18,58,99,1) 0%, rgba(25,113,123,0.96) 100%)",
                color: "common.white",
              }}
            >
              <Typography variant="overline" sx={{ opacity: 0.82, letterSpacing: "0.18em", fontWeight: 800 }}>
                {t("landing.footer.links.contactUs")}
              </Typography>
              <Typography variant="h2" sx={{ fontWeight: 900, letterSpacing: "-0.05em", mt: 1, mb: 2 }}>
                {data.contactPageTitle}
              </Typography>
              <Typography variant="h6" sx={{ lineHeight: 1.8, maxWidth: 880, opacity: 0.92, mb: 1.5 }}>
                {data.contactPageSubtitle}
              </Typography>
              <Typography variant="body1" sx={{ lineHeight: 2, maxWidth: 900, opacity: 0.84 }}>
                {data.contactPageDescription}
              </Typography>
            </Paper>

            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: { xs: "1fr", md: "repeat(2, minmax(0, 1fr))" },
                gap: 2,
                mb: 3,
              }}
            >
              {contactCards.map((card) => (
                <Card
                  key={card.key}
                  elevation={0}
                  sx={{
                    borderRadius: 6,
                    border: "1px solid",
                    borderColor: alpha(theme.palette.primary.main, 0.12),
                    background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                  }}
                >
                  <CardContent sx={{ p: 3.5 }}>
                    <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 1.5 }}>
                      {card.icon}
                      <Typography variant="h6" sx={{ fontWeight: 800 }}>
                        {card.title}
                      </Typography>
                    </Stack>
                    <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.9, minHeight: 56 }}>
                      {card.value || "-"}
                    </Typography>
                    {card.actionHref && (
                      <Button component="a" href={card.actionHref} variant="outlined" sx={{ mt: 2 }}>
                        {card.actionLabel}
                      </Button>
                    )}
                  </CardContent>
                </Card>
              ))}
            </Box>

            <Paper
              elevation={0}
              sx={{
                p: { xs: 3, md: 4 },
                borderRadius: 6,
                border: "1px solid",
                borderColor: alpha(theme.palette.primary.main, 0.12),
              }}
            >
              <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.03em", mb: 1.5 }}>
                {t("landing.contactPage.ctaTitle")}
              </Typography>
              <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.9, mb: 2.5 }}>
                {t("landing.contactPage.ctaSubtitle")}
              </Typography>
              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5}>
                <Button
                  variant="contained"
                  sx={{ background: "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)" }}
                  onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
                >
                  {data.primaryButtonText || t("landing.actions.register")}
                </Button>
                <Button variant="outlined" onClick={() => navigateTo("/about-us")}>
                  {t("landing.contactPage.learnMoreAction")}
                </Button>
              </Stack>
            </Paper>
          </>
        )}
      </Container>
    </PublicSiteShell>
  );
}
