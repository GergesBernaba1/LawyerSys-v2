"use client";

export type LandingFeature = {
  iconKey: string;
  title: string;
  description: string;
};

export type LandingPageData = {
  systemName: string;
  tagline: string;
  heroTitle: string;
  heroSubtitle: string;
  primaryButtonText: string;
  primaryButtonUrl: string;
  secondaryButtonText: string;
  secondaryButtonUrl: string;
  aboutTitle: string;
  aboutDescription: string;
  aboutPageTitle: string;
  aboutPageSubtitle: string;
  aboutPageDescription: string;
  aboutPageMissionTitle: string;
  aboutPageMissionDescription: string;
  aboutPageVisionTitle: string;
  aboutPageVisionDescription: string;
  contactPageTitle: string;
  contactPageSubtitle: string;
  contactPageDescription: string;
  contactAddress: string;
  contactWorkingHours: string;
  contactEmail: string;
  contactPhone: string;
  features: LandingFeature[];
};

export function getRequestLanguage(language: string) {
  return language === "ar" ? "ar-SA" : "en-US";
}

export function pickText(value: string | null | undefined, fallback: string) {
  return typeof value === "string" && value.trim().length > 0 ? value : fallback;
}

export function getDefaultLandingPage(t: (key: string, options?: any) => string): LandingPageData {
  return {
    systemName: t("landing.defaults.systemName"),
    tagline: t("landing.defaults.tagline"),
    heroTitle: t("landing.defaults.heroTitle"),
    heroSubtitle: t("landing.defaults.heroSubtitle"),
    primaryButtonText: t("landing.defaults.primaryButtonText"),
    primaryButtonUrl: "/register",
    secondaryButtonText: t("landing.defaults.secondaryButtonText"),
    secondaryButtonUrl: "/login",
    aboutTitle: t("landing.defaults.aboutTitle"),
    aboutDescription: t("landing.defaults.aboutDescription"),
    aboutPageTitle: t("landing.defaults.aboutPage.title"),
    aboutPageSubtitle: t("landing.defaults.aboutPage.subtitle"),
    aboutPageDescription: t("landing.defaults.aboutPage.description"),
    aboutPageMissionTitle: t("landing.defaults.aboutPage.missionTitle"),
    aboutPageMissionDescription: t("landing.defaults.aboutPage.missionDescription"),
    aboutPageVisionTitle: t("landing.defaults.aboutPage.visionTitle"),
    aboutPageVisionDescription: t("landing.defaults.aboutPage.visionDescription"),
    contactPageTitle: t("landing.defaults.contactPage.title"),
    contactPageSubtitle: t("landing.defaults.contactPage.subtitle"),
    contactPageDescription: t("landing.defaults.contactPage.description"),
    contactAddress: t("landing.defaults.contactPage.address"),
    contactWorkingHours: t("landing.defaults.contactPage.workingHours"),
    contactEmail: "support@qadaya.app",
    contactPhone: "01018206558",
    features: [
      {
        iconKey: "automation",
        title: t("landing.defaults.features.automation.title"),
        description: t("landing.defaults.features.automation.description"),
      },
      {
        iconKey: "collaboration",
        title: t("landing.defaults.features.collaboration.title"),
        description: t("landing.defaults.features.collaboration.description"),
      },
      {
        iconKey: "insight",
        title: t("landing.defaults.features.insight.title"),
        description: t("landing.defaults.features.insight.description"),
      },
    ],
  };
}

export function buildLandingData(responseData: Partial<LandingPageData> | undefined, fallback: LandingPageData): LandingPageData {
  const responseFeatures = Array.isArray(responseData?.features) ? responseData.features : [];

  return {
    systemName: pickText(responseData?.systemName, fallback.systemName),
    tagline: pickText(responseData?.tagline, fallback.tagline),
    heroTitle: pickText(responseData?.heroTitle, fallback.heroTitle),
    heroSubtitle: pickText(responseData?.heroSubtitle, fallback.heroSubtitle),
    primaryButtonText: pickText(responseData?.primaryButtonText, fallback.primaryButtonText),
    primaryButtonUrl: pickText(responseData?.primaryButtonUrl, fallback.primaryButtonUrl),
    secondaryButtonText: pickText(responseData?.secondaryButtonText, fallback.secondaryButtonText),
    secondaryButtonUrl: pickText(responseData?.secondaryButtonUrl, fallback.secondaryButtonUrl),
    aboutTitle: pickText(responseData?.aboutTitle, fallback.aboutTitle),
    aboutDescription: pickText(responseData?.aboutDescription, fallback.aboutDescription),
    aboutPageTitle: pickText(responseData?.aboutPageTitle, fallback.aboutPageTitle),
    aboutPageSubtitle: pickText(responseData?.aboutPageSubtitle, fallback.aboutPageSubtitle),
    aboutPageDescription: pickText(responseData?.aboutPageDescription, fallback.aboutPageDescription),
    aboutPageMissionTitle: pickText(responseData?.aboutPageMissionTitle, fallback.aboutPageMissionTitle),
    aboutPageMissionDescription: pickText(responseData?.aboutPageMissionDescription, fallback.aboutPageMissionDescription),
    aboutPageVisionTitle: pickText(responseData?.aboutPageVisionTitle, fallback.aboutPageVisionTitle),
    aboutPageVisionDescription: pickText(responseData?.aboutPageVisionDescription, fallback.aboutPageVisionDescription),
    contactPageTitle: pickText(responseData?.contactPageTitle, fallback.contactPageTitle),
    contactPageSubtitle: pickText(responseData?.contactPageSubtitle, fallback.contactPageSubtitle),
    contactPageDescription: pickText(responseData?.contactPageDescription, fallback.contactPageDescription),
    contactAddress: pickText(responseData?.contactAddress, fallback.contactAddress),
    contactWorkingHours: pickText(responseData?.contactWorkingHours, fallback.contactWorkingHours),
    contactEmail: pickText(responseData?.contactEmail, fallback.contactEmail),
    contactPhone: pickText(responseData?.contactPhone, fallback.contactPhone),
    features: fallback.features.map((feature, index) => {
      const responseFeature = responseFeatures[index];
      return {
        iconKey: pickText(responseFeature?.iconKey, feature.iconKey),
        title: pickText(responseFeature?.title, feature.title),
        description: pickText(responseFeature?.description, feature.description),
      };
    }),
  };
}
