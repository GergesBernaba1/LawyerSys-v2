"use client";

import React from "react";
import {
  Avatar,
  Box,
  Button,
  Container,
  Link as MuiLink,
  Paper,
  Stack,
  Typography,
  alpha,
  useTheme,
} from "@mui/material";
import { ArrowBackRounded as ArrowBackRoundedIcon } from "@mui/icons-material";

type AuthFeature = {
  icon: React.ReactNode;
  text: string;
};

type AuthSplitLayoutProps = {
  badge: string;
  title: string;
  subtitle: string;
  formTitle: string;
  formSubtitle: string;
  heroIcon: React.ReactNode;
  formIcon: React.ReactNode;
  features: AuthFeature[];
  children: React.ReactNode;
  footerLinkHref?: string;
  footerLinkLabel?: string;
};

export default function AuthSplitLayout({
  badge,
  title,
  subtitle,
  formTitle,
  formSubtitle,
  heroIcon,
  formIcon,
  features,
  children,
  footerLinkHref,
  footerLinkLabel,
}: AuthSplitLayoutProps) {
  const theme = useTheme();
  const isRTL = theme.direction === "rtl";

  return (
    <Box
      sx={{
        minHeight: "100vh",
        position: "relative",
        // overflow hidden clips content on mobile — use auto so the form is reachable on small screens
        overflow: { xs: "auto", md: "hidden" },
        display: "flex",
        alignItems: { xs: "flex-start", md: "center" },
        py: { xs: 3, md: 5 },
        px: { xs: 2, md: 4 },
        background:
          "radial-gradient(circle at top left, rgba(54, 131, 144, 0.24) 0%, rgba(54, 131, 144, 0) 32%), radial-gradient(circle at bottom right, rgba(199, 153, 84, 0.24) 0%, rgba(199, 153, 84, 0) 28%), linear-gradient(135deg, #081320 0%, #0f2742 52%, #14345a 100%)",
        "&::before": {
          content: '""',
          position: "absolute",
          inset: 0,
          background:
            "linear-gradient(120deg, rgba(255,255,255,0.04) 0px, rgba(255,255,255,0.04) 1px, transparent 1px, transparent 34px)",
          opacity: 0.45,
          pointerEvents: "none",
        },
      }}
    >
      <Container maxWidth="xl" disableGutters dir={isRTL ? "rtl" : "ltr"} sx={{ position: "relative", zIndex: 1 }}>
        <Paper
          elevation={0}
          sx={{
            overflow: "hidden",
            borderRadius: { xs: 4, md: 6 },
            border: "1px solid rgba(255,255,255,0.14)",
            boxShadow: "0 34px 80px rgba(3, 12, 24, 0.34)",
            backgroundColor: alpha("#ffffff", 0.1),
            backdropFilter: "blur(14px)",
          }}
        >
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", lg: "minmax(0, 1.08fr) minmax(420px, 0.92fr)" },
            }}
          >
            <Box
              sx={{
                position: "relative",
                p: { xs: 3, sm: 4, lg: 5 },
                color: "common.white",
                background:
                  "linear-gradient(150deg, rgba(8, 19, 32, 0.92) 0%, rgba(15, 39, 66, 0.9) 56%, rgba(22, 70, 92, 0.82) 100%)",
                borderInlineEnd: { lg: "1px solid rgba(255,255,255,0.08)" },
                // Hide the hero/branding panel on mobile — form-first UX
                display: { xs: "none", lg: "flex" },
                flexDirection: "column",
                justifyContent: "space-between",
                gap: 4,
                "&::after": {
                  content: '""',
                  position: "absolute",
                  insetInlineEnd: -80,
                  bottom: -80,
                  width: 220,
                  height: 220,
                  borderRadius: "50%",
                  background: "rgba(255,255,255,0.08)",
                  filter: "blur(10px)",
                },
              }}
            >
              <Box sx={{ position: "relative", zIndex: 1 }}>
                <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 3 }}>
                  <Avatar
                    sx={{
                      width: 56,
                      height: 56,
                      bgcolor: alpha("#ffffff", 0.12),
                      border: "1px solid rgba(255,255,255,0.22)",
                    }}
                  >
                    {heroIcon}
                  </Avatar>
                  <Box>
                    <Typography variant="overline" sx={{ letterSpacing: "0.18em", opacity: 0.84, fontWeight: 800 }}>
                      {badge}
                    </Typography>
                    <Typography variant="h6" sx={{ fontWeight: 900, letterSpacing: "-0.03em" }}>
                      Qadaya
                    </Typography>
                  </Box>
                </Stack>

                <Typography variant="h3" sx={{ fontWeight: 900, lineHeight: 1.08, letterSpacing: "-0.05em", maxWidth: 640 }}>
                  {title}
                </Typography>
                <Typography variant="body1" sx={{ mt: 2, maxWidth: 600, opacity: 0.82, lineHeight: 1.85 }}>
                  {subtitle}
                </Typography>
              </Box>

              <Stack spacing={1.25} sx={{ position: "relative", zIndex: 1 }}>
                {features.map((feature, index) => (
                  <Box
                    key={`${feature.text}-${index}`}
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      gap: 1.25,
                      px: 1.5,
                      py: 1.25,
                      borderRadius: 3,
                      border: "1px solid rgba(255,255,255,0.1)",
                      backgroundColor: alpha("#ffffff", 0.06),
                      flexDirection: isRTL ? "row-reverse" : "row",
                    }}
                  >
                    <Avatar
                      sx={{
                        width: 34,
                        height: 34,
                        bgcolor: alpha("#ffffff", 0.12),
                        color: "common.white",
                      }}
                    >
                      {feature.icon}
                    </Avatar>
                    <Typography variant="body2" sx={{ fontWeight: 600, opacity: 0.92 }}>
                      {feature.text}
                    </Typography>
                  </Box>
                ))}
              </Stack>
            </Box>

            <Box
              sx={{
                p: { xs: 3, sm: 4, lg: 5 },
                background:
                  "linear-gradient(180deg, rgba(252,254,255,0.98) 0%, rgba(244,248,252,0.98) 100%)",
                textAlign: isRTL ? "right" : "left",
                display: "flex",
                flexDirection: "column",
                justifyContent: "center",
              }}
            >
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
                <Stack direction="row" spacing={1.5} alignItems="center">
                  <Avatar
                    sx={{
                      width: 48,
                      height: 48,
                      background: "linear-gradient(135deg, #14345a 0%, #2d6a87 100%)",
                      boxShadow: "0 10px 20px rgba(20, 52, 90, 0.18)",
                    }}
                  >
                    {formIcon}
                  </Avatar>
                  <Box>
                    <Typography variant="h5" sx={{ fontWeight: 900, letterSpacing: "-0.03em" }}>
                      {formTitle}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 0.4 }}>
                      {formSubtitle}
                    </Typography>
                  </Box>
                </Stack>

                {footerLinkHref && footerLinkLabel ? (
                  <Button
                    component={MuiLink}
                    href={footerLinkHref}
                    color="inherit"
                    startIcon={!isRTL ? <ArrowBackRoundedIcon /> : undefined}
                    endIcon={isRTL ? <ArrowBackRoundedIcon sx={{ transform: "rotate(180deg)" }} /> : undefined}
                    sx={{ fontWeight: 800, color: "text.secondary", textDecoration: "none" }}
                  >
                    {footerLinkLabel}
                  </Button>
                ) : null}
              </Stack>

              {children}
            </Box>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}
