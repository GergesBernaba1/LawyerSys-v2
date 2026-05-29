"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Container,
  Paper,
  Stack,
  TextField,
  Typography,
  alpha,
  useTheme,
} from "@mui/material";
import {
  AccessTime as AccessTimeIcon,
  AccountBalanceOutlined as AccountBalanceOutlinedIcon,
  ApartmentOutlined as ApartmentOutlinedIcon,
  ArrowBackIosNew as ArrowBackIosNewIcon,
  ArrowForwardIos as ArrowForwardIosIcon,
  ArrowOutward as ArrowOutwardIcon,
  AutoAwesome as AutoAwesomeIcon,
  BarChart as BarChartIcon,
  Bolt as BoltIcon,
  BusinessOutlined as BusinessOutlinedIcon,
  CalendarMonth as CalendarMonthIcon,
  Check as CheckIcon,
  ExpandMore as ExpandMoreIcon,
  FolderOutlined as FolderOutlinedIcon,
  Insights as InsightsIcon,
  Lock as LockIcon,
  NotificationsActive as NotificationsActiveIcon,
  People as PeopleIcon,
  PeopleAltOutlined as PeopleAltOutlinedIcon,
  PlayArrow as PlayArrowIcon,
  Repeat as RepeatIcon,
  Security as SecurityIcon,
  SupportAgent as SupportAgentIcon,
  WorkspacePremium as WorkspacePremiumIcon,
} from "@mui/icons-material";
import api from "../src/services/api";
import { useAuth } from "../src/services/auth";
import { useCurrency } from "../src/hooks/useCurrency";
import PublicSiteShell from "../src/components/public/PublicSiteShell";
import {
  buildLandingData,
  getDefaultLandingPage,
  getRequestLanguage,
  type LandingFeature,
  type LandingPageData,
} from "../src/services/publicSite";

// ─── Types ───────────────────────────────────────────────────────────────────

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

type PartnerTenant = {
  id: number;
  name: string;
  countryName: string;
  userCount: number;
  logoUrl?: string;
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

function getFeatureIcon(iconKey: string, size = 26) {
  switch (iconKey) {
    case "automation":
      return <BoltIcon sx={{ fontSize: size }} />;
    case "collaboration":
      return <SecurityIcon sx={{ fontSize: size }} />;
    case "insight":
      return <InsightsIcon sx={{ fontSize: size }} />;
    default:
      return <AutoAwesomeIcon sx={{ fontSize: size }} />;
  }
}

function getPartnerIcon(index: number) {
  switch (index % 3) {
    case 0:
      return <ApartmentOutlinedIcon sx={{ fontSize: 24 }} />;
    case 1:
      return <AccountBalanceOutlinedIcon sx={{ fontSize: 24 }} />;
    default:
      return <BusinessOutlinedIcon sx={{ fontSize: 24 }} />;
  }
}

function toPublicMediaUrl(path: string | undefined): string | undefined {
  if (!path) return undefined;
  if (/^https?:\/\//i.test(path)) return path;
  const apiBase = String(api.defaults.baseURL || "");
  const apiRoot = apiBase.replace(/\/api\/?$/, "") || "";
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return `${apiRoot}${normalizedPath}`;
}

// ─── Dark card style helper ───────────────────────────────────────────────────

const darkCard = {
  background: "rgba(255,255,255,0.04)",
  border: "1px solid rgba(255,255,255,0.08)",
  backdropFilter: "blur(8px)",
};

import { brandGradient as tealGradient } from "../src/brand";

// ─── Dashboard Mockup ─────────────────────────────────────────────────────────

function DashboardMockup({ t }: { t: (key: string, opts?: any) => string }) {
  const statItems = [
    { label: t("landing.mockup.total", { defaultValue: "الكلي" }), value: "248", color: "#14c8d4" },
    { label: t("landing.mockup.active", { defaultValue: "النشطة" }), value: "164", color: "#10b981" },
    { label: t("landing.mockup.week", { defaultValue: "الأسبوع" }), value: "18", color: "#f59e0b" },
    { label: t("landing.mockup.financial", { defaultValue: "مالية" }), value: "7", color: "#a78bfa" },
  ];

  const caseRows = [
    { color: "#14c8d4", statusColor: "#14c8d4", status: t("landing.mockup.statusActive", { defaultValue: "نشطة" }) },
    { color: "#f59e0b", statusColor: "#f59e0b", status: t("landing.mockup.statusPending", { defaultValue: "معلقة" }) },
    { color: "#10b981", statusColor: "#10b981", status: t("landing.mockup.statusClosed", { defaultValue: "مغلقة" }) },
    { color: "#a78bfa", statusColor: "#a78bfa", status: t("landing.mockup.statusNew", { defaultValue: "جديدة" }) },
    { color: "#14c8d4", statusColor: "#14c8d4", status: t("landing.mockup.statusActive", { defaultValue: "نشطة" }) },
  ];

  const bars = [28, 46, 38, 62, 52, 76, 68, 88, 72, 82, 68, 100];

  return (
    <Box
      sx={{
        borderRadius: 3,
        overflow: "hidden",
        border: "1px solid rgba(28,123,130,0.25)",
        background: "rgba(4,12,28,0.85)",
        boxShadow: "0 48px 96px -24px rgba(0,0,0,0.7), 0 0 0 1px rgba(28,123,130,0.15)",
        transform: { md: "perspective(1200px) rotateY(-4deg) rotateX(2deg)" },
        transition: "transform 0.4s ease",
        "&:hover": { transform: "perspective(1200px) rotateY(-1deg) rotateX(0deg)" },
      }}
    >
      {/* Window titlebar */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          px: 1.5,
          py: 1,
          borderBottom: "1px solid rgba(255,255,255,0.06)",
          background: "rgba(3,8,20,0.95)",
          gap: 0.6,
        }}
      >
        {["#ff5f56", "#ffbd2e", "#27c93f"].map((c) => (
          <Box key={c} sx={{ width: 8, height: 8, borderRadius: "50%", bgcolor: c }} />
        ))}
        <Box
          sx={{
            flex: 1,
            mx: 1.5,
            height: 18,
            borderRadius: 1,
            bgcolor: "rgba(255,255,255,0.04)",
            display: "flex",
            alignItems: "center",
            px: 1,
          }}
        >
          <Typography sx={{ fontSize: "0.55rem", color: "rgba(255,255,255,0.25)" }}>
            {t("app.title", { defaultValue: "قضايا" })} &nbsp;·&nbsp; {t("landing.mockup.dashboard", { defaultValue: "لوحة التحكم" })}
          </Typography>
        </Box>
      </Box>

      {/* Body */}
      <Box sx={{ display: "grid", gridTemplateColumns: "44px 1fr", minHeight: 290 }}>
        {/* Sidebar */}
        <Box
          sx={{
            borderInlineEnd: "1px solid rgba(255,255,255,0.05)",
            display: "flex",
            flexDirection: "column",
            gap: 0.75,
            pt: 1.5,
            alignItems: "center",
            bgcolor: "rgba(3,8,20,0.6)",
          }}
        >
          {[...Array(7)].map((_, i) => (
            <Box
              key={i}
              sx={{
                width: 26,
                height: 26,
                borderRadius: 1.5,
                bgcolor: i === 0 ? "rgba(28,123,130,0.3)" : "rgba(255,255,255,0.04)",
                border: i === 0 ? "1px solid rgba(28,123,130,0.45)" : "1px solid transparent",
              }}
            />
          ))}
        </Box>

        {/* Content */}
        <Box sx={{ p: 1.25, overflow: "hidden" }}>
          {/* Stats row */}
          <Box sx={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 0.6, mb: 1.25 }}>
            {statItems.map((s) => (
              <Box
                key={s.label}
                sx={{
                  p: 0.75,
                  borderRadius: 1.5,
                  bgcolor: "rgba(255,255,255,0.04)",
                  border: "1px solid rgba(255,255,255,0.06)",
                }}
              >
                <Typography sx={{ fontSize: "0.5rem", color: "rgba(255,255,255,0.4)", mb: 0.25 }}>
                  {s.label}
                </Typography>
                <Typography sx={{ fontSize: "0.9rem", fontWeight: 900, color: s.color }}>
                  {s.value}
                </Typography>
              </Box>
            ))}
          </Box>

          {/* Case rows */}
          <Box sx={{ mb: 1 }}>
            {caseRows.map((row, i) => (
              <Box
                key={i}
                sx={{
                  display: "flex",
                  alignItems: "center",
                  gap: 0.6,
                  py: 0.45,
                  borderBottom: "1px solid rgba(255,255,255,0.04)",
                }}
              >
                <Box sx={{ width: 5, height: 5, borderRadius: "50%", bgcolor: row.color, flexShrink: 0 }} />
                <Box sx={{ flex: 1, height: 7, borderRadius: 0.5, bgcolor: "rgba(255,255,255,0.06)" }} />
                <Box sx={{ width: 30, height: 7, borderRadius: 0.5, bgcolor: "rgba(255,255,255,0.03)" }} />
                <Box
                  sx={{
                    px: 0.65,
                    py: 0.1,
                    borderRadius: 0.5,
                    bgcolor: `${row.statusColor}20`,
                    border: `1px solid ${row.statusColor}40`,
                  }}
                >
                  <Typography sx={{ fontSize: "0.42rem", color: row.statusColor }}>{row.status}</Typography>
                </Box>
              </Box>
            ))}
          </Box>

          {/* Mini bar chart */}
          <Box
            sx={{
              height: 52,
              borderRadius: 1.5,
              bgcolor: "rgba(255,255,255,0.02)",
              border: "1px solid rgba(255,255,255,0.05)",
              display: "flex",
              alignItems: "flex-end",
              gap: 0.4,
              px: 0.75,
              py: 0.75,
              overflow: "hidden",
            }}
          >
            {bars.map((h, i) => (
              <Box
                key={i}
                sx={{
                  flex: 1,
                  height: `${h}%`,
                  borderRadius: "2px 2px 0 0",
                  background:
                    i >= 10
                      ? tealGradient
                      : `rgba(28,123,130,${0.12 + i * 0.055})`,
                }}
              />
            ))}
          </Box>
        </Box>
      </Box>
    </Box>
  );
}

// ─── Section wrapper helpers ──────────────────────────────────────────────────

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <Typography
      variant="overline"
      sx={{
        fontWeight: 800,
        letterSpacing: "0.2em",
        color: "#14c8d4",
        display: "block",
        mb: 1,
      }}
    >
      {children}
    </Typography>
  );
}

function SectionTitle({ children, light = false }: { children: React.ReactNode; light?: boolean }) {
  return (
    <Typography
      variant="h4"
      sx={{
        fontWeight: 900,
        letterSpacing: "-0.04em",
        color: light ? "rgba(255,255,255,0.95)" : "common.white",
        lineHeight: 1.22,
        mb: 1.5,
        fontSize: { xs: "1.55rem", md: "2rem" },
      }}
    >
      {children}
    </Typography>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function LandingPage() {
  const router = useRouter();
  const theme = useTheme();
  const { t, i18n } = useTranslation();
  const { isAuthenticated, isAuthInitialized } = useAuth();
  const { formatCurrency } = useCurrency();
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
  const [expandedFaq, setExpandedFaq] = useState<string | false>(false);

  useEffect(() => {
    setData(fallbackData);
  }, [fallbackData]);

  useEffect(() => {
    let mounted = true;
    const requestLanguage = getRequestLanguage(currentLanguage);

    (async () => {
      try {
        const [landingResponse, packagesResponse, partnersResponse] = await Promise.all([
          api.get("/LandingPage", { skipTenantHeader: true, headers: { "Accept-Language": requestLanguage } } as any),
          api.get("/SubscriptionPackages/public", { skipTenantHeader: true, headers: { "Accept-Language": requestLanguage } } as any),
          api.get("/Tenants/public-partners", { skipTenantHeader: true, headers: { "Accept-Language": requestLanguage } } as any),
        ]);
        if (mounted) {
          // Build from API to extract config/contact values, but always keep
          // localised text from translation keys so switching language works correctly.
          const apiBuilt = buildLandingData(landingResponse.data, fallbackData);
          setData({
            ...fallbackData,                                              // all text from i18n
            primaryButtonUrl:   apiBuilt.primaryButtonUrl   || fallbackData.primaryButtonUrl,
            secondaryButtonUrl: apiBuilt.secondaryButtonUrl || fallbackData.secondaryButtonUrl,
            contactEmail:       apiBuilt.contactEmail       || fallbackData.contactEmail,
            contactPhone:       apiBuilt.contactPhone       || fallbackData.contactPhone,
            contactAddress:     apiBuilt.contactAddress     || fallbackData.contactAddress,
            contactWorkingHours: apiBuilt.contactWorkingHours || fallbackData.contactWorkingHours,
          });
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

  const updateDemoField = <K extends keyof DemoRequestForm>(field: K, value: DemoRequestForm[K]) => {
    setDemoForm((c) => ({ ...c, [field]: value }));
    setDemoMessage("");
  };

  const submitDemoRequest = async () => {
    setDemoSubmitting(true);
    setDemoMessage("");
    try {
      const response = await api.post("/DemoRequests", demoForm, {
        skipTenantHeader: true,
        headers: { "Accept-Language": getRequestLanguage(currentLanguage) },
      } as any);
      setDemoForm(emptyDemoRequestForm);
      setDemoMessage(response.data?.message || t("landing.demo.success", { defaultValue: "Demo request submitted successfully." }));
    } catch (e: any) {
      setDemoMessage(e?.response?.data?.message || t("landing.demo.failed", { defaultValue: "Failed to submit demo request." }));
    } finally {
      setDemoSubmitting(false);
    }
  };

  // Partner carousel
  const cardsPerPage = 4;
  const startIndex = partners.length > 0 ? partnerPage % partners.length : 0;
  const visiblePartners = partners.length > 0
    ? Array.from({ length: Math.min(cardsPerPage, partners.length) }, (_, i) =>
        partners[(startIndex + i) % partners.length]
      )
    : [];

  // Sorted packages
  const sortedPackages = useMemo(
    () => [...packages].sort((a, b) => a.displayOrder - b.displayOrder),
    [packages]
  );

  // Static data for new sections
  const problemCards = useMemo(() => [
    {
      icon: <AccessTimeIcon sx={{ fontSize: 28 }} />,
      color: "#f59e0b",
      title: t("landing.problems.time.title", { defaultValue: "ضياع الوقت في المتابعة" }),
      description: t("landing.problems.time.description", { defaultValue: "المتابعة اليدوية للقضايا والمواعيد تستنزف وقتك وتزيد من خطر الفوات على أي موعد أو إجراء." }),
      solution: t("landing.problems.time.solution", { defaultValue: "تنبيهات ذكية وذكرى دورية لكل قضية" }),
    },
    {
      icon: <FolderOutlinedIcon sx={{ fontSize: 28 }} />,
      color: "#14c8d4",
      title: t("landing.problems.info.title", { defaultValue: "تشتت المعلومات" }),
      description: t("landing.problems.info.description", { defaultValue: "المعلومات موزعة بين ملفات ورق والبريد الإلكتروني ومحادثات واتساب؛ كل المعلومات في مكان واحد منظم وسهل الوصول." }),
      solution: t("landing.problems.info.solution", { defaultValue: "كل المعلومات في مكان واحد منظم" }),
    },
    {
      icon: <BarChartIcon sx={{ fontSize: 28 }} />,
      color: "#a78bfa",
      title: t("landing.problems.perf.title", { defaultValue: "صعوبة قياس الأداء" }),
      description: t("landing.problems.perf.description", { defaultValue: "غياب التقارير التحليلية يعيق اتخاذ القرارات المبنية على بيانات دقيقة لتطوير أداء الفريق والقضايا." }),
      solution: t("landing.problems.perf.solution", { defaultValue: "تقارير ولوحات مؤشرات أداء دقيقة" }),
    },
  ], [t]);

  const howToSteps = useMemo(() => [
    {
      number: "01",
      icon: <PeopleAltOutlinedIcon sx={{ fontSize: 32 }} />,
      title: t("landing.steps.one.title", { defaultValue: "أنشئ حسابك" }),
      description: t("landing.steps.one.description", { defaultValue: "سجل بكل من بياناتك وعلى الفور ستجد أمامك مساحة جاهزة لمكتبك القانوني." }),
    },
    {
      number: "02",
      icon: <FolderOutlinedIcon sx={{ fontSize: 32 }} />,
      title: t("landing.steps.two.title", { defaultValue: "استورد بياناتك" }),
      description: t("landing.steps.two.description", { defaultValue: "ساعدك في نقل بياناتك بكل سهولة وبياناتك في مكان واحد آمنة وسريعة." }),
    },
    {
      number: "03",
      icon: <BoltIcon sx={{ fontSize: 32 }} />,
      title: t("landing.steps.three.title", { defaultValue: "ابدأ إدارة قضاياك" }),
      description: t("landing.steps.three.description", { defaultValue: "ابدأ فوراً إدارة القضايا والإجراءات والفريق بكفاءة وثقة واستمتع بنتائج ملموسة." }),
    },
  ], [t]);

  const faqItems = useMemo(() => [
    {
      id: "faq1",
      question: t("landing.faq.trial.q", { defaultValue: "هل يمكنني تجربة قضايا قبل الاشتراك؟" }),
      answer: t("landing.faq.trial.a", { defaultValue: "نعم، نقدم فترة تجريبية مجانية تتيح لك الوصول الكامل لميزات المنصة دون الحاجة لبطاقة ائتمانية." }),
    },
    {
      id: "faq2",
      question: t("landing.faq.data.q", { defaultValue: "هل بياناتي آمنة؟" }),
      answer: t("landing.faq.data.a", { defaultValue: "بالتأكيد، نستخدم تشفيراً من الدرجة المصرفية ونلتزم بأعلى معايير أمن المعلومات لحماية بيانات مكتبك وعملائك." }),
    },
    {
      id: "faq3",
      question: t("landing.faq.users.q", { defaultValue: "كيف يتم احتساب المستخدمين؟" }),
      answer: t("landing.faq.users.a", { defaultValue: "يُحتسب كل مستخدم نشط في مكتبك بصرف النظر عن صلاحياته، ويمكنك إضافة وإزالة المستخدمين في أي وقت." }),
    },
    {
      id: "faq4",
      question: t("landing.faq.cancel.q", { defaultValue: "هل يمكنني إلغاء الاشتراك في أي وقت؟" }),
      answer: t("landing.faq.cancel.a", { defaultValue: "نعم، يمكنك إلغاء اشتراكك في أي وقت دون رسوم إضافية، وستبقى بياناتك متاحة حتى نهاية فترة الاشتراك." }),
    },
    {
      id: "faq5",
      question: t("landing.faq.training.q", { defaultValue: "هل تدعمون تدريباً للفريق؟" }),
      answer: t("landing.faq.training.a", { defaultValue: "نعم، نقدم جلسات تأهيل موجهة وموارد تعليمية شاملة لمساعدة فريقك على الاستفادة القصوى من المنصة." }),
    },
    {
      id: "faq6",
      question: t("landing.faq.english.q", { defaultValue: "هل تدعمون اللغة الإنجليزية؟" }),
      answer: t("landing.faq.english.a", { defaultValue: "نعم، المنصة تدعم كلاً من العربية والإنجليزية بشكل كامل مع دعم اتجاه RTL لواجهة المستخدم." }),
    },
  ], [t]);

  const bigStats = useMemo(() => [
    { value: "+250", label: t("landing.stats.lawFirms", { defaultValue: "مكتب قانوني" }) },
    { value: "+10,000", label: t("landing.stats.activeUsers", { defaultValue: "مستخدم نشط" }) },
    { value: "+45,000", label: t("landing.stats.managedCases", { defaultValue: "قضية مُدارة" }) },
    { value: "99.9%", label: t("landing.stats.uptime", { defaultValue: "وقت التشغيل" }) },
    { value: "+98%", label: t("landing.stats.satisfaction", { defaultValue: "رضا العملاء" }) },
  ], [t]);

  const featureHighlights = useMemo(() => [
    {
      icon: <FolderOutlinedIcon sx={{ fontSize: 26 }} />,
      color: "#14c8d4",
      title: t("landing.highlights.cases.title", { defaultValue: "تتبع شامل للقضايا" }),
      description: t("landing.highlights.cases.description", { defaultValue: "عرض موحد لجميع القضايا ومراحلها مع إمكانية التخصيص الكامل لحقول وعمليات سير العمل بما يناسب أحتياجك." }),
    },
    {
      icon: <NotificationsActiveIcon sx={{ fontSize: 26 }} />,
      color: "#f59e0b",
      title: t("landing.highlights.alerts.title", { defaultValue: "تنبيهات للمواعيد الحرة" }),
      description: t("landing.highlights.alerts.description", { defaultValue: "تنبيهات تلقائية عبر المنصة والبريد الإلكتروني لإبلاغك دائماً بخطواتك القادمة قبل كل موعد مهم." }),
    },
    {
      icon: <LockIcon sx={{ fontSize: 26 }} />,
      color: "#a78bfa",
      title: t("landing.highlights.perms.title", { defaultValue: "صلاحيات مرنة وآمنة" }),
      description: t("landing.highlights.perms.description", { defaultValue: "تحكم كامل في الصلاحيات للبيانات حسب الدور مع سجل كامل لضمان الحوكمة الداخلية والسرية." }),
    },
    {
      icon: <InsightsIcon sx={{ fontSize: 26 }} />,
      color: "#10b981",
      title: t("landing.highlights.analytics.title", { defaultValue: "تقارير وتحليلات ذكية" }),
      description: t("landing.highlights.analytics.description", { defaultValue: "لوحات مؤشرات لقطية تساعدك على قياس الأداء واتخاذ القرارات الذكية المبنية على بيانات دقيقة." }),
    },
  ], [t]);

  return (
    <PublicSiteShell
      data={data}
      currentLanguage={currentLanguage}
      onChangeLanguage={changeLanguage}
      onNavigate={navigateTo}
      isAuthenticated={isAuthenticated}
      isAuthInitialized={isAuthInitialized}
      darkMode
      extraHeaderActions={
        <Button
          variant="contained"
          onClick={() => document.getElementById("demo-section")?.scrollIntoView({ behavior: "smooth" })}
          sx={{
            borderRadius: 999,
            fontWeight: 800,
            background: tealGradient,
            px: 2,
            py: 0.7,
            boxShadow: "0 8px 20px -8px rgba(28,123,130,0.5)",
          }}
        >
          {t("landing.demo.bookButton", { defaultValue: "احجز عرضاً توضيحياً" })}
        </Button>
      }
    >
      {error && (
        <Box sx={{ position: "relative", zIndex: 2, pt: 1 }}>
          <Container maxWidth="xl">
            <Alert severity="warning">{error}</Alert>
          </Container>
        </Box>
      )}

      {/* ── HERO ─────────────────────────────────────────────────────── */}
      <Box
        sx={{
          pt: { xs: 8, md: 12 },
          pb: { xs: 6, md: 10 },
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
        {/* Background glow blobs */}
        <Box sx={{ position: "absolute", top: 60, insetInlineStart: "5%", width: 320, height: 320, borderRadius: "50%", background: "rgba(18,58,99,0.18)", filter: "blur(60px)", pointerEvents: "none" }} />
        <Box sx={{ position: "absolute", top: 120, insetInlineEnd: "8%", width: 260, height: 260, borderRadius: "50%", background: "rgba(28,123,130,0.12)", filter: "blur(50px)", pointerEvents: "none" }} />

        <Container maxWidth="xl" sx={{ position: "relative", zIndex: 1 }}>
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", lg: "minmax(0,1fr) minmax(0,1.1fr)" },
              gap: { xs: 5, lg: 6 },
              alignItems: "center",
            }}
          >
            {/* Left text */}
            <Box>
              <Chip
                label={t("landing.badge", { defaultValue: "منصة إدارة المكاتب القانونية" })}
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
                  lineHeight: 1.1,
                  fontSize: { xs: "2.4rem", sm: "3rem", md: "3.8rem" },
                  mb: 2.5,
                }}
              >
                {data.heroTitle}
              </Typography>

              <Typography
                variant="h6"
                sx={{
                  color: "rgba(255,255,255,0.68)",
                  lineHeight: 1.8,
                  fontWeight: 400,
                  fontSize: { xs: "1rem", md: "1.1rem" },
                  maxWidth: 560,
                  mb: 3.5,
                }}
              >
                {data.heroSubtitle}
              </Typography>

              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} sx={{ mb: 4 }}>
                <Button
                  size="large"
                  variant="contained"
                  endIcon={<ArrowOutwardIcon />}
                  onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
                  sx={{
                    px: 3.5,
                    py: 1.2,
                    borderRadius: 999,
                    fontWeight: 800,
                    fontSize: "1rem",
                    background: tealGradient,
                    boxShadow: "0 16px 36px -12px rgba(28,123,130,0.55)",
                    "&:hover": { background: "linear-gradient(135deg, #0f3358 0%, #187479 100%)" },
                  }}
                >
                  {data.primaryButtonText || t("landing.actions.register")}
                </Button>
                <Button
                  size="large"
                  variant="outlined"
                  startIcon={<PlayArrowIcon />}
                  onClick={() => document.getElementById("demo-section")?.scrollIntoView({ behavior: "smooth" })}
                  sx={{
                    px: 3.5,
                    py: 1.2,
                    borderRadius: 999,
                    fontWeight: 800,
                    fontSize: "1rem",
                    color: "rgba(255,255,255,0.9)",
                    borderColor: "rgba(255,255,255,0.22)",
                    "&:hover": { borderColor: "rgba(255,255,255,0.5)", bgcolor: "rgba(255,255,255,0.06)" },
                  }}
                >
                  {t("landing.demo.bookButton", { defaultValue: "احجز عرضاً توضيحياً" })}
                </Button>
              </Stack>

              {/* Social proof row */}
              <Stack direction="row" spacing={2} alignItems="center" flexWrap="wrap">
                <Stack direction="row" spacing={-0.75}>
                  {[...Array(4)].map((_, i) => (
                    <Box
                      key={i}
                      sx={{
                        width: 30,
                        height: 30,
                        borderRadius: "50%",
                        border: "2px solid rgba(255,255,255,0.15)",
                        bgcolor: ["#1c7b82", "#123a63", "#14c8d4", "#0f3358"][i],
                        display: "grid",
                        placeItems: "center",
                      }}
                    >
                      <PeopleAltOutlinedIcon sx={{ fontSize: 14, color: "rgba(255,255,255,0.8)" }} />
                    </Box>
                  ))}
                </Stack>
                <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.6)" }}>
                  {t("landing.heroProof", { defaultValue: "لا تحتاج بطاقة ائتمانية • 14 يوم تجربة مجانية • إلغاء في أي وقت" })}
                </Typography>
              </Stack>
            </Box>

            {/* Right: Dashboard mockup */}
            <Box sx={{ display: { xs: "none", lg: "block" } }}>
              <DashboardMockup t={t} />
            </Box>
          </Box>
        </Container>
      </Box>

      {/* ── PARTNERS LOGOS STRIP ──────────────────────────────────────── */}
      {partners.length > 0 && (
        <Box
          sx={{
            py: 3,
            borderTop: "1px solid rgba(255,255,255,0.06)",
            borderBottom: "1px solid rgba(255,255,255,0.06)",
            bgcolor: "rgba(255,255,255,0.02)",
            overflow: "hidden",
          }}
        >
          <Container maxWidth="xl">
            <Typography
              variant="overline"
              sx={{ color: "rgba(255,255,255,0.35)", letterSpacing: "0.2em", fontWeight: 700, display: "block", textAlign: "center", mb: 2.5 }}
            >
              {t("landing.partners.trustedBy", { defaultValue: "ثق بنا روّاد القطاع القانوني" })}
            </Typography>
            <Box
              sx={{
                display: "flex",
                gap: 3,
                flexWrap: "wrap",
                justifyContent: "center",
                alignItems: "center",
              }}
            >
              {partners.slice(0, 8).map((partner, index) => {
                const logoUrl = toPublicMediaUrl(partner.logoUrl);
                return (
                  <Stack
                    key={partner.id}
                    direction="row"
                    spacing={1}
                    alignItems="center"
                    sx={{
                      px: 2,
                      py: 1,
                      borderRadius: 2,
                      border: "1px solid rgba(255,255,255,0.07)",
                      bgcolor: "rgba(255,255,255,0.03)",
                      transition: "all 0.2s",
                      "&:hover": { bgcolor: "rgba(28,123,130,0.08)", borderColor: "rgba(28,123,130,0.2)" },
                    }}
                  >
                    <Box
                      sx={{
                        width: 28,
                        height: 28,
                        borderRadius: "50%",
                        bgcolor: "rgba(28,123,130,0.15)",
                        display: "grid",
                        placeItems: "center",
                        color: "#14c8d4",
                        flexShrink: 0,
                      }}
                    >
                      {logoUrl ? (
                        <Box component="img" src={logoUrl} alt={partner.name} sx={{ width: 22, height: 22, objectFit: "contain", borderRadius: "50%" }} />
                      ) : (
                        getPartnerIcon(index)
                      )}
                    </Box>
                    <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.7)", fontWeight: 700, whiteSpace: "nowrap" }}>
                      {partner.name}
                    </Typography>
                  </Stack>
                );
              })}
            </Box>
          </Container>
        </Box>
      )}

      {/* ── BIG STATS ────────────────────────────────────────────────── */}
      <Box sx={{ py: { xs: 5, md: 6 }, bgcolor: "rgba(255,255,255,0.015)" }}>
        <Container maxWidth="xl">
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "repeat(2,1fr)", sm: "repeat(3,1fr)", md: "repeat(5,1fr)" },
              gap: 2,
            }}
          >
            {bigStats.map((stat, i) => (
              <Box
                key={stat.label}
                sx={{
                  textAlign: "center",
                  py: 1.75,
                  borderRadius: 3,
                  ...darkCard,
                  transition: "all 0.22s",
                  "&:hover": { borderColor: "rgba(28,123,130,0.25)", bgcolor: "rgba(28,123,130,0.06)" },
                }}
              >
                <Typography
                  sx={{
                    fontSize: { xs: "1.6rem", md: "2rem" },
                    fontWeight: 900,
                    letterSpacing: "-0.04em",
                    background: tealGradient,
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                    mb: 0.5,
                  }}
                >
                  {stat.value}
                </Typography>
                <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.55)", fontWeight: 600 }}>
                  {stat.label}
                </Typography>
              </Box>
            ))}
          </Box>
        </Container>
      </Box>

      {/* ── PROBLEMS SECTION ─────────────────────────────────────────── */}
      <Box sx={{ py: { xs: 7, md: 10 } }}>
        <Container maxWidth="xl">
          <Box sx={{ textAlign: "center", mb: 6 }}>
            <SectionLabel>{t("landing.problems.label", { defaultValue: "حل ذكي لمشكلات يومية" })}</SectionLabel>
            <SectionTitle>{t("landing.problems.title", { defaultValue: "حل لمشكلات يومية معقدة" })}</SectionTitle>
            <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.5)", maxWidth: 540, mx: "auto" }}>
              {t("landing.problems.subtitle", { defaultValue: "قضايا تحوّل أصعب تحديات إدارة مكتبك القانوني إلى سير عمل منظم وفعّال." })}
            </Typography>
          </Box>

          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "repeat(3,1fr)" },
              gap: 2,
            }}
          >
            {problemCards.map((card, i) => (
              <Box
                key={i}
                sx={{
                  p: { xs: 2, md: 2.5 },
                  borderRadius: 4,
                  ...darkCard,
                  transition: "all 0.25s",
                  "&:hover": {
                    borderColor: `${card.color}35`,
                    bgcolor: `${card.color}08`,
                    transform: "translateY(-4px)",
                  },
                }}
              >
                <Box
                  sx={{
                    width: 44,
                    height: 44,
                    borderRadius: 3,
                    display: "grid",
                    placeItems: "center",
                    bgcolor: `${card.color}18`,
                    border: `1px solid ${card.color}30`,
                    color: card.color,
                    mb: 1.75,
                  }}
                >
                  {card.icon}
                </Box>
                <Typography variant="h6" sx={{ fontWeight: 800, color: "common.white", mb: 1.25, letterSpacing: "-0.02em" }}>
                  {card.title}
                </Typography>
                <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.5)", lineHeight: 1.85, mb: 2 }}>
                  {card.description}
                </Typography>
                <Chip
                  icon={<CheckIcon sx={{ fontSize: 14, color: `${card.color} !important` }} />}
                  label={card.solution}
                  size="small"
                  sx={{
                    borderRadius: 999,
                    bgcolor: `${card.color}15`,
                    border: `1px solid ${card.color}30`,
                    color: card.color,
                    fontWeight: 700,
                    fontSize: "0.72rem",
                  }}
                />
              </Box>
            ))}
          </Box>
        </Container>
      </Box>

      {/* ── FEATURES SECTION ─────────────────────────────────────────── */}
      <Box
        sx={{
          py: { xs: 7, md: 10 },
          background: "radial-gradient(ellipse 100% 50% at 50% 100%, rgba(18,58,99,0.18) 0%, transparent 70%)",
          borderTop: "1px solid rgba(255,255,255,0.05)",
          borderBottom: "1px solid rgba(255,255,255,0.05)",
        }}
      >
        <Container maxWidth="xl">
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", lg: "minmax(240px,0.9fr) minmax(0,1fr)" },
              gap: { xs: 5, lg: 8 },
              alignItems: "center",
            }}
          >
            {/* Left: text + API features */}
            <Box>
              <SectionLabel>{t("landing.featuresLabel", { defaultValue: "المميزات" })}</SectionLabel>
              <SectionTitle>{t("landing.featuresTitle", { defaultValue: "كل ما تحتاجه لإدارة قانونية متكاملة" })}</SectionTitle>
              <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.5)", lineHeight: 1.85, mb: 3.5 }}>
                {data.aboutDescription}
              </Typography>
              <Stack spacing={1.5}>
                {(data.features || []).map((feature: LandingFeature, index) => (
                  <Box
                    key={index}
                    sx={{
                      display: "flex",
                      gap: 1.25,
                      p: 1.25,
                      borderRadius: 3,
                      ...darkCard,
                      transition: "all 0.2s",
                      "&:hover": { borderColor: "rgba(28,123,130,0.25)", bgcolor: "rgba(28,123,130,0.06)" },
                    }}
                  >
                    <Box
                      sx={{
                        width: 34,
                        height: 34,
                        borderRadius: 2,
                        display: "grid",
                        placeItems: "center",
                        bgcolor: "rgba(28,123,130,0.15)",
                        color: "#14c8d4",
                        flexShrink: 0,
                      }}
                    >
                      {getFeatureIcon(feature.iconKey, 20)}
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" sx={{ fontWeight: 800, color: "common.white", mb: 0.25 }}>
                        {feature.title}
                      </Typography>
                      <Typography variant="caption" sx={{ color: "rgba(255,255,255,0.5)", lineHeight: 1.7 }}>
                        {feature.description}
                      </Typography>
                    </Box>
                  </Box>
                ))}
              </Stack>
            </Box>

            {/* Right: highlight cards grid */}
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "repeat(2,1fr)",
                gap: 2,
              }}
            >
              {featureHighlights.map((f, i) => (
                <Box
                  key={i}
                  sx={{
                    p: 2,
                    borderRadius: 4,
                    ...darkCard,
                    transition: "all 0.25s",
                    "&:hover": {
                      borderColor: `${f.color}30`,
                      bgcolor: `${f.color}06`,
                      transform: "translateY(-4px)",
                    },
                  }}
                >
                  <Box
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: 2.5,
                      display: "grid",
                      placeItems: "center",
                      bgcolor: `${f.color}18`,
                      border: `1px solid ${f.color}28`,
                      color: f.color,
                      mb: 1.5,
                    }}
                  >
                    {f.icon}
                  </Box>
                  <Typography variant="subtitle1" sx={{ fontWeight: 800, color: "common.white", mb: 0.75, letterSpacing: "-0.02em" }}>
                    {f.title}
                  </Typography>
                  <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.48)", lineHeight: 1.8, fontSize: "0.82rem" }}>
                    {f.description}
                  </Typography>
                </Box>
              ))}
            </Box>
          </Box>
        </Container>
      </Box>

      {/* ── HOW TO START ─────────────────────────────────────────────── */}
      <Box sx={{ py: { xs: 7, md: 10 } }}>
        <Container maxWidth="xl">
          <Box sx={{ textAlign: "center", mb: 6 }}>
            <SectionLabel>{t("landing.steps.label", { defaultValue: "البداية بسيطة" })}</SectionLabel>
            <SectionTitle>{t("landing.steps.title", { defaultValue: "كيف تبدأ مع قضايا؟" })}</SectionTitle>
          </Box>

          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "repeat(3,1fr)" },
              gap: 2,
              position: "relative",
            }}
          >
            {howToSteps.map((step, i) => (
              <Box
                key={i}
                sx={{
                  p: { xs: 2, md: 2.5 },
                  borderRadius: 4,
                  ...darkCard,
                  position: "relative",
                  overflow: "hidden",
                  transition: "all 0.25s",
                  "&:hover": { borderColor: "rgba(28,123,130,0.3)", transform: "translateY(-4px)" },
                }}
              >
                {/* Big step number in background */}
                <Typography
                  sx={{
                    position: "absolute",
                    top: -8,
                    insetInlineEnd: 16,
                    fontSize: "6rem",
                    fontWeight: 900,
                    color: "rgba(255,255,255,0.03)",
                    letterSpacing: "-0.06em",
                    userSelect: "none",
                    lineHeight: 1,
                  }}
                >
                  {step.number}
                </Typography>

                <Chip
                  label={step.number}
                  size="small"
                  sx={{
                    mb: 2,
                    bgcolor: "rgba(28,123,130,0.15)",
                    color: "#14c8d4",
                    border: "1px solid rgba(28,123,130,0.3)",
                    fontWeight: 900,
                    borderRadius: 999,
                  }}
                />
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 3,
                    display: "grid",
                    placeItems: "center",
                    background: tealGradient,
                    color: "common.white",
                    mb: 2,
                    boxShadow: "0 10px 22px -8px rgba(28,123,130,0.45)",
                  }}
                >
                  {step.icon}
                </Box>
                <Typography variant="h6" sx={{ fontWeight: 800, color: "common.white", mb: 1.25, letterSpacing: "-0.03em" }}>
                  {step.title}
                </Typography>
                <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.5)", lineHeight: 1.85 }}>
                  {step.description}
                </Typography>
              </Box>
            ))}
          </Box>
        </Container>
      </Box>

      {/* ── TESTIMONIAL ──────────────────────────────────────────────── */}
      <Box
        sx={{
          py: { xs: 7, md: 9 },
          background: "linear-gradient(135deg, rgba(18,58,99,0.22) 0%, rgba(28,123,130,0.14) 100%)",
          borderTop: "1px solid rgba(255,255,255,0.06)",
          borderBottom: "1px solid rgba(255,255,255,0.06)",
        }}
      >
        <Container maxWidth="md">
          <Box sx={{ textAlign: "center" }}>
            <Typography
              sx={{
                fontSize: { xs: "2rem", md: "3rem" },
                color: "#1c7b82",
                opacity: 0.6,
                lineHeight: 1,
                mb: 2,
                fontFamily: "Georgia, serif",
              }}
            >
              &quot;
            </Typography>
            <Typography
              variant="h5"
              sx={{
                fontWeight: 600,
                color: "rgba(255,255,255,0.88)",
                lineHeight: 1.75,
                fontStyle: "italic",
                mb: 3.5,
                fontSize: { xs: "1.1rem", md: "1.3rem" },
              }}
            >
              {t("landing.testimonial.quote", {
                defaultValue:
                  "قضايا غيّرت طريقة عملنا بالكامل. أصبحنا أكثر تنظيماً، وانخفضت الأخطاء، وزادت إنتاجية الفريق بشكل ملحوظ.",
              })}
            </Typography>
            <Stack direction="row" spacing={1.5} alignItems="center" justifyContent="center">
              <Box
                sx={{
                  width: 44,
                  height: 44,
                  borderRadius: "50%",
                  background: tealGradient,
                  display: "grid",
                  placeItems: "center",
                  color: "common.white",
                  fontWeight: 800,
                  fontSize: "1rem",
                }}
              >
                أ
              </Box>
              <Box sx={{ textAlign: isRTL ? "right" : "left" }}>
                <Typography variant="subtitle2" sx={{ color: "common.white", fontWeight: 800 }}>
                  {t("landing.testimonial.name", { defaultValue: "أشرف الحمزي" })}
                </Typography>
                <Typography variant="caption" sx={{ color: "rgba(255,255,255,0.45)" }}>
                  {t("landing.testimonial.role", { defaultValue: "شريك مؤسس · مكتب القمر للمحاماة" })}
                </Typography>
              </Box>
            </Stack>
          </Box>
        </Container>
      </Box>

      {/* ── PRICING ──────────────────────────────────────────────────── */}
      <Box
        sx={{
          py: { xs: 8, md: 12 },
          position: "relative",
          overflow: "hidden",
          background: "linear-gradient(180deg, transparent 0%, rgba(8,24,58,0.5) 40%, rgba(8,24,58,0.5) 60%, transparent 100%)",
          borderTop: "1px solid rgba(255,255,255,0.05)",
          borderBottom: "1px solid rgba(255,255,255,0.05)",
        }}
      >
        {/* Background glow blobs */}
        <Box sx={{ position: "absolute", top: "15%", left: "50%", transform: "translateX(-50%)", width: 700, height: 700, borderRadius: "50%", background: "radial-gradient(circle, rgba(28,123,130,0.1) 0%, transparent 70%)", filter: "blur(60px)", pointerEvents: "none" }} />
        <Box sx={{ position: "absolute", bottom: "10%", insetInlineStart: "10%", width: 300, height: 300, borderRadius: "50%", background: "rgba(18,58,99,0.18)", filter: "blur(80px)", pointerEvents: "none" }} />
        <Box sx={{ position: "absolute", top: "5%", insetInlineEnd: "8%", width: 240, height: 240, borderRadius: "50%", background: "rgba(28,123,130,0.08)", filter: "blur(70px)", pointerEvents: "none" }} />

        <Container maxWidth="xl" sx={{ position: "relative", zIndex: 1 }}>
          {/* Section header */}
          <Box sx={{ textAlign: "center", mb: 7 }}>
            <SectionLabel>{t("subscription.pricingTitle", { defaultValue: "باقات الاشتراك" })}</SectionLabel>
            <SectionTitle>{t("landing.pricing.title", { defaultValue: "خطط مرنة تناسب احتياجاتك" })}</SectionTitle>
            <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.5)", maxWidth: 500, mx: "auto", lineHeight: 1.8 }}>
              {t("landing.pricing.subtitle", { defaultValue: "جميع الخطط تشمل خدمات مُستمرة ودعماً متخصصاً وتجربة سلسة من اليوم الأول." })}
            </Typography>
          </Box>

          {/* Package cards */}
          {sortedPackages.length > 0 ? (() => {
            // Determine which single card to feature — the highest-priced one
            const maxPrice = Math.max(
              ...sortedPackages.map((p) => (p.annualOption ?? p.monthlyOption)?.price ?? 0)
            );
            return (
              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: {
                    xs: "1fr",
                    md: sortedPackages.length === 2 ? "repeat(2,1fr)" : "repeat(3,1fr)",
                  },
                  gap: { xs: 3, md: 4 },
                  alignItems: "center",
                  maxWidth: sortedPackages.length === 2 ? 820 : "100%",
                  mx: "auto",
                }}
              >
                {sortedPackages.map((pkg, i) => {
                  const option = pkg.annualOption ?? pkg.monthlyOption;
                  const isAnnual = Boolean(pkg.annualOption);
                  const cycleLabel = isAnnual
                    ? t("subscription.billingCycle.annual", { defaultValue: "سنوي" })
                    : t("subscription.billingCycle.monthly", { defaultValue: "شهري" });
                  // Only the single most-expensive package is featured
                  const isFeatured = (option?.price ?? 0) === maxPrice;

                  return (
                    <Box
                      key={i}
                      sx={{
                        position: "relative",
                        borderRadius: 5,
                        overflow: "visible",
                        // Push featured card up slightly
                        mt: isFeatured ? { md: -2 } : 0,
                      }}
                    >
                      {/* Outer glow for featured */}
                      {isFeatured && (
                        <Box
                          sx={{
                            position: "absolute",
                            inset: -1,
                            borderRadius: 5,
                            background: "linear-gradient(135deg, rgba(28,123,130,0.6) 0%, rgba(20,200,212,0.3) 100%)",
                            filter: "blur(18px)",
                            opacity: 0.55,
                            zIndex: 0,
                            pointerEvents: "none",
                          }}
                        />
                      )}

                      <Box
                        sx={{
                          position: "relative",
                          zIndex: 1,
                          borderRadius: 5,
                          overflow: "hidden",
                          border: isFeatured
                            ? "1.5px solid rgba(28,123,130,0.55)"
                            : "1px solid rgba(255,255,255,0.09)",
                          background: isFeatured
                            ? "linear-gradient(155deg, rgba(10,36,74,0.98) 0%, rgba(12,72,82,0.96) 100%)"
                            : "rgba(255,255,255,0.035)",
                          backdropFilter: "blur(12px)",
                          boxShadow: isFeatured
                            ? "0 40px 80px -20px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.06)"
                            : "0 8px 32px -8px rgba(0,0,0,0.4)",
                          transition: "transform 0.3s ease, box-shadow 0.3s ease",
                          "&:hover": {
                            transform: "translateY(-6px)",
                            boxShadow: isFeatured
                              ? "0 56px 96px -24px rgba(28,123,130,0.5), inset 0 1px 0 rgba(255,255,255,0.08)"
                              : "0 24px 56px -12px rgba(0,0,0,0.5)",
                          },
                        }}
                      >
                        {/* Featured banner */}
                        {isFeatured && (
                          <Box
                            sx={{
                              textAlign: "center",
                              py: 0.75,
                              background: "linear-gradient(90deg, rgba(18,58,99,0) 0%, rgba(28,123,130,0.9) 20%, rgba(20,200,212,0.9) 50%, rgba(28,123,130,0.9) 80%, rgba(18,58,99,0) 100%)",
                            }}
                          >
                            <Stack direction="row" spacing={0.75} justifyContent="center" alignItems="center">
                              <WorkspacePremiumIcon sx={{ fontSize: 14, color: "common.white" }} />
                              <Typography variant="caption" sx={{ fontWeight: 900, color: "common.white", letterSpacing: "0.12em", fontSize: "0.72rem" }}>
                                {t("subscription.bestValue", { defaultValue: "الأكثر تميزاً" })}
                              </Typography>
                            </Stack>
                          </Box>
                        )}

                        {/* Card body */}
                        <Box sx={{ p: { xs: 2.5, md: 3 } }}>

                          {/* Icon + cycle badge row */}
                          <Stack direction="row" justifyContent="space-between" alignItems="flex-start" sx={{ mb: 2.5 }}>
                            <Box
                              sx={{
                                width: 48,
                                height: 48,
                                borderRadius: 3,
                                display: "grid",
                                placeItems: "center",
                                background: isFeatured
                                  ? "linear-gradient(135deg, rgba(18,58,99,0.8) 0%, rgba(28,123,130,0.8) 100%)"
                                  : "rgba(255,255,255,0.06)",
                                border: isFeatured ? "1px solid rgba(28,123,130,0.4)" : "1px solid rgba(255,255,255,0.1)",
                                color: isFeatured ? "#14c8d4" : "rgba(255,255,255,0.5)",
                                boxShadow: isFeatured ? "0 8px 20px -6px rgba(28,123,130,0.5)" : "none",
                              }}
                            >
                              {isAnnual
                                ? <CalendarMonthIcon sx={{ fontSize: 24 }} />
                                : <RepeatIcon sx={{ fontSize: 24 }} />
                              }
                            </Box>
                            <Chip
                              label={cycleLabel}
                              size="small"
                              sx={{
                                fontWeight: 800,
                                borderRadius: 999,
                                fontSize: "0.75rem",
                                px: 0.5,
                                bgcolor: isFeatured ? "rgba(20,200,212,0.12)" : "rgba(255,255,255,0.06)",
                                color: isFeatured ? "#14c8d4" : "rgba(255,255,255,0.5)",
                                border: isFeatured ? "1px solid rgba(20,200,212,0.3)" : "1px solid rgba(255,255,255,0.1)",
                              }}
                            />
                          </Stack>

                          {/* Name & description */}
                          <Typography
                            variant="h5"
                            sx={{
                              fontWeight: 900,
                              color: "common.white",
                              letterSpacing: "-0.04em",
                              mb: 0.75,
                              lineHeight: 1.25,
                            }}
                          >
                            {pkg.name}
                          </Typography>
                          <Typography
                            variant="body2"
                            sx={{ color: "rgba(255,255,255,0.48)", lineHeight: 1.75, mb: 3 }}
                          >
                            {pkg.description}
                          </Typography>

                          {/* Price block */}
                          {option ? (
                            <Box
                              sx={{
                                py: 2.5,
                                px: 2,
                                mb: 3,
                                borderRadius: 3,
                                background: isFeatured
                                  ? "rgba(28,123,130,0.1)"
                                  : "rgba(255,255,255,0.03)",
                                border: isFeatured
                                  ? "1px solid rgba(28,123,130,0.2)"
                                  : "1px solid rgba(255,255,255,0.06)",
                                textAlign: "center",
                              }}
                            >
                              <Typography
                                sx={{
                                  fontSize: { xs: "2.6rem", md: "3rem" },
                                  fontWeight: 900,
                                  letterSpacing: "-0.05em",
                                  lineHeight: 1,
                                  color: isFeatured ? "#14c8d4" : "common.white",
                                  background: isFeatured
                                    ? "linear-gradient(135deg, #14c8d4 0%, #20e8d8 60%, #14c8d4 100%)"
                                    : undefined,
                                  WebkitBackgroundClip: isFeatured ? "text" : undefined,
                                  WebkitTextFillColor: isFeatured ? "transparent" : undefined,
                                  mb: 0.5,
                                }}
                              >
                                {formatCurrency(option.price)}
                              </Typography>
                              <Typography
                                variant="caption"
                                sx={{ color: "rgba(255,255,255,0.38)", fontWeight: 600, letterSpacing: "0.04em" }}
                              >
                                / {cycleLabel}
                              </Typography>
                            </Box>
                          ) : null}

                          {/* Features list */}
                          <Stack spacing={1.1} sx={{ mb: 3.5 }}>
                            {(pkg.features || []).map((f) => (
                              <Stack key={f} direction="row" spacing={1.25} alignItems="flex-start">
                                <Box
                                  sx={{
                                    width: 18,
                                    height: 18,
                                    borderRadius: "50%",
                                    display: "grid",
                                    placeItems: "center",
                                    flexShrink: 0,
                                    mt: 0.15,
                                    bgcolor: isFeatured ? "rgba(20,200,212,0.15)" : "rgba(16,185,129,0.12)",
                                    border: isFeatured ? "1px solid rgba(20,200,212,0.3)" : "1px solid rgba(16,185,129,0.25)",
                                  }}
                                >
                                  <CheckIcon sx={{ fontSize: 11, color: isFeatured ? "#14c8d4" : "#10b981" }} />
                                </Box>
                                <Typography
                                  variant="body2"
                                  sx={{ color: "rgba(255,255,255,0.72)", lineHeight: 1.65, fontSize: "0.845rem" }}
                                >
                                  {f}
                                </Typography>
                              </Stack>
                            ))}
                          </Stack>

                          {/* CTA button */}
                          <Button
                            variant="contained"
                            fullWidth
                            onClick={() => router.push("/register")}
                            endIcon={<ArrowOutwardIcon sx={{ fontSize: "1rem !important" }} />}
                            sx={{
                              borderRadius: 999,
                              fontWeight: 800,
                              py: 1.3,
                              fontSize: "0.95rem",
                              background: isFeatured
                                ? tealGradient
                                : "rgba(255,255,255,0.07)",
                              color: "common.white",
                              border: isFeatured ? "none" : "1px solid rgba(255,255,255,0.14)",
                              boxShadow: isFeatured
                                ? "0 16px 36px -10px rgba(28,123,130,0.55)"
                                : "none",
                              "&:hover": {
                                background: isFeatured
                                  ? "linear-gradient(135deg, #0f3358 0%, #156e74 100%)"
                                  : "rgba(255,255,255,0.12)",
                                boxShadow: isFeatured ? "0 20px 44px -12px rgba(28,123,130,0.65)" : "none",
                              },
                            }}
                          >
                            {t("subscription.choosePackage", { defaultValue: "ابدأ الآن" })}
                          </Button>
                        </Box>
                      </Box>
                    </Box>
                  );
                })}
              </Box>
            );
          })() : (
            <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.3)", textAlign: "center" }}>
              {t("landing.pricing.noPackages", { defaultValue: "سيتم عرض الخطط قريباً" })}
            </Typography>
          )}

          {/* Bottom trust line */}
          <Stack direction="row" spacing={3} justifyContent="center" alignItems="center" flexWrap="wrap" sx={{ mt: 5, gap: 2 }}>
            {[
              t("landing.pricing.trustNoCard", { defaultValue: "لا حاجة لبطاقة ائتمانية" }),
              t("landing.pricing.trustCancel", { defaultValue: "إلغاء في أي وقت" }),
              t("landing.pricing.trustSupport", { defaultValue: "دعم مستمر طوال الاشتراك" }),
            ].map((text) => (
              <Stack key={text} direction="row" spacing={0.75} alignItems="center">
                <CheckIcon sx={{ fontSize: 14, color: "#1c7b82" }} />
                <Typography variant="caption" sx={{ color: "rgba(255,255,255,0.38)", fontWeight: 600 }}>
                  {text}
                </Typography>
              </Stack>
            ))}
          </Stack>
        </Container>
      </Box>

      {/* ── FAQ ──────────────────────────────────────────────────────── */}
      <Box
        sx={{
          py: { xs: 7, md: 10 },
          borderTop: "1px solid rgba(255,255,255,0.05)",
          background: "rgba(255,255,255,0.015)",
        }}
      >
        <Container maxWidth="md">
          <Box sx={{ textAlign: "center", mb: 5 }}>
            <SectionLabel>{t("landing.faq.label", { defaultValue: "الأسئلة الشائعة" })}</SectionLabel>
            <SectionTitle>{t("landing.faq.title", { defaultValue: "الأسئلة الشائعة" })}</SectionTitle>
          </Box>

          <Stack spacing={1.5}>
            {faqItems.map((item) => (
              <Accordion
                key={item.id}
                expanded={expandedFaq === item.id}
                onChange={(_, expanded) => setExpandedFaq(expanded ? item.id : false)}
                disableGutters
                elevation={0}
                sx={{
                  background: "rgba(255,255,255,0.04)",
                  border: "1px solid",
                  borderColor: expandedFaq === item.id ? "rgba(28,123,130,0.35)" : "rgba(255,255,255,0.08)",
                  borderRadius: "12px !important",
                  overflow: "hidden",
                  transition: "border-color 0.2s",
                  "&:before": { display: "none" },
                }}
              >
                <AccordionSummary
                  expandIcon={<ExpandMoreIcon sx={{ color: expandedFaq === item.id ? "#14c8d4" : "rgba(255,255,255,0.4)" }} />}
                  sx={{
                    px: 2.5,
                    py: 0.5,
                    "& .MuiAccordionSummary-content": { my: 1.5 },
                  }}
                >
                  <Typography variant="subtitle1" sx={{ fontWeight: 700, color: expandedFaq === item.id ? "#14c8d4" : "rgba(255,255,255,0.88)" }}>
                    {item.question}
                  </Typography>
                </AccordionSummary>
                <AccordionDetails sx={{ px: 2.5, pb: 2.5, pt: 0 }}>
                  <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.55)", lineHeight: 1.85 }}>
                    {item.answer}
                  </Typography>
                </AccordionDetails>
              </Accordion>
            ))}
          </Stack>
        </Container>
      </Box>

      {/* ── DEMO REQUEST FORM ─────────────────────────────────────────── */}
      <Box
        id="demo-section"
        sx={{
          py: { xs: 7, md: 10 },
          background: "linear-gradient(135deg, rgba(12,36,68,0.6) 0%, rgba(14,70,80,0.5) 100%)",
          borderTop: "1px solid rgba(28,123,130,0.15)",
        }}
      >
        <Container maxWidth="lg">
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "minmax(0,1fr) minmax(360px,0.9fr)" },
              gap: { xs: 4, md: 0 },
              borderRadius: 5,
              overflow: "hidden",
              border: "1px solid rgba(28,123,130,0.2)",
              boxShadow: "0 40px 80px -24px rgba(0,0,0,0.5)",
            }}
          >
            {/* Left info */}
            <Box
              sx={{
                p: { xs: 2.5, md: 3 },
                background: "linear-gradient(135deg, rgba(8,24,52,1) 0%, rgba(10,60,68,0.98) 100%)",
              }}
            >
              <Chip
                label={t("landing.demo.bookButton", { defaultValue: "احجز عرضاً توضيحياً" })}
                sx={{ mb: 2.5, bgcolor: "rgba(28,123,130,0.2)", color: "#14c8d4", border: "1px solid rgba(28,123,130,0.35)", fontWeight: 800 }}
              />
              <Typography variant="h4" sx={{ fontWeight: 900, color: "common.white", letterSpacing: "-0.04em", mb: 1.5, fontSize: { xs: "1.5rem", md: "2rem" } }}>
                {t("landing.demo.title", { defaultValue: "جاهز للسيطرة على قضاياك؟" })}
              </Typography>
              <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.6)", lineHeight: 1.85, mb: 3.5 }}>
                {t("landing.demo.subtitle", { defaultValue: "انضم إلى مئات المكاتب القانونية التي تثق في قضايا. ابدأ تجربتك المجانية اليوم." })}
              </Typography>
              <Stack spacing={1.5}>
                {[
                  { label: t("landing.contact.email"), value: data.contactEmail || "-" },
                  { label: t("landing.contact.phone"), value: data.contactPhone || "-" },
                  { label: t("landing.contact.workingHours"), value: data.contactWorkingHours || "-" },
                ].map((item) => (
                  <Stack key={item.label} direction="row" spacing={1} alignItems="center">
                    <CheckIcon sx={{ fontSize: 16, color: "#14c8d4" }} />
                    <Typography variant="body2" sx={{ color: "rgba(255,255,255,0.6)" }}>
                      <strong style={{ color: "rgba(255,255,255,0.8)" }}>{item.label}:</strong> {item.value}
                    </Typography>
                  </Stack>
                ))}
              </Stack>
            </Box>

            {/* Right form */}
            <Box
              sx={{
                p: { xs: 2.5, md: 3 },
                bgcolor: "rgba(6,14,30,0.97)",
                display: "grid",
                gap: 1.75,
                alignContent: "start",
              }}
            >
              {[
                { field: "fullName" as const, label: t("landing.demo.fields.fullName", { defaultValue: "الاسم الكامل" }) },
                { field: "officeName" as const, label: t("landing.demo.fields.officeName", { defaultValue: "اسم المكتب" }) },
                { field: "email" as const, label: t("landing.demo.fields.email", { defaultValue: "البريد الإلكتروني" }) },
                { field: "phoneNumber" as const, label: t("landing.demo.fields.phoneNumber", { defaultValue: "رقم الهاتف" }) },
              ].map(({ field, label }) => (
                <TextField
                  key={field}
                  label={label}
                  value={demoForm[field]}
                  onChange={(e) => updateDemoField(field, e.target.value)}
                  fullWidth
                  sx={{
                    "& .MuiOutlinedInput-root": {
                      color: "rgba(255,255,255,0.9)",
                      "& fieldset": { borderColor: "rgba(255,255,255,0.12)" },
                      "&:hover fieldset": { borderColor: "rgba(28,123,130,0.4)" },
                      "&.Mui-focused fieldset": { borderColor: "#1c7b82" },
                    },
                    "& .MuiInputLabel-root": { color: "rgba(255,255,255,0.4)" },
                    "& .MuiInputLabel-root.Mui-focused": { color: "#14c8d4" },
                  }}
                />
              ))}
              <TextField
                label={t("landing.demo.fields.notes", { defaultValue: "ملاحظات" })}
                value={demoForm.notes}
                onChange={(e) => updateDemoField("notes", e.target.value)}
                fullWidth
                multiline
                minRows={3}
                sx={{
                  "& .MuiOutlinedInput-root": {
                    color: "rgba(255,255,255,0.9)",
                    "& fieldset": { borderColor: "rgba(255,255,255,0.12)" },
                    "&:hover fieldset": { borderColor: "rgba(28,123,130,0.4)" },
                    "&.Mui-focused fieldset": { borderColor: "#1c7b82" },
                  },
                  "& .MuiInputLabel-root": { color: "rgba(255,255,255,0.4)" },
                  "& .MuiInputLabel-root.Mui-focused": { color: "#14c8d4" },
                }}
              />
              {demoMessage && (
                <Alert
                  severity={demoMessage.toLowerCase().includes("success") || demoMessage.toLowerCase().includes("submitted") ? "success" : "info"}
                >
                  {demoMessage}
                </Alert>
              )}
              <Button
                variant="contained"
                onClick={submitDemoRequest}
                disabled={demoSubmitting}
                size="large"
                sx={{
                  borderRadius: 999,
                  fontWeight: 800,
                  py: 1.3,
                  background: tealGradient,
                  boxShadow: "0 16px 36px -12px rgba(28,123,130,0.55)",
                  "&:hover": { background: "linear-gradient(135deg, #0f3358 0%, #187479 100%)" },
                }}
              >
                {t("landing.demo.submit", { defaultValue: "إرسال طلب العرض" })}
              </Button>
            </Box>
          </Box>
        </Container>
      </Box>

      {/* ── BOTTOM CTA ───────────────────────────────────────────────── */}
      <Box
        sx={{
          py: { xs: 8, md: 12 },
          textAlign: "center",
          position: "relative",
          overflow: "hidden",
          "&::before": {
            content: '""',
            position: "absolute",
            inset: 0,
            background: "radial-gradient(ellipse 70% 80% at 50% 100%, rgba(28,123,130,0.16) 0%, transparent 70%)",
            pointerEvents: "none",
          },
        }}
      >
        <Container maxWidth="md" sx={{ position: "relative", zIndex: 1 }}>
          <WorkspacePremiumIcon sx={{ fontSize: 40, color: "#1c7b82", opacity: 0.6, mb: 2 }} />
          <Typography
            variant="h3"
            sx={{
              fontWeight: 900,
              color: "common.white",
              letterSpacing: "-0.04em",
              lineHeight: 1.15,
              mb: 2,
              fontSize: { xs: "1.8rem", md: "2.6rem" },
            }}
          >
            {t("landing.cta.title", { defaultValue: "جاهز للسيطرة على قضاياك؟" })}
          </Typography>
          <Typography variant="body1" sx={{ color: "rgba(255,255,255,0.5)", mb: 4, maxWidth: 480, mx: "auto" }}>
            {t("landing.cta.subtitle", { defaultValue: "انضم إلى مئات المكاتب القانونية. ابدأ تجربتك المجانية الآن." })}
          </Typography>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2} justifyContent="center">
            <Button
              size="large"
              variant="contained"
              endIcon={<ArrowOutwardIcon />}
              onClick={() => navigateTo(data.primaryButtonUrl || "/register")}
              sx={{
                px: 4,
                py: 1.3,
                borderRadius: 999,
                fontWeight: 800,
                fontSize: "1rem",
                background: tealGradient,
                boxShadow: "0 16px 36px -12px rgba(28,123,130,0.55)",
                "&:hover": { background: "linear-gradient(135deg, #0f3358 0%, #187479 100%)" },
              }}
            >
              {t("landing.cta.startTrial", { defaultValue: "ابدأ التجربة مجاناً" })}
            </Button>
            <Button
              size="large"
              variant="outlined"
              onClick={() => document.getElementById("demo-section")?.scrollIntoView({ behavior: "smooth" })}
              sx={{
                px: 4,
                py: 1.3,
                borderRadius: 999,
                fontWeight: 800,
                fontSize: "1rem",
                color: "rgba(255,255,255,0.85)",
                borderColor: "rgba(255,255,255,0.2)",
                "&:hover": { borderColor: "rgba(255,255,255,0.45)", bgcolor: "rgba(255,255,255,0.05)" },
              }}
            >
              {t("landing.demo.bookButton", { defaultValue: "احجز عرضاً توضيحياً" })}
            </Button>
          </Stack>
        </Container>
      </Box>
    </PublicSiteShell>
  );
}
