'use client'
import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Alert,
  Box,
  Button,
  IconButton,
  InputAdornment,
  Link as MuiLink,
  Stack,
  TextField,
  Typography,
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
import AuthSplitLayout from '../../src/components/auth/AuthSplitLayout';

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

  useEffect(() => {
    if (!isAuthInitialized || !isAuthenticated || !user) return;

    const isCustomerOnly =
      hasRole('Customer') &&
      !hasRole('Admin') &&
      !hasRole('Employee') &&
      !hasRole('SuperAdmin');

    router.replace(isCustomerOnly ? '/client-portal' : '/dashboard');
  }, [isAuthenticated, isAuthInitialized, user, hasRole, router]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');
    setLoading(true);

    const result = await login(userName, password);
    if (!result.success) {
      setError(result.message || t('login.invalidCredentials') || 'Invalid credentials');
      setLoading(false);
    }
  };

  return (
    <AuthSplitLayout
      badge={isRTL ? 'منصة تشغيل قانونية' : 'LEGAL OPERATIONS PLATFORM'}
      title={t('login.workspaceTitle')}
      subtitle={t('login.workspaceSubtitle')}
      formTitle={t('app.login')}
      formSubtitle={isRTL ? 'الوصول الآمن إلى لوحة التحكم وأدوات المكتب' : 'Secure access to your dashboard and office tools'}
      heroIcon={<AccountBalanceOutlined />}
      formIcon={<LockOutlinedIcon />}
      footerLinkHref="/"
      footerLinkLabel={isRTL ? 'العودة إلى الرئيسية' : 'Back to home'}
      features={[
        {
          icon: <GavelOutlined fontSize="small" />,
          text: isRTL ? 'الوصول السريع إلى القضايا والجلسات من نفس الواجهة' : 'Reach cases and hearings quickly from one consistent workspace',
        },
        {
          icon: <ShieldOutlined fontSize="small" />,
          text: isRTL ? 'نفس ضوابط الوصول الحالية مع عرض أوضح للحقول والإجراءات' : 'The same access controls with clearer field and action presentation',
        },
      ]}
    >
      <Box component="form" onSubmit={handleSubmit}>
        <Stack spacing={2}>
          <TextField
            required
            fullWidth
            id="userName"
            label={t('login.username') || 'Username'}
            name="userName"
            autoComplete="username"
            autoFocus
            value={userName}
            onChange={(e) => setUserName(e.target.value)}
            sx={fieldSx}
          />
          <TextField
            required
            fullWidth
            name="password"
            label={t('login.password') || 'Password'}
            type={showPassword ? 'text' : 'password'}
            id="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            sx={fieldSx}
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
          {error ? (
            <Alert severity="error" sx={{ borderRadius: 3 }}>
              {error}
            </Alert>
          ) : null}
          <Button
            type="submit"
            fullWidth
            variant="contained"
            size="large"
            disabled={loading}
            sx={{ mt: 1, py: 1.35, borderRadius: 3, fontWeight: 800 }}
          >
            {loading ? (t('app.loading') || 'Loading...') : t('app.login')}
          </Button>
        </Stack>

        <Box sx={{ display: 'flex', justifyContent: 'space-between', flexDirection: isRTL ? 'row-reverse' : 'row', mt: 2.5, gap: 2, flexWrap: 'wrap' }}>
          <MuiLink href="/forgot-password" variant="body2" sx={{ color: 'primary.main', fontWeight: 700 }}>
            {t('login.forgotPassword') || 'Forgot password?'}
          </MuiLink>
          <MuiLink href="/register" variant="body2" sx={{ color: 'primary.main', fontWeight: 700 }}>
            {t('login.noAccount') || "Don't have an account? Sign Up"}
          </MuiLink>
        </Box>

      </Box>
    </AuthSplitLayout>
  );
}
