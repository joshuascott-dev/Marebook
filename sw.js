// Marebook service worker: the app shell works offline; data sync is handled in the app.
const CACHE = "marebook-v9";
const SHELL = ["/", "/index.html", "/config.js", "/manifest.webmanifest", "/icons/icon-192.png", "/icons/icon-512.png", "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => Promise.all(SHELL.map(u => c.add(u).catch(() => null))))); self.skipWaiting(); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))); self.clients.claim(); });
self.addEventListener("fetch", e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== "GET") return;
  if (/supabase\.co$/.test(u.hostname) && !u.pathname.includes("/storage/v1/object/public/")) return; // live data: never cache
  const isPage = r.mode === "navigate" || (u.origin === location.origin && (u.pathname === "/" || u.pathname.endsWith(".html") || u.pathname.endsWith("config.js")));
  if (isPage){ // network first, fall back to the saved copy
    e.respondWith(fetch(r).then(res => { const cp = res.clone(); caches.open(CACHE).then(c => c.put(r, cp)); return res; }).catch(() => caches.match(r).then(m => m || caches.match("/index.html"))));
    return;
  }
  e.respondWith(caches.match(r).then(m => m || fetch(r).then(res => { if (res.ok && (u.origin === location.origin || /jsdelivr|gstatic|googleapis|supabase\.co/.test(u.hostname))){ const cp = res.clone(); caches.open(CACHE).then(c => c.put(r, cp)); } return res; })));
});
