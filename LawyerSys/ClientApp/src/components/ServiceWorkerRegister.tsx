"use client";

import { useEffect } from 'react';

export default function ServiceWorkerRegister() {
  useEffect(() => {
    if (typeof window === 'undefined' || !('serviceWorker' in navigator)) {
      return;
    }

    navigator.serviceWorker.getRegistrations().then((registrations) => {
      registrations.forEach((registration) => {
        registration.unregister();
      });
    });

    if (process.env.NEXT_PUBLIC_ENABLE_SW !== 'true') {
      return;
    }

    navigator.serviceWorker.register('/sw.js').catch(() => {
      // no-op: service worker registration should not block app startup
    });
  }, []);

  return null;
}
