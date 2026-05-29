"use client";

import React from "react";
import { usePathname } from "next/navigation";
import { useTranslation } from "react-i18next";
import {
  Box,
  Button,
  Container,
  Link,
  Stack,
  Typography,
  alpha,
  useTheme,
} from "@mui/material";
import { Balance as BalanceIcon } from "@mui/icons-material";
import type { LandingPageData } from "../../services/publicSite";
import { brandGradient, BRAND_TEAL_END } from "../../brand";

type PublicSiteShellProps = {
  data: LandingPageData;
  currentLanguage: "ar" | "en";
  onChangeLanguage: (language: "ar" | "en") => void;
  onNavigate: (target?: string) => void;
  isAuthenticated: boolean;
  isAuthInitialized: boolean;
  children: React.ReactNode;
  extraHeaderActions?: React.ReactNode;
  darkMode?: boolean;
};

export default function PublicSiteShell({
  data,
  currentLanguage,
  onChangeLanguage,
  onNavigate,
  isAuthenticated,
  isAuthInitialized,
  children,
  extraHeaderActions,
  darkMode = false,
}: PublicSiteShellProps) {
  const theme = useTheme();
  const { t } = useTranslation();
  const isRTL = currentLanguage === "ar";
  const pathname = usePathname();

  const navLinks = [
    { label: t("landing.footer.links.home"), path: "/" },
    { label: t("landing.footer.links.aboutUs"), path: "/about-us" },
    { label: t("landing.footer.links.contactUs"), path: "/contact-us" },
  ];

  const footerLinks = [
    ...navLinks,
    { label: t("landing.footer.links.register"), path: data.primaryButtonUrl || "/register" },
    {
      label: isAuthenticated ? t("landing.footer.links.dashboard") : t("landing.footer.links.login"),
      path: isAuthenticated ? "/dashboard" : data.secondaryButtonUrl || "/login",
    },
  ];

  const isActivePath = (path: string) => pathname === path;

  const headerBg = darkMode ? alpha("#030d1e", 0.92) : alpha("#ffffff", 0.84);
  const headerBorderColor = darkMode ? alpha(BRAND_TEAL_END, 0.18) : alpha(theme.palette.primary.main, 0.12);
  const headerGradientLine = darkMode
    ? "linear-gradient(90deg, rgba(28,123,130,0) 0%, rgba(28,123,130,0.45) 35%, rgba(28,123,130,0) 100%)"
    : "linear-gradient(90deg, rgba(18,58,99,0) 0%, rgba(28,123,130,0.34) 35%, rgba(18,58,99,0) 100%)";

  const navPillBg = darkMode ? alpha("#ffffff", 0.04) : alpha(theme.palette.primary.main, 0.05);
  const navPillBorder = darkMode ? alpha("#ffffff", 0.08) : alpha(theme.palette.primary.main, 0.08);
  const navLinkColor = darkMode ? "rgba(255,255,255,0.85)" : "text.primary";
  const navLinkActive = darkMode ? "rgba(255,255,255,1)" : "primary.main";
  const navLinkActiveBg = darkMode ? alpha(BRAND_TEAL_END, 0.22) : alpha(theme.palette.primary.main, 0.12);
  const navLinkHoverBg = darkMode ? alpha("#ffffff", 0.06) : alpha(theme.palette.primary.main, 0.08);
  const logoNameColor = darkMode ? "common.white" : "text.primary";
  const langPillBg = darkMode ? alpha("#ffffff", 0.06) : alpha(theme.palette.primary.main, 0.06);

  return (
    <Box
      dir={isRTL ? "rtl" : "ltr"}
      sx={{
        minHeight: "100vh",
        background: darkMode
          ? "linear-gradient(180deg, #050d1a 0%, #060f1c 100%)"
          : "radial-gradient(circle at top, rgba(21,93,117,0.22) 0%, rgba(21,93,117,0) 34%), linear-gradient(180deg, #f3f8fb 0%, #ffffff 42%, #edf3f7 100%)",
      }}
    >
      {/* Header */}
      <Box
        sx={{
          position: "sticky",
          top: 0,
          zIndex: 10,
          backdropFilter: "blur(20px)",
          backgroundColor: headerBg,
          borderBottom: "1px solid",
          borderColor: headerBorderColor,
          boxShadow: darkMode
            ? "0 8px 32px -20px rgba(0,0,0,0.6)"
            : "0 10px 32px -28px rgba(18,58,99,0.35)",
          "&::after": {
            content: '""',
            position: "absolute",
            insetInlineStart: 0,
            insetInlineEnd: 0,
            bottom: 0,
            height: 2,
            background: headerGradientLine,
            pointerEvents: "none",
          },
        }}
      >
        <Container maxWidth="lg">
          {/* Mobile nav */}
          <Stack
            direction="row"
            spacing={0.75}
            alignItems="center"
            sx={{
              display: { xs: "flex", md: "none" },
              overflowX: "auto",
              py: 1,
              mb: 0.5,
            }}
          >
            {navLinks.map((link) => (
              <Button
                key={`mobile-${link.path}`}
                variant={isActivePath(link.path) ? "contained" : "text"}
                onClick={() => onNavigate(link.path)}
                sx={{
                  borderRadius: 999,
                  whiteSpace: "nowrap",
                  fontWeight: 800,
                  minWidth: "fit-content",
                  color: darkMode && !isActivePath(link.path) ? "rgba(255,255,255,0.75)" : undefined,
                }}
              >
                {link.label}
              </Button>
            ))}
          </Stack>

          {/* Desktop header row */}
          <Box
            sx={{
              py: 1.5,
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              gap: 2,
              flexWrap: { xs: "wrap", lg: "nowrap" },
            }}
          >
            {/* Logo */}
            <Stack direction="row" spacing={1.5} alignItems="center" sx={{ minWidth: 0 }}>
              <Box
                sx={{
                  width: 44,
                  height: 44,
                  borderRadius: 3,
                  display: "grid",
                  placeItems: "center",
                  color: "common.white",
                  background: brandGradient,
                  boxShadow: "0 12px 24px -16px rgba(18,58,99,0.65)",
                }}
              >
                <BalanceIcon />
              </Box>
              <Box sx={{ minWidth: 0 }}>
                <Typography variant="h6" sx={{ fontWeight: 900, letterSpacing: "-0.03em", color: logoNameColor }}>
                  {data.systemName || t("app.title")}
                </Typography>
              </Box>
            </Stack>

            {/* Desktop nav links */}
            <Stack
              direction="row"
              spacing={0.75}
              alignItems="center"
              sx={{
                display: { xs: "none", md: "flex" },
                p: 0.5,
                borderRadius: 999,
                bgcolor: navPillBg,
                border: "1px solid",
                borderColor: navPillBorder,
              }}
            >
              {navLinks.map((link) => (
                <Link
                  key={link.path}
                  component="button"
                  underline="hover"
                  onClick={() => onNavigate(link.path)}
                  sx={{
                    px: 1.5,
                    py: 0.85,
                    borderRadius: 999,
                    fontWeight: 800,
                    textDecoration: "none",
                    backgroundColor: isActivePath(link.path) ? navLinkActiveBg : "transparent",
                    color: isActivePath(link.path) ? navLinkActive : navLinkColor,
                    position: "relative",
                    transition: "all 0.18s ease",
                    "&:hover": { backgroundColor: navLinkHoverBg },
                  }}
                >
                  {link.label}
                </Link>
              ))}
            </Stack>

            {/* Right actions */}
            <Stack direction="row" spacing={1} flexWrap="wrap" alignItems="center" sx={{ justifyContent: { xs: "flex-start", lg: "flex-end" } }}>
              <Stack
                direction="row"
                spacing={0.75}
                sx={{ p: 0.5, borderRadius: 999, bgcolor: langPillBg }}
              >
                {(["ar", "en"] as const).map((languageCode) => (
                  <Button
                    key={languageCode}
                    size="small"
                    variant={currentLanguage === languageCode ? "contained" : "text"}
                    onClick={() => onChangeLanguage(languageCode)}
                    sx={{
                      minWidth: 52,
                      borderRadius: 999,
                      fontWeight: 800,
                      color: currentLanguage === languageCode ? "common.white" : darkMode ? "rgba(255,255,255,0.6)" : "text.secondary",
                      background:
                        currentLanguage === languageCode
                          ? brandGradient
                          : "transparent",
                    }}
                  >
                    {languageCode === "ar" ? t("landing.languages.ar") : t("landing.languages.en")}
                  </Button>
                ))}
              </Stack>
              {isAuthInitialized && isAuthenticated && (
                <Button
                  variant="outlined"
                  onClick={() => onNavigate("/dashboard")}
                  sx={darkMode ? { borderColor: alpha(BRAND_TEAL_END, 0.6), color: BRAND_TEAL_END } : {}}
                >
                  {t("landing.actions.dashboard")}
                </Button>
              )}
              {extraHeaderActions}
              <Button
                variant="text"
                sx={{ fontWeight: 800, color: darkMode ? "rgba(255,255,255,0.75)" : undefined }}
                onClick={() => onNavigate(data.secondaryButtonUrl || "/login")}
              >
                {data.secondaryButtonText || t("landing.actions.login")}
              </Button>
            </Stack>
          </Box>
        </Container>
      </Box>

      {children}

      {/* Footer */}
      <Box
        component="footer"
        sx={{
          borderTop: "1px solid",
          borderColor: darkMode ? alpha(BRAND_TEAL_END, 0.15) : alpha(theme.palette.primary.main, 0.12),
          background: "linear-gradient(180deg, rgba(4,12,28,1) 0%, rgba(6,18,38,1) 100%)",
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
                    background: brandGradient,
                  }}
                >
                  <BalanceIcon />
                </Box>
                <Typography variant="h6" sx={{ fontWeight: 900 }}>
                  {data.systemName}
                </Typography>
              </Stack>
              <Typography variant="body2" sx={{ opacity: 0.72, maxWidth: 560, lineHeight: 1.9 }}>
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
                    key={item.path}
                    component="button"
                    onClick={() => onNavigate(item.path)}
                    underline="hover"
                    color="inherit"
                    sx={{ textAlign: "start", opacity: 0.72, transition: "opacity 0.15s", "&:hover": { opacity: 1 } }}
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
                <Typography variant="body2" sx={{ opacity: 0.72 }}>
                  {t("landing.contact.email")}: {data.contactEmail || "-"}
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.72 }}>
                  {t("landing.contact.phone")}: {data.contactPhone || "-"}
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.72 }}>
                  {t("landing.contact.address")}: {data.contactAddress || "-"}
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
              borderColor: alpha("#ffffff", 0.1),
              opacity: 0.5,
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
