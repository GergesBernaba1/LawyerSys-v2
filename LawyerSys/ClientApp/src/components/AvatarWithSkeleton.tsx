"use client";

import React, { useState } from "react";
import { Avatar, Skeleton, type AvatarProps } from "@mui/material";

type AvatarWithSkeletonProps = AvatarProps & {
  src?: string;
  size?: number;
  skeletonVariant?: "circular" | "rounded" | "rectangular";
};

/**
 * An Avatar that shows a Skeleton placeholder while the image is loading,
 * and gracefully falls back to the children (initials/icon) on error.
 */
export default function AvatarWithSkeleton({
  src,
  size = 40,
  skeletonVariant = "circular",
  children,
  sx,
  ...rest
}: AvatarWithSkeletonProps) {
  const [imgStatus, setImgStatus] = useState<"idle" | "loading" | "loaded" | "error">(
    src ? "loading" : "idle"
  );

  React.useEffect(() => {
    if (src) {
      setImgStatus("loading");
    } else {
      setImgStatus("idle");
    }
  }, [src]);

  const showSkeleton = imgStatus === "loading";

  return (
    <span style={{ position: "relative", display: "inline-flex", width: size, height: size }}>
      {showSkeleton && (
        <Skeleton
          variant={skeletonVariant}
          width={size}
          height={size}
          sx={{ position: "absolute", top: 0, left: 0 }}
          aria-hidden="true"
        />
      )}
      <Avatar
        src={imgStatus !== "error" ? src : undefined}
        onLoad={() => setImgStatus("loaded")}
        onError={() => setImgStatus("error")}
        sx={{
          width: size,
          height: size,
          opacity: showSkeleton ? 0 : 1,
          transition: "opacity 0.2s ease",
          ...sx,
        }}
        {...rest}
      >
        {children}
      </Avatar>
    </span>
  );
}
