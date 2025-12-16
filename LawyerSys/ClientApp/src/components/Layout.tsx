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
  Button,
  Tooltip,
  Breadcrumbs,
  useTheme,
  useMediaQuery,
  Collapse,
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
  Chat as ChatIcon,
  Description as DescriptionIcon,
  Task as TaskIcon,
  Receipt as ReceiptIcon,
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
} from '@mui/icons-material';
import { useAuth } from '../services/auth';
import { useTranslation } from 'react-i18next'

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
  { key: 'legacyusers', icon: <PersonIcon />, path: '/legacyusers' },
  { key: 'caserelations', icon: <LinkIcon />, path: '/caserelations' },
];

interface LayoutProps {
  children: React.ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const router = useRouter();
  const pathname = usePathname();
  const { user, logout, isAuthenticated } = useAuth();
  const { t, i18n } = useTranslation()
  const [langAnchor, setLangAnchor] = useState<null | HTMLElement>(null)
  const [lng, setLng] = useState(i18n.language || 'ar')

  // Redirect to login if not authenticated
  React.useEffect(() => {
    if (!isAuthenticated && pathname !== '/login' && pathname !== '/register') {
      router.push('/login');
    }
  }, [isAuthenticated, pathname, router]);

  // For auth pages, don't show layout
  if (pathname === '/login' || pathname === '/register') {
    return <>{children}</>;
  }

  // keep layout reactive to language changes so elements like the drawer
  // reposition immediately when switching between LTR/RTL
  React.useEffect(() => {
    const onChange = (l: string) => setLng(l)
    i18n.on('languageChanged', onChange)
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
    try { document.documentElement.setAttribute('dir', lng.startsWith('ar') ? 'rtl' : 'ltr') } catch {}
    i18n.changeLanguage(lng);
    handleLangClose();
  }

  const handleProfileMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = () => {
    logout();
    handleProfileMenuClose();
    router.push('/login');
  };

  const handleNavigation = (path: string) => {
    if (isMobile) {
      setMobileOpen(false);
    }
    router.push(path);
  };

  const collapsedWidth = 72;
  const [collapsed, setCollapsed] = useState<boolean>(() => {
    try { return localStorage.getItem('layout.sidebarCollapsed') === 'true' }
    catch { return false }
  });

  React.useEffect(() => {
    try { localStorage.setItem('layout.sidebarCollapsed', collapsed ? 'true' : 'false') } catch {}
  }, [collapsed]);

  const drawer = (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          p: 2,
          minHeight: 64,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <GavelIcon sx={{ color: 'primary.main', fontSize: 32 }} />
          {!collapsed && (
            <Typography variant="h6" sx={{ fontWeight: 700, color: 'primary.main' }}>
              LawyerSys
            </Typography>
          )}
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {/* collapse toggle on md+ */}
          <IconButton
            onClick={() => setCollapsed(!collapsed)}
            sx={{ display: { xs: 'none', md: 'inline-flex' } }}
            size="small"
            aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {isRTL ? (collapsed ? <ChevronLeftIcon /> : <ChevronRightIcon />) : (collapsed ? <ChevronRightIcon /> : <ChevronLeftIcon />)}
          </IconButton>
          {/* mobile only close button */}
          {isMobile && (
            <IconButton onClick={handleDrawerToggle}>
              {/* use a mirrored icon when RTL */}
              {isRTL ? <ChevronRightIcon /> : <ChevronLeftIcon />}
            </IconButton>
          )}
        </Box>
      </Box>
      <Divider />
      <List sx={{ flex: 1, py: 2 }}>
        {menuItems.map((item) => (
          <ListItem key={item.key} disablePadding>
            <Tooltip title={t(`app.${item.key}`)} placement={isRTL ? 'right' : 'left'} disableHoverListener={!collapsed}>
              <ListItemButton
                selected={pathname === item.path}
                onClick={() => handleNavigation(item.path)}
                sx={{
                  mx: collapsed ? 0 : 1,
                  borderRadius: 2,
                  justifyContent: collapsed ? 'center' : undefined,
                  px: collapsed ? 1.5 : undefined,
                  '&.Mui-selected': {
                    backgroundColor: 'primary.light',
                    color: 'white',
                    '& .MuiListItemIcon-root': {
                      color: 'white',
                    },
                    '&:hover': {
                      backgroundColor: 'primary.main',
                    },
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: collapsed ? 'auto' : 40,
                    color: pathname === item.path ? 'inherit' : 'text.secondary',
                    /* keep spacing correct when reversing order */
                    mr: isRTL ? 0 : (collapsed ? 0 : 1),
                    ml: isRTL ? (collapsed ? 0 : 1) : 0,
                    display: 'flex',
                    justifyContent: 'center',
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                {!collapsed && (
                  <ListItemText
                    primary={t(`app.${item.key}`)}
                    primaryTypographyProps={{
                      fontSize: '0.9rem',
                      fontWeight: pathname === item.path ? 600 : 400,
                      textAlign: isRTL ? 'right' : 'left',
                    }}
                  />
                )}
              </ListItemButton>
            </Tooltip>
          </ListItem>
        ))}
      </List>
      <Divider />
      <Box sx={{ p: 2 }}>
        {user ? (
          <Tooltip title={t('app.logout')} placement={isRTL ? 'right' : 'left'} disableHoverListener={!collapsed}>
            <ListItemButton
              onClick={handleLogout}
              sx={{ 
                borderRadius: 2, 
                color: 'error.main',
                justifyContent: collapsed ? 'center' : undefined,
              }}
            >
              <ListItemIcon sx={{ minWidth: collapsed ? 'auto' : 40, color: 'error.main', mr: isRTL ? 0 : (collapsed ? 0 : 1), ml: isRTL ? (collapsed ? 0 : 1) : 0 }}>
                <LogoutIcon />
              </ListItemIcon>
              {!collapsed && <ListItemText primary={t('app.logout')} primaryTypographyProps={{ textAlign: isRTL ? 'right' : 'left' }} />}
            </ListItemButton>
          </Tooltip>
        ) : (
          <Tooltip title={t('app.login')} placement={isRTL ? 'right' : 'left'} disableHoverListener={!collapsed}>
            <ListItemButton
              onClick={() => handleNavigation('/login')}
              sx={{ 
                borderRadius: 2,
                justifyContent: collapsed ? 'center' : undefined,
              }}
            >
              <ListItemIcon sx={{ minWidth: collapsed ? 'auto' : 40, mr: isRTL ? 0 : (collapsed ? 0 : 1), ml: isRTL ? (collapsed ? 0 : 1) : 0 }}>
                <LoginIcon />
              </ListItemIcon>
              {!collapsed && <ListItemText primary={t('app.login')} primaryTypographyProps={{ textAlign: isRTL ? 'right' : 'left' }} />}
            </ListItemButton>
          </Tooltip>
        )}
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
          width: '100%',
          bgcolor: 'background.paper',
          color: 'text.primary',
          zIndex: theme.zIndex.drawer + 2,
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ [isRTL ? 'ml' : 'mr']: 2, display: { md: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          
          {/* Language Selector */}
          <IconButton 
            onClick={handleLangOpen} 
            sx={{ 
              [isRTL ? 'ml' : 'mr']: 1,
              border: '1px solid',
              borderColor: 'divider',
              borderRadius: 2,
              px: 1.5,
              fontSize: '0.875rem',
              fontWeight: 600
            }}
          >
            {isRTL ? 'العربية' : 'English'}
          </IconButton>
          <Menu 
            anchorEl={langAnchor} 
            open={Boolean(langAnchor)} 
            onClose={handleLangClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: isRTL ? 'left' : 'right' }}
          >
            <MenuItem onClick={()=>changeLang('en')} selected={!isRTL}>English</MenuItem>
            <MenuItem onClick={()=>changeLang('ar')} selected={isRTL}>العربية</MenuItem>
          </Menu>

          {user && (
            <>
              {/* Logout Button */}
              <Tooltip title={t('app.logout')}>
                <IconButton 
                  onClick={handleLogout}
                  sx={{ 
                    [isRTL ? 'ml' : 'mr']: 1,
                    color: 'error.main',
                    '&:hover': {
                      bgcolor: 'error.light',
                      color: 'white',
                    }
                  }}
                >
                  <LogoutIcon />
                </IconButton>
              </Tooltip>

              <IconButton onClick={handleProfileMenuOpen} sx={{ p: 0 }}>
                <Avatar
                  sx={{
                    bgcolor: 'primary.main',
                    width: 36,
                    height: 36,
                  }}
                >
                  {user.email?.charAt(0).toUpperCase() || 'U'}
                </Avatar>
              </IconButton>
              <Menu
                anchorEl={anchorEl}
                open={Boolean(anchorEl)}
                onClose={handleProfileMenuClose}
                anchorOrigin={{
                  vertical: 'bottom',
                  horizontal: isRTL ? 'left' : 'right',
                }}
                transformOrigin={{
                  vertical: 'top',
                  horizontal: isRTL ? 'left' : 'right',
                }}
              >
                <MenuItem disabled>
                  <Typography variant="body2">{user.email}</Typography>
                </MenuItem>
                <Divider />
                <MenuItem onClick={() => {/* TODO: Navigate to profile */}}>
                  <ListItemIcon>
                    <PersonIcon fontSize="small" />
                  </ListItemIcon>
                  {t('app.profile')}
                </MenuItem>
                <MenuItem onClick={handleLogout}>
                  <ListItemIcon>
                    <LogoutIcon fontSize="small" />
                  </ListItemIcon>
                  {t('app.logout')}
                </MenuItem>
              </Menu>

              {/* DEV DEBUG: show detected RTL/language state (dev only) */}
              {process.env.NODE_ENV !== 'production' && (
                <Box sx={{ ml: 2, px: 1, py: 0.5, borderRadius: 1, bgcolor: 'primary.light', color: 'white', fontSize: '0.75rem', display: 'inline-flex', gap: 1, alignItems: 'center' }}>
                  <Box component="span" sx={{ opacity: 0.85 }}>dir:</Box>
                  <Box component="span" sx={{ fontWeight: 700 }}>{docDir || theme.direction}</Box>
                  <Box component="span" sx={{ opacity: 0.6 }}>|</Box>
                  <Box component="span" sx={{ opacity: 0.85 }}>i18n:</Box>
                  <Box component="span" sx={{ fontWeight: 700 }}>{lng}</Box>
                  <Box component="span" sx={{ opacity: 0.6 }}>|</Box>
                  <Box component="span" sx={{ opacity: 0.85 }}>isRTL:</Box>
                  <Box component="span" sx={{ fontWeight: 700 }}>{isRTL ? 'true' : 'false'}</Box>
                </Box>
              )}
            </>
          )}
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
            },
          }}
          PaperProps={{ sx: { position: 'fixed', top: '64px', height: 'calc(100% - 64px)' } }}
        >
          {drawer}
        </Drawer>

        {/* Desktop sidebar - uses CSS logical properties for RTL */}
        <Box
          key={`sidebar-perm-${isRTL ? 'rtl' : 'ltr'}`}
          sx={{
            display: { xs: 'none', md: 'block' },
            position: 'fixed',
            top: '64px',
            height: 'calc(100% - 64px)',
            width: collapsed ? collapsedWidth : drawerWidth,
            // Use insetInlineStart for RTL-aware positioning
            insetInlineStart: 0,
            insetInlineEnd: 'auto',
            boxSizing: 'border-box',
            overflowX: 'hidden',
            overflowY: 'auto',
            backgroundColor: theme.palette.background.paper,
            // Use borderInlineEnd for RTL-aware border
            borderInlineEnd: `1px solid ${theme.palette.divider}`,
            transition: theme.transitions.create('width', { easing: theme.transitions.easing.sharp, duration: theme.transitions.duration.shortest }),
            zIndex: theme.zIndex.drawer,
          }}
        >
          {drawer}
        </Box>
      </Box>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          mt: '64px',
          width: { xs: '100%', md: `calc(100% - ${collapsed ? collapsedWidth : drawerWidth}px)` },
          // Use marginInlineStart for RTL-aware margin
          marginInlineStart: { xs: 0, md: `${collapsed ? collapsedWidth : drawerWidth}px` },
          marginInlineEnd: 0,
        }}
      >
        {/* Breadcrumb Navigation */}
        <Breadcrumbs
          separator={isRTL ? <NavigateBeforeIcon fontSize="small" /> : <NavigateNextIcon fontSize="small" />}
          aria-label="breadcrumb"
          sx={{ mb: 2 }}
        >
          <Box
            component="a"
            href="/"
            onClick={(e: React.MouseEvent) => { e.preventDefault(); handleNavigation('/'); }}
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 0.5,
              color: 'text.secondary',
              textDecoration: 'none',
              '&:hover': { color: 'primary.main', textDecoration: 'underline' },
            }}
          >
            <HomeIcon fontSize="small" />
            {t('app.dashboard')}
          </Box>
          {pathname !== '/' && (
            <Typography color="text.primary" sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {menuItems.find((item) => item.path === pathname)?.icon}
              {t(`app.${menuItems.find((item) => item.path === pathname)?.key || 'dashboard'}`)}
            </Typography>
          )}
        </Breadcrumbs>
        {children}
      </Box>
    </Box>
  );
}
