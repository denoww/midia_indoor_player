// offline-app-service-worker.js
const VERSION = 'sc-player-v3';
const SHELL_CACHE = `shell-${VERSION}`;
const RUNTIME_CACHE = `rt-${VERSION}`;
const API_CACHE = `api-${VERSION}`;

const APP_SHELL = [
  '/', '/index.html',
  '/stylesheets/fonts.css',
  '/stylesheets/styles.css',
  '/stylesheets/sc-icons.css',
  '/images/favicon.png',
  '/images/logo-white.png',
  // REMOVIDOS icons 192/512 se não existir no servidor
  '/javascripts/lib/array.js',
  '/javascripts/lib/date.js',
  '/javascripts/lib/object.js',
  '/javascripts/lib/string.js',
  '/javascripts/lib/moment.min.js',
  '/javascripts/lib/moment-timezone.js',
  '/javascripts/lib/moment_pt-br.js',
  '/javascripts/lib/vue.min.js',
  '/javascripts/lib/vue-resource.min.js',
  '/javascripts/player.js',
  '/images/weather/few_clouds.png',
  '/images/weather/clear.png',
  '/images/weather/clouds.png',
  '/images/weather/rain.png',
];

function isHttp(s) {
  return s === 'http:' || s === 'https:';
}
function isApiRequest(url) {
  return url.pathname.startsWith('/grade') ||
         url.pathname.startsWith('/feeds') ||
         url.pathname.startsWith('/check_tv');
}
function isStaticAsset(req) {
  return (
    req.destination === 'style' ||
    req.destination === 'script' ||
    req.destination === 'font' ||
    req.destination === 'image' ||
    req.destination === 'document'
  );
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(SHELL_CACHE);
    const results = await Promise.allSettled(
      APP_SHELL.map(u => cache.add(new Request(u, { cache: 'reload' })))
    );
    const fails = results
      .map((r,i)=>[r,APP_SHELL[i]])
      .filter(([r])=>r.status==='rejected');
    if (fails.length) {
      console.warn('[SW] pulando itens ausentes no APP_SHELL:', fails.map(([,u])=>u));
    }
  })());
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys.filter(k => ![SHELL_CACHE, RUNTIME_CACHE, API_CACHE].includes(k))
          .map(k => caches.delete(k))
    );
  })());
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // 0) Ignorar esquemas não-HTTP (chrome-extension, blob, data, file, about)
  if (!isHttp(url.protocol)) return;

  // 0.1) Range requests (vídeo): não cachear, só proxy
  if (req.headers.has('range')) {
    event.respondWith(fetch(req));
    return;
  }

  // 1) API -> network-first
  if (isApiRequest(url)) {
    event.respondWith(networkFirst(req, API_CACHE));
    return;
  }

  // 2) assets estáticos -> cache-first
  if (isStaticAsset(req)) {
    event.respondWith(cacheFirst(req, SHELL_CACHE));
    return;
  }

  // 3) demais -> SWR
  event.respondWith(staleWhileRevalidate(req, RUNTIME_CACHE));
});

// Estratégias
async function cacheFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  const hit = await cache.match(req, { ignoreVary: true, ignoreSearch: true });
  if (hit) return hit;

  const resp = await fetch(req);
  if (canCacheResponse(resp)) cache.put(req, resp.clone());
  return resp;
}

async function networkFirst(req, cacheName) {
  const cache = await caches.open(cacheName);
  try {
    const resp = await fetch(req);
    if (canCacheResponse(resp)) cache.put(req, resp.clone());
    return resp;
  } catch (e) {
    const hit = await cache.match(req, { ignoreVary: true, ignoreSearch: true });
    if (hit) return hit;
    if (req.destination === 'document') {
      const shell = await caches.open(SHELL_CACHE);
      return (await shell.match('/index.html')) || new Response('offline', { status: 503 });
    }
    throw e;
  }
}

async function staleWhileRevalidate(req, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(req, { ignoreVary: true });
  const fetchPromise = fetch(req).then((resp) => {
    if (canCacheResponse(resp)) cache.put(req, resp.clone());
    return resp;
  }).catch(() => null);
  return cached || fetchPromise || Response.error();
}

// Só cacheia respostas completas (200) e não-parciais
function canCacheResponse(resp) {
  if (!resp || !resp.ok) return false;
  if (resp.status !== 200) return false;                   // evita 206
  const cr = resp.headers.get('Content-Range');
  if (cr) return false;                                    // evita parciais
  // Se quiser, ignore também respostas opaques de cross-origin:
  // if (resp.type === 'opaque') return false;
  return true;
}
