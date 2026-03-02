import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Button, Dialog, DialogActions, DialogContent, DialogTitle, Typography } from '@mui/material';
import { useTranslation } from 'react-i18next';

type ConfirmOptions = {
  title?: string;
  confirmText?: string;
  cancelText?: string;
};

type ConfirmState = {
  open: boolean;
  message: string;
  title: string;
  confirmText: string;
  cancelText: string;
};

export default function useConfirmDialog() {
  const { t } = useTranslation();
  const defaultTitle = t('common.confirm', 'Confirm');
  const defaultMessage = t('common.confirmDelete', 'Are you sure you want to continue?');
  const defaultConfirmText = t('common.confirm', 'Confirm');
  const defaultCancelText = t('common.cancel', 'Cancel');

  const resolverRef = useRef<((value: boolean) => void) | null>(null);
  const [state, setState] = useState<ConfirmState>({
    open: false,
    message: defaultMessage,
    title: defaultTitle,
    confirmText: defaultConfirmText,
    cancelText: defaultCancelText,
  });

  const close = useCallback((result: boolean) => {
    setState((prev) => ({ ...prev, open: false }));
    resolverRef.current?.(result);
    resolverRef.current = null;
  }, []);

  const confirm = useCallback((message: string, options?: ConfirmOptions) => {
    return new Promise<boolean>((resolve) => {
      resolverRef.current = resolve;
      setState({
        open: true,
        message: message?.trim() || defaultMessage,
        title: options?.title?.trim() || defaultTitle,
        confirmText: options?.confirmText?.trim() || defaultConfirmText,
        cancelText: options?.cancelText?.trim() || defaultCancelText,
      });
    });
  }, [defaultCancelText, defaultConfirmText, defaultMessage, defaultTitle]);

  const confirmDialog = useMemo(() => (
    <Dialog open={state.open} onClose={() => close(false)} maxWidth="xs" fullWidth>
      <DialogTitle>{state.title}</DialogTitle>
      <DialogContent>
        <Typography>{state.message}</Typography>
      </DialogContent>
      <DialogActions>
        <Button onClick={() => close(false)}>{state.cancelText}</Button>
        <Button variant="contained" color="error" onClick={() => close(true)} autoFocus>
          {state.confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  ), [close, state]);

  return { confirm, confirmDialog };
}
