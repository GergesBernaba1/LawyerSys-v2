import { createTheme } from '@mui/material/styles';

const base = {
  palette: {
    mode: 'light',
    primary: {
      main: '#1565c0',
      light: '#1976d2',
      dark: '#0d47a1',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#7c4dff',
      light: '#b388ff',
      dark: '#651fff',
      contrastText: '#ffffff',
    },
    background: {
      default: '#f5f7fa',
      paper: '#ffffff',
    },
    error: {
      main: '#d32f2f',
    },
    warning: {
      main: '#ed6c02',
    },
    info: {
      main: '#0288d1',
    },
    success: {
      main: '#2e7d32',
    },
    text: {
      primary: '#1a1a2e',
      secondary: '#4a4a68',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontWeight: 700,
      fontSize: '2.5rem',
    },
    h2: {
      fontWeight: 600,
      fontSize: '2rem',
    },
    h3: {
      fontWeight: 600,
      fontSize: '1.75rem',
    },
    h4: {
      fontWeight: 600,
      fontSize: '1.5rem',
    },
    h5: {
      fontWeight: 600,
      fontSize: '1.25rem',
    },
    h6: {
      fontWeight: 600,
      fontSize: '1rem',
    },
    body1: {
      fontSize: '1rem',
    },
    body2: {
      fontSize: '0.875rem',
    },
    button: {
      textTransform: 'none',
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 12,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          padding: '10px 20px',
          boxShadow: 'none',
          '&:hover': {
            boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
          },
        },
        containedPrimary: {
          background: 'linear-gradient(45deg, #1565c0 30%, #1976d2 90%)',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
          borderRadius: 16,
          '&:hover': {
            boxShadow: '0 4px 20px rgba(0,0,0,0.12)',
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 12,
        },
        elevation1: {
          boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 8,
          },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 600,
          backgroundColor: '#f5f7fa',
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          borderRight: 'none',
          borderLeft: 'none',
          boxShadow: '2px 0 12px rgba(0,0,0,0.08)',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
        },
      },
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          margin: '4px 8px',
          '&.Mui-selected': {
            backgroundColor: 'rgba(21, 101, 192, 0.12)',
            '&:hover': {
              backgroundColor: 'rgba(21, 101, 192, 0.18)',
            },
          },
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
        : '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    },
    components: {
      ...base.components,
      MuiTableCell: {
        styleOverrides: {
          root: {
            textAlign: isRTL ? 'right' : 'left',
          },
          head: {
            fontWeight: 600,
            backgroundColor: '#f5f7fa',
            textAlign: isRTL ? 'right' : 'left',
          },
        },
      },
      MuiTextField: {
        styleOverrides: {
          root: {
            '& .MuiOutlinedInput-root': {
              borderRadius: 8,
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
          },
        },
      },
      MuiDialogActions: {
        styleOverrides: {
          root: {
            flexDirection: isRTL ? 'row-reverse' : 'row',
          },
        },
      },
      MuiAlert: {
        styleOverrides: {
          root: {
            flexDirection: isRTL ? 'row-reverse' : 'row',
          },
        },
      },
      MuiListItemIcon: {
        styleOverrides: {
          root: {
            minWidth: 40,
            marginRight: isRTL ? 0 : 8,
            marginLeft: isRTL ? 8 : 0,
          },
        },
      },
    },
  });
};

export default getTheme;
