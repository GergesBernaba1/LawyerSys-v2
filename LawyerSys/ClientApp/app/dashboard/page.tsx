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
import { Grid } from '@mui/material'
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

function StatCard({ title, value, icon, color, loading, onClick, trend, trendLabel }: any) {
  const { t } = useTranslation();
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
        {!loading && typeof trend === 'number' && (
          <Box sx={{ mt: 2, display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <TrendingUpIcon sx={{ fontSize: 16, color: trend >= 0 ? 'success.main' : 'error.main' }} />
            <Typography variant="caption" fontWeight={700} color={trend >= 0 ? 'success.main' : 'error.main'}>
              {trend >= 0 ? '+' : ''}{trend}%
            </Typography>
            <Typography variant="caption" color="text.secondary" sx={{ ml: 0.5 }}>
              {trendLabel || t('dashboard.thisMonth')}
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
  const [stats, setStats] = useState({
    cases: 0,
    customers: 0,
    employees: 0,
    files: 0,
    casesTrend: 0,
    revenueThisMonth: 0,
    revenueTrend: 0,
    upcomingHearings: 0,
    overdueTasks: 0,
  });
  const [loading, setLoading] = useState(true);
  const [recentCases, setRecentCases] = useState<any[]>([]);
  const numberLocale = isRTL ? 'ar' : 'en-US'

  useEffect(() => {
    async function fetchStats() {
      try {
        const analyticsRes = await api.get('/Dashboard/analytics');
        const analytics = analyticsRes.data || {};

        setStats({
          cases: analytics.totals?.cases || 0,
          customers: analytics.totals?.customers || 0,
          employees: analytics.totals?.employees || 0,
          files: analytics.totals?.files || 0,
          casesTrend: analytics.trends?.casesChangePercent || 0,
          revenueThisMonth: analytics.trends?.revenueThisMonth || 0,
          revenueTrend: analytics.trends?.revenueChangePercent || 0,
          upcomingHearings: analytics.alerts?.upcomingHearings || 0,
          overdueTasks: analytics.alerts?.overdueTasks || 0,
        });

        const casesRes = await api.get('/Cases?page=1&pageSize=5').catch(() => ({ data: { items: [] } }));
        const caseItems = Array.isArray(casesRes.data) ? casesRes.data : (casesRes.data?.items || []);
        setRecentCases(caseItems.slice(0, 5));
      } catch (e) {
        // fallback if analytics endpoint is unavailable
        try {
          const [casesRes, customersRes, employeesRes, filesRes] = await Promise.all([
            api.get('/Cases').catch(() => ({ data: [] })),
            api.get('/Customers').catch(() => ({ data: [] })),
            api.get('/Employees').catch(() => ({ data: [] })),
            api.get('/Files').catch(() => ({ data: [] })),
          ]);
          const casesData = Array.isArray(casesRes.data) ? casesRes.data : (casesRes.data?.items || []);
          const customersData = Array.isArray(customersRes.data) ? customersRes.data : (customersRes.data?.items || []);
          const employeesData = Array.isArray(employeesRes.data) ? employeesRes.data : (employeesRes.data?.items || []);
          const filesData = Array.isArray(filesRes.data) ? filesRes.data : (filesRes.data?.items || []);
          setStats(prev => ({
            ...prev,
            cases: casesData.length || 0,
            customers: customersData.length || 0,
            employees: employeesData.length || 0,
            files: filesData.length || 0,
          }));
          setRecentCases(casesData.slice(0, 5));
        } catch {
          console.error('Error fetching stats');
        }
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
    <Box dir={isRTL ? 'rtl' : 'ltr'} sx={{ pb: 4, minHeight: '100vh', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
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
              aria-label="view-all-cases"
              variant="contained"
              sx={{
                bgcolor: 'rgba(255,255,255,0.95)',
                color: 'rgba(255,255,255,0.95)',
                fontWeight: 800,
                px: { xs: 2.5, md: 3 },
                py: { xs: 1, md: 1.5 },
                minWidth: 160,
                borderRadius: 3,
                boxShadow: '0 8px 20px -12px rgba(0,0,0,0.18)',
                border: '1px solid',
                borderColor: alpha('#ffffff', 0.18),
                transition: 'transform 150ms ease, box-shadow 150ms ease, background-color 150ms ease',
                '&:hover': {
                  bgcolor: 'rgba(255,255,255,1)',
                  transform: 'translateY(-2px)',
                  boxShadow: '0 12px 28px -16px rgba(0,0,0,0.22)'
                }
              }}
              onClick={() => navigate('/cases')}
            >
              {t('dashboard.viewAllCases') || 'View All Cases'}
            </Button>
          </Box>
        </Box>
      </Paper>

      <Box sx={{ flex: 1, overflowY: 'auto', px: { xs: 2, md: 0 } }}>
        {/* Stats Grid */}
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }, gap: 3, mb: 4 }}>
          <Box><StatCard title={t('dashboard.totalCases')} value={stats.cases} icon={<GavelIcon />} color="#6366f1" loading={loading} onClick={() => navigate('/cases')} trend={stats.casesTrend} trendLabel={t('dashboard.thisMonth')} /></Box>
          <Box><StatCard title={t('dashboard.customers')} value={stats.customers} icon={<PeopleIcon />} color="#a855f7" loading={loading} onClick={() => navigate('/customers')} /></Box>
          <Box><StatCard title={t('dashboard.employees')} value={stats.employees} icon={<BadgeIcon />} color="#06b6d4" loading={loading} onClick={() => navigate('/employees')} /></Box>
          <Box><StatCard title={t('dashboard.files')} value={stats.files} icon={<FolderIcon />} color="#f59e0b" loading={loading} onClick={() => navigate('/files')} /></Box>
        </Box>

        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 3, mb: 4 }}>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
            <Typography variant="subtitle2" color="text.secondary" fontWeight={700}>{t('billing.title') || 'Billing'}</Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>
              {stats.revenueThisMonth.toLocaleString(numberLocale, { maximumFractionDigits: 2 })}
            </Typography>
            <Typography variant="caption" color={stats.revenueTrend >= 0 ? 'success.main' : 'error.main'} fontWeight={700}>
              {stats.revenueTrend >= 0 ? '+' : ''}{stats.revenueTrend}% {t('dashboard.thisMonth')}
            </Typography>
          </Paper>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
            <Typography variant="subtitle2" color="text.secondary" fontWeight={700}>{t('sitings.upcoming') || 'Upcoming Hearings'}</Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>{stats.upcomingHearings}</Typography>
          </Paper>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider' }}>
            <Typography variant="subtitle2" color="text.secondary" fontWeight={700}>{t('tasks.overdue') || 'Overdue Tasks'}</Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>{stats.overdueTasks}</Typography>
          </Paper>
        </Box>
      {/* Quick Actions & Recent Cases */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 2fr' }, gap: 3 }}>
        <Box>
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
        </Box>
        <Box>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 4, border: '1px solid', borderColor: 'divider', height: '100%', maxHeight: 520, overflowY: 'auto' }}>
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
                <Typography variant="body2" sx={{ mb: 3 }}>{t('dashboard.startFirstCase')}</Typography>
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
        </Box>
      </Box>

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
      </Paper>
    </Box>
  </Box>
  )
}
