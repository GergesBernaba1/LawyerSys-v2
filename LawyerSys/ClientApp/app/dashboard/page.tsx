"use client"
import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Paper,
  IconButton,
  Skeleton,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Divider,
  useTheme,
  alpha,
} from '@mui/material';
import Grid from '@mui/material/Grid2'
import {
  Gavel as GavelIcon,
  People as PeopleIcon,
  Badge as BadgeIcon,
  Folder as FolderIcon,
  Event as EventIcon,
  Receipt as ReceiptIcon,
  OpenInNew as OpenInNewIcon,
  ArrowForward as ArrowForwardIcon,
  TrendingUp as TrendingUpIcon,
  WavingHand as WavingHandIcon,
} from '@mui/icons-material';
import { useRouter, useParams } from 'next/navigation';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';

function StatCard({ title, value, icon, color, loading, onClick }: any) {
  const theme = useTheme();
  return (
    <Card
      elevation={0}
      sx={{
        height: '100%',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        borderRadius: 4,
        border: '1px solid',
        borderColor: 'divider',
        '&:hover': onClick
          ? {
              transform: 'translateY(-4px)',
              boxShadow: `0 12px 24px -10px ${alpha(color, 0.3)}`,
              borderColor: alpha(color, 0.5),
            }
          : {},
      }}
      onClick={onClick}
    >
      <CardContent sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box>
            <Typography variant="subtitle2" color="text.secondary" fontWeight={600} gutterBottom>
              {title}
            </Typography>
            {loading ? (
              <Skeleton width={60} height={40} />
            ) : (
              <Typography variant="h4" fontWeight={800} sx={{ color: 'text.primary', letterSpacing: '-0.02em' }}>
                {value}
              </Typography>
            )}
          </Box>
          <Avatar 
            sx={{ 
              width: 56, 
              height: 56, 
              borderRadius: 3,
              background: `linear-gradient(135deg, ${color} 0%, ${alpha(color, 0.7)} 100%)`,
              boxShadow: `0 8px 16px -4px ${alpha(color, 0.4)}`,
              color: 'white'
            }}
          >
            {React.cloneElement(icon, { sx: { fontSize: 28 } })}
          </Avatar>
        </Box>
        {!loading && (
          <Box sx={{ mt: 2, display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <TrendingUpIcon sx={{ fontSize: 16, color: 'success.main' }} />
            <Typography variant="caption" fontWeight={700} color="success.main">
              +12%
            </Typography>
            <Typography variant="caption" color="text.secondary" sx={{ ml: 0.5 }}>
              {title.toLowerCase().includes('cases') ? 'this month' : 'since last week'}
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
}

export default function DashboardPageClient() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams() as { locale?: string } | undefined;
  const locale = params?.locale || 'ar';
  const { isAuthenticated, user } = useAuth();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl' || locale.startsWith('ar');
  const [stats, setStats] = useState({ cases: 0, customers: 0, employees: 0, files: 0 });
  const [loading, setLoading] = useState(true);
  const [recentCases, setRecentCases] = useState<any[]>([]);

  useEffect(() => {
    async function fetchStats() {
      try {
        const [casesRes, customersRes, employeesRes, filesRes] = await Promise.all([
          api.get('/Cases').catch(() => ({ data: [] })),
          api.get('/Customers').catch(() => ({ data: [] })),
          api.get('/Employees').catch(() => ({ data: [] })),
          api.get('/Files').catch(() => ({ data: [] })),
        ]);
        setStats({
          cases: casesRes.data?.length || 0,
          customers: customersRes.data?.length || 0,
          employees: employeesRes.data?.length || 0,
          files: filesRes.data?.length || 0,
        });
        setRecentCases((casesRes.data || []).slice(0, 5));
      } catch (e) {
        console.error('Error fetching stats:', e);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  const navigate = (path: string) => {
    const target = `/${locale}${path}`
    router.push(target)
  }

  const quickActions = [
    { label: t('dashboard.newCase'), path: '/cases', icon: <GavelIcon />, color: '#6366f1' },
    { label: t('dashboard.newCustomer'), path: '/customers', icon: <PeopleIcon />, color: '#a855f7' },
    { label: t('dashboard.viewBilling'), path: '/billing', icon: <ReceiptIcon />, color: '#f43f5e' },
    { label: t('dashboard.adminTasks'), path: '/tasks', icon: <EventIcon />, color: '#10b981' },
  ];

  return (
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4 }}>
      {/* Welcome Section */}
      <Paper 
        elevation={0}
        sx={{ 
          p: { xs: 3, md: 4 }, 
          mb: 4, 
          background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)', 
          color: 'white', 
          borderRadius: 5,
          position: 'relative',
          overflow: 'hidden',
          boxShadow: '0 20px 40px -12px rgba(99, 102, 241, 0.35)',
          '&::after': {
            content: '""',
            position: 'absolute',
            top: -50,
            right: -50,
            width: 200,
            height: 200,
            borderRadius: '50%',
            background: 'rgba(255, 255, 255, 0.1)',
          }
        }}
      >
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative', zIndex: 1 }}>
          <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
              <WavingHandIcon sx={{ color: '#fbbf24' }} />
              <Typography variant="h4" fontWeight={800} sx={{ letterSpacing: '-0.02em' }}>
                {t('dashboard.welcomeBack')}{user ? `, ${user.fullName || user.userName || 'User'}` : ''}!
              </Typography>
            </Box>
            <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 500, maxWidth: 600 }}>
              {t('dashboard.subtitle') || 'Here is what is happening with your legal practice today.'}
            </Typography>
          </Box>
          <Box sx={{ display: { xs: 'none', md: 'block' } }}>
            <Button 
              variant="contained" 
              sx={{ 
                bgcolor: 'white', 
                color: 'primary.main', 
                fontWeight: 700,
                px: 3,
                py: 1.5,
                borderRadius: 3,
                '&:hover': { bgcolor: alpha('#white', 0.9) }
              }}
              onClick={() => navigate('/cases')}
            >
              {t('dashboard.viewAllCases') || 'View All Cases'}
            </Button>
          </Box>
        </Box>
      </Paper>

      {/* Stats Grid */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard title={t('dashboard.totalCases')} value={stats.cases} icon={<GavelIcon />} color="#6366f1" loading={loading} onClick={() => navigate('/cases')} />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard title={t('dashboard.customers')} value={stats.customers} icon={<PeopleIcon />} color="#a855f7" loading={loading} onClick={() => navigate('/customers')} />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard title={t('dashboard.employees')} value={stats.employees} icon={<BadgeIcon />} color="#06b6d4" loading={loading} onClick={() => navigate('/employees')} />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard title={t('dashboard.files')} value={stats.files} icon={<FolderIcon />} color="#f59e0b" loading={loading} onClick={() => navigate('/files')} />
        </Grid>
      </Grid>

      {/* Quick Actions & Recent Cases */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider', height: '100%' }}>
            <Typography variant="h6" fontWeight={800} sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 1 }}>
              <OpenInNewIcon sx={{ color: 'primary.main' }} />
              {t('dashboard.quickActions')}
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {quickActions.map((action) => (
                <Button 
                  key={action.label} 
                  variant="outlined" 
                  startIcon={!isRTL ? action.icon : undefined} 
                  endIcon={isRTL ? action.icon : undefined} 
                  onClick={() => navigate(action.path)} 
                  sx={{ 
                    justifyContent: isRTL ? 'flex-end' : 'flex-start', 
                    py: 2, 
                    px: 2.5,
                    borderRadius: 3,
                    borderWidth: 2,
                    fontWeight: 700,
                    color: 'text.primary',
                    borderColor: alpha(action.color, 0.2),
                    '&:hover': {
                      borderColor: action.color,
                      bgcolor: alpha(action.color, 0.05),
                      borderWidth: 2,
                    }
                  }} 
                  fullWidth
                >
                  {action.label}
                </Button>
              ))}
            </Box>
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, md: 8 }}>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider', height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
              <Typography variant="h6" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <GavelIcon sx={{ color: 'primary.main' }} />
                {t('dashboard.recentCases')}
              </Typography>
              <Button 
                size="small" 
                endIcon={isRTL ? <ArrowForwardIcon sx={{ transform: 'rotate(180deg)' }} /> : <ArrowForwardIcon />} 
                onClick={() => navigate('/cases')}
                sx={{ fontWeight: 700 }}
              >
                {t('app.viewAll')}
              </Button>
            </Box>
            {loading ? (
              <Box>{[1,2,3].map(i => <Skeleton key={i} height={80} sx={{ mb: 1, borderRadius: 2 }} />)}</Box>
            ) : recentCases.length > 0 ? (
              <List disablePadding>
                {recentCases.map((c, index) => (
                  <React.Fragment key={c.caseId}>
                    <ListItem 
                      sx={{ 
                        px: 2, 
                        py: 1.5,
                        cursor: 'pointer', 
                        '&:hover': { bgcolor: 'action.hover' }, 
                        borderRadius: 3,
                        mb: index < recentCases.length - 1 ? 1 : 0
                      }} 
                      onClick={() => navigate('/cases')}
                    >
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: alpha(theme.palette.primary.main, 0.1), color: 'primary.main', borderRadius: 2 }}>
                          <GavelIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText 
                        primary={<Typography fontWeight={700}>{c.caseName || `${t('cases.caseNumber')} ${c.caseId}`}</Typography>} 
                        secondary={c.caseNumber || t('cases.noCaseNumber')} 
                      />
                      <Chip 
                        label={c.caseType || t('cases.general')} 
                        size="small" 
                        sx={{ 
                          fontWeight: 700, 
                          bgcolor: alpha(theme.palette.primary.main, 0.1),
                          color: 'primary.main',
                          border: 'none'
                        }} 
                      />
                    </ListItem>
                    {index < recentCases.length - 1 && <Divider variant="inset" component="li" sx={{ opacity: 0.5, my: 0.5 }} />}
                  </React.Fragment>
                ))}
              </List>
            ) : (
              <Box sx={{ textAlign: 'center', py: 6, color: 'text.secondary' }}>
                <Avatar sx={{ width: 80, height: 80, bgcolor: 'action.hover', mx: 'auto', mb: 2 }}>
                  <GavelIcon sx={{ fontSize: 40, opacity: 0.3 }} />
                </Avatar>
                <Typography variant="h6" fontWeight={700}>{t('dashboard.noRecentCases')}</Typography>
                <Typography variant="body2" sx={{ mb: 3 }}>Start by adding your first legal case.</Typography>
                <Button 
                  variant="contained" 
                  sx={{ borderRadius: 3, px: 4, py: 1.5, fontWeight: 700 }} 
                  onClick={() => navigate('/cases')}
                >
                  {t('dashboard.createFirstCase')}
                </Button>
              </Box>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* System Info */}
      <Paper 
        elevation={0}
        sx={{ 
          mt: 4, 
          p: 2.5, 
          borderRadius: 4, 
          bgcolor: alpha(theme.palette.primary.main, 0.03),
          border: '1px dashed',
          borderColor: alpha(theme.palette.primary.main, 0.2)
        }}
      >
        <Box sx={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 2 }}>
          <Typography variant="body2" fontWeight={700} color="text.secondary">
            {t('dashboard.systemStatus') || 'System Status'}:
          </Typography>
          <Chip 
            label={isAuthenticated ? t('dashboard.authenticated') : t('dashboard.notAuthenticated')} 
            size="small" 
            color={isAuthenticated ? "success" : "warning"} 
            sx={{ fontWeight: 700 }}
          />
          <Divider orientation="vertical" flexItem sx={{ mx: 1 }} />
          <Typography variant="caption" color="text.secondary">
            <strong>API:</strong> {process?.env?.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000/api'}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            <strong>Session:</strong> {isAuthenticated ? 'Active' : 'None'}
          </Typography>
        </Box>
      </Paper>
    </Box>
  )
}
