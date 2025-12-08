import React, { useState, useEffect } from 'react';
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
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import { useAuth } from '../services/auth';

interface StatCardProps {
  title: string;
  value: number | string;
  icon: React.ReactNode;
  color: string;
  loading?: boolean;
  onClick?: () => void;
}

function StatCard({ title, value, icon, color, loading, onClick }: StatCardProps) {
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
          <Avatar
            sx={{
              bgcolor: `${color}15`,
              color: color,
              width: 48,
              height: 48,
            }}
          >
            {icon}
          </Avatar>
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
  const [stats, setStats] = useState({
    cases: 0,
    customers: 0,
    employees: 0,
    files: 0,
  });
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
    <Box dir={isRTL ? 'rtl' : 'ltr'}>
      {/* Welcome Section */}
      <Paper
        sx={{
          p: 3,
          mb: 3,
          background: 'linear-gradient(135deg, #1565c0 0%, #1976d2 50%, #42a5f5 100%)',
          color: 'white',
          borderRadius: 3,
        }}
      >
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexDirection: isRTL ? 'row-reverse' : 'row' }}>
          <Box sx={{ textAlign: isRTL ? 'right' : 'left' }}>
            <Typography variant="h4" fontWeight={700} gutterBottom>
              {t('dashboard.welcomeBack')}{user ? `, ${user.email}` : ''}!
            </Typography>
            <Typography variant="body1" sx={{ opacity: 0.9 }}>
              {t('dashboard.subtitle')}
            </Typography>
          </Box>
          <Button
            variant="contained"
            startIcon={isRTL ? <OpenInNewIcon /> : undefined}
            endIcon={!isRTL ? <OpenInNewIcon /> : undefined}
            href="/swagger"
            target="_blank"
            sx={{
              bgcolor: 'rgba(255,255,255,0.2)',
              color: 'white',
              '&:hover': { bgcolor: 'rgba(255,255,255,0.3)' },
            }}
          >
            {t('dashboard.apiDocs')}
          </Button>
        </Box>
      </Paper>

      {/* Stats Grid */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title={t('dashboard.totalCases')}
            value={stats.cases}
            icon={<GavelIcon />}
            color="#1565c0"
            loading={loading}
            onClick={() => navigate('/cases')}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title={t('dashboard.customers')}
            value={stats.customers}
            icon={<PeopleIcon />}
            color="#7c4dff"
            loading={loading}
            onClick={() => navigate('/customers')}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title={t('dashboard.employees')}
            value={stats.employees}
            icon={<BadgeIcon />}
            color="#00bcd4"
            loading={loading}
            onClick={() => navigate('/employees')}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title={t('dashboard.files')}
            value={stats.files}
            icon={<FolderIcon />}
            color="#ff9800"
            loading={loading}
            onClick={() => navigate('/files')}
          />
        </Grid>
      </Grid>

      {/* Quick Actions & Recent Cases */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" fontWeight={600} gutterBottom>
                {t('dashboard.quickActions')}
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, mt: 2 }}>
                {quickActions.map((action) => (
                  <Button
                    key={action.label}
                    variant="outlined"
                    startIcon={!isRTL ? action.icon : undefined}
                    endIcon={isRTL ? action.icon : undefined}
                    onClick={() => navigate(action.path)}
                    sx={{
                      justifyContent: isRTL ? 'flex-end' : 'flex-start',
                      py: 1.5,
                      textAlign: isRTL ? 'right' : 'left',
                    }}
                    fullWidth
                  >
                    {action.label}
                  </Button>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 8 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexDirection: isRTL ? 'row-reverse' : 'row' }}>
                <Typography variant="h6" fontWeight={600}>
                  {t('dashboard.recentCases')}
                </Typography>
                <Button
                  size="small"
                  startIcon={isRTL ? <ArrowForwardIcon sx={{ transform: 'scaleX(-1)' }} /> : undefined}
                  endIcon={!isRTL ? <ArrowForwardIcon /> : undefined}
                  onClick={() => navigate('/cases')}
                >
                  {t('app.viewAll')}
                </Button>
              </Box>
              {loading ? (
                <Box>
                  {[1, 2, 3].map((i) => (
                    <Skeleton key={i} height={60} sx={{ mb: 1 }} />
                  ))}
                </Box>
              ) : recentCases.length > 0 ? (
                <List disablePadding>
                  {recentCases.map((c, index) => (
                    <React.Fragment key={c.caseId}>
                      <ListItem
                        sx={{
                          px: 0,
                          cursor: 'pointer',
                          '&:hover': { bgcolor: 'action.hover' },
                          borderRadius: 1,
                        }}
                        onClick={() => navigate('/cases')}
                      >
                        <ListItemAvatar>
                          <Avatar sx={{ bgcolor: 'primary.light' }}>
                            <GavelIcon />
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={c.caseName || `Case #${c.caseId}`}
                          secondary={c.caseNumber || 'No case number'}
                        />
                        <Chip
                          label={c.caseType || 'General'}
                          size="small"
                          variant="outlined"
                        />
                      </ListItem>
                      {index < recentCases.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              ) : (
                <Box sx={{ textAlign: 'center', py: 4, color: 'text.secondary' }}>
                  <GavelIcon sx={{ fontSize: 48, opacity: 0.3, mb: 1 }} />
                  <Typography>No cases found</Typography>
                  <Button
                    variant="contained"
                    sx={{ mt: 2 }}
                    onClick={() => navigate('/cases')}
                  >
                    Create First Case
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* System Info */}
      <Paper sx={{ mt: 3, p: 2 }}>
        {/* Use a div here because we render inline <code> and <Chip> components (which are divs) */}
        <Typography component="div" variant="body2" color="text.secondary">
          <strong>System Info:</strong> API Base URL: {process?.env?.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000/api'} •
          JWT stored in localStorage as <code>lawyersys-token</code> •
          {isAuthenticated ? (
            <Box component="span" sx={{ display: 'inline-flex', ml: 1 }}>
              <Chip label="Authenticated" size="small" color="success" />
            </Box>
          ) : (
            <Box component="span" sx={{ display: 'inline-flex', ml: 1 }}>
              <Chip label="Not Authenticated" size="small" color="warning" />
            </Box>
          )}
        </Typography>
      </Paper>
    </Box>
  );
}
