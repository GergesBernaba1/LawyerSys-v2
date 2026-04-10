"use client";

import React from "react";
import { Alert, Button, type AlertProps } from "@mui/material";
import { Refresh as RefreshIcon } from "@mui/icons-material";
import { useTranslation } from "react-i18next";

type RetryAlertProps = Omit<AlertProps, "action"> & {
  message: string;
  onRetry: () => void;
  retryLabel?: string;
  loading?: boolean;
};

/**
 * An error Alert with an optional Retry button.
 * Wraps MUI Alert and adds an accessible retry action.
 */
export default function RetryAlert({
  message,
  onRetry,
  retryLabel,
  loading = false,
  severity = "error",
  ...rest
}: RetryAlertProps) {
  const { t } = useTranslation();
  const label = retryLabel ?? t("common.retry", "Retry");

  return (
    <Alert
      severity={severity}
      role="alert"
      aria-live="polite"
      action={
        <Button
          color="inherit"
          size="small"
          onClick={onRetry}
          disabled={loading}
          startIcon={<RefreshIcon fontSize="inherit" />}
          sx={{ fontWeight: 700, whiteSpace: "nowrap" }}
        >
          {label}
        </Button>
      }
      {...rest}
    >
      {message}
    </Alert>
  );
}
