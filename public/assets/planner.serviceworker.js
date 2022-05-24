self.addEventListener("install", (e) => {
  e.waitUntil(
    caches
      .open("planner")
      .then((cache) => cache.addAll(["/planner/", "/assets/b-button.png"]))
  );
});

self.addEventListener("fetch", (e) => {
  console.log("A1LIU-fetch:", e.request.url);

  e.respondWith(
    caches
      .match(e.request)
      .then((response) => response || fetch(e.request))
  );
});
