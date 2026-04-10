"use client";

import React from "react";
import { Button, CircularProgress, type ButtonProps } from "@mui/material";

type LoadingButtonProps = ButtonProps & {
  loading?: boolean;
  loadingPosition?: "start" | "end" | "center";
};

/**
 * A Button that shows a CircularProgress spinner while `loading` is true.
 * The button is automatically disabled while loading.
 */
export default function LoadingButton({
  loading = false,
  loadingPosition = "center",
  children,
  disabled,
  startIcon,
  endIcon,
  sx,
  ...rest
}: LoadingButtonProps) {
  const spinner = (
    <CircularProgress
      color="inherit"
      size={16}
      thickness={4}
      aria-hidden="true"
    />
  );

  return (
    <Button
      disabled={disabled || loading}
      startIcon={loadingPosition === "start" && loading ? spinner : startIcon}
      endIcon={loadingPosition === "end" && loading ? spinner : endIcon}
      sx={{ position: "relative", minWidth: 80, ...sx }}
      {...rest}
    >
      {loadingPosition === "center" && loading ? (
        <>
          <CircularProgress
            color="inherit"
            size={16}
            thickness={4}
            sx={{ position: "absolute" }}
            aria-hidden="true"
          />
          <span style={{ visibility: "hidden" }}>{children}</span>
        </>
      ) : (
        children
      )}
    </Button>
  );
}
