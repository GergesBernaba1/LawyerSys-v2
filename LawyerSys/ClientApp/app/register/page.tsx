'use client'
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Alert,
  Box,
  Button,
  Chip,
  IconButton,
  InputAdornment,
  Paper,
  Stack,
  Step,
  StepLabel,
  Stepper,
  TextField,
  Typography,
  useTheme,
} from '@mui/material';
import {
  PersonAddOutlined as PersonAddOutlinedIcon,
  Visibility,
  VisibilityOff,
  AccountBalanceOutlined,
  GavelOutlined,
  ShieldOutlined,
  GroupsOutlined,
  ArrowForward as ArrowForwardIcon,
  ArrowBack as ArrowBackIcon,
  CalendarMonth as CalendarMonthIcon,
  EventRepeat as EventRepeatIcon,
} from '@mui/icons-material';
import { useAuth } from '../../src/services/auth';
import { useTranslation } from 'react-i18next';
import api from '../../src/services/api';
import SearchableSelect from '../../src/components/SearchableSelect';
import AuthSplitLayout from '../../src/components/auth/AuthSplitLayout';
import LoadingButton from '../../src/components/LoadingButton';
import RetryAlert from '../../src/components/RetryAlert';
import { formatCurrencyValue } from '../../src/hooks/useCurrency';
import { brandGradientButtonSx, BRAND_TEAL_END } from '../../src/brand';

// ─── Types ───────────────────────────────────────────────────────────────────

type CountryOption = {
  id: number;
  name: string;
};

type SubscriptionPackageCycleOption = {
  subscriptionPackageId: number;
  billingCycle: string;
  price: number;
  currency: string;
  isActive: boolean;
};

type SubscriptionPackageGroup = {
  name: string;
  description: string;
  officeSize: string;
  features: string[];
  monthlyOption?: SubscriptionPackageCycleOption | null;
  annualOption?: SubscriptionPackageCycleOption | null;
};

/** Flattened card shown in step 2 — one card per active billing-cycle option. */
type PlanCard = {
  packageId: number;
  billingCycle: 'Monthly' | 'Annual';
  label: string;
  description: string;
  features: string[];
  price: number;
  currency: string;
};

// ─── Component ───────────────────────────────────────────────────────────────

export default function RegisterPage() {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const router = useRouter();
  const { register, isAuthenticated } = useAuth();
  const isRTL = theme.direction === 'rtl' || (i18n.resolvedLanguage || i18n.language || '').startsWith('ar');
  const fieldSx = isRTL ? { '& .MuiInputBase-input': { textAlign: 'right' } } : {};

  // ── Step ────────────────────────────────────────────────────────────────
  const [step, setStep] = useState<1 | 2>(1);

  // ── Step-1 fields ───────────────────────────────────────────────────────
  const [userName, setUserName] = useState('');
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [lawyerOfficeName, setLawyerOfficeName] = useState('');
  const [lawyerOfficePhoneNumber, setLawyerOfficePhoneNumber] = useState('');
  const [countryId, setCountryId] = useState<number | ''>('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // ── Step-2 fields ───────────────────────────────────────────────────────
  const [selectedPackageId, setSelectedPackageId] = useState<number | null>(null);

  // ── Remote data ─────────────────────────────────────────────────────────
  const [countries, setCountries] = useState<CountryOption[]>([]);
  const [packages, setPackages] = useState<SubscriptionPackageGroup[]>([]);

  // ── UI state ────────────────────────────────────────────────────────────
  const [step1Error, setStep1Error] = useState('');
  const [submitError, setSubmitError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [countriesLoading, setCountriesLoading] = useState(false);
  const [countriesError, setCountriesError] = useState('');
  const [packagesLoading, setPackagesLoading] = useState(false);
  const [packagesError, setPackagesError] = useState('');

  const resolvedCountryId = typeof countryId === 'number' ? countryId : undefined;
  const formatAmount = (value: number, currency: string) =>
    formatCurrencyValue(value, resolvedCountryId, i18n.language);

  // ── Redirect if already authenticated ───────────────────────────────────
  useEffect(() => {
    if (isAuthenticated) router.push('/dashboard');
  }, [isAuthenticated, router]);

  // ── Load countries ───────────────────────────────────────────────────────
  const loadCountries = useCallback(async () => {
    setCountriesLoading(true);
    setCountriesError('');
    try {
      const language = (i18n.resolvedLanguage || i18n.language || 'en').startsWith('ar') ? 'ar-SA' : 'en-US';
      const res = await api.get('/Account/countries', { headers: { 'Accept-Language': language } });
      const next = Array.isArray(res.data) ? res.data : [];
      setCountries(next);
      if (next.length === 1) setCountryId(next[0].id);
    } catch {
      setCountriesError(t('register.failedCountries', { defaultValue: 'Failed to load countries.' }));
    } finally {
      setCountriesLoading(false);
    }
  }, [i18n.resolvedLanguage, i18n.language, t]);

  useEffect(() => { void loadCountries(); }, [loadCountries]);

  // ── Load packages (eager — no delay on step 2) ───────────────────────────
  const loadPackages = useCallback(async () => {
    setPackagesLoading(true);
    setPackagesError('');
    try {
      const language = (i18n.resolvedLanguage || i18n.language || 'en').startsWith('ar') ? 'ar-SA' : 'en-US';
      const res = await api.get('/SubscriptionPackages/public', {
        headers: { 'Accept-Language': language },
        skipTenantHeader: true,
      } as any);
      setPackages(Array.isArray(res.data) ? res.data : []);
    } catch {
      setPackagesError(t('register.failedPackages', { defaultValue: 'Failed to load subscription packages.' }));
    } finally {
      setPackagesLoading(false);
    }
  }, [i18n.resolvedLanguage, i18n.language, t]);

  useEffect(() => { void loadPackages(); }, [loadPackages]);

  // ── Flatten groups into individual billing-cycle cards ───────────────────
  const planCards = useMemo<PlanCard[]>(() => {
    const cards: PlanCard[] = [];
    for (const group of packages) {
      if (group.monthlyOption?.isActive) {
        cards.push({
          packageId: group.monthlyOption.subscriptionPackageId,
          billingCycle: 'Monthly',
          label: t('subscription.billingCycle.monthly', { defaultValue: 'Monthly' }),
          description: group.description,
          features: group.features,
          price: group.monthlyOption.price,
          currency: group.monthlyOption.currency,
        });
      }
      if (group.annualOption?.isActive) {
        cards.push({
          packageId: group.annualOption.subscriptionPackageId,
          billingCycle: 'Annual',
          label: t('subscription.billingCycle.annual', { defaultValue: 'Annual' }),
          description: group.description,
          features: group.features,
          price: group.annualOption.price,
          currency: group.annualOption.currency,
        });
      }
    }
    return cards;
  }, [packages, t]);

  // Auto-select first card when plans load
  useEffect(() => {
    if (planCards.length > 0 && !selectedPackageId) {
      setSelectedPackageId(planCards[0].packageId);
    }
  }, [planCards, selectedPackageId]);

  // ── Step-1 validation → advance ──────────────────────────────────────────
  const handleNext = () => {
    setStep1Error('');
    if (!userName.trim()) {
      setStep1Error(t('register.usernameRequired', { defaultValue: 'Please enter a username.' }));
      return;
    }
    if (!fullName.trim()) {
      setStep1Error(t('register.fullNameRequired', { defaultValue: 'Please enter your full name.' }));
      return;
    }
    if (!lawyerOfficeName.trim()) {
      setStep1Error(t('register.officeNameRequired', { defaultValue: 'Please enter the lawyer office name.' }));
      return;
    }
    if (!lawyerOfficePhoneNumber.trim()) {
      setStep1Error(t('register.officePhoneRequired', { defaultValue: 'Please enter the lawyer office phone number.' }));
      return;
    }
    if (!countryId) {
      setStep1Error(t('register.countryRequired', { defaultValue: 'Please select a country.' }));
      return;
    }
    if (!email.trim()) {
      setStep1Error(t('register.emailRequired', { defaultValue: 'Please enter a valid email.' }));
      return;
    }
    if (!password) {
      setStep1Error(t('register.passwordRequired', { defaultValue: 'Please enter a password.' }));
      return;
    }
    if (password !== confirmPassword) {
      setStep1Error(t('register.passwordMismatch', { defaultValue: 'Passwords do not match.' }));
      return;
    }
    setStep(2);
  };

  // ── Final submission ─────────────────────────────────────────────────────
  const handleSubmit = async () => {
    setSubmitError('');
    if (!selectedPackageId) {
      setSubmitError(t('register.packageRequired', { defaultValue: 'Please select a subscription package.' }));
      return;
    }
    setLoading(true);
    const result = await register(
      userName,
      email,
      password,
      fullName,
      Number(countryId),
      lawyerOfficeName,
      lawyerOfficePhoneNumber,
      selectedPackageId,
    );
    if (result.success) {
      setSuccessMessage(
        result.message ||
        t('register.pendingActivation', { defaultValue: 'Registration completed. Your account is pending activation by the system administrator.' }),
      );
      setTimeout(() => router.push('/login'), 1800);
    } else {
      setSubmitError(result.message || t('register.registrationFailed', { defaultValue: 'Registration failed. Please try again.' }));
    }
    setLoading(false);
  };

  // ── Dynamic hero features per step ──────────────────────────────────────
  const heroFeatures = step === 1
    ? [
        { icon: <GavelOutlined fontSize="small" />, text: t('register.featureSequencing') },
        { icon: <GroupsOutlined fontSize="small" />, text: t('register.featureFlow') },
        { icon: <ShieldOutlined fontSize="small" />, text: t('register.featureActivation') },
      ]
    : [
        { icon: <CalendarMonthIcon fontSize="small" />, text: t('register.featureMonthly') },
        { icon: <EventRepeatIcon fontSize="small" />, text: t('register.featureAnnual') },
        { icon: <ShieldOutlined fontSize="small" />, text: t('register.featureSecure') },
      ];

  // ── Stepper styles (dark-panel friendly) ────────────────────────────────
  const stepperSx = {
    mb: 3,
    '& .MuiStepLabel-label': {
      color: 'rgba(255,255,255,0.45)',
      fontSize: '0.8rem',
      fontWeight: 600,
      '&.Mui-active': { color: '#fff', fontWeight: 700 },
      '&.Mui-completed': { color: BRAND_TEAL_END, fontWeight: 700 },
    },
    '& .MuiStepIcon-root': {
      color: 'rgba(255,255,255,0.15)',
      '&.Mui-active': { color: BRAND_TEAL_END },
      '&.Mui-completed': { color: BRAND_TEAL_END },
    },
    '& .MuiStepConnector-line': {
      borderColor: 'rgba(255,255,255,0.12)',
    },
  };

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <AuthSplitLayout
      badge={t('register.badge', { defaultValue: 'NEW FIRM ONBOARDING' })}
      title={t('register.workspaceTitle')}
      subtitle={t('register.workspaceSubtitle')}
      formTitle={t('register.title', { defaultValue: 'Sign Up' })}
      formSubtitle={step === 1
        ? t('register.step1Subtitle', { defaultValue: 'Enter your account and office information' })
        : t('register.step2Subtitle', { defaultValue: 'Pick the billing plan that suits your office' })}
      heroIcon={<AccountBalanceOutlined />}
      formIcon={<PersonAddOutlinedIcon />}
      footerLinkHref="/login"
      footerLinkLabel={t('register.haveAccount', { defaultValue: 'Already have an account? Sign in' })}
      features={heroFeatures}
    >
      {/* ── Step indicator ─────────────────────────────────────────────── */}
      <Stepper activeStep={step - 1} sx={stepperSx}>
        <Step>
          <StepLabel>{t('register.step1Label', { defaultValue: 'Account Details' })}</StepLabel>
        </Step>
        <Step>
          <StepLabel>{t('register.step2Label', { defaultValue: 'Choose Package' })}</StepLabel>
        </Step>
      </Stepper>

      {/* ════════════════════════════════════════════════════════════════
          STEP 1 — Registration fields
      ════════════════════════════════════════════════════════════════ */}
      {step === 1 && (
        <Stack spacing={2.5}>
          {countriesError && (
            <RetryAlert message={countriesError} onRetry={loadCountries} loading={countriesLoading} />
          )}

          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, minmax(0, 1fr))' }, gap: 2 }}>
            <TextField
              required
              fullWidth
              id="userName"
              label={t('register.username', { defaultValue: 'Username' })}
              autoComplete="username"
              autoFocus
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
              sx={fieldSx}
            />
            <TextField
              required
              fullWidth
              id="fullName"
              label={t('register.fullName', { defaultValue: 'Full Name' })}
              autoComplete="name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              sx={fieldSx}
            />
            <TextField
              required
              fullWidth
              id="lawyerOfficeName"
              label={t('register.lawyerOfficeName', { defaultValue: 'Lawyer Office Name' })}
              value={lawyerOfficeName}
              onChange={(e) => setLawyerOfficeName(e.target.value)}
              sx={fieldSx}
            />
            <TextField
              required
              fullWidth
              id="lawyerOfficePhoneNumber"
              label={t('register.lawyerOfficePhoneNumber', { defaultValue: 'Lawyer Office Phone Number' })}
              value={lawyerOfficePhoneNumber}
              onChange={(e) => setLawyerOfficePhoneNumber(e.target.value)}
              sx={fieldSx}
            />
            <SearchableSelect
              label={t('register.country', { defaultValue: 'Country' })}
              value={countryId}
              onChange={(value) => setCountryId(value === null || value === '' ? '' : Number(value))}
              options={[
                { value: '', label: t('register.selectCountry', { defaultValue: 'Select country' }) },
                ...countries.map((c) => ({ value: c.id, label: c.name })),
              ]}
              required
              sx={fieldSx}
            />
            <TextField
              required
              fullWidth
              id="email"
              label={t('register.email', { defaultValue: 'Email' })}
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              sx={fieldSx}
            />
            <TextField
              required
              fullWidth
              id="password"
              name="password"
              label={t('register.password', { defaultValue: 'Password' })}
              type={showPassword ? 'text' : 'password'}
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              sx={fieldSx}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      aria-label={showPassword ? t('login.hidePassword', { defaultValue: 'Hide password' }) : t('login.showPassword', { defaultValue: 'Show password' })}
                      aria-pressed={showPassword}
                      onClick={() => setShowPassword((p) => !p)}
                      edge="end"
                    >
                      {showPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
            <TextField
              required
              fullWidth
              id="confirmPassword"
              name="confirmPassword"
              label={t('register.confirmPassword', { defaultValue: 'Confirm Password' })}
              type={showConfirmPassword ? 'text' : 'password'}
              autoComplete="new-password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              sx={fieldSx}
              error={confirmPassword.length > 0 && password !== confirmPassword}
              helperText={
                confirmPassword.length > 0 && password !== confirmPassword
                  ? t('register.passwordMismatch', { defaultValue: 'Passwords do not match' })
                  : ''
              }
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      aria-label={showConfirmPassword ? t('login.hidePassword', { defaultValue: 'Hide password' }) : t('login.showPassword', { defaultValue: 'Show password' })}
                      aria-pressed={showConfirmPassword}
                      onClick={() => setShowConfirmPassword((p) => !p)}
                      edge="end"
                    >
                      {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
          </Box>

          {step1Error && (
            <Alert severity="error" role="alert" aria-live="polite" sx={{ borderRadius: 3 }}>
              {step1Error}
            </Alert>
          )}

          {/* Next → */}
          <Button
            fullWidth
            variant="contained"
            size="large"
            onClick={handleNext}
            endIcon={isRTL ? <ArrowBackIcon /> : <ArrowForwardIcon />}
            sx={{ py: 1.35, borderRadius: 3, fontWeight: 800, ...brandGradientButtonSx }}
          >
            {t('register.next', { defaultValue: 'Next' })}
          </Button>
        </Stack>
      )}

      {/* ════════════════════════════════════════════════════════════════
          STEP 2 — Package selection
      ════════════════════════════════════════════════════════════════ */}
      {step === 2 && (
        <Stack spacing={2.5}>
          {packagesError && (
            <RetryAlert message={packagesError} onRetry={loadPackages} loading={packagesLoading} />
          )}

          {/* Plan cards */}
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, minmax(0, 1fr))' },
              gap: 2,
            }}
          >
            {packagesLoading
              ? [0, 1].map((i) => (
                  <Paper
                    key={i}
                    elevation={0}
                    sx={{
                      p: 2.5,
                      borderRadius: 3,
                      border: '1px solid rgba(255,255,255,0.08)',
                      bgcolor: 'rgba(255,255,255,0.03)',
                      minHeight: 180,
                    }}
                  />
                ))
              : planCards.map((card) => {
                  const selected = selectedPackageId === card.packageId;
                  return (
                    <Paper
                      key={card.packageId}
                      component="button"
                      type="button"
                      elevation={0}
                      onClick={() => setSelectedPackageId(card.packageId)}
                      aria-pressed={selected}
                      sx={{
                        p: 2.5,
                        borderRadius: 3,
                        border: '1.5px solid',
                        borderColor: selected ? BRAND_TEAL_END : 'rgba(255,255,255,0.1)',
                        bgcolor: selected ? 'rgba(28,123,130,0.14)' : 'rgba(255,255,255,0.03)',
                        cursor: 'pointer',
                        textAlign: isRTL ? 'right' : 'left',
                        transition: 'border-color 0.18s, background-color 0.18s, box-shadow 0.18s',
                        position: 'relative',
                        width: '100%',
                        '&:hover': {
                          borderColor: `${BRAND_TEAL_END}88`,
                          boxShadow: '0 6px 20px rgba(28,123,130,0.2)',
                        },
                        '&:focus-visible': {
                          outline: `2px solid ${BRAND_TEAL_END}`,
                          outlineOffset: 2,
                        },
                      }}
                    >
                      {/* Popular badge for annual */}
                      {card.billingCycle === 'Annual' && (
                        <Chip
                          size="small"
                          label={isRTL ? 'الأوفر' : 'Best Value'}
                          sx={{
                            position: 'absolute',
                            top: 10,
                            right: isRTL ? 'auto' : 10,
                            left: isRTL ? 10 : 'auto',
                            bgcolor: BRAND_TEAL_END,
                            color: '#fff',
                            fontWeight: 800,
                            fontSize: '0.68rem',
                            height: 22,
                          }}
                        />
                      )}

                      {/* Billing cycle icon + label */}
                      <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 1.5 }}>
                        <Box
                          sx={{
                            width: 36,
                            height: 36,
                            borderRadius: 2,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            bgcolor: selected ? `${BRAND_TEAL_END}22` : 'rgba(255,255,255,0.06)',
                            color: selected ? BRAND_TEAL_END : 'rgba(255,255,255,0.4)',
                            transition: 'background-color 0.18s, color 0.18s',
                          }}
                        >
                          {card.billingCycle === 'Monthly' ? <CalendarMonthIcon fontSize="small" /> : <EventRepeatIcon fontSize="small" />}
                        </Box>
                        <Typography variant="subtitle1" sx={{ fontWeight: 800, color: selected ? '#fff' : 'rgba(255,255,255,0.75)' }}>
                          {card.label}
                        </Typography>
                      </Stack>

                      {/* Features */}
                      <Stack spacing={0.4} sx={{ mb: 2 }}>
                        {card.features.slice(0, 3).map((f) => (
                          <Typography key={f} variant="caption" sx={{ color: 'rgba(255,255,255,0.45)', lineHeight: 1.6 }}>
                            • {f}
                          </Typography>
                        ))}
                      </Stack>

                      {/* Price */}
                      <Stack direction="row" alignItems="baseline" spacing={0.5}>
                        <Typography variant="h5" sx={{ fontWeight: 900, color: selected ? '#14c8d4' : 'rgba(255,255,255,0.8)' }}>
                          {formatAmount(card.price, card.currency)}
                        </Typography>
                        <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.35)', fontWeight: 400 }}>
                          / {card.label}
                        </Typography>
                      </Stack>
                    </Paper>
                  );
                })}
          </Box>

          {/* Selected plan summary */}
          {(() => {
            const selected = planCards.find((c) => c.packageId === selectedPackageId);
            if (!selected) return null;
            return (
              <Paper
                elevation={0}
                sx={{ px: 2.5, py: 1.5, borderRadius: 3, bgcolor: 'rgba(28,123,130,0.08)', border: '1px solid rgba(28,123,130,0.22)' }}
              >
                <Stack direction={isRTL ? 'row-reverse' : 'row'} justifyContent="space-between" alignItems="center">
                  <Typography variant="subtitle2" sx={{ fontWeight: 700, color: 'rgba(255,255,255,0.75)' }}>
                    {t('register.selectedPackage', { defaultValue: 'Selected plan' })}:{' '}
                    <Box component="span" sx={{ color: '#fff' }}>{selected.label}</Box>
                  </Typography>
                  <Typography variant="subtitle2" sx={{ fontWeight: 800, color: '#14c8d4' }}>
                    {formatAmount(selected.price, selected.currency)}
                  </Typography>
                </Stack>
              </Paper>
            );
          })()}

          {submitError && (
            <Alert severity="error" role="alert" aria-live="polite" sx={{ borderRadius: 3 }}>
              {submitError}
            </Alert>
          )}
          {successMessage && (
            <Alert severity="success" role="status" aria-live="polite" sx={{ borderRadius: 3 }}>
              {successMessage}
            </Alert>
          )}

          {/* Back / Sign Up */}
          <Stack direction={isRTL ? 'row-reverse' : 'row'} spacing={1.5}>
            <Button
              variant="outlined"
              size="large"
              onClick={() => { setStep(1); setSubmitError(''); }}
              startIcon={isRTL ? <ArrowForwardIcon /> : <ArrowBackIcon />}
              sx={{
                borderRadius: 3,
                fontWeight: 700,
                borderColor: 'rgba(255,255,255,0.18)',
                color: 'rgba(255,255,255,0.75)',
                '&:hover': { borderColor: 'rgba(255,255,255,0.35)', bgcolor: 'rgba(255,255,255,0.05)' },
                flexShrink: 0,
              }}
            >
              {t('register.back', { defaultValue: 'Back' })}
            </Button>
            <LoadingButton
              fullWidth
              variant="contained"
              size="large"
              loading={loading}
              loadingPosition="start"
              onClick={handleSubmit}
              aria-busy={loading}
              sx={{ py: 1.35, borderRadius: 3, fontWeight: 800, ...brandGradientButtonSx }}
            >
              {t('register.signUp', { defaultValue: 'Sign Up' })}
            </LoadingButton>
          </Stack>
        </Stack>
      )}
    </AuthSplitLayout>
  );
}
