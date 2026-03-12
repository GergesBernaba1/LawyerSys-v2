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
  TextField,
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
  const [packages, setPackages] = useState<PricingPackage[]>([]);
  const [partners, setPartners] = useState<PartnerTenant[]>([]);
  const [demoForm, setDemoForm] = useState<DemoRequestForm>(emptyDemoRequestForm);
  const [loading, setLoading] = useState(true);
  const [demoSubmitting, setDemoSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [demoMessage, setDemoMessage] = useState("");

  const pricingCycleCards = useMemo<PricingCycleCard[]>(() => {
    const buildCard = (billingCycle: "Monthly" | "Annual") => {
      const options = packages
        .map((pkg) => ({
          description: pkg.description,
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

      const prices = options
        .map((item) => item.option?.price ?? 0)
        .filter((price) => price > 0);
      const currency = options[0].option?.currency || "";

      return {
        billingCycle,
        title: t(`subscription.billingCycle.${billingCycle.toLowerCase()}`, { defaultValue: billingCycle }),
        description:
          billingCycle === "Monthly"
            ? t("subscription.public.monthlyDescription", { defaultValue: "Pay monthly with a flexible recurring subscription." })
            : t("subscription.public.annualDescription", { defaultValue: "Pay annually for a longer billing cycle and simpler renewal planning." }),
        features,
        price: prices.length > 0 ? Math.min(...prices) : 0,
        currency,
      };
    };

    return [buildCard("Monthly"), buildCard("Annual")].filter((item): item is PricingCycleCard => item !== null);
  }, [packages, t]);

  useEffect(() => {
    setData(fallbackData);
  }, [fallbackData]);

  useEffect(() => {
    let mounted = true;
    const requestLanguage = currentLanguage === "ar" ? "ar-SA" : "en-US";

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

  const updateDemoField = <K extends keyof DemoRequestForm>(field: K, value: DemoRequestForm[K]) => {
    setDemoForm((current) => ({ ...current, [field]: value }));
    setDemoMessage("");
  };

  const submitDemoRequest = async () => {
    setDemoSubmitting(true);
    setDemoMessage("");

    try {
      const requestLanguage = currentLanguage === "ar" ? "ar-SA" : "en-US";
      const response = await api.post("/DemoRequests", demoForm, {
        skipTenantHeader: true,
        headers: {
          "Accept-Language": requestLanguage,
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
              <Button variant="outlined" onClick={() => document.getElementById("landing-demo-section")?.scrollIntoView({ behavior: "smooth" })}>
                {t("landing.demo.bookButton", { defaultValue: "Book a demo" })}
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
                onClick={() => document.getElementById("landing-demo-section")?.scrollIntoView({ behavior: "smooth" })}
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
                {t("landing.demo.bookButton", { defaultValue: "Book a demo" })}
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

        <Box sx={{ mb: 4 }}>
          <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
            {t("subscription.pricingTitle", { defaultValue: "Pricing packages" })}
          </Typography>
          <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 2.5 }}>
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
                  borderRadius: 5,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                }}
              >
                <CardContent sx={{ p: 3 }}>
                  <Typography variant="h6" sx={{ fontWeight: 900, mb: 0.75 }}>
                    {card.title}
                  </Typography>
                  <Typography variant="body1" color="text.secondary" sx={{ mb: 1.5 }}>
                    {card.description}
                  </Typography>

                  <Stack spacing={1} sx={{ mb: 2 }}>
                    {card.features.map((feature) => (
                      <Typography key={feature} variant="body2" color="text.secondary">
                        - {feature}
                      </Typography>
                    ))}
                  </Stack>

                  <Paper elevation={0} sx={{ p: 1.5, borderRadius: 3, border: "1px solid", borderColor: "divider", mb: 2 }}>
                    <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>
                      {t("subscription.public.startsFrom", { defaultValue: "Starts from" })}
                    </Typography>
                    <Typography variant="h6" sx={{ fontWeight: 900, mt: 0.75 }}>
                      {card.price.toFixed(0)} {card.currency}
                    </Typography>
                  </Paper>

                  <Button
                    variant="contained"
                    onClick={() => router.push("/register")}
                    sx={{
                      background: "linear-gradient(135deg, #123a63 0%, #1c7b82 100%)",
                    }}
                  >
                    {t("subscription.choosePackage", { defaultValue: "Choose package" })}
                  </Button>
                </CardContent>
              </Card>
            ))}
          </Box>
        </Box>

        <Box sx={{ mb: 4 }}>
          <Typography variant="overline" color="primary.main" sx={{ fontWeight: 800, letterSpacing: "0.18em" }}>
            {t("landing.partners.title", { defaultValue: "Our partners" })}
          </Typography>
          <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 2.5 }}>
            {t("landing.partners.subtitle", { defaultValue: "Law firms already operating with our platform" })}
          </Typography>

          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "repeat(3, minmax(0, 1fr))" },
              gap: 2,
            }}
          >
            {partners.map((partner) => (
              <Card
                key={partner.id}
                elevation={0}
                sx={{
                  borderRadius: 5,
                  border: "1px solid",
                  borderColor: alpha(theme.palette.primary.main, 0.12),
                  background: "linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(244,248,251,0.98) 100%)",
                }}
              >
                <CardContent sx={{ p: 3 }}>
                  <Typography variant="h6" sx={{ fontWeight: 800, mb: 0.75 }}>
                    {partner.name}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                    {partner.countryName || t("landing.partners.countryFallback", { defaultValue: "Regional partner" })}
                  </Typography>
                  <Chip
                    size="small"
                    label={t("landing.partners.users", {
                      defaultValue: "{{count}} active users",
                      count: partner.userCount,
                    })}
                  />
                </CardContent>
              </Card>
            ))}
          </Box>
        </Box>

        <Paper
          id="landing-demo-section"
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
              gridTemplateColumns: { xs: "1fr", md: "minmax(0, 1fr) minmax(320px, 0.9fr)" },
              gap: 3,
              alignItems: "start",
            }}
          >
            <Box>
              <Typography variant="h4" sx={{ fontWeight: 900, letterSpacing: "-0.04em", mb: 1 }}>
                {t("landing.demo.title", { defaultValue: "Book a demo" })}
              </Typography>
              <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.9, mb: 2 }}>
                {t("landing.demo.subtitle", { defaultValue: "Request a guided demo for your office and our team will review and approve it." })}
              </Typography>
              <Stack spacing={1.25}>
                <Chip label={`${t("landing.contact.email")}: ${data.contactEmail || "-"}`} sx={{ justifyContent: "flex-start" }} />
                <Chip label={`${t("landing.contact.phone")}: ${data.contactPhone || "-"}`} sx={{ justifyContent: "flex-start" }} />
              </Stack>
            </Box>

            <Box sx={{ display: "grid", gap: 1.5 }}>
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
              <Button variant="contained" onClick={submitDemoRequest} disabled={demoSubmitting}>
                {t("landing.demo.submit", { defaultValue: "Send demo request" })}
              </Button>
            </Box>
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
