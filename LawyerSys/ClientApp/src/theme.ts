import { createTheme } from '@mui/material/styles';

const base = {
  palette: {
    mode: 'light',
    primary: {
      main: '#14345a', // Legal Deep Blue
      light: '#2d6a87',
      dark: '#112b4b',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#b98746', // Legal Gold
      light: '#d4a15a',
      dark: '#8a602d',
      contrastText: '#ffffff',
    },
    background: {
      default: '#eef4fa',
      paper: '#ffffff',
    },
    error: {
      main: '#ef4444',
    },
    warning: {
      main: '#f59e0b',
    },
    info: {
      main: '#0ea5e9',
    },
    success: {
      main: '#10b981',
    },
    text: {
      primary: '#0f172a', // Slate 900
      secondary: '#5f7085',
    },
    divider: '#e2e8f0',
  },
  typography: {
    fontFamily: '"Inter", "Poppins", "Roboto", "Helvetica", "Arial", sans-serif',
    fontSize: 14,
    h1: {
      fontWeight: 800,
      fontSize: '2.5rem',
      lineHeight: 1.2,
      letterSpacing: '-0.02em',
    },
    h2: {
      fontWeight: 700,
      fontSize: '2rem',
      lineHeight: 1.3,
      letterSpacing: '-0.01em',
    },
    h3: {
      fontWeight: 700,
      fontSize: '1.5rem',
      lineHeight: 1.4,
    },
    h4: {
      fontWeight: 600,
      fontSize: '1.25rem',
      lineHeight: 1.4,
    },
    h5: {
      fontWeight: 600,
      fontSize: '1.125rem',
      lineHeight: 1.5,
    },
    h6: {
      fontWeight: 600,
      fontSize: '1rem',
      lineHeight: 1.5,
    },
    body1: {
      fontSize: '1rem',
      lineHeight: 1.6,
    },
    body2: {
      fontSize: '0.875rem',
      lineHeight: 1.5,
    },
    button: {
      textTransform: 'none',
      fontWeight: 600,
      fontSize: '0.875rem',
    },
    subtitle1: {
      fontSize: '1rem',
      fontWeight: 500,
      color: '#64748b',
    },
    subtitle2: {
      fontSize: '0.875rem',
      fontWeight: 500,
      color: '#64748b',
    },
  },
  shape: {
    borderRadius: 18,
  },
  shadows: [
    'none',
    '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
    '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)',
    '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1)',
    '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)',
    '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
    ...Array(18).fill('none'),
  ],
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 14,
          padding: '10px 18px',
          boxShadow: 'none',
          fontWeight: 700,
          '&:hover': {
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)',
          },
        },
        containedPrimary: {
          background: 'linear-gradient(135deg, #14345a 0%, #2d6a87 100%)',
          '&:hover': {
            background: 'linear-gradient(135deg, #112b4b 0%, #255a74 100%)',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 18px 40px -30px rgba(15, 23, 42, 0.3)',
          borderRadius: 22,
          border: '1px solid rgba(20, 52, 90, 0.1)',
          '&:hover': {
            boxShadow: '0 26px 52px -34px rgba(15, 23, 42, 0.34)',
            borderColor: 'rgba(20, 52, 90, 0.18)',
          },
          transition: 'all 0.2s ease-in-out',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 18,
          backgroundImage: 'none',
        },
        elevation1: {
          boxShadow: '0 18px 40px -30px rgba(15, 23, 42, 0.28)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 14,
            backgroundColor: 'rgba(255,255,255,0.92)',
            '& fieldset': {
              borderColor: 'rgba(20, 52, 90, 0.12)',
            },
            '&:hover fieldset': {
              borderColor: 'rgba(20, 52, 90, 0.2)',
            },
            '&.Mui-focused fieldset': {
              borderWidth: '2px',
            },
          },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 700,
          backgroundColor: '#f8fafc',
          color: '#475569',
          borderBottom: '2px solid #e2e8f0',
        },
        root: {
          padding: '16px',
          borderColor: '#f1f5f9',
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          borderRight: '1px solid rgba(20, 52, 90, 0.08)',
          borderLeft: '1px solid rgba(20, 52, 90, 0.08)',
          background:
            'linear-gradient(180deg, rgba(255,255,255,0.98) 0%, rgba(247,250,252,0.98) 100%)',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: 'rgba(255, 255, 255, 0.82)',
          backdropFilter: 'blur(16px)',
          color: '#0f172a',
          boxShadow: 'none',
          borderBottom: '1px solid rgba(20, 52, 90, 0.08)',
        },
      },
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: 14,
          margin: '5px 12px',
          padding: '11px 16px',
          color: '#64748b',
          '&.Mui-selected': {
            background: 'linear-gradient(135deg, rgba(20, 52, 90, 0.1) 0%, rgba(45, 106, 135, 0.12) 100%)',
            color: '#14345a',
            fontWeight: 600,
            '& .MuiListItemIcon-root': {
              color: '#14345a',
            },
            '&:hover': {
              backgroundColor: 'rgba(20, 52, 90, 0.12)',
            },
          },
          '&:hover': {
            backgroundColor: '#f6f9fc',
            color: '#0f172a',
          },
        },
      },
    },
    MuiListItemIcon: {
      styleOverrides: {
        root: {
          color: 'inherit',
          minWidth: 36,
        },
      },
    },
  },
};

const getTheme = (direction: 'ltr' | 'rtl' = 'ltr') => {
  const isRTL = direction === 'rtl';
  return createTheme({ 
    ...base as any, 
    direction,
    typography: {
      ...base.typography,
      fontFamily: isRTL 
        ? '"Cairo", "Tajawal", "Noto Sans Arabic", "Arial", sans-serif'
        : '"Inter", "Poppins", "Roboto", "Helvetica", "Arial", sans-serif',
    },
    components: {
      ...base.components,
      MuiTableCell: {
        styleOverrides: {
          root: {
            textAlign: 'start',
            padding: '16px',
            borderColor: '#f1f5f9',
          },
          head: {
            fontWeight: 700,
            backgroundColor: '#f8fafc',
            color: '#475569',
            borderBottom: '2px solid #e2e8f0',
            textAlign: 'start',
          },
        },
      },
      MuiDialogTitle: {
        styleOverrides: {
          root: {
            textAlign: 'start',
            fontWeight: 700,
          },
        },
      },
      MuiDialogActions: {
        styleOverrides: {
          root: {
            flexDirection: isRTL ? 'row-reverse' : 'row',
            padding: '16px 24px',
          },
        },
      },
      MuiAlert: {
        styleOverrides: {
          root: {
            flexDirection: isRTL ? 'row-reverse' : 'row',
            borderRadius: 10,
          },
        },
      },
      MuiListItemIcon: {
        styleOverrides: {
          root: {
            minWidth: 36,
            marginInlineEnd: 12,
            color: 'inherit',
          },
        },
      },
    },
  });
};

export default getTheme;
