const build = [
  "/_app/immutable/start-4001072d.js",
  "/_app/immutable/layout.svelte-40aabdf5.js",
  "/_app/immutable/error.svelte-be903dfb.js",
  "/_app/immutable/pages/algebra/index.svelte-9a623ca4.js",
  "/_app/immutable/assets/pages/algebra/index.svelte-6399099c.css",
  "/_app/immutable/assets/worker.3c9e647e.js",
  "/_app/immutable/pages/bench/index.svelte-f864ec60.js",
  "/_app/immutable/assets/pages/bench/index.svelte-a4b29ed6.css",
  "/_app/immutable/assets/worker.3bbd7e0c.js",
  "/_app/immutable/pages/game-2d-simple/index.svelte-0176743a.js",
  "/_app/immutable/assets/pages/game-2d-simple/index.svelte-61c9f58e.css",
  "/_app/immutable/assets/worker.4f703258.js",
  "/_app/immutable/pages/index.svelte-511d2249.js",
  "/_app/immutable/assets/pages/index.svelte-76f9793e.css",
  "/_app/immutable/pages/kilordle/index.svelte-87b4d473.js",
  "/_app/immutable/assets/pages/kilordle/index.svelte-79a80acd.css",
  "/_app/immutable/assets/kilordle-cdf7a0b1.wasm",
  "/_app/immutable/pages/painter/index.svelte-7f5419d0.js",
  "/_app/immutable/assets/pages/painter/index.svelte-7a55bec7.css",
  "/_app/immutable/assets/worker.f0e4f857.js",
  "/_app/immutable/chunks/index-d7f9ae17.js",
  "/_app/immutable/chunks/index-fd4f8e4a.js",
  "/_app/immutable/chunks/errors-24dc42ac.js",
  "/_app/immutable/assets/errors-7b4c2b46.css",
  "/_app/immutable/chunks/wasm-e70d817c.js",
  "/_app/immutable/chunks/util-93425279.js",
  "/_app/immutable/chunks/gamescreen-125cf4fe.js"
];
const files = [
  "/.gitignore",
  "/favicon.ico",
  "/fonts/cour.ttf",
  "/fonts/latex/cmunbx.ttf",
  "/fonts/latex/cmunrm.ttf",
  "/fonts/latex/cmuntb.ttf",
  "/global.css",
  "/kilordle/data.rtf",
  "/kilordle/k-emoji.svg",
  "/kilordle/kilordle.webmanifest",
  "/pfp.jpg"
];
const version = "1670814146311";
const worker = self;
const FILES = `cache${version}`;
const to_cache = build.concat(files);
const staticAssets = new Set(to_cache);
worker.addEventListener("install", (event) => {
  event.waitUntil(caches.open(FILES).then((cache) => cache.addAll(to_cache)).then(() => {
    worker.skipWaiting();
  }));
});
worker.addEventListener("activate", (event) => {
  event.waitUntil(caches.keys().then(async (keys) => {
    for (const key of keys) {
      if (key !== FILES)
        await caches.delete(key);
    }
    worker.clients.claim();
  }));
});
async function fetchAndCache(request) {
  const cache = await caches.open(`offline${version}`);
  try {
    const response = await fetch(request);
    cache.put(request, response.clone());
    return response;
  } catch (err) {
    const response = await cache.match(request);
    if (response)
      return response;
    throw err;
  }
}
worker.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET")
    return;
  if (req.headers.has("range"))
    return;
  const url = new URL(req.url);
  const isHttp = url.protocol.startsWith("http");
  if (!isHttp)
    return;
  const isStaticAsset = url.host === self.location.host && staticAssets.has(url.pathname);
  const skipBecauseUncached = req.cache === "only-if-cached" && !isStaticAsset;
  if (skipBecauseUncached)
    return;
  event.respondWith((async () => {
    const cachedAsset = isStaticAsset && await caches.match(req);
    return cachedAsset || fetchAndCache(req);
  })());
});
