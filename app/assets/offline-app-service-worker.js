// /offline-app-service-worker.js  (versão "mata-tudo")
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // apaga todos os caches
    const keys = await caches.keys();
    await Promise.all(keys.map(k => caches.delete(k)));
    // toma controle e desregistra
    const regs = await self.registration.unregister();
    clients.claim();
  })());
});

// Não intercepta nada
self.addEventListener('fetch', () => {});


// // offline-app-service-worker.js
// const VERSION = 'sc-player-v4'; // <- bump
// const SHELL_CACHE = `shell-${VERSION}`;
// const RUNTIME_CACHE_BASE = `rt-${VERSION}`;
// const API_CACHE_BASE = `api-${VERSION}`;

// // Mapa clientId -> tvId
// const clientTv = new Map();

// const APP_SHELL = [
//   '/', '/index.html',
//   '/stylesheets/fonts.css',
//   '/stylesheets/styles.css',
//   '/stylesheets/sc-icons.css',
//   '/images/favicon.png',
//   '/images/logo-white.png',
//   '/javascripts/lib/array.js',
//   '/javascripts/lib/date.js',
//   '/javascripts/lib/object.js',
//   '/javascripts/lib/string.js',
//   '/javascripts/lib/moment.min.js',
//   '/javascripts/lib/moment-timezone.js',
//   '/javascripts/lib/moment_pt-br.js',
//   '/javascripts/lib/vue.min.js',
//   '/javascripts/lib/vue-resource.min.js',
//   '/javascripts/player.js',
//   '/images/weather/few_clouds.png',
//   '/images/weather/clear.png',
//   '/images/weather/clouds.png',
//   '/images/weather/rain.png',
// ];

// function isHttp(s) { return s === 'http:' || s === 'https:'; }
// function isApiRequest(url) {
//   return url.pathname.startsWith('/grade') ||
//          url.pathname.startsWith('/feeds') ||
//          url.pathname.startsWith('/check_tv');
// }
// function isStaticAsset(req) {
//   return ['style','script','font','image','document'].includes(req.destination);
// }

// // Recebe tvId da página
// self.addEventListener('message', (event) => {
//   const { data, source } = event;
//   if (data && data.type === 'SET_TV_ID' && source && source.id) {
//     clientTv.set(source.id, String(data.tvId || 'unknown'));
//   }
// });

// // Helpers de nome de cache por client/tv
// function cacheNameFor(base, clientId) {
//   const tv = clientId ? clientTv.get(clientId) : null;
//   return tv ? `${base}-tv${tv}` : `${base}-default`;
// }

// self.addEventListener('install', (event) => {
//   event.waitUntil((async () => {
//     const cache = await caches.open(SHELL_CACHE);
//     const results = await Promise.allSettled(
//       APP_SHELL.map(u => cache.add(new Request(u, { cache: 'reload' })))
//     );
//     const fails = results.map((r,i)=>[r,APP_SHELL[i]]).filter(([r])=>r.status==='rejected');
//     if (fails.length) console.warn('[SW] pulando itens ausentes no APP_SHELL:', fails.map(([,u])=>u));
//   })());
//   self.skipWaiting();
// });

// self.addEventListener('activate', (event) => {
//   event.waitUntil((async () => {
//     const keys = await caches.keys();
//     await Promise.all(
//       keys.filter(k => !k.startsWith('shell-') && !k.startsWith('rt-') && !k.startsWith('api-'))
//           .map(k => caches.delete(k))
//     );
//   })());
//   self.clients.claim();
// });

// self.addEventListener('fetch', (event) => {
//   const req = event.request;
//   if (req.method !== 'GET') return;

//   const url = new URL(req.url);

//   // Guarda tvId quando vier num navigation (/?tvId=...)
//   if (event.clientId && url.searchParams.has('tvId')) {
//     clientTv.set(event.clientId, url.searchParams.get('tvId'));
//   }

//   if (!isHttp(url.protocol)) return;

//   // Range (vídeo): não cacheia
//   if (req.headers.has('range')) {
//     event.respondWith(fetch(req));
//     return;
//   }

//   const API_CACHE  = cacheNameFor(API_CACHE_BASE, event.clientId);
//   const RUNTIME_CACHE = cacheNameFor(RUNTIME_CACHE_BASE, event.clientId);

//   if (isApiRequest(url)) {
//     event.respondWith(networkFirst(req, API_CACHE));
//     return;
//   }

//   if (isStaticAsset(req)) {
//     // Shell pode ser compartilhado entre TVs
//     event.respondWith(cacheFirst(req, SHELL_CACHE));
//     return;
//   }

//   event.respondWith(staleWhileRevalidate(req, RUNTIME_CACHE));
// });

// // Estratégias
// async function cacheFirst(req, cacheName) {
//   const cache = await caches.open(cacheName);
//   const hit = await cache.match(req, { ignoreVary: true, ignoreSearch: true });
//   if (hit) return hit;

//   const resp = await fetch(req);
//   if (canCacheResponse(resp)) cache.put(req, resp.clone());
//   return resp;
// }

// async function networkFirst(req, cacheName) {
//   const cache = await caches.open(cacheName);
//   try {
//     const resp = await fetch(req);
//     if (canCacheResponse(resp)) cache.put(req, resp.clone());
//     return resp;
//   } catch (e) {
//     const hit = await cache.match(req, { ignoreVary: true, ignoreSearch: true });
//     if (hit) return hit;
//     if (req.destination === 'document') {
//       const shell = await caches.open(SHELL_CACHE);
//       return (await shell.match('/index.html')) || new Response('offline', { status: 503 });
//     }
//     throw e;
//   }
// }

// async function staleWhileRevalidate(req, cacheName) {
//   const cache = await caches.open(cacheName);
//   const cached = await cache.match(req, { ignoreVary: true });
//   const fetchPromise = fetch(req).then((resp) => {
//     if (canCacheResponse(resp)) cache.put(req, resp.clone());
//     return resp;
//   }).catch(() => null);
//   return cached || fetchPromise || Response.error();
// }

// function canCacheResponse(resp) {
//   if (!resp || !resp.ok) return false;
//   if (resp.status !== 200) return false; // evita 206
//   if (resp.headers.get('Content-Range')) return false; // evita parciais
//   // if (resp.type === 'opaque') return false; // opcional
//   return true;
// }
