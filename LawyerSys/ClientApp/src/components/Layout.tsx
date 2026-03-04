'use client'
import React, { useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import {
  Box,
  Drawer,
  AppBar,
  Toolbar,
  List,
  Typography,
  Divider,
  IconButton,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Avatar,
  Menu,
  MenuItem,
  Paper,
  Button,
  Tooltip,
  ClickAwayListener,
  Breadcrumbs,
  Link,
  useTheme,
  useMediaQuery,
  Collapse,
  alpha,
  TextField,
  CircularProgress,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  Gavel as GavelIcon,
  People as PeopleIcon,
  Badge as BadgeIcon,
  Folder as FolderIcon,
  AccountBalance as AccountBalanceIcon,
  LocationCity as LocationCityIcon,
  PersonSearch as PersonSearchIcon,
  Event as EventIcon,
  CalendarMonth as CalendarIcon,
  Assessment as ReportsIcon,
  History as AuditIcon,
  AutoFixHigh as DocGenIcon,
  Public as PortalIcon,
  Chat as ChatIcon,
  Description as DescriptionIcon,
  Task as TaskIcon,
  Receipt as ReceiptIcon,
  Savings as TrustAccountingIcon,
  ShowChart as TrustReportsIcon,
  Person as PersonIcon,
  Link as LinkIcon,
  Login as LoginIcon,
  Logout as LogoutIcon,
  ExpandLess,
  ExpandMore,
  ChevronLeft as ChevronLeftIcon,
  ChevronRight as ChevronRightIcon,
  NavigateNext as NavigateNextIcon,
  NavigateBefore as NavigateBeforeIcon,
  Home as HomeIcon,
  AdminPanelSettings as AdminPanelSettingsIcon,
  FactCheck as IntakeIcon,
  BorderColor as ESignIcon,
  Timer as TimeTrackingIcon,
  SmartToy as AiAssistantIcon,
  Rule as CourtAutomationIcon,
  Close as CloseIcon,
  SendRounded as SendRoundedIcon,
} from '@mui/icons-material';
import { useAuth } from '../services/auth';
import { useTranslation } from 'react-i18next'
import api from '../services/api';

const drawerWidth = 280;

interface MenuItem {
  key: string;
  icon: React.ReactNode;
  path: string;
  children?: MenuItem[];
}

const menuItems: MenuItem[] = [
  { key: 'dashboard', icon: <DashboardIcon />, path: '/' },
  { key: 'cases', icon: <GavelIcon />, path: '/cases' },
  { key: 'customers', icon: <PeopleIcon />, path: '/customers' },
  { key: 'employees', icon: <BadgeIcon />, path: '/employees' },
  { key: 'files', icon: <FolderIcon />, path: '/files' },
  { key: 'courts', icon: <AccountBalanceIcon />, path: '/courts' },
  { key: 'governments', icon: <LocationCityIcon />, path: '/governments' },
  { key: 'contenders', icon: <PersonSearchIcon />, path: '/contenders' },
  { key: 'sitings', icon: <EventIcon />, path: '/sitings' },
  { key: 'consultations', icon: <ChatIcon />, path: '/consultations' },
  { key: 'judicial', icon: <DescriptionIcon />, path: '/judicial' },
  { key: 'tasks', icon: <TaskIcon />, path: '/tasks' },
  { key: 'billing', icon: <ReceiptIcon />, path: '/billing' },
  { key: 'trustaccounting', icon: <TrustAccountingIcon />, path: '/trust-accounting' },
  { key: 'trustreports', icon: <TrustReportsIcon />, path: '/trust-reports' },
  { key: 'reports', icon: <ReportsIcon />, path: '/reports' },
  { key: 'calendar', icon: <CalendarIcon />, path: '/calendar' },
  { key: 'documentgeneration', icon: <DocGenIcon />, path: '/document-generation' },
  { key: 'courtautomation', icon: <CourtAutomationIcon />, path: '/court-automation' },
  { key: 'clientportal', icon: <PortalIcon />, path: '/client-portal' },
  { key: 'auditlogs', icon: <AuditIcon />, path: '/auditlogs' },
  { key: 'users', icon: <PersonIcon />, path: '/users' },
  { key: 'caserelations', icon: <LinkIcon />, path: '/caserelations' },
  { key: 'intake', icon: <IntakeIcon />, path: '/intake' },
  { key: 'esign', icon: <ESignIcon />, path: '/esign' },
  { key: 'timetracking', icon: <TimeTrackingIcon />, path: '/timetracking' },
  { key: 'administration', icon: <AdminPanelSettingsIcon />, path: '/administration' },
];

interface LayoutProps {
  children: React.ReactNode;
}

interface ChatMessage {
  id: number;
  role: 'assistant' | 'user';
  text: string;
}

export default function Layout({ children }: LayoutProps) {
  const pathname = usePathname();
  const isLayoutBypassedPage =
    pathname === '/login' ||
    pathname === '/register' ||
    pathname === '/forgot-password' ||
    pathname === '/reset-password' ||
    pathname === '/intake/public' ||
    pathname.startsWith('/esign/sign/');

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const router = useRouter();
  const { user, logout, isAuthenticated, isAuthInitialized, hasRole, hasAnyRole } = useAuth();
  const { t, i18n } = useTranslation()
  const [langAnchor, setLangAnchor] = useState<null | HTMLElement>(null)
  const [chatOpen, setChatOpen] = useState(false)
  const [chatInput, setChatInput] = useState('')
  const [chatLoading, setChatLoading] = useState(false)
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([])
  const chatEndRef = React.useRef<HTMLDivElement | null>(null)
  const isAdmin = hasRole('Admin')
  const canUseIntake = hasAnyRole('Admin', 'Employee')
  const canUseESign = hasAnyRole('Admin', 'Employee')
  const canUseTimeTracking = hasAnyRole('Admin', 'Employee')
  const visibleMenuItems = menuItems.filter((item) => {
    if (item.key === 'administration') return isAdmin
    if (item.key === 'intake') return canUseIntake
    if (item.key === 'esign') return canUseESign
    if (item.key === 'timetracking') return canUseTimeTracking
    return true
  })
  // Start from SSR default language to keep hydrated text identical.
  const [lng, setLng] = useState('ar')
  const assistantLanguage: 'ar' | 'en' = (lng && lng.startsWith('ar')) ? 'ar' : 'en'

  React.useEffect(() => {
    if (!isAuthInitialized || isLayoutBypassedPage) return;

    let targetPath: string | null = null;

    if (!isAuthenticated) {
      const hasStoredToken = typeof window !== 'undefined' && !!localStorage.getItem('lawyersys-token');
      if (!hasStoredToken) {
        targetPath = '/login';
      }
    } else if (pathname === '/administration' && !isAdmin) {
      targetPath = '/dashboard';
    } else if (pathname === '/intake' && !canUseIntake) {
      targetPath = '/dashboard';
    } else if (pathname === '/esign' && !canUseESign) {
      targetPath = '/dashboard';
    } else if (pathname === '/timetracking' && !canUseTimeTracking) {
      targetPath = '/dashboard';
    }

    if (targetPath && pathname !== targetPath) {
      router.replace(targetPath);
    }
  }, [
    isAuthInitialized,
    isLayoutBypassedPage,
    isAuthenticated,
    pathname,
    isAdmin,
    canUseIntake,
    canUseESign,
    canUseTimeTracking,
    router,
  ]);

  // keep layout reactive to language changes so elements like the drawer
  // reposition immediately when switching between LTR/RTL
  React.useEffect(() => {
    const onChange = (l: string) => setLng(l)
    i18n.on('languageChanged', onChange)
    const detected = i18n.resolvedLanguage || i18n.language
    if (detected) setLng(detected)
    return () => { i18n.off('languageChanged', onChange) }
  }, [i18n])
  // prefer using theme direction (keeps in sync with ThemeProvider) but
  // fall back to i18n language or the document dir attribute if theme isn't updated yet
  const docDir = typeof document !== 'undefined' ? document.documentElement.getAttribute('dir') : null
  const isRTL = theme.direction === 'rtl' || (lng && lng.startsWith('ar')) || docDir === 'rtl'
  // Use the effective isRTL boolean so drawer anchor follows the same
  // runtime detection (i18n or theme) and doesn't get out of sync.
  const drawerAnchor = isRTL ? 'right' : 'left'

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleLangOpen = (event: React.MouseEvent<HTMLElement>) => setLangAnchor(event.currentTarget)
  const handleLangClose = () => setLangAnchor(null)
  const changeLang = (lng: string) => {
    try {
      document.documentElement.setAttribute('dir', lng.startsWith('ar') ? 'rtl' : 'ltr')
      document.documentElement.setAttribute('lang', lng.startsWith('ar') ? 'ar' : 'en')
    } catch {}
    i18n.changeLanguage(lng);
    handleLangClose();
  }

  const handleProfileMenuClose = () => {
    setAnchorEl(null);
  };

  const handleOpenProfile = () => {
    handleProfileMenuClose();
    router.push('/profile');
    setTimeout(() => {
      if (typeof window !== 'undefined' && window.location.pathname !== '/profile') {
        window.location.assign('/profile');
      }
    }, 75);
  };

  const handleLogout = () => {
    logout();
    handleProfileMenuClose();
    router.replace('/login');
  };

  const handleNavigation = (path: string) => {
    if (isMobile) {
      setMobileOpen(false);
    }
    router.push(path);
  };

  const collapsedWidth = 72;
  const [collapsed, setCollapsed] = useState<boolean>(false);

  // Ensure sidebar defaults to expanded. Clear any previous saved collapsed state on mount.
  React.useEffect(() => {
    try { localStorage.setItem('layout.sidebarCollapsed', 'false') } catch {}
  }, []);

  React.useEffect(() => {
    try { localStorage.setItem('layout.sidebarCollapsed', collapsed ? 'true' : 'false') } catch {}
  }, [collapsed]);

  React.useEffect(() => {
    if (!chatOpen || chatMessages.length > 0) return
    setChatMessages([
      {
        id: Date.now(),
        role: 'assistant',
        text: t(
          'aiAssistant.quickChatGreeting',
          assistantLanguage === 'ar'
            ? 'مرحباً، كيف يمكنني مساعدتك في عملك القانوني اليوم؟'
            : 'Hello, how can I help with your legal work today?',
        ),
      },
    ])
  }, [chatOpen, chatMessages.length, assistantLanguage, t])

  React.useEffect(() => {
    if (!chatOpen) return
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [chatMessages, chatLoading, chatOpen])

  const currentPageKey =
    pathname === '/profile'
      ? 'profile'
      : pathname === '/ai-assistant'
      ? 'aiassistant'
      : (visibleMenuItems.find((item) => item.path === pathname)?.key || 'dashboard');

  const handleSendChat = async () => {
    const prompt = chatInput.trim()
    if (!prompt || chatLoading) return

    const userMessage: ChatMessage = {
      id: Date.now(),
      role: 'user',
      text: prompt,
    }
    const nextHistory = [...chatMessages.slice(-8), userMessage]
    setChatMessages((prev) => [...prev, userMessage])
    setChatInput('')
    setChatLoading(true)

    try {
      const context = nextHistory
        .map((m) => `${m.role === 'user' ? 'User' : 'Assistant'}: ${m.text}`)
        .join('\n')

      const res = await api.post('/AIAssistant/draft', {
        language: assistantLanguage,
        draftType: 'General',
        instructions: prompt,
        context,
      })

      const replyText = String(
        res?.data?.draftText
          || res?.data?.summary
          || t(
            'aiAssistant.quickChatResponseFallback',
            assistantLanguage === 'ar'
              ? 'تم استلام رسالتك وسيتم الرد قريباً.'
              : 'Your request was received and processed.',
          )
      )

      setChatMessages((prev) => [
        ...prev,
        { id: Date.now() + 1, role: 'assistant', text: replyText },
      ])
    } catch (e: any) {
      const fallback = e?.response?.data?.message
        || t(
          'aiAssistant.quickChatErrorFallback',
          assistantLanguage === 'ar'
            ? 'حدث خطأ أثناء معالجة الطلب. حاول مرة أخرى.'
            : 'An error occurred while processing your request. Please try again.',
        )

      setChatMessages((prev) => [
        ...prev,
        { id: Date.now() + 1, role: 'assistant', text: String(fallback) },
      ])
    } finally {
      setChatLoading(false)
    }
  }

  const handleChatInputKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      void handleSendChat()
    }
  }
  const chatArabicSide = (i18n.resolvedLanguage || i18n.language || lng || '').startsWith('ar')
  const quickChatOpenLabel = t(
    'aiAssistant.quickChatOpen',
    assistantLanguage === 'ar' ? 'فتح محادثة المساعد' : 'Open assistant chat',
  )
  const quickChatCloseLabel = t(
    'aiAssistant.quickChatClose',
    assistantLanguage === 'ar' ? 'إغلاق محادثة المساعد' : 'Close assistant chat',
  )

  if (isLayoutBypassedPage) {
    return <>{children}</>;
  }

  if (!isAuthInitialized) {
    return null;
  }

  const drawer = (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column', bgcolor: 'background.paper' }}>
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          p: 2.5,
          minHeight: 72,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box
            sx={{
              width: 42,
              height: 42,
              borderRadius: 3,
              background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 8px 16px rgba(20, 52, 90, 0.3)',
            }}
          >
            <GavelIcon sx={{ color: 'white', fontSize: 24 }} />
          </Box>
          {!collapsed && (
            <Typography variant="h5" sx={{ fontWeight: 900, color: 'text.primary', letterSpacing: '-0.03em', background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
              LawyerSys
            </Typography>
          )}
        </Box>
        {!isMobile && (
          <IconButton
            onClick={() => setCollapsed(!collapsed)}
            size="small"
            sx={{ 
              bgcolor: 'primary.50',
              color: 'primary.main',
              '&:hover': { bgcolor: 'primary.100' },
              position: 'relative',
              zIndex: 3,
              p: 1
            }}
          >
            {isRTL ? (collapsed ? <ChevronLeftIcon /> : <ChevronRightIcon />) : (collapsed ? <ChevronRightIcon /> : <ChevronLeftIcon />)}
          </IconButton>
        )}
      </Box>
      
      <Box sx={{ px: 3, mb: 2, mt: 1 }}>
        {!collapsed && (
          <Typography variant="overline" sx={{ fontWeight: 800, color: 'text.secondary', opacity: 0.5, letterSpacing: '0.1em' }}>
            {t('app.menu')}
          </Typography>
        )}
      </Box>

      <List sx={{ flex: 1, px: 2, py: 0 }}>
        {visibleMenuItems.map((item) => (
          <ListItem key={item.key} disablePadding sx={{ mb: 0.8 }}>
            <Tooltip title={t(`app.${item.key}`)} placement={isRTL ? 'left' : 'right'} disableHoverListener={!collapsed}>
              <ListItemButton
                selected={pathname === item.path}
                onClick={() => handleNavigation(item.path)}
                sx={{
                  borderRadius: 3,
                  justifyContent: collapsed ? 'center' : undefined,
                  px: collapsed ? 1.5 : 2.5,
                  py: 1.4,
                  transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                  '&.Mui-selected': {
                    background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
                    color: 'white',
                    boxShadow: '0 10px 20px -5px rgba(20, 52, 90, 0.35)',
                    '& .MuiListItemIcon-root': {
                      color: 'white',
                    },
                    '&:hover': {
                      background: 'linear-gradient(135deg, #112b4b 0%, #255a74 100%)',
                    },
                  },
                  '&:hover:not(.Mui-selected)': {
                    bgcolor: 'primary.50',
                    color: 'primary.main',
                    '& .MuiListItemIcon-root': {
                      color: 'primary.main',
                    },
                    transform: isRTL ? 'translateX(-4px)' : 'translateX(4px)',
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: collapsed ? 'auto' : 40,
                    color: pathname === item.path ? 'inherit' : 'text.secondary',
                    mr: isRTL ? 0 : (collapsed ? 0 : 1),
                    ml: isRTL ? (collapsed ? 0 : 1) : 0,
                    transition: 'color 0.2s',
                  }}
                >
                  {React.cloneElement(item.icon as React.ReactElement, { fontSize: 'medium' })}
                </ListItemIcon>
                {!collapsed && (
                  <ListItemText
                    primary={t(`app.${item.key}`)}
                    primaryTypographyProps={{
                      fontSize: '0.95rem',
                      fontWeight: pathname === item.path ? 800 : 600,
                      letterSpacing: '-0.01em',
                    }}
                  />
                )}
              </ListItemButton>
            </Tooltip>
          </ListItem>
        ))}
      </List>

      <Box sx={{ p: 2, mt: 'auto' }}>
        <Paper
          elevation={0}
          sx={{
            p: collapsed ? 1 : 2,
            bgcolor: 'grey.50',
            borderRadius: 4,
            border: '1px solid',
            borderColor: 'divider',
            display: 'flex',
            alignItems: 'center',
            gap: 1.5,
            transition: 'all 0.2s',
            '&:hover': {
              bgcolor: 'white',
              boxShadow: '0 4px 12px rgba(0,0,0,0.05)',
              borderColor: 'primary.200',
            }
          }}
        >
          <Avatar
            sx={{
              width: 42,
              height: 42,
              borderRadius: 2.5,
              background: 'linear-gradient(135deg, #b98746 0%, #d4a15a 100%)',
              fontWeight: 800,
              boxShadow: '0 4px 12px rgba(185, 135, 70, 0.3)',
            }}
          >
            {(user?.fullName?.charAt(0) || user?.userName?.charAt(0) || 'U').toUpperCase()}
          </Avatar>
          {!collapsed && (
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Typography variant="subtitle2" noWrap sx={{ fontWeight: 800, color: 'text.primary' }}>
                {user?.fullName || user?.userName}
              </Typography>
              <Typography variant="caption" color="text.secondary" noWrap sx={{ display: 'block', fontWeight: 600 }}>
                {t('app.lawyer', 'Senior Lawyer')}
              </Typography>
            </Box>
          )}
          {!collapsed && (
            <IconButton size="small" onClick={handleLogout} sx={{ color: 'error.main', '&:hover': { bgcolor: 'error.50' } }}>
              <LogoutIcon fontSize="small" />
            </IconButton>
          )}
        </Paper>
      </Box>
    </Box>
  );

  return (
    <Box
      dir={isRTL ? 'rtl' : 'ltr'}
      sx={{
        display: 'flex',
        minHeight: '100vh',
        bgcolor: 'background.default',
      }}
    >
      <AppBar
        position="fixed"
        sx={{
          width: { xs: '100%', md: `calc(100% - ${collapsed ? collapsedWidth : drawerWidth}px)` },
          insetInlineStart: { xs: 0, md: `${collapsed ? collapsedWidth : drawerWidth}px` },
          insetInlineEnd: 0,
          ml: 0,
          mr: 0,
          transition: theme.transitions.create(['width', 'margin'], {
            easing: theme.transitions.easing.sharp,
            duration: theme.transitions.duration.shortest,
          }),
          bgcolor: 'rgba(255, 255, 255, 0.8)',
          backdropFilter: 'blur(20px)',
          color: 'text.primary',
          zIndex: theme.zIndex.drawer + 2,
          borderBottom: '1px solid',
          borderColor: alpha(theme.palette.divider, 0.1),
          boxShadow: '0 4px 20px rgba(0,0,0,0.03)',
        }}
      >
        <Toolbar sx={{ justifyContent: 'space-between', minHeight: 72, px: { xs: 2, md: 4 } }}>
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <IconButton
              color="inherit"
              aria-label="open drawer"
              edge="start"
              onClick={handleDrawerToggle}
              sx={{ [isRTL ? 'ml' : 'mr']: 2, display: { md: 'none' }, bgcolor: 'grey.50' }}
            >
              <MenuIcon />
            </IconButton>

            {/* Desktop collapse toggle in header */}
            <IconButton
              aria-label="toggle sidebar"
              onClick={() => setCollapsed(!collapsed)}
              sx={{ display: { xs: 'none', md: 'inline-flex' }, bgcolor: 'transparent', color: 'text.primary', [isRTL ? 'ml' : 'mr']: 1 }}
            >
              {isRTL ? (collapsed ? <ChevronLeftIcon /> : <ChevronRightIcon />) : (collapsed ? <ChevronRightIcon /> : <ChevronLeftIcon />)}
            </IconButton>
            
            {/* Search Bar */}
            <Box
              sx={{
                display: { xs: 'none', sm: 'flex' },
                alignItems: 'center',
                gap: 1.5,
                bgcolor: 'grey.50',
                borderRadius: 3,
                px: 2.5,
                py: 1,
                width: 350,
                border: '1px solid',
                borderColor: 'divider',
                '&:focus-within': {
                  bgcolor: 'white',
                  borderColor: 'primary.main',
                  boxShadow: '0 0 0 4px rgba(20, 52, 90, 0.12)',
                  width: 400,
                },
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              }}
            >
              {isRTL ? (
                <>
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600, opacity: 0.8, direction: 'rtl' }}>
                    {t('app.search')}...
                  </Typography>
                  <PersonSearchIcon sx={{ color: 'primary.main', fontSize: 22 }} />
                </>
              ) : (
                <>
                  <PersonSearchIcon sx={{ color: 'primary.main', fontSize: 22 }} />
                  <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600, opacity: 0.8 }}>
                    {t('app.search')}...
                  </Typography>
                </>
              )}
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            {/* Language Selector */}
            <Button
              onClick={handleLangOpen}
              variant="text"
              size="medium"
              startIcon={!isRTL ? <HomeIcon sx={{ fontSize: 20, color: 'primary.main' }} /> : undefined}
              endIcon={isRTL ? <HomeIcon sx={{ fontSize: 20, color: 'primary.main' }} /> : undefined}
              sx={{
                borderRadius: 2.5,
                textTransform: 'none',
                fontWeight: 800,
                color: 'text.primary',
                px: 2,
                '& .MuiButton-startIcon, & .MuiButton-endIcon': {
                  m: 0,
                },
                '&:hover': { bgcolor: 'primary.50' },
              }}
            >
              {isRTL ? 'العربية' : 'English'}
            </Button>
            <Menu 
              anchorEl={langAnchor} 
              open={Boolean(langAnchor)} 
              onClose={handleLangClose}
              anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
              transformOrigin={{ vertical: 'top', horizontal: isRTL ? 'left' : 'right' }}
              PaperProps={{
                elevation: 25,
                sx: {
                  mt: 1.5,
                  borderRadius: 3,
                  border: '1px solid',
                  borderColor: 'divider',
                  minWidth: 150,
                  p: 1,
                }
              }}
            >
              <MenuItem onClick={()=>changeLang('en')} selected={!isRTL} sx={{ borderRadius: 2, fontWeight: 700, mb: 0.5 }}>English</MenuItem>
              <MenuItem onClick={()=>changeLang('ar')} selected={isRTL} sx={{ borderRadius: 2, fontWeight: 700 }}>العربية</MenuItem>
            </Menu>

            {user && (
              <>
                <Divider orientation="vertical" flexItem sx={{ mx: 0.5, height: 24, alignSelf: 'center', opacity: 0.5 }} />
                <IconButton 
                  onClick={handleProfileMenuOpen} 
                  sx={{ 
                    p: 0.5,
                    border: '2px solid',
                    borderColor: 'primary.50',
                    transition: 'all 0.2s',
                    '&:hover': { borderColor: 'primary.main', transform: 'scale(1.05)' }
                  }}
                >
                  <Avatar
                    sx={{
                      background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
                      width: 38,
                      height: 38,
                      fontSize: '0.9rem',
                      fontWeight: 800,
                      boxShadow: '0 4px 12px rgba(20, 52, 90, 0.3)',
                    }}
                  >
                    {(user.fullName?.charAt(0) || user.userName?.charAt(0) || 'U').toUpperCase()}
                  </Avatar>
                </IconButton>
                <Menu
                  anchorEl={anchorEl}
                  open={Boolean(anchorEl)}
                  onClose={handleProfileMenuClose}
                  anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
                  transformOrigin={{ vertical: 'top', horizontal: isRTL ? 'left' : 'right' }}
                  PaperProps={{
                    elevation: 25,
                    sx: {
                      mt: 1.5,
                      minWidth: 240,
                      borderRadius: 4,
                      border: '1px solid',
                      borderColor: 'divider',
                      p: 1.5,
                    }
                  }}
                >
                  <Box sx={{ px: 2, py: 1.5, mb: 1, bgcolor: 'primary.50', borderRadius: 3 }}>
                    <Typography variant="subtitle1" sx={{ fontWeight: 900, color: 'primary.dark' }}>{user.fullName || user.userName}</Typography>
                    <Typography variant="caption" sx={{ fontWeight: 700, color: 'primary.main', opacity: 0.8 }}>{user.email || 'lawyer@example.com'}</Typography>
                  </Box>
                  <MenuItem onClick={handleOpenProfile} sx={{ borderRadius: 2, py: 1.2, fontWeight: 700 }}>
                    <ListItemIcon><PersonIcon fontSize="small" sx={{ color: 'primary.main' }} /></ListItemIcon>
                    {t('app.profile')}
                  </MenuItem>
                  <Divider sx={{ my: 1, opacity: 0.5 }} />
                  <MenuItem onClick={handleLogout} sx={{ borderRadius: 2, py: 1.2, fontWeight: 700, color: 'error.main', '&:hover': { bgcolor: 'error.50' } }}>
                    <ListItemIcon><LogoutIcon fontSize="small" color="error" /></ListItemIcon>
                    {t('app.logout')}
                  </MenuItem>
                </Menu>
              </>
            )}
          </Box>
        </Toolbar>
      </AppBar>
      <Box
        component="nav"
        sx={{
          flexShrink: 0,
        }}
        aria-label="sidebar navigation"
      >
        <Drawer
          key={`drawer-temp-${isRTL ? 'rtl' : 'ltr'}`}
          variant="temporary"
          anchor={drawerAnchor}
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true,
          }}
          sx={{
            display: { xs: 'block', md: 'none' },
            '& .MuiDrawer-paper': {
              boxSizing: 'border-box',
              width: drawerWidth,
              border: 'none',
            },
          }}
          PaperProps={{ sx: { position: 'fixed', top: 0, height: '100%' } }}
        >
          {drawer}
        </Drawer>

        {/* Desktop sidebar */}
        <Box
          key={`sidebar-perm-${isRTL ? 'rtl' : 'ltr'}`}
          sx={{
            display: { xs: 'none', md: 'block' },
            position: 'fixed',
            top: 0,
            height: '100%',
            width: collapsed ? collapsedWidth : drawerWidth,
            insetInlineStart: 0,
            insetInlineEnd: 'auto',
            boxSizing: 'border-box',
            overflowX: 'hidden',
            overflowY: 'auto',
            backgroundColor: 'background.paper',
            borderInlineEnd: '1px solid',
            borderColor: 'divider',
            transition: theme.transitions.create('width', { easing: theme.transitions.easing.sharp, duration: theme.transitions.duration.shortest }),
            zIndex: theme.zIndex.drawer + 1,
          }}
        >
          {drawer}
        </Box>
      </Box>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: { xs: 2, md: 4 },
          mt: '72px',
          width: { xs: '100%', md: `calc(100% - ${collapsed ? collapsedWidth : drawerWidth}px)` },
          marginInlineStart: { xs: 0, md: `${collapsed ? collapsedWidth : drawerWidth}px` },
          marginInlineEnd: 0,
          transition: theme.transitions.create(['width', 'margin'], { easing: theme.transitions.easing.sharp, duration: theme.transitions.duration.shortest }),
        }}
      >
        {/* Breadcrumb Navigation */}
        <Box sx={{ mb: 5, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Breadcrumbs
              separator={isRTL ? <NavigateBeforeIcon sx={{ fontSize: 18, opacity: 0.6, color: 'primary.main' }} /> : <NavigateNextIcon sx={{ fontSize: 18, opacity: 0.6, color: 'primary.main' }} />}
              aria-label="breadcrumb"
              sx={{ 
                mb: 1.5,
                '& .MuiBreadcrumbs-ol': { alignItems: 'center' }
              }}
            >
              <Link
                component="button"
                onClick={() => handleNavigation('/')}
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1,
                  color: 'text.secondary',
                  textDecoration: 'none',
                  fontSize: '0.9rem',
                  fontWeight: 700,
                  transition: 'all 0.2s',
                  '&:hover': { color: 'primary.main', transform: 'translateY(-1px)' },
                }}
              >
                <HomeIcon sx={{ fontSize: 20 }} />
                {t('app.dashboard')}
              </Link>
              {pathname !== '/' && (
                <Typography 
                  variant="body2" 
                  sx={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    gap: 1, 
                    color: 'primary.main',
                    fontWeight: 800,
                    bgcolor: 'primary.50',
                    px: 2,
                    py: 0.5,
                    borderRadius: 2,
                  }}
                >
                  {t(`app.${currentPageKey}`)}
                </Typography>
              )}
            </Breadcrumbs>
            <Typography variant="h3" sx={{ fontWeight: 900, letterSpacing: '-0.03em', color: 'text.primary' }}>
              {pathname === '/' ? t('app.dashboard') : t(`app.${currentPageKey}`)}
            </Typography>
          </Box>
          
          {/* Quick Actions */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<PeopleIcon />}
              onClick={() => handleNavigation('/customers')}
              sx={{ display: { xs: 'none', sm: 'inline-flex' }, borderRadius: 3, px: 3, py: 1, fontWeight: 800, borderWidth: 2, '&:hover': { borderWidth: 2 } }}
            >
              {t('app.customers', 'Customers')}
            </Button>
            <Button
              variant="contained"
              startIcon={<GavelIcon />}
              onClick={() => handleNavigation('/cases')}
              sx={{ 
                display: { xs: 'none', sm: 'inline-flex' },
                borderRadius: 3, 
                px: 4, 
                py: 1, 
                fontWeight: 800,
                background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
                boxShadow: '0 10px 20px -5px rgba(20, 52, 90, 0.35)',
                '&:hover': {
                  background: 'linear-gradient(135deg, #112b4b 0%, #255a74 100%)',
                  boxShadow: '0 12px 24px -5px rgba(20, 52, 90, 0.45)',
                }
              }}
            >
              {t('app.newCase') || 'New Case'}
            </Button>
          </Box>
        </Box>
        
        <Box sx={{ animation: 'fade-in 0.4s ease-out' }}>
          {children}
        </Box>

        <ClickAwayListener onClickAway={() => { if (chatOpen) setChatOpen(false) }}>
          <Box>
            <Box
              sx={{
                position: 'fixed',
                bottom: { xs: 16, md: 24 },
                insetInlineEnd: { xs: 16, md: 24 },
                insetInlineStart: 'auto',
                zIndex: theme.zIndex.drawer + 3,
              }}
            >
              <Tooltip title={chatOpen ? quickChatCloseLabel : quickChatOpenLabel} placement={chatArabicSide ? 'left' : 'right'}>
                <IconButton
                  aria-label={chatOpen ? quickChatCloseLabel : quickChatOpenLabel}
                  onClick={() => setChatOpen((prev) => !prev)}
                  sx={{
                    width: 52,
                    height: 52,
                    color: 'white',
                    background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
                    boxShadow: '0 10px 20px -5px rgba(20, 52, 90, 0.35)',
                    transition: 'all 0.2s ease',
                    '&:hover': {
                      background: 'linear-gradient(135deg, #112b4b 0%, #255a74 100%)',
                      transform: 'translateY(-1px)',
                    },
                  }}
                >
                  <ChatIcon />
                </IconButton>
              </Tooltip>
            </Box>

            {chatOpen && (
              <Box
                sx={{
                  position: 'fixed',
                  bottom: { xs: 78, md: 88 },
                  insetInlineEnd: { xs: 16, md: 24 },
                  width: { xs: 'calc(100vw - 24px)', sm: 420, lg: 460 },
                  maxWidth: 'calc(100vw - 24px)',
                  zIndex: theme.zIndex.drawer + 3,
                }}
              >
                <Paper
                  elevation={0}
                  sx={{
                    border: 'none',
                    boxShadow: '0 20px 40px rgba(4, 10, 19, 0.28)',
                    borderRadius: 3,
                    display: 'flex',
                    flexDirection: 'column',
                    overflow: 'hidden',
                    minHeight: { xs: 300, sm: 360 },
                    maxHeight: 'calc(100vh - 120px)',
                    resize: { xs: 'none', md: 'both' },
                    minWidth: { md: 360 },
                    maxWidth: 'min(560px, calc(100vw - 24px))',
                  }}
                >
                  <Box
                    sx={{
                      px: 2,
                      py: 1.5,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      borderBottom: '1px solid',
                      borderColor: 'divider',
                      background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
                      color: 'white',
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <AiAssistantIcon fontSize="small" />
                      <Typography variant="subtitle1" sx={{ fontWeight: 800 }}>
                        {t('aiAssistant.quickChatTitle', 'Assistant Chat')}
                      </Typography>
                    </Box>
                    <IconButton onClick={() => setChatOpen(false)} size="small" sx={{ color: 'white' }}>
                      <CloseIcon fontSize="small" />
                    </IconButton>
                  </Box>

                  <Box sx={{ flex: 1, overflowY: 'auto', p: 2, bgcolor: '#f5f8fc' }}>
                    {chatMessages.map((message) => (
                      <Box
                        key={message.id}
                        sx={{
                          display: 'flex',
                          justifyContent: message.role === 'user' ? 'flex-end' : 'flex-start',
                          mb: 1.2,
                        }}
                      >
                        <Box
                          sx={{
                            maxWidth: '86%',
                            px: 1.5,
                            py: 1.15,
                            borderRadius: 2,
                            whiteSpace: 'pre-wrap',
                            lineHeight: 1.5,
                            bgcolor: message.role === 'user' ? 'primary.main' : 'white',
                            color: message.role === 'user' ? 'white' : 'text.primary',
                            border: message.role === 'user' ? 'none' : '1px solid #e5edf6',
                            boxShadow: message.role === 'user'
                              ? '0 6px 16px rgba(20, 52, 90, 0.24)'
                              : '0 3px 10px rgba(2, 12, 27, 0.05)',
                          }}
                        >
                          <Typography variant="body2">{message.text}</Typography>
                        </Box>
                      </Box>
                    ))}

                    {chatLoading && (
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, px: 0.5, py: 0.5 }}>
                        <CircularProgress size={16} />
                        <Typography variant="caption" color="text.secondary">
                          {t('app.loading')}
                        </Typography>
                      </Box>
                    )}
                    <div ref={chatEndRef} />
                  </Box>

                  <Box sx={{ p: 1.5, borderTop: '1px solid', borderColor: 'divider', bgcolor: 'white' }}>
                    <TextField
                      fullWidth
                      multiline
                      maxRows={4}
                      size="small"
                      value={chatInput}
                      onChange={(e) => setChatInput(e.target.value)}
                      onKeyDown={handleChatInputKeyDown}
                      placeholder={t('aiAssistant.quickChatPlaceholder', 'Type your message...')}
                      InputProps={{
                        endAdornment: (
                          <IconButton
                            edge="end"
                            color="primary"
                            onClick={() => void handleSendChat()}
                            disabled={chatLoading || !chatInput.trim()}
                          >
                            <SendRoundedIcon fontSize="small" />
                          </IconButton>
                        ),
                      }}
                    />
                  </Box>
                </Paper>
              </Box>
            )}
          </Box>
        </ClickAwayListener>
      </Box>
    </Box>
  );
}
