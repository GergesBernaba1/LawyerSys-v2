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
} from '@mui/icons-material';
import { useAuth } from '../../src/services/auth';
import { useTranslation } from 'react-i18next';
import api from '../../src/services/api';
import SearchableSelect from '../../src/components/SearchableSelect';
import AuthSplitLayout from '../../src/components/auth/AuthSplitLayout';
import LoadingButton from '../../src/components/LoadingButton';
import RetryAlert from '../../src/components/RetryAlert';
import { formatCurrencyValue } from '../../src/hooks/useCurrency';

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

type SubscriptionPackageOption = {
  name: string;
  description: string;
  officeSize: string;
  features: string[];
  monthlyOption?: SubscriptionPackageCycleOption | null;
  annualOption?: SubscriptionPackageCycleOption | null;
};

export default function RegisterPage() {
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
  const [countries, setCountries] = useState<CountryOption[]>([]);
  const [packages, setPackages] = useState<SubscriptionPackageOption[]>([]);
  const [selectedOfficeSize, setSelectedOfficeSize] = useState<string>("");
  const [selectedBillingCycle, setSelectedBillingCycle] = useState<"Monthly" | "Annual">("Monthly");
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [countriesLoading, setCountriesLoading] = useState(false);
  const [countriesError, setCountriesError] = useState('');
  const [packagesLoading, setPackagesLoading] = useState(false);
  const [packagesError, setPackagesError] = useState('');
  const { register, isAuthenticated } = useAuth();
  const router = useRouter();
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl' || (i18n.resolvedLanguage || i18n.language || '').startsWith('ar');
  const resolvedCountryId = typeof countryId === 'number' ? countryId : undefined;
  const formatAmount = (value: number) => formatCurrencyValue(value, resolvedCountryId, i18n.language);
  const fieldSx = isRTL ? { '& .MuiInputBase-input': { textAlign: 'right' } } : {};

  useEffect(() => {
    if (isAuthenticated) {
      router.push('/dashboard');
    }
  }, [isAuthenticated, router]);

  const loadCountries = useCallback(async () => {
    setCountriesLoading(true);
    setCountriesError('');
    try {
      const language = (i18n.resolvedLanguage || i18n.language || 'en').startsWith('ar') ? 'ar-SA' : 'en-US';
      const res = await api.get('/Account/countries', { headers: { 'Accept-Language': language } });
      const nextCountries = Array.isArray(res.data) ? res.data : [];
      setCountries(nextCountries);
      if (nextCountries.length === 1) {
        setCountryId(nextCountries[0].id);
      }
    } catch {
      setCountriesError(t('register.failedCountries', { defaultValue: 'Failed to load countries.' }));
    } finally {
      setCountriesLoading(false);
    }
  }, [i18n.resolvedLanguage, i18n.language, t]);

  useEffect(() => {
    void loadCountries();
  }, [loadCountries]);

  const loadPackages = useCallback(async () => {
    setPackagesLoading(true);
    setPackagesError('');
    try {
      const language = (i18n.resolvedLanguage || i18n.language || 'en').startsWith('ar') ? 'ar-SA' : 'en-US';
      const res = await api.get('/SubscriptionPackages/public', {
        headers: { 'Accept-Language': language },
        skipTenantHeader: true,
      } as any);
      const nextPackages = Array.isArray(res.data) ? res.data : [];
      setPackages(nextPackages);
      if (nextPackages.length > 0) {
        setSelectedOfficeSize((current) => current || nextPackages[0].officeSize);
        setSelectedBillingCycle(nextPackages[0].monthlyOption ? "Monthly" : "Annual");
      }
    } catch {
      setPackagesError(t('register.failedPackages', { defaultValue: 'Failed to load subscription packages.' }));
    } finally {
      setPackagesLoading(false);
    }
  }, [i18n.resolvedLanguage, i18n.language, t]);

  useEffect(() => {
    void loadPackages();
  }, [loadPackages]);

  const selectedGroup = useMemo(
    () => packages.find((pkg) => pkg.officeSize === selectedOfficeSize) || null,
    [packages, selectedOfficeSize]
  );

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');
    setSuccessMessage('');

    const selectedPackageId =
      selectedBillingCycle === "Annual"
        ? selectedGroup?.annualOption?.subscriptionPackageId ?? null
        : selectedGroup?.monthlyOption?.subscriptionPackageId ?? null;

    if (password !== confirmPassword) {
      setError(t('register.passwordMismatch') || 'Passwords do not match');
      return;
    }

    if (!countryId) {
      setError(t('register.countryRequired', { defaultValue: 'Please select a country.' }));
      return;
    }

    if (!lawyerOfficeName.trim()) {
      setError(t('register.officeNameRequired', { defaultValue: 'Please enter the lawyer office name.' }));
      return;
    }

    if (!lawyerOfficePhoneNumber.trim()) {
      setError(t('register.officePhoneRequired', { defaultValue: 'Please enter the lawyer office phone number.' }));
      return;
    }

    if (!selectedPackageId) {
      setError(t('register.packageRequired', { defaultValue: 'Please select a subscription package.' }));
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
      selectedPackageId
    );
    if (result.success) {
      setSuccessMessage(result.message || t('register.pendingActivation', { defaultValue: 'Registration completed. Your account is pending activation by the system administrator.' }));
      setTimeout(() => {
        router.push('/login');
      }, 1800);
    } else {
      setError(result.message || t('register.registrationFailed') || 'Registration failed');
    }
    setLoading(false);
  };

  return (
    <AuthSplitLayout
      badge={isRTL ? 'بدء مكتب جديد' : 'NEW FIRM ONBOARDING'}
      title={t('register.workspaceTitle')}
      subtitle={t('register.workspaceSubtitle')}
      formTitle={t('register.title') || 'Sign Up'}
      formSubtitle={isRTL ? 'أكمل بيانات المكتب والحساب لاختيار الباقة المناسبة' : 'Complete office and account details, then choose the right package'}
      heroIcon={<AccountBalanceOutlined />}
      formIcon={<PersonAddOutlinedIcon />}
      footerLinkHref="/login"
      footerLinkLabel={t('register.haveAccount') || 'Already have an account? Sign in'}
      features={[
        {
          icon: <GavelOutlined fontSize="small" />,
          text: isRTL ? 'يوضح الفرق بين الباقات وخيارات الفوترة من أول خطوة' : 'Clarifies package and billing choices from the start',
        },
        {
          icon: <GroupsOutlined fontSize="small" />,
          text: isRTL ? 'يرتب بيانات المكتب والحساب في مسار واحد سهل المراجعة' : 'Keeps office and account information in one reviewable flow',
        },
        {
          icon: <ShieldOutlined fontSize="small" />,
          text: isRTL ? 'يحافظ على نفس منطق التسجيل الحالي والتنشيط اللاحق' : 'Preserves the same registration and later-activation behavior',
        },
      ]}
    >
      <Box component="form" onSubmit={handleSubmit}>
        <Stack spacing={2}>
          <Box>
            <Typography variant="subtitle2" sx={{ fontWeight: 800, mb: 1 }}>
              {t('register.package', { defaultValue: 'Subscription Package' })}
            </Typography>
            <Box
              sx={{
                display: 'grid',
                gridTemplateColumns: { xs: '1fr', xl: 'repeat(2, minmax(0, 1fr))' },
                gap: 1.5,
              }}
            >
              {packages.map((pkg) => {
                const selected = selectedOfficeSize === pkg.officeSize;
                return (
                  <Paper
                    key={pkg.officeSize}
                    component="button"
                    type="button"
                    elevation={0}
                    onClick={() => setSelectedOfficeSize(pkg.officeSize)}
                    aria-pressed={selected}
                    sx={{
                      p: 2,
                      borderRadius: 3,
                      border: '1px solid',
                      borderColor: selected ? 'primary.main' : 'divider',
                      bgcolor: selected ? 'rgba(20, 52, 90, 0.04)' : '#ffffff',
                      cursor: 'pointer',
                      textAlign: 'left',
                      '&:hover': {
                        boxShadow: 3,
                      },
                      '&:focus-visible': {
                        outline: '2px solid',
                        outlineColor: 'primary.main',
                        outlineOffset: 2,
                      },
                    }}
                  >
                    <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
                      <Typography variant="subtitle1" sx={{ fontWeight: 800 }}>
                        {pkg.name}
                      </Typography>
                      <Chip size="small" label={pkg.officeSize} color={selected ? 'primary' : 'default'} />
                    </Stack>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1.25, lineHeight: 1.7 }}>
                      {pkg.description}
                    </Typography>
                    <Stack spacing={0.5} sx={{ mb: 1.5 }}>
                      {(pkg.features || []).slice(0, 3).map((feature) => (
                        <Typography key={feature} variant="caption" color="text.secondary">
                          • {feature}
                        </Typography>
                      ))}
                    </Stack>
                    <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                      {pkg.monthlyOption ? (
                        <Chip
                          size="small"
                          variant={selected && selectedBillingCycle === "Monthly" ? "filled" : "outlined"}
                          color={selected && selectedBillingCycle === "Monthly" ? "primary" : "default"}
                          onClick={(event) => {
                            event.stopPropagation();
                            setSelectedOfficeSize(pkg.officeSize);
                            setSelectedBillingCycle("Monthly");
                          }}
                          label={`${t('subscription.billingCycle.monthly', { defaultValue: 'Monthly' })}: ${formatAmount(pkg.monthlyOption.price)}`}
                        />
                      ) : null}
                      {pkg.annualOption ? (
                        <Chip
                          size="small"
                          variant={selected && selectedBillingCycle === "Annual" ? "filled" : "outlined"}
                          color={selected && selectedBillingCycle === "Annual" ? "primary" : "default"}
                          onClick={(event) => {
                            event.stopPropagation();
                            setSelectedOfficeSize(pkg.officeSize);
                            setSelectedBillingCycle("Annual");
                          }}
                          label={`${t('subscription.billingCycle.annual', { defaultValue: 'Annual' })}: ${formatAmount(pkg.annualOption.price)}`}
                        />
                      ) : null}
                    </Stack>
                  </Paper>
                );
              })}
            </Box>
          </Box>

          {countriesError && (
            <RetryAlert message={countriesError} onRetry={loadCountries} loading={countriesLoading} />
          )}
          {packagesError && (
            <RetryAlert message={packagesError} onRetry={loadPackages} loading={packagesLoading} />
          )}
          {error ? <Alert severity="error" role="alert" aria-live="polite" sx={{ borderRadius: 3 }}>{error}</Alert> : null}
          {successMessage ? <Alert severity="success" role="status" aria-live="polite" sx={{ borderRadius: 3 }}>{successMessage}</Alert> : null}

          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, minmax(0, 1fr))' }, gap: 2 }}>
            <TextField required fullWidth id="userName" label={t('register.username') || 'Username'} value={userName} onChange={(e) => setUserName(e.target.value)} sx={fieldSx} />
            <TextField required fullWidth id="fullName" label={t('register.fullName') || 'Full Name'} value={fullName} onChange={(e) => setFullName(e.target.value)} sx={fieldSx} />
            <TextField required fullWidth id="lawyerOfficeName" label={t('register.lawyerOfficeName', { defaultValue: 'Lawyer Office Name' })} value={lawyerOfficeName} onChange={(e) => setLawyerOfficeName(e.target.value)} sx={fieldSx} />
            <TextField required fullWidth id="lawyerOfficePhoneNumber" label={t('register.lawyerOfficePhoneNumber', { defaultValue: 'Lawyer Office Phone Number' })} value={lawyerOfficePhoneNumber} onChange={(e) => setLawyerOfficePhoneNumber(e.target.value)} sx={fieldSx} />
            <SearchableSelect
              label={t('register.country', { defaultValue: 'Country' })}
              value={countryId}
              onChange={(value) => setCountryId(value === null || value === '' ? '' : Number(value))}
              options={[
                { value: '', label: t('register.selectCountry', { defaultValue: 'Select country' }) },
                ...countries.map((country) => ({ value: country.id, label: country.name })),
              ]}
              required
              sx={fieldSx}
            />
            <TextField required fullWidth id="email" label={t('register.email') || 'Email'} type="email" value={email} onChange={(e) => setEmail(e.target.value)} sx={fieldSx} />
            <TextField
              required
              fullWidth
              name="password"
              label={t('register.password') || 'Password'}
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              sx={fieldSx}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton aria-label="toggle password visibility" onClick={() => setShowPassword(!showPassword)} edge="end">
                      {showPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
            <TextField
              required
              fullWidth
              name="confirmPassword"
              label={t('register.confirmPassword') || 'Confirm Password'}
              type={showConfirmPassword ? 'text' : 'password'}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              sx={fieldSx}
              error={confirmPassword.length > 0 && password !== confirmPassword}
              helperText={confirmPassword.length > 0 && password !== confirmPassword ? t('register.passwordMismatch') || 'Passwords do not match' : ''}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton aria-label="toggle confirm password visibility" onClick={() => setShowConfirmPassword(!showConfirmPassword)} edge="end">
                      {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
          </Box>

          {selectedGroup ? (
            <Paper elevation={0} sx={{ p: 2, borderRadius: 3, bgcolor: 'rgba(20, 52, 90, 0.04)', border: '1px solid', borderColor: 'divider' }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>
                {t('register.selectedPackage', { defaultValue: 'Selected plan' })}: {selectedGroup.name}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                {selectedBillingCycle === 'Annual'
                  ? t('subscription.billingCycle.annual', { defaultValue: 'Annual' })
                  : t('subscription.billingCycle.monthly', { defaultValue: 'Monthly' })}
              </Typography>
            </Paper>
          ) : null}

          <LoadingButton type="submit" fullWidth variant="contained" size="large" loading={loading} loadingPosition="start" sx={{ py: 1.35, borderRadius: 3, fontWeight: 800 }}>
            {t('register.signUp') || 'Sign Up'}
          </LoadingButton>
        </Stack>
      </Box>
    </AuthSplitLayout>
  );
}
