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
import { PersonAddOutlined as PersonAddOutlinedIcon, Visibility, VisibilityOff } from '@mui/icons-material';
import { useAuth } from '../../src/services/auth';
import { useTranslation } from 'react-i18next';

export default function RegisterPage() {
  const [userName, setUserName] = useState('');
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { register, isAuthenticated } = useAuth();
  const router = useRouter();
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl' || (i18n.resolvedLanguage || i18n.language || '').startsWith('ar');
  const fieldSx = isRTL ? { '& .MuiInputBase-input': { textAlign: 'right' } } : undefined;

  // Redirect authenticated users away from register page
  useEffect(() => {
    if (isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, router]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');

    if (password !== confirmPassword) {
      setError(t('register.passwordMismatch') || 'Passwords do not match');
      return;
    }

    setLoading(true);

    const success = await register(userName, email, password, fullName);
    if (success) {
      router.push('/login');
    } else {
      setError(t('register.registrationFailed') || 'Registration failed');
    }
    setLoading(false);
  };

  return (
    <Container component="main" maxWidth="sm" dir={isRTL ? 'rtl' : 'ltr'}>
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          textAlign: isRTL ? 'right' : 'left',
        }}
      >
        <Avatar sx={{ m: 1, bgcolor: 'primary.main' }}>
          <PersonAddOutlinedIcon />
        </Avatar>
        <Typography component="h1" variant="h5" sx={{ width: '100%', textAlign: 'center' }}>
          {t('register.title') || 'Sign Up'}
        </Typography>
        <Paper
          elevation={3}
          sx={{
            padding: 4,
            width: '100%',
            mt: 2,
          }}
        >
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <TextField
              margin="normal"
              required
              fullWidth
              id="userName"
              label={t('register.username') || 'Username'}
              name="userName"
              autoComplete="username"
              autoFocus
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
              sx={fieldSx}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="fullName"
              label={t('register.fullName') || 'Full Name'}
              name="fullName"
              autoComplete="name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              sx={fieldSx}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label={t('register.email') || 'Email'}
              name="email"
              autoComplete="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              sx={fieldSx}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label={t('register.password') || 'Password'}
              type={showPassword ? 'text' : 'password'}
              id="password"
              autoComplete="new-password"
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
            <TextField
              margin="normal"
              required
              fullWidth
              name="confirmPassword"
              label={t('register.confirmPassword') || 'Confirm Password'}
              type={showConfirmPassword ? 'text' : 'password'}
              id="confirmPassword"
              autoComplete="new-password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              sx={fieldSx}
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
              <Alert severity="error" sx={{ mt: 2 }}>
                {error}
              </Alert>
            )}
            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2 }}
              disabled={loading}
            >
              {loading ? (t('app.loading') || 'Loading...') : (t('register.signUp') || 'Sign Up')}
            </Button>
            <Box sx={{ display: 'flex', justifyContent: isRTL ? 'flex-start' : 'flex-end', mt: 2 }}>
              <MuiLink href="/login" variant="body2">
                {t('register.haveAccount') || 'Already have an account? Sign in'}
              </MuiLink>
            </Box>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
}
