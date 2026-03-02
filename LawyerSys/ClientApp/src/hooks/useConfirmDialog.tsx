import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Button, Dialog, DialogActions, DialogContent, DialogTitle, Typography } from '@mui/material';

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

const DEFAULT_TITLE = 'Confirm';
const DEFAULT_CONFIRM_TEXT = 'Confirm';
const DEFAULT_CANCEL_TEXT = 'Cancel';

export default function useConfirmDialog() {
  const resolverRef = useRef<((value: boolean) => void) | null>(null);
  const [state, setState] = useState<ConfirmState>({
    open: false,
    message: '',
    title: DEFAULT_TITLE,
    confirmText: DEFAULT_CONFIRM_TEXT,
    cancelText: DEFAULT_CANCEL_TEXT,
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
        message,
        title: options?.title || DEFAULT_TITLE,
        confirmText: options?.confirmText || DEFAULT_CONFIRM_TEXT,
        cancelText: options?.cancelText || DEFAULT_CANCEL_TEXT,
      });
    });
  }, []);

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
