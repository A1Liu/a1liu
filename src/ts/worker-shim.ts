// Weird-ass bullshit to fix a problem in Vite: https://github.com/vitejs/vite/issues/9879
// The `/_app/immutable/workers/` thing is very confusing, and I'm not sure exactly what should
// be in the baseURI section but if this works then I guess this works.
self.document = {
  baseURI: location.origin + "/_app/immutable/workers/",
} as any;

export {};
