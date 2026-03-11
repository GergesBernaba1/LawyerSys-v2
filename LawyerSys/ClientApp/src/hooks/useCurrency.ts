"use client";

import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { useAuth } from "../services/auth";

const DEFAULT_CURRENCY = "USD";

const countryCurrencyMap: Record<number, string> = {
  1: "EGP",
  2: "SAR",
  3: "AED",
  4: "KWD",
  5: "QAR",
  6: "BHD",
  7: "OMR",
  8: "JOD",
};

const countryLocaleMap: Record<number, string> = {
  1: "en-EG",
  2: "en-SA",
  3: "en-AE",
  4: "en-KW",
  5: "en-QA",
  6: "en-BH",
  7: "en-OM",
  8: "en-JO",
};

function resolveCurrencyCode(countryId?: number | null) {
  return countryId ? countryCurrencyMap[countryId] ?? DEFAULT_CURRENCY : DEFAULT_CURRENCY;
}

function resolveLocale(language: string | undefined, countryId?: number | null) {
  if (language?.toLowerCase().startsWith("ar")) {
    switch (countryId) {
      case 1:
        return "ar-EG";
      case 2:
        return "ar-SA";
      case 3:
        return "ar-AE";
      case 4:
        return "ar-KW";
      case 5:
        return "ar-QA";
      case 6:
        return "ar-BH";
      case 7:
        return "ar-OM";
      case 8:
        return "ar-JO";
      default:
        return "ar";
    }
  }

  return countryId ? countryLocaleMap[countryId] ?? undefined : undefined;
}

export function formatCurrencyValue(
  value: number,
  countryId?: number | null,
  language?: string,
  options?: Intl.NumberFormatOptions
) {
  const currency = resolveCurrencyCode(countryId);
  const locale = resolveLocale(language, countryId);

  try {
    return new Intl.NumberFormat(locale, {
      style: "currency",
      currency,
      maximumFractionDigits: 2,
      ...options,
    }).format(value || 0);
  } catch {
    return `${(value || 0).toLocaleString()} ${currency}`;
  }
}

export function useCurrency() {
  const { user } = useAuth();
  const { i18n } = useTranslation();

  return useMemo(() => {
    const countryId = user?.countryId ?? null;
    const currencyCode = resolveCurrencyCode(countryId);

    return {
      countryId,
      currencyCode,
      formatCurrency: (value: number, options?: Intl.NumberFormatOptions) =>
        formatCurrencyValue(value, countryId, i18n.language, options),
    };
  }, [i18n.language, user?.countryId]);
}
