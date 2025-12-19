"use client"
import React, { useState } from 'react';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
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
  Grid,
  useTheme,
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Person as PersonIcon,
  Email as EmailIcon,
  Lock as LockIcon,
  HowToReg as HowToRegIcon,
} from '@mui/icons-material';
import api from '../services/api';

export default function Register() {
  const { t } = useTranslation();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [message, setMessage] = useState<{ text: string; severity: 'success' | 'error' } | null>(null);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setMessage(null);

    if (password !== confirmPassword) {
      setMessage({ text: t('register.passwordMismatch'), severity: 'error' });
      return;
    }

    setLoading(true);
    try {
      await api.post('/Account/register', { userName: username, email, password });
      setMessage({ text: t('register.accountCreated'), severity: 'success' });
      setTimeout(() => navigate('/login'), 2000);
    } catch (err: any) {
      setMessage({ text: err?.response?.data?.message ?? t('register.registrationFailed'), severity: 'error' });
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
          maxWidth: 520, 
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
            bgcolor: 'secondary.main',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 10px 25px -5px rgba(244, 63, 94, 0.5)',
            background: 'linear-gradient(135deg, #f43f5e 0%, #fb7185 100%)',
            zIndex: 2,
          }}
        >
          <HowToRegIcon sx={{ fontSize: 40, color: 'white' }} />
        </Box>

        <CardContent sx={{ p: { xs: 4, sm: 6 }, pt: 8 }}>
          <Box sx={{ textAlign: 'center', mb: 5 }}>
            <Typography variant="h4" fontWeight={800} gutterBottom sx={{ letterSpacing: '-0.02em', color: 'text.primary' }}>
              {t('register.title')}
            </Typography>
            <Typography variant="body1" color="text.secondary" sx={{ fontWeight: 500 }}>
              {t('register.subtitle') || 'Join our legal community today.'}
            </Typography>
          </Box>

          {message && (
            <Alert 
              severity={message.severity} 
              variant="filled"
              sx={{ mb: 4, borderRadius: 3, boxShadow: message.severity === 'success' ? '0 4px 12px rgba(16, 185, 129, 0.2)' : '0 4px 12px rgba(239, 68, 68, 0.2)' }}
            >
              {message.text}
            </Alert>
          )}

          <form onSubmit={handleSubmit}>
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)' }, gap: 2.5 }}>
              <Box sx={{ gridColumn: '1 / -1' }}>
                <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                  {t('register.username')}
                </Typography>
                <TextField
                  fullWidth
                  placeholder={t('register.usernamePlaceholder') || "Choose a username"}
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
              <Box sx={{ gridColumn: '1 / -1' }}>
                <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                  {t('register.email')}
                </Typography>
                <TextField
                  fullWidth
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  sx={{ '& .MuiOutlinedInput-root': { borderRadius: 3, bgcolor: 'white' } }}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <EmailIcon sx={{ color: 'primary.main', fontSize: 20 }} />
                      </InputAdornment>
                    ),
                  }}
                />
              </Box>
              <Box>
                <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                  {t('register.password')}
                </Typography>
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
                  }}
                />
              </Box>
              <Box>
                <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 700, color: 'text.primary', textAlign: isRTL ? 'right' : 'left' }}>
                  {t('register.confirmPassword')}
                </Typography>
                <TextField
                  fullWidth
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
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
            </Box>

            <Button
              fullWidth
              type="submit"
              variant="contained"
              size="large"
              disabled={loading}
              sx={{
                mt: 4,
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
              {loading ? <CircularProgress size={24} color="inherit" /> : t('register.createAccount')}
            </Button>
          </form>

          <Box sx={{ mt: 4, textAlign: 'center' }}>
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
              {t('register.alreadyHaveAccount')}{' '}
              <Link
                component={RouterLink}
                to="/login"
                sx={{ fontWeight: 700, textDecoration: 'none', color: 'primary.main' }}
              >
                {t('register.signIn')}
              </Link>
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
}
