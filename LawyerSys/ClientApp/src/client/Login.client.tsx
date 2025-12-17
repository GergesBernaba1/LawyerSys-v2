"use client"
import React, { useState } from 'react';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  InputAdornment,
  IconButton,
  Link,
  CircularProgress,
  useTheme,
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Person as PersonIcon,
  Lock as LockIcon,
  Gavel as GavelIcon,
} from '@mui/icons-material';
import { useAuth } from '../services/auth';
import { useTranslation } from 'react-i18next';

export default function Login() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const auth = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const ok = await auth.login(username, password);
      if (!ok) {
        setError(t('login.invalidCredentials'));
      } else {
        navigate('/');
      }
    } catch (err) {
      setError(t('login.errorOccurred'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
        p: 2,
        position: 'relative',
        overflow: 'hidden',
        '&::before': {
          content: '""',
          position: 'absolute',
          width: '140%',
          height: '140%',
          top: '-20%',
          left: '-20%',
          background: 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 70%)',
          animation: 'pulse 15s infinite alternate',
        },
        '@keyframes pulse': {
          '0%': { transform: 'scale(1) translate(0, 0)' },
          '100%': { transform: 'scale(1.1) translate(2%, 2%)' },
        }
      }}
    >
      <Card 
        elevation={0}
        sx={{ 
          maxWidth: 480, 
          width: '100%', 
          borderRadius: 6,
          bgcolor: 'rgba(255, 255, 255, 0.9)',
          backdropFilter: 'blur(20px)',
          border: '1px solid rgba(255, 255, 255, 0.3)',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
          overflow: 'visible',
          position: 'relative',
          zIndex: 1,
        }}
      >
        <Box
          sx={{
            position: 'absolute',
            top: -40,
            left: '50%',
            transform: 'translateX(-50%)',
            width: 80,
            height: 80,
            borderRadius: 4,
            bgcolor: 'primary.main',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 10px 25px -5px rgba(99, 102, 241, 0.5)',
            background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
            zIndex: 2,
          }}
        >
          <GavelIcon sx={{ fontSize: 40, color: 'white' }} />
        </Box>

        <CardContent sx={{ p: { xs: 4, sm: 6 }, pt: 8 }}>
          <Box sx={{ textAlign: 'center', mb: 5 }}>
            <Typography variant="h4" fontWeight={800} gutterBottom sx={{ letterSpacing: '-0.02em', color: 'text.primary' }}>
              {t('login.title')}
            </Typography>
            <Typography variant="body1" color="text.secondary" sx={{ fontWeight: 500 }}>
              {t('login.subtitle') || 'Welcome back! Please enter your details.'}
            </Typography>
          </Box>

          {error && (
            <Alert 
              severity="error" 
              variant="filled"
              sx={{ mb: 4, borderRadius: 3, boxShadow: '0 4px 12px rgba(239, 68, 68, 0.2)' }}
            >
              {error}
            </Alert>
          )}

          <form onSubmit={handleSubmit}>
            <Box sx={{ mb: 3 }}>
              <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                {t('login.username')}
              </Typography>
              <TextField
                fullWidth
                placeholder={t('login.usernamePlaceholder') || "Enter your username"}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PersonIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Box>

            <Box sx={{ mb: 4 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 700, color: 'text.primary' }}>
                  {t('login.password')}
                </Typography>
                <Link
                  component={RouterLink}
                  to="/forgot-password"
                  variant="body2"
                  sx={{ fontWeight: 600, textDecoration: 'none', color: 'primary.main' }}
                >
                  {t('login.forgotPassword') || 'Forgot password?'}
                </Link>
              </Box>
              <TextField
                fullWidth
                type={showPassword ? 'text' : 'password'}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <LockIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                    </InputAdornment>
                  ),
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton onClick={() => setShowPassword(!showPassword)} edge="end" size="small">
                        {showPassword ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
              />
            </Box>

            <Button
              fullWidth
              type="submit"
              variant="contained"
              size="large"
              disabled={loading}
              sx={{
                py: 2,
                borderRadius: 3,
                fontSize: '1rem',
                fontWeight: 700,
                textTransform: 'none',
                background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
                boxShadow: '0 10px 20px -5px rgba(99, 102, 241, 0.4)',
                '&:hover': {
                  boxShadow: '0 15px 25px -5px rgba(99, 102, 241, 0.5)',
                  transform: 'translateY(-1px)',
                },
                '&:active': {
                  transform: 'translateY(0)',
                },
                transition: 'all 0.2s ease-in-out',
              }}
            >
              {loading ? <CircularProgress size={24} color="inherit" /> : t('login.submit') || t('login.signIn')}
            </Button>
          </form>

          <Box sx={{ mt: 4, textAlign: 'center' }}>
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
              {t('login.dontHaveAccount') || "Don't have an account?"}{' '}
              <Link
                component={RouterLink}
                to="/register"
                sx={{ fontWeight: 700, textDecoration: 'none', color: 'primary.main' }}
              >
                {t('login.createOne') || 'Sign up for free'}
              </Link>
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
}
