"use client"
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Grid,
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
import {
  Gavel as GavelIcon,
  People as PeopleIcon,
  Badge as BadgeIcon,
  Folder as FolderIcon,
  TrendingUp as TrendingUpIcon,
  Event as EventIcon,
  Receipt as ReceiptIcon,
  OpenInNew as OpenInNewIcon,
  ArrowForward as ArrowForwardIcon,
  WavingHand as WavingHandIcon,
  ChevronRight as ChevronRightIcon,
  ChevronLeft as ChevronLeftIcon,
} from '@mui/icons-material';
import api from '../services/api';
import { useAuth } from '../services/auth';

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
            {React.cloneElement(icon as React.ReactElement, { sx: { fontSize: 28 } })}
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

export default function Dashboard() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { isAuthenticated, user } = useAuth();
  const theme = useTheme();
  const isRTL = theme.direction === 'rtl';
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

  const quickActions = [
    { label: t('dashboard.newCase'), path: '/cases', icon: <GavelIcon />, color: '#6366f1' },
    { label: t('dashboard.newCustomer'), path: '/customers', icon: <PeopleIcon />, color: '#a855f7' },
    { label: t('dashboard.viewBilling'), path: '/billing', icon: <ReceiptIcon />, color: '#f43f5e' },
    { label: t('dashboard.adminTasks'), path: '/tasks', icon: <EventIcon />, color: '#10b981' },
  ];

  return (
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 1600, margin: '0 auto' }}>
      {/* Welcome Section */}
      <Paper 
        elevation={0}
        sx={{ 
          p: { xs: 3, md: 5 }, 
          mb: 4, 
          borderRadius: 6, 
          background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
          color: 'white',
          position: 'relative',
          overflow: 'hidden',
          boxShadow: '0 20px 40px rgba(99, 102, 241, 0.2)'
        }}
      >
        <Box sx={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
              <Box sx={{ 
                width: 50, 
                height: 50, 
                borderRadius: 3, 
                bgcolor: 'rgba(255, 255, 255, 0.2)', 
                backdropFilter: 'blur(10px)',
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                border: '1px solid rgba(255, 255, 255, 0.3)'
              }}>
                <WavingHandIcon sx={{ fontSize: 30, color: '#fbbf24' }} />
              </Box>
              <Typography variant="h3" fontWeight={800} sx={{ letterSpacing: '-0.02em' }}>
                {t('dashboard.welcomeBack')}{user ? `, ${user.fullName || user.userName || 'User'}` : ''}!
              </Typography>
            </Box>
            <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 600 }}>
              {t('dashboard.subtitle', 'Here is what is happening with your legal practice today.')}
            </Typography>
          </Box>
          <Box sx={{ display: { xs: 'none', md: 'block' } }}>
            <Button 
              variant="contained" 
              sx={{ 
                bgcolor: 'white',
                color: 'primary.main',
                '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.9)' },
                borderRadius: 3, 
                px: 4, 
                py: 1.5,
                fontWeight: 800,
                textTransform: 'none',
                boxShadow: '0 10px 20px rgba(0,0,0,0.1)'
              }}
              onClick={() => navigate('/cases')}
            >
              {t('dashboard.viewAllCases', 'View All Cases')}
            </Button>
          </Box>
        </Box>
        
        {/* Decorative background elements */}
        <Box sx={{ position: 'absolute', top: -50, right: -50, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,255,255,0.1)', zIndex: 0 }} />
        <Box sx={{ position: 'absolute', bottom: -30, left: '20%', width: 120, height: 120, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', zIndex: 0 }} />
      </Paper>

      {/* Stats Grid */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title={t('dashboard.totalCases')} value={stats.cases} icon={<GavelIcon />} color="#6366f1" loading={loading} onClick={() => navigate('/cases')} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title={t('dashboard.customers')} value={stats.customers} icon={<PeopleIcon />} color="#a855f7" loading={loading} onClick={() => navigate('/customers')} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title={t('dashboard.employees')} value={stats.employees} icon={<BadgeIcon />} color="#06b6d4" loading={loading} onClick={() => navigate('/employees')} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title={t('dashboard.files')} value={stats.files} icon={<FolderIcon />} color="#f59e0b" loading={loading} onClick={() => navigate('/files')} />
        </Grid>
      </Grid>

      {/* Quick Actions & Recent Cases */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Paper 
            elevation={0} 
            sx={{ 
              p: 4, 
              borderRadius: 5, 
              border: '1px solid', 
              borderColor: 'divider', 
              height: '100%',
              boxShadow: '0 10px 30px rgba(0,0,0,0.04)'
            }}
          >
            <Typography variant="h5" fontWeight={800} sx={{ mb: 4, display: 'flex', alignItems: 'center', gap: 2 }}>
              <Box sx={{ p: 1, borderRadius: 2, bgcolor: 'primary.50', color: 'primary.main', display: 'flex' }}>
                <OpenInNewIcon />
              </Box>
              {t('dashboard.quickActions')}
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {quickActions.map((action, index) => (
                <Button 
                  key={action.path || index} 
                  variant="outlined" 
                  startIcon={!isRTL ? action.icon : undefined}  
                  endIcon={isRTL ? action.icon : undefined} 
                  onClick={() => navigate(action.path)} 
                  sx={{ 
                    justifyContent: isRTL ? 'flex-end' : 'flex-start', 
                    py: 2.5, 
                    px: 3,
                    borderRadius: 4,
                    borderWidth: 2,
                    fontWeight: 800,
                    color: 'text.primary',
                    borderColor: alpha(action.color, 0.1),
                    bgcolor: alpha(action.color, 0.02),
                    '&:hover': {
                      borderColor: action.color,
                      bgcolor: alpha(action.color, 0.05),
                      borderWidth: 2,
                      transform: 'translateX(4px)'
                    },
                    transition: 'all 0.2s'
                  }} 
                  fullWidth
                >
                  {action.label}
                </Button>
              ))}
            </Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={8}>
          <Paper 
            elevation={0} 
            sx={{ 
              p: 4, 
              borderRadius: 5, 
              border: '1px solid', 
              borderColor: 'divider', 
              height: '100%',
              boxShadow: '0 10px 30px rgba(0,0,0,0.04)'
            }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
              <Typography variant="h5" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Box sx={{ p: 1, borderRadius: 2, bgcolor: 'primary.50', color: 'primary.main', display: 'flex' }}>
                  <GavelIcon />
                </Box>
                {t('dashboard.recentCases')}
              </Typography>
              <Button 
                size="large" 
                endIcon={isRTL ? <ArrowForwardIcon sx={{ transform: 'rotate(180deg)' }} /> : <ArrowForwardIcon />} 
                onClick={() => navigate('/cases')}
                sx={{ fontWeight: 800, borderRadius: 3 }}
              >
                {t('app.viewAll', 'View All')}
              </Button>
            </Box>
            {loading ? (
              <Box>{[1,2,3].map(i => <Skeleton key={i} height={100} sx={{ mb: 2, borderRadius: 4 }} />)}</Box>
            ) : recentCases.length > 0 ? (
              <List disablePadding>
                {recentCases.map((c, index) => (
                  <React.Fragment key={c.caseId || index}>
                    <ListItem 
                      sx={{ 
                        px: 3, 
                        py: 2.5,
                        cursor: 'pointer', 
                        '&:hover': { bgcolor: 'primary.50', transform: 'scale(1.01)' }, 
                        borderRadius: 4,
                        mb: 2,
                        border: '1px solid transparent',
                        '&:hover': { borderColor: 'primary.100', bgcolor: 'primary.50' },
                        transition: 'all 0.2s'
                      }} 
                      onClick={() => navigate('/cases')}
                    >
                      <ListItemAvatar>
                        <Avatar sx={{ 
                          width: 50, 
                          height: 50, 
                          bgcolor: 'white', 
                          color: 'primary.main', 
                          borderRadius: 3,
                          border: '1px solid',
                          borderColor: 'primary.100',
                          boxShadow: '0 4px 10px rgba(0,0,0,0.05)'
                        }}>
                          <GavelIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText 
                        primary={<Typography fontWeight={800} variant="h6">{c.caseName || `${t('cases.caseNumber')} ${c.caseId}`}</Typography>} 
                        secondary={c.caseNumber || t('cases.noCaseNumber')} 
                      />
                      <Chip 
                        label={c.caseType || t('cases.general')} 
                        size="small" 
                        sx={{ 
                          fontWeight: 800, 
                          borderRadius: 2,
                          bgcolor: 'primary.50',
                          color: 'primary.dark',
                          border: '1px solid',
                          borderColor: 'primary.100'
                        }} 
                      />
                    </ListItem>
                    {index < recentCases.length - 1 && <Divider variant="inset" component="li" sx={{ opacity: 0.5, my: 0.5 }} />}
                  </React.Fragment>
                ))}
              </List>
            ) : (
              <Box sx={{ textAlign: 'center', py: 10, color: 'text.secondary' }}>
                <Avatar sx={{ width: 100, height: 100, bgcolor: 'grey.50', mx: 'auto', mb: 3 }}>
                  <GavelIcon sx={{ fontSize: 50, opacity: 0.2 }} />
                </Avatar>
                <Typography variant="h5" fontWeight={800} sx={{ mb: 1 }}>{t('dashboard.noRecentCases')}</Typography>
                <Typography variant="body1" sx={{ mb: 4, opacity: 0.7 }}>Start by adding your first legal case to track progress.</Typography>
                <Button 
                  variant="contained" 
                  sx={{ borderRadius: 3, px: 5, py: 1.5, fontWeight: 800 }} 
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
          p: 3, 
          borderRadius: 5, 
          bgcolor: alpha(theme.palette.primary.main, 0.02),
          border: '1px dashed',
          borderColor: alpha(theme.palette.primary.main, 0.2)
        }}
      >
        <Box sx={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 3 }}>
          <Typography variant="body1" fontWeight={800} color="text.secondary">
            {t('dashboard.systemStatus', 'System Status')}:
          </Typography>
          <Chip 
            label={isAuthenticated ? t('dashboard.authenticated') : t('dashboard.notAuthenticated')} 
            size="small" 
            color={isAuthenticated ? "success" : "warning"} 
            sx={{ fontWeight: 800, borderRadius: 2 }}
          />
          <Divider orientation="vertical" flexItem sx={{ mx: 1 }} />
          <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
            <strong>API:</strong> {process?.env?.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000/api'}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
            <strong>Session:</strong> {isAuthenticated ? 'Active' : 'None'}
          </Typography>
        </Box>
      </Paper>
    </Box>
  );
}
