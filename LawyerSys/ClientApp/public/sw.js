const CACHE_NAME = 'qadaya-v2';
const STATIC_CACHE = 'qadaya-static-v2';

// Core app shell to pre-cache on install
const APP_SHELL = [
  '/',
  '/manifest.webmanifest',
  '/favicon.svg',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((k) => k !== CACHE_NAME && k !== STATIC_CACHE)
          .map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(event.request.url);
  const isSameOrigin = requestUrl.origin === self.location.origin;
  const isNextInternal = requestUrl.pathname.startsWith('/_next');
  const isApiRoute = requestUrl.pathname.startsWith('/api');
  const isRscRequest = requestUrl.searchParams.has('_rsc');
  const isProgrammaticFetch = event.request.destination === '';

  // Never intercept API calls, Next internal, RSC, cross-origin, or XHR/fetch
  if (!isSameOrigin || isApiRoute || isNextInternal || isRscRequest || isProgrammaticFetch) {
    return;
  }

  // Static assets: cache-first strategy
  const isStaticAsset =
    requestUrl.pathname.startsWith('/icons/') ||
    requestUrl.pathname.startsWith('/fonts/') ||
    requestUrl.pathname === '/favicon.svg' ||
    requestUrl.pathname === '/manifest.webmanifest';

  if (isStaticAsset) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        if (cached) return cached;
        return fetch(event.request).then((response) => {
          if (!response || response.status !== 200) return response;
          const clone = response.clone();
          caches.open(STATIC_CACHE).then((cache) => cache.put(event.request, clone));
          return response;
        });
      })
    );
    return;
  }

  // Navigation requests: network-first, fall back to cached shell
  event.respondWith(
    caches.match(event.request).then((cached) => {
      return fetch(event.request)
        .then((response) => {
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          return response;
        })
        .catch(() => cached || caches.match('/'));
    })
  );
});
