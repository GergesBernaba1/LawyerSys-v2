"use client"
import React, { useState, useEffect } from 'react';
import { BrowserRouter, useNavigate } from 'react-router-dom';
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
} from '@mui/icons-material';
import api from '../services/api';
import { useAuth } from '../services/auth';

function StatCard({ title, value, icon, color, loading, onClick }: any) {
  return (
    <Card
      sx={{
        height: '100%',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.3s ease',
        '&:hover': onClick
          ? {
              transform: 'translateY(-4px)',
              boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
            }
          : {},
      }}
      onClick={onClick}
    >
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <Box>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              {title}
            </Typography>
            {loading ? (
              <Skeleton width={60} height={40} />
            ) : (
              <Typography variant="h4" fontWeight={700}>
                {value}
              </Typography>
            )}
          </Box>
          <Avatar sx={{ bgcolor: `${color}15`, color: color, width: 48, height: 48 }}>{icon}</Avatar>
        </Box>
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
    { label: t('dashboard.newCase'), path: '/cases', icon: <GavelIcon /> },
    { label: t('dashboard.newCustomer'), path: '/customers', icon: <PeopleIcon /> },
    { label: t('dashboard.viewBilling'), path: '/billing', icon: <ReceiptIcon /> },
    { label: t('dashboard.adminTasks'), path: '/tasks', icon: <EventIcon /> },
  ];

  return (
    <BrowserRouter>
      <Box dir={isRTL ? 'rtl' : 'ltr'}>
        {/* Welcome Section */}
        <Paper sx={{ p: 3, mb: 3, background: 'linear-gradient(135deg, #1565c0 0%, #1976d2 50%, #42a5f5 100%)', color: 'white', borderRadius: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexDirection: isRTL ? 'row-reverse' : 'row' }}>
            <Box sx={{ textAlign: isRTL ? 'right' : 'left' }}>
              <Typography variant="h4" fontWeight={700} gutterBottom>
                {t('dashboard.welcomeBack')}{user ? `, ${user.email}` : ''}!
              </Typography>
              <Typography variant="body1" sx={{ opacity: 0.9 }}>{t('dashboard.subtitle')}</Typography>
            </Box>
            <Button variant="contained" startIcon={isRTL ? <OpenInNewIcon /> : undefined} endIcon={!isRTL ? <OpenInNewIcon /> : undefined} href="/swagger" target="_blank" sx={{ bgcolor: 'rgba(255,255,255,0.2)', color: 'white', '&:hover': { bgcolor: 'rgba(255,255,255,0.3)' } }}>{t('dashboard.apiDocs')}</Button>
          </Box>
        </Paper>

        {/* Stats Grid */}
        <Grid container spacing={3} sx={{ mb: 3 }}>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <StatCard title={t('dashboard.totalCases')} value={stats.cases} icon={<GavelIcon />} color="#1565c0" loading={loading} onClick={() => navigate('/cases')} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <StatCard title={t('dashboard.customers')} value={stats.customers} icon={<PeopleIcon />} color="#7c4dff" loading={loading} onClick={() => navigate('/customers')} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <StatCard title={t('dashboard.employees')} value={stats.employees} icon={<BadgeIcon />} color="#00bcd4" loading={loading} onClick={() => navigate('/employees')} />
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <StatCard title={t('dashboard.files')} value={stats.files} icon={<FolderIcon />} color="#ff9800" loading={loading} onClick={() => navigate('/files')} />
          </Grid>
        </Grid>

        {/* Quick actions + Recent/Trends */}
        <Grid container spacing={3}>
          <Grid size={{ xs: 12, md: 8 }}>
            <Grid container spacing={3}>
              <Grid size={{ xs: 12 }}>
                <Paper sx={{ p: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                    <Typography variant="h6">{t('dashboard.quickActions')}</Typography>
                    <Button variant="text" size="small" endIcon={<ArrowForwardIcon />} onClick={() => navigate('/cases')}>{t('dashboard.viewAll')}</Button>
                  </Box>
                  <Grid container spacing={2}>
                    {quickActions.map((q, i) => (
                      <Grid key={i} size={{ xs: 12, sm: 6, md: 3 }}>
                        <StatCard title={q.label} value={'-'} icon={q.icon} color="#1976d2" onClick={() => navigate(q.path)} />
                      </Grid>
                    ))}
                  </Grid>
                </Paper>
              </Grid>
              <Grid size={{ xs: 12 }}>
                <Paper sx={{ p: 2 }}>
                  <Typography variant="h6" sx={{ mb: 2 }}>{t('dashboard.recentCases')}</Typography>
                  <List>
                    {recentCases.length === 0 ? (
                      <ListItem><ListItemText primary={t('dashboard.noRecentCases')} /></ListItem>
                    ) : (
                      recentCases.map((c: any) => (
                        <React.Fragment key={c.id}>
                          <ListItem sx={{ p: 1 }}>
                            <ListItemAvatar><Avatar><GavelIcon /></Avatar></ListItemAvatar>
                            <ListItemText primary={c.title || 'Untitled'} secondary={c.customerName || ''} />
                          </ListItem>
                          <Divider component="li" />
                        </React.Fragment>
                      ))
                    )}
                  </List>
                </Paper>
              </Grid>
            </Grid>
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6">{t('dashboard.trends')}</Typography>
              <Typography variant="body2" sx={{ mt: 2 }}>{t('dashboard.trendsComingSoon')}</Typography>
            </Paper>
          </Grid>
        </Grid>
      </Box>
    </BrowserRouter>
  );
}
