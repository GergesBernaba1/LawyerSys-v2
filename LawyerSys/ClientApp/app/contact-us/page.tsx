"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
import {
  Alert,
  Box,
  Button,
  Chip,
  CircularProgress,
  Container,
  Stack,
  Typography,
} from "@mui/material";
import {
  ArrowOutward as ArrowOutwardIcon,
  AutoAwesome as AutoAwesomeIcon,
  Call as CallIcon,
  Email as EmailIcon,
  Place as PlaceIcon,
  Schedule as ScheduleIcon,
} from "@mui/icons-material";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";
import PublicSiteShell from "../../src/components/public/PublicSiteShell";
import {
  buildLandingData,
  getDefaultLandingPage,
  getRequestLanguage,
  type LandingPageData,
} from "../../src/services/publicSite";

// ─── shared tokens (same as landing / about-us) ──────────────────────────────
const darkCard = {
  background: "rgba(255,255,255,0.04)",
  border: "1px solid rgba(255,255,255,0.08)",
  backdropFilter: "blur(8px)",
};

const tealGradient = "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)";

export default function ContactUsPage() {
  const router = useRouter();
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
          headers: { "Accept-Language": getRequestLanguage(currentLanguage) },
        } as any);
        if (mounted) {
          const apiBuilt = buildLandingData(response.data, fallbackData);
          setData({
            ...fallbackData,
            primaryButtonUrl:    apiBuilt.primaryButtonUrl    || fallbackData.primaryButtonUrl,
            secondaryButtonUrl:  apiBuilt.secondaryButtonUrl  || fallbackData.secondaryButtonUrl,
            contactEmail:        apiBuilt.contactEmail        || fallbackData.contactEmail,
            contactPhone:        apiBuilt.contactPhone        || fallbackData.contactPhone,
            contactAddress:      apiBuilt.contactAddress      || fallbackData.contactAddress,
            contactWorkingHours: apiBuilt.contactWorkingHours || fallbackData.contactWorkingHours,
          });
          setError("");
        }
      } catch {
        if (mounted) {
          setData(fallbackData);
          setError(t("landing.failedLoad"));
        }
      } finally {
        if (mounted) setLoading(false);
      }
    })();
    return () => { mounted = false; };
  }, [currentLanguage, fallbackData, t]);

  const navigateTo = (target?: string) => {
    if (!target) return;
    if (/^https?:\/\//i.test(target)) { window.open(target, "_blank", "noopener,noreferrer"); return; }
    router.push(target);
  };

  const changeLanguage = (nextLanguage: "ar" | "en") => {
    if (nextLanguage === currentLanguage) return;
    try { localStorage.setItem("i18nextLng", nextLanguage); } catch {}
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
      darkMode
    >
      {error && (
        <Container maxWidth="lg" sx={{ pt: 2 }}>
          <Alert severity="warning">{error}</Alert>
        </Container>
      )}

      {loading ? (
        <Box sx={{ display: "flex", justifyContent: "center", py: 16 }}>
          <CircularProgress sx={{ color: "#1c7b82" }} />
        </Box>
      ) : (
        <>
          {/* ── HERO ──────────────────────────────────────────────────── */}
          <Box
            sx={{
              pt: { xs: 8, md: 12 },
              pb: { xs: 7, md: 10 },
              position: "relative",
              overflow: "hidden",
              "&::before": {
                content: '""',
                position: "absolute",
                inset: 0,
                background:
                  "radial-gradient(ellipse 80% 60% at 50% -10%, rgba(28,123,130,0.18) 0%, transparent 70%)",
                pointerEvents: "none",
              },
            }}
          >
            {/* Background blobs */}
            <Box sx={{ position: "absolute", top: 40, insetInlineStart: "4%", width: 280, height: 280, borderRadius: "50%", background: "rgba(18,58,99,0.15)", filter: "blur(55px)", pointerEvents: "none" }} />
            <Box sx={{ position: "absolute", top: 100, insetInlineEnd: "6%", width: 220, height: 220, borderRadius: "50%", background: "rgba(28,123,130,0.1)", filter: "blur(45px)", pointerEvents: "none" }} />

            <Container maxWidth="lg" sx={{ position: "relative", zIndex: 1, textAlign: "center" }}>
              <Chip
                label={t("landing.footer.links.contactUs")}
                sx={{
                  mb: 3,
                  color: "#14c8d4",
                  bgcolor: "rgba(28,123,130,0.12)",
                  border: "1px solid rgba(28,123,130,0.3)",
                  fontWeight: 800,
                  borderRadius: 999,
                }}
              />
              <Typography
                variant="h1"
                sx={{
                  fontWeight: 900,
                  color: "common.white",
                  letterSpacing: "-0.04em",
                  lineHeight: 1.12,
                  fontSize: { xs: "2.2rem", sm: "3rem", md: "3.8rem" },
                  mb: 2,
                }}
              >
                {data.contactPageTitle}
              </Typography>
              <Typography
                variant="h6"
                sx={{
                  color: "rgba(255,255,255,0.6)",
                  lineHeight: 1.8,
                  fontWeight: 400,
                  fontSize: { xs: "1rem", md: "1.15rem" },
                  maxWidth: 640,
                  mx: "auto",
                  mb: 1.5,
                }}
              >
                {data.contactPageSubtitle}
              </Typography>
              {data.contactPageDescription && (
                <Typography
                  variant="body1"
                  sx={{
                    color: "rgba(255,255,255,0.42)",
                    lineHeight: 1.85,
                    maxWidth: 600,
                    mx: "auto",
                  }}
                >
                  {data.contactPageDescription}
                </Typography>
              )}
            </Container>
          </Box>

          {/* ── CONTACT CARDS ─────────────────────────────────────────── */}
          <Box sx={{ pb: { xs: 7, md: 10 }, borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
            <Container maxWidth="lg">
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", sm: "repeat(2,1fr)" },
                  gap: 1.75,
                  alignItems: "start",
                }}
              >
                {[
                  {
                    key: "email",
                    icon: <EmailIcon sx={{ fontSize: 20 }} />,
                    color: "#14c8d4",
                    title: t("landing.contact.email"),
                    value: data.contactEmail,
                    actionLabel: t("landing.contactPage.emailAction", { defaultValue: "مراسلتنا" }),
                    actionHref: data.contactEmail ? `mailto:${data.contactEmail}` : undefined,
                  },
                  {
                    key: "phone",
                    icon: <CallIcon sx={{ fontSize: 20 }} />,
                    color: "#10b981",
                    title: t("landing.contact.phone"),
                    value: data.contactPhone,
                    actionLabel: t("landing.contactPage.phoneAction", { defaultValue: "اتصل بنا" }),
                    actionHref: data.contactPhone ? `tel:${data.contactPhone}` : undefined,
                  },
                  {
                    key: "address",
                    icon: <PlaceIcon sx={{ fontSize: 20 }} />,
                    color: "#f59e0b",
                    title: t("landing.contact.address"),
                    value: data.contactAddress,
                    actionLabel: t("landing.contactPage.addressAction", { defaultValue: "عرض على الخريطة" }),
                    actionHref: undefined,
                  },
                  {
                    key: "hours",
                    icon: <ScheduleIcon sx={{ fontSize: 20 }} />,
                    color: "#a78bfa",
                    title: t("landing.contact.workingHours"),
                    value: data.contactWorkingHours,
                    actionLabel: "",
                    actionHref: undefined,
                  },
                ].map((card) => (
                  <Box
                    key={card.key}
                    sx={{
                      p: { xs: 1.75, md: 2 },
                      borderRadius: 3,
                      ...darkCard,
                      display: "flex",
                      gap: 1.5,
                      alignItems: "flex-start",
                      transition: "all 0.22s",
                      "&:hover": {
                        borderColor: `${card.color}35`,
                        bgcolor: `${card.color}06`,
                        transform: "translateY(-2px)",
                      },
                    }}
                  >
                    {/* Icon */}
                    <Box
                      sx={{
                        width: 40,
                        height: 40,
                        borderRadius: 2,
                        display: "grid",
                        placeItems: "center",
                        bgcolor: `${card.color}18`,
                        border: `1px solid ${card.color}28`,
                        color: card.color,
                        flexShrink: 0,
                        mt: 0.25,
                      }}
                    >
                      {card.icon}
                    </Box>

                    {/* Text + action */}
                    <Box sx={{ minWidth: 0, flex: 1 }}>
                      <Typography
                        variant="caption"
                        sx={{ color: card.color, fontWeight: 800, letterSpacing: "0.14em", display: "block", mb: 0.4, textTransform: "uppercase" }}
                      >
                        {card.title}
                      </Typography>
                      <Typography
                        variant="subtitle1"
                        sx={{ color: "rgba(255,255,255,0.9)", fontWeight: 700, lineHeight: 1.5, wordBreak: "break-word" }}
                      >
                        {card.value || "-"}
                      </Typography>
                      {card.actionHref && (
                        <Button
                          component="a"
                          href={card.actionHref}
                          variant="outlined"
                          size="small"
                          sx={{
                            mt: 1,
                            borderRadius: 999,
                            fontWeight: 700,
                            fontSize: "0.75rem",
                            px: 1.5,
                            py: 0.3,
                            borderColor: `${card.color}40`,
                            color: card.color,
                            "&:hover": { borderColor: `${card.color}80`, bgcolor: `${card.color}10` },
                          }}
                        >
                          {card.actionLabel}
                        </Button>
                      )}
                    </Box>
                  </Box>
                ))}
              </Box>
            </Container>
          </Box>

          {/* ── CTA BAND ──────────────────────────────────────────────── */}
          <Box
            sx={{
              py: { xs: 7, md: 10 },
              background:
                "linear-gradient(135deg, rgba(12,36,68,0.55) 0%, rgba(14,70,80,0.45) 100%)",
              borderBottom: "1px solid rgba(255,255,255,0.05)",
            }}
          >
            <Container maxWidth="lg">
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", md: "minmax(0,1fr) auto" },
                  gap: 3,
                  alignItems: "center",
                  p: { xs: 2.5, md: 3 },
                  borderRadius: 4,
                  border: "1px solid rgba(28,123,130,0.2)",
                  background: "linear-gradient(135deg, rgba(8,24,52,0.9) 0%, rgba(10,60,68,0.85) 100%)",
                  boxShadow: "0 32px 64px -24px rgba(0,0,0,0.45)",
                }}
              >
                <Box>
                  <Typography
                    variant="overline"
                    sx={{ color: "#14c8d4", fontWeight: 800, letterSpacing: "0.2em", display: "block", mb: 1 }}
                  >
                    {t("landing.contactPage.ctaBadge", { defaultValue: "ابدأ اليوم" })}
                  </Typography>
                  <Typography
                    variant="h4"
                    sx={{
                      fontWeight: 900,
                      color: "common.white",
                      letterSpacing: "-0.04em",
                      mb: 1,
                      fontSize: { xs: "1.4rem", md: "1.9rem" },
                    }}
                  >
                    {t("landing.contactPage.ctaTitle", { defaultValue: "هل أنت مستعد للبدء؟" })}
                  </Typography>
                  <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.5)", lineHeight: 1.8 }}>
                    {t("landing.contactPage.ctaSubtitle", { defaultValue: "سجّل مجاناً وابدأ إدارة قضاياك بكفاءة من اليوم الأول." })}
                  </Typography>
                </Box>
                <Stack direction={{ xs: "row", md: "column", lg: "row" }} spacing={1.5} flexShrink={0} flexWrap="wrap">
                  <Button
                    variant="contained"
                    endIcon={<ArrowOutwardIcon />}
                    onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
                    sx={{
                      px: 3,
                      py: 1.1,
                      borderRadius: 999,
                      fontWeight: 800,
                      whiteSpace: "nowrap",
                      background: tealGradient,
                      boxShadow: "0 12px 28px -8px rgba(28,123,130,0.55)",
                      "&:hover": { background: "linear-gradient(135deg, #0f3358 0%, #187479 100%)" },
                    }}
                  >
                    {data.primaryButtonText || t("landing.actions.register")}
                  </Button>
                  <Button
                    variant="outlined"
                    onClick={() => navigateTo("/about-us")}
                    sx={{
                      px: 3,
                      py: 1.1,
                      borderRadius: 999,
                      fontWeight: 800,
                      whiteSpace: "nowrap",
                      color: "rgba(255,255,255,0.8)",
                      borderColor: "rgba(255,255,255,0.2)",
                      "&:hover": { borderColor: "rgba(255,255,255,0.45)", bgcolor: "rgba(255,255,255,0.05)" },
                    }}
                  >
                    {t("landing.contactPage.learnMoreAction", { defaultValue: "تعرّف علينا أكثر" })}
                  </Button>
                </Stack>
              </Box>
            </Container>
          </Box>

          {/* ── BOTTOM CTA ────────────────────────────────────────────── */}
          <Box
            sx={{
              py: { xs: 8, md: 10 },
              textAlign: "center",
              position: "relative",
              overflow: "hidden",
              "&::before": {
                content: '""',
                position: "absolute",
                inset: 0,
                background:
                  "radial-gradient(ellipse 60% 70% at 50% 100%, rgba(28,123,130,0.14) 0%, transparent 70%)",
                pointerEvents: "none",
              },
            }}
          >
            <Container maxWidth="sm" sx={{ position: "relative", zIndex: 1 }}>
              <AutoAwesomeIcon sx={{ fontSize: 36, color: "#1c7b82", opacity: 0.6, mb: 2 }} />
              <Typography
                variant="h4"
                sx={{
                  fontWeight: 900,
                  color: "common.white",
                  letterSpacing: "-0.04em",
                  lineHeight: 1.2,
                  mb: 1.5,
                  fontSize: { xs: "1.5rem", md: "2rem" },
                }}
              >
                {t("landing.cta.title", { defaultValue: "جاهز للسيطرة على قضاياك؟" })}
              </Typography>
              <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.45)", mb: 3.5 }}>
                {t("landing.cta.subtitle", { defaultValue: "ابدأ تجربتك المجانية اليوم ولا تحتاج بطاقة ائتمانية." })}
              </Typography>
              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} justifyContent="center">
                <Button
                  variant="contained"
                  endIcon={<ArrowOutwardIcon />}
                  onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
                  sx={{
                    px: 3.5,
                    py: 1.2,
                    borderRadius: 999,
                    fontWeight: 800,
                    background: tealGradient,
                    boxShadow: "0 16px 36px -12px rgba(28,123,130,0.55)",
                    "&:hover": { background: "linear-gradient(135deg, #0f3358 0%, #187479 100%)" },
                  }}
                >
                  {t("landing.cta.startTrial", { defaultValue: "ابدأ التجربة مجاناً" })}
                </Button>
                <Button
                  variant="outlined"
                  onClick={() => navigateTo("/about-us")}
                  sx={{
                    px: 3.5,
                    py: 1.2,
                    borderRadius: 999,
                    fontWeight: 800,
                    color: "rgba(255,255,255,0.85)",
                    borderColor: "rgba(255,255,255,0.2)",
                    "&:hover": { borderColor: "rgba(255,255,255,0.45)", bgcolor: "rgba(255,255,255,0.05)" },
                  }}
                >
                  {t("landing.footer.links.aboutUs")}
                </Button>
              </Stack>
            </Container>
          </Box>
        </>
      )}
    </PublicSiteShell>
  );
}
