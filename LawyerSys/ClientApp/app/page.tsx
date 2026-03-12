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
  Paper,
  Stack,
  TextField,
  Typography,
  alpha,
  useTheme,
} from "@mui/material";
import {
  AccountBalanceOutlined as AccountBalanceOutlinedIcon,
  ApartmentOutlined as ApartmentOutlinedIcon,
  ArrowBackIosNew as ArrowBackIosNewIcon,
  ArrowForwardIos as ArrowForwardIosIcon,
  ArrowOutward as ArrowOutwardIcon,
  AutoAwesome as AutoAwesomeIcon,
  BusinessOutlined as BusinessOutlinedIcon,
  Bolt as BoltIcon,
  Insights as InsightsIcon,
  Security as SecurityIcon,
} from "@mui/icons-material";
import api from "../src/services/api";
import { useAuth } from "../src/services/auth";
import PublicSiteShell from "../src/components/public/PublicSiteShell";
import {
  buildLandingData,
  getDefaultLandingPage,
  getRequestLanguage,
  type LandingFeature,
  type LandingPageData,
} from "../src/services/publicSite";

type PricingOption = {
  subscriptionPackageId: number;
  billingCycle: string;
  price: number;
  currency: string;
  isActive: boolean;
};

type PricingPackage = {
  officeSize: string;
  name: string;
  description: string;
  features: string[];
  monthlyOption?: PricingOption | null;
  annualOption?: PricingOption | null;
  displayOrder: number;
};

type PricingCycleCard = {
  billingCycle: "Monthly" | "Annual";
  title: string;
  description: string;
  features: string[];
  price: number;
  currency: string;
};

type PartnerTenant = {
  id: number;
  name: string;
  countryName: string;
  userCount: number;
};

type DemoRequestForm = {
  fullName: string;
  email: string;
  phoneNumber: string;
  officeName: string;
  notes: string;
};

const emptyDemoRequestForm: DemoRequestForm = {
  fullName: "",
  email: "",
  phoneNumber: "",
  officeName: "",
  notes: "",
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

function getPartnerIcon(index: number) {
  switch (index % 3) {
    case 0:
      return <ApartmentOutlinedIcon sx={{ fontSize: 28 }} />;
    case 1:
      return <AccountBalanceOutlinedIcon sx={{ fontSize: 28 }} />;
    default:
      return <BusinessOutlinedIcon sx={{ fontSize: 28 }} />;
  }
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
  const [packages, setPackages] = useState<PricingPackage[]>([]);
  const [partners, setPartners] = useState<PartnerTenant[]>([]);
  const [partnerPage, setPartnerPage] = useState(0);
  const [demoForm, setDemoForm] = useState<DemoRequestForm>(emptyDemoRequestForm);
  const [loading, setLoading] = useState(true);
  const [demoSubmitting, setDemoSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [demoMessage, setDemoMessage] = useState("");

  const pricingCycleCards = useMemo<PricingCycleCard[]>(() => {
    const buildCard = (billingCycle: "Monthly" | "Annual") => {
      const options = packages
        .map((pkg) => ({
          features: pkg.features || [],
          option: billingCycle === "Monthly" ? pkg.monthlyOption : pkg.annualOption,
        }))
        .filter((item) => item.option);

      if (options.length === 0) {
        return null;
      }

      const features = Array.from(
        new Set(
          options
            .flatMap((item) => item.features)
            .map((feature) => feature.trim())
            .filter((feature) => feature.length > 0),
        ),
      );

      const prices = options.map((item) => item.option?.price ?? 0).filter((price) => price > 0);

      return {
        billingCycle,
        title: t(`subscription.billingCycle.${billingCycle.toLowerCase()}`, { defaultValue: billingCycle }),
        description:
          billingCycle === "Monthly"
            ? t("subscription.public.monthlyDescription", { defaultValue: "Pay monthly with a flexible recurring subscription." })
            : t("subscription.public.annualDescription", { defaultValue: "Pay annually for a longer billing cycle and simpler renewal planning." }),
        features,
        price: prices.length > 0 ? Math.min(...prices) : 0,
        currency: options[0].option?.currency || "",
      };
    };

    return [buildCard("Monthly"), buildCard("Annual")].filter((item): item is PricingCycleCard => item !== null);
  }, [packages, t]);

  useEffect(() => {
    setData(fallbackData);
  }, [fallbackData]);

  useEffect(() => {
    let mounted = true;
    const requestLanguage = getRequestLanguage(currentLanguage);

    (async () => {
      try {
        const [landingResponse, packagesResponse, partnersResponse] = await Promise.all([
          api.get("/LandingPage", {
            skipTenantHeader: true,
            headers: {
              "Accept-Language": requestLanguage,
            },
          } as any),
          api.get("/SubscriptionPackages/public", {
            skipTenantHeader: true,
            headers: {
              "Accept-Language": requestLanguage,
            },
          } as any),
          api.get("/Tenants/public-partners", {
            skipTenantHeader: true,
            headers: {
              "Accept-Language": requestLanguage,
            },
          } as any),
        ]);

        if (mounted) {
          setData(buildLandingData(landingResponse.data, fallbackData));
          setPackages(Array.isArray(packagesResponse.data) ? packagesResponse.data : []);
          setPartners(Array.isArray(partnersResponse.data) ? partnersResponse.data : []);
          setError("");
        }
      } catch {
        if (mounted) {
          setData(fallbackData);
          setPackages([]);
          setPartners([]);
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
      { value: "2", label: t("landing.stats.packages", { defaultValue: "Office packages" }) },
      { value: "360", label: t("landing.stats.visibility") },
    ],
    [t],
  );

  const activePartner = partners.length > 0 ? partners[partnerPage % partners.length] : null;

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

  const updateDemoField = <K extends keyof DemoRequestForm>(field: K, value: DemoRequestForm[K]) => {
    setDemoForm((current) => ({ ...current, [field]: value }));
    setDemoMessage("");
  };

  const submitDemoRequest = async () => {
    setDemoSubmitting(true);
    setDemoMessage("");

    try {
      const response = await api.post("/DemoRequests", demoForm, {
        skipTenantHeader: true,
        headers: {
          "Accept-Language": getRequestLanguage(currentLanguage),
        },
      } as any);
      setDemoForm(emptyDemoRequestForm);
      setDemoMessage(response.data?.message || t("landing.demo.success", { defaultValue: "Demo request submitted successfully." }));
    } catch (e: any) {
      setDemoMessage(e?.response?.data?.message || t("landing.demo.failed", { defaultValue: "Failed to submit demo request." }));
    } finally {
      setDemoSubmitting(false);
    }
  };

  return (
    <PublicSiteShell
      data={data}
      currentLanguage={currentLanguage}
      onChangeLanguage={changeLanguage}
      onNavigate={navigateTo}
      isAuthenticated={isAuthenticated}
      isAuthInitialized={isAuthInitialized}
      extraHeaderActions={
        <Button variant="outlined" onClick={() => document.getElementById("landing-demo-section")?.scrollIntoView({ behavior: "smooth" })}>
          {t("landing.demo.bookButton", { defaultValue: "Book a demo" })}
        </Button>
      }
    >
      <Container maxWidth="lg" sx={{ py: { xs: 5, md: 8 } }}>
        {error && (
          <Alert severity="warning" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ position: "relative", mb: 5 }}>
          <Box
            sx={{
              position: "absolute",
              insetInlineStart: { xs: -24, md: -60 },
              top: { xs: -14, md: 18 },
              width: { xs: 120, md: 180 },
              height: { xs: 120, md: 180 },
              borderRadius: "50%",
              background: alpha(theme.palette.primary.light, 0.22),
              filter: "blur(20px)",
            }}
          />
          <Box
            sx={{
              position: "absolute",
              insetInlineEnd: { xs: -30, md: 20 },
              top: { xs: 40, md: -20 },
              width: { xs: 140, md: 220 },
              height: { xs: 140, md: 220 },
              borderRadius: "50%",
              background: alpha("#52a49d", 0.18),
              filter: "blur(26px)",
            }}
          />
          <Box
            sx={{
              position: "relative",
              display: "grid",
              gridTemplateColumns: { xs: "1fr", lg: "minmax(0, 1.12fr) minmax(340px, 0.88fr)" },
              gap: 3,
              alignItems: "stretch",
            }}
          >
            <Paper
              elevation={0}
              sx={{
                p: { xs: 2.5, md: 4 },
                borderRadius: 6,
                minHeight: { xs: 360, md: 400 },
                display: "flex",
                flexDirection: "column",
                justifyContent: "space-between",
              color: "common.white",
              border: "1px solid",
              borderColor: alpha("#ffffff", 0.16),
              background:
                "linear-gradient(135deg, rgba(10,40,79,1) 0%, rgba(18,58,99,0.98) 40%, rgba(28,123,130,0.94) 100%)",
              boxShadow: "0 38px 78px -34px rgba(18,58,99,0.62)",
              position: "relative",
              overflow: "hidden",
              "&::before": {
                content: '""',
                position: "absolute",
                insetInlineEnd: -80,
                top: -60,
                width: 220,
                height: 220,
                borderRadius: "50%",
                background: "rgba(255,255,255,0.08)",
              },
              "&::after": {
                content: '""',
                position: "absolute",
                insetInlineStart: -40,
                bottom: -90,
                width: 260,
                height: 260,
                borderRadius: "50%",
                background: "rgba(255,255,255,0.08)",
              },
            }}
          >
            <Box sx={{ position: "relative", zIndex: 1 }}>
              <Chip
                label={t("landing.badge")}
                sx={{
                  mb: 2.5,
                  color: "common.white",
                  backgroundColor: alpha("#ffffff", 0.14),
                  borderRadius: 999,
                  fontWeight: 800,
                  backdropFilter: "blur(10px)",
                }}
              />
              <Typography
                variant="h2"
                sx={{
                  fontWeight: 900,
                  letterSpacing: "-0.06em",
                  maxWidth: 700,
                  mb: 1.5,
                  lineHeight: 1.12,
                  fontSize: { xs: "2rem", md: "3.25rem" },
                }}
              >
                {data.heroTitle}
              </Typography>
              <Typography
                variant="h6"
                sx={{
                  maxWidth: 620,
                  opacity: 0.84,
                  lineHeight: 1.75,
                  fontWeight: 500,
                  fontSize: { xs: "1rem", md: "1.1rem" },
                }}
              >
                {data.heroSubtitle}
              </Typography>
            </Box>

            <Stack spacing={2.25} sx={{ mt: 3, position: "relative", zIndex: 1 }}>
              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5}>
                <Button
                  size="large"
                  variant="contained"
                  endIcon={<ArrowOutwardIcon />}
                  onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
                  sx={{
                    px: 3,
                    py: 1.1,
                    borderRadius: 999,
                    color: "primary.dark",
                    backgroundColor: "common.white",
                    fontWeight: 800,
                    "&:hover": { backgroundColor: alpha("#ffffff", 0.92) },
                  }}
                >
                  {data.primaryButtonText || t("landing.actions.register")}
                </Button>
                <Button
                  size="large"
                  variant="outlined"
                  onClick={() => document.getElementById("landing-demo-section")?.scrollIntoView({ behavior: "smooth" })}
                  sx={{
                    px: 3,
                    py: 1.1,
                    borderRadius: 999,
                    color: "common.white",
                    borderColor: alpha("#ffffff", 0.45),
                    fontWeight: 800,
                    "&:hover": {
                      borderColor: "common.white",
                      backgroundColor: alpha("#ffffff", 0.08),
                    },
                  }}
                >
                  {t("landing.demo.bookButton", { defaultValue: "Book a demo" })}
                </Button>
              </Stack>

              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: { xs: "1fr", sm: "repeat(3, minmax(0, 1fr))" },
                  gap: 1,
                }}
              >
                {stats.map((item) => (
                  <Paper
                    key={item.label}
                    elevation={0}
                    sx={{
                      p: 1.4,
                      borderRadius: 3,
                      border: "1px solid",
                      borderColor: alpha("#ffffff", 0.12),
                      backgroundColor: alpha("#ffffff", 0.08),
                      backdropFilter: "blur(12px)",
                    }}
                  >
                    <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 0.25 }}>
                      {item.value}
                    </Typography>
                    <Typography variant="caption" sx={{ opacity: 0.82, lineHeight: 1.5 }}>
                      {item.label}
                    </Typography>
                  </Paper>
                ))}
              </Box>
            </Stack>
          </Paper>

          <Stack spacing={3}>
          <Paper
            elevation={0}
            sx={{
              p: { xs: 2.5, md: 3 },
              borderRadius: 5,
              border: "1px solid",
              borderColor: alpha(theme.palette.primary.main, 0.12),
              background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(241,247,250,0.98) 100%)",
              boxShadow: "0 24px 56px -42px rgba(18,58,99,0.4)",
            }}
          >
            {loading ? (
              <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: 220 }}>
                <CircularProgress />
              </Box>
            ) : (
              <Stack spacing={2.5}>
                <Box>
                  <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
                    {t("landing.highlights")}
                  </Typography>
                  <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 1.25 }}>
                    {data.aboutTitle}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ lineHeight: 1.85 }}>
                    {data.aboutDescription}
                  </Typography>
                </Box>

                <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                  {(data.features || []).slice(0, 3).map((feature) => (
                    <Chip
                      key={feature.title}
                      label={feature.title}
                      sx={{
                        borderRadius: 999,
                        fontWeight: 700,
                        backgroundColor: alpha(theme.palette.primary.main, 0.08),
                        color: "primary.main",
                      }}
                    />
                  ))}
                </Stack>
              </Stack>
            )}
          </Paper>

          <Paper
            elevation={0}
            sx={{
              p: { xs: 2.5, md: 3 },
              borderRadius: 5,
              color: "common.white",
              border: "1px solid",
              borderColor: alpha(theme.palette.primary.main, 0.08),
              background: "linear-gradient(135deg, rgba(21,78,108,1) 0%, rgba(20,101,119,0.98) 100%)",
              boxShadow: "0 28px 62px -40px rgba(18,58,99,0.55)",
            }}
          >
            <Typography variant="overline" sx={{ opacity: 0.78, letterSpacing: "0.18em", fontWeight: 800 }}>
              {t("landing.contactTitle")}
            </Typography>
            <Typography variant="h6" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mt: 1, mb: 1 }}>
              {t("landing.contactSubtitle")}
            </Typography>

            <Stack spacing={1} sx={{ mt: 2 }}>
              <Chip label={`${t("landing.contact.email")}: ${data.contactEmail || "-"}`} sx={{ justifyContent: "flex-start", bgcolor: alpha("#ffffff", 0.12), color: "common.white" }} />
              <Chip label={`${t("landing.contact.phone")}: ${data.contactPhone || "-"}`} sx={{ justifyContent: "flex-start", bgcolor: alpha("#ffffff", 0.12), color: "common.white" }} />
              <Chip label={`${t("landing.contact.address")}: ${data.contactAddress || "-"}`} sx={{ justifyContent: "flex-start", bgcolor: alpha("#ffffff", 0.12), color: "common.white" }} />
            </Stack>

            <Stack direction={{ xs: "column", sm: "row" }} spacing={1.25} sx={{ mt: 2 }}>
              <Button
                variant="contained"
                onClick={() => navigateTo("/about-us")}
                sx={{
                  borderRadius: 999,
                  bgcolor: "common.white",
                  color: "primary.dark",
                  fontWeight: 800,
                  "&:hover": { bgcolor: alpha("#ffffff", 0.92) },
                }}
              >
                {t("landing.footer.links.aboutUs")}
              </Button>
              <Button
                variant="outlined"
                onClick={() => navigateTo("/contact-us")}
                sx={{
                  borderRadius: 999,
                  borderColor: alpha("#ffffff", 0.38),
                  color: "common.white",
                  fontWeight: 800,
                  "&:hover": { borderColor: "common.white", backgroundColor: alpha("#ffffff", 0.08) },
                }}
              >
                {t("landing.footer.links.contactUs")}
              </Button>
            </Stack>
          </Paper>
          </Stack>
          </Box>
        </Box>

        <Paper
          elevation={0}
          sx={{
            mb: 4,
            p: { xs: 2.5, md: 3 },
            borderRadius: 5,
            border: "1px solid",
            borderColor: alpha(theme.palette.primary.main, 0.1),
            background: "linear-gradient(180deg, rgba(255,255,255,0.84) 0%, rgba(247,250,252,0.96) 100%)",
          }}
        >
          <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
            {t("landing.featuresTitle")}
          </Typography>
          <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 2.5 }}>
            {t("landing.featuresSubtitle")}
          </Typography>

          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "repeat(3, minmax(0, 1fr))" },
              gap: 2,
            }}
          >
            {(data.features || []).map((feature: LandingFeature, index) => (
              <Card
                key={`${feature.title}-${index}`}
                elevation={0}
                sx={{
                  height: "100%",
                  borderRadius: 4,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background:
                    index === 1
                      ? "linear-gradient(180deg, rgba(16,64,106,1) 0%, rgba(26,93,120,0.96) 100%)"
                      : "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                  color: index === 1 ? "common.white" : "text.primary",
                  transform: "none",
                  boxShadow: index === 1 ? "0 28px 60px -34px rgba(18,58,99,0.46)" : "none",
                }}
              >
                <CardContent sx={{ p: 2.5 }}>
                  <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 2 }}>
                    <Box
                      sx={{
                        width: 56,
                        height: 56,
                        display: "grid",
                        placeItems: "center",
                        borderRadius: 4,
                        color: index === 1 ? "common.white" : "primary.main",
                        backgroundColor: index === 1 ? alpha("#ffffff", 0.12) : alpha(theme.palette.primary.main, 0.1),
                      }}
                    >
                      {getFeatureIcon(feature.iconKey)}
                    </Box>
                    <Typography variant="caption" sx={{ opacity: index === 1 ? 0.74 : 0.5, fontWeight: 800 }}>
                      0{index + 1}
                    </Typography>
                  </Stack>
                  <Typography variant="subtitle1" sx={{ fontWeight: 800, mb: 0.75 }}>
                    {feature.title}
                  </Typography>
                  <Typography variant="body2" color={index === 1 ? "inherit" : "text.secondary"} sx={{ lineHeight: 1.9, opacity: index === 1 ? 0.88 : 1 }}>
                    {feature.description}
                  </Typography>
                </CardContent>
              </Card>
            ))}
          </Box>
        </Paper>

        <Paper
          elevation={0}
          sx={{
            mb: 4,
            p: { xs: 2.5, md: 3 },
            borderRadius: 5,
            border: "1px solid",
            borderColor: alpha(theme.palette.primary.main, 0.1),
            background: "linear-gradient(180deg, rgba(255,255,255,0.9) 0%, rgba(243,248,251,0.98) 100%)",
          }}
        >
          <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
            {t("subscription.pricingTitle", { defaultValue: "Pricing packages" })}
          </Typography>
          <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 2.5 }}>
            {t("subscription.pricingSubtitle", { defaultValue: "Choose monthly or annual billing" })}
          </Typography>

          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "repeat(2, minmax(0, 1fr))" },
              gap: 2,
            }}
          >
            {pricingCycleCards.map((card) => (
              <Card
                key={card.billingCycle}
                elevation={0}
                sx={{
                  borderRadius: 4,
                  border: "1px solid",
                  borderColor: card.billingCycle === "Annual" ? alpha("#123a63", 0.28) : alpha(theme.palette.primary.main, 0.12),
                  background:
                    card.billingCycle === "Annual"
                      ? "linear-gradient(180deg, rgba(15,56,95,1) 0%, rgba(22,91,119,0.96) 100%)"
                      : "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                  color: card.billingCycle === "Annual" ? "common.white" : "text.primary",
                  boxShadow:
                    card.billingCycle === "Annual"
                      ? "0 30px 62px -36px rgba(18,58,99,0.48)"
                      : "0 20px 42px -36px rgba(18,58,99,0.32)",
                }}
              >
                <CardContent sx={{ p: 2.5 }}>
                  <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1.5 }}>
                    <Typography variant="subtitle1" sx={{ fontWeight: 900 }}>
                      {card.title}
                    </Typography>
                    <Chip
                      size="small"
                      label={card.billingCycle}
                      sx={{
                        borderRadius: 999,
                        fontWeight: 800,
                        color: card.billingCycle === "Annual" ? "common.white" : "primary.main",
                        bgcolor: card.billingCycle === "Annual" ? alpha("#ffffff", 0.12) : alpha(theme.palette.primary.main, 0.08),
                      }}
                    />
                  </Stack>
                  <Typography variant="body2" color={card.billingCycle === "Annual" ? "inherit" : "text.secondary"} sx={{ mb: 1.25, opacity: card.billingCycle === "Annual" ? 0.84 : 1, lineHeight: 1.75 }}>
                    {card.description}
                  </Typography>

                  <Stack spacing={1} sx={{ mb: 2 }}>
                    {card.features.map((feature) => (
                      <Typography key={feature} variant="body2" color={card.billingCycle === "Annual" ? "inherit" : "text.secondary"} sx={{ opacity: card.billingCycle === "Annual" ? 0.84 : 1 }}>
                        - {feature}
                      </Typography>
                    ))}
                  </Stack>

                  <Paper
                    elevation={0}
                    sx={{
                      p: 1.25,
                      borderRadius: 3,
                      border: "1px solid",
                      borderColor: card.billingCycle === "Annual" ? alpha("#ffffff", 0.14) : "divider",
                      mb: 2,
                      bgcolor: card.billingCycle === "Annual" ? alpha("#ffffff", 0.08) : "background.paper",
                    }}
                  >
                    <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>
                      {t("subscription.public.startsFrom", { defaultValue: "Starts from" })}
                    </Typography>
                    <Typography variant="subtitle1" sx={{ fontWeight: 900, mt: 0.5 }}>
                      {card.price.toFixed(0)} {card.currency}
                    </Typography>
                  </Paper>

                  <Button
                    variant="contained"
                    onClick={() => router.push("/register")}
                    sx={{
                      width: "100%",
                      borderRadius: 999,
                      fontWeight: 800,
                      background:
                        card.billingCycle === "Annual"
                          ? "linear-gradient(135deg, rgba(255,255,255,1) 0%, rgba(232,241,246,1) 100%)"
                          : "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)",
                      color: card.billingCycle === "Annual" ? "primary.dark" : "common.white",
                    }}
                  >
                    {t("subscription.choosePackage", { defaultValue: "Choose package" })}
                  </Button>
                </CardContent>
              </Card>
            ))}
          </Box>
        </Paper>

        <Paper
          elevation={0}
          sx={{
            mb: 4,
            p: { xs: 2.5, md: 3 },
            borderRadius: 5,
            border: "1px solid",
            borderColor: alpha(theme.palette.primary.main, 0.1),
            background: "linear-gradient(180deg, rgba(255,255,255,0.82) 0%, rgba(246,250,252,0.96) 100%)",
          }}
        >
          <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
            {t("landing.partners.title", { defaultValue: "Our partners" })}
          </Typography>
          <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 2.5 }}>
            {t("landing.partners.subtitle", { defaultValue: "Law firms already operating with our platform" })}
          </Typography>

          {activePartner ? (
            <Box>
              <Card
                key={activePartner.id}
                elevation={0}
                sx={{
                  borderRadius: 999,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                  boxShadow: "0 20px 42px -36px rgba(18,58,99,0.3)",
                  position: "relative",
                  overflow: "hidden",
                  maxWidth: 520,
                  mx: "auto",
                  "&::before": {
                    content: '""',
                    position: "absolute",
                    insetInlineStart: 0,
                    insetInlineEnd: 0,
                    top: 0,
                    height: 4,
                    background: "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)",
                  },
                }}
              >
                <CardContent
                  sx={{
                    p: { xs: 2.5, md: 3 },
                    minHeight: { xs: 160, md: 180 },
                    display: "flex",
                    flexDirection: "column",
                    justifyContent: "center",
                  }}
                >
                  <Stack direction="row" justifyContent="space-between" alignItems="flex-start" sx={{ mb: 1.25 }}>
                    <Box
                      sx={{
                        width: 40,
                        height: 40,
                        borderRadius: "50%",
                        display: "grid",
                        placeItems: "center",
                        color: "primary.main",
                        bgcolor: alpha(theme.palette.primary.main, 0.08),
                        border: "1px solid",
                        borderColor: alpha(theme.palette.primary.main, 0.1),
                        flexShrink: 0,
                      }}
                    >
                      <Box sx={{ transform: "scale(0.8)", display: "grid", placeItems: "center" }}>
                        {getPartnerIcon(partnerPage)}
                      </Box>
                    </Box>
                    <Chip
                      size="small"
                      label={activePartner.countryName || t("landing.partners.countryFallback", { defaultValue: "Regional partner" })}
                      sx={{
                        borderRadius: 999,
                        fontWeight: 700,
                        bgcolor: alpha(theme.palette.primary.main, 0.08),
                        color: "primary.main",
                      }}
                    />
                  </Stack>
                  <Typography variant="h6" sx={{ fontWeight: 800, mb: 0.5 }}>
                    {activePartner.name}
                  </Typography>
                  <Typography
                    variant="body2"
                    sx={{
                      display: "block",
                      color: "text.secondary",
                      lineHeight: 1.7,
                    }}
                  >
                    {data.systemName}
                  </Typography>
                </CardContent>
              </Card>
              <Stack direction="row" justifyContent="center" alignItems="center" spacing={1} sx={{ mt: 2 }}>
                <Button
                  size="small"
                  variant="text"
                  aria-label={t("app.previous")}
                  onClick={() => setPartnerPage((current) => (current - 1 + partners.length) % partners.length)}
                  sx={{ minWidth: 0, width: 36, height: 36, borderRadius: "50%" }}
                >
                  {isRTL ? <ArrowForwardIosIcon sx={{ fontSize: 16 }} /> : <ArrowBackIosNewIcon sx={{ fontSize: 16 }} />}
                </Button>
                <Stack direction="row" spacing={0.75} alignItems="center">
                  {partners.map((partner, index) => (
                    <Box
                      key={partner.id}
                      component="button"
                      onClick={() => setPartnerPage(index)}
                      sx={{
                        width: index === partnerPage ? 26 : 8,
                        height: 8,
                        borderRadius: 999,
                        border: "none",
                        cursor: "pointer",
                        transition: "all 0.2s ease",
                        background: index === partnerPage ? "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)" : alpha(theme.palette.primary.main, 0.22),
                      }}
                    />
                  ))}
                </Stack>
                <Button
                  size="small"
                  variant="text"
                  aria-label={t("app.next")}
                  onClick={() => setPartnerPage((current) => (current + 1) % partners.length)}
                  sx={{ minWidth: 0, width: 36, height: 36, borderRadius: "50%" }}
                >
                  {isRTL ? <ArrowBackIosNewIcon sx={{ fontSize: 16 }} /> : <ArrowForwardIosIcon sx={{ fontSize: 16 }} />}
                </Button>
              </Stack>
            </Box>
          ) : null}
        </Paper>

        <Paper
          id="landing-demo-section"
          elevation={0}
          sx={{
            p: { xs: 1.25, md: 1.5 },
            borderRadius: 5,
            border: "1px solid",
            borderColor: alpha(theme.palette.primary.main, 0.12),
            background: "linear-gradient(135deg, rgba(18,58,99,0.08) 0%, rgba(28,123,130,0.12) 100%)",
            mb: 4,
            boxShadow: "0 28px 60px -44px rgba(18,58,99,0.34)",
          }}
        >
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "minmax(0, 1fr) minmax(320px, 0.9fr)" },
              gap: 0,
              alignItems: "stretch",
            }}
          >
            <Box
              sx={{
                p: { xs: 2.5, md: 3 },
                borderRadius: { xs: "18px 18px 0 0", md: "18px 0 0 18px" },
                color: "common.white",
                background: "linear-gradient(135deg, rgba(10,40,79,1) 0%, rgba(22,91,119,0.96) 100%)",
              }}
            >
              <Typography variant="overline" sx={{ opacity: 0.78, letterSpacing: "0.18em", fontWeight: 800 }}>
                {t("landing.demo.bookButton", { defaultValue: "Book a demo" })}
              </Typography>
              <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 1, mt: 0.75 }}>
                {t("landing.demo.title", { defaultValue: "Book a demo" })}
              </Typography>
              <Typography variant="body2" sx={{ lineHeight: 1.85, opacity: 0.86, mb: 2 }}>
                {t("landing.demo.subtitle", { defaultValue: "Request a guided demo for your office and our team will review and approve it." })}
              </Typography>
              <Stack spacing={1.25}>
                <Chip label={`${t("landing.contact.email")}: ${data.contactEmail || "-"}`} sx={{ justifyContent: "flex-start", bgcolor: alpha("#ffffff", 0.12), color: "common.white" }} />
                <Chip label={`${t("landing.contact.phone")}: ${data.contactPhone || "-"}`} sx={{ justifyContent: "flex-start", bgcolor: alpha("#ffffff", 0.12), color: "common.white" }} />
                <Chip label={`${t("landing.contact.workingHours")}: ${data.contactWorkingHours || "-"}`} sx={{ justifyContent: "flex-start", bgcolor: alpha("#ffffff", 0.12), color: "common.white" }} />
              </Stack>
            </Box>

            <Box
              sx={{
                p: { xs: 2.5, md: 3 },
                borderRadius: { xs: "0 0 18px 18px", md: "0 18px 18px 0" },
                backgroundColor: alpha("#ffffff", 0.96),
                display: "grid",
                gap: 1.5,
              }}
            >
              <TextField label={t("landing.demo.fields.fullName", { defaultValue: "Full name" })} value={demoForm.fullName} onChange={(e) => updateDemoField("fullName", e.target.value)} fullWidth />
              <TextField label={t("landing.demo.fields.officeName", { defaultValue: "Office name" })} value={demoForm.officeName} onChange={(e) => updateDemoField("officeName", e.target.value)} fullWidth />
              <TextField label={t("landing.demo.fields.email", { defaultValue: "Email" })} value={demoForm.email} onChange={(e) => updateDemoField("email", e.target.value)} fullWidth />
              <TextField label={t("landing.demo.fields.phoneNumber", { defaultValue: "Phone number" })} value={demoForm.phoneNumber} onChange={(e) => updateDemoField("phoneNumber", e.target.value)} fullWidth />
              <TextField label={t("landing.demo.fields.notes", { defaultValue: "Notes" })} value={demoForm.notes} onChange={(e) => updateDemoField("notes", e.target.value)} fullWidth multiline minRows={3} />
              {demoMessage && (
                <Alert severity={demoMessage.toLowerCase().includes("success") || demoMessage.toLowerCase().includes("submitted") ? "success" : "info"}>
                  {demoMessage}
                </Alert>
              )}
              <Button
                variant="contained"
                onClick={submitDemoRequest}
                disabled={demoSubmitting}
                sx={{ borderRadius: 999, fontWeight: 800, background: "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)" }}
              >
                {t("landing.demo.submit", { defaultValue: "Send demo request" })}
              </Button>
            </Box>
          </Box>
        </Paper>
      </Container>
    </PublicSiteShell>
  );
}
