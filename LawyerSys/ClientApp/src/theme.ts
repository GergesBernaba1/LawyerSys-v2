import { createTheme } from '@mui/material/styles';

const base = {
  palette: {
    mode: 'light',
    primary: {
      main: '#4f46e5', // Modern Indigo
      light: '#818cf8',
      dark: '#3730a3',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#e11d48', // Modern Rose
      light: '#fb7185',
      dark: '#9f1239',
      contrastText: '#ffffff',
    },
    background: {
      default: '#f8fafc', // Slate 50
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
      secondary: '#64748b', // Slate 500
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
    borderRadius: 12,
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
          borderRadius: 10,
          padding: '8px 16px',
          boxShadow: 'none',
          fontWeight: 600,
          '&:hover': {
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)',
          },
        },
        containedPrimary: {
          background: 'linear-gradient(135deg, #4f46e5 0%, #6366f1 100%)',
          '&:hover': {
            background: 'linear-gradient(135deg, #4338ca 0%, #4f46e5 100%)',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
          borderRadius: 16,
          border: '1px solid #e2e8f0',
          '&:hover': {
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1)',
            borderColor: '#cbd5e1',
          },
          transition: 'all 0.2s ease-in-out',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          backgroundImage: 'none',
        },
        elevation1: {
          boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 10,
            backgroundColor: '#ffffff',
            '& fieldset': {
              borderColor: '#e2e8f0',
            },
            '&:hover fieldset': {
              borderColor: '#cbd5e1',
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
          borderRight: '1px solid #e2e8f0',
          borderLeft: '1px solid #e2e8f0',
          backgroundColor: '#ffffff',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: 'rgba(255, 255, 255, 0.8)',
          backdropFilter: 'blur(8px)',
          color: '#0f172a',
          boxShadow: 'none',
          borderBottom: '1px solid #e2e8f0',
        },
      },
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: 10,
          margin: '4px 12px',
          padding: '10px 16px',
          color: '#64748b',
          '&.Mui-selected': {
            backgroundColor: '#f1f5f9',
            color: '#4f46e5',
            fontWeight: 600,
            '& .MuiListItemIcon-root': {
              color: '#4f46e5',
            },
            '&:hover': {
              backgroundColor: '#e2e8f0',
            },
          },
          '&:hover': {
            backgroundColor: '#f8fafc',
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
            textAlign: isRTL ? 'right' : 'left',
            padding: '16px',
            borderColor: '#f1f5f9',
          },
          head: {
            fontWeight: 700,
            backgroundColor: '#f8fafc',
            color: '#475569',
            borderBottom: '2px solid #e2e8f0',
            textAlign: isRTL ? 'right' : 'left',
          },
        },
      },
      MuiTextField: {
        styleOverrides: {
          root: {
            '& .MuiOutlinedInput-root': {
              borderRadius: 10,
              backgroundColor: '#ffffff',
              '& fieldset': {
                borderColor: '#e2e8f0',
              },
              '&:hover fieldset': {
                borderColor: '#cbd5e1',
              },
              '&.Mui-focused fieldset': {
                borderWidth: '2px',
              },
            },
            '& .MuiInputBase-input': {
              textAlign: isRTL ? 'right' : 'left',
            },
            '& .MuiInputLabel-root': {
              left: isRTL ? 'auto' : 0,
              right: isRTL ? 0 : 'auto',
              transformOrigin: isRTL ? 'right' : 'left',
            },
          },
        },
      },
      MuiInputLabel: {
        styleOverrides: {
          root: {
            left: isRTL ? 'auto' : 0,
            right: isRTL ? 28 : 'auto',
            transformOrigin: isRTL ? 'top right' : 'top left',
          },
        },
      },
      MuiOutlinedInput: {
        styleOverrides: {
          notchedOutline: {
            textAlign: isRTL ? 'right' : 'left',
          },
        },
      },
      MuiDialogTitle: {
        styleOverrides: {
          root: {
            textAlign: isRTL ? 'right' : 'left',
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
            marginRight: isRTL ? 0 : 12,
            marginLeft: isRTL ? 12 : 0,
            color: 'inherit',
          },
        },
      },
    },
  });
};

export default getTheme;
