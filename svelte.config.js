import adapter from "@sveltejs/adapter-static";
import preprocess from "svelte-preprocess";
import {vitePreprocess} from "@sveltejs/kit/vite";

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // Consult https://github.com/sveltejs/svelte-preprocess
  // for more information about preprocessors
  preprocess: vitePreprocess({ postcss: true }),

  kit: {
    adapter: adapter({
      pages: ".out",
      assets: ".out",
    }),
    files: {
      assets: "./static",
      lib: "./src",
      serviceWorker: "./src/svelte/service-worker.ts",
    },
  },
};

export default config;
