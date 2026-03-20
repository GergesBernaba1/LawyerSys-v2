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

type PublicSiteShellProps = {
  data: LandingPageData;
  currentLanguage: "ar" | "en";
  onChangeLanguage: (language: "ar" | "en") => void;
  onNavigate: (target?: string) => void;
  isAuthenticated: boolean;
  isAuthInitialized: boolean;
  children: React.ReactNode;
  extraHeaderActions?: React.ReactNode;
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
          boxShadow: "0 10px 32px -28px rgba(18,58,99,0.35)",
        }}
      >
        <Container maxWidth="lg">
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
                }}
              >
                {link.label}
              </Button>
            ))}
          </Stack>
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
            <Stack direction="row" spacing={1.5} alignItems="center" sx={{ minWidth: 0 }}>
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
              <Box sx={{ minWidth: 0 }}>
                <Typography variant="h6" sx={{ fontWeight: 900, letterSpacing: "-0.03em" }}>
                  {data.systemName || t("app.title")}
                </Typography>
              </Box>
            </Stack>

            <Stack
              direction="row"
              spacing={0.75}
              alignItems="center"
              sx={{
                display: { xs: "none", md: "flex" },
                p: 0.5,
                borderRadius: 999,
                bgcolor: alpha(theme.palette.primary.main, 0.05),
                border: "1px solid",
                borderColor: alpha(theme.palette.primary.main, 0.08),
              }}
            >
              {navLinks.map((link) => (
                <Link
                  key={link.path}
                  component="button"
                  color="text.primary"
                  underline="hover"
                  onClick={() => onNavigate(link.path)}
                  sx={{
                    px: 1.5,
                    py: 0.75,
                    borderRadius: 999,
                    fontWeight: 800,
                    textDecoration: "none",
                    backgroundColor: isActivePath(link.path) ? alpha(theme.palette.primary.main, 0.12) : "transparent",
                    color: isActivePath(link.path) ? "primary.main" : "text.primary",
                    "&:hover": {
                      backgroundColor: alpha(theme.palette.primary.main, 0.08),
                    },
                  }}
                >
                  {link.label}
                </Link>
              ))}
            </Stack>

            <Stack direction="row" spacing={1} flexWrap="wrap" alignItems="center" sx={{ justifyContent: { xs: "flex-start", lg: "flex-end" } }}>
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
                    onClick={() => onChangeLanguage(languageCode)}
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
                <Button variant="outlined" onClick={() => onNavigate("/dashboard")}>
                  {t("landing.actions.dashboard")}
                </Button>
              )}
              {extraHeaderActions}
              <Button variant="text" sx={{ fontWeight: 800 }} onClick={() => onNavigate(data.secondaryButtonUrl || "/login")}>
                {data.secondaryButtonText || t("landing.actions.login")}
              </Button>
            </Stack>
          </Box>
        </Container>
      </Box>

      {children}

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
                    key={item.path}
                    component="button"
                    onClick={() => onNavigate(item.path)}
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
                <Typography variant="body2" sx={{ opacity: 0.86 }}>
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
