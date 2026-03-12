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
  ArrowOutward as ArrowOutwardIcon,
  AutoAwesome as AutoAwesomeIcon,
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

export default function LandingPage() {
  const router = useRouter();
  const theme = useTheme();
  const { t, i18n } = useTranslation();
  const { isAuthenticated, isAuthInitialized } = useAuth();
  const currentLanguage = (i18n.resolvedLanguage || i18n.language || "ar").startsWith("ar") ? "ar" : "en";
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

            <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} sx={{ mt: 4, position: "relative", zIndex: 1 }}>
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
            {(data.features || []).map((feature: LandingFeature, index) => (
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
                  <Typography variant="body2" color="text.secondary">
                    {partner.countryName || t("landing.partners.countryFallback", { defaultValue: "Regional partner" })}
                  </Typography>
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
    </PublicSiteShell>
  );
}
