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
  const { user, logout } = useAuth();
  const { t, i18n } = useTranslation()
  const [langAnchor, setLangAnchor] = useState<null | HTMLElement>(null)
  // prefer using theme direction (keeps in sync with ThemeProvider) but
  // fall back to i18n language or the document dir attribute if theme isn't updated yet
  const docDir = typeof document !== 'undefined' ? document.documentElement.getAttribute('dir') : null
  const isRTL = theme.direction === 'rtl' || i18n.language.startsWith('ar') || docDir === 'rtl'
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
          <Typography variant="h6" sx={{ fontWeight: 700, color: 'primary.main' }}>
            LawyerSys
          </Typography>
        </Box>
        {isMobile && (
          <IconButton onClick={handleDrawerToggle}>
            {/* use a mirrored icon when RTL */}
            {isRTL ? <ChevronRightIcon /> : <ChevronLeftIcon />}
          </IconButton>
        )}
      </Box>
      <Divider />
      <List sx={{ flex: 1, py: 2 }}>
        {menuItems.map((item) => (
          <ListItem key={item.key} disablePadding>
            <ListItemButton
              selected={pathname === item.path}
              onClick={() => handleNavigation(item.path)}
              sx={{
                mx: 1,
                /* mirror icon/text order on RTL */
                flexDirection: isRTL ? 'row-reverse' : 'row',
                borderRadius: 2,
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
                  minWidth: 40,
                  color: pathname === item.path ? 'inherit' : 'text.secondary',
                  /* keep spacing correct when reversing order */
                  mr: isRTL ? 0 : 1,
                  ml: isRTL ? 1 : 0,
                }}
              >
                {item.icon}
              </ListItemIcon>
              <ListItemText
                primary={t(`app.${item.key}`)}
                primaryTypographyProps={{
                  fontSize: '0.9rem',
                  fontWeight: pathname === item.path ? 600 : 400,
                  textAlign: isRTL ? 'right' : 'left',
                }}
              />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
      <Divider />
      <Box sx={{ p: 2 }}>
        {user ? (
          <ListItemButton
            onClick={handleLogout}
            sx={{ 
              borderRadius: 2, 
              color: 'error.main',
              flexDirection: isRTL ? 'row-reverse' : 'row',
            }}
          >
            <ListItemIcon sx={{ minWidth: 40, color: 'error.main', mr: isRTL ? 0 : 1, ml: isRTL ? 1 : 0 }}>
              <LogoutIcon />
            </ListItemIcon>
            <ListItemText primary={t('app.logout')} primaryTypographyProps={{ textAlign: isRTL ? 'right' : 'left' }} />
          </ListItemButton>
        ) : (
          <ListItemButton
            onClick={() => handleNavigation('/login')}
            sx={{ 
              borderRadius: 2,
              flexDirection: isRTL ? 'row-reverse' : 'row',
            }}
          >
            <ListItemIcon sx={{ minWidth: 40, mr: isRTL ? 0 : 1, ml: isRTL ? 1 : 0 }}>
              <LoginIcon />
            </ListItemIcon>
            <ListItemText primary={t('app.login')} primaryTypographyProps={{ textAlign: isRTL ? 'right' : 'left' }} />
          </ListItemButton>
        )}
      </Box>
    </Box>
  );

  return (
    <Box
      dir={isRTL ? 'rtl' : 'ltr'}
      sx={{
        display: 'flex',
        flexDirection: isRTL ? 'row-reverse' : 'row',
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
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            {t(`app.${menuItems.find((item) => item.path === pathname)?.key || 'dashboard'}`)}
          </Typography>
          
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
            {isRTL ? 'AR' : 'EN'}
          </IconButton>
          <Menu 
            anchorEl={langAnchor} 
            open={Boolean(langAnchor)} 
            onClose={handleLangClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: isRTL ? 'left' : 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: isRTL ? 'left' : 'right' }}
          >
            <MenuItem onClick={()=>changeLang('en')} selected={!isRTL}>EN - English</MenuItem>
            <MenuItem onClick={()=>changeLang('ar')} selected={isRTL}>AR - عربي</MenuItem>
          </Menu>

          {user && (
            <>
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
                  <Box component="span" sx={{ fontWeight: 700 }}>{i18n.language}</Box>
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
        sx={{ width: { md: drawerWidth }, flexShrink: { md: 0 } }}
      >
        <Drawer
          variant="temporary"
          anchor={drawerAnchor}
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true,
          }}
          sx={{
            display: { xs: 'block', md: 'none' },
            /* Force the drawer paper to the correct side explicitly to avoid
               inconsistencies with CSS direction or other overrides. */
            '& .MuiDrawer-paper': {
                  boxSizing: 'border-box',
                  width: drawerWidth,
                  left: isRTL ? 'auto' : 0,
                  right: isRTL ? 0 : 'auto',
                },
              /* also strongly enforce paper placement so RTL renders on right */
              '& .MuiDrawer-paper.MuiDrawer-paperAnchorRight': {
                left: 'auto !important',
                right: 0,
              },
              '& .MuiDrawer-paper.MuiDrawer-paperAnchorLeft': {
                right: 'auto !important',
                left: 0,
              },
          }}
          PaperProps={{ sx: { position: 'fixed', top: '64px', height: 'calc(100% - 64px)', left: isRTL ? 'auto' : 0, right: isRTL ? 0 : 'auto' } }}
        >
          {drawer}
        </Drawer>
        <Drawer
          anchor={drawerAnchor}
          variant="permanent"
          sx={{
            display: { xs: 'none', md: 'block' },
            '& .MuiDrawer-paper': {
                  boxSizing: 'border-box',
                  width: drawerWidth,
                  left: isRTL ? 'auto' : 0,
                  right: isRTL ? 0 : 'auto',
                },
              /* enforce placement rules for permanent drawer */
              '& .MuiDrawer-paper.MuiDrawer-paperAnchorRight': {
                left: 'auto !important',
                right: 0,
              },
              '& .MuiDrawer-paper.MuiDrawer-paperAnchorLeft': {
                right: 'auto !important',
                left: 0,
              },
              /* remove root overrides - instead we'll explicitly position the paper via PaperProps */
          }}
           /* permanent drawer should remain in normal flow so it pushes main content
             (when permanent, don't use fixed positioning - let flexbox & nav width reserve the space) */
          open
        >
          {drawer}
        </Drawer>
      </Box>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          mt: '64px',
          /* let flexbox handle width; nav Box provides the reserved drawer width */
          width: 'auto',
          /* Reserve space for the permanent drawer on the correct side
             - LTR: drawer on left, so main content needs NO left margin (drawer takes space)
             - RTL: drawer on right, so main content needs NO right margin (drawer takes space)
             The margin is already handled by flexbox row-reverse, so we don't need extra margins
          */
        }}
      >
        {children}
      </Box>
    </Box>
  );
}
