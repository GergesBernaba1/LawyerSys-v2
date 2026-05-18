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
  alpha,
} from "@mui/material";
import {
  ArrowOutward as ArrowOutwardIcon,
  AutoAwesome as AutoAwesomeIcon,
  Check as CheckIcon,
  EmojiObjects as EmojiObjectsIcon,
  GpsFixed as GpsFixedIcon,
  Mail as MailIcon,
  Phone as PhoneIcon,
  Place as PlaceIcon,
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

// ─── shared dark-card style (same as landing page) ───────────────────────────
const darkCard = {
  background: "rgba(255,255,255,0.04)",
  border: "1px solid rgba(255,255,255,0.08)",
  backdropFilter: "blur(8px)",
};

const tealGradient = "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)";

export default function AboutUsPage() {
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
                label={t("landing.footer.links.aboutUs")}
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
                  mb: 2.5,
                }}
              >
                {data.aboutPageTitle}
              </Typography>
              <Typography
                variant="h6"
                sx={{
                  color: "rgba(255,255,255,0.6)",
                  lineHeight: 1.8,
                  fontWeight: 400,
                  fontSize: { xs: "1rem", md: "1.15rem" },
                  maxWidth: 680,
                  mx: "auto",
                  mb: 4,
                }}
              >
                {data.aboutPageSubtitle}
              </Typography>
              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} justifyContent="center">
                <Button
                  variant="contained"
                  endIcon={<ArrowOutwardIcon />}
                  onClick={() => navigateTo("/contact-us")}
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
                  {t("landing.aboutPage.contactAction", { defaultValue: "تواصل معنا" })}
                </Button>
                <Button
                  variant="outlined"
                  onClick={() => navigateTo("/")}
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
                  {t("landing.footer.links.home")}
                </Button>
              </Stack>
            </Container>
          </Box>

          {/* ── ABOUT DESCRIPTION + CONTACT CARD ─────────────────────── */}
          <Box sx={{ pb: { xs: 7, md: 10 }, borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
            <Container maxWidth="lg">
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", md: "minmax(0,1.2fr) minmax(300px,0.8fr)" },
                  gap: 3,
                }}
              >
                {/* About text */}
                <Box
                  sx={{
                    p: { xs: 2.5, md: 3 },
                    borderRadius: 4,
                    ...darkCard,
                    transition: "border-color 0.2s",
                    "&:hover": { borderColor: "rgba(28,123,130,0.25)" },
                  }}
                >
                  <Typography
                    variant="overline"
                    sx={{ color: "#14c8d4", fontWeight: 800, letterSpacing: "0.2em", display: "block", mb: 1.5 }}
                  >
                    {t("landing.aboutPage.aboutLabel", { defaultValue: "من نحن" })}
                  </Typography>
                  <Typography
                    variant="h4"
                    sx={{ fontWeight: 900, letterSpacing: "-0.04em", color: "common.white", mb: 2, fontSize: { xs: "1.5rem", md: "1.9rem" } }}
                  >
                    {data.aboutTitle}
                  </Typography>
                  <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.55)", lineHeight: 2 }}>
                    {data.aboutPageDescription}
                  </Typography>
                </Box>

                {/* Contact info card */}
                <Box
                  sx={{
                    p: { xs: 2.5, md: 3 },
                    borderRadius: 4,
                    background: "linear-gradient(160deg, rgba(12,40,78,1) 0%, rgba(14,80,90,0.98) 100%)",
                    border: "1px solid rgba(28,123,130,0.25)",
                    boxShadow: "0 28px 56px -20px rgba(28,123,130,0.25)",
                    display: "flex",
                    flexDirection: "column",
                    gap: 2,
                  }}
                >
                  <Box>
                    <Typography
                      variant="overline"
                      sx={{ color: "#14c8d4", fontWeight: 800, letterSpacing: "0.18em", display: "block", mb: 1 }}
                    >
                      {t("landing.aboutPage.contactCardLabel", { defaultValue: "تواصل معنا" })}
                    </Typography>
                    <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.03em", color: "common.white", mb: 0.5 }}>
                      {data.systemName}
                    </Typography>
                    <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.45)", lineHeight: 1.7 }}>
                      {data.tagline}
                    </Typography>
                  </Box>

                  <Stack spacing={1.5}>
                    {[
                      { icon: <MailIcon sx={{ fontSize: 16 }} />, label: t("landing.contact.email"), value: data.contactEmail },
                      { icon: <PhoneIcon sx={{ fontSize: 16 }} />, label: t("landing.contact.phone"), value: data.contactPhone },
                      { icon: <PlaceIcon sx={{ fontSize: 16 }} />, label: t("landing.contact.address"), value: data.contactAddress },
                    ].map((item) => (
                      <Stack key={item.label} direction="row" spacing={1.25} alignItems="flex-start">
                        <Box
                          sx={{
                            width: 28,
                            height: 28,
                            borderRadius: 1.5,
                            display: "grid",
                            placeItems: "center",
                            bgcolor: "rgba(28,123,130,0.2)",
                            color: "#14c8d4",
                            flexShrink: 0,
                            mt: 0.1,
                          }}
                        >
                          {item.icon}
                        </Box>
                        <Box>
                          <Typography variant="caption" sx={{ color: "rgba(255,255,255,0.35)", display: "block" }}>
                            {item.label}
                          </Typography>
                          <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.75)", fontWeight: 600 }}>
                            {item.value || "-"}
                          </Typography>
                        </Box>
                      </Stack>
                    ))}
                  </Stack>

                  <Button
                    variant="contained"
                    endIcon={<ArrowOutwardIcon />}
                    onClick={() => navigateTo("/contact-us")}
                    sx={{
                      borderRadius: 999,
                      fontWeight: 800,
                      background: tealGradient,
                      boxShadow: "0 10px 24px -8px rgba(28,123,130,0.5)",
                      "&:hover": { background: "linear-gradient(135deg, #0f3358 0%, #187479 100%)" },
                    }}
                  >
                    {t("landing.aboutPage.contactAction", { defaultValue: "تواصل معنا" })}
                  </Button>
                </Box>
              </Box>
            </Container>
          </Box>

          {/* ── MISSION & VISION ──────────────────────────────────────── */}
          <Box
            sx={{
              py: { xs: 7, md: 10 },
              background:
                "radial-gradient(ellipse 100% 50% at 50% 100%, rgba(18,58,99,0.18) 0%, transparent 70%)",
            }}
          >
            <Container maxWidth="lg">
              <Box sx={{ textAlign: "center", mb: 6 }}>
                <Typography
                  variant="overline"
                  sx={{ color: "#14c8d4", fontWeight: 800, letterSpacing: "0.2em", display: "block", mb: 1 }}
                >
                  {t("landing.aboutPage.valuesLabel", { defaultValue: "قيمنا ورؤيتنا" })}
                </Typography>
                <Typography
                  variant="h4"
                  sx={{
                    fontWeight: 900,
                    letterSpacing: "-0.04em",
                    color: "common.white",
                    lineHeight: 1.22,
                    fontSize: { xs: "1.55rem", md: "2rem" },
                  }}
                >
                  {t("landing.aboutPage.valuesSectionTitle", { defaultValue: "ما الذي يُحرّكنا كل يوم" })}
                </Typography>
              </Box>

              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", md: "repeat(2,1fr)" },
                  gap: 2.5,
                }}
              >
                {/* Mission */}
                <Box
                  sx={{
                    p: { xs: 2.5, md: 3 },
                    borderRadius: 4,
                    ...darkCard,
                    transition: "all 0.25s",
                    "&:hover": { borderColor: "rgba(20,200,212,0.25)", bgcolor: "rgba(20,200,212,0.04)", transform: "translateY(-4px)" },
                  }}
                >
                  <Box
                    sx={{
                      width: 44,
                      height: 44,
                      borderRadius: 2.5,
                      display: "grid",
                      placeItems: "center",
                      bgcolor: "rgba(20,200,212,0.12)",
                      border: "1px solid rgba(20,200,212,0.22)",
                      color: "#14c8d4",
                      mb: 2,
                    }}
                  >
                    <GpsFixedIcon sx={{ fontSize: 26 }} />
                  </Box>
                  <Typography
                    variant="overline"
                    sx={{ color: "#14c8d4", fontWeight: 800, letterSpacing: "0.18em", display: "block", mb: 1 }}
                  >
                    {t("landing.aboutPage.missionBadge", { defaultValue: "رسالتنا" })}
                  </Typography>
                  <Typography
                    variant="h5"
                    sx={{ fontWeight: 900, letterSpacing: "-0.03em", color: "common.white", mb: 1.5, fontSize: { xs: "1.2rem", md: "1.4rem" } }}
                  >
                    {data.aboutPageMissionTitle}
                  </Typography>
                  <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.52)", lineHeight: 1.9 }}>
                    {data.aboutPageMissionDescription}
                  </Typography>
                </Box>

                {/* Vision */}
                <Box
                  sx={{
                    p: { xs: 2.5, md: 3 },
                    borderRadius: 4,
                    ...darkCard,
                    transition: "all 0.25s",
                    "&:hover": { borderColor: "rgba(167,139,250,0.25)", bgcolor: "rgba(167,139,250,0.04)", transform: "translateY(-4px)" },
                  }}
                >
                  <Box
                    sx={{
                      width: 44,
                      height: 44,
                      borderRadius: 2.5,
                      display: "grid",
                      placeItems: "center",
                      bgcolor: "rgba(167,139,250,0.12)",
                      border: "1px solid rgba(167,139,250,0.22)",
                      color: "#a78bfa",
                      mb: 2,
                    }}
                  >
                    <EmojiObjectsIcon sx={{ fontSize: 26 }} />
                  </Box>
                  <Typography
                    variant="overline"
                    sx={{ color: "#a78bfa", fontWeight: 800, letterSpacing: "0.18em", display: "block", mb: 1 }}
                  >
                    {t("landing.aboutPage.visionBadge", { defaultValue: "رؤيتنا" })}
                  </Typography>
                  <Typography
                    variant="h5"
                    sx={{ fontWeight: 900, letterSpacing: "-0.03em", color: "common.white", mb: 1.5, fontSize: { xs: "1.2rem", md: "1.4rem" } }}
                  >
                    {data.aboutPageVisionTitle}
                  </Typography>
                  <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.52)", lineHeight: 1.9 }}>
                    {data.aboutPageVisionDescription}
                  </Typography>
                </Box>
              </Box>
            </Container>
          </Box>

          {/* ── BOTTOM CTA ────────────────────────────────────────────── */}
          <Box
            sx={{
              py: { xs: 8, md: 10 },
              textAlign: "center",
              borderTop: "1px solid rgba(255,255,255,0.05)",
              position: "relative",
              overflow: "hidden",
              "&::before": {
                content: '""',
                position: "absolute",
                inset: 0,
                background: "radial-gradient(ellipse 60% 70% at 50% 100%, rgba(28,123,130,0.14) 0%, transparent 70%)",
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
                  onClick={() => navigateTo("/contact-us")}
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
                  {t("landing.footer.links.contactUs")}
                </Button>
              </Stack>
            </Container>
          </Box>
        </>
      )}
    </PublicSiteShell>
  );
}
