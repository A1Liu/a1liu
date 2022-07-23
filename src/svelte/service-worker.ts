import { build, files, version } from "$service-worker";

// Using
// https://blog.logrocket.com/building-a-pwa-with-svelte/

const worker = self as unknown as any;
const FILES = `cache${version}`;
const to_cache = build.concat(files);
const staticAssets = new Set(to_cache);

// listen for the install events
worker.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(FILES)
      .then((cache) => cache.addAll(to_cache))
      .then(() => {
        worker.skipWaiting();
      })
  );
});

// listen for the activate events
worker.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then(async (keys) => {
      // delete old caches
      for (const key of keys) {
        if (key !== FILES) await caches.delete(key);
      }

      worker.clients.claim();
    })
  );
});

// attempt to process HTTP requests and rely on the cache if offline
async function fetchAndCache(request: Request) {
  const cache = await caches.open(`offline${version}`);
  try {
    const response = await fetch(request);
    cache.put(request, response.clone());
    return response;
  } catch (err) {
    const response = await cache.match(request);
    if (response) return response;
    throw err;
  }
}

// listen for the fetch events
worker.addEventListener("fetch", (event) => {
  const req = event.request;

  if (req.method !== "GET") return;
  if (req.headers.has("range")) return;

  const url = new URL(req.url);

  // only cache files that are local to your application
  const isHttp = url.protocol.startsWith("http");
  if (!isHttp) return;

  const isDevServerRequest =
    url.hostname === self.location.hostname && url.port !== self.location.port;
  if (isDevServerRequest) return;

  const skipBecauseUncached =
    event.request.cache === "only-if-cached" && !isStaticAsset;
  if (skipBecauseUncached) return;

  const isStaticAsset =
    url.host === self.location.host && staticAssets.has(url.pathname);

  // always serve static files and bundler-generated assets from cache.
  // if your application has other URLs with data that will never change,
  // set this variable to true for them and they will only be fetched once.
  event.respondWith(
    (async () => {
      const cachedAsset = isStaticAsset && (await caches.match(req));
      return cachedAsset || fetchAndCache(req);
    })()
  );
});
