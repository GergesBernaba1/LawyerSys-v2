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
  Skeleton,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  LinearProgress,
  Stack,
  Divider,
  useTheme,
  alpha,
} from '@mui/material';
import {
  Gavel as GavelIcon,
  People as PeopleIcon,
  Badge as BadgeIcon,
  Folder as FolderIcon,
  AssignmentTurnedIn as TaskIcon,
  Event as EventIcon,
  Receipt as ReceiptIcon,
  OpenInNew as OpenInNewIcon,
  ArrowForward as ArrowForwardIcon,
  TrendingUp as TrendingUpIcon,
  Refresh as RefreshIcon,
  AccessTime as AccessTimeIcon,
  WarningAmber as WarningAmberIcon,
  WavingHand as WavingHandIcon,
} from '@mui/icons-material';
import { useRouter } from 'next/navigation';
import api from '../../src/services/api';
import { useAuth } from '../../src/services/auth';
import { useCurrency } from '../../src/hooks/useCurrency';

function StatCard({ title, value, icon, color, loading, onClick, trend, trendLabel, animationDelay = 0 }: any) {
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
        animation: 'scale-in 0.35s ease-out both',
        animationDelay: `${animationDelay}ms`,
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
  const { t, i18n } = useTranslation();
  const router = useRouter();
  const { isAuthenticated, user, hasRole } = useAuth();
  const { formatCurrency } = useCurrency();
  const theme = useTheme();
  const currentLanguage = i18n.resolvedLanguage || i18n.language || 'ar';
  const isRTL = theme.direction === 'rtl' || currentLanguage.startsWith('ar');
  const locale = currentLanguage.startsWith('ar') ? 'ar-SA' : 'en-US';
  const isSuperAdmin = hasRole('SuperAdmin');
  const isEmployeeOnly = hasRole('Employee') && !hasRole('Admin') && !isSuperAdmin;
  const isCustomerOnly = hasRole('Customer') && !hasRole('Admin') && !hasRole('Employee') && !isSuperAdmin;
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
  const [employeeMetrics, setEmployeeMetrics] = useState({
    assignedTasks: 0,
    assignedLeads: 0,
    assignedConsultations: 0,
    overdueTasks: 0,
    openCases: 0,
    qualifiedLeads: 0,
  });
  const [employeeWorkload, setEmployeeWorkload] = useState({
    overdueTasks: [] as any[],
    followUps: [] as any[],
  });
  const [refreshTick, setRefreshTick] = useState(0);
  const [lastUpdatedAt, setLastUpdatedAt] = useState<Date | null>(null);
  const [isManualRefreshing, setIsManualRefreshing] = useState(false);
  useEffect(() => {
    if (!isAuthenticated || !user) return
    if (isCustomerOnly) {
      router.replace('/client-portal')
    }
  }, [isAuthenticated, user, isCustomerOnly, router])

  useEffect(() => {
    if (isCustomerOnly) {
      setLoading(false)
      setIsManualRefreshing(false)
      return
    }

    async function fetchStats() {
      const requestConfig = isSuperAdmin ? ({ skipTenantHeader: true } as any) : undefined;

      if (isEmployeeOnly) {
        try {
          const [casesRes, tasksRes, intakeRes, consultationsRes] = await Promise.all([
            api.get('/Cases?page=1&pageSize=50'),
            api.get('/AdminTasks?page=1&pageSize=100'),
            api.get('/Intake'),
            api.get('/Consulations'),
          ]);

          const caseItems = Array.isArray(casesRes.data) ? casesRes.data : (casesRes.data?.items || []);
          const taskItems = Array.isArray(tasksRes.data) ? tasksRes.data : (tasksRes.data?.items || []);
          const leadItems = intakeRes.data || [];
          const consultationItems = Array.isArray(consultationsRes.data) ? consultationsRes.data : (consultationsRes.data?.items || []);
          const now = new Date();

          setStats({
            cases: caseItems.length || 0,
            customers: taskItems.length || 0,
            employees: leadItems.length || 0,
            files: consultationItems.length || 0,
            casesTrend: 0,
            revenueThisMonth: 0,
            revenueTrend: 0,
            upcomingHearings: 0,
            overdueTasks: taskItems.filter((item: any) => item.taskReminderDate && new Date(item.taskReminderDate) < now).length,
          });

          setEmployeeMetrics({
            assignedTasks: taskItems.length || 0,
            assignedLeads: leadItems.length || 0,
            assignedConsultations: consultationItems.length || 0,
            overdueTasks: taskItems.filter((item: any) => item.taskReminderDate && new Date(item.taskReminderDate) < now).length,
            openCases: caseItems.filter((item: any) => {
              const status = String(item.status ?? item.Status ?? '').toLowerCase();
              return status !== '3' && status !== '4' && status !== '5' && status !== 'closed' && status !== 'won' && status !== 'lost';
            }).length,
            qualifiedLeads: leadItems.filter((item: any) => String(item.status || '').toLowerCase() === 'qualified').length,
          });

          setEmployeeWorkload({
            overdueTasks: taskItems
              .filter((item: any) => item.taskReminderDate && new Date(item.taskReminderDate) < now)
              .sort((a: any, b: any) => new Date(a.taskReminderDate).getTime() - new Date(b.taskReminderDate).getTime())
              .slice(0, 5),
            followUps: leadItems
              .filter((item: any) => item.nextFollowUpAt)
              .sort((a: any, b: any) => new Date(a.nextFollowUpAt).getTime() - new Date(b.nextFollowUpAt).getTime())
              .slice(0, 5),
          });

          setRecentCases(caseItems.slice(0, 5));
        } catch {
          console.error('Error fetching employee dashboard stats');
        } finally {
          setLoading(false);
          setIsManualRefreshing(false);
          setLastUpdatedAt(new Date());
        }

        return;
      }

      try {
        const analyticsRes = await api.get('/Dashboard/analytics', requestConfig);
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

        const casesRes = await api.get('/Cases?page=1&pageSize=5', requestConfig).catch(() => ({ data: { items: [] } }));
        const caseItems = Array.isArray(casesRes.data) ? casesRes.data : (casesRes.data?.items || []);
        setRecentCases(caseItems.slice(0, 5));
      } catch (e) {
        // fallback if analytics endpoint is unavailable
        try {
          const [casesRes, customersRes, employeesRes, filesRes] = await Promise.all([
            api.get('/Cases', requestConfig).catch(() => ({ data: [] })),
            api.get('/Customers', requestConfig).catch(() => ({ data: [] })),
            api.get('/Employees', requestConfig).catch(() => ({ data: [] })),
            api.get('/Files', requestConfig).catch(() => ({ data: [] })),
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
        setIsManualRefreshing(false);
        setLastUpdatedAt(new Date());
      }
    }
    fetchStats();
  }, [isSuperAdmin, isCustomerOnly, isEmployeeOnly, refreshTick]);

  if (isCustomerOnly) {
    return null
  }

  const navigate = (path: string) => {
    router.push(path)
  }

  const handleRefreshDashboard = () => {
    if (loading) return;
    setLoading(true);
    setIsManualRefreshing(true);
    setRefreshTick((prev) => prev + 1);
  };

  const overdueCount = isEmployeeOnly ? employeeMetrics.overdueTasks : stats.overdueTasks;
  const priorityLoad = isEmployeeOnly ? employeeMetrics.assignedTasks : stats.upcomingHearings + stats.overdueTasks;
  const activityHealthScore = Math.max(0, Math.min(100, 100 - overdueCount * 12));
  const completionScore = Math.max(0, Math.min(100, 100 - Math.round(priorityLoad * 6.5)));
  const attentionLevel =
    overdueCount === 0
      ? { label: t('dashboard.onTrack', { defaultValue: 'On Track' }), color: theme.palette.success.main, variant: 'filled' as const }
      : overdueCount <= 3
      ? { label: t('dashboard.needsAttention', { defaultValue: 'Needs Attention' }), color: theme.palette.warning.main, variant: 'filled' as const }
      : { label: t('dashboard.critical', { defaultValue: 'Critical' }), color: theme.palette.error.main, variant: 'filled' as const };

  const getCaseStatusInfo = (caseItem: any) => {
    const status = String(caseItem.status ?? caseItem.Status ?? '').toLowerCase();
    if (status === 'won' || status === 'closed' || status === '4') {
      return { label: t('cases.won', { defaultValue: 'Closed' }), color: theme.palette.success.main };
    }
    if (status === 'lost' || status === '5') {
      return { label: t('cases.lost', { defaultValue: 'Lost' }), color: theme.palette.error.main };
    }
    if (status === 'pending' || status === 'review') {
      return { label: t('common.pending', { defaultValue: 'Pending' }), color: theme.palette.warning.main };
    }
    return { label: t('common.active', { defaultValue: 'Active' }), color: theme.palette.info.main };
  };

  const quickActions = isEmployeeOnly
    ? [
        { label: t('dashboard.workQueue', { defaultValue: 'My Work Queue' }), path: '/employee-workqueue', icon: <TaskIcon />, color: theme.palette.error.main },
        { label: t('dashboard.myCases', { defaultValue: 'My Cases' }), path: '/cases', icon: <GavelIcon />, color: theme.palette.primary.main },
        { label: t('dashboard.myTasks', { defaultValue: 'My Tasks' }), path: '/tasks', icon: <EventIcon />, color: theme.palette.success.main },
        { label: t('dashboard.myLeads', { defaultValue: 'My Leads' }), path: '/intake', icon: <PeopleIcon />, color: theme.palette.primary.light },
        { label: t('dashboard.myConsultations', { defaultValue: 'My Consultations' }), path: '/consultations', icon: <ReceiptIcon />, color: theme.palette.secondary.main },
      ]
    : [
        { label: t('dashboard.newCase'), path: '/cases', icon: <GavelIcon />, color: theme.palette.primary.main },
        { label: t('dashboard.newCustomer'), path: '/customers', icon: <PeopleIcon />, color: theme.palette.primary.light },
        { label: t('dashboard.viewBilling'), path: '/billing', icon: <ReceiptIcon />, color: theme.palette.secondary.main },
        { label: t('dashboard.adminTasks'), path: '/tasks', icon: <EventIcon />, color: theme.palette.success.main },
      ];

  return (
    <Box
      dir={isRTL ? 'rtl' : 'ltr'}
      sx={{
        pb: 4,
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
        animation: 'fade-in-up 0.45s ease-out',
        background: `linear-gradient(180deg, ${alpha(theme.palette.primary.light, 0.07)} 0%, ${alpha(theme.palette.background.default, 0)} 34%)`,
      }}
    >
      {/* Welcome Section */}
      <Paper 
        elevation={0}
        sx={{ 
          p: { xs: 3, md: 4 }, 
          mb: 4, 
          background: `linear-gradient(125deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.main} 58%, ${theme.palette.secondary.main} 100%)`,
          color: 'white', 
          borderRadius: 6,
          position: 'relative',
          overflow: 'hidden',
          boxShadow: `0 20px 40px -12px ${alpha(theme.palette.primary.main, 0.35)}`,
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
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2, flexWrap: 'wrap', position: 'relative', zIndex: 1 }}>
          <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1 }}>
              <WavingHandIcon sx={{ color: theme.palette.secondary.light }} />
              <Typography variant="h4" fontWeight={800} sx={{ letterSpacing: '-0.02em' }}>
                {t('dashboard.welcomeBack')}{user ? `, ${user.fullName || user.userName || t('dashboard.userFallback', { defaultValue: 'User' })}` : ''}!
              </Typography>
            </Box>
            <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 500, maxWidth: 600 }}>
              {isEmployeeOnly
                ? t('dashboard.employeeSubtitle', { defaultValue: 'Here is the work currently assigned to you.' })
                : (t('dashboard.subtitle') || 'Here is what is happening with your legal practice today.')}
            </Typography>
            <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap" sx={{ mt: 2 }}>
              <Chip
                size="small"
                label={`${attentionLevel.label}`}
                sx={{
                  bgcolor: alpha(attentionLevel.color, 0.2),
                  color: '#fff',
                  border: `1px solid ${alpha('#ffffff', 0.22)}`,
                  fontWeight: 700,
                }}
              />
              <Chip
                size="small"
                label={`${t('tasks.overdue')}: ${overdueCount.toLocaleString(locale)}`}
                sx={{
                  bgcolor: alpha('#ffffff', 0.12),
                  color: '#fff',
                  border: `1px solid ${alpha('#ffffff', 0.2)}`,
                  fontWeight: 700,
                }}
              />
              <Chip
                size="small"
                label={`${t('dashboard.activityHealth')}: ${activityHealthScore.toLocaleString(locale)}%`}
                sx={{
                  bgcolor: alpha('#ffffff', 0.12),
                  color: '#fff',
                  border: `1px solid ${alpha('#ffffff', 0.2)}`,
                  fontWeight: 700,
                }}
              />
            </Stack>
          </Box>
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: isRTL ? 'flex-start' : 'flex-end', gap: 1.5, width: { xs: '100%', md: 'auto' } }}>
            <Chip
              icon={<AccessTimeIcon sx={{ fontSize: 16 }} />}
              label={
                loading
                  ? t('app.loading', { defaultValue: 'Loading...' })
                  : `${t('dashboard.lastUpdated', { defaultValue: 'Last Updated' })}: ${lastUpdatedAt ? lastUpdatedAt.toLocaleString(locale) : t('common.now', { defaultValue: 'Now' })}`
              }
              sx={{
                bgcolor: alpha('#ffffff', 0.14),
                color: '#fff',
                border: `1px solid ${alpha('#ffffff', 0.26)}`,
                fontWeight: 700,
                '& .MuiChip-icon': { color: '#fff' },
              }}
            />
            <Box sx={{ display: 'flex', gap: 1.25, width: { xs: '100%', md: 'auto' }, flexWrap: 'wrap', justifyContent: isRTL ? 'flex-start' : 'flex-end' }}>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon sx={{ fontSize: 18 }} />}
                onClick={handleRefreshDashboard}
                disabled={loading}
                sx={{
                  color: '#fff',
                  borderColor: alpha('#ffffff', 0.4),
                  fontWeight: 700,
                  borderRadius: 3,
                  px: 2.5,
                  minWidth: 140,
                  '&:hover': {
                    borderColor: '#fff',
                    bgcolor: alpha('#ffffff', 0.09),
                  },
                }}
              >
                {isManualRefreshing ? t('dashboard.refreshing', { defaultValue: 'Refreshing...' }) : t('dashboard.refresh', { defaultValue: 'Refresh' })}
              </Button>
          <Button
              aria-label={isEmployeeOnly ? t('dashboard.workQueue', { defaultValue: 'My Work Queue' }) : t('dashboard.viewAllCases')}
              variant="contained"
              sx={{
                background: 'linear-gradient(135deg, rgba(255,255,255,0.98) 0%, rgba(243,247,253,0.96) 100%)',
                color: 'primary.dark',
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
                  background: 'linear-gradient(135deg, #ffffff 0%, #f1f6fd 100%)',
                  transform: 'translateY(-2px)',
                  boxShadow: '0 12px 28px -16px rgba(0,0,0,0.22)'
                }
              }}
              onClick={() => navigate(isEmployeeOnly ? '/employee-workqueue' : '/cases')}
            >
              {isEmployeeOnly ? t('dashboard.workQueue', { defaultValue: 'My Work Queue' }) : (t('dashboard.viewAllCases') || 'View All Cases')}
            </Button>
            </Box>
          </Box>
        </Box>
      </Paper>

      <Box sx={{ flex: 1, overflowY: 'auto', px: { xs: 2, md: 0 } }}>
        <Typography variant="h6" fontWeight={800} sx={{ mb: 2.25, px: { xs: 0.5, md: 0 } }}>
          {t('dashboard.statistics')}
        </Typography>
        {/* Stats Grid */}
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }, gap: 3, mb: 4 }}>
          <Box><StatCard title={isEmployeeOnly ? t('dashboard.myCases', { defaultValue: 'My Cases' }) : t('dashboard.totalCases')} value={stats.cases} icon={<GavelIcon />} color={theme.palette.primary.main} loading={loading} onClick={() => navigate('/cases')} trend={isEmployeeOnly ? undefined : stats.casesTrend} trendLabel={t('dashboard.thisMonth')} animationDelay={40} /></Box>
          <Box><StatCard title={isEmployeeOnly ? t('dashboard.myTasks', { defaultValue: 'My Tasks' }) : t('dashboard.customers')} value={isEmployeeOnly ? employeeMetrics.assignedTasks : stats.customers} icon={<PeopleIcon />} color={theme.palette.primary.light} loading={loading} onClick={() => navigate(isEmployeeOnly ? '/tasks' : '/customers')} animationDelay={90} /></Box>
          <Box><StatCard title={isEmployeeOnly ? t('dashboard.myLeads', { defaultValue: 'My Leads' }) : t('dashboard.employees')} value={isEmployeeOnly ? employeeMetrics.assignedLeads : stats.employees} icon={<BadgeIcon />} color={theme.palette.secondary.main} loading={loading} onClick={() => navigate(isEmployeeOnly ? '/intake' : '/employees')} animationDelay={140} /></Box>
          <Box><StatCard title={isEmployeeOnly ? t('dashboard.myConsultations', { defaultValue: 'My Consultations' }) : t('dashboard.files')} value={isEmployeeOnly ? employeeMetrics.assignedConsultations : stats.files} icon={<FolderIcon />} color={theme.palette.warning.main} loading={loading} onClick={() => navigate(isEmployeeOnly ? '/consultations' : '/files')} animationDelay={190} /></Box>
        </Box>

        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 3, mb: 4 }}>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 5, border: '1px solid', borderColor: 'divider' }}>
            <Typography variant="subtitle2" color="text.secondary" fontWeight={700}>{isEmployeeOnly ? t('dashboard.openCases', { defaultValue: 'Open Cases' }) : (t('billing.title') || 'Billing')}</Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>
              {isEmployeeOnly ? employeeMetrics.openCases.toLocaleString(locale) : formatCurrency(stats.revenueThisMonth)}
            </Typography>
            {!isEmployeeOnly && (
              <Typography variant="caption" color={stats.revenueTrend >= 0 ? 'success.main' : 'error.main'} fontWeight={700}>
                {stats.revenueTrend >= 0 ? '+' : ''}{stats.revenueTrend}% {t('dashboard.thisMonth')}
              </Typography>
            )}
          </Paper>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 5, border: '1px solid', borderColor: 'divider' }}>
            <Typography variant="subtitle2" color="text.secondary" fontWeight={700}>{isEmployeeOnly ? t('dashboard.qualifiedLeads', { defaultValue: 'Qualified Leads' }) : (t('sitings.upcoming') || 'Upcoming Hearings')}</Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>{isEmployeeOnly ? employeeMetrics.qualifiedLeads : stats.upcomingHearings}</Typography>
          </Paper>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 5, border: '1px solid', borderColor: 'divider' }}>
            <Typography variant="subtitle2" color="text.secondary" fontWeight={700}>{t('tasks.overdue') || 'Overdue Tasks'}</Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>{isEmployeeOnly ? employeeMetrics.overdueTasks : stats.overdueTasks}</Typography>
          </Paper>
        </Box>

        <Paper
          elevation={0}
          sx={{
            p: { xs: 2.5, md: 3 },
            borderRadius: 5,
            border: '1px solid',
            borderColor: 'divider',
            mb: 4,
            background: `linear-gradient(140deg, ${alpha(theme.palette.background.paper, 0.98)} 0%, ${alpha(theme.palette.primary.light, 0.03)} 100%)`,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 1.5, flexWrap: 'wrap', mb: 2.5 }}>
            <Typography variant="h6" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <WarningAmberIcon sx={{ color: attentionLevel.color }} />
              {t('dashboard.operationalFocus', { defaultValue: 'Operational Focus' })}
            </Typography>
            <Chip
              label={attentionLevel.label}
              variant={attentionLevel.variant}
              sx={{
                fontWeight: 800,
                bgcolor: alpha(attentionLevel.color, 0.14),
                color: attentionLevel.color,
                border: `1px solid ${alpha(attentionLevel.color, 0.24)}`,
              }}
            />
          </Box>

          <Stack spacing={2.25}>
            <Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.75 }}>
                <Typography variant="body2" fontWeight={700} color="text.secondary">
                  {t('dashboard.activityHealth', { defaultValue: 'Activity Health' })}
                </Typography>
                <Typography variant="body2" fontWeight={800}>
                  {activityHealthScore}%
                </Typography>
              </Box>
              <LinearProgress
                variant="determinate"
                value={activityHealthScore}
                sx={{
                  height: 10,
                  borderRadius: 99,
                  bgcolor: alpha(theme.palette.primary.main, 0.08),
                  '& .MuiLinearProgress-bar': {
                    borderRadius: 99,
                    background: `linear-gradient(90deg, ${theme.palette.primary.main} 0%, ${theme.palette.secondary.main} 100%)`,
                  },
                }}
              />
            </Box>
            <Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.75 }}>
                <Typography variant="body2" fontWeight={700} color="text.secondary">
                  {t('dashboard.completionScore', { defaultValue: 'Completion Readiness' })}
                </Typography>
                <Typography variant="body2" fontWeight={800}>
                  {completionScore}%
                </Typography>
              </Box>
              <LinearProgress
                variant="determinate"
                value={completionScore}
                color={completionScore >= 70 ? 'success' : completionScore >= 50 ? 'warning' : 'error'}
                sx={{ height: 10, borderRadius: 99 }}
              />
            </Box>
          </Stack>
        </Paper>

      {/* Quick Actions & Recent Cases */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 2fr' }, gap: 3 }}>
        <Box>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 5, border: '1px solid', borderColor: 'divider', height: '100%' }}>
            <Typography variant="h6" fontWeight={800} sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 1 }}>
              <OpenInNewIcon sx={{ color: 'primary.main' }} />
              {t('dashboard.quickActions')}
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {quickActions.map((action) => (
                <Button 
                  key={action.label} 
                  onClick={() => navigate(action.path)} 
                  sx={{ 
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    py: 2.1, 
                    px: 2.5,
                    borderRadius: 3,
                    borderWidth: 2,
                    fontWeight: 700,
                    color: 'text.primary',
                    bgcolor: alpha(action.color, 0.04),
                    borderColor: alpha(action.color, 0.18),
                    textTransform: 'none',
                    '&:hover': {
                      borderColor: action.color,
                      bgcolor: alpha(action.color, 0.09),
                      borderWidth: 2,
                      transform: 'translateY(-1px)',
                    }
                  }}
                  variant="outlined"
                  fullWidth
                >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                    <Avatar
                      sx={{
                        width: 34,
                        height: 34,
                        bgcolor: alpha(action.color, 0.14),
                        color: action.color,
                        borderRadius: 2,
                      }}
                    >
                      {action.icon}
                    </Avatar>
                    <Typography
                      sx={{
                        fontWeight: 800,
                        fontSize: '1rem',
                        color: 'text.primary',
                        textAlign: isRTL ? 'right' : 'left',
                      }}
                    >
                      {action.label}
                    </Typography>
                  </Box>
                  <ArrowForwardIcon
                    sx={{
                      color: action.color,
                      opacity: 0.7,
                      transform: isRTL ? 'rotate(180deg)' : 'none',
                    }}
                  />
                </Button>
              ))}
            </Box>
          </Paper>
        </Box>
        <Box>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 5, border: '1px solid', borderColor: 'divider', height: '100%', maxHeight: 520, overflowY: 'auto' }}>
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
                {recentCases.map((c, index) => {
                  const status = getCaseStatusInfo(c);
                  return (
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
                          secondary={
                            <Typography variant="body2" color="text.secondary">
                              {c.caseNumber || t('cases.noCaseNumber')}
                            </Typography>
                          }
                        />
                        <Stack direction={isRTL ? 'row-reverse' : 'row'} spacing={1} alignItems="center">
                          {!!c.caseType && (
                            <Chip
                              label={c.caseType}
                              size="small"
                              sx={{
                                fontWeight: 700,
                                bgcolor: alpha(theme.palette.primary.main, 0.1),
                                color: 'primary.main',
                                border: 'none',
                              }}
                            />
                          )}
                          <Chip
                            label={status.label}
                            size="small"
                            sx={{
                              fontWeight: 700,
                              bgcolor: alpha(status.color, 0.12),
                              color: status.color,
                              border: `1px solid ${alpha(status.color, 0.22)}`,
                            }}
                          />
                        </Stack>
                      </ListItem>
                      {index < recentCases.length - 1 && <Divider variant="inset" component="li" sx={{ opacity: 0.5, my: 0.5 }} />}
                    </React.Fragment>
                  );
                })}
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

      {isEmployeeOnly && (
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, 1fr)' }, gap: 3, mt: 4 }}>
          <Paper elevation={0} sx={{ p: 3, borderRadius: 5, border: '1px solid', borderColor: 'divider' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2.5 }}>
              <Typography variant="h6" fontWeight={800}>
                {t('dashboard.myOverdueTasks', { defaultValue: 'My Overdue Tasks' })}
              </Typography>
              <Button size="small" onClick={() => navigate('/tasks')} sx={{ fontWeight: 700 }}>
                {t('app.viewAll')}
              </Button>
            </Box>
            {employeeWorkload.overdueTasks.length > 0 ? (
              <List disablePadding>
                {employeeWorkload.overdueTasks.map((task, index) => (
                  <React.Fragment key={task.id ?? index}>
                    <ListItem sx={{ px: 0, py: 1.25 }}>
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: alpha(theme.palette.error.main, 0.12), color: 'error.main', borderRadius: 2 }}>
                          <EventIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary={<Typography fontWeight={700}>{task.taskName || task.task_Name || t('tasks.task', { defaultValue: 'Task' })}</Typography>}
                        secondary={task.taskReminderDate ? new Date(task.taskReminderDate).toLocaleString(locale) : t('common.noData', { defaultValue: 'No data' })}
                      />
                    </ListItem>
                    {index < employeeWorkload.overdueTasks.length - 1 && <Divider component="li" />}
                  </React.Fragment>
                ))}
              </List>
            ) : (
              <Typography color="text.secondary">{t('dashboard.noOverdueTasks', { defaultValue: 'No overdue tasks assigned to you.' })}</Typography>
            )}
          </Paper>

          <Paper elevation={0} sx={{ p: 3, borderRadius: 5, border: '1px solid', borderColor: 'divider' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2.5 }}>
              <Typography variant="h6" fontWeight={800}>
                {t('dashboard.myFollowUps', { defaultValue: 'My Follow-ups' })}
              </Typography>
              <Button size="small" onClick={() => navigate('/intake')} sx={{ fontWeight: 700 }}>
                {t('app.viewAll')}
              </Button>
            </Box>
            {employeeWorkload.followUps.length > 0 ? (
              <List disablePadding>
                {employeeWorkload.followUps.map((lead, index) => (
                  <React.Fragment key={lead.id ?? index}>
                    <ListItem sx={{ px: 0, py: 1.25 }}>
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: alpha(theme.palette.warning.main, 0.12), color: 'warning.main', borderRadius: 2 }}>
                          <PeopleIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary={<Typography fontWeight={700}>{lead.fullName || t('customers.customer', { defaultValue: 'Lead' })}</Typography>}
                        secondary={lead.nextFollowUpAt ? new Date(lead.nextFollowUpAt).toLocaleString(locale) : t('common.noData', { defaultValue: 'No data' })}
                      />
                      <Chip size="small" label={lead.status || t('common.pending', { defaultValue: 'Pending' })} />
                    </ListItem>
                    {index < employeeWorkload.followUps.length - 1 && <Divider component="li" />}
                  </React.Fragment>
                ))}
              </List>
            ) : (
              <Typography color="text.secondary">{t('dashboard.noFollowUps', { defaultValue: 'No follow-ups are scheduled right now.' })}</Typography>
            )}
          </Paper>
        </Box>
      )}

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
