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
  useTheme,
} from '@mui/material';
import {
  LockOutlined as LockOutlinedIcon,
  Visibility,
  VisibilityOff,
  AccountBalanceOutlined,
  GavelOutlined,
  ShieldOutlined,
} from '@mui/icons-material';
import { useAuth } from '../../src/services/auth';
import { useTranslation } from 'react-i18next';

export default function LoginPage() {
  const [userName, setUserName] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login, isAuthenticated, isAuthInitialized, user, hasRole } = useAuth();
  const router = useRouter();
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl' || (i18n.resolvedLanguage || i18n.language || '').startsWith('ar');
  const fieldSx = isRTL ? { '& .MuiInputBase-input': { textAlign: 'right' } } : {};

  // Redirect authenticated users away from login page
  useEffect(() => {
    if (!isAuthInitialized) return;
    if (!isAuthenticated) return;
    if (!user) return;

    const isCustomerOnly =
      hasRole('Customer') &&
      !hasRole('Admin') &&
      !hasRole('Employee') &&
      !hasRole('SuperAdmin');

    if (isCustomerOnly) {
      router.replace('/client-portal');
    } else {
      router.replace('/dashboard');
    }
  }, [isAuthenticated, isAuthInitialized, user, hasRole, router]);


  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');
    setLoading(true);

    const result = await login(userName, password);
    if (result.success) {
      return;
    } else {
      setError(result.message || t('login.invalidCredentials') || 'Invalid credentials');
    }
    setLoading(false);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        position: 'relative',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        px: { xs: 2, md: 4 },
        py: { xs: 3, md: 6 },
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
            borderRadius: 4,
            overflow: 'hidden',
            border: '1px solid rgba(255, 255, 255, 0.2)',
            boxShadow: '0 30px 70px rgba(4, 10, 19, 0.45)',
            backdropFilter: 'blur(5px)',
            background: 'rgba(18, 29, 46, 0.3)',
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: '1.1fr 0.9fr' },
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
              gap: 4,
            }}
          >
            <Box>
              <Avatar sx={{ mb: 2, width: 52, height: 52, bgcolor: 'rgba(255, 255, 255, 0.14)', border: '1px solid rgba(255, 255, 255, 0.3)' }}>
                <AccountBalanceOutlined />
              </Avatar>
              <Typography variant="overline" sx={{ letterSpacing: '0.14em', opacity: 0.86 }}>
                {isRTL ? 'نظام مكتب المحاماة' : 'LAW OFFICE PLATFORM'}
              </Typography>
              <Typography variant="h4" component="h2" sx={{ mt: 1, fontWeight: 700, lineHeight: 1.2 }}>
                {isRTL ? 'إدارة القضايا والمستندات بثقة واحترافية' : 'Manage Cases And Documents With Confidence'}
              </Typography>
              <Typography variant="body1" sx={{ mt: 2, opacity: 0.84, maxWidth: 520 }}>
                {isRTL
                  ? 'واجهة آمنة مصممة لبيئة العمل القانوني مع تنظيم دقيق للملفات والجلسات وسير العمل.'
                  : 'A secure workspace tailored for legal teams, built to keep cases, hearings, and documents under control.'}
              </Typography>
            </Box>

            <Box sx={{ display: 'grid', gap: 1.4 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                <GavelOutlined fontSize="small" />
                <Typography variant="body2">
                  {isRTL ? 'متابعة القضايا والجلسات في لوحة واحدة' : 'Track cases and hearings from a single dashboard'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                <ShieldOutlined fontSize="small" />
                <Typography variant="body2">
                  {isRTL ? 'دخول محمي وصلاحيات دقيقة للمستخدمين' : 'Protected access with role-based permissions'}
                </Typography>
              </Box>
            </Box>
          </Box>

          <Box
            sx={{
              p: { xs: 3, sm: 4, md: 5 },
              background: 'rgba(251, 252, 255, 0.96)',
              textAlign: isRTL ? 'right' : 'left',
            }}
          >
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <Avatar sx={{ width: 48, height: 48, bgcolor: '#1e3a5f', color: '#fff', mb: 1.5 }}>
                <LockOutlinedIcon />
              </Avatar>
              <Typography component="h1" variant="h5" sx={{ fontWeight: 700 }}>
                {t('app.login')}
              </Typography>
              <Typography variant="body2" sx={{ mt: 0.8, mb: 1, color: '#4b5563', textAlign: 'center' }}>
                {isRTL ? 'تسجيل دخول آمن إلى نظام إدارة المكتب' : 'Secure sign in to your law office workspace'}
              </Typography>
            </Box>

            <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
              <TextField
                margin="normal"
                required
                fullWidth
                id="userName"
                label={t('login.username') || 'Username'}
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
                margin="normal"
                required
                fullWidth
                name="password"
                label={t('login.password') || 'Password'}
                type={showPassword ? 'text' : 'password'}
                id="password"
                autoComplete="current-password"
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
                  mt: 3,
                  mb: 2,
                  py: 1.1,
                  borderRadius: 1.8,
                  fontWeight: 700,
                  textTransform: 'none',
                  background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
                  boxShadow: '0 10px 25px rgba(20, 52, 90, 0.34)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #112b4b 0%, #255a74 100%)',
                  },
                }}
                disabled={loading}
              >
                {loading ? (t('app.loading') || 'Loading...') : t('app.login')}
              </Button>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', flexDirection: isRTL ? 'row-reverse' : 'row', mt: 2, gap: 2 }}>
                <MuiLink href="/forgot-password" variant="body2" sx={{ color: '#1f4c74', fontWeight: 600 }}>
                  {t('login.forgotPassword') || 'Forgot password?'}
                </MuiLink>
                <MuiLink href="/register" variant="body2" sx={{ color: '#1f4c74', fontWeight: 600 }}>
                  {t('login.noAccount') || "Don't have an account? Sign Up"}
                </MuiLink>
              </Box>
            </Box>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}
