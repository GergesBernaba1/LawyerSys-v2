/**
 * Shared brand tokens for the public marketing site and auth flows.
 *
 * The authenticated app uses the MUI theme (`theme.ts`) which is the legal-blue
 * + gold identity. The public-facing pages (landing, about, contact, login,
 * register, forgot/reset password) intentionally use a separate teal gradient
 * brand. Tokens live here so the gradient is changed in one place.
 */

export const BRAND_TEAL_START = '#123a63';
export const BRAND_TEAL_END = '#1c7b82';
export const BRAND_TEAL_START_HOVER = '#0f3358';
export const BRAND_TEAL_END_HOVER = '#187479';

export const brandGradient =
  `linear-gradient(135deg, ${BRAND_TEAL_START} 0%, ${BRAND_TEAL_END} 100%)`;

export const brandGradientHover =
  `linear-gradient(135deg, ${BRAND_TEAL_START_HOVER} 0%, ${BRAND_TEAL_END_HOVER} 100%)`;

/** Convenience `sx` fragment for primary CTA buttons on public/auth pages. */
export const brandGradientButtonSx = {
  background: brandGradient,
  '&:hover': { background: brandGradientHover },
} as const;
