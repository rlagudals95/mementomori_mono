import { defineConfig } from 'vite';
import { createHash } from 'node:crypto';

export default defineConfig({
  build: { rollupOptions: { input: { main: 'index.html', widgets: 'widgets.html', motion: 'motion.html' } } },
  plugins: [{
    name: 'offline-app-shell',
    enforce: 'post',
    generateBundle(_options, bundle) {
      const files = Object.keys(bundle).map((file) => `/${file}`);
      const hash = createHash('sha256');
      for (const [name, entry] of Object.entries(bundle)) {
        hash.update(name);
        hash.update(entry.type === 'chunk' ? entry.code : entry.source);
      }
      const revision = hash.digest('hex').slice(0, 12);
      const cache = `mementomori-${revision}`;
      const assets = ['/', '/icon.svg', '/icon-192.png', '/icon-512.png', '/icon-maskable-512.png', '/manifest.webmanifest', ...files];
      this.emitFile({ type: 'asset', fileName: 'sw.js', source: `
const CACHE = ${JSON.stringify(cache)};
const ASSETS = ${JSON.stringify(assets)};
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(ASSETS)));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith('mementomori-') && key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET' || new URL(event.request.url).origin !== self.location.origin) return;
  if (event.request.mode === 'navigate') {
    event.respondWith(fetch(event.request).catch(() => caches.match(event.request, { ignoreVary: true }).then(cached => cached || caches.match('/'))));
    return;
  }
  // These are same-origin static build artifacts. Development preview adds
  // Vary: Origin, which otherwise prevents cached module/CSS requests matching.
  event.respondWith(caches.match(event.request, { ignoreVary: true }).then(cached => cached || fetch(event.request)));
});
` });
    },
  }],
});
