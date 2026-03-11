'use client'
import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  Link as MuiLink,
  Container,
  Avatar,
  IconButton,
  InputAdornment,
  MenuItem,
  useTheme,
} from '@mui/material';
import {
  PersonAddOutlined as PersonAddOutlinedIcon,
  Visibility,
  VisibilityOff,
  AccountBalanceOutlined,
  GavelOutlined,
  ShieldOutlined,
  DescriptionOutlined,
  GroupsOutlined,
} from '@mui/icons-material';
import { useAuth } from '../../src/services/auth';
import { useTranslation } from 'react-i18next';
import api from '../../src/services/api';

type CountryOption = {
  id: number;
  name: string;
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
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { register, isAuthenticated } = useAuth();
  const router = useRouter();
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl' || (i18n.resolvedLanguage || i18n.language || '').startsWith('ar');
  const fieldSx = isRTL ? { '& .MuiInputBase-input': { textAlign: 'right' } } : {};

  // Redirect authenticated users away from register page
  useEffect(() => {
    if (isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, router]);

  useEffect(() => {
    let mounted = true;

    const loadCountries = async () => {
      try {
        const language = (i18n.resolvedLanguage || i18n.language || 'en').startsWith('ar') ? 'ar-SA' : 'en-US';
        const res = await api.get('/Account/countries', { headers: { 'Accept-Language': language } });
        if (!mounted) {
          return;
        }

        const nextCountries = Array.isArray(res.data) ? res.data : [];
        setCountries(nextCountries);

        if (nextCountries.length === 1) {
          setCountryId(nextCountries[0].id);
        }
      } catch {
        if (mounted) {
          setError(t('register.failedCountries', { defaultValue: 'Failed to load countries.' }));
        }
      }
    };

    loadCountries();
    return () => {
      mounted = false;
    };
  }, [i18n.language, i18n.resolvedLanguage, t]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');

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

    setLoading(true);

    const success = await register(
      userName,
      email,
      password,
      fullName,
      Number(countryId),
      lawyerOfficeName,
      lawyerOfficePhoneNumber
    );
    if (success) {
      router.push('/login');
    } else {
      setError(t('register.registrationFailed') || 'Registration failed');
    }
    setLoading(false);
  };

  return (
    <Box
      sx={{
        height: '100dvh',
        position: 'relative',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        px: { xs: 2, md: 4 },
        py: { xs: 1.5, md: 2 },
        '@media (max-height: 820px)': {
          py: { xs: 1, md: 1.25 },
        },
        background: 'linear-gradient(120deg, #081222 0%, #102a43 48%, #4c361b 100%)',
        '&::before': {
          content: '""',
          position: 'absolute',
          inset: '-20%',
          background:
            'radial-gradient(circle at 20% 20%, rgba(255, 210, 138, 0.2), transparent 40%), radial-gradient(circle at 80% 35%, rgba(255, 255, 255, 0.12), transparent 38%)',
          transform: 'rotate(-6deg)',
        },
        '&::after': {
          content: '""',
          position: 'absolute',
          inset: 0,
          background:
            'repeating-linear-gradient(120deg, rgba(255, 255, 255, 0.04) 0px, rgba(255, 255, 255, 0.04) 1px, transparent 1px, transparent 30px)',
        },
      }}
    >
      <Container component="main" maxWidth="lg" disableGutters dir={isRTL ? 'rtl' : 'ltr'} sx={{ position: 'relative', zIndex: 1 }}>
        <Paper
          elevation={0}
          sx={{
            width: '100%',
            maxHeight: '96dvh',
            borderRadius: 4,
            overflow: 'hidden',
            border: '1px solid rgba(255, 255, 255, 0.2)',
            boxShadow: '0 30px 70px rgba(4, 10, 19, 0.45)',
            backdropFilter: 'blur(5px)',
            background: 'rgba(18, 29, 46, 0.3)',
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: '1.1fr 0.9fr' },
            '@media (max-height: 820px)': {
              maxHeight: '98dvh',
            },
          }}
        >
          <Box
            sx={{
              p: { xs: 3, sm: 4, md: 5 },
              color: '#f8fafc',
              background: 'linear-gradient(145deg, rgba(9, 20, 36, 0.92) 0%, rgba(23, 43, 73, 0.85) 56%, rgba(90, 63, 29, 0.78) 100%)',
              borderInlineEnd: { md: '1px solid rgba(255, 255, 255, 0.18)' },
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              gap: 3,
              '@media (max-height: 820px)': {
                p: { xs: 2.2, sm: 2.6, md: 3.2 },
                gap: 2,
              },
            }}
          >
            <Box>
              <Avatar sx={{ mb: 2, width: 52, height: 52, bgcolor: 'rgba(255, 255, 255, 0.14)', border: '1px solid rgba(255, 255, 255, 0.3)', '@media (max-height: 820px)': { mb: 1.2, width: 42, height: 42 } }}>
                <AccountBalanceOutlined />
              </Avatar>
              <Typography variant="overline" sx={{ letterSpacing: '0.14em', opacity: 0.86, '@media (max-height: 820px)': { fontSize: '0.62rem' } }}>
                {isRTL ? 'نظام مكتب المحاماة' : 'LAW OFFICE PLATFORM'}
              </Typography>
              <Typography variant="h4" component="h2" sx={{ mt: 1, fontWeight: 700, lineHeight: 1.2, '@media (max-height: 820px)': { mt: 0.5, fontSize: '1.6rem' } }}>
                {isRTL ? 'إنشاء حساب جديد لفريق المكتب القانوني' : 'Create A New Account For Your Legal Team'}
              </Typography>
              <Typography variant="body1" sx={{ mt: 2, opacity: 0.84, maxWidth: 520, '@media (max-height: 820px)': { mt: 1, fontSize: '0.9rem' } }}>
                {isRTL
                  ? 'ابدأ بيئة عمل قانونية منظمة تتيح إدارة القضايا والملفات والصلاحيات من مكان واحد.'
                  : 'Set up a structured legal workspace to manage cases, files, and permissions from one place.'}
              </Typography>
            </Box>

            <Box
              aria-hidden
              sx={{
                position: 'relative',
                height: { xs: 120, md: 152 },
                borderRadius: 3,
                border: '1px solid rgba(255,255,255,0.18)',
                background:
                  'radial-gradient(circle at 20% 20%, rgba(255,255,255,0.2), transparent 42%), linear-gradient(135deg, rgba(255,255,255,0.09) 0%, rgba(255,255,255,0.03) 100%)',
                overflow: 'hidden',
                '@keyframes legalPulse': {
                  '0%, 100%': { transform: 'scale(1)', opacity: 0.45 },
                  '50%': { transform: 'scale(1.12)', opacity: 0.9 },
                },
                '@keyframes legalFloat': {
                  '0%': { transform: 'translateY(0px)' },
                  '50%': { transform: 'translateY(-8px)' },
                  '100%': { transform: 'translateY(0px)' },
                },
                '@keyframes legalOrbit': {
                  '0%': { transform: 'rotate(0deg)' },
                  '100%': { transform: 'rotate(360deg)' },
                },
                '@media (max-height: 820px)': {
                  height: { xs: 96, md: 110 },
                },
              }}
            >
              <Box
                sx={{
                  position: 'absolute',
                  inset: '50% auto auto 50%',
                  transform: 'translate(-50%, -50%)',
                  width: 56,
                  height: 56,
                  borderRadius: '50%',
                  display: 'grid',
                  placeItems: 'center',
                  background: 'rgba(255,255,255,0.14)',
                  border: '1px solid rgba(255,255,255,0.3)',
                  animation: 'legalFloat 3.4s ease-in-out infinite',
                  '@media (max-height: 820px)': {
                    width: 46,
                    height: 46,
                  },
                }}
              >
                <AccountBalanceOutlined />
              </Box>

              <Box
                sx={{
                  position: 'absolute',
                  inset: '50% auto auto 50%',
                  width: 110,
                  height: 110,
                  marginTop: '-55px',
                  marginLeft: '-55px',
                  borderRadius: '50%',
                  border: '1px dashed rgba(255,255,255,0.4)',
                  animation: 'legalOrbit 10s linear infinite',
                  '@media (max-height: 820px)': {
                    width: 84,
                    height: 84,
                    marginTop: '-42px',
                    marginLeft: '-42px',
                    animationDuration: '8s',
                  },
                }}
              >
                <Box sx={{ position: 'absolute', top: -10, left: '50%', transform: 'translateX(-50%)', color: '#fff', opacity: 0.9 }}>
                  <GavelOutlined fontSize="small" />
                </Box>
                <Box sx={{ position: 'absolute', right: -9, top: '50%', transform: 'translateY(-50%)', color: '#fff', opacity: 0.9 }}>
                  <DescriptionOutlined fontSize="small" />
                </Box>
                <Box sx={{ position: 'absolute', bottom: -10, left: '50%', transform: 'translateX(-50%)', color: '#fff', opacity: 0.9 }}>
                  <GroupsOutlined fontSize="small" />
                </Box>
              </Box>

              <Box
                sx={{
                  position: 'absolute',
                  inset: '50% auto auto 50%',
                  width: 76,
                  height: 76,
                  marginTop: '-38px',
                  marginLeft: '-38px',
                  borderRadius: '50%',
                  border: '1px solid rgba(255,255,255,0.35)',
                  animation: 'legalPulse 2.2s ease-in-out infinite',
                  '@media (max-height: 820px)': {
                    width: 62,
                    height: 62,
                    marginTop: '-31px',
                    marginLeft: '-31px',
                  },
                }}
              />
            </Box>

            <Box sx={{ display: 'grid', gap: 1.4, '@media (max-height: 820px)': { gap: 0.8 } }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                <GavelOutlined fontSize="small" />
                <Typography variant="body2" sx={{ '@media (max-height: 820px)': { fontSize: '0.8rem' } }}>
                  {isRTL ? 'إعداد سريع للحسابات القانونية الجديدة' : 'Fast onboarding for new legal accounts'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                <ShieldOutlined fontSize="small" />
                <Typography variant="body2" sx={{ '@media (max-height: 820px)': { fontSize: '0.8rem' } }}>
                  {isRTL ? 'حماية بيانات المكتب بمعايير أمان قوية' : 'Strong security for office data and access'}
                </Typography>
              </Box>
            </Box>
          </Box>

          <Box
            sx={{
              p: { xs: 3, sm: 4, md: 5 },
              background: 'rgba(251, 252, 255, 0.96)',
              textAlign: isRTL ? 'right' : 'left',
              overflow: 'hidden',
              '@media (max-height: 820px)': {
                p: { xs: 2.1, sm: 2.5, md: 3 },
              },
            }}
          >
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <Avatar sx={{ width: 48, height: 48, bgcolor: '#1e3a5f', color: '#fff', mb: 1.5, '@media (max-height: 820px)': { width: 40, height: 40, mb: 0.9 } }}>
                <PersonAddOutlinedIcon />
              </Avatar>
              <Typography component="h1" variant="h5" sx={{ fontWeight: 700, '@media (max-height: 820px)': { fontSize: '1.25rem' } }}>
                {t('register.title') || 'Sign Up'}
              </Typography>
              <Typography variant="body2" sx={{ mt: 0.8, mb: 1, color: '#4b5563', textAlign: 'center', '@media (max-height: 820px)': { mt: 0.5, mb: 0.7, fontSize: '0.82rem' } }}>
                {isRTL ? 'أنشئ حسابك للوصول إلى نظام المكتب القانوني' : 'Create your account to access the law office system'}
              </Typography>
            </Box>

            <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1, '@media (max-height: 820px)': { mt: 0.5 } }}>
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                id="userName"
                label={t('register.username') || 'Username'}
                name="userName"
                autoComplete="username"
                autoFocus
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
              />
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                id="lawyerOfficeName"
                label={t('register.lawyerOfficeName', { defaultValue: 'Lawyer Office Name' })}
                name="lawyerOfficeName"
                value={lawyerOfficeName}
                onChange={(e) => setLawyerOfficeName(e.target.value)}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
              />
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                id="lawyerOfficePhoneNumber"
                label={t('register.lawyerOfficePhoneNumber', { defaultValue: 'Lawyer Office Phone Number' })}
                name="lawyerOfficePhoneNumber"
                value={lawyerOfficePhoneNumber}
                onChange={(e) => setLawyerOfficePhoneNumber(e.target.value)}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
              />
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                select
                id="countryId"
                label={t('register.country', { defaultValue: 'Country' })}
                name="countryId"
                value={countryId}
                onChange={(e) => setCountryId(e.target.value === '' ? '' : Number(e.target.value))}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
              >
                <MenuItem value="">
                  {t('register.selectCountry', { defaultValue: 'Select country' })}
                </MenuItem>
                {countries.map((country) => (
                  <MenuItem key={country.id} value={country.id}>
                    {country.name}
                  </MenuItem>
                ))}
              </TextField>
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                id="fullName"
                label={t('register.fullName') || 'Full Name'}
                name="fullName"
                autoComplete="name"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
              />
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                id="email"
                label={t('register.email') || 'Email'}
                name="email"
                autoComplete="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
              />
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                name="password"
                label={t('register.password') || 'Password'}
                type={showPassword ? 'text' : 'password'}
                id="password"
                autoComplete="new-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
                InputProps={{
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle password visibility"
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
              />
              <TextField
                margin="dense"
                size="small"
                required
                fullWidth
                name="confirmPassword"
                label={t('register.confirmPassword') || 'Confirm Password'}
                type={showConfirmPassword ? 'text' : 'password'}
                id="confirmPassword"
                autoComplete="new-password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                sx={{
                  ...fieldSx,
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 1.6,
                    backgroundColor: '#ffffff',
                  },
                }}
                InputProps={{
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle confirm password visibility"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        edge="end"
                      >
                        {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
              />
              {error && (
                <Alert severity="error" sx={{ mt: 2, borderRadius: 1.5 }}>
                  {error}
                </Alert>
              )}
              <Button
                type="submit"
                fullWidth
                variant="contained"
                sx={{
                  mt: 2.2,
                  mb: 1.6,
                  py: 1.1,
                  borderRadius: 1.8,
                  fontWeight: 700,
                  textTransform: 'none',
                  background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
                  boxShadow: '0 10px 25px rgba(20, 52, 90, 0.34)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #112b4b 0%, #255a74 100%)',
                  },
                  '@media (max-height: 820px)': {
                    mt: 1.5,
                    mb: 1,
                    py: 0.8,
                  },
                }}
                disabled={loading}
              >
                {loading ? (t('app.loading') || 'Loading...') : (t('register.signUp') || 'Sign Up')}
              </Button>
              <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', mt: 1.2, '@media (max-height: 820px)': { mt: 0.6 } }}>
                <MuiLink href="/login" variant="body2" sx={{ color: '#1f4c74', fontWeight: 600 }}>
                  {t('register.haveAccount') || 'Already have an account? Sign in'}
                </MuiLink>
              </Box>
            </Box>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}
